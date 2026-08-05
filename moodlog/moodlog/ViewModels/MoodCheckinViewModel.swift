//
//  MoodCheckinViewModel.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//  重构于 2026/7/29 — 移除二级情绪相关逻辑
//

import CoreData
import Foundation

/// 情绪记录ViewModel
class MoodCheckinViewModel: ObservableObject {
    @Published var selectedMoodType: MoodType?
    @Published var intensity: Int = 5
    @Published var selectedTagNames: [String] = []
    @Published var note: String = ""
    @Published var showAllTags: Bool = false
    @Published var showSuccessAnimation: Bool = false
    @Published var errorMessage: String?

    private let dataManager: any MoodDataManaging

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
    }

    // MARK: - 情绪选择

    /// 选择情绪
    func selectMoodType(_ moodType: MoodType) {
        selectedMoodType = moodType
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

    // MARK: - 记录操作

    /// 提交情绪记录
    func submitRecord() {
        guard let moodType = selectedMoodType else {
            errorMessage = L.localized("checkin.select_mood_first")
            return
        }

        do {
            let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            _ = try dataManager.createMoodRecord(
                moodType: moodType,
                intensity: intensity,
                tagNames: selectedTagNames,
                note: noteText
            )

            // 成功动画
            showSuccessAnimation = true

            // 重置表单
            resetForm()
        } catch {
            errorMessage = String(format: L.localized("checkin.save_failed"), error.localizedDescription)
        }
    }

    /// 快速记录（使用上次标签+强度）
    func quickCheckin(moodType: MoodType) {
        do {
            _ = try dataManager.createMoodRecord(
                moodType: moodType,
                intensity: intensity,
                tagNames: selectedTagNames,
                note: nil
            )
            showSuccessAnimation = true
        } catch {
            errorMessage = String(format: L.localized("checkin.quick_failed"), error.localizedDescription)
        }
    }

    /// 重置表单
    func resetForm() {
        selectedMoodType = nil
        intensity = 5
        selectedTagNames = []
        note = ""
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
            return (.happy, .happy)
        }
    }

    // MARK: - 时间段问候语

    /// 当前时间段
    enum TimeOfDay: String {
        case morning, forenoon, noon, afternoon, evening, night

        var greetingKey: String {
            "greeting.\(rawValue)"
        }

        var imageName: String {
            rawValue
        }

        static var current: TimeOfDay {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<9: return .morning
            case 9..<12: return .forenoon
            case 12..<14: return .noon
            case 14..<18: return .afternoon
            case 18..<22: return .evening
            default: return .night
            }
        }
    }

    /// 当前时间段问候语
    var currentGreeting: String {
        L.localized(TimeOfDay.current.greetingKey)
    }

    /// 当前时间段图标名称
    var currentTimeImageName: String {
        TimeOfDay.current.imageName
    }
}