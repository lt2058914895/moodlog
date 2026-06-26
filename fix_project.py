#!/usr/bin/env python3
import os

filepath = os.path.join(os.path.dirname(__file__), 'moodlog', 'moodlog.xcodeproj', 'project.pbxproj')
with open(filepath, 'r') as f:
    content = f.read()

changes = 0

# 1. Add PBXBuildFile for EditMoodRecordView.swift
old1 = 'AA0000132FED4D95001B6443 /* LocalizationManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000142FED4D95001B6443 /* LocalizationManager.swift */; };'
new1 = old1 + '\n\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000162FED4D95001B6443 /* EditMoodRecordView.swift */; };'
if old1 in content and 'EditMoodRecordView' not in content:
    content = content.replace(old1, new1)
    changes += 1
    print('Step 1: PBXBuildFile added')

# 2. Add PBXFileReference for EditMoodRecordView.swift
old2 = 'AA0000142FED4D95001B6443 /* LocalizationManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LocalizationManager.swift; sourceTree = "<group>"; };'
new2 = old2 + '\n\t\tAA0000162FED4D95001B6443 /* EditMoodRecordView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EditMoodRecordView.swift; sourceTree = "<group>"; };'
if old2 in content and 'AA0000162FED4D95001B6443' not in content:
    content = content.replace(old2, new2)
    changes += 1
    print('Step 2: PBXFileReference added')

# 3. Add to Checkin group children
old3 = 'AA00000C2FED4D95001B6443 /* MoodCheckinView.swift */,\n\t\t\t);\n\t\t\tpath = Checkin;'
new3 = 'AA00000C2FED4D95001B6443 /* MoodCheckinView.swift */,\n\t\t\t\tAA0000162FED4D95001B6443 /* EditMoodRecordView.swift */,\n\t\t\t);\n\t\t\tpath = Checkin;'
if old3 in content and 'AA0000162FED4D95001B6443' not in content.split('Checkin')[0]:
    content = content.replace(old3, new3)
    changes += 1
    print('Step 3: Checkin group updated')

# 4. Add to PBXSourcesBuildPhase
old4 = 'AA0000132FED4D95001B6443 /* LocalizationManager.swift in Sources */,'
new4 = old4 + '\n\t\t\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */,'
if old4 in content and 'AA0000152FED4D95001B6443' not in content:
    content = content.replace(old4, new4)
    changes += 1
    print('Step 4: PBXSourcesBuildPhase updated')

with open(filepath, 'w') as f:
    f.write(content)

print(f'Total changes: {changes}')
print('File saved successfully')