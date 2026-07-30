//
//  MoodModels.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//  重构于 2026/7/29 — 删除二级情绪，精简一级情绪为9个核心大类
//

import SwiftUI

// MARK: - 情绪类型（精简为9个核心大类）
enum MoodType: String, CaseIterable, Codable {
    case happy = "happy"       // 😊 开心
    case sad = "sad"           // 😢 难过
    case angry = "angry"       // 😠 生气
    case anxious = "anxious"   // 😰 焦虑
    case neutral = "neutral"   // 😐 平淡
    case love = "love"         // 🥰 爱
    case afraid = "afraid"     // 😨 害怕
    case tired = "tired"       // 😩 疲惫
    case relaxed = "relaxed"   // 😌 放松

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .neutral: return "😐"
        case .love: return "🥰"
        case .afraid: return "😨"
        case .tired: return "😩"
        case .relaxed: return "😌"
        }
    }

    var displayName: String {
        switch self {
        case .happy: return L.localized("mood.happy")
        case .sad: return L.localized("mood.sad")
        case .angry: return L.localized("mood.angry")
        case .anxious: return L.localized("mood.anxious")
        case .neutral: return L.localized("mood.neutral")
        case .love: return L.localized("mood.love")
        case .afraid: return L.localized("mood.afraid")
        case .tired: return L.localized("mood.tired")
        case .relaxed: return L.localized("mood.relaxed")
        }
    }

    var color: Color {
        switch self {
        case .happy: return Color(hex: "FFD93D")
        case .sad: return Color(hex: "6C9BCF")
        case .angry: return Color(hex: "FF6B6B")
        case .anxious: return Color(hex: "C084FC")
        case .neutral: return Color(hex: "94A3B8")
        case .love: return Color(hex: "F472B6")
        case .afraid: return Color(hex: "7C3AED")
        case .tired: return Color(hex: "78716C")
        case .relaxed: return Color(hex: "6EE7B7")
        }
    }
}

// MARK: - 活动标签分类
enum TagCategory: String, CaseIterable, Codable {
    case relationship = "relationship"   // 💔 情感关系
    case work = "work"                   // 💼 工作职场
    case family = "family"               // 👨‍👩‍👧 家庭关系
    case study = "study"                 // 📚 学业成长
    case health = "health"               // 🏃 身体健康
    case social = "social"               // 🎭 社交生活
    case finance = "finance"             // 💰 财务状况
    case lifeEvent = "lifeEvent"         // 🌍 生活事件

    var emoji: String {
        switch self {
        case .relationship: return "💔"
        case .work: return "💼"
        case .family: return "👨‍👩‍👧"
        case .study: return "📚"
        case .health: return "🏃"
        case .social: return "🎭"
        case .finance: return "💰"
        case .lifeEvent: return "🌍"
        }
    }

    var displayName: String {
        switch self {
        case .relationship: return L.localized("tagcat.relationship")
        case .work: return L.localized("tagcat.work")
        case .family: return L.localized("tagcat.family")
        case .study: return L.localized("tagcat.study")
        case .health: return L.localized("tagcat.health")
        case .social: return L.localized("tagcat.social")
        case .finance: return L.localized("tagcat.finance")
        case .lifeEvent: return L.localized("tagcat.lifeEvent")
        }
    }

