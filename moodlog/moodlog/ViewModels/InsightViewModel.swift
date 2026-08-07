//
//  InsightViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import Foundation

/// 数据洞察ViewModel
class InsightViewModel: ObservableObject {
    @Published var selectedRange: InsightTimeRange = .week
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var moodDistribution: [MoodType: Int] = [:]
    @Published var topTags: [(name: String, count: Int)] = []
    @Published var totalRecords: Int = 0
    @Published var averageIntensity: Double = 0
    @Published var mostFrequentMood: MoodType = .happy
    @Published var availableYears: [Int] = []

    private let dataManager: any MoodDataManaging
    private let calendar: Calendar = {
        var cal = Calendar.current
        // 根据用户地区设置每周第一天
        // 周一起始是 ISO 8601 标准及全球多数国家的惯例，
        // 仅少数地区（北美、日本、中东等）以周日为一周起始
        let region: String
        if #available(iOS 16, *) {
            region = Locale.current.region?.identifier ?? ""
        } else {
            region = Locale.current.regionCode ?? ""
        }
        let sundayFirstRegions: Set<String> = [
            "US", "CA", "MX",     // 北美
            "JP", "KR",           // 东亚
            "IN", "PH", "TH", "PK", "BD", "LK", "MM", "KH", // 南亚/东南亚
            "IL", "SA", "AE", "KW", "BH", "QA", "OM", "EG", "JO", "LB", "IQ" // 中东
        ]
        cal.firstWeekday = sundayFirstRegions.contains(region) ? 1 : 2
        return cal
    }()

    private var cancellable: Any?

    /// 防抖定时器
    private var loadDebounceTimer: Timer?

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
        loadAvailableYears()
        loadData()
        // 监听数据变更通知
        cancellable = NotificationCenter.default.addObserver(forName: .moodDataDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.loadAvailableYears()
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

    // MARK: - 年份管理

    /// 最早可选年份
    private let minYear = 2020

    /// 当前年份
    var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    func loadAvailableYears() {
        availableYears = dataManager.fetchAvailableYears()
        if selectedYear > currentYear || selectedYear < minYear {
            selectedYear = currentYear
        }
    }

    /// 是否可以切换到更早的年份
    var canGoPreviousYear: Bool {
        selectedYear > minYear
    }

    /// 是否可以切换到更近的年份
    var canGoNextYear: Bool {
        selectedYear < currentYear
    }

    // MARK: - 时间范围

    var dateRange: (start: Date, end: Date) {
        let now = Date()
        switch selectedRange {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now.endOfDay)
        case .week:
            // 使用 dateInterval 自动适应用户地区（中国周一为起始，美国周日为起始）
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) {
                return (weekInterval.start, now.endOfDay)
            }
            return (calendar.startOfDay(for: now), now.endOfDay)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components)!
            return (start, now.endOfDay)
        case .quarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            components.day = 1
            let start = calendar.date(from: components)!
            return (start, now.endOfDay)
        case .year:
            var components = DateComponents()
            components.year = selectedYear
            components.month = 1
            components.day = 1
            let start = calendar.date(from: components)!
            if selectedYear == currentYear {
                // 今年：1.1 到今日
                return (start, now.endOfDay)
            } else {
                // 往年：整年
                components.year = selectedYear + 1
                let end = calendar.date(from: components)!
                return (start, end)
            }
        }
    }

    // MARK: - 日期范围标题

    var dateRangeTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        let now = Date()
        let today = formatter.string(from: now)
        let todayLabel = L.localized("insight.range_today")

        switch selectedRange {
        case .today:
            // 今日：只显示当天，如 "8.6"
            return today
        case .week, .month, .quarter:
            // 本周/本月/本季：起始日 - 今日(日期)，如 "8.4 - 今日(8.6)"
            let start = formatter.string(from: dateRange.start)
            return "\(start) - \(todayLabel)(\(today))"
        case .year:
            if selectedYear == currentYear {
                // 今年：1.1 - 今日(日期)，如 "1.1 - 今日(8.6)"
                let start = formatter.string(from: dateRange.start)
                return "\(start) - \(todayLabel)(\(today))"
            } else {
                // 往年：只显示年份，如 "2025"
                return "\(selectedYear)"
            }
        }
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

        // 最频繁情绪
        if let maxMood = moodDistribution.max(by: { $0.value < $1.value }) {
            mostFrequentMood = maxMood.key
        } else {
            // 无数据时重置为默认值，配合 UI 显示 "--"
            mostFrequentMood = .happy
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

enum InsightTimeRange: Hashable, CaseIterable {
    case today
    case week
    case month
    case quarter
    case year

    static var allCases: [InsightTimeRange] {
        [.today, .week, .month, .quarter, .year]
    }

    var displayName: String {
        switch self {
        case .today:
            return L.localized("insight.range_today")
        case .week:
            return L.localized("insight.range_week")
        case .month:
            return L.localized("insight.range_month")
        case .quarter:
            return L.localized("insight.range_quarter")
        case .year:
            return L.localized("insight.range_year")
        }
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
