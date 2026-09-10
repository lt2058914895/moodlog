//
//  MoodLibraryView.swift
//  moodlog
//
//  Created by deppon on 2026/9/10.
//

import SwiftUI

/// 情绪图书馆：八本情绪集组成一座私人的情绪档案馆
struct MoodLibraryView: View {
    private let manager = MoodDataManager.shared

    @Environment(\.dismiss) private var dismiss

    @State private var books: [MoodBookStats] = MoodType.allCases.map {
        MoodBookStats(mood: $0, count: 0, averageIntensity: 0, latestDate: nil)
    }
    @State private var selectedBook: MoodBookStats?

    private var recordCount: Int {
        books.reduce(0) { $0 + $1.count }
    }

    private var openedBookCount: Int {
        books.filter { $0.count > 0 }.count
    }

    private var dominantBook: MoodBookStats? {
        books.filter { $0.count > 0 }.max { $0.count < $1.count }
    }

    var body: some View {
        ZStack {
            archiveBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    archiveHeader
                    volumeSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 44)
            }
        }
        .navigationTitle(L.localized("profile.library_nav_title"))
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
        .sheet(item: $selectedBook) { book in
            MoodBookDetailView(stats: book)
        }
        .task { loadBookStats() }
        .onReceive(NotificationCenter.default.publisher(for: .moodDataDidChange)) { _ in
            loadBookStats()
        }
    }

    private var archiveBackground: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)

            LinearGradient(
                colors: [
                    Color("AccentColor").opacity(0.10),
                    Color(hex: "E9C97C").opacity(0.08),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color("AccentColor").opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: 145, y: -135)
                .blur(radius: 32)
        }
        .ignoresSafeArea()
    }

    private var archiveHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "books.vertical.fill")
                        .font(.headline)
                        .foregroundColor(Color("AccentColor"))
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color("AccentColor").opacity(0.12)))
                        .overlay(Circle().stroke(Color("AccentColor").opacity(0.18)))

                    VStack(alignment: .leading, spacing: 7) {
                    Text(L.localized("profile.library_page_subtitle"))
                        .font(.headline)
                        .foregroundColor(.primary)

                        Text(L.localized("profile.library_archive_intro"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }

            HStack(spacing: 10) {
                archiveStat(
                    title: L.localized("profile.library_total"),
                    value: "\(recordCount)"
                )

                archiveStat(
                    title: L.localized("profile.library_stat_opened"),
                    value: "\(openedBookCount)/8"
                )

                archiveStat(
                    title: L.localized("profile.library_stat_dominant"),
                    value: dominantBook?.mood.displayName ?? L.localized("profile.library_empty")
                )
            }
        }
        .padding(22)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color("AccentColor").opacity(0.20), Color(hex: "E9C97C").opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func archiveStat(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Capsule().fill(Color(UIColor.systemGroupedBackground)))
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L.localized("profile.library_shelf_title"))
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(L.localized("profile.library_shelf_subtitle"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 2)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 22),
                    GridItem(.flexible())
                ],
                spacing: 28
            ) {
                ForEach(books) { book in
                    shelfCell(book)
                }
            }
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                .shelfBackgroundTop,
                                .shelfBackgroundMiddle,
                                .shelfBackgroundBottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    Circle()
                        .fill(Color.shelfDecorationTop.opacity(0.08))
                        .frame(width: 210, height: 210)
                        .offset(x: -105, y: -72)
                        .blur(radius: 28)

                    Circle()
                        .stroke(Color.shelfDecorationLine.opacity(0.12), lineWidth: 1)
                        .frame(width: 260, height: 260)
                        .offset(x: 122, y: 112)

                    Circle()
                        .fill(Color.shelfDecorationBottom.opacity(0.07))
                        .frame(width: 240, height: 240)
                        .offset(x: 128, y: 130)
                        .blur(radius: 34)

                    VStack(spacing: 34) {
                        ForEach(0..<7, id: \.self) { index in
                            Capsule()
                                .fill(Color.shelfDecorationLine.opacity(index % 2 == 0 ? 0.06 : 0.03))
                                .frame(height: 1)
                        }
                    }
                    .padding(.horizontal, 28)
                    .opacity(0.7)
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.shelfBorderTop, .shelfBorderBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.14), radius: 22, y: 10)
        }
    }

    private func shelfCell(_ book: MoodBookStats) -> some View {
        VStack(spacing: 12) {
            bookButton(book)
                .frame(maxWidth: 134)
                .aspectRatio(0.68, contentMode: .fit)

            Ellipse()
                .fill(Color.black.opacity(0.07))
                .frame(height: 9)
                .blur(radius: 7)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: 134, alignment: .center)
    }

    private func bookButton(_ book: MoodBookStats) -> some View {
        Button {
            selectedBook = book
        } label: {
            MoodBookCover(stats: book)
        }
        .buttonStyle(.plain)
    }

    private func loadBookStats() {
        let records = manager.fetchAllRecords()
        var statsByMood: [MoodType: (count: Int, intensityTotal: Int, latestDate: Date?)] = [:]

        for record in records {
            let mood = MoodType.from(rawValue: record.moodType)
            let current = statsByMood[mood] ?? (0, 0, nil)
            let createdAt = record.createdAt

            statsByMood[mood] = (
                current.count + 1,
                current.intensityTotal + Int(record.intensity),
                max(current.latestDate ?? .distantPast, createdAt ?? .distantPast)
            )
        }

        books = MoodType.allCases.map { mood in
            let stats = statsByMood[mood]
            let count = stats?.count ?? 0

            return MoodBookStats(
                mood: mood,
                count: count,
                averageIntensity: count == 0 ? 0 : Double(stats?.intensityTotal ?? 0) / Double(count),
                latestDate: count == 0 ? nil : stats?.latestDate
            )
        }
    }
}

