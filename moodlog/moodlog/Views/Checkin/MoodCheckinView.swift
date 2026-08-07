//
//  MoodCheckinView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 情绪记录主页面
struct MoodCheckinView: View {
    @StateObject private var viewModel = MoodCheckinViewModel()
    @StateObject private var dataManager = MoodDataManager.shared
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 标题区域
                headerSection

                // 连续打卡卡片
                streakCard

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

                // 备注
                if viewModel.selectedMoodType != nil {
                    noteField
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
        .onTapGesture {
            isNoteFocused = false
        }
        .onChange(of: dataManager.dataVersion) { _ in
            viewModel.refreshStats()
        }
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
            HStack(spacing: 8) {
                Image(viewModel.currentTimeImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)

                Text(viewModel.currentGreeting)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text(L.localized("checkin.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 48)
    }

    // MARK: - 状态卡片
    private var streakCard: some View {
        HStack(spacing: 12) {
            // 左侧：上次记录
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: lastRecordIcon)
                        .font(.system(size: 18))
                        .foregroundColor(lastRecordColor)
                    Text(lastRecordText)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                }
                Text(lastRecordSubtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 右侧：总记录数
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6C5CE7").colorSchemeAdapted)
                    Text("\(viewModel.totalRecords)")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                }
                Text(L.localized("checkin.total_records"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "6C5CE7").colorSchemeAdapted.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "6C5CE7").colorSchemeAdapted.opacity(0.2), lineWidth: 1)
        )
    }

    private var lastRecordIcon: String {
        if viewModel.totalRecords == 0 {
            return "heart.fill"
        } else if viewModel.daysSinceLastRecord == 0 {
            return "checkmark.circle.fill"
        } else if viewModel.daysSinceLastRecord <= 3 {
            return "clock.fill"
        } else {
            return "arrow.clockwise"
        }
    }

    private var lastRecordColor: Color {
        if viewModel.totalRecords == 0 {
            return Color(hex: "6C5CE7").colorSchemeAdapted
        } else if viewModel.daysSinceLastRecord == 0 {
            return Color(hex: "00B894").colorSchemeAdapted
        } else if viewModel.daysSinceLastRecord <= 3 {
            return Color(hex: "F39C12").colorSchemeAdapted
        } else {
            return Color(hex: "5B8FB9").colorSchemeAdapted
        }
    }

    private var lastRecordText: String {
        if viewModel.totalRecords == 0 {
            return L.localized("checkin.first_record")
        } else if viewModel.daysSinceLastRecord == 0 {
            return L.localized("checkin.recorded_today")
        } else if viewModel.daysSinceLastRecord == 1 {
            return L.localized("checkin.recorded_yesterday")
        } else {
            return String(format: L.localized("checkin.recorded_days_ago"), viewModel.daysSinceLastRecord)
        }
    }

    private var lastRecordSubtitle: String {
        if viewModel.totalRecords == 0 {
            return L.localized("checkin.record_subtitle_first")
        } else if viewModel.daysSinceLastRecord == 0 {
            return L.localized("checkin.record_subtitle_today")
        } else {
            return L.localized("checkin.record_subtitle_return")
        }
    }

    // MARK: - 备注
    private var noteField: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.note_title"))
                    .font(.subheadline.bold())
                Spacer()
            }

            if #available(iOS 16.0, *) {
                TextField("", text: $viewModel.note, prompt: Text(L.localized("checkin.note_placeholder")).foregroundColor(.secondary), axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
                    .focused($isNoteFocused)
            } else {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.note)
                        .font(.subheadline)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                        .focused($isNoteFocused)

                    if viewModel.note.isEmpty {
                        Text(L.localized("checkin.note_placeholder"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
                    colors: [Color(hex: "6C5CE7").colorSchemeAdapted, Color(hex: "A29BFE").colorSchemeAdapted],
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
    ]

    var body: some View {
        VStack(spacing: 16) {
            // 情绪网格
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MoodType.allCases, id: \.self) { moodType in
                    MoodTypeCell(
                        moodType: moodType,
                        isSelected: viewModel.selectedMoodType == moodType,
                        onTap: { viewModel.selectMoodType(moodType) }
                    )
                }
            }
        }
    }
}

