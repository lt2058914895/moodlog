//
//  MoodModels.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

// MARK: - 一级情绪类型
enum MoodType: String, CaseIterable, Codable {
    case happy = "happy"       // 😊 开心
    case sad = "sad"           // 😢 难过
    case angry = "angry"       // 😠 生气
    case anxious = "anxious"   // 😰 焦虑
    case neutral = "neutral"   // 😐 平淡
    case love = "love"         // 🥰 爱
    case thinking = "thinking" // 🤔 思考

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .neutral: return "😐"
        case .love: return "🥰"
        case .thinking: return "🤔"
        }
    }

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .sad: return "难过"
        case .angry: return "生气"
        case .anxious: return "焦虑"
        case .neutral: return "平淡"
        case .love: return "爱"
        case .thinking: return "思考"
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
        case .thinking: return Color(hex: "34D399")
        }
    }

    var subTypes: [MoodSubType] {
        switch self {
        case .happy: return [.joyful, .satisfied, .grateful, .excited, .peaceful]
        case .sad: return [.grief, .lost, .lonely, .missing, .disappointed]
        case .angry: return [.furious, .irritated, .dissatisfied, .jealous, .wronged]
        case .anxious: return [.tense, .worried, .scared, .uneasy, .panicked]
        case .neutral: return [.numb, .bored, .exhausted, .confused, .apathetic]
        case .love: return [.blissful, .crush, .beloved, .warm, .sweet]
        case .thinking: return [.reflective, .conflicted, .hesitant, .insightful, .doubtful]
        }
    }
}

// MARK: - 二级情绪类型
enum MoodSubType: String, CaseIterable, Codable {
    // 开心
    case joyful = "joyful"           // 愉悦
    case satisfied = "satisfied"     // 满足
    case grateful = "grateful"       // 感恩
    case excited = "excited"         // 兴奋
    case peaceful = "peaceful"       // 平静
    // 难过
    case grief = "grief"             // 悲伤
    case lost = "lost"               // 失落
    case lonely = "lonely"           // 孤独
    case missing = "missing"         // 想念
    case disappointed = "disappointed" // 失望
    // 生气
    case furious = "furious"         // 愤怒
    case irritated = "irritated"     // 烦躁
    case dissatisfied = "dissatisfied" // 不满
    case jealous = "jealous"         // 嫉妒
    case wronged = "wronged"         // 委屈
    // 焦虑
    case tense = "tense"             // 紧张
    case worried = "worried"         // 担忧
    case scared = "scared"           // 害怕
    case uneasy = "uneasy"           // 不安
    case panicked = "panicked"       // 恐慌
    // 平淡
    case numb = "numb"               // 无感
    case bored = "bored"             // 无聊
    case exhausted = "exhausted"     // 疲惫
    case confused = "confused"       // 迷茫
    case apathetic = "apathetic"     // 麻木
    // 爱
    case blissful = "blissful"       // 幸福
    case crush = "crush"             // 心动
    case beloved = "beloved"         // 被爱
    case warm = "warm"               // 温暖
    case sweet = "sweet"             // 甜蜜
    // 思考
    case reflective = "reflective"   // 反思
    case conflicted = "conflicted"   // 纠结
    case hesitant = "hesitant"       // 犹豫
    case insightful = "insightful"   // 领悟
    case doubtful = "doubtful"       // 怀疑

    var displayName: String {
        switch self {
        // 开心
        case .joyful: return "愉悦"
        case .satisfied: return "满足"
        case .grateful: return "感恩"
        case .excited: return "兴奋"
        case .peaceful: return "平静"
        // 难过
        case .grief: return "悲伤"
        case .lost: return "失落"
        case .lonely: return "孤独"
        case .missing: return "想念"
        case .disappointed: return "失望"
        // 生气
        case .furious: return "愤怒"
        case .irritated: return "烦躁"
        case .dissatisfied: return "不满"
        case .jealous: return "嫉妒"
        case .wronged: return "委屈"
        // 焦虑
        case .tense: return "紧张"
        case .worried: return "担忧"
        case .scared: return "害怕"
        case .uneasy: return "不安"
        case .panicked: return "恐慌"
        // 平淡
        case .numb: return "无感"
        case .bored: return "无聊"
        case .exhausted: return "疲惫"
        case .confused: return "迷茫"
        case .apathetic: return "麻木"
        // 爱
        case .blissful: return "幸福"
        case .crush: return "心动"
        case .beloved: return "被爱"
        case .warm: return "温暖"
        case .sweet: return "甜蜜"
        // 思考
        case .reflective: return "反思"
        case .conflicted: return "纠结"
        case .hesitant: return "犹豫"
        case .insightful: return "领悟"
        case .doubtful: return "怀疑"
        }
    }

    var parentType: MoodType {
        switch self {
        case .joyful, .satisfied, .grateful, .excited, .peaceful: return .happy
        case .grief, .lost, .lonely, .missing, .disappointed: return .sad
        case .furious, .irritated, .dissatisfied, .jealous, .wronged: return .angry
        case .tense, .worried, .scared, .uneasy, .panicked: return .anxious
        case .numb, .bored, .exhausted, .confused, .apathetic: return .neutral
        case .blissful, .crush, .beloved, .warm, .sweet: return .love
        case .reflective, .conflicted, .hesitant, .insightful, .doubtful: return .thinking
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
    case selfCare = "selfCare"           // 🧘 自我关怀

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
        case .selfCare: return "🧘"
        }
    }

