//
//  CalendarViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import Foundation

/// 日历视图ViewModel（按需加载优化版）
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date? = nil
    @Published var recordsForSelectedDate: [MoodRecord] = []
    @Published var monthlyRecords: [Date: [MoodRecord]] = [:]

    /// 轻量查询数据（日历网格展示用）
    @Published var dayRecordCounts: [Date: Int] = [:]
    @Published var dayPrimaryMoods: [Date: MoodType] = [:]
    @Published var dayAverageIntensities: [Date: Double] = [:]

    /// 记录列表数据（按天分组）
    @Published var groupedRecords: [(date: Date, records: [MoodRecord])] = []

    /// 是否还有更多记录可加载
    @Published var hasMoreRecords: Bool = false

    /// 是否正在加载更多记录
    @Published var isLoadingMore: Bool = false

    private let dataManager: any MoodDataManaging
    private let calendar = Calendar.current

    private var cancellable: Any?

    /// 防抖定时器
    private var loadDebounceTimer: Timer?

    /// 分页加载相关
    private let pageSize: Int = 50
    private var currentOffset: Int = 0

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
        loadMonthlyData()
        loadGroupedRecordsInitial()
        // 监听数据变更通知（防抖）
        cancellable = NotificationCenter.default.addObserver(forName: .moodDataDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.debouncedLoadMonthlyData()
                self?.loadGroupedRecordsInitial()
            }
        }
    }

    deinit {
        loadDebounceTimer?.invalidate()
        if let cancellable = cancellable {
            NotificationCenter.default.removeObserver(cancellable)
        }
    }

    /// 防抖加载月度数据（300ms内多次调用只执行最后一次）
    private func debouncedLoadMonthlyData() {
        loadDebounceTimer?.invalidate()
        loadDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.loadMonthlyData()
            }
        }
    }

    // MARK: - 月份导航

    func goToPreviousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
            loadMonthlyData()
        }
    }

    func goToNextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
            loadMonthlyData()
        }
    }

    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
        loadMonthlyData()
    }

    // MARK: - 日期选择

    func selectDate(_ date: Date) {
        if selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!) {
            // 再次点击已选中日期，取消选中
            selectedDate = nil
            recordsForSelectedDate = []
        } else {
            selectedDate = date
            loadRecordsForSelectedDate()
        }
    }

    // MARK: - 数据加载

    func loadMonthlyData() {
        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)

        // 使用轻量查询获取日历网格数据（不加载完整记录）
        dayRecordCounts = dataManager.fetchDayRecordCounts(year: year, month: month)
        dayPrimaryMoods = dataManager.fetchDayPrimaryMoods(year: year, month: month)
        dayAverageIntensities = dataManager.fetchDayAverageIntensities(year: year, month: month)

        // 仅在需要时加载完整记录（选中日期的记录）
        loadRecordsForSelectedDate()
    }

    func loadRecordsForSelectedDate() {
        if let date = selectedDate {
            recordsForSelectedDate = dataManager.fetchRecords(for: date)
        } else {
            recordsForSelectedDate = []
        }
    }

    // MARK: - 日历网格数据

    /// 根据用户地区确定一周起始日（1=周日, 2=周一）
    /// 周一起始是 ISO 8601 标准及全球多数国家的惯例，
    /// 仅少数地区（北美、日本、中东等）以周日为一周起始
    private var firstWeekday: Int {
        let region = Locale.current.region?.identifier ?? ""
        // 周日起始的地区：北美、日本、韩国、印度、中东、菲律宾、泰国等
        let sundayFirstRegions: Set<String> = [
            "US", "CA", "MX",     // 北美
            "JP", "KR",           // 东亚
            "IN", "PH", "TH", "PK", "BD", "LK", "MM", "KH", // 南亚/东南亚
            "IL", "SA", "AE", "KW", "BH", "QA", "OM", "EG", "JO", "LB", "IQ" // 中东
        ]
        return sundayFirstRegions.contains(region) ? 1 : 2
    }

    /// 按用户地区排序的星期标题（短格式）
    var weekdaySymbols: [String] {
        // DateFormatter 的 veryShortWeekdaySymbols 固定从周日开始
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let symbols = formatter.veryShortWeekdaySymbols ?? ["日","一","二","三","四","五","六"]
        // 按 firstWeekday 重新排列
        let offset = firstWeekday - 1 // firstWeekday: 1=Sun, 2=Mon
        return (0..<7).map { symbols[(offset + $0) % 7] }
    }

    /// 获取当月日历网格（包含前后补位）
    var calendarDays: [CalendarDay] {
        let startOfMonth = currentMonth.startOfMonth
        let daysInMonth = currentMonth.daysInMonth
        let firstWeekdayOfMonth = currentMonth.firstWeekdayOfMonth // 1=Sun, 2=Mon...

        // 根据用户地区的一周起始日计算偏移
        // firstWeekdayOfMonth 是 Calendar 的 weekday (1=Sun, 2=Mon...)
        // firstWeekday 是用户地区的起始日 (1=Sun, 2=Mon...)
        let leadingDays = (firstWeekdayOfMonth - firstWeekday + 7) % 7

        var days: [CalendarDay] = []

        // 前面补位
        for i in 0..<leadingDays {
            if let date = calendar.date(byAdding: .day, value: -(leadingDays - i), to: startOfMonth) {
                days.append(CalendarDay(date: date, isCurrentMonth: false))
            }
        }

        // 当月日期
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(CalendarDay(date: date, isCurrentMonth: true))
            }
        }

        // 后面补位至42格（6行）
        let remaining = 42 - days.count
        if remaining > 0 {
            let lastDay = days.last?.date ?? startOfMonth
            for i in 1...remaining {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    days.append(CalendarDay(date: date, isCurrentMonth: false))
                }
            }
        }

        return days
    }

    // MARK: - 日期情绪信息（使用轻量查询数据）

    /// 获取某日的主情绪
    func primaryMoodForDate(_ date: Date) -> MoodType? {
        let dayStart = calendar.startOfDay(for: date)
        return dayPrimaryMoods[dayStart]
    }

    /// 获取某日情绪强度均值
    func averageIntensityForDate(_ date: Date) -> Double {
        let dayStart = calendar.startOfDay(for: date)
        return dayAverageIntensities[dayStart] ?? 0
    }

    /// 获取某日记录数量
    func recordCountForDate(_ date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        return dayRecordCounts[dayStart] ?? 0
    }

    /// 是否是今天
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// 是否是选中日期
    func isSelectedDate(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }

    /// 月份标题
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMM", options: 0, locale: Locale.current)
        return formatter.string(from: currentMonth)
    }

    /// 连续记录天数（首页已有展示，此处保留供兼容）
    var streakDays: Int {
        dataManager.fetchStreakDays()
    }

    /// 当前选中月份的总记录数
    var currentMonthRecordCount: Int {
        dayRecordCounts.values.reduce(0, +)
    }

    /// 当前月份的打卡天数（有记录的天数）
    var currentMonthActiveDays: Int {
        dayRecordCounts.values.filter { $0 > 0 }.count
    }

    /// 删除记录（异步，不阻塞主线程）
    func deleteRecord(_ record: MoodRecord) {
        Task {
            do {
                try await dataManager.deleteRecordAsync(record)
                // 删除后重新加载当前页数据
                loadGroupedRecordsInitial()
                loadMonthlyData()
            } catch {
                // 删除失败静默处理，UI 已有错误提示
            }
        }
    }

    // MARK: - 记录列表（按天分组，分页加载）

    /// 初始加载记录列表（第一页）
    func loadGroupedRecordsInitial() {
        currentOffset = 0
        let records = dataManager.fetchRecords(limit: pageSize, offset: 0)
        currentOffset = records.count
        // 如果返回的记录数等于页大小，说明可能还有更多
        hasMoreRecords = records.count == pageSize
        groupedRecords = groupRecordsByDate(records)
    }

    /// 加载更多记录（下一页）
    func loadMoreRecords() {
        guard hasMoreRecords, !isLoadingMore else { return }
        isLoadingMore = true

        let records = dataManager.fetchRecords(limit: pageSize, offset: currentOffset)
        currentOffset += records.count
        // 返回记录数不足页大小，说明已到末尾
        hasMoreRecords = records.count == pageSize

        let newGroups = groupRecordsByDate(records)
        groupedRecords = mergeRecordGroups(existing: groupedRecords, new: newGroups)

        isLoadingMore = false
    }

    /// 兼容旧接口：全量加载（仅在数据变更时使用）
    func loadGroupedRecords() {
        loadGroupedRecordsInitial()
    }

    /// 将记录按日期分组
    private func groupRecordsByDate(_ records: [MoodRecord]) -> [(date: Date, records: [MoodRecord])] {
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.createdAt ?? Date())
        }
        return grouped
            .map { (date: $0.key, records: $0.value.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }) }
            .sorted { $0.date > $1.date }
    }

    /// 合并两组按日期分组的记录
    private func mergeRecordGroups(
        existing: [(date: Date, records: [MoodRecord])],
        new: [(date: Date, records: [MoodRecord])]
    ) -> [(date: Date, records: [MoodRecord])] {
        var merged: [Date: [MoodRecord]] = [:]
        for group in existing {
            merged[group.date] = group.records
        }
        for group in new {
            if var existing = merged[group.date] {
                existing.append(contentsOf: group.records)
                merged[group.date] = existing
            } else {
                merged[group.date] = group.records
            }
        }
        return merged
            .map { (date: $0.key, records: $0.value.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }) }
            .sorted { $0.date > $1.date }
    }

    /// 格式化日期为分组标题（如"7月31日 周五"）
    func sectionDateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        if calendar.isDateInToday(date) {
            return L.localized("records.today")
        } else if calendar.isDateInYesterday(date) {
            return L.localized("records.yesterday")
        } else {
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMddEEE", options: 0, locale: Locale.current)
            return formatter.string(from: date)
        }
    }
}

// MARK: - 日历日期模型
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}
