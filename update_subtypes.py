#!/usr/bin/env python3
# -*- coding: utf-8 -*-
filepath = '/Users/deppon/Desktop/moodlog/moodlog/moodlog/moodlog/Models/MoodModels.swift'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Step 1: Add new MoodSubType cases
old_subtypes = '''    // 思考
    case reflective = "reflective"   // 反思
    case conflicted = "conflicted"   // 纠结
    case hesitant = "hesitant"       // 犹豫
    case insightful = "insightful"   // 领悟
    case doubtful = "doubtful"       // 怀疑

    var displayName: String {'''

new_subtypes = '''    // 思考
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

    var displayName: String {'''

content = content.replace(old_subtypes, new_subtypes)
print('Step 1: Added new MoodSubType cases')

# Step 2: Add new displayName cases
old_display_end = '''        case .doubtful: return L.localized("moodsub.doubtful")
        }
    }

    var parentType: MoodType {'''

new_display_end = '''        case .doubtful: return L.localized("moodsub.doubtful")
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

    var parentType: MoodType {'''

content = content.replace(old_display_end, new_display_end)
print('Step 2: Added new displayName cases')

# Step 3: Update parentType mapping
old_parent = '''        case .numb, .bored, .exhausted, .confused, .apathetic: return .neutral
        case .blissful, .crush, .beloved, .warm, .sweet: return .love
        case .reflective, .conflicted, .hesitant, .insightful, .doubtful: return .thinking
        }
    }
}'''

new_parent = '''        case .numb, .confused, .apathetic: return .neutral
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
}'''

content = content.replace(old_parent, new_parent)
print('Step 3: Updated parentType mapping')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('MoodSubType updated successfully')