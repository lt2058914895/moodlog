//
//  InsightViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import Foundation

/// 数据洞察ViewModel
class InsightViewModel: ObservableObject {
    @Published var selectedRange: InsightTimeRange = .sevenDays
    @Published var moodDistribution: [MoodType: Int] = [:]
    @Published var topTags: [(name: String, count: Int)] = []
    @Published var totalRecords: Int = 0
    @Published var averageIntensity: Double = 0
    @Published var mostFrequentMood: MoodType = .happy
    @Published var dominantMoodPercentage: Double = 0
    @Published var isMoodSpread: Bool = false
    @Published var topTwoMoods: [MoodType] = []
    private let dataManager: any MoodDataManaging
    private var cancellable: Any?

    /// 防抖定时器
    private var loadDebounceTimer: Timer?

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
        loadData()
        // 监听数据变更通知
        cancellable = NotificationCenter.default.addObserver(forName: .moodDataDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.debouncedLoadData()
        }
    }

    deinit {
        loadDebounceTimer?.invalidate()
        if let cancellable = cancellable {
            NotificationCenter.default.removeObserver(cancellable)
        }
    }

    /// 防抖加载数据（300ms内多次调用只执行最后一次）
    private func debouncedLoadData() {
        loadDebounceTimer?.invalidate()
        loadDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.loadData()
        }
    }

    // MARK: - 时间范围

    var dateRange: (start: Date, end: Date) {
        selectedRange.dateRange()
    }

    // MARK: - 日期范围标题

    var dateRangeTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        let now = Date()
        let today = formatter.string(from: now)
        let todayLabel = L.localized("insight.range_today")
        let start = formatter.string(from: dateRange.start)
        return "\(start) - \(todayLabel)(\(today))"
    }

    // MARK: - 数据加载

    func loadData() {
        let range = dateRange
        let records = dataManager.fetchRecords(from: range.start, to: range.end)

        totalRecords = records.count

        // 平均强度
        if !records.isEmpty {
            let totalIntensity = records.reduce(0.0) { $0 + Double($1.intensity) }
            averageIntensity = totalIntensity / Double(records.count)
        } else {
            averageIntensity = 0
        }

        // 情绪分布
        moodDistribution = dataManager.fetchMoodDistribution(from: range.start, to: range.end)

        // 最频繁情绪 + 分布分析
        let totalCount = moodDistribution.values.reduce(0, +)
        if totalCount > 0 {
            let sortedMoods = moodDistribution.sorted { $0.value > $1.value }
            mostFrequentMood = sortedMoods[0].key
            dominantMoodPercentage = Double(sortedMoods[0].value) / Double(totalCount) * 100
            // 取前两个情绪用于对比
            topTwoMoods = Array(sortedMoods.prefix(2).map { $0.key })
            // 如果占比低于 40%，或前两名占比差值小于 10%，认为情绪分布较分散
            if sortedMoods.count >= 2 {
                let gap = Double(sortedMoods[0].value - sortedMoods[1].value) / Double(totalCount) * 100
                isMoodSpread = dominantMoodPercentage < 40 || gap < 10
            } else {
                isMoodSpread = false
            }
        } else {
            mostFrequentMood = .happy
            dominantMoodPercentage = 0
            isMoodSpread = false
            topTwoMoods = []
        }

        // 标签频次
        topTags = dataManager.fetchTopTags(from: range.start, to: range.end, limit: 10)
    }

    /// 饼图数据
    var pieChartData: [PieChartData] {
        let total = moodDistribution.values.reduce(0, +)
        guard total > 0 else { return [] }

        return moodDistribution.map { mood, count in
            PieChartData(
                moodType: mood,
                value: count,
                percentage: Double(count) / Double(total) * 100
            )
        }.sorted { $0.value > $1.value }
    }

    /// 标签柱状图数据
    var tagBarData: [TagBarData] {
        let maxCount = topTags.first?.count ?? 1
        return topTags.map { tag in
            TagBarData(
                name: tag.name,
                count: tag.count,
                ratio: Double(tag.count) / Double(maxCount)
            )
        }
    }

    /// 时间范围标题
    var periodTitle: String {
        return dateRangeTitle
    }
}

// MARK: - 枚举与数据模型

struct InsightTimeRange: Hashable, Identifiable {
    let weeks: Int

    var id: Int { weeks }

    static let sevenDays = InsightTimeRange(weeks: 1)
    static let allCases: [InsightTimeRange] = (1...52).map { InsightTimeRange(weeks: $0) }

    var displayName: String {
        if weeks == 1 {
            return L.localized("insight.range_7_days")
        }
        return String(format: L.localized("insight.range_weeks_format"), weeks)
    }
}

struct PieChartData: Identifiable {
    let id = UUID()
    let moodType: MoodType
    let value: Int
    let percentage: Double
}

struct TagBarData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let ratio: Double
}

// MARK: - 时间区间（回顾页与分享卡片共用的单一实现）

extension InsightTimeRange {
    /// 日期区间口径：截至今天的连续周区间，1 周等于 7 天
    func dateRange(at date: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = date.endOfDay
        let totalDays = max(weeks, 1) * 7
        let startOfToday = calendar.startOfDay(for: date)
        let start = calendar.date(byAdding: .day, value: -(totalDays - 1), to: startOfToday)!
        return (start, end)
    }
}
