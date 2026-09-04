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
    @State private var showConfirmAlert: Bool = false
    @State private var showExistsAlert: Bool = false
    @State private var existingCategoryName: String = ""
    @FocusState private var isInputFocused: Bool

    /// 可选 emoji 列表
    private let emojiOptions: [[String]] = [
        ["💔", "❤️", "💕", "💖", "💗", "💘", "💞", "💓", "💝", "💟"],
        ["😊", "😢", "😠", "😰", "😐", "🤗", "😨", "😩", "😌", "🤔"],
        ["💼", "🏢", "💻", "📱", "🎓", "📚", "📝", "🎯", "🏆", "🎉"],
        ["🏠", "✈️", "🚗", "🚌", "🚀", "⛵", "🏖", "🏕", "🗺", "🌍"],
        ["💪", "🏃", "🧘", "🛌", "🤒", "💊", "🩹", "🍎", "🥗", "🍔"],
        ["🎵", "🎬", "📖", "🎨", "🎭", "🎪", "📸", "🎮", "🧩", "🎲"],
        ["💰", "💸", "📈", "📉", "🏦", "💳", "🛒", "🎁", "🧧", "💎"],
        ["⭐", "🌟", "✨", "🔥", "❄️", "🌈", "☀️", "🌙", "🍀", "🌸"],
    ]

    var body: some View {
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("AccentColor"))
                }
            }
        }
        .onAppear {
            // 隐藏 Tab 栏
            TabBarHelper.setTabBarHidden(true)
        }
        .onDisappear {
            // 恢复 Tab 栏
            TabBarHelper.setTabBarHidden(false)
        }
        .onTapGesture {
            // 点击空白区域收起键盘
            isInputFocused = false
            hideKeyboard()
        }
        .alert(L.localized("custom_tag.create_title"), isPresented: $showConfirmAlert) {
            Button(L.localized("custom_tag.cancel"), role: .cancel) {}
            Button(L.localized("custom_tag.confirm"), role: .none) {
                createTag()
            }
        } message: {
            Text(L.localized("custom_tag.confirm_create_message_prefix") + "「\(selectedEmoji) \(tagName.trimmingCharacters(in: .whitespacesAndNewlines))」" + L.localized("custom_tag.confirm_create_message_suffix"))
        }
        .alert("", isPresented: $showExistsAlert) {
            Button(L.localized("custom_tag.got_it"), role: .cancel) {}
        } message: {
            Text("「\(selectedEmoji) \(tagName.trimmingCharacters(in: .whitespacesAndNewlines))」" + L.localized("custom_tag.name_exists_in_category") + "「\(existingCategoryName)」")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - 标签名称输入
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.localized("custom_tag.name_placeholder"))
                .font(.subheadline.bold())

            TextField(L.localized("custom_tag.name_placeholder"), text: $tagName)
                .focused($isInputFocused)
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

            // Emoji 网格
            ForEach(0..<emojiOptions.count, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    ForEach(emojiOptions[rowIndex], id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji)
                                .font(.system(size: 22))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedEmoji == emoji ? Color("AccentColor").opacity(0.15) : Color.clear)
                                )
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
        HStack(spacing: 12) {
            Text(L.localized("custom_tag.preview"))
                .font(.subheadline.bold())
            Spacer()
            HStack(spacing: 4) {
                Text(selectedEmoji)
                    .font(.system(size: 14))
                Text(tagName.isEmpty ? L.localized("custom_tag.name_placeholder") : tagName)
                    .font(.caption)
                    .foregroundColor(tagName.isEmpty ? .secondary : Color("AccentColor"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tagName.isEmpty ? Color(UIColor.tertiarySystemGroupedBackground) : Color("AccentColor").opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(tagName.isEmpty ? Color.clear : Color("AccentColor").opacity(0.6), lineWidth: 1)
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 创建按钮
    private var createButton: some View {
        Button(action: checkAndCreate) {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(L.localized("custom_tag.create"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color("AccentColor"), Color("AccentLightColor")],
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

    // MARK: - 检查并创建
    private func checkAndCreate() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 检查是否已存在同名标签（精确按名称查找，包含所有预设标签）
        if let existingTag = dataManager.fetchTagByName(trimmedName) {
            existingCategoryName = TagCategory(rawValue: existingTag.category ?? "")?.displayName ?? L.localized("custom_tag.unknown_category")
            showExistsAlert = true
            return
        }

        // 不存在，弹出确认创建弹窗
        showConfirmAlert = true
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

// MARK: - Tab 栏辅助
struct TabBarHelper {
    static func setTabBarHidden(_ hidden: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        findTabBarController(from: rootViewController)?.tabBar.isHidden = hidden
    }

    private static func findTabBarController(from vc: UIViewController) -> UITabBarController? {
        if let tabBar = vc as? UITabBarController {
            return tabBar
        }
        if let nav = vc as? UINavigationController {
            return findTabBarController(from: nav.visibleViewController ?? nav.topViewController ?? nav)
        }
        if let presented = vc.presentedViewController {
            if let tabBar = findTabBarController(from: presented) {
                return tabBar
            }
        }
        for child in vc.children {
            if let tabBar = findTabBarController(from: child) {
                return tabBar
            }
        }
        return nil
    }
}

#Preview {
    CustomTagCreationView(dataManager: MoodDataManager.shared) { _ in }
}
