//
//  EditMoodRecordView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 编辑情绪记录视图
struct EditMoodRecordView: View {
    @Environment(\.dismiss) private var dismiss
    let record: MoodRecord

    @State private var selectedMoodType: MoodType
    @State private var intensity: Int
    @State private var selectedTagNames: [String]
    @State private var note: String
    @State private var showAllTags: Bool = false
    @State private var showSuccessAnimation: Bool = false
    @State private var errorMessage: String?
    @State private var isUpdating: Bool = false
    @FocusState private var isNoteFocused: Bool

    @StateObject private var dataManager = MoodDataManager.shared

    init(record: MoodRecord) {
        self.record = record
        _selectedMoodType = State(initialValue: MoodType(rawValue: record.moodType ?? "happy") ?? .happy)
        _intensity = State(initialValue: Int(record.intensity))
        _selectedTagNames = State(initialValue: MoodDataManager.tagNamesFromRecord(record))
        _note = State(initialValue: record.note ?? "")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 情绪选择器
                editMoodSelector

                // 情绪强度滑块
                editIntensitySlider

                // 活动标签选择
                editTagSelector

                // 备注
                editNoteField

                // 更新按钮
                updateButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L.localized("checkin.edit_title"))
        .onTapGesture {
            isNoteFocused = false
        }
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
            TabBarHelper.setTabBarHidden(true)
        }
        .onDisappear {
            TabBarHelper.setTabBarHidden(false)
        }
        .overlay {
            if showSuccessAnimation {
                SuccessOverlayView {
                    showSuccessAnimation = false
                    dismiss()
                }
            }
        }
        .alert(L.localized("checkin.alert_title"), isPresented: .constant(errorMessage != nil)) {
            Button(L.localized("checkin.alert_ok")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - 情绪选择器
    private var editMoodSelector: some View {
        VStack(spacing: 16) {
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ]

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MoodType.allCases, id: \.self) { moodType in
                    Button(action: {
                        selectedMoodType = moodType
                    }) {
                        VStack(spacing: 6) {
                            Image(moodType.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: selectedMoodType == moodType ? 54 : 46, height: selectedMoodType == moodType ? 54 : 46)
                                .scaleEffect(selectedMoodType == moodType ? 1.1 : 1.0)
                            Text(moodType.displayName)
                                .font(.caption)
                                .foregroundColor(selectedMoodType == moodType ? moodType.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedMoodType == moodType ? moodType.color.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedMoodType == moodType ? moodType.color : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 强度滑块
    private var editIntensitySlider: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.intensity"))
                    .font(.subheadline.bold())
                Spacer()
                Text("\(intensity)")
                    .font(.title2.bold())
                    .foregroundColor(selectedMoodType.color)
            }

            Slider(value: Binding(
                get: { Double(intensity) },
                set: { intensity = Int($0) }
            ), in: 1...10, step: 1)
            .tint(selectedMoodType.color)

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

    // MARK: - 标签选择
    @State private var editSelectedCategory: TagCategory = .relationship
    @State private var frequentTags: [ActivityTag] = []
    @State private var customTags: [ActivityTag] = []
    @State private var showCustomTagCreation: Bool = false
    @State private var tagToDelete: ActivityTag?
    @State private var showDeleteConfirm: Bool = false

    /// 标签名 → emoji 映射
    private var editTagEmojiMap: [String: String] {
        var map: [String: String] = [:]
        for tag in frequentTags { map[tag.name ?? ""] = tag.emoji ?? "📋" }
        for tag in customTags { map[tag.name ?? ""] = tag.emoji ?? "📋" }
        for category in TagCategory.allCases {
            for preset in category.presetTags { map[preset.name] = preset.emoji }
        }
        return map
    }

    private var editTagSelector: some View {
        VStack(spacing: 12) {
            editTagHeader

            if showAllTags {
                expandedTagsContent
            } else {
                frequentTagsContent
            }

            if !selectedTagNames.isEmpty {
                selectedTagsSummary
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
            Text(L.localized("custom_tag.delete_confirm_prefix") + "「\(tag.emoji ?? "📋") \(tag.name ?? "")」" + L.localized("custom_tag.delete_confirm_suffix"))
        }
    }

    /// 标签区头部（标题+展开/收起按钮）
    private var editTagHeader: some View {
        HStack {
            Text(L.localized("checkin.activity_tags"))
                .font(.subheadline.bold())
            Spacer()
            Button(action: { showAllTags.toggle() }) {
                Text(showAllTags ? L.localized("checkin.collapse") : L.localized("checkin.more"))
                    .font(.caption)
                    .foregroundColor(Color("AccentColor"))
            }
        }
    }

    /// 已选标签摘要
    private var selectedTagsSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L.localizedInt("checkin.selected_count", value: selectedTagNames.count))
                .font(.caption2)
                .foregroundColor(.secondary)

            FlowLayout(data: selectedTagNames, spacing: 6) { name in
                SelectedTagChip(name: name) {
                    toggleTag(name)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - 标签选择子视图（拆分以加速编译）

    /// 展开模式：分类浏览标签
    private var expandedTagsContent: some View {
        VStack(spacing: 0) {
            // 一级分类
            VStack(alignment: .leading, spacing: 8) {
                Text(L.localized("checkin.category_title"))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                FlowLayout(data: Array(TagCategory.allCases), spacing: 8) { category in
                    CategoryPill(
                        emoji: category.emoji,
                        name: category.displayName,
                        isSelected: editSelectedCategory == category,
                        onTap: { editSelectedCategory = category }
                    )
                }
            }
            .padding(.bottom, 12)

            // 分隔线
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, -4)

            // 二级标签
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(editSelectedCategory.emoji)
                        .font(.caption2)
                    Text(editSelectedCategory.displayName)
                        .font(.caption2)
                        .foregroundColor(Color("AccentColor"))
                }

                FlowLayout(data: editSelectedCategory.presetTags, spacing: 8) { preset in
                    TagChip(
                        emoji: preset.emoji,
                        name: preset.name,
                        isSelected: selectedTagNames.contains(preset.name),
                        color: Color("AccentColor"),
                        onTap: { toggleTag(preset.name) }
                    )
                }

                customTagsForCategory
            }
            .padding(.top, 12)

            addCustomTagButton
        }
        .animation(.easeInOut(duration: 0.2), value: editSelectedCategory)
    }

    /// 当前分类下的自定义标签
    private var customTagsForCategory: some View {
        let categoryCustomTags = customTags.filter { $0.category == editSelectedCategory.rawValue }
        return Group {
            if !categoryCustomTags.isEmpty {
                FlowLayout(data: categoryCustomTags, spacing: 8) { tag in
                    TagChip(
                        emoji: tag.emoji ?? "📋",
                        name: tag.name ?? "",
                        isSelected: selectedTagNames.contains(tag.name ?? ""),
                        color: Color("AccentColor"),
                        onTap: { toggleTag(tag.name ?? "") },
                        isCustom: true,
                        onLongPress: {
                            tagToDelete = tag
                            showDeleteConfirm = true
                        }
                    )
                }
            }
        }
    }

    /// 添加自定义标签按钮
    private var addCustomTagButton: some View {
        NavigationLink(isActive: $showCustomTagCreation) {
            CustomTagCreationView(dataManager: dataManager) { tagName in
                frequentTags = dataManager.fetchFrequentTags()
                customTags = dataManager.fetchCustomTags()
                toggleTag(tagName)
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

    /// 常用标签模式
    private var frequentTagsContent: some View {
        FlowLayout(data: frequentTags, spacing: 8) { tag in
            TagChip(
                emoji: tag.emoji ?? "📋",
                name: tag.name ?? "",
                isSelected: selectedTagNames.contains(tag.name ?? ""),
                color: Color("AccentColor"),
                onTap: { toggleTag(tag.name ?? "") }
            )
        }
    }

    // MARK: - 删除自定义标签
    private func deleteCustomTag(_ tag: ActivityTag) {
        do {
            let tagName = tag.name ?? ""
            try dataManager.deleteCustomTag(tag)
            customTags = dataManager.fetchCustomTags()
            frequentTags = dataManager.fetchFrequentTags()
            // 如果该标签已被选中，从已选列表中移除
            if selectedTagNames.contains(tagName) {
                toggleTag(tagName)
            }
        } catch {
            // 静默处理
        }
    }

    // MARK: - 备注
    private var editNoteField: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.note_title"))
                    .font(.subheadline.bold())
                Spacer()
            }

            if #available(iOS 16.0, *) {
                TextField("", text: $note, prompt: Text(L.localized("checkin.note_placeholder")).foregroundColor(.secondary), axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
                    .focused($isNoteFocused)
            } else {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $note)
                        .font(.subheadline)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                        .focused($isNoteFocused)

                    if note.isEmpty {
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

    // MARK: - 更新按钮
    private var updateButton: some View {
        Button(action: updateRecord) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text(L.localized("checkin.update"))
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
        .padding(.top, 8)
    }

    // MARK: - 方法

    private func toggleTag(_ tagName: String) {
        if selectedTagNames.contains(tagName) {
            selectedTagNames.removeAll { $0 == tagName }
        } else if selectedTagNames.count < 5 {
            selectedTagNames.append(tagName)
        }
    }

    private func updateRecord() {
        guard !isUpdating else { return }
        isUpdating = true

        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        let moodType = selectedMoodType
        let currentIntensity = intensity
        let tags = selectedTagNames

        Task {
            do {
                try await dataManager.updateMoodRecordAsync(
                    record,
                    moodType: moodType,
                    intensity: currentIntensity,
                    tagNames: tags,
                    note: noteText
                )
                showSuccessAnimation = true
                isUpdating = false
            } catch {
                errorMessage = String(format: L.localized("checkin.save_failed"), error.localizedDescription)
                isUpdating = false
            }
        }
    }
}
