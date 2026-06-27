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
            VStack(spacing: 20) {
                // 时间段选择
                periodPicker

                // 统计概览卡片
                statsOverview

                // 情绪趋势图
                trendChartCard

                // 情绪分布饼图
                distributionCard

                // 标签频次柱状图
                tagBarCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L.localized("insight.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 时间段选择
    private var periodPicker: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(InsightPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        viewModel.selectedPeriod = period
                        viewModel.loadData()
                    }) {
                        Text(period.displayName)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.selectedPeriod == period
                                    ? Color(hex: "6C5CE7")
                                    : Color.clear
                            )
                            .foregroundColor(
                                viewModel.selectedPeriod == period
                                    ? .white
                                    : Color(hex: "6C5CE7")
                            )
                            .cornerRadius(10)
                    }
                }
            }
            .padding(4)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // 年份选择器（仅在选择"年"时显示）
            if viewModel.selectedPeriod == .year {
                yearPicker
            }
        }
        .padding(.top, 12)
    }

    // MARK: - 年份选择器
    private var yearPicker: some View {
        HStack(spacing: 12) {
            // 左箭头（切换到更早的年份）
            Button(action: {
                viewModel.selectedYear -= 1
                viewModel.loadData()
            }) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(viewModel.canGoPreviousYear ? Color(hex: "6C5CE7") : Color.gray.opacity(0.3))
            }
            .disabled(!viewModel.canGoPreviousYear)

            Spacer()

            // 年份显示
            Text("\(viewModel.selectedYear)\(L.localized("insight.year_unit"))")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // 右箭头（切换到更近的年份）
            Button(action: {
                viewModel.selectedYear += 1
                viewModel.loadData()
            }) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(viewModel.canGoNextYear ? Color(hex: "6C5CE7") : Color.gray.opacity(0.3))
            }
            .disabled(!viewModel.canGoNextYear)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - 统计概览
    private var statsOverview: some View {
        HStack(spacing: 12) {
            StatCard(
                title: L.localized("insight.record_count"),
                value: "\(viewModel.totalRecords)",
                icon: "pencil.circle.fill",
                color: Color(hex: "6C5CE7")
            )
            StatCard(
                title: L.localized("insight.avg_intensity"),
                value: String(format: "%.1f", viewModel.averageIntensity),
                icon: "chart.bar.fill",
                color: Color(hex: "00B894")
            )
            StatCard(
                title: L.localized("insight.most_mood"),
                value: viewModel.mostFrequentMood.emoji,
                icon: "heart.fill",
                color: viewModel.mostFrequentMood.color
            )
        }
    }

    // MARK: - 趋势图卡片
    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.localized("insight.mood_trend"))
                    .font(.subheadline.bold())
                Spacer()
                Text(viewModel.periodTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.chartDataPoints.isEmpty {
                emptyState(text: L.localized("insight.no_trend_data"))
            } else {
                MoodTrendChart(dataPoints: viewModel.chartDataPoints)
                    .frame(height: 200)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 情绪分布卡片
    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.localized("insight.mood_distribution"))
                    .font(.subheadline.bold())
                Spacer()
                Text(viewModel.periodTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.pieChartData.isEmpty {
                emptyState(text: L.localized("insight.no_distribution_data"))
            } else {
                // 情绪轮（普拉奇克风格）
                MoodEmotionWheel(data: viewModel.pieChartData, totalRecords: viewModel.totalRecords)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 标签频次卡片
    private var tagBarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.localized("insight.tag_frequency"))
                    .font(.subheadline.bold())
                Spacer()
                Text(viewModel.periodTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.tagBarData.isEmpty {
                emptyState(text: L.localized("insight.no_tag_data"))
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.tagBarData) { tag in
                        TagBarRow(data: tag)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 空状态
    private func emptyState(text: String) -> some View {
        VStack(spacing: 8) {
            Text("📊")
                .font(.title)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 情绪趋势折线图
struct MoodTrendChart: View {
    let dataPoints: [ChartDataPoint]

    private let lineWidth: CGFloat = 2.5
    private let pointSize: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 30

            ZStack {
                // Y轴刻度线
                VStack(spacing: 0) {
                    ForEach([10, 7, 4, 1], id: \.self) { value in
                        HStack {
                            Text("\(value)")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .frame(width: 20, alignment: .trailing)
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 0.5)
                            Spacer()
                        }
                        .frame(height: (height - padding * 2) / 3)
                    }
                }

                // 折线
                if dataPoints.count >= 2 {
                    let chartWidth = width - padding - 20
                    let chartHeight = height - padding * 2

                    Path { path in
                        for (index, point) in dataPoints.enumerated() {
                            let x = padding + 20 + (CGFloat(index) / CGFloat(max(dataPoints.count - 1, 1))) * chartWidth
                            let y = padding + chartHeight - ((point.value - 1) / 9) * chartHeight

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )

                    // 数据点
                    ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                        let x = padding + 20 + (CGFloat(index) / CGFloat(max(dataPoints.count - 1, 1))) * chartWidth
                        let y = padding + chartHeight - ((point.value - 1) / 9) * chartHeight

                        Circle()
                            .fill(Color(hex: "6C5CE7"))
                            .frame(width: pointSize, height: pointSize)
                            .position(x: x, y: y)
                    }

                    // X轴标签
                    ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                        if dataPoints.count <= 7 || index % (dataPoints.count / 7 + 1) == 0 {
                            let x = padding + 20 + (CGFloat(index) / CGFloat(max(dataPoints.count - 1, 1))) * chartWidth
                            Text(point.label)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .position(x: x, y: height - 8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 情绪轮（普拉奇克风格）
struct MoodEmotionWheel: View {
    let data: [PieChartData]
    let totalRecords: Int
    @State private var animatedProgress: Double = 0

    private let gapAngle: Double = 0.04
    private let innerRatio: CGFloat = 0.35
    private let shadowOffset: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = min(geometry.size.width, geometry.size.height) / 2 - 36
            let innerRadius = outerRadius * innerRatio
            let total = data.reduce(0) { $0 + $1.value }

            ZStack {
                // 阴影层
                Canvas { context, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let r = min(size.width, size.height) / 2 - 36
                    let ir = r * innerRatio
                    var startAngle: Double = -Double.pi / 2

                    for item in data {
                        let angle = Double(item.value) / Double(total) * 2 * Double.pi * animatedProgress
                        let endAngle = startAngle + angle
                        let sliceStart = startAngle + gapAngle / 2
                        let sliceEnd = endAngle - gapAngle / 2
                        guard sliceEnd > sliceStart else { startAngle = endAngle; continue }

                        let path = Path { p in
                            p.addArc(center: c, radius: r, startAngle: Angle(radians: sliceStart), endAngle: Angle(radians: sliceEnd), clockwise: false)
                            p.addArc(center: c, radius: ir, startAngle: Angle(radians: sliceEnd), endAngle: Angle(radians: sliceStart), clockwise: true)
                            p.closeSubpath()
                        }
                        context.fill(path, with: .color(item.moodType.color.opacity(0.12)))
                        startAngle = endAngle
                    }
                }
                .blur(radius: 8)
                .offset(y: shadowOffset)
                .opacity(0.5)

                // 主环形扇区
                Canvas { context, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let r = min(size.width, size.height) / 2 - 36
                    let ir = r * innerRatio
                    var startAngle: Double = -Double.pi / 2

                    for item in data {
                        let angle = Double(item.value) / Double(total) * 2 * Double.pi * animatedProgress
                        let endAngle = startAngle + angle
                        let sliceStart = startAngle + gapAngle / 2
                        let sliceEnd = endAngle - gapAngle / 2
                        guard sliceEnd > sliceStart else { startAngle = endAngle; continue }

                        let path = Path { p in
                            p.addArc(center: c, radius: r, startAngle: Angle(radians: sliceStart), endAngle: Angle(radians: sliceEnd), clockwise: false)
                            p.addArc(center: c, radius: ir, startAngle: Angle(radians: sliceEnd), endAngle: Angle(radians: sliceStart), clockwise: true)
                            p.closeSubpath()
                        }
                        context.fill(path, with: .color(item.moodType.color))
                        startAngle = endAngle
                    }
                }

                // 扇区标签（emoji + 百分比）
                ForEach(Array(data.enumerated()), id: \.element.id) { i, item in
                    let angle = sectorAngle(for: i, total: total)
                    let midRadius = (outerRadius + innerRadius) / 2
                    let labelX = center.x + midRadius * CGFloat(cos(angle))
                    let labelY = center.y + midRadius * CGFloat(sin(angle))

                    VStack(spacing: 0) {
                        Text(item.moodType.emoji)
                            .font(.system(size: 16))
                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .opacity(animatedProgress > 0.5 ? 1 : 0)
                    .position(x: labelX, y: labelY)
                }

                // 中心圆
                Circle()
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .frame(width: innerRadius * 2 - 4, height: innerRadius * 2 - 4)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                // 中心文字
                VStack(spacing: 2) {
                    Text("\(totalRecords)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(L.localized("insight.record_count"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                // 外圈标签（情绪名称）
                ForEach(Array(data.enumerated()), id: \.element.id) { i, item in
                    let angle = sectorAngle(for: i, total: total)
                    let labelR = outerRadius + 22
                    let labelX = center.x + labelR * CGFloat(cos(angle))
                    let labelY = center.y + labelR * CGFloat(sin(angle))

                    Text(item.moodType.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(item.moodType.color)
                        .lineLimit(1)
                        .fixedSize()
                        .position(x: labelX, y: labelY)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = 1.0
                }
            }
        }
    }

    private func sectorAngle(for index: Int, total: Int) -> Double {
        var angle = -Double.pi / 2
        for i in 0...index {
            let sliceAngle = Double(data[i].value) / Double(total) * 2 * Double.pi
            if i < index {
                angle += sliceAngle
            } else {
                angle += sliceAngle / 2
            }
        }
        return angle
    }
}

// MARK: - 标签柱状图行
struct TagBarRow: View {
    let data: TagBarData

    var body: some View {
        HStack(spacing: 8) {
            Text(data.name)
                .font(.caption)
                .frame(width: 60, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 16)

                    // 数据条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(CGFloat(data.ratio) * geometry.size.width, 4), height: 16)
                }
            }
            .frame(height: 16)

            Text("\(data.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationView {
        MoodInsightView()
    }
}