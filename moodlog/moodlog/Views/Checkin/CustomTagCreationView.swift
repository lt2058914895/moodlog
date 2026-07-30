//
//  CustomTagCreationView.swift
//  moodlog
//
//  Created by deppon on 2026/7/29.
//  自定义活动标签创建弹窗
//

import SwiftUI

/// 自定义标签创建视图
struct CustomTagCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: MoodDataManager

    /// 创建成功回调，返回新标签名
    let onTagCreated: (String) -> Void

    @State private var tagName: String = ""
    @State private var selectedCategory: TagCategory = .lifeEvent
    @State private var selectedEmoji: String = "📋"
    @State private var errorMessage: String?
    @State private var isCreating: Bool = false

    /// 可选 emoji 列表
    private let emojiOptions: [[String]] = [
        ["💔", "❤️", "💕", "💖", "💗", "💘", "💞", "💓", "💝", "💟"],
        ["😊", "😢", "😠", "😰", "😐", "🥰", "😨", "😩", "😌", "🤔"],
        ["💼", "🏢", "💻", "📱", "🎓", "📚", "📝", "🎯", "🏆", "🎉"],
        ["🏠", "✈️", "🚗", "🚌", "🚀", "⛵", "🏖", "🏕", "🗺", "🌍"],
        ["💪", "🏃", "🧘", "🛌", "🤒", "💊", "🩹", "🍎", "🥗", "🍔"],
        ["🎵", "🎬", "📖", "🎨", "🎭", "🎪", "📸", "🎮", "🧩", "🎲"],
        ["💰", "💸", "📈", "📉", "🏦", "💳", "🛒", "🎁", "🧧", "💎"],
        ["⭐", "🌟", "✨", "🔥", "❄️", "🌈", "☀️", "🌙", "🍀", "🌸"],
    ]

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 标签名称输入
                    nameInputSection

                    // 分类选择
                    categorySection

                    // Emoji 选择
                    emojiSection

                    // 错误提示
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }

                    // 预览
                    previewSection

                    // 创建按钮
                    createButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(L.localized("custom_tag.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.localized("checkin.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 标签名称输入
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.localized("custom_tag.name_placeholder"))
                .font(.subheadline.bold())

            TextField(L.localized("custom_tag.name_placeholder"), text: $tagName)
                .font(.body)
                .padding(12)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(10)
                .onChange(of: tagName) { newValue in
                    if newValue.count > 10 {
                        tagName = String(newValue.prefix(10))
                    }
                }

            Text("\(tagName.count)/10")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 分类选择
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.localized("custom_tag.select_category"))
                .font(.subheadline.bold())

            FlowLayout(data: Array(TagCategory.allCases), spacing: 8) { category in
                CategoryPill(
                    emoji: category.emoji,
                    name: category.displayName,
                    isSelected: selectedCategory == category,
                    onTap: { selectedCategory = category }
                )
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Emoji 选择
    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.localized("custom_tag.select_emoji"))
                .font(.subheadline.bold())

            // 当前选中 emoji 预览
            Text(selectedEmoji)
                .font(.system(size: 36))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            // Emoji 网格
            ForEach(0..<emojiOptions.count, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(emojiOptions[rowIndex], id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji)
                                .font(.system(size: selectedEmoji == emoji ? 28 : 22))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedEmoji == emoji ? Color(hex: "6C5CE7").opacity(0.15) : Color.clear)
                                )
                                .scaleEffect(selectedEmoji == emoji ? 1.1 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 预览
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.localized("custom_tag.preview"))
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text(selectedEmoji)
                    .font(.system(size: 14))
                Text(tagName.isEmpty ? L.localized("custom_tag.name_placeholder") : tagName)
                    .font(.caption)
                    .foregroundColor(tagName.isEmpty ? .secondary : Color(hex: "6C5CE7"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tagName.isEmpty ? Color(UIColor.tertiarySystemGroupedBackground) : Color(hex: "6C5CE7").opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(tagName.isEmpty ? Color.clear : Color(hex: "6C5CE7").opacity(0.6), lineWidth: 1)
            )
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 创建按钮
    private var createButton: some View {
        Button(action: createTag) {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "plus.circle.fill")
                }
                Text(L.localized("custom_tag.create"))
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
        .disabled(isCreating || tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
    }

    // MARK: - 创建标签
    private func createTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证
        guard !trimmedName.isEmpty else {
            errorMessage = L.localized("custom_tag.name_required")
            return
        }

        guard trimmedName.count <= 10 else {
            errorMessage = L.localized("custom_tag.name_too_long")
            return
        }

        // 检查是否已存在同名标签
        let existingTags = dataManager.fetchFrequentTags(limit: 100)
        if existingTags.contains(where: { $0.name == trimmedName }) {
            errorMessage = L.localized("custom_tag.name_exists")
            return
        }

        isCreating = true
        errorMessage = nil

        do {
            _ = try dataManager.createCustomTag(
                name: trimmedName,
                category: selectedCategory,
                emoji: selectedEmoji
            )
            isCreating = false
            onTagCreated(trimmedName)
            dismiss()
        } catch {
            isCreating = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CustomTagCreationView(dataManager: MoodDataManager.shared) { _ in }
}