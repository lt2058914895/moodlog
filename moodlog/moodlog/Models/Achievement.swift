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
    let descKey: String
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
                   descKey: "achievement.first_record.desc",
                   icon: "star.fill", metric: .totalRecords, requirement: 1),
        Achievement(id: "streak_7",
                   titleKey: "achievement.streak_7.title",
                   descKey: "achievement.streak_7.desc",
                   icon: "flame.fill", metric: .streakDays, requirement: 7),
        Achievement(id: "streak_30",
                   titleKey: "achievement.streak_30.title",
                   descKey: "achievement.streak_30.desc",
                   icon: "rosette", metric: .streakDays, requirement: 30),
        Achievement(id: "streak_100",
                   titleKey: "achievement.streak_100.title",
                   descKey: "achievement.streak_100.desc",
                   icon: "crown.fill", metric: .streakDays, requirement: 100),
        Achievement(id: "records_50",
                   titleKey: "achievement.records_50.title",
                   descKey: "achievement.records_50.desc",
                   icon: "note.text", metric: .totalRecords, requirement: 50),
        Achievement(id: "records_200",
                   titleKey: "achievement.records_200.title",
                   descKey: "achievement.records_200.desc",
                   icon: "books.vertical.fill", metric: .totalRecords, requirement: 200),
    ]
}
