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

    var body: some View {
        VStack(spacing: 0) {
            // 月份导航
            monthNavigation

            // 连续打卡
            if viewModel.streakDays > 0 {
                streakBanner
            }

            // 日历网格
            calendarGrid

            Divider()

            // 日情绪时间线
            dayTimeline
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
            try MoodDataManager.shared.deleteRecord(record)
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

    // MARK: - 连续打卡横幅
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

        return Button(action: { viewModel.selectDate(day.date) }) {
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

    // MARK: - 日情绪时间线
    private var dayTimeline: some View {
        VStack(spacing: 0) {
            // 日期标题
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

            if viewModel.recordsForSelectedDate.isEmpty {
                // 空状态
                VStack(spacing: 8) {
                    Text("📝")
                        .font(.title)
                    Text(L.localized("calendar.no_records"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // 时间线列表
                ScrollView {
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
                    .padding(.bottom, 8)
                }

                // 操作提示
                Text(L.localized("calendar.long_press_hint"))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.bottom, 8)
            }
        }
        .background(Color(UIColor.systemBackground))
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: viewModel.selectedDate)
    }
}

// MARK: - 情绪记录行
struct MoodRecordRow: View {
    let record: MoodRecord
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    private var moodType: MoodType? {
        MoodType(rawValue: record.moodType ?? "happy")
    }

    private var moodSubType: MoodSubType? {
        MoodSubType.from(rawValue: record.moodSubType ?? "joyful")
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
            // 时间
            Text(timeString)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .leading)

            // 情绪色块
            RoundedRectangle(cornerRadius: 4)
                .fill(moodType?.color ?? .gray)
                .frame(width: 4, height: 40)

            // 情绪信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(moodType?.emoji ?? "😊")
                        .font(.title3)
                    Text(moodType?.displayName ?? "")
                        .font(.subheadline.bold())
                    Text(moodSubType?.displayName ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(L.localizedInt("calendar.intensity", value: Int(record.intensity)))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(moodType?.color.opacity(0.15) ?? Color.gray.opacity(0.15)))
                        .foregroundColor(moodType?.color ?? .gray)
                }

                if !tagNames.isEmpty {
                    Text(tagNames.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            // 强度指示条
            IntensityBar(value: Int(record.intensity), color: moodType?.color ?? .gray)
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

#Preview {
    MoodCalendarView()
}