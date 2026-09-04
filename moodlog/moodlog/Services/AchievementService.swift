//
//  AchievementService.swift
//  moodlog
//
//  阶段二：成就进度计算
//

import Foundation

/// 单个成就的当前状态
struct AchievementStatus: Identifiable {
    let id = UUID()
    let achievement: Achievement
    let currentValue: Int

    var isEarned: Bool { achievement.isEarned(currentValue: currentValue) }
    var progress: Double {
        let p = Double(currentValue) / Double(achievement.requirement)
        return min(max(p, 0), 1)
    }
}

/// 成就服务：基于现有统计数据计算徽章进度
class AchievementService: ObservableObject {
    private let dataManager: any MoodDataManaging

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
    }

    /// 获取全部成就状态
    func fetchAllStatuses() -> [AchievementStatus] {
        let streak = dataManager.fetchStreakDays()
        let total = dataManager.fetchRecordCount()
        return AchievementCatalog.all.map { ach in
            let value: Int
            switch ach.metric {
            case .streakDays: value = streak
            case .totalRecords: value = total
            }
            return AchievementStatus(achievement: ach, currentValue: value)
        }
    }

    /// 已获得的成就数量
    var earnedCount: Int { fetchAllStatuses().filter { $0.isEarned }.count }

    /// 成就总数
    var totalCount: Int { AchievementCatalog.all.count }
}
