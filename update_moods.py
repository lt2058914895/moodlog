#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os

filepath = '/Users/deppon/Desktop/moodlog/moodlog/moodlog/moodlog/Models/MoodModels.swift'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Step 1: Add new MoodType cases
old_cases = '''    case thinking = "thinking" // 🤔 思考

    var emoji: String {'''
new_cases = '''    case thinking = "thinking"     // 🤔 思考
    case afraid = "afraid"         // 😨 害怕
    case surprised = "surprised"   // 😲 惊讶
    case tired = "tired"           // 😩 疲惫
    case relaxed = "relaxed"       // 😌 放松
    case calm = "calm"             // 🧘 平静
    case bored = "bored"           // 🥱 无聊
    case upset = "upset"           // 😖 烦恼
    case painful = "painful"       // 😣 痛苦

    var emoji: String {'''
content = content.replace(old_cases, new_cases)
print('Step 1: Added new MoodType cases')

# Step 2: Add new emoji cases
old_emoji = '''        case .thinking: return "🤔"
        }
    }

    var displayName: String {'''
new_emoji = '''        case .thinking: return "🤔"
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

    var displayName: String {'''
content = content.replace(old_emoji, new_emoji)
print('Step 2: Added new emoji cases')

# Step 3: Add new displayName cases
old_display = '''        case .thinking: return L.localized("mood.thinking")
        }
    }

    var color: Color {'''
new_display = '''        case .thinking: return L.localized("mood.thinking")
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

    var color: Color {'''
content = content.replace(old_display, new_display)
print('Step 3: Added new displayName cases')

# Step 4: Add new color cases
old_color = '''        case .thinking: return Color(hex: "34D399")
        }
    }

    var subTypes: [MoodSubType] {'''
new_color = '''        case .thinking: return Color(hex: "34D399")
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

    var subTypes: [MoodSubType] {'''
content = content.replace(old_color, new_color)
print('Step 4: Added new color cases')

# Step 5: Update neutral subTypes (remove bored and exhausted which are now top-level)
old_neutral_sub = 'case .neutral: return [.numb, .bored, .exhausted, .confused, .apathetic]'
new_neutral_sub = 'case .neutral: return [.numb, .confused, .apathetic]'
content = content.replace(old_neutral_sub, new_neutral_sub)
print('Step 5: Updated neutral subTypes')

# Step 6: Add new subTypes
old_subtypes_end = '''        case .thinking: return [.reflective, .conflicted, .hesitant, .insightful, .doubtful]
        }
    }
}'''
new_subtypes_end = '''        case .thinking: return [.reflective, .conflicted, .hesitant, .insightful, .doubtful]
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
}'''
content = content.replace(old_subtypes_end, new_subtypes_end)
print('Step 6: Added new subTypes')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('MoodModels.swift updated successfully')