// MARK: - 差异化封面

private struct MoodBookCover: View {
    let stats: MoodBookStats

    private var mood: MoodType { stats.mood }

    private var usesDeepCover: Bool {
        mood == .happy || mood == .sad
    }

    private var background: some View {
        Rectangle()
            .fill(coverColor)
    }

    private var coverColor: Color {
        switch mood {
        case .happy:
            return Color(hex: "C89431")
        case .sad:
            return Color(hex: "5277A8")
        case .angry:
            return Color(hex: "C25A4D")
        case .anxious:
            return Color(hex: "C27536")
        case .neutral:
            return Color(hex: "818781")
        case .afraid:
            return Color(hex: "6F59A1")
        case .tired:
            return Color(hex: "8A6350")
        case .relaxed:
            return Color(hex: "529570")
        }
    }

    private var spineColor: Color {
        switch mood {
        case .happy: return Color(hex: "B2862F")
        case .sad: return Color(hex: "4E719F")
        case .angry: return Color(hex: "B35449")
        case .anxious: return Color(hex: "AF6B2F")
        case .neutral: return Color(hex: "747B74")
        case .afraid: return Color(hex: "654E91")
        case .tired: return Color(hex: "7B5947")
        case .relaxed: return Color(hex: "488A65")
        }
    }

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .aspectRatio(0.68, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    let spineWidth = proxy.size.width * 0.10
                    let pageWidth = proxy.size.width * 0.055
                    let contentWidth = proxy.size.width - spineWidth - pageWidth

                    ZStack {
                        background
                        coverMotifs
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .opacity(coverMotifOpacity)
                        mysticMarks
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                        coverTexture
                            .opacity(usesDeepCover ? 0 : 0.8)

                        HStack(spacing: 0) {
                            bookSpine(width: spineWidth)
                            coverContent(width: contentWidth, height: proxy.size.height)
                                .clipped()
                            bookPageEdge(width: pageWidth)
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: "3A2A1A").opacity(0.20), radius: 18, y: 12)
            .shadow(color: .black.opacity(0.14), radius: 12, y: 9)
        .opacity(stats.count == 0 ? 0.94 : 1)
    }

