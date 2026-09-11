//
//  MoodBookDetailView.swift
//  moodlog
//
//  Created by deppon on 2026/9/11.
//

import SwiftUI

// MARK: - 单本情绪集详情

struct MoodBookDetailView: View {
    let stats: MoodBookStats

    @Environment(\.dismiss) private var dismiss
    @State private var records: [MoodRecord] = []
    @State private var isBookOpen = false

    private var mood: MoodType { stats.mood }

    private var groupedRecords: [(date: Date, records: [MoodRecord])] {
        Dictionary(grouping: records) { record in
            Calendar.current.startOfDay(for: record.createdAt ?? Date())
        }
        .map { date, records in (date: date, records: records.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }) }
        .sorted { $0.date > $1.date }
    }

    private var summaryText: String {
        guard !records.isEmpty else {
            return L.localized("profile.library_summary_empty")
        }

        return String(
            format: L.localized("profile.library_summary_filled"),
            mood.displayName,
            stats.count,
            stats.averageIntensity,
            Self.dateFormatter.string(from: stats.latestDate ?? Date())
        )
    }

    var body: some View {
        ZStack {
            readingRoomBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    openedBook
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle(mood.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color("AccentColor"))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                    }
                }
        }
        .task { loadRecords() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65).delay(0.06)) {
                isBookOpen = true
            }
        }
    }

    private var readingRoomBackground: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)

            Circle()
                .fill(mood.color.opacity(0.07))
                .frame(width: 300, height: 300)
                .blur(radius: 48)
                .offset(x: 110, y: -90)
        }
    }

    private var openedBook: some View {
        VStack(spacing: 0) {
            titlePage

            Rectangle()
                .fill(Color(hex: "E0D0AE"))
                .frame(height: 1)
                .padding(.horizontal, 32)

            recordTimeline

            bookFooter
        }
        .padding(.vertical, 24)
        .background(bookBlock)
        .overlay(alignment: .leading) { bookSpine }
        .overlay(alignment: .topTrailing) { bookmarkRibbon }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: Color(hex: "37291C").opacity(0.24), radius: 24, x: 8, y: 14)
        .scaleEffect(isBookOpen ? 1 : 0.97, anchor: .topLeading)
        .rotation3DEffect(
            .degrees(isBookOpen ? 0 : -8),
            axis: (x: 0, y: 1, z: 0),
            anchor: .leading,
            perspective: 0.72
        )
        .opacity(isBookOpen ? 1 : 0.22)
    }

    private var bookBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: "EFE3C8"))
                .offset(x: 7, y: 5)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: "F7EEDA"))
                .offset(x: 3.5, y: 2.5)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: "FFF9EA"))
        }
    }

    private var bookSpine: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: "443322").opacity(0.07))
                .frame(width: 10)

            Rectangle()
                .fill(Color(hex: "443322").opacity(0.03))
                .frame(width: 4)
        }
    }

    private var bookmarkRibbon: some View {
        BookmarkRibbonShape()
            .fill(mood.color.opacity(0.9))
            .frame(width: 14, height: 76)
            .shadow(color: Color(hex: "40301E").opacity(0.14), radius: 4, x: -1, y: 2)
    }

    private var titlePage: some View {
        VStack(spacing: 18) {
            Text(L.localized("profile.library_archive_name"))
                .font(.caption2.weight(.semibold))
                .tracking(2.6)
                .foregroundColor(Color(hex: "A5834E"))

            ZStack {
                Circle()
                    .fill(mood.color.opacity(0.10))
                    .frame(width: 74, height: 74)

                Circle()
                    .stroke(Color(hex: "C9A96F").opacity(0.45), lineWidth: 1)
                    .frame(width: 61, height: 61)

                Image(mood.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 43, height: 43)
            }

            VStack(spacing: 8) {
                Text(mood.displayName)
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .foregroundColor(Color(hex: "41301C"))

                HStack(spacing: 7) {
                    Rectangle().fill(Color(hex: "C9A96F").opacity(0.5)).frame(height: 1)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "C9A96F").opacity(0.7))
                        .frame(width: 5, height: 5)
                        .rotationEffect(.degrees(45))
                    Rectangle().fill(Color(hex: "C9A96F").opacity(0.5)).frame(height: 1)
                }
                .frame(width: 126)
            }

            Text(summaryText)
                .font(.system(.footnote, design: .serif))
                .foregroundColor(Color(hex: "6B573C"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)

            HStack(spacing: 0) {
                journalStat(
                    title: L.localized("profile.library_book_count"),
                    value: "\(stats.count)"
                )

                Rectangle().fill(Color(hex: "DCCBAA")).frame(width: 1, height: 28)

                journalStat(
                    title: L.localized("profile.library_detail_intensity"),
                    value: stats.count == 0 ? "-" : String(format: "%.1f/10", stats.averageIntensity)
                )

                Rectangle().fill(Color(hex: "DCCBAA")).frame(width: 1, height: 28)

                journalStat(
                    title: L.localized("profile.library_book_latest"),
                    value: stats.latestDate.map { Self.compactDateFormatter.string(from: $0) } ?? "-"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 26)
        .padding(.bottom, 26)
    }

    private var bookFooter: some View {
        Text(L.localized("profile.library_archive_name"))
            .font(.caption2.weight(.medium))
            .tracking(2)
            .foregroundColor(Color(hex: "A5834E").opacity(0.65))
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
    }

    private func journalStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Color(hex: "947955"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(value)
                .font(.system(.subheadline, design: .serif).weight(.semibold).monospacedDigit())
                .foregroundColor(Color(hex: "41301C"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }

    private var recordTimeline: some View {
        VStack(spacing: 0) {
            if groupedRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.title3)
                        .foregroundColor(Color(hex: "A5834E"))

                    Text(L.localized("profile.library_timeline_empty"))
                        .font(.system(.footnote, design: .serif))
                        .foregroundColor(Color(hex: "6B573C"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(Array(groupedRecords.enumerated()), id: \.element.date) { index, group in
                    journalPage(index: index, group: group)

                    if index < groupedRecords.count - 1 {
                        pageBreak
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 26)
    }

    private var pageBreak: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color(hex: "DCCBAA").opacity(0.6)).frame(height: 1)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "C9A96F").opacity(0.42))
                .frame(width: 4, height: 4)
                .rotationEffect(.degrees(45))
            Rectangle().fill(Color(hex: "DCCBAA").opacity(0.6)).frame(height: 1)
        }
        .frame(width: 168)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }

    private func journalPage(index: Int, group: (date: Date, records: [MoodRecord])) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 8) {
                Text(Self.dayFormatter.string(from: group.date))
                    .font(.system(.footnote, design: .serif).weight(.semibold))
                    .foregroundColor(Color(hex: "41301C"))

                Text("PAGE \(String(format: "%02d", index + 1))")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.8)
                    .foregroundColor(Color(hex: "A5834E").opacity(0.7))
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(hex: "DCCBAA"))
                .frame(height: 1)

            ForEach(Array(group.records.enumerated()), id: \.element.objectID) { index, record in
                archiveRecordRow(record)

                if index < group.records.count - 1 {
                    Rectangle()
                        .fill(Color(hex: "EFE4C9"))
                        .frame(height: 1)
                        .padding(.leading, 34)
                }
            }
        }
    }

    private func archiveRecordRow(_ record: MoodRecord) -> some View {
        let tags = MoodDataManager.tagNamesFromRecord(record)
        let note = record.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let time = record.createdAt.map { Self.timeFormatter.string(from: $0) } ?? "-"

        return HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 8) {
                Text(time)
                    .font(.system(size: 9, weight: .semibold, design: .serif).monospacedDigit())
                    .foregroundColor(Color(hex: "705A39"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .frame(minWidth: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(mood.color.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(mood.color.opacity(0.18), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 1)
                    .fill(mood.color.opacity(0.72))
                    .frame(width: 4, height: 4)
                    .rotationEffect(.degrees(45))

                VStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(Color(hex: "DCCBAA"))
                            .frame(width: 2, height: 2)
                    }
                }
            }
            .frame(width: 38)

            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .bottom) {
                    intensityInkMark(record.intensity)
                    Spacer()
                }

                if !tags.isEmpty {
                    FlowLayout(data: tags, spacing: 8) { tag in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(mood.color.opacity(0.58))
                                .frame(width: 3, height: 13)

                            Text(MoodDataManager.emojiForTagName(tag))

                            Text(MoodDataManager.displayName(forTagName: tag))
                                .font(.system(.caption2, design: .serif).weight(.medium))
                                .foregroundColor(Color(hex: "5E4A2F"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Color(hex: "FFFDF4")))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color(hex: "E4D3B2"), lineWidth: 1)
                        )
                    }
                }

                if let note, !note.isEmpty {
                    Text(note)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundColor(Color(hex: "433321").opacity(0.92))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, 18)
        }
    }

    private func intensityInkMark(_ value: Int16) -> some View {
        let filledCount = min(10, max(0, Int(Double(value).rounded())))

        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < filledCount ? mood.color.opacity(0.86) : Color(hex: "EFE3C8"))
                    .frame(width: 3, height: 5 + CGFloat(index) * 1.15)
            }
        }
        .padding(.bottom, 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: L.localized("profile.library_intensity_format"), filledCount))
    }

    private func loadRecords() {
        records = MoodDataManager.shared
            .fetchAllRecords()
            .filter { $0.createdAt != nil && MoodType.from(rawValue: $0.moodType) == mood }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let compactDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct BookmarkRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.65))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
