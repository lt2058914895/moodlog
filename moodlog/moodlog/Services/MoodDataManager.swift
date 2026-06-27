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

/// 缓存键
private enum CacheKey {
    static func dailyIntensity(start: Date, end: Date) -> String {
        "daily_intensity_\(Int(start.timeIntervalSince1970))_\(Int(end.timeIntervalSince1970))"
    }
    static func monthlyIntensity(year: Int) -> String {
        "monthly_intensity_\(year)"
    }
    static func moodDistribution(start: Date, end: Date) -> String {
        "mood_dist_\(Int(start.timeIntervalSince1970))_\(Int(end.timeIntervalSince1970))"
    }
    static func topTags(start: Date, end: Date, limit: Int) -> String {
        "top_tags_\(Int(start.timeIntervalSince1970))_\(Int(end.timeIntervalSince1970))_\(limit)"
    }
    static let streakDays = "streak_days"
    static let availableYears = "available_years"
}

/// Core Data CRUD管理器（性能优化版）
class MoodDataManager: ObservableObject {
    static let shared = MoodDataManager()
    @Published var dataVersion: Int = 0

    let container: NSPersistentContainer
    let viewContext: NSManagedObjectContext

    /// 后台上下文用于耗时查询
    private let backgroundContext: NSManagedObjectContext

    /// 统计数据缓存
    private let cache = NSCache<NSString, CacheWrapper>()
    private let cacheExpiry: TimeInterval = 30 // 缓存30秒

    init(container: NSPersistentContainer = PersistenceController.shared.container,
         backgroundContext: NSManagedObjectContext = PersistenceController.shared.backgroundContext) {
        self.container = container
        self.viewContext = container.viewContext
        self.backgroundContext = backgroundContext

        // 配置缓存
        cache.countLimit = 50
    }

    // MARK: - 缓存管理

    /// 缓存包装器
    private class CacheWrapper {
        let data: Any
        let expiry: Date

        init(data: Any) {
            self.data = data
            self.expiry = Date().addingTimeInterval(30)
        }

        var isExpired: Bool {
            Date() > expiry
        }
    }

    /// 存入缓存
    private func cacheSet(_ key: String, data: Any) {
        cache.setObject(CacheWrapper(data: data), forKey: key as NSString)
    }

    /// 读取缓存
    private func cacheGet<T>(_ key: String, type: T.Type) -> T? {
        guard let wrapper = cache.object(forKey: key as NSString),
              !wrapper.isExpired,
              let data = wrapper.data as? T else {
            return nil
        }
        return data
    }

    /// 清除所有缓存
    private func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - MoodRecord CRUD

