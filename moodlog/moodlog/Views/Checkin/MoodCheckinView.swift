//
//  MoodCheckinView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 情绪打卡主页面
struct MoodCheckinView: View {
    @StateObject private var viewModel = MoodCheckinViewModel()
    @StateObject private var dataManager = MoodDataManager.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 标题区域
                headerSection

                // 情绪选择器
                MoodSelectorView(viewModel: viewModel)

                // 情绪强度滑块
                if viewModel.selectedMoodType != nil {
                    IntensitySliderView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 活动标签选择
                if viewModel.selectedMoodType != nil {
                    TagSelectorView(viewModel: viewModel, dataManager: dataManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 记录按钮
                if viewModel.selectedMoodType != nil {
                    submitButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedMoodType != nil)
        .overlay {
            if viewModel.showSuccessAnimation {
                SuccessOverlayView {
                    viewModel.showSuccessAnimation = false
                }
            }
        }
        .alert(L.localized("checkin.alert_title"), isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(L.localized("checkin.alert_ok")) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(L.localized("checkin.title"))
                .font(.title2.bold())
                .foregroundColor(.primary)

            Text(L.localized("checkin.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - 提交按钮
    private var submitButton: some View {
        Button(action: viewModel.submitRecord) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text(L.localized("checkin.submit"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.top, 8)
    }
}

// MARK: - 情绪选择器
struct MoodSelectorView: View {
    @ObservedObject var viewModel: MoodCheckinViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(spacing: 16) {
            // 一级情绪网格
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MoodType.allCases, id: \.self) { moodType in
                    MoodTypeCell(
                        moodType: moodType,
                        isSelected: viewModel.selectedMoodType == moodType,
                        onTap: { viewModel.selectMoodType(moodType) }
                    )
                }
            }

            // 二级情绪选择
            if viewModel.showSubMoods, let moodType = viewModel.selectedMoodType {
                SubMoodSelectorView(
                    moodType: moodType,
                    selectedSubType: viewModel.selectedMoodSubType,
                    onSelect: { viewModel.selectMoodSubType($0) }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showSubMoods)
    }
}

// MARK: - 一级情绪单元格
struct MoodTypeCell: View {
    let moodType: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(moodType.emoji)
                    .font(.system(size: isSelected ? 40 : 32))
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(moodType.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? moodType.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? moodType.color.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? moodType.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 二级情绪选择器
struct SubMoodSelectorView: View {
    let moodType: MoodType
    let selectedSubType: MoodSubType?
    let onSelect: (MoodSubType) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(L.localized("checkin.describe_feeling"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            FlowLayout(data: moodType.subTypes, spacing: 8) { subType in
                SubMoodChip(
                    subType: subType,
                    isSelected: selectedSubType == subType,
                    color: moodType.color,
                    onTap: { onSelect(subType) }
                )
            }
        }
    }
}

// MARK: - 二级情绪标签
struct SubMoodChip: View {
    let subType: MoodSubType
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(subType.displayName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color(UIColor.secondarySystemGroupedBackground))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                )
                .foregroundColor(isSelected ? color : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 情绪强度滑块
struct IntensitySliderView: View {
    @ObservedObject var viewModel: MoodCheckinViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.intensity"))
                    .font(.subheadline.bold())
                Spacer()
                Text("\(viewModel.intensity)")
                    .font(.title2.bold())
                    .foregroundColor(intensityGradientColor)
            }

            Slider(value: Binding(
                get: { Double(viewModel.intensity) },
                set: { viewModel.intensity = Int($0) }
            ), in: 1...10, step: 1)
            .tint(intensityGradientColor)

            HStack {
                Text(L.localized("checkin.intensity.light"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(L.localized("checkin.intensity.strong"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var intensityGradientColor: Color {
        let colors = viewModel.intensityColor
        if viewModel.intensity <= 3 {
            return colors.start.color
        } else if viewModel.intensity <= 6 {
            return colors.end.color
        } else {
            return colors.end.color
        }
    }
}

// MARK: - 活动标签选择器
struct TagSelectorView: View {
    @ObservedObject var viewModel: MoodCheckinViewModel
    @ObservedObject var dataManager: MoodDataManager
    @State private var selectedCategory: TagCategory = .relationship
    @State private var frequentTags: [ActivityTag] = []

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.activity_tags"))
                    .font(.subheadline.bold())
                Spacer()
                Button(action: { viewModel.showAllTags.toggle() }) {
                    Text(viewModel.showAllTags ? L.localized("checkin.collapse") : L.localized("checkin.more"))
                        .font(.caption)
                        .foregroundColor(Color(hex: "6C5CE7"))
                }
            }

            if viewModel.showAllTags {
                // 分类标签 - Tab切换
                categoryTabView
            } else {
                // 常用标签
                frequentTagsView
            }

            if !viewModel.selectedTagNames.isEmpty {
                selectedTagsPreview
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .task {
            frequentTags = dataManager.fetchFrequentTags()
        }
    }

    // MARK: - 常用标签
    private var frequentTagsView: some View {
        FlowLayout(data: frequentTags, spacing: 8) { tag in
            TagChip(
                emoji: tag.emoji ?? "📋",
                name: tag.name ?? "",
                isSelected: viewModel.isTagSelected(tag.name ?? ""),
                color: Color(hex: "6C5CE7"),
                onTap: { viewModel.toggleTag(tag.name ?? "") }
            )
        }
    }

    // MARK: - 分类标签Tab视图
    private var categoryTabView: some View {
        VStack(spacing: 0) {
            // 一级分类 - 流式换行
            VStack(alignment: .leading, spacing: 8) {
                Text(L.localized("checkin.category_title"))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                FlowLayout(data: Array(TagCategory.allCases), spacing: 8) { category in
                    CategoryPill(
                        emoji: category.emoji,
                        name: category.displayName,
                        isSelected: selectedCategory == category,
                        onTap: { selectedCategory = category }
                    )
                }
            }
            .padding(.bottom, 12)

            // 分隔线
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, -4)

            // 二级标签 - 流式换行
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(selectedCategory.emoji)
                        .font(.caption2)
                    Text(selectedCategory.displayName)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "6C5CE7"))
                }

                FlowLayout(data: selectedCategory.presetTags, spacing: 8) { preset in
                    TagChip(
                        emoji: preset.emoji,
                        name: preset.name,
                        isSelected: viewModel.isTagSelected(preset.name),
                        color: Color(hex: "6C5CE7"),
                        onTap: { viewModel.toggleTag(preset.name) }
                    )
                }
            }
            .padding(.top, 12)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedCategory)
    }

    // MARK: - 已选标签预览
    private var selectedTagsPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L.localizedInt("checkin.selected_count", value: viewModel.selectedTagNames.count))
                .font(.caption2)
                .foregroundColor(.secondary)

            FlowLayout(data: viewModel.selectedTagNames, spacing: 6) { name in
                SelectedTagChip(name: name) {
                    viewModel.toggleTag(name)
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - 一级分类标签（大号胶囊，视觉层级高于二级标签）
struct CategoryPill: View {
    let emoji: String
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 15))
                Text(name)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "6C5CE7").opacity(0.12) : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(hex: "6C5CE7") : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? Color(hex: "6C5CE7") : .primary)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - 二级标签芯片（小号胶囊，视觉层级低于一级分类）
struct TagChip: View {
    let emoji: String
    let name: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 11))
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.12) : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color.opacity(0.6) : Color.clear, lineWidth: 1)
            )
            .foregroundColor(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 已选标签芯片
struct SelectedTagChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption2)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color(hex: "6C5CE7").opacity(0.1)))
        .foregroundColor(Color(hex: "6C5CE7"))
    }
}

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

// MARK: - 成功动画覆盖层
struct SuccessOverlayView: View {
    let onDismiss: () -> Void
    @State private var showCheckmark = false
    @State private var showText = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "00B894"))
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .opacity(showCheckmark ? 1 : 0)

                Text(L.localized("checkin.success"))
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .opacity(showText ? 1 : 0)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 20)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                showText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}

#Preview {
    MoodCheckinView()
}