    /// 该分类下的预设标签
    var presetTags: [PresetTag] {
        switch self {
        case .relationship:
            return [
                PresetTag(name: "热恋", emoji: "❤️‍🔥"),
                PresetTag(name: "结婚", emoji: "💍"),
                PresetTag(name: "纪念日", emoji: "💝"),
                PresetTag(name: "约会", emoji: "🌹"),
                PresetTag(name: "复合", emoji: "💞"),
                PresetTag(name: "表白", emoji: "💌"),
                PresetTag(name: "暗恋", emoji: "💕"),
                PresetTag(name: "异地恋", emoji: "✈️"),
                PresetTag(name: "冷战", emoji: "🧊"),
                PresetTag(name: "吵架了", emoji: "😤"),
                PresetTag(name: "被分手", emoji: "💔"),
                PresetTag(name: "想分手", emoji: "💔"),
                PresetTag(name: "想离婚", emoji: "💔"),
            ]
        case .work:
            return [
                PresetTag(name: "升职加薪", emoji: "🎉"),
                PresetTag(name: "入职", emoji: "🆕"),
                PresetTag(name: "团队协作", emoji: "🤝"),
                PresetTag(name: "摸鱼", emoji: "🐟"),
                PresetTag(name: "面试", emoji: "🏢"),
                PresetTag(name: "离职", emoji: "👋"),
                PresetTag(name: "绩效考核", emoji: "📋"),
                PresetTag(name: "加班", emoji: "💼"),
                PresetTag(name: "项目压力", emoji: "😰"),
                PresetTag(name: "同事冲突", emoji: "😤"),
                PresetTag(name: "被批评", emoji: "😞"),
            ]
        case .family:
            return [
                PresetTag(name: "陪伴家人", emoji: "🫶"),
                PresetTag(name: "家人支持", emoji: "❤️"),
                PresetTag(name: "家庭聚会", emoji: "🏠"),
                PresetTag(name: "父母催婚", emoji: "💍"),
                PresetTag(name: "家人生病", emoji: "😢"),
                PresetTag(name: "亲子冲突", emoji: "😠"),
            ]
        case .study:
            return [
                PresetTag(name: "获奖", emoji: "🏆"),
                PresetTag(name: "毕业", emoji: "🎓"),
                PresetTag(name: "学习突破", emoji: "💡"),
                PresetTag(name: "通过考试", emoji: "✅"),
                PresetTag(name: "考试焦虑", emoji: "😰"),
                PresetTag(name: "挂科", emoji: "😞"),
            ]
        case .health:
            return [
                PresetTag(name: "运动后", emoji: "💪"),
                PresetTag(name: "养生", emoji: "🍵"),
                PresetTag(name: "体检", emoji: "🩺"),
                PresetTag(name: "生理期", emoji: "🩹"),
                PresetTag(name: "失眠", emoji: "😰"),
                PresetTag(name: "生病", emoji: "🤒"),
                PresetTag(name: "身体疼痛", emoji: "😣"),
            ]
        case .social:
            return [
                PresetTag(name: "朋友聚会", emoji: "🎉"),
                PresetTag(name: "朋友出行", emoji: "🚗"),
                PresetTag(name: "新朋友", emoji: "👋"),
                PresetTag(name: "被误解", emoji: "😞"),
                PresetTag(name: "社交恐惧", emoji: "😰"),
                PresetTag(name: "被孤立", emoji: "😢"),
            ]
        case .finance:
            return [
                PresetTag(name: "财务自由", emoji: "🎉"),
                PresetTag(name: "发工资", emoji: "💰"),
                PresetTag(name: "理财", emoji: "📊"),
                PresetTag(name: "还贷压力", emoji: "🏦"),
                PresetTag(name: "投资亏损", emoji: "📉"),
                PresetTag(name: "缺钱", emoji: "😰"),
            ]
        case .lifeEvent:
            return [
                PresetTag(name: "旅行", emoji: "✈️"),
                PresetTag(name: "冥想", emoji: "🧘"),
                PresetTag(name: "阅读", emoji: "📖"),
                PresetTag(name: "散步", emoji: "🚶"),
                PresetTag(name: "听音乐", emoji: "🎵"),
                PresetTag(name: "看电影", emoji: "🎬"),
                PresetTag(name: "写日记", emoji: "📝"),
                PresetTag(name: "独处", emoji: "🤫"),
                PresetTag(name: "搬家", emoji: "🏠"),
                PresetTag(name: "天气季节", emoji: "🌤"),
            ]
        }
    }
}

// MARK: - 预设标签数据
struct PresetTag: Hashable {
    let name: String
    let emoji: String
}

// MARK: - 情绪记录UI模型
struct MoodRecordUIModel: Identifiable {
    let id: UUID
    let moodType: MoodType
    let intensity: Int
    let tagNames: [String]
    let note: String?
    let createdAt: Date
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extension
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)!
    }

    var startOfWeek: Date {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return Calendar.current.date(from: components)!
    }

    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    var firstWeekdayOfMonth: Int {
        Calendar.current.component(.weekday, from: startOfMonth)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
}