    private var coverMotifOpacity: Double {
        switch mood {
        case .happy: return 0.75
        case .sad: return 0.84
        default: return 1
        }
    }

    private var goldFoil: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "F6E4B8"),
                Color(hex: "D8B26A"),
                Color(hex: "FFF6DC")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var coverTexture: some View {
        Canvas { context, size in
            let spacing: CGFloat = 5
            var row = 0

            while CGFloat(row) * spacing < size.height {
                let y = CGFloat(row) * spacing
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y + spacing * 0.35))

                context.stroke(
                    path,
                    with: .color(.white.opacity(row.isMultiple(of: 2) ? 0.025 : 0.015)),
                    lineWidth: 1
                )

                row += 1
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .opacity(usesDeepCover ? 0 : 0.8)
    }

    private func bookSpine(width: CGFloat) -> some View {
        ZStack {
            spineColor

            LinearGradient(
                colors: [
                    .black.opacity(0.34),
                    .black.opacity(0.08),
                    .black.opacity(0.28)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            if !usesDeepCover {
                LinearGradient(
                    colors: [.white.opacity(0.18), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(width: width)
    }

    private func bookPageEdge(width: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color(hex: "FFF9EA"),
                Color(hex: "F0DDBC"),
                Color(hex: "D2B48C")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: width)
        .overlay {
            VStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.035))
                        .frame(height: 1)
                }
            }
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var coverMotifs: some View {
        switch mood {
        case .happy: sunRays
        case .sad: rainDrops
        case .angry: sharpShards
        case .anxious: restlessRings
        case .neutral: quietBands
        case .afraid: starBurst
        case .tired: heavyLayers
        case .relaxed: smoothWaves
        }
    }

    private var sunRays: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: "2B1A08").opacity(0.12))
                    .frame(width: 3, height: 104)
                    .offset(y: -88)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            Circle()
                .fill(Color(hex: "2B1A08").opacity(0.10))
                .frame(width: 112, height: 112)
        }
    }

    private var rainDrops: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Capsule()
                    .fill(Color(hex: "0E1B26").opacity(0.14))
                    .frame(width: 4, height: 24 + CGFloat(index % 3) * 13)
                    .offset(
                        x: -64 + CGFloat(index) * 18,
                        y: CGFloat([18, -30, 46, -12, 4, -40, 34, 68][index])
                    )
            }
        }
    }

    private var sharpShards: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 86, height: 7)
                    .rotationEffect(.degrees(Double(index) * 26 - 34))
                    .offset(
                        x: CGFloat([12, -24, 26, -8, 2, -14][index]),
                        y: CGFloat([-62, -20, 4, 38, 72, 92][index])
                    )
            }
        }
    }

    private var restlessRings: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1.4)
                    .frame(width: 60 + CGFloat(index) * 27, height: 60 + CGFloat(index) * 27)
            }
        }
    }

    private var quietBands: some View {
        VStack(spacing: 14) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index % 2 == 0 ? 0.20 : 0.09))
                    .frame(width: index % 2 == 0 ? 116 : 70, height: 4)
            }
        }
    }

    private var starBurst: some View {
        ZStack {
            ForEach(0..<22, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: CGFloat(index % 3) + 2, height: CGFloat(index % 3) + 2)
                    .offset(
                        x: CGFloat((index * 61) % 170) - 85,
                        y: CGFloat((index * 43) % 235) - 117
                    )
            }
        }
    }

    private var heavyLayers: some View {
        ZStack {
            Text("z z z")
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.34))
                .rotationEffect(.degrees(-8))
                .offset(x: 40, y: -74)

            VStack(spacing: 9) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 100 - CGFloat(index) * 13, height: 6)
                }
            }
        }
    }

    private var smoothWaves: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .trim(from: 0, to: 0.52)
                    .stroke(
                        Color.white.opacity(0.20),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 84 + CGFloat(index) * 34, height: 84 + CGFloat(index) * 34)
                    .rotationEffect(.degrees(Double(index) * 32))
            }
        }
    }

    private func coverContent(width: CGFloat, height: CGFloat) -> some View {
        let contentPadding = max(9, width * 0.075)
        let emblemSize = min(70, height * 0.31)
        let titleSize = max(15, min(20, width * 0.115))
        let englishLabelSize = max(7, min(9, width * 0.052))
        let countSize = max(9, min(12, width * 0.065))
        let barWidth = min(46, width * 0.30)

        return VStack(spacing: 0) {
            VStack(spacing: max(5, width * 0.028)) {
                coverOrnament(width: width)

                Text(L.localized("profile.library_archive_name"))
                    .font(.system(size: englishLabelSize, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.74))
                    .lineLimit(1)
                    .minimumScaleFactor(0.50)
            }

            Spacer(minLength: 8)

            VStack(spacing: max(6, height * 0.022)) {
                coverEmblem(size: emblemSize)

                Text(mood.displayName)
                    .font(.system(size: titleSize, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.60)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 8)

            VStack(spacing: max(6, height * 0.018)) {
                coverDotPattern(width: width)

                Rectangle()
                    .fill(goldFoil.opacity(0.36))
                    .frame(height: 1)

                HStack(spacing: 7) {
                    Text(stats.count == 0 ? L.localized("profile.library_unopened") : String(format: L.localized("profile.library_book_count_format"), stats.count))
                        .font(.system(size: countSize, weight: .semibold))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.60)

                    Spacer(minLength: 5)

                    Capsule()
                        .fill(Color.white.opacity(0.26))
                        .frame(width: barWidth, height: 4)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.90))
                                .frame(width: max(4, barWidth * stats.averageIntensity / 10))
                        }
                }
            }
        }
        .padding(.horizontal, contentPadding)
        .padding(.vertical, max(12, height * 0.055))
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
    }

    private func coverOrnament(width: CGFloat) -> some View {
        let lineWidth = max(16, width * 0.24)
        let circleSize = max(13, width * 0.09)
        let centerSize = max(7, width * 0.05)
        let diamondSize = max(4, width * 0.026)

        return VStack(spacing: max(6, width * 0.035)) {
            ZStack {
                Circle()
                    .fill(goldFoil.opacity(0.16))
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .stroke(goldFoil.opacity(0.52), lineWidth: 1)
                    .frame(width: centerSize, height: centerSize)
            }

            HStack(spacing: max(5, width * 0.035)) {
                Capsule()
                    .fill(goldFoil.opacity(0.38))
                    .frame(width: lineWidth, height: 1)

                RoundedRectangle(cornerRadius: 1)
                    .fill(goldFoil.opacity(0.48))
                    .frame(width: diamondSize, height: diamondSize)
                    .rotationEffect(.degrees(45))

                Capsule()
                    .fill(goldFoil.opacity(0.38))
                    .frame(width: lineWidth, height: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func coverDotPattern(width: CGFloat) -> some View {
        HStack(spacing: max(4, width * 0.032)) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(goldFoil.opacity(index == 2 ? 0.52 : 0.24))
                    .frame(width: index == 2 ? 3 : 2, height: index == 2 ? 3 : 2)
            }
        }
    }

    private func coverEmblem(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(usesDeepCover ? Color.black.opacity(0.18) : Color.white.opacity(0.13))

            Circle()
                .fill(usesDeepCover ? Color.black.opacity(0.10) : Color.white.opacity(0.05))
                .frame(width: size * 0.88, height: size * 0.88)

            Circle()
                .stroke(goldFoil.opacity(0.58), lineWidth: 1)

            Circle()
                .stroke(goldFoil.opacity(0.22), lineWidth: 1)
                .frame(width: size * 0.72, height: size * 0.72)

            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(goldFoil.opacity(index.isMultiple(of: 3) ? 0.56 : 0.26))
                    .frame(width: 1, height: size * 0.055)
                    .rotationEffect(.degrees(Double(index) * 30))
                    .offset(y: -size * 0.44)
            }

            Image(mood.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.62, height: size * 0.62)
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    private var mysticMarks: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.47)
            let radius = min(size.width, size.height)

            for (multiplier, opacity, dash) in [
                (0.36, 0.10, true),
                (0.52, 0.07, false),
                (0.66, 0.05, true)
            ] {
                var ring = Path()
                ring.addEllipse(in: CGRect(
                    x: center.x - radius * multiplier,
                    y: center.y - radius * multiplier,
                    width: radius * multiplier * 2,
                    height: radius * multiplier * 2
                ))
                context.stroke(
                    ring,
                    with: .color(.white.opacity(opacity)),
                    style: StrokeStyle(lineWidth: 1, dash: dash ? [2, 4] : [])
                )
            }

            let constellations = [
                [
                    CGPoint(x: size.width * 0.16, y: size.height * 0.21),
                    CGPoint(x: size.width * 0.25, y: size.height * 0.15),
                    CGPoint(x: size.width * 0.36, y: size.height * 0.22),
                    CGPoint(x: size.width * 0.29, y: size.height * 0.33)
                ],
                [
                    CGPoint(x: size.width * 0.70, y: size.height * 0.69),
                    CGPoint(x: size.width * 0.78, y: size.height * 0.76),
                    CGPoint(x: size.width * 0.72, y: size.height * 0.86)
                ]
            ]

            for constellation in constellations {
                var lines = Path()
                lines.addLines(constellation)
                context.stroke(lines, with: .color(.white.opacity(0.09)), lineWidth: 1)

                for point in constellation {
                    let dot = CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 3, height: 3)
                    context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.20)))
                }
            }

            let stars: [CGPoint] = [
                CGPoint(x: size.width * 0.79, y: size.height * 0.18),
                CGPoint(x: size.width * 0.20, y: size.height * 0.68),
                CGPoint(x: size.width * 0.82, y: size.height * 0.47)
            ]

            for star in stars {
                var spark = Path()
                spark.move(to: CGPoint(x: star.x, y: star.y - 5))
                spark.addLine(to: CGPoint(x: star.x + 1.5, y: star.y - 1.5))
                spark.addLine(to: CGPoint(x: star.x + 5, y: star.y))
                spark.addLine(to: CGPoint(x: star.x + 1.5, y: star.y + 1.5))
                spark.addLine(to: CGPoint(x: star.x, y: star.y + 5))
                spark.addLine(to: CGPoint(x: star.x - 1.5, y: star.y + 1.5))
                spark.addLine(to: CGPoint(x: star.x - 5, y: star.y))
                spark.addLine(to: CGPoint(x: star.x - 1.5, y: star.y - 1.5))
                spark.closeSubpath()
                context.fill(spark, with: .color(.white.opacity(0.20)))
            }
        }
        .allowsHitTesting(false)
        .opacity(0.72)
    }
}

