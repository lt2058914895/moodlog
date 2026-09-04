//
//  MoodRecordsView.swift
//  moodlog
//
//  Created by deppon on 2026/7/31.
//

import SwiftUI

/// 记录/日历视图（合并页）
struct MoodRecordsView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var viewMode: ViewMode = .list
    @State private var recordToEdit: MoodRecord?
    @State private var recordToDelete: MoodRecord?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    var onNavigateToCheckin: (() -> Void)? = nil

    enum ViewMode: Int, CaseIterable {
        case list, calendar

        var title: String {
            switch self {
            case .list: return L.localized("records.mode.records")
            case .calendar: return L.localized("records.mode.calendar")
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 视图切换器
            modePicker
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            Group {
                if viewMode == .list {
                    listContent
                } else {
                    calendarContent
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationDestination(isPresented: Binding(
            get: { recordToEdit != nil },
            set: { if !$0 { recordToEdit = nil } }
        )) {
            if let record = recordToEdit {
                EditMoodRecordView(record: record)
            }
        }
        .alert(L.localized("checkin.delete_confirm"), isPresented: $showDeleteConfirmation, presenting: recordToDelete) { record in
            Button(L.localized("checkin.delete"), role: .destructive) {
                deleteRecord(record)
            }
            Button(L.localized("checkin.cancel"), role: .cancel) {}
        }
        .alert(L.localized("checkin.alert_title"), isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button(L.localized("checkin.alert_ok"), role: .cancel) {
                errorMessage = nil
            }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - 视图切换器
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                }) {
                    Text(mode.title)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewMode == mode
                                ? Color("AccentColor")
                                : Color.clear
                        )
                        .foregroundColor(
                            viewMode == mode
                                ? .white
                                : Color("AccentColor")
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - 列表模式
    private var listContent: some View {
        VStack(spacing: 0) {
            if viewModel.groupedRecords.isEmpty {
                emptyStateView
            } else {
                Text(L.localized("calendar.long_press_hint"))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.top, 0)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity)

                List {
                    ForEach(viewModel.groupedRecords, id: \.date) { group in
                        Section {
                            ForEach(Array(group.records.enumerated()), id: \.element.id) { index, record in
                                MoodRecordListRow(record: record, onEdit: {
                                    recordToEdit = record
                                }, onDelete: {
                                    recordToDelete = record
                                    showDeleteConfirmation = true
                                })
                                .onAppear {
                                    // 滚动到最后3条记录时触发加载更多
                                    if index >= group.records.count - 3 {
                                        triggerLoadMoreIfNeeded()
                                    }
                                }
                            }
                        } header: {
                            recordsSectionHeader(group.date, count: group.records.count)
                        }
                    }

                    // 底部加载更多指示器
                    if viewModel.isLoadingMore {
                        Section {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 8)
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    /// 触发分页加载（防重复）
    private func triggerLoadMoreIfNeeded() {
        guard viewModel.hasMoreRecords, !viewModel.isLoadingMore else { return }
        viewModel.loadMoreRecords()
    }

    // MARK: - 日历模式
    private var calendarContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    monthNavigation

                    monthStatsBanner

                    calendarGrid
                }

                if viewModel.selectedDate != nil {
                    Section(header: dayTimelineHeader) {
                        dayTimelineContent
                    }
                }
            }
        }
    }

    // MARK: - 列表分组头部
    private func recordsSectionHeader(_ date: Date, count: Int) -> some View {
        HStack {
            Text(viewModel.sectionDateTitle(date))
                .font(.subheadline.bold())
                .foregroundColor(Color("AccentColor"))
            Spacer()
            Text(L.localizedInt("calendar.records_count", value: count))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.text.square")
                .font(.system(size: 56))
                .foregroundColor(Color("AccentColor").opacity(0.6))
            Text(L.localized("records.empty"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: {
                onNavigateToCheckin?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(L.localized("records.empty_action"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color("AccentColor"), Color("AccentLightColor")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 月份导航
    private var monthNavigation: some View {
        HStack {
            Button(action: viewModel.goToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color("AccentColor"))
                    .padding(8)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.headline)

            Spacer()

            Button(action: viewModel.goToToday) {
                Text(L.localized("calendar.today"))
                    .font(.caption.bold())
                    .foregroundColor(Color("AccentColor"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color("AccentColor").opacity(0.1)))
            }

            Button(action: viewModel.goToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color("AccentColor"))
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 月度统计横幅
    private var monthStatsBanner: some View {
        HStack(spacing: 0) {
            // 本月总记录数
            VStack(spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color("AccentColor"))
                Text("\(viewModel.currentMonthRecordCount)")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Text(L.localized("calendar.month_records"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            // 分隔线
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.3))
                .frame(width: 1, height: 40)

            // 本月打卡天数
            VStack(spacing: 4) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 18))
                    .foregroundColor(Color("SuccessColor"))
                Text("\(viewModel.currentMonthActiveDays)")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                Text(L.localized("calendar.month_days"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground).opacity(0.6))
    }

    // MARK: - 日历网格
    private var calendarGrid: some View {
        VStack(spacing: 4) {
            weekdayHeader

            let days = viewModel.calendarDays
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(days) { day in
                    calendarDayCell(day)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 星期标题
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - 日期单元格
    private func calendarDayCell(_ day: CalendarDay) -> some View {
        let dayComponent = Calendar.current.component(.day, from: day.date)
        let moodType = viewModel.primaryMoodForDate(day.date)
        let intensity = viewModel.averageIntensityForDate(day.date)
        let isToday = viewModel.isToday(day.date)
        let isSelected = viewModel.isSelectedDate(day.date)
        let hasRecords = viewModel.recordCountForDate(day.date) > 0

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectDate(day.date)
            }
        }) {
            ZStack {
                if let mood = moodType, day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(mood.color.opacity(0.15 + intensity / 20))
                        .frame(height: 44)
                } else if day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(height: 44)
                }

                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("AccentColor"), lineWidth: 2)
                        .frame(height: 44)
                }

                VStack(spacing: 2) {
                    Text("\(dayComponent)")
                        .font(isToday ? .caption.bold() : .caption)
                        .foregroundColor(
                            !day.isCurrentMonth ? .secondary :
                            isToday ? Color("AccentColor") :
                            isSelected ? Color("AccentColor") : .primary
                        )

                    if hasRecords, day.isCurrentMonth {
                        Circle()
                            .fill(moodType?.color ?? .gray)
                            .frame(width: 5, height: 5)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 44)
    }

    // MARK: - 日情绪时间线粘性头部
    private var dayTimelineHeader: some View {
        HStack {
            Text(dateTitle)
                .font(.subheadline.bold())
            Spacer()
            Text(L.localizedInt("calendar.records_count", value: viewModel.recordsForSelectedDate.count))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 日情绪时间线内容
    private var dayTimelineContent: some View {
        VStack(spacing: 0) {
            if viewModel.recordsForSelectedDate.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 40))
                        .foregroundColor(Color("AccentColor").opacity(0.5))
                    Text(L.localized("calendar.no_records"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        onNavigateToCheckin?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text(L.localized("calendar.empty_action"))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color("AccentColor"), Color("AccentLightColor")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recordsForSelectedDate, id: \.id) { record in
                        MoodRecordRow(record: record, onEdit: {
                            recordToEdit = record
                        }, onDelete: {
                            recordToDelete = record
                            showDeleteConfirmation = true
                        })
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                Text(L.localized("calendar.long_press_hint"))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 8)
            }

            Color.clear.frame(height: 20)
        }
    }

    private var dateTitle: String {
        guard let date = viewModel.selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func deleteRecord(_ record: MoodRecord) {
        viewModel.deleteRecord(record)
    }
}

#Preview {
    MoodRecordsView()
}
