//
//  MoodDataManager.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//  重构于 2026/7/1 — 拆分为 MoodRecordRepository / TagRepository / StatisticsService / CacheManager
//

import CoreData
import Foundation
import os.log

/// 数据变更通知
extension Notification.Name {
    static let moodDataDidChange = Notification.Name("moodDataDidChange")
}

/// 数据操作错误类型
enum MoodDataError: LocalizedError {
    case createFailed(String)
    case deleteFailed(String)
    case updateFailed(String)
    case fetchFailed(String)
    case tagCreationFailed(String)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .createFailed(let detail): return String(format: L.localized("error.create_failed"), detail)
        case .deleteFailed(let detail): return String(format: L.localized("error.delete_failed"), detail)
        case .updateFailed(let detail): return String(format: L.localized("error.update_failed"), detail)
        case .fetchFailed(let detail): return String(format: L.localized("error.fetch_failed"), detail)
        case .tagCreationFailed(let detail): return String(format: L.localized("error.tag_creation_failed"), detail)
        case .invalidData(let detail): return String(format: L.localized("error.invalid_data"), detail)
        }
    }
}

// MARK: - MoodDataManaging 组合协议

/// 数据管理组合协议（面向 ViewModel 的统一接口）
protocol MoodDataManaging: ObservableObject {
    var lastError: MoodDataError? { get set }

    // MoodRecord CRUD
    func createMoodRecord(moodType: MoodType, intensity: Int, tagNames: [String], note: String?) throws -> MoodRecord
    func fetchAllRecords() -> [MoodRecord]
    func fetchRecords(from startDate: Date, to endDate: Date) -> [MoodRecord]
    func fetchRecords(for date: Date) -> [MoodRecord]
    func fetchRecords(limit: Int, offset: Int) -> [MoodRecord]
    /// 记录总数（count 查询，不加载对象）
    func fetchRecordCount() -> Int
    /// 最近一条记录时间（fetchLimit=1）
    func fetchLatestRecordDate() -> Date?
    func deleteRecord(_ record: MoodRecord) throws
    func deleteRecords(_ records: [MoodRecord]) throws
    func updateMoodRecord(_ record: MoodRecord, moodType: MoodType, intensity: Int, tagNames: [String], note: String?) throws

    // MoodRecord Async CRUD（异步，不阻塞主线程）
    func createMoodRecordAsync(moodType: MoodType, intensity: Int, tagNames: [String], note: String?) async throws -> MoodRecord
    func deleteRecordAsync(_ record: MoodRecord) async throws
    func deleteRecordsAsync(_ records: [MoodRecord]) async throws
    func updateMoodRecordAsync(_ record: MoodRecord, moodType: MoodType, intensity: Int, tagNames: [String], note: String?) async throws

    // Tag
    func getOrCreateTag(name: String, category: TagCategory, emoji: String, isCustom: Bool) -> ActivityTag
    func fetchFrequentTags(limit: Int) -> [ActivityTag]
    func fetchCustomTags() -> [ActivityTag]
    func fetchTagByName(_ name: String) -> ActivityTag?
    func createCustomTag(name: String, category: TagCategory, emoji: String) throws -> ActivityTag
    func deleteCustomTag(_ tag: ActivityTag) throws
    func initializePresetTagsIfNeeded()

    // Statistics
    func fetchMoodDistribution(from startDate: Date, to endDate: Date) -> [MoodType: Int]
    func fetchTopTags(from startDate: Date, to endDate: Date, limit: Int) -> [(name: String, count: Int)]
    func fetchAvailableYears() -> [Int]
    func fetchStreakDays() -> Int
    func fetchDayRecordCounts(year: Int, month: Int) -> [Date: Int]
    func fetchDayPrimaryMoods(year: Int, month: Int) -> [Date: MoodType]
    func fetchDayAverageIntensities(year: Int, month: Int) -> [Date: Double]
    func performQuery<T>(on queue: DispatchQueue, query: @escaping (NSManagedObjectContext) -> T, completion: @escaping (T) -> Void)

    // 辅助
    static func tagNamesFromRecord(_ record: MoodRecord) -> [String]

