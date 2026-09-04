//
//  FlowLayout.swift
//  moodlog
//
//  从 MoodCheckinView.swift 拆分而来
//

import SwiftUI

// MARK: - 流式布局
/// 基于数据数组的流式布局，标签超出宽度自动换行
/// 使用 alignmentGuide + offset 实现真正的流式换行，高度自适应
struct FlowLayout<Data: Hashable, ItemContent: View>: View {
    let data: [Data]
    var spacing: CGFloat = 8
    let content: (Data) -> ItemContent

    var body: some View {
        FlowLayoutLayout(spacing: spacing) {
            ForEach(data, id: \.self) { item in
                content(item)
            }
        }
    }
}

// MARK: - Layout 协议实现
struct FlowLayoutLayout: Layout {
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
