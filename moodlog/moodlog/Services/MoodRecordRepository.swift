//
//  MoodRecordRepository.swift
//  moodlog
//
//  Created by deppon on 2026/7/1.
//

import CoreData
import Foundation
import os.log

/// 情绪记录仓储协议
protocol MoodRecordManaging {
    func createMoodRecord(
        moodType: MoodType,
        intensity: Int,
        tagNames: [String],
        note: String?
    ) throws -> MoodRecord

    func fetchAllRecords() -> [MoodRecord]
    func fetchRecords(from startDate: Date, to endDate: Date) -> [MoodRecord]
    func fetchRecords(for date: Date) -> [MoodRecord]
    func deleteRecord(_ record: MoodRecord) throws
    func deleteRecords(_ records: [MoodRecord]) throws
    func updateMoodRecord(
        _ record: MoodRecord,
        moodType: MoodType,
        intensity: Int,
        tagNames: [String],
        note: String?
    ) throws

    /// 辅助方法
    static func tagNamesFromRecord(_ record: MoodRecord) -> [String]

    /// 轻量查询：记录总数（不加载任何对象到内存）
    func fetchRecordCount() -> Int
    /// 轻量查询：最近一条记录的时间（fetchLimit=1，不遍历全部记录）
    func fetchLatestRecordDate() -> Date?
}

/// 情绪记录 CRUD 仓储（使用 backgroundContext 写入，避免主线程阻塞）
class MoodRecordRepository: MoodRecordManaging {
    let container: NSPersistentContainer
    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext

    private static let logger = Logger(subsystem: "com.moodlog.app", category: "MoodRecordRepository")

    init(container: NSPersistentContainer = PersistenceController.shared.container,
         backgroundContext: NSManagedObjectContext = PersistenceController.shared.backgroundContext) {
        self.container = container
        self.viewContext = container.viewContext
        self.backgroundContext = backgroundContext
    }

    // MARK: - 异步后台上下文执行辅助方法

