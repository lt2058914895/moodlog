#!/usr/bin/env python3
filepath = '/Users/deppon/Desktop/moodlog/moodlog/moodlog/moodlog.xcodeproj/project.pbxproj'
with open(filepath, 'r') as f:
    content = f.read()

old_src = 'AA0000132FED4D95001B6443 /* LocalizationManager.swift in Sources */,'
new_src = old_src + '\n\t\t\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */,'
if 'AA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */' not in content:
    content = content.replace(old_src, new_src)
    with open(filepath, 'w') as f:
        f.write(content)
    print('Added to PBXSourcesBuildPhase')
else:
    print('Already in PBXSourcesBuildPhase')