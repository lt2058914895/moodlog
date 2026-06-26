//
//  MoodCheckinViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import CoreData
import Foundation

/// 情绪打卡ViewModel
class MoodCheckinViewModel: ObservableObject {
    @Published var selectedMoodType: MoodType?
    @Published var selectedMoodSubType: MoodSubType?
    @Published var intensity: Int = 5
    @Published var selectedTagNames: [String] = []
    @Published var note: String = ""
    @Published var showSubMoods: Bool = false
    @Published var showAllTags: Bool = false
    @Published var showSuccessAnimation: Bool = false
    @Published var errorMessage: String?

    private let dataManager: MoodDataManager

    init(dataManager: MoodDataManager = .shared) {
        self.dataManager = dataManager
    }

    // MARK: - 情绪选择

    /// 选择一级情绪
    func selectMoodType(_ moodType: MoodType) {
        selectedMoodType = moodType
        selectedMoodSubType = moodType.subTypes.first
        showSubMoods = true
    }

    /// 选择二级情绪
    func selectMoodSubType(_ subType: MoodSubType) {
        selectedMoodSubType = subType
    }

    // MARK: - 标签选择

    /// 切换标签选择
    func toggleTag(_ tagName: String) {
        if selectedTagNames.contains(tagName) {
            selectedTagNames.removeAll { $0 == tagName }
        } else if selectedTagNames.count < 5 {
            selectedTagNames.append(tagName)
        }
    }

    /// 标签是否已选中
    func isTagSelected(_ tagName: String) -> Bool {
        selectedTagNames.contains(tagName)
    }

    // MARK: - 打卡操作

    /// 提交情绪记录
    func submitRecord() {
        guard let moodType = selectedMoodType,
              let moodSubType = selectedMoodSubType else {
            errorMessage = L.localized("checkin.select_mood_first")
            return
        }

        do {
            let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            _ = try dataManager.createMoodRecord(
                moodType: moodType,
                moodSubType: moodSubType,
                intensity: intensity,
                tagNames: selectedTagNames,
                note: noteText
            )

            // 成功动画
            showSuccessAnimation = true

            // 重置表单
            resetForm()
        } catch {
            errorMessage = "记录保存失败：\(error.localizedDescription)"
        }
    }

    /// 快捷打卡（使用上次标签+强度）
    func quickCheckin(moodType: MoodType) {
        do {
            let subType = moodType.subTypes.first ?? .joyful
            _ = try dataManager.createMoodRecord(
                moodType: moodType,
                moodSubType: subType,
                intensity: intensity,
                tagNames: selectedTagNames
            )
            showSuccessAnimation = true
        } catch {
            errorMessage = "快捷打卡失败：\(error.localizedDescription)"
        }
    }

    /// 重置表单
    func resetForm() {
        selectedMoodType = nil
        selectedMoodSubType = nil
        intensity = 5
        selectedTagNames = []
        note = ""
        showSubMoods = false
        showAllTags = false
        errorMessage = nil
    }

    // MARK: - 强度滑块颜色

    /// 根据强度返回渐变色
    var intensityColor: (start: MoodType, end: MoodType) {
        if intensity <= 3 {
            return (.sad, .neutral)
        } else if intensity <= 6 {
            return (.neutral, .happy)
        } else {
            return (.happy, .love)
        }
    }
}