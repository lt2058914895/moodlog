//
//  MoodInsightView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 数据洞察主页面
struct MoodInsightView: View {
    @StateObject private var viewModel = InsightViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Hero 区域
                heroSection

                // 时间段切换（嵌入 Hero 下方）
                periodPicker

                // 统计概览
                statsOverview

                // 情绪分布
                distributionSection

                // 标签排行
                tagSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 60)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L.localized("insight.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero 区域
    private var heroSection: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                Text(heroTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if viewModel.totalRecords > 0 {
                if viewModel.isMoodSpread && viewModel.topTwoMoods.count >= 2 {
                    HStack(spacing: -8) {
                        Image(viewModel.topTwoMoods[0].imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        Image(viewModel.topTwoMoods[1].imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                } else {
                    Image(viewModel.mostFrequentMood.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: heroGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private var heroGradientColors: [Color] {
        if viewModel.isMoodSpread && viewModel.topTwoMoods.count >= 2 {
            let m1 = viewModel.topTwoMoods[0].color
            let m2 = viewModel.topTwoMoods[1].color
            return [m1.opacity(0.85), m2.opacity(0.7)]
        }
        let mood = viewModel.mostFrequentMood
        return [
            mood.color.opacity(0.85),
            mood.color.opacity(0.65)
        ]
    }

    private var greetingText: String {
        guard viewModel.totalRecords > 0 else {
            return L.localized("insight.empty_greeting")
        }
        return L.localized("insight.greeting")
    }

    private var heroTitle: String {
        guard viewModel.totalRecords > 0 else {
            return L.localized("insight.empty_title")
        }
        if viewModel.isMoodSpread {
            if viewModel.topTwoMoods.count >= 2 {
                return String(format: L.localized("insight.hero_spread_two"), viewModel.topTwoMoods[0].displayName, viewModel.topTwoMoods[1].displayName)
            } else {
                return L.localized("insight.hero_spread")
            }
        } else {
            return String(format: L.localized("insight.hero_title"), viewModel.mostFrequentMood.displayName)
        }
    }

    // MARK: - 时间段选择
    private var periodPicker: some View {
        VStack(spacing: 6) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(InsightTimeRange.allCases, id: \.self) { range in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedRange = range
                                    viewModel.loadData()
                                }
                            }) {
                                Text(range.displayName)
                                    .font(.subheadline.weight(viewModel.selectedRange == range ? .bold : .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(
                                            viewModel.selectedRange == range
                                                ? Color("AccentColor")
                                                : Color(UIColor.secondarySystemGroupedBackground)
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                viewModel.selectedRange == range
                                                    ? Color.clear
                                                    : Color(UIColor.separator).opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                    .foregroundColor(
                                        viewModel.selectedRange == range ? .white : .primary
                                    )
                            }
                            .id(range)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .onChange(of: viewModel.selectedRange) { newRange in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newRange, anchor: .center)
                    }
                }
            }

            if case .year = viewModel.selectedRange {
                yearPicker
            }
        }
        .padding(.top, 4)
    }

    // MARK: - 年份选择器
    private var yearPicker: some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.selectedYear -= 1
                viewModel.loadData()
            }) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(viewModel.canGoPreviousYear ? Color("AccentColor") : Color.gray.opacity(0.3))
            }
            .disabled(!viewModel.canGoPreviousYear)

            Spacer()

            Text("\(viewModel.selectedYear)\(L.localized("insight.year_unit"))")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                viewModel.selectedYear += 1
                viewModel.loadData()
            }) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(viewModel.canGoNextYear ? Color("AccentColor") : Color.gray.opacity(0.3))
            }
            .disabled(!viewModel.canGoNextYear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - 统计概览（紧凑信息条）
    private var statsOverview: some View {
        let hasData = viewModel.totalRecords > 0
        return HStack(spacing: 0) {
            statItem(
                value: hasData ? "\(viewModel.totalRecords)" : "--",
                label: L.localized("insight.record_count")
            )
            statDivider
            statItem(
                value: hasData ? String(format: "%.1f", viewModel.averageIntensity) : "--",
                label: L.localized("insight.avg_intensity")
            )
            statDivider
            statItem(
                value: hasData ? viewModel.mostFrequentMood.displayName : "--",
                label: L.localized("insight.most_mood")
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(value == "--" ? Color(UIColor.tertiaryLabel) : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color(UIColor.separator).opacity(0.3))
            .frame(width: 1, height: 28)
    }

    // MARK: - 情绪分布
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.localized("insight.mood_distribution"))
                    .font(.headline)
                Spacer()
                Text(viewModel.periodTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            if viewModel.pieChartData.isEmpty {
                emptyStateView(
                    image: "moon.stars",
                    text: L.localized("insight.no_distribution_data")
                )
            } else {
                HStack(spacing: 16) {
                    MoodDonutChart(data: viewModel.pieChartData, totalRecords: viewModel.totalRecords)
                        .frame(width: 180, height: 180)

                    MoodLegend(data: viewModel.pieChartData)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - 标签排行
    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.localized("insight.tag_frequency"))
                    .font(.headline)
                Spacer()
                Text(viewModel.periodTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)

            if viewModel.tagBarData.isEmpty {
                emptyStateView(
                    image: "tag",
                    text: L.localized("insight.no_tag_data")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.tagBarData.enumerated()), id: \.element.id) { index, tag in
                        TagBarRow(data: tag, rank: index + 1)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - 空状态
    private func emptyStateView(image: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: image)
                .font(.system(size: 32))
                .foregroundColor(Color("AccentColor").opacity(0.4))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - 情绪甜甜圈图
struct MoodDonutChart: View {
    let data: [PieChartData]
    let totalRecords: Int
    @State private var animatedProgress: Double = 1.0

    private let innerRatio: CGFloat = 0.62

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = size / 2 - 8
            let innerRadius = outerRadius * innerRatio
            let total = data.reduce(0) { $0 + $1.value }

            ZStack {
                // 背景轨道
                Circle()
                    .stroke(Color.gray.opacity(0.08), style: StrokeStyle(lineWidth: (outerRadius - innerRadius) / 2))
                    .frame(width: (outerRadius + innerRadius), height: (outerRadius + innerRadius))

                // 主环形
                Canvas { context, size in
                    guard total > 0 else { return }
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let r = outerRadius
                    let ir = innerRadius
                    let lineWidth = (r - ir) / 2
                    let midR = (r + ir) / 2
                    var startAngle: Double = -Double.pi / 2

                    for item in data {
                        let angle = Double(item.value) / Double(total) * 2 * Double.pi * animatedProgress
                        let endAngle = startAngle + angle

                        let path = Path { p in
                            p.addArc(center: c, radius: midR, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
                        }
                        context.stroke(
                            path,
                            with: .color(item.moodType.color),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        startAngle = endAngle
                    }
                }

                // 中心内容
                VStack(spacing: 4) {
                    Text("\(totalRecords)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(L.localized("insight.record_count"))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: data.count) { newValue in
            animateChart()
        }
    }

    private func animateChart() {
        animatedProgress = 0
        withAnimation(.easeOut(duration: 0.8)) {
            animatedProgress = 1.0
        }
    }
}

// MARK: - 情绪图例
struct MoodLegend: View {
    let data: [PieChartData]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(data) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.moodType.color)
                        .frame(width: 10, height: 10)
                    Text(item.moodType.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(String(format: "%.0f%%", item.percentage))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(item.moodType.color)
                }
            }
        }
    }
}

// MARK: - 标签柱状图行
struct TagBarRow: View {
    let data: TagBarData
    let rank: Int

    var body: some View {
        HStack(spacing: 10) {
            // 排名
            ZStack {
                Circle()
                    .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    .frame(width: 24, height: 24)
                Text("\(rank)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(rank <= 3 ? Color("AccentColor") : .secondary)
            }

            // 标签名
            Text(data.name)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 72, alignment: .leading)
                .lineLimit(1)

            // 条形图
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.08))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color("AccentColor"), Color("AccentLightColor")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(CGFloat(data.ratio) * geometry.size.width, 6), height: 12)
                }
            }
            .frame(height: 12)

            // 数量
            Text("\(data.count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color("AccentColor"))
                .frame(width: 32, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationView {
        MoodInsightView()
    }
}