// MARK: - 单本情绪集详情

private struct MoodBookDetailView: View {
    let stats: MoodBookStats

    @Environment(\.dismiss) private var dismiss
    @State private var records: [MoodRecord] = []

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
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        summaryCard
                        recordTimeline
                    }
                    .padding(18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(mood.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.localized("share.close")) {
                        dismiss()
                    }
                }
            }
            .task { loadRecords() }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(mood.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .padding(12)
                    .background(Circle().fill(mood.color.opacity(0.20)))

                VStack(alignment: .leading, spacing: 6) {
                    Text(L.localized("profile.library_detail_title"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(mood.color)

                    Text(mood.displayName)
                        .font(.title2.bold())
                }

                Spacer()
            }

            Text(summaryText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineSpacing(4)

            HStack(spacing: 10) {
                detailStat(title: L.localized("profile.library_book_count"), value: "\(stats.count)")
                detailStat(title: L.localized("profile.library_detail_intensity"), value: stats.count == 0 ? "-" : String(format: "%.1f/10", stats.averageIntensity))
                detailStat(title: L.localized("profile.library_book_latest"), value: stats.latestDate.map { Self.compactDateFormatter.string(from: $0) } ?? "-")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private var recordTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.localized("profile.library_timeline_title"))
                .font(.headline)
                .padding(.leading, 4)

            if groupedRecords.isEmpty {
                Text(L.localized("profile.library_timeline_empty"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
            } else {
                ForEach(groupedRecords, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(Self.dayFormatter.string(from: group.date))
                            .font(.footnote.bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)

                        ForEach(Array(group.records.enumerated()), id: \.element.objectID) { index, record in
                            archiveRecordRow(record)

                            if index < group.records.count - 1 {
                                Divider()
                                    .padding(.leading, 22)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
            }
        }
    }

    private func archiveRecordRow(_ record: MoodRecord) -> some View {
        let tags = MoodDataManager.tagNamesFromRecord(record)

        return HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 0) {
                Text(record.createdAt.map { Self.timeFormatter.string(from: $0) } ?? "-")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundColor(.secondary)

                Circle()
                    .fill(mood.color.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(String(format: L.localized("profile.library_intensity_format"), Int(record.intensity)))
                        .font(.caption.weight(.bold))
                        .foregroundColor(mood.color)

                    Spacer()

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(mood.color.opacity(0.15))
                            Capsule().fill(mood.color)
                                .frame(width: max(4, proxy.size.width * Double(record.intensity) / 10))
                        }
                    }
                    .frame(height: 5)
                    .frame(maxWidth: 74)
                }

                if !tags.isEmpty {
                    FlowLayout(data: tags, spacing: 7) { tag in
                        HStack(spacing: 4) {
                            Text(MoodDataManager.emojiForTagName(tag))
                            Text(tag)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(mood.color.opacity(0.10)))
                    }
                } else {
                    Text(L.localized("profile.library_no_tags"))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }

                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.86))
                        .lineSpacing(4)
                } else {
                    Text(L.localized("profile.library_no_note"))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
    }

    private func detailStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(Color(UIColor.systemGroupedBackground)))
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

private extension Color {
    static let shelfBackgroundTop = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
            : .white
    })

    static let shelfBackgroundMiddle = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 32 / 255, green: 32 / 255, blue: 36 / 255, alpha: 1)
            : .white
    })

    static let shelfBackgroundBottom = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 42 / 255, green: 42 / 255, blue: 46 / 255, alpha: 1)
            : UIColor(red: 252 / 255, green: 249 / 255, blue: 243 / 255, alpha: 1)
    })

    static let shelfDecorationTop = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 138 / 255, green: 118 / 255, blue: 86 / 255, alpha: 1)
            : UIColor(red: 226 / 255, green: 194 / 255, blue: 135 / 255, alpha: 1)
    })

    static let shelfDecorationLine = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 142 / 255, green: 122 / 255, blue: 93 / 255, alpha: 1)
            : UIColor(red: 185 / 255, green: 159 / 255, blue: 124 / 255, alpha: 1)
    })

    static let shelfDecorationBottom = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 110 / 255, green: 91 / 255, blue: 65 / 255, alpha: 1)
            : UIColor(red: 247 / 255, green: 232 / 255, blue: 200 / 255, alpha: 1)
    })

    static let shelfBorderTop = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor(red: 220 / 255, green: 194 / 255, blue: 148 / 255, alpha: 0.42)
    })

    static let shelfBorderBottom = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.05)
            : UIColor(red: 184 / 255, green: 154 / 255, blue: 116 / 255, alpha: 0.16)
    })

    static let shelfCellBackgroundTop = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 44 / 255, green: 44 / 255, blue: 48 / 255, alpha: 1)
            : UIColor(red: 239 / 255, green: 231 / 255, blue: 218 / 255, alpha: 1)
    })

    static let shelfCellBackgroundBottom = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 36 / 255, green: 36 / 255, blue: 40 / 255, alpha: 1)
            : UIColor(red: 226 / 255, green: 215 / 255, blue: 196 / 255, alpha: 1)
    })
}