    var displayName: String {
        switch self {
        case .relationship: return "情感关系"
        case .work: return "工作职场"
        case .family: return "家庭关系"
        case .study: return "学业成长"
        case .health: return "身体健康"
        case .social: return "社交生活"
        case .finance: return "财务状况"
        case .lifeEvent: return "生活事件"
        case .selfCare: return "自我关怀"
        }
    }

    /// 该分类下的预设标签
    var presetTags: [PresetTag] {
        switch self {
        case .relationship:
            return [
                PresetTag(name: "想离婚", emoji: "💔"),
                PresetTag(name: "想分手", emoji: "💔"),
                PresetTag(name: "吵架了", emoji: "😤"),
                PresetTag(name: "被分手", emoji: "💔"),
                PresetTag(name: "被出轨", emoji: "💔"),
                PresetTag(name: "冷战", emoji: "🧊"),
                PresetTag(name: "异地恋", emoji: "✈️"),
                PresetTag(name: "暗恋", emoji: "💕"),
                PresetTag(name: "表白", emoji: "💌"),
                PresetTag(name: "复合", emoji: "💞"),
                PresetTag(name: "约会", emoji: "🌹"),
                PresetTag(name: "纪念日", emoji: "🎂"),
            ]
        case .work:
            return [
                PresetTag(name: "被批评", emoji: "😞"),
                PresetTag(name: "加班", emoji: "💼"),
                PresetTag(name: "升职加薪", emoji: "🎉"),
                PresetTag(name: "离职", emoji: "👋"),
                PresetTag(name: "面试", emoji: "🏢"),
                PresetTag(name: "被辞退", emoji: "😢"),
                PresetTag(name: "职场PUA", emoji: "😠"),
                PresetTag(name: "同事冲突", emoji: "😤"),
                PresetTag(name: "项目压力", emoji: "😰"),
                PresetTag(name: "摸鱼", emoji: "🐟"),
            ]
        case .family:
            return [
                PresetTag(name: "父母催婚", emoji: "💍"),
                PresetTag(name: "婆媳矛盾", emoji: "😤"),
                PresetTag(name: "亲子冲突", emoji: "😠"),
                PresetTag(name: "家人生病", emoji: "😢"),
                PresetTag(name: "家庭聚会", emoji: "🏠"),
                PresetTag(name: "家人支持", emoji: "❤️"),
            ]
        case .study:
            return [
                PresetTag(name: "考试焦虑", emoji: "😰"),
                PresetTag(name: "挂科", emoji: "😞"),
                PresetTag(name: "毕业", emoji: "🎓"),
                PresetTag(name: "论文压力", emoji: "📝"),
                PresetTag(name: "获奖", emoji: "🏆"),
                PresetTag(name: "学习突破", emoji: "💡"),
            ]
        case .health:
            return [
                PresetTag(name: "失眠", emoji: "😰"),
                PresetTag(name: "生理期", emoji: "🩹"),
                PresetTag(name: "生病", emoji: "🤒"),
                PresetTag(name: "运动后", emoji: "💪"),
                PresetTag(name: "暴饮暴食", emoji: "🍔"),
                PresetTag(name: "节食", emoji: "🥗"),
                PresetTag(name: "身体疼痛", emoji: "😣"),
            ]
        case .social:
            return [
                PresetTag(name: "朋友聚会", emoji: "🎉"),
                PresetTag(name: "被误解", emoji: "😞"),
                PresetTag(name: "社交恐惧", emoji: "😰"),
                PresetTag(name: "被孤立", emoji: "😢"),
                PresetTag(name: "新朋友", emoji: "👋"),
                PresetTag(name: "网络社交", emoji: "📱"),
            ]
        case .finance:
            return [
                PresetTag(name: "缺钱", emoji: "😰"),
                PresetTag(name: "超支", emoji: "💸"),
                PresetTag(name: "投资亏损", emoji: "📉"),
                PresetTag(name: "发工资", emoji: "💰"),
                PresetTag(name: "还贷压力", emoji: "🏦"),
                PresetTag(name: "财务自由", emoji: "🎉"),
            ]
        case .lifeEvent:
            return [
                PresetTag(name: "搬家", emoji: "🏠"),
                PresetTag(name: "旅行", emoji: "✈️"),
                PresetTag(name: "天气影响", emoji: "🌤"),
                PresetTag(name: "新闻事件", emoji: "📰"),
                PresetTag(name: "季节变化", emoji: "🍂"),
            ]
        case .selfCare:
            return [
                PresetTag(name: "冥想", emoji: "🧘"),
                PresetTag(name: "阅读", emoji: "📖"),
                PresetTag(name: "独处", emoji: "🤫"),
                PresetTag(name: "哭泣", emoji: "😢"),
                PresetTag(name: "写日记", emoji: "📝"),
                PresetTag(name: "散步", emoji: "🚶"),
                PresetTag(name: "听音乐", emoji: "🎵"),
                PresetTag(name: "看电影", emoji: "🎬"),
            ]
        }
    }
}

// MARK: - 预设标签数据
struct PresetTag {
    let name: String
    let emoji: String
}

// MARK: - 情绪记录UI模型
struct MoodRecordUIModel: Identifiable {
    let id: UUID
    let moodType: MoodType
    let moodSubType: MoodSubType
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