    /// 创建情绪记录（主线程写入）
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
        clearCache()
        notifyDataChange()
        return record
    }

    /// 获取所有情绪记录（按时间降序，带批量大小）
    func fetchAllRecords() -> [MoodRecord] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchBatchSize = 20
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch records error: \(error)")
            return []
        }
    }

    /// 获取指定日期范围内的记录（带批量大小）
    func fetchRecords(from startDate: Date, to endDate: Date) -> [MoodRecord] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchBatchSize = 50
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
        clearCache()
        notifyDataChange()
    }

    /// 批量删除记录
    func deleteRecords(_ records: [MoodRecord]) throws {
        for record in records {
            viewContext.delete(record)
        }
        try viewContext.save()
        clearCache()
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
        request.fetchBatchSize = limit
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
        request.fetchBatchSize = 20
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

    // MARK: - 统计查询（带缓存）

    /// 获取指定日期范围内的情绪类型分布（带缓存）
    func fetchMoodDistribution(from startDate: Date, to endDate: Date) -> [MoodType: Int] {
        let key = CacheKey.moodDistribution(start: startDate, end: endDate)
        if let cached = cacheGet(key, type: [MoodType: Int].self) {
            return cached
        }

        // 使用数据库端聚合
        let request = NSFetchRequest<NSDictionary>(entityName: "MoodRecord")
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        request.resultType = .dictionaryResultType

        let moodTypeExpr = NSExpression(forKeyPath: "moodType")
        let countExpr = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "moodType")])

        let moodTypeDesc = NSExpressionDescription()
        moodTypeDesc.name = "moodType"
        moodTypeDesc.expression = moodTypeExpr
        moodTypeDesc.expressionResultType = .stringAttributeType

        let countDesc = NSExpressionDescription()
        countDesc.name = "count"
        countDesc.expression = countExpr
        countDesc.expressionResultType = .integer16AttributeType

        request.propertiesToGroupBy = ["moodType"]
        request.propertiesToFetch = [moodTypeDesc, countDesc]

        var result: [MoodType: Int] = [:]
        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            for dict in results {
                if let moodStr = dict["moodType"] as? String,
                   let moodType = MoodType(rawValue: moodStr),
                   let count = dict["count"] as? Int {
                    result[moodType] = count
                }
            }
        } catch {
            print("Fetch mood distribution error: \(error)")
            // 降级到内存计算
            return fetchMoodDistributionFallback(from: startDate, to: endDate)
        }

        cacheSet(key, data: result)
        return result
    }

    /// 情绪分布降级查询（内存计算）
    private func fetchMoodDistributionFallback(from startDate: Date, to endDate: Date) -> [MoodType: Int] {
        let records = fetchRecords(from: startDate, to: endDate)
        var distribution: [MoodType: Int] = [:]
        for record in records {
            if let moodType = MoodType(rawValue: record.moodType ?? "happy") {
                distribution[moodType, default: 0] += 1
            }
        }
        return distribution
    }

    /// 获取指定日期范围内的标签频次Top N（带缓存）
    func fetchTopTags(from startDate: Date, to endDate: Date, limit: Int = 10) -> [(name: String, count: Int)] {
        let key = CacheKey.topTags(start: startDate, end: endDate, limit: limit)
        if let cached = cacheGet(key, type: [(name: String, count: Int)].self) {
            return cached
        }

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
        let result = tagCount.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }

        cacheSet(key, data: result)
        return result
    }

    /// 获取指定日期范围内的日均情绪强度（带缓存）
    func fetchDailyAverageIntensity(from startDate: Date, to endDate: Date) -> [(date: Date, intensity: Double)] {
        let key = CacheKey.dailyIntensity(start: startDate, end: endDate)
        if let cached = cacheGet(key, type: [(date: Date, intensity: Double)].self) {
            return cached
        }

        let records = fetchRecords(from: startDate, to: endDate)
        let calendar = Calendar.current

        var dailyData: [Date: [Int]] = [:]
        for record in records {
            if let createdAt = record.createdAt {
                let dayStart = calendar.startOfDay(for: createdAt)
                dailyData[dayStart, default: []].append(Int(record.intensity))
            }
        }

        let result = dailyData.map { (date: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }

        cacheSet(key, data: result)
        return result
    }

    /// 获取指定年份的月均情绪强度（带缓存）
    func fetchMonthlyAverageIntensity(for year: Int) -> [(month: Int, intensity: Double)] {
        let key = CacheKey.monthlyIntensity(year: year)
        if let cached = cacheGet(key, type: [(month: Int, intensity: Double)].self) {
            return cached
        }

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        guard let yearStart = calendar.date(from: components) else { return [] }
        components.year = year + 1
        guard let yearEnd = calendar.date(from: components) else { return [] }

        let records = fetchRecords(from: yearStart, to: yearEnd)

        var monthlyData: [Int: [Int]] = [:]
        for record in records {
            if let createdAt = record.createdAt {
                let month = calendar.component(.month, from: createdAt)
                monthlyData[month, default: []].append(Int(record.intensity))
            }
        }

        let result = monthlyData.map { (month: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.month < $1.month }

        cacheSet(key, data: result)
        return result
    }

    /// 获取有数据的年份列表（降序，带缓存）
    func fetchAvailableYears() -> [Int] {
        if let cached = cacheGet(CacheKey.availableYears, type: [Int].self) {
            return cached
        }

        let records = fetchAllRecords()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        var years = Set<Int>()
        years.insert(currentYear)
        for record in records {
            if let createdAt = record.createdAt {
                let year = calendar.component(.year, from: createdAt)
                years.insert(year)
            }
        }
        let result = years.sorted(by: >)

        cacheSet(CacheKey.availableYears, data: result)
        return result
    }

    /// 获取连续打卡天数（带缓存）
    func fetchStreakDays() -> Int {
        if let cached = cacheGet(CacheKey.streakDays, type: Int.self) {
            return cached
        }

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

        cacheSet(CacheKey.streakDays, data: streak)
        return streak
    }

    // MARK: - 后台查询

    /// 在后台线程执行查询，结果回调到主线程
    func performQuery<T>(on backgroundQueue: DispatchQueue = .global(qos: .userInitiated),
                         query: @escaping (NSManagedObjectContext) -> T,
                         completion: @escaping (T) -> Void) {
        backgroundQueue.async {
            let result = query(self.backgroundContext)
            DispatchQueue.main.async {
                completion(result)
            }
        }
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
        clearCache()
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