// MARK: - 一级情绪单元格
struct MoodTypeCell: View {
    let moodType: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(moodType.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isSelected ? 62 : 54, height: isSelected ? 62 : 54)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(moodType.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? moodType.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
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
    @State private var customTags: [ActivityTag] = []
    @State private var showCustomTagCreation: Bool = false
    @State private var tagToDelete: ActivityTag?
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.activity_tags"))
                    .font(.subheadline.bold())
                Spacer()
                Button(action: { viewModel.showAllTags.toggle() }) {
                    Text(viewModel.showAllTags ? L.localized("checkin.collapse") : L.localized("checkin.more"))
                        .font(.caption)
                        .foregroundColor(Color(hex: "6C5CE7").colorSchemeAdapted)
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
            customTags = dataManager.fetchCustomTags()
        }
        .onChange(of: dataManager.dataVersion) { _ in
            frequentTags = dataManager.fetchFrequentTags()
            customTags = dataManager.fetchCustomTags()
        }
        .alert(
            L.localized("custom_tag.delete"),
            isPresented: $showDeleteConfirm,
            presenting: tagToDelete
        ) { tag in
            Button(L.localized("custom_tag.delete"), role: .destructive) {
                deleteCustomTag(tag)
            }
            Button(L.localized("checkin.cancel"), role: .cancel) {}
        } message: { tag in
            Text(String(format: L.localized("custom_tag.delete_confirm"), tag.name ?? ""))
        }
    }

    // MARK: - 常用标签
    private var frequentTagsView: some View {
        FlowLayout(data: frequentTags, spacing: 8) { tag in
            TagChip(
                emoji: tag.emoji ?? "📋",
                name: tag.name ?? "",
                isSelected: viewModel.isTagSelected(tag.name ?? ""),
                color: Color(hex: "6C5CE7").colorSchemeAdapted,
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
                        .foregroundColor(Color(hex: "6C5CE7").colorSchemeAdapted)
                }

                FlowLayout(data: selectedCategory.presetTags, spacing: 8) { preset in
                    TagChip(
                        emoji: preset.emoji,
                        name: preset.name,
                        isSelected: viewModel.isTagSelected(preset.name),
                        color: Color(hex: "6C5CE7").colorSchemeAdapted,
                        onTap: { viewModel.toggleTag(preset.name) }
                    )
                }

                // 该分类下的自定义标签
                let categoryCustomTags = customTags.filter { $0.category == selectedCategory.rawValue }
                if !categoryCustomTags.isEmpty {
                    FlowLayout(data: categoryCustomTags, spacing: 8) { tag in
                        TagChip(
                            emoji: tag.emoji ?? "📋",
                            name: tag.name ?? "",
                            isSelected: viewModel.isTagSelected(tag.name ?? ""),
                            color: Color(hex: "6C5CE7").colorSchemeAdapted,
                            onTap: { viewModel.toggleTag(tag.name ?? "") },
                            isCustom: true,
                            onLongPress: {
                                tagToDelete = tag
                                showDeleteConfirm = true
                            }
                        )
                    }
                }
            }
            .padding(.top, 12)

            // 自定义标签按钮 - push 进入创建页
            NavigationLink(isActive: $showCustomTagCreation) {
                CustomTagCreationView(dataManager: dataManager) { tagName in
                    frequentTags = dataManager.fetchFrequentTags()
                    customTags = dataManager.fetchCustomTags()
                    viewModel.toggleTag(tagName)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.caption)
                    Text(L.localized("custom_tag.add"))
                        .font(.caption)
                }
                .foregroundColor(Color(hex: "6C5CE7").colorSchemeAdapted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .stroke(Color(hex: "6C5CE7").colorSchemeAdapted.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedCategory)
    }

    // MARK: - 删除自定义标签
    private func deleteCustomTag(_ tag: ActivityTag) {
        do {
            try dataManager.deleteCustomTag(tag)
            customTags = dataManager.fetchCustomTags()
            frequentTags = dataManager.fetchFrequentTags()
        } catch {
            // 静默处理
        }
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
                    .fill(isSelected ? Color(hex: "6C5CE7").colorSchemeAdapted.opacity(0.12) : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(hex: "6C5CE7").colorSchemeAdapted : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? Color(hex: "6C5CE7").colorSchemeAdapted : .primary)
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
    var isCustom: Bool = false
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 11))
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                if isCustom {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary.opacity(0.6))
                }
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
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if isCustom, let onLongPress = onLongPress {
                        onLongPress()
                    }
                }
        )
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
        .background(Capsule().fill(Color(hex: "6C5CE7").colorSchemeAdapted.opacity(0.1)))
        .foregroundColor(Color(hex: "6C5CE7").colorSchemeAdapted)
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
                    .foregroundColor(Color(hex: "00B894").colorSchemeAdapted)
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
