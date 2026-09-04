//
//  Achievement.swift
//  moodlog
//
//  阶段二：轻量成就系统
//

import Foundation

/// 成就徽章定义
struct Achievement: Identifiable {
    let id: String
    let titleKey: String
    let icon: String          // SF Symbol
    let metric: Metric
    let requirement: Int

    enum Metric {
        case streakDays
        case totalRecords
    }

    func isEarned(currentValue: Int) -> Bool {
        currentValue >= requirement
    }
}

/// 成就徽章目录（集中管理）
enum AchievementCatalog {
    static let all: [Achievement] = [
        Achievement(id: "first_record",
                   titleKey: "achievement.first_record.title",
                   icon: "star.fill", metric: .totalRecords, requirement: 1),
        Achievement(id: "streak_7",
                   titleKey: "achievement.streak_7.title",
                   icon: "flame.fill", metric: .streakDays, requirement: 7),
        Achievement(id: "streak_30",
                   titleKey: "achievement.streak_30.title",
                   icon: "rosette", metric: .streakDays, requirement: 30),
        Achievement(id: "streak_100",
                   titleKey: "achievement.streak_100.title",
                   icon: "crown.fill", metric: .streakDays, requirement: 100),
        Achievement(id: "records_50",
                   titleKey: "achievement.records_50.title",
                   icon: "note.text", metric: .totalRecords, requirement: 50),
        Achievement(id: "records_200",
                   titleKey: "achievement.records_200.title",
                   icon: "books.vertical.fill", metric: .totalRecords, requirement: 200),
    ]
}
