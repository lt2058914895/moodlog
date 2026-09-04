//
//  FlowLayout.swift
//  moodlog
//
//  从 MoodCheckinView.swift 拆分而来
//

import SwiftUI

// MARK: - 流式布局（iOS 15兼容，支持自动换行）
/// 基于数据数组的流式布局，标签超出宽度自动换行
/// 使用 alignmentGuide + offset 实现真正的流式换行，高度自适应
struct FlowLayout<Data: Hashable, ItemContent: View>: View {
    let data: [Data]
    var spacing: CGFloat = 8
    let content: (Data) -> ItemContent

    var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayoutLayout(spacing: spacing) {
                ForEach(data, id: \.self) { item in
                    content(item)
                }
            }
        } else {
            FlowLayoutFallback(data: data, spacing: spacing, content: content)
        }
    }
}

// MARK: - iOS 16+ Layout 协议实现
@available(iOS 16.0, *)
private struct FlowLayoutLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + rowHeight
        }

        return (positions, CGSize(width: maxWidth == .infinity ? currentX : maxWidth, height: totalHeight))
    }
}

// MARK: - iOS 15 兼容的流式布局（使用 VStack + HStack 手动分行）
private struct FlowLayoutFallback<Data: Hashable, ItemContent: View>: View {
    let data: [Data]
    var spacing: CGFloat = 8
    let content: (Data) -> ItemContent

    @State private var itemWidths: [AnyHashable: CGFloat] = [:]
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        let rows = computeRows()
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(rows[rowIndex], id: \.self) { item in
                        content(item)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.onAppear {
                                        itemWidths[AnyHashable(item)] = proxy.size.width
                                    }
                                    .onChange(of: proxy.size.width) { newWidth in
                                        itemWidths[AnyHashable(item)] = newWidth
                                    }
                                }
                            )
                    }
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.onAppear { containerWidth = proxy.size.width }
                .onChange(of: proxy.size.width) { newWidth in
                    containerWidth = newWidth
                }
            }
        )
        .onChange(of: data) { _ in
            itemWidths.removeAll()
        }
    }

    private func computeRows() -> [[Data]] {
        guard containerWidth > 0 else { return [data] }
        var rows: [[Data]] = []
        var currentRow: [Data] = []
        var currentRowWidth: CGFloat = 0

        for item in data {
            let itemWidth = itemWidths[AnyHashable(item)] ?? 80
            let neededWidth = currentRow.isEmpty ? itemWidth : currentRowWidth + spacing + itemWidth
            if neededWidth > containerWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [item]
                currentRowWidth = itemWidth
            } else {
                currentRow.append(item)
                currentRowWidth = neededWidth
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows.isEmpty ? [data] : rows
    }
}
