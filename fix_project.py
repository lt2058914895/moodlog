#!/usr/bin/env python3
import os

filepath = os.path.join(os.path.dirname(__file__), 'moodlog', 'moodlog.xcodeproj', 'project.pbxproj')
with open(filepath, 'r') as f:
    content = f.read()

changes = 0

# 1. Add PBXBuildFile for LocalizationManager.swift
old1 = 'C2C65F312FEE4B2F006AD954 /* Localizable.strings in Resources */ = {isa = PBXBuildFile; fileRef = C2C65F332FEE4B2F006AD954 /* Localizable.strings */; };'
new1 = old1 + '\n\t\tAA0000132FED4D95001B6443 /* LocalizationManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000142FED4D95001B6443 /* LocalizationManager.swift */; };'
if old1 in content:
    content = content.replace(old1, new1)
    changes += 1
    print('Step 1: PBXBuildFile added')

# 2. Add PBXFileReference for LocalizationManager.swift
old2 = 'C2C65F342FEE4B31006AD954 /* en */ = {isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = en; path = en.lproj/Localizable.strings; sourceTree = "<group>"; };'
new2 = old2 + '\n\t\tAA0000142FED4D95001B6443 /* LocalizationManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LocalizationManager.swift; sourceTree = "<group>"; };'
if old2 in content:
    content = content.replace(old2, new2)
    changes += 1
    print('Step 2: PBXFileReference added')

# 3. Add to Services group children
old3 = 'AA0000042FED4D95001B6443 /* MoodDataManager.swift */,\n\t\t\t);\n\t\t\tpath = Services;'
new3 = 'AA0000042FED4D95001B6443 /* MoodDataManager.swift */,\n\t\t\t\tAA0000142FED4D95001B6443 /* LocalizationManager.swift */,\n\t\t\t);\n\t\t\tpath = Services;'
if old3 in content:
    content = content.replace(old3, new3)
    changes += 1
    print('Step 3: Services group updated')

# 4. Add to PBXSourcesBuildPhase
old4 = 'AA0000112FED4D95001B6443 /* MainTabView.swift in Sources */,'
new4 = old4 + '\n\t\t\t\tAA0000132FED4D95001B6443 /* LocalizationManager.swift in Sources */,'
if old4 in content:
    content = content.replace(old4, new4)
    changes += 1
    print('Step 4: PBXSourcesBuildPhase updated')

with open(filepath, 'w') as f:
    f.write(content)

print(f'Total changes: {changes}')
print('File saved successfully')