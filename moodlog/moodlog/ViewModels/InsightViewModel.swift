//
//  InsightViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import Foundation

/// 数据洞察ViewModel
class InsightViewModel: ObservableObject {
    @Published var selectedPeriod: InsightPeriod = .week
    @Published var dailyIntensityData: [(date: Date, intensity: Double)] = []
    @Published var moodDistribution: [MoodType: Int] = [:]
    @Published var topTags: [(name: String, count: Int)] = []
    @Published var totalRecords: Int = 0
    @Published var averageIntensity: Double = 0
    @Published var mostFrequentMood: MoodType = .happy

    private let dataManager: MoodDataManager
    private let calendar = Calendar.current

    private var cancellable: Any?

    init(dataManager: MoodDataManager = .shared) {
        self.dataManager = dataManager
        loadData()
        // 监听数据变更通知
        cancellable = NotificationCenter.default.addObserver(forName: .moodDataDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.loadData()
        }
    }

    deinit {
        if let cancellable = cancellable {
            NotificationCenter.default.removeObserver(cancellable)
        }
    }

    // MARK: - 时间范围

    var dateRange: (start: Date, end: Date) {
        let now = Date()
        switch selectedPeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: now.startOfDay)!
            return (start, now.endOfDay)
        case .month:
            let start = calendar.date(byAdding: .day, value: -29, to: now.startOfDay)!
            return (start, now.endOfDay)
        }
    }

    // MARK: - 数据加载

    func loadData() {
        let range = dateRange
        let records = dataManager.fetchRecords(from: range.start, to: range.end)

        totalRecords = records.count

        // 日均强度
        dailyIntensityData = dataManager.fetchDailyAverageIntensity(from: range.start, to: range.end)

        // 平均强度
        if !records.isEmpty {
            let totalIntensity = records.reduce(0.0) { $0 + Double($1.intensity) }
            averageIntensity = totalIntensity / Double(records.count)
        } else {
            averageIntensity = 0
        }

        // 情绪分布
        moodDistribution = dataManager.fetchMoodDistribution(from: range.start, to: range.end)

        // 最频繁情绪
        if let maxMood = moodDistribution.max(by: { $0.value < $1.value }) {
            mostFrequentMood = maxMood.key
        }

        // 标签频次
        topTags = dataManager.fetchTopTags(from: range.start, to: range.end, limit: 10)
    }

    // MARK: - 图表数据

    /// 趋势图数据点
    var chartDataPoints: [ChartDataPoint] {
        dailyIntensityData.map { point in
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return ChartDataPoint(
                label: formatter.string(from: point.date),
                value: point.intensity,
                date: point.date
            )
        }
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

    /// 情绪分布摘要文字
    var distributionSummary: String {
        guard !moodDistribution.isEmpty else { return L.localized("insight.no_data") }
        let sorted = moodDistribution.sorted { $0.value > $1.value }
        let top = sorted.prefix(3).map { mood, count in
            String(format: L.localized("insight.mood_times"), "\(mood.emoji)\(mood.displayName)", count)
        }
        return top.joined(separator: L.localized("insight.separator"))
    }

    /// 时间范围标题
    var periodTitle: String {
        switch selectedPeriod {
        case .week: return L.localized("insight.last_7_days")
        case .month: return L.localized("insight.last_30_days")
        }
    }
}

// MARK: - 枚举与数据模型

enum InsightPeriod: String, CaseIterable {
    case week = "insight.week"
    case month = "insight.month"
    
    var displayName: String {
        L.localized(rawValue)
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let date: Date
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