    /// 根据标签名获取emoji，优先查预设标签，再查自定义标签
    static func emojiForTagName(_ name: String) -> String
}

// MARK: - MoodDataManager 门面（组合子组件）

/// 数据管理门面（组合 MoodRecordRepository + TagRepository + StatisticsService + CacheManager）
class MoodDataManager: MoodDataManaging {
    static let shared = MoodDataManager()

    @Published var lastError: MoodDataError?

    let container: NSPersistentContainer
    let viewContext: NSManagedObjectContext

    // 子组件
    let recordRepository: MoodRecordRepository
    let tagRepository: TagRepository
    let statisticsService: StatisticsService
    let cacheManager: CacheManaging

    private static let logger = Logger(subsystem: "com.moodlog.app", category: "MoodDataManager")

    init(container: NSPersistentContainer = PersistenceController.shared.container,
         backgroundContext: NSManagedObjectContext = PersistenceController.shared.backgroundContext,
         cacheManager: CacheManaging? = nil) {
        self.container = container
        self.viewContext = container.viewContext
        self.cacheManager = cacheManager ?? CacheManager()

        self.recordRepository = MoodRecordRepository(container: container, backgroundContext: backgroundContext)
        self.tagRepository = TagRepository(viewContext: container.viewContext, backgroundContext: backgroundContext)
        self.statisticsService = StatisticsService(viewContext: container.viewContext, backgroundContext: backgroundContext, cache: self.cacheManager)
    }

    // 便利初始化（用于测试注入）
    convenience init(recordRepository: MoodRecordRepository,
                     tagRepository: TagRepository,
                     statisticsService: StatisticsService,
                     cacheManager: CacheManaging) {
        self.init(container: recordRepository.container,
                  backgroundContext: recordRepository.backgroundContext,
                  cacheManager: cacheManager)
    }

    // MARK: - MoodRecord CRUD（委托）

