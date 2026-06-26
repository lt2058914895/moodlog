//
//  MoodDataManager.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import CoreData
import Foundation

/// 数据变更通知
extension Notification.Name {
    static let moodDataDidChange = Notification.Name("moodDataDidChange")
}

/// Core Data CRUD管理器
class MoodDataManager: ObservableObject {
    static let shared = MoodDataManager()
    @Published var dataVersion: Int = 0

    let container: NSPersistentContainer
    let viewContext: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        self.viewContext = container.viewContext
    }

    // MARK: - MoodRecord CRUD

    /// 创建情绪记录
    func createMoodRecord(
        moodType: MoodType,
        moodSubType: MoodSubType,
        intensity: Int,
        tagNames: [String] = [],
        note: String? = nil
    ) throws -> MoodRecord {
        let record = MoodRecord(context: viewContext)
        record.id = UUID()
        record.moodType = moodType.rawValue
        record.moodSubType = moodSubType.rawValue
        record.intensity = Int16(intensity)
        record.note = note
        record.tagNames = tagNames.joined(separator: ",")
        record.createdAt = Date()
        record.updatedAt = Date()
        record.isSynced = false

        // 更新标签使用次数
        for tagName in tagNames {
            _ = getOrCreateTag(name: tagName)
        }

        try viewContext.save()
        notifyDataChange()
        return record
    }

    /// 获取所有情绪记录（按时间降序）
    func fetchAllRecords() -> [MoodRecord] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch records error: \(error)")
            return []
        }
    }

    /// 获取指定日期范围内的记录
    func fetchRecords(from startDate: Date, to endDate: Date) -> [MoodRecord] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch records error: \(error)")
            return []
        }
    }

    /// 获取指定日期的记录
    func fetchRecords(for date: Date) -> [MoodRecord] {
        fetchRecords(from: date.startOfDay, to: date.endOfDay)
    }

    /// 删除情绪记录
    func deleteRecord(_ record: MoodRecord) throws {
        viewContext.delete(record)
        try viewContext.save()
        notifyDataChange()
    }

    /// 批量删除记录
    func deleteRecords(_ records: [MoodRecord]) throws {
        for record in records {
            viewContext.delete(record)
        }
        try viewContext.save()
        notifyDataChange()
    }

    // MARK: - ActivityTag CRUD

    /// 获取或创建标签
    func getOrCreateTag(name: String, category: TagCategory = .selfCare, emoji: String = "📋", isCustom: Bool = false) -> ActivityTag {
        // 先查找已有标签
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        if let existing = try? viewContext.fetch(request).first {
            existing.usageCount += 1
            try? viewContext.save()
            return existing
        }

        // 创建新标签
        let tag = ActivityTag(context: viewContext)
        tag.id = UUID()
        tag.name = name
        tag.category = category.rawValue
        tag.emoji = emoji
        tag.isCustom = isCustom
        tag.usageCount = 1
        tag.createdAt = Date()
        try? viewContext.save()
        return tag
    }

    /// 获取常用标签（按使用频次排序，最多8个）
    func fetchFrequentTags(limit: Int = 8) -> [ActivityTag] {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]
        request.fetchLimit = limit
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch tags error: \(error)")
            return []
        }
    }

    /// 获取所有自定义标签
    func fetchCustomTags() -> [ActivityTag] {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch custom tags error: \(error)")
            return []
        }
    }

    /// 创建自定义标签
    func createCustomTag(name: String, category: TagCategory, emoji: String) throws -> ActivityTag {
        let tag = ActivityTag(context: viewContext)
        tag.id = UUID()
        tag.name = name
        tag.category = category.rawValue
        tag.emoji = emoji
        tag.isCustom = true
        tag.usageCount = 0
        tag.createdAt = Date()
        try viewContext.save()
        return tag
    }

    /// 删除自定义标签
    func deleteCustomTag(_ tag: ActivityTag) throws {
        guard tag.isCustom else { return }
        viewContext.delete(tag)
        try viewContext.save()
    }

    // MARK: - 统计查询

    /// 获取指定日期范围内的情绪类型分布
    func fetchMoodDistribution(from startDate: Date, to endDate: Date) -> [MoodType: Int] {
        let records = fetchRecords(from: startDate, to: endDate)
        var distribution: [MoodType: Int] = [:]
        for record in records {
            if let moodType = MoodType(rawValue: record.moodType ?? "happy") {
                distribution[moodType, default: 0] += 1
            }
        }
        return distribution
    }

    /// 获取指定日期范围内的标签频次Top N
    func fetchTopTags(from startDate: Date, to endDate: Date, limit: Int = 10) -> [(name: String, count: Int)] {
        let records = fetchRecords(from: startDate, to: endDate)
        var tagCount: [String: Int] = [:]
        for record in records {
            if let tagNamesStr = record.tagNames {
                let names = tagNamesStr.components(separatedBy: ",").filter { !$0.isEmpty }
                for name in names {
                    tagCount[name, default: 0] += 1
                }
            }
        }
        return tagCount.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }
    }

    /// 获取指定日期范围内的日均情绪强度
    func fetchDailyAverageIntensity(from startDate: Date, to endDate: Date) -> [(date: Date, intensity: Double)] {
        let records = fetchRecords(from: startDate, to: endDate)
        let calendar = Calendar.current

        var dailyData: [Date: [Int]] = [:]
        for record in records {
            if let createdAt = record.createdAt {
                let dayStart = calendar.startOfDay(for: createdAt)
                dailyData[dayStart, default: []].append(Int(record.intensity))
            }
        }

        return dailyData.map { (date: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }
    }

    /// 获取连续打卡天数
    func fetchStreakDays() -> Int {
        let records = fetchAllRecords()
        guard !records.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // 按日期分组（降序）
        let recordDates = Set(records.compactMap { calendar.startOfDay(for: $0.createdAt ?? Date()) })
        let sortedDates = recordDates.sorted(by: >)

        guard let latestDate = sortedDates.first else { return 0 }

        // 如果今天没有记录，从最近一次记录日期开始计算
        if !recordDates.contains(checkDate) {
            checkDate = latestDate
        }

        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if date < checkDate {
                break
            }
        }

        return streak
    }

    // MARK: - 预设标签初始化

    /// 初始化预设标签到Core Data（仅首次启动调用）
    func initializePresetTagsIfNeeded() {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        let count = (try? viewContext.count(for: request)) ?? 0
        guard count == 0 else { return } // 已有标签，跳过

        for category in TagCategory.allCases {
            for preset in category.presetTags {
                let tag = ActivityTag(context: viewContext)
                tag.id = UUID()
                tag.name = preset.name
                tag.category = category.rawValue
                tag.emoji = preset.emoji
                tag.isCustom = false
                tag.usageCount = 0
                tag.createdAt = Date()
            }
        }

        try? viewContext.save()
    }

    // MARK: - 更新记录

    /// 更新情绪记录
    func updateMoodRecord(
        _ record: MoodRecord,
        moodType: MoodType,
        moodSubType: MoodSubType,
        intensity: Int,
        tagNames: [String],
        note: String?
    ) throws {
        record.moodType = moodType.rawValue
        record.moodSubType = moodSubType.rawValue
        record.intensity = Int16(intensity)
        record.tagNames = tagNames.joined(separator: ",")
        record.note = note
        record.updatedAt = Date()
        try viewContext.save()
        notifyDataChange()
    }

    // MARK: - 辅助方法

    /// 从MoodRecord获取标签名列表
    static func tagNamesFromRecord(_ record: MoodRecord) -> [String] {
        guard let tagNamesStr = record.tagNames else { return [] }
        return tagNamesStr.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    /// 发送数据变更通知
    private func notifyDataChange() {
        DispatchQueue.main.async { [weak self] in
            self?.dataVersion += 1
            NotificationCenter.default.post(name: .moodDataDidChange, object: nil)
        }
    }
}