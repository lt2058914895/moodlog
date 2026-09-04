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
@MainActor
class MoodCheckinViewModel: ObservableObject {
    @Published var selectedMoodType: MoodType?
    @Published var intensity: Int = 5
    @Published var selectedTagNames: [String] = []
    @Published var note: String = ""
    @Published var showAllTags: Bool = false
    @Published var showSuccessAnimation: Bool = false
    @Published var errorMessage: String?
    @Published var isSubmitting: Bool = false
    @Published var streakDays: Int = 0
    @Published var totalRecords: Int = 0
    @Published var daysSinceLastRecord: Int = 0

    private let dataManager: any MoodDataManaging

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
        loadStats()
    }

    /// 加载统计数据（轻量查询：count + fetchLimit=1，不加载全部记录）
    private func loadStats() {
        totalRecords = dataManager.fetchRecordCount()
        streakDays = dataManager.fetchStreakDays()
        daysSinceLastRecord = calculateDaysSinceLastRecord()
    }

    private func calculateDaysSinceLastRecord() -> Int {
        guard let lastDate = dataManager.fetchLatestRecordDate() else { return 0 }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day ?? 0
    }

    /// 数据变更后刷新统计
    func refreshStats() {
        loadStats()
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

    /// 提交情绪记录（异步，不阻塞主线程）
    func submitRecord() {
        guard let moodType = selectedMoodType else {
            errorMessage = L.localized("checkin.select_mood_first")
            return
        }

        guard !isSubmitting else { return }
        isSubmitting = true

        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
        let tags = selectedTagNames
        let currentIntensity = intensity

        Task {
            do {
                _ = try await dataManager.createMoodRecordAsync(
                    moodType: moodType,
                    intensity: currentIntensity,
                    tagNames: tags,
                    note: noteText
                )
                // 成功动画 + 重置表单 + 刷新统计
                showSuccessAnimation = true
                resetForm()
                loadStats()
                isSubmitting = false
            } catch {
                errorMessage = String(format: L.localized("checkin.save_failed"), error.localizedDescription)
                isSubmitting = false
            }
        }
    }

    /// 快速记录（使用上次标签+强度，异步）
    func quickCheckin(moodType: MoodType) {
        guard !isSubmitting else { return }
        isSubmitting = true

        let tags = selectedTagNames
        let currentIntensity = intensity

        Task {
            do {
                _ = try await dataManager.createMoodRecordAsync(
                    moodType: moodType,
                    intensity: currentIntensity,
                    tagNames: tags,
                    note: nil
                )
                showSuccessAnimation = true
                isSubmitting = false
            } catch {
                errorMessage = String(format: L.localized("checkin.quick_failed"), error.localizedDescription)
                isSubmitting = false
            }
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