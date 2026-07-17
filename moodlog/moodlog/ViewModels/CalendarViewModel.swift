//
//  CalendarViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import Foundation

/// 日历视图ViewModel（按需加载优化版）
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    @Published var recordsForSelectedDate: [MoodRecord] = []
    @Published var monthlyRecords: [Date: [MoodRecord]] = [:]

    /// 轻量查询数据（日历网格展示用）
    @Published var dayRecordCounts: [Date: Int] = [:]
    @Published var dayPrimaryMoods: [Date: MoodType] = [:]
    @Published var dayAverageIntensities: [Date: Double] = [:]

    private let dataManager: any MoodDataManaging
    private let calendar = Calendar.current

    private var cancellable: Any?

    /// 防抖定时器
    private var loadDebounceTimer: Timer?

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
        loadMonthlyData()
        // 监听数据变更通知（防抖）
        cancellable = NotificationCenter.default.addObserver(forName: .moodDataDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.debouncedLoadMonthlyData()
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
            self?.loadMonthlyData()
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
        selectedDate = date
        loadRecordsForSelectedDate()
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
        recordsForSelectedDate = dataManager.fetchRecords(for: selectedDate)
    }

    // MARK: - 日历网格数据

    /// 获取当月日历网格（包含前后补位）
    var calendarDays: [CalendarDay] {
        let startOfMonth = currentMonth.startOfMonth
        let daysInMonth = currentMonth.daysInMonth
        let firstWeekday = currentMonth.firstWeekdayOfMonth

        // 周日=1, 周一=2... 我们需要调整为周一开始
        let adjustedFirstWeekday = firstWeekday == 1 ? 7 : firstWeekday - 1 // 转为周一=1...周日=7

        var days: [CalendarDay] = []

        // 前面补位
        for i in 0..<(adjustedFirstWeekday - 1) {
            if let date = calendar.date(byAdding: .day, value: -(adjustedFirstWeekday - 1 - i), to: startOfMonth) {
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
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    /// 月份标题
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMM", options: 0, locale: Locale.current)
        return formatter.string(from: currentMonth)
    }

    /// 连续打卡天数
    var streakDays: Int {
        dataManager.fetchStreakDays()
    }

    /// 删除记录
    func deleteRecord(_ record: MoodRecord) throws {
        try dataManager.deleteRecord(record)
    }
}

// MARK: - 日历日期模型
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
}