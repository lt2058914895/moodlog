#!/usr/bin/env python3
filepath = '/Users/deppon/Desktop/moodlog/moodlog/moodlog/moodlog.xcodeproj/project.pbxproj'
with open(filepath, 'r') as f:
    content = f.read()

# Fix corrupted line 28 - the sed command merged two lines
content = content.replace(
    'ttttAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */,\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000162FED4D95001B6443 /* EditMoodRecordView.swift */; };',
    '\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */ = {isa = PBXBuildFile; fileRef = AA0000162FED4D95001B6443 /* EditMoodRecordView.swift */; };'
)

# Fix corrupted line 331
content = content.replace(
    'ttttAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */,\t\t\t);',
    '\t\t\t\tAA0000152FED4D95001B6443 /* EditMoodRecordView.swift in Sources */,\n\t\t\t);'
)

with open(filepath, 'w') as f:
    f.write(content)
print('Fixed corrupted lines')