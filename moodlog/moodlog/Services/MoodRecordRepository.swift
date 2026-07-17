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
        moodSubType: MoodSubType,
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
        moodSubType: MoodSubType,
        intensity: Int,
        tagNames: [String],
        note: String?
    ) throws

    /// 辅助方法
    static func tagNamesFromRecord(_ record: MoodRecord) -> [String]
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

    // MARK: - Create（后台写入）

    func createMoodRecord(
        moodType: MoodType,
        moodSubType: MoodSubType,
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
            record.moodSubType = moodSubType.rawValue
            record.intensity = Int16(intensity)
            record.note = note
            record.tagNames = tagNames.joined(separator: ",")
            record.createdAt = Date()
            record.updatedAt = Date()
            record.isSynced = false

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
        moodSubType: MoodSubType,
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
                bgRecord?.moodSubType = moodSubType.rawValue
                bgRecord?.intensity = Int16(intensity)
                bgRecord?.tagNames = tagNames.joined(separator: ",")
                bgRecord?.note = note
                bgRecord?.updatedAt = Date()
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

    // MARK: - 辅助方法

    static func tagNamesFromRecord(_ record: MoodRecord) -> [String] {
        guard let tagNamesStr = record.tagNames else { return [] }
        return tagNamesStr.components(separatedBy: ",").filter { !$0.isEmpty }
    }
}
