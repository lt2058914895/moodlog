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
        .padding(.top, 12)
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
            Text(L.localized("insight.mood_distribution"))
                .font(.subheadline.bold())

            if viewModel.pieChartData.isEmpty {
                emptyState(text: L.localized("insight.no_distribution_data"))
            } else {
                HStack(spacing: 16) {
                    // 饼图
                    MoodPieChart(data: viewModel.pieChartData)
                        .frame(width: 150, height: 150)

                    // 图例
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(viewModel.pieChartData) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.moodType.color)
                                    .frame(width: 10, height: 10)
                                Text("\(item.moodType.emoji) \(item.moodType.displayName)")
                                    .font(.caption2)
                                Spacer()
                                Text(String(format: "%.0f%%", item.percentage))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 标签频次卡片
    private var tagBarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.localized("insight.tag_frequency"))
                .font(.subheadline.bold())

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

// MARK: - 情绪分布饼图
struct MoodPieChart: View {
    let data: [PieChartData]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            let total = data.reduce(0) { $0 + $1.value }

            var startAngle: Double = -Double.pi / 2

            for item in data {
                let angle = Double(item.value) / Double(total) * 2 * Double.pi
                let endAngle = startAngle + angle

                let path = Path { p in
                    p.move(to: center)
                    p.addArc(center: center, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
                    p.closeSubpath()
                }

                context.fill(path, with: .color(item.moodType.color))
                startAngle = endAngle
            }

            // 中心圆（甜甜圈效果）
            let innerPath = Path { p in
                p.addArc(center: center, radius: radius * 0.4, startAngle: .zero, endAngle: Angle(radians: 2 * Double.pi), clockwise: false)
            }
            context.fill(innerPath, with: .color(Color(UIColor.secondarySystemGroupedBackground)))
        }
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