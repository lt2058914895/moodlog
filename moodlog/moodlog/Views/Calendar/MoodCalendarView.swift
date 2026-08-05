//
//  MoodCalendarView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 日历视图主页面
struct MoodCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var recordToEdit: MoodRecord?
    @State private var recordToDelete: MoodRecord?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    var onNavigateToCheckin: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // 日历区域
                Section {
                    // 月份导航
                    monthNavigation

                    // 连续记录
                    if viewModel.streakDays > 0 {
                        streakBanner
                    }

                    // 日历网格
                    calendarGrid
                }

                // 选中日期后显示记录区域（带粘性头部）
                if viewModel.selectedDate != nil {
                    Section(header: dayTimelineHeader) {
                        dayTimelineContent
                    }
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(item: $recordToEdit) { record in
            EditMoodRecordView(record: record)
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

    private func deleteRecord(_ record: MoodRecord) {
        do {
            try viewModel.deleteRecord(record)
            viewModel.loadMonthlyData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 月份导航
    private var monthNavigation: some View {
        HStack {
            Button(action: viewModel.goToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "6C5CE7"))
                    .padding(8)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.headline)

            Spacer()

            Button(action: viewModel.goToToday) {
                Text(L.localized("calendar.today"))
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: "6C5CE7"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "6C5CE7").opacity(0.1)))
            }

            Button(action: viewModel.goToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "6C5CE7"))
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 连续记录横幅
    private var streakBanner: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.title3)
            Text(L.localizedInt("calendar.streak", value: viewModel.streakDays))
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "FF6B6B"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "FF6B6B").opacity(0.08))
    }

    // MARK: - 日历网格
    private var calendarGrid: some View {
        VStack(spacing: 4) {
            // 星期标题
            weekdayHeader

            // 日期网格
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
            ForEach([L.localized("calendar.weekday_mon"), L.localized("calendar.weekday_tue"), L.localized("calendar.weekday_wed"), L.localized("calendar.weekday_thu"), L.localized("calendar.weekday_fri"), L.localized("calendar.weekday_sat"), L.localized("calendar.weekday_sun")], id: \.self) { weekday in
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
                // 背景色块（情绪色）
                if let mood = moodType, day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(mood.color.opacity(0.15 + intensity / 20))
                        .frame(height: 44)
                } else if day.isCurrentMonth {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(height: 44)
                }

                // 选中边框
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "6C5CE7"), lineWidth: 2)
                        .frame(height: 44)
                }

                VStack(spacing: 2) {
                    Text("\(dayComponent)")
                        .font(isToday ? .caption.bold() : .caption)
                        .foregroundColor(
                            !day.isCurrentMonth ? .secondary :
                            isToday ? Color(hex: "6C5CE7") :
                            isSelected ? Color(hex: "6C5CE7") : .primary
                        )

                    // 情绪指示点
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
                        .foregroundColor(Color(hex: "6C5CE7").opacity(0.5))
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
                                colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
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
                // 时间线列表
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

                // 操作提示
                Text(L.localized("calendar.long_press_hint"))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 8)
            }

            // 底部安全区域
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
}

// MARK: - 情绪记录行
struct MoodRecordRow: View {
    let record: MoodRecord
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    private var moodType: MoodType {
        MoodType.from(rawValue: record.moodType)
    }

    private var timeString: String {
        guard let date = record.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var tagNames: [String] {
        MoodDataManager.tagNamesFromRecord(record)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 情绪emoji圆形背景
            ZStack {
                Circle()
                    .fill(moodType.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(moodType.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
            }

            // 情绪信息
            VStack(alignment: .leading, spacing: 6) {
                // 第一行：情绪名称 + 时间
                HStack(spacing: 6) {
                    Text(moodType.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    Text(timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    // 强度胶囊
                    Text(L.localizedInt("calendar.intensity", value: Int(record.intensity)))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(moodType.color.opacity(0.15)))
                        .foregroundColor(moodType.color)
                }

                // 活动标签
                if !tagNames.isEmpty {
                    FlowLayout(data: tagNames, spacing: 6) { tagName in
                        HStack(spacing: 4) {
                            Text(PresetTag.emoji(for: tagName) ?? "📋")
                                .font(.system(size: 11))
                            Text(tagName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color(UIColor.tertiarySystemGroupedBackground))
                        )
                        .foregroundColor(.secondary)
                    }
                }

                // 备注
                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 强度指示条
            IntensityBar(value: Int(record.intensity), color: moodType.color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label(L.localized("checkin.edit"), systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label(L.localized("checkin.delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - 强度指示条
struct IntensityBar: View {
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            ForEach((1...10).reversed(), id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i <= value ? color : Color.gray.opacity(0.15))
                    .frame(width: 3, height: 3)
            }
        }
    }
}

// MARK: - 记录列表行（用于记录列表模式）
struct MoodRecordListRow: View {
    let record: MoodRecord
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    private var moodType: MoodType {
        MoodType.from(rawValue: record.moodType)
    }

    private var timeString: String {
        guard let date = record.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var tagNames: [String] {
        MoodDataManager.tagNamesFromRecord(record)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 情绪emoji圆形背景
            ZStack {
                Circle()
                    .fill(moodType.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(moodType.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }

            // 情绪信息
            VStack(alignment: .leading, spacing: 6) {
                // 第一行：情绪名称 + 时间
                HStack(spacing: 6) {
                    Text(moodType.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Spacer()
                    Text(timeString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    // 强度胶囊
                    Text(L.localizedInt("calendar.intensity", value: Int(record.intensity)))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(moodType.color.opacity(0.15)))
                        .foregroundColor(moodType.color)
                }

                // 活动标签
                if !tagNames.isEmpty {
                    FlowLayout(data: tagNames, spacing: 6) { tagName in
                        HStack(spacing: 4) {
                            Text(PresetTag.emoji(for: tagName) ?? "📋")
                                .font(.system(size: 11))
                            Text(tagName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Color(UIColor.tertiarySystemGroupedBackground))
                        )
                        .foregroundColor(.secondary)
                    }
                }

                // 备注
                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 强度指示条
            IntensityBar(value: Int(record.intensity), color: moodType.color)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label(L.localized("checkin.edit"), systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label(L.localized("checkin.delete"), systemImage: "trash")
            }
        }
    }
}

#Preview {
    MoodCalendarView()
}
