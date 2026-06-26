#!/usr/bin/env python3
import os

filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'moodlog', 'moodlog.xcodeproj', 'project.pbxproj')
with open(filepath, 'r') as f:
    content = f.read()

changes = 0

# 1. Add PBXFileReference for EditMoodRecordView.swift
old_ref = 'AA0000142FED4D95001B6443 /* LocalizationManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LocalizationManager.swift; sourceTree = "<group>"; };'
new_ref = old_ref + '\n\t\tAA0000162FED4D95001B6443 /* EditMoodRecordView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EditMoodRecordView.swift; sourceTree = "<group>"; };'
if 'AA0000162FED4D95001B6443' not in content:
    content = content.replace(old_ref, new_ref)
    changes += 1
    print('Step 1: PBXFileReference added')
else:
    print('Step 1: skipped - already exists')

# 2. Add to PBXSourcesBuildPhase
old_src = 'AA0000132FED4D95001B6443 /* LocalizationManager.swift in Sources */,'
new_src = old_src + '\n\t\t\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */,'
if 'AA0000152FED4D95001B6443' not in content:
    content = content.replace(old_src, new_src)
    changes += 1
    print('Step 2: PBXSourcesBuildPhase updated')
else:
    print('Step 2: skipped - already exists')

with open(filepath, 'w') as f:
    f.write(content)

print(f'Total changes: {changes}')