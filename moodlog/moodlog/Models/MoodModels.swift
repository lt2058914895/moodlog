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
    case thinking = "thinking"     // 🤔 思考
    case afraid = "afraid"         // 😨 害怕
    case surprised = "surprised"   // 😲 惊讶
    case tired = "tired"           // 😩 疲惫
    case relaxed = "relaxed"       // 😌 放松
    case calm = "calm"             // 🧘 平静
    case bored = "bored"           // 🥱 无聊
    case upset = "upset"           // 😖 烦恼
    case painful = "painful"       // 😣 痛苦

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .sad: return "😢"
        case .angry: return "😠"
        case .anxious: return "😰"
        case .neutral: return "😐"
        case .love: return "🥰"
        case .thinking: return "🤔"
        case .afraid: return "😨"
        case .surprised: return "😲"
        case .tired: return "😩"
        case .relaxed: return "😌"
        case .calm: return "🧘"
        case .bored: return "🥱"
        case .upset: return "😖"
        case .painful: return "😣"
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
        case .thinking: return L.localized("mood.thinking")
        case .afraid: return L.localized("mood.afraid")
        case .surprised: return L.localized("mood.surprised")
        case .tired: return L.localized("mood.tired")
        case .relaxed: return L.localized("mood.relaxed")
        case .calm: return L.localized("mood.calm")
        case .bored: return L.localized("mood.bored")
        case .upset: return L.localized("mood.upset")
        case .painful: return L.localized("mood.painful")
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
        case .afraid: return Color(hex: "7C3AED")
        case .surprised: return Color(hex: "F59E0B")
        case .tired: return Color(hex: "78716C")
        case .relaxed: return Color(hex: "6EE7B7")
        case .calm: return Color(hex: "67E8F9")
        case .bored: return Color(hex: "A8A29E")
        case .upset: return Color(hex: "FB923C")
        case .painful: return Color(hex: "DC2626")
        }
    }

    var subTypes: [MoodSubType] {
        switch self {
        case .happy: return [.joyful, .satisfied, .grateful, .excited, .peaceful]
        case .sad: return [.grief, .lost, .lonely, .missing, .disappointed]
        case .angry: return [.furious, .irritated, .dissatisfied, .jealous, .wronged]
        case .anxious: return [.tense, .worried, .scared, .uneasy, .panicked]
        case .neutral: return [.numb, .confused, .apathetic]
        case .love: return [.blissful, .crush, .beloved, .warm, .sweet]
        case .thinking: return [.reflective, .conflicted, .hesitant, .insightful, .doubtful]
        case .afraid: return [.fearful, .terrified, .insecure, .alarmed, .helpless]
        case .surprised: return [.amazed, .shocked, .unexpected, .astonished, .awed]
        case .tired: return [.sleepy, .drained, .burntOut, .weary, .drowsy]
        case .relaxed: return [.cozy, .leisurely, .chill, .content, .serene]
        case .calm: return [.tranquil, .centered, .mindful, .steady, .composed]
        case .bored: return [.dull, .uninterested, .listless, .indifferent, .restless]
        case .upset: return [.frustrated, .annoyed, .agitated, .disturbed, .bothered]
        case .painful: return [.aching, .suffering, .hurt, .sore, .agonizing]
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
    // 害怕
    case fearful = "fearful"         // 恐惧
    case terrified = "terrified"     // 惊恐
    case insecure = "insecure"       // 不安
    case alarmed = "alarmed"         // 惊慌
    case helpless = "helpless"       // 无助
    // 惊讶
    case amazed = "amazed"           // 惊奇
    case shocked = "shocked"         // 震惊
    case unexpected = "unexpected"   // 意外
    case astonished = "astonished"   // 惊叹
    case awed = "awed"               // 敬畏
    // 疲惫
    case sleepy = "sleepy"           // 困倦
    case drained = "drained"         // 精疲力竭
    case burntOut = "burntOut"       // 倦怠
    case weary = "weary"             // 疲劳
    case drowsy = "drowsy"           // 昏沉
    // 放松
    case cozy = "cozy"               // 惬意
    case leisurely = "leisurely"     // 闲适
    case chill = "chill"             // 悠闲
    case content = "content"         // 满足
    case serene = "serene"           // 宁静
    // 平静
    case tranquil = "tranquil"       // 安详
    case centered = "centered"       // 专注
    case mindful = "mindful"         // 正念
    case steady = "steady"           // 稳定
    case composed = "composed"       // 从容
    // 无聊
    case dull = "dull"               // 乏味
    case uninterested = "uninterested" // 无趣
    case listless = "listless"       // 百无聊赖
    case indifferent = "indifferent" // 漠然
    case restless = "restless"       // 烦闷
    // 烦恼
    case frustrated = "frustrated"   // 挫败
    case annoyed = "annoyed"         // 烦扰
    case agitated = "agitated"       // 焦躁
    case disturbed = "disturbed"     // 不安
    case bothered = "bothered"       // 烦心
    // 痛苦
    case aching = "aching"           // 隐痛
    case suffering = "suffering"     // 煎熬
    case hurt = "hurt"               // 受伤
    case sore = "sore"               // 酸痛
    case agonizing = "agonizing"     // 极痛

    var displayName: String {
        switch self {
        case .joyful: return L.localized("moodsub.joyful")
        case .satisfied: return L.localized("moodsub.satisfied")
        case .grateful: return L.localized("moodsub.grateful")
        case .excited: return L.localized("moodsub.excited")
        case .peaceful: return L.localized("moodsub.peaceful")
        case .grief: return L.localized("moodsub.grief")
        case .lost: return L.localized("moodsub.lost")
        case .lonely: return L.localized("moodsub.lonely")
        case .missing: return L.localized("moodsub.missing")
        case .disappointed: return L.localized("moodsub.disappointed")
        case .furious: return L.localized("moodsub.furious")
        case .irritated: return L.localized("moodsub.irritated")
        case .dissatisfied: return L.localized("moodsub.dissatisfied")
        case .jealous: return L.localized("moodsub.jealous")
        case .wronged: return L.localized("moodsub.wronged")
        case .tense: return L.localized("moodsub.tense")
        case .worried: return L.localized("moodsub.worried")
        case .scared: return L.localized("moodsub.scared")
        case .uneasy: return L.localized("moodsub.uneasy")
        case .panicked: return L.localized("moodsub.panicked")
        case .numb: return L.localized("moodsub.numb")
        case .bored: return L.localized("moodsub.bored")
        case .exhausted: return L.localized("moodsub.exhausted")
        case .confused: return L.localized("moodsub.confused")
        case .apathetic: return L.localized("moodsub.apathetic")
        case .blissful: return L.localized("moodsub.blissful")
        case .crush: return L.localized("moodsub.crush")
        case .beloved: return L.localized("moodsub.beloved")
        case .warm: return L.localized("moodsub.warm")
        case .sweet: return L.localized("moodsub.sweet")
        case .reflective: return L.localized("moodsub.reflective")
        case .conflicted: return L.localized("moodsub.conflicted")
        case .hesitant: return L.localized("moodsub.hesitant")
        case .insightful: return L.localized("moodsub.insightful")
        case .doubtful: return L.localized("moodsub.doubtful")
        case .fearful: return L.localized("moodsub.fearful")
        case .terrified: return L.localized("moodsub.terrified")
        case .insecure: return L.localized("moodsub.insecure")
        case .alarmed: return L.localized("moodsub.alarmed")
        case .helpless: return L.localized("moodsub.helpless")
        case .amazed: return L.localized("moodsub.amazed")
        case .shocked: return L.localized("moodsub.shocked")
        case .unexpected: return L.localized("moodsub.unexpected")
        case .astonished: return L.localized("moodsub.astonished")
        case .awed: return L.localized("moodsub.awed")
        case .sleepy: return L.localized("moodsub.sleepy")
        case .drained: return L.localized("moodsub.drained")
        case .burntOut: return L.localized("moodsub.burntOut")
        case .weary: return L.localized("moodsub.weary")
        case .drowsy: return L.localized("moodsub.drowsy")
        case .cozy: return L.localized("moodsub.cozy")
        case .leisurely: return L.localized("moodsub.leisurely")
        case .chill: return L.localized("moodsub.chill")
        case .content: return L.localized("moodsub.content")
        case .serene: return L.localized("moodsub.serene")
        case .tranquil: return L.localized("moodsub.tranquil")
        case .centered: return L.localized("moodsub.centered")
        case .mindful: return L.localized("moodsub.mindful")
        case .steady: return L.localized("moodsub.steady")
        case .composed: return L.localized("moodsub.composed")
        case .dull: return L.localized("moodsub.dull")
        case .uninterested: return L.localized("moodsub.uninterested")
        case .listless: return L.localized("moodsub.listless")
        case .indifferent: return L.localized("moodsub.indifferent")
        case .restless: return L.localized("moodsub.restless")
        case .frustrated: return L.localized("moodsub.frustrated")
        case .annoyed: return L.localized("moodsub.annoyed")
        case .agitated: return L.localized("moodsub.agitated")
        case .disturbed: return L.localized("moodsub.disturbed")
        case .bothered: return L.localized("moodsub.bothered")
        case .aching: return L.localized("moodsub.aching")
        case .suffering: return L.localized("moodsub.suffering")
        case .hurt: return L.localized("moodsub.hurt")
        case .sore: return L.localized("moodsub.sore")
        case .agonizing: return L.localized("moodsub.agonizing")
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
        case .fearful, .terrified, .insecure, .alarmed, .helpless: return .afraid
        case .amazed, .shocked, .unexpected, .astonished, .awed: return .surprised
        case .sleepy, .drained, .burntOut, .weary, .drowsy: return .tired
        case .cozy, .leisurely, .chill, .content, .serene: return .relaxed
        case .tranquil, .centered, .mindful, .steady, .composed: return .calm
        case .dull, .uninterested, .listless, .indifferent, .restless: return .bored
        case .frustrated, .annoyed, .agitated, .disturbed, .bothered: return .upset
        case .aching, .suffering, .hurt, .sore, .agonizing: return .painful
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
        case .relationship: return L.localized("tagcat.relationship")
        case .work: return L.localized("tagcat.work")
        case .family: return L.localized("tagcat.family")
        case .study: return L.localized("tagcat.study")
        case .health: return L.localized("tagcat.health")
        case .social: return L.localized("tagcat.social")
        case .finance: return L.localized("tagcat.finance")
        case .lifeEvent: return L.localized("tagcat.lifeEvent")
        case .selfCare: return L.localized("tagcat.selfCare")
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