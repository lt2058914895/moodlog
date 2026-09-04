//
//  TagSelectorView.swift
//  moodlog
//
//  从 MoodCheckinView.swift 拆分而来
//

import SwiftUI

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
                        .foregroundColor(Color("AccentColor"))
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
        .onReceive(NotificationCenter.default.publisher(for: .moodDataDidChange)) { _ in
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
                color: Color("AccentColor"),
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
                        .foregroundColor(Color("AccentColor"))
                }

                FlowLayout(data: selectedCategory.presetTags, spacing: 8) { preset in
                    TagChip(
                        emoji: preset.emoji,
                        name: preset.name,
                        isSelected: viewModel.isTagSelected(preset.name),
                        color: Color("AccentColor"),
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
                            color: Color("AccentColor"),
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
                .foregroundColor(Color("AccentColor"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .stroke(Color("AccentColor").opacity(0.4), lineWidth: 1)
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
                    .fill(isSelected ? Color("AccentColor").opacity(0.12) : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color("AccentColor") : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? Color("AccentColor") : .primary)
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
            Text(MoodDataManager.emojiForTagName(name))
                .font(.caption2)
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
        .background(Capsule().fill(Color("AccentColor").opacity(0.1)))
        .foregroundColor(Color("AccentColor"))
    }
}