    func createMoodRecord(moodType: MoodType, intensity: Int, tagNames: [String] = [], note: String? = nil) throws -> MoodRecord {
        do {
            let record = try recordRepository.createMoodRecord(
                moodType: moodType, intensity: intensity, tagNames: tagNames, note: note
            )
            cacheManager.clearCache()
            notifyDataChange()
            return record
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.createFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func fetchAllRecords() -> [MoodRecord] { recordRepository.fetchAllRecords() }
    func fetchRecordCount() -> Int { recordRepository.fetchRecordCount() }
    func fetchLatestRecordDate() -> Date? { recordRepository.fetchLatestRecordDate() }
    func fetchRecords(from startDate: Date, to endDate: Date) -> [MoodRecord] { recordRepository.fetchRecords(from: startDate, to: endDate) }
    func fetchRecords(for date: Date) -> [MoodRecord] { recordRepository.fetchRecords(for: date) }

    func deleteRecord(_ record: MoodRecord) throws {
        do {
            try recordRepository.deleteRecord(record)
            cacheManager.clearCache()
            notifyDataChange()
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.deleteFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func deleteRecords(_ records: [MoodRecord]) throws {
        do {
            try recordRepository.deleteRecords(records)
            cacheManager.clearCache()
            notifyDataChange()
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.deleteFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func updateMoodRecord(_ record: MoodRecord, moodType: MoodType, intensity: Int, tagNames: [String], note: String?) throws {
        do {
            try recordRepository.updateMoodRecord(record, moodType: moodType, intensity: intensity, tagNames: tagNames, note: note)
            cacheManager.clearCache()
            notifyDataChange()
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.updateFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    // MARK: - MoodRecord Async CRUD（异步委托）

    func createMoodRecordAsync(moodType: MoodType, intensity: Int, tagNames: [String], note: String?) async throws -> MoodRecord {
        do {
            let record = try await recordRepository.createMoodRecordAsync(
                moodType: moodType, intensity: intensity, tagNames: tagNames, note: note
            )
            cacheManager.clearCache()
            notifyDataChange()
            return record
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.createFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func deleteRecordAsync(_ record: MoodRecord) async throws {
        do {
            try await recordRepository.deleteRecordAsync(record)
            cacheManager.clearCache()
            notifyDataChange()
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.deleteFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func deleteRecordsAsync(_ records: [MoodRecord]) async throws {
        do {
            try await recordRepository.deleteRecordsAsync(records)
            cacheManager.clearCache()
            notifyDataChange()
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.deleteFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func updateMoodRecordAsync(_ record: MoodRecord, moodType: MoodType, intensity: Int, tagNames: [String], note: String?) async throws {
        do {
            try await recordRepository.updateMoodRecordAsync(record, moodType: moodType, intensity: intensity, tagNames: tagNames, note: note)
            cacheManager.clearCache()
            notifyDataChange()
        } catch let error as MoodDataError {
            lastError = error
            throw error
        } catch {
            let moodError = MoodDataError.updateFailed(error.localizedDescription)
            lastError = moodError
            throw moodError
        }
    }

    func fetchRecords(limit: Int, offset: Int) -> [MoodRecord] {
        recordRepository.fetchRecords(limit: limit, offset: offset)
    }

    // MARK: - Tag（委托）

    func getOrCreateTag(name: String, category: TagCategory = .lifeEvent, emoji: String = "📋", isCustom: Bool = false) -> ActivityTag {
        tagRepository.getOrCreateTag(name: name, category: category, emoji: emoji, isCustom: isCustom)
    }

    func fetchFrequentTags(limit: Int = 8) -> [ActivityTag] { tagRepository.fetchFrequentTags(limit: limit) }
    func fetchCustomTags() -> [ActivityTag] { tagRepository.fetchCustomTags() }
    func fetchTagByName(_ name: String) -> ActivityTag? { tagRepository.fetchTagByName(name) }

    func createCustomTag(name: String, category: TagCategory, emoji: String) throws -> ActivityTag {
        try tagRepository.createCustomTag(name: name, category: category, emoji: emoji)
    }

    func deleteCustomTag(_ tag: ActivityTag) throws {
        try tagRepository.deleteCustomTag(tag)
    }

    func initializePresetTagsIfNeeded() {
        tagRepository.initializePresetTagsIfNeeded()
    }

    // MARK: - Statistics（委托）

    func fetchMoodDistribution(from startDate: Date, to endDate: Date) -> [MoodType: Int] {
        statisticsService.fetchMoodDistribution(from: startDate, to: endDate)
    }

    func fetchTopTags(from startDate: Date, to endDate: Date, limit: Int = 10) -> [(name: String, count: Int)] {
        statisticsService.fetchTopTags(from: startDate, to: endDate, limit: limit)
    }

    func fetchAvailableYears() -> [Int] { statisticsService.fetchAvailableYears() }
    func fetchStreakDays() -> Int { statisticsService.fetchStreakDays() }
    func fetchDayRecordCounts(year: Int, month: Int) -> [Date: Int] { statisticsService.fetchDayRecordCounts(year: year, month: month) }
    func fetchDayPrimaryMoods(year: Int, month: Int) -> [Date: MoodType] { statisticsService.fetchDayPrimaryMoods(year: year, month: month) }
    func fetchDayAverageIntensities(year: Int, month: Int) -> [Date: Double] { statisticsService.fetchDayAverageIntensities(year: year, month: month) }

    func performQuery<T>(on queue: DispatchQueue = .global(qos: .userInitiated),
                         query: @escaping (NSManagedObjectContext) -> T,
                         completion: @escaping (T) -> Void) {
        statisticsService.performQuery(on: queue, query: query, completion: completion)
    }

    // MARK: - 辅助方法

    static func tagNamesFromRecord(_ record: MoodRecord) -> [String] {
        MoodRecordRepository.tagNamesFromRecord(record)
    }

    /// 根据标签名获取emoji，优先查预设标签，再查自定义标签
    static func emojiForTagName(_ name: String) -> String {
        // 优先查预设标签
        if let emoji = PresetTag.emoji(for: name) {
            return emoji
        }
        // 查自定义标签
        if let tag = shared.tagRepository.fetchTagByName(name) {
            return tag.emoji ?? "📋"
        }
        return "📋"
    }

    /// 发送数据变更通知（统一走 NotificationCenter）
    private func notifyDataChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .moodDataDidChange, object: nil)
        }
    }
}