    /// 在后台上下文异步执行操作（不阻塞主线程）
    private func performAsync<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                do {
                    let result = try block(self.backgroundContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 在主上下文异步执行操作
    private func performOnViewContextAsync<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            viewContext.perform {
                do {
                    let result = try block(self.viewContext)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Create（后台写入）

    func createMoodRecord(
        moodType: MoodType,
        intensity: Int,
        tagNames: [String] = [],
        note: String? = nil
    ) throws -> MoodRecord {
        Self.logger.info("Creating mood record: \(moodType.rawValue), intensity: \(intensity)")

        // 在后台上下文中创建记录
        var createdObjectID: NSManagedObjectID?
        var createError: MoodDataError?

        backgroundContext.performAndWait {
            let record = MoodRecord(context: backgroundContext)
            record.id = UUID()
            record.moodType = moodType.rawValue
            record.intensity = Int16(intensity)
            record.note = note
            record.createdAt = Date()
            record.updatedAt = Date()

            // 建立标签关系并更新使用时间
            let tags = getOrCreateTagsByNames(tagNames, in: backgroundContext)
            for tag in tags {
                tag.lastUsedAt = Date()
                tag.usageCount += 1
            }
            record.tags = NSSet(array: tags)

            do {
                try backgroundContext.save()
                createdObjectID = record.objectID
                Self.logger.info("Mood record created successfully on background context")
            } catch let saveError {
                Self.logger.error("Failed to create mood record: \(saveError.localizedDescription)")
                backgroundContext.rollback()
                createError = .createFailed(saveError.localizedDescription)
            }
        }

        if let createError = createError {
            throw createError
        }

        // 通过 objectID 在主上下文中获取刚创建的记录
        guard let objectID = createdObjectID,
              let record = try? viewContext.existingObject(with: objectID) as? MoodRecord else {
            throw MoodDataError.createFailed("Failed to fetch created record")
        }
        return record
    }

    // MARK: - Read（主上下文读取）

    func fetchAllRecords() -> [MoodRecord] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchBatchSize = 20
        do {
            return try viewContext.fetch(request)
        } catch {
            Self.logger.error("Fetch all records failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 轻量查询（避免全量加载）

    /// 记录总数（count 查询，不加载任何对象到内存）
    func fetchRecordCount() -> Int {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        do {
            let count = try viewContext.count(for: request)
            return max(count, 0)
        } catch {
            Self.logger.error("Count records failed: \(error.localizedDescription)")
            return 0
        }
    }

    /// 最近一条记录的时间（fetchLimit=1 降序，不遍历全部记录）
    func fetchLatestRecordDate() -> Date? {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = 1
        request.fetchBatchSize = 1
        do {
            return try viewContext.fetch(request).first?.createdAt
        } catch {
            Self.logger.error("Fetch latest record date failed: \(error.localizedDescription)")
            return nil
        }
    }

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
            Self.logger.error("Fetch records from \(startDate) to \(endDate) failed: \(error.localizedDescription)")
            return []
        }
    }

    func fetchRecords(for date: Date) -> [MoodRecord] {
        fetchRecords(from: date.startOfDay, to: date.endOfDay)
    }

    // MARK: - Delete（后台写入）

    func deleteRecord(_ record: MoodRecord) throws {
        Self.logger.info("Deleting mood record")

        let objectID = record.objectID
        var deleteError: MoodDataError?

        backgroundContext.performAndWait {
            do {
                let bgRecord = backgroundContext.object(with: objectID)
                backgroundContext.delete(bgRecord)
                try backgroundContext.save()
            } catch {
                Self.logger.error("Failed to delete mood record: \(error.localizedDescription)")
                deleteError = .deleteFailed(error.localizedDescription)
            }
        }

        if let deleteError = deleteError {
            throw deleteError
        }
    }

    func deleteRecords(_ records: [MoodRecord]) throws {
        Self.logger.info("Batch deleting \(records.count) records")

        let objectIDs = records.map { $0.objectID }
        var deleteError: MoodDataError?

        backgroundContext.performAndWait {
            do {
                for objectID in objectIDs {
                    let bgRecord = backgroundContext.object(with: objectID)
                    backgroundContext.delete(bgRecord)
                }
                try backgroundContext.save()
            } catch {
                Self.logger.error("Batch delete failed: \(error.localizedDescription)")
                deleteError = .deleteFailed(error.localizedDescription)
            }
        }

        if let deleteError = deleteError {
            throw deleteError
        }
    }

    // MARK: - Update（后台写入）

    func updateMoodRecord(
        _ record: MoodRecord,
        moodType: MoodType,
        intensity: Int,
        tagNames: [String],
        note: String?
    ) throws {
        Self.logger.info("Updating mood record")

        let objectID = record.objectID
        var updateError: MoodDataError?

        backgroundContext.performAndWait {
            do {
                let bgRecord = backgroundContext.object(with: objectID) as? MoodRecord
                bgRecord?.moodType = moodType.rawValue
                bgRecord?.intensity = Int16(intensity)
                bgRecord?.note = note
                bgRecord?.updatedAt = Date()

                // 更新标签关系并更新使用时间
                let tags = getOrCreateTagsByNames(tagNames, in: backgroundContext)
                for tag in tags {
                    tag.lastUsedAt = Date()
                    tag.usageCount += 1
                }
                bgRecord?.tags = NSSet(array: tags)

                try backgroundContext.save()
            } catch {
                Self.logger.error("Failed to update mood record: \(error.localizedDescription)")
                updateError = .updateFailed(error.localizedDescription)
            }
        }

        if let updateError = updateError {
            throw updateError
        }
    }

    // MARK: - 异步 CRUD（使用 async/await，不阻塞主线程）

    /// 异步创建情绪记录
    func createMoodRecordAsync(
        moodType: MoodType,
        intensity: Int,
        tagNames: [String] = [],
        note: String? = nil
    ) async throws -> MoodRecord {
        Self.logger.info("Creating mood record (async): \(moodType.rawValue), intensity: \(intensity)")

        let objectID: NSManagedObjectID = try await performAsync { ctx in
            let record = MoodRecord(context: ctx)
            record.id = UUID()
            record.moodType = moodType.rawValue
            record.intensity = Int16(intensity)
            record.note = note
            record.createdAt = Date()
            record.updatedAt = Date()

            let tags = self.getOrCreateTagsByNames(tagNames, in: ctx)
            for tag in tags {
                tag.lastUsedAt = Date()
                tag.usageCount += 1
            }
            record.tags = NSSet(array: tags)

            do {
                try ctx.save()
                Self.logger.info("Mood record created successfully (async)")
                return record.objectID
            } catch {
                ctx.rollback()
                Self.logger.error("Failed to create mood record: \(error.localizedDescription)")
                throw MoodDataError.createFailed(error.localizedDescription)
            }
        }

        // 在主上下文中获取刚创建的记录
        return try await performOnViewContextAsync { ctx in
            guard let record = try? ctx.existingObject(with: objectID) as? MoodRecord else {
                throw MoodDataError.createFailed("Failed to fetch created record")
            }
            return record
        }
    }

    /// 异步删除单条记录
    func deleteRecordAsync(_ record: MoodRecord) async throws {
        Self.logger.info("Deleting mood record (async)")
        let objectID = record.objectID

        try await performAsync { ctx in
            do {
                let bgRecord = ctx.object(with: objectID)
                ctx.delete(bgRecord)
                try ctx.save()
            } catch {
                Self.logger.error("Failed to delete mood record: \(error.localizedDescription)")
                throw MoodDataError.deleteFailed(error.localizedDescription)
            }
        }
    }

    /// 异步批量删除记录
    func deleteRecordsAsync(_ records: [MoodRecord]) async throws {
        Self.logger.info("Batch deleting \(records.count) records (async)")
        let objectIDs = records.map { $0.objectID }

        try await performAsync { ctx in
            do {
                for objectID in objectIDs {
                    let bgRecord = ctx.object(with: objectID)
                    ctx.delete(bgRecord)
                }
                try ctx.save()
            } catch {
                Self.logger.error("Batch delete failed: \(error.localizedDescription)")
                throw MoodDataError.deleteFailed(error.localizedDescription)
            }
        }
    }

    /// 异步更新记录
    func updateMoodRecordAsync(
        _ record: MoodRecord,
        moodType: MoodType,
        intensity: Int,
        tagNames: [String],
        note: String?
    ) async throws {
        Self.logger.info("Updating mood record (async)")
        let objectID = record.objectID

        try await performAsync { ctx in
            do {
                let bgRecord = ctx.object(with: objectID) as? MoodRecord
                bgRecord?.moodType = moodType.rawValue
                bgRecord?.intensity = Int16(intensity)
                bgRecord?.note = note
                bgRecord?.updatedAt = Date()

                let tags = self.getOrCreateTagsByNames(tagNames, in: ctx)
                for tag in tags {
                    tag.lastUsedAt = Date()
                    tag.usageCount += 1
                }
                bgRecord?.tags = NSSet(array: tags)

                try ctx.save()
            } catch {
                Self.logger.error("Failed to update mood record: \(error.localizedDescription)")
                throw MoodDataError.updateFailed(error.localizedDescription)
            }
        }
    }

    /// 异步分页查询记录（按创建时间倒序）
    func fetchRecords(limit: Int, offset: Int) -> [MoodRecord] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.fetchLimit = limit
        request.fetchOffset = offset
        request.fetchBatchSize = 20
        do {
            return try viewContext.fetch(request)
        } catch {
            Self.logger.error("Fetch records (limit: \(limit), offset: \(offset)) failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 辅助方法

    /// 从记录中获取标签名称列表（tags 关系为唯一数据源）
    static func tagNamesFromRecord(_ record: MoodRecord) -> [String] {
        // 统一走 tags 关系
        guard let tags = record.tags as? Set<ActivityTag> else { return [] }
        return tags.compactMap { $0.name }.sorted()
    }

    /// 在指定上下文中按名称 getOrCreate ActivityTag（保证 tags 关系完整，不依赖标签预初始化）
    private func getOrCreateTagsByNames(_ names: [String], in context: NSManagedObjectContext) -> [ActivityTag] {
        guard !names.isEmpty else { return [] }
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "name IN %@", names)
        do {
            let existing = try context.fetch(request)
            let existingNames = Set(existing.compactMap { $0.name })
            var result = existing
            // 不存在的名称创建为标签（预设标签带正确 emoji/分类，其余用默认值）
            for name in names where !existingNames.contains(name) {
                let tag = ActivityTag(context: context)
                tag.id = UUID()
                tag.name = name
                tag.category = (PresetTag.category(for: name) ?? .lifeEvent).rawValue
                tag.emoji = PresetTag.emoji(for: name) ?? "📋"
                tag.isCustom = false
                tag.usageCount = 0
                tag.createdAt = Date()
                result.append(tag)
            }
            return result
        } catch {
            Self.logger.error("Get-or-create tags by names failed: \(error.localizedDescription)")
            return []
        }
    }
}
