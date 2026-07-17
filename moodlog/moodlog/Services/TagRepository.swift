//
//  TagRepository.swift
//  moodlog
//
//  Created by deppon on 2026/7/1.
//

import CoreData
import Foundation
import os.log

/// 标签管理协议
protocol TagManaging {
    func getOrCreateTag(name: String, category: TagCategory, emoji: String, isCustom: Bool) -> ActivityTag
    func fetchFrequentTags(limit: Int) -> [ActivityTag]
    func fetchCustomTags() -> [ActivityTag]
    func createCustomTag(name: String, category: TagCategory, emoji: String) throws -> ActivityTag
    func deleteCustomTag(_ tag: ActivityTag) throws
    func initializePresetTagsIfNeeded()
}

/// 标签仓储（使用 backgroundContext 写入）
class TagRepository: TagManaging {
    let viewContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext

    private static let logger = Logger(subsystem: "com.moodlog.app", category: "TagRepository")

    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
         backgroundContext: NSManagedObjectContext = PersistenceController.shared.backgroundContext) {
        self.viewContext = viewContext
        self.backgroundContext = backgroundContext
    }

    // MARK: - 获取或创建标签（后台写入）

    func getOrCreateTag(name: String, category: TagCategory = .selfCare, emoji: String = "📋", isCustom: Bool = false) -> ActivityTag {
        // 先在主上下文查找已有标签
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        if let existing = try? viewContext.fetch(request).first {
            // 更新使用次数在后台上下文
            let objectID = existing.objectID
            backgroundContext.performAndWait {
                let bgTag = backgroundContext.object(with: objectID) as? ActivityTag
                bgTag?.usageCount += 1
                try? backgroundContext.save()
            }
            return existing
        }

        // 创建新标签在后台上下文
        var createdObjectID: NSManagedObjectID?
        backgroundContext.performAndWait {
            let tag = ActivityTag(context: backgroundContext)
            tag.id = UUID()
            tag.name = name
            tag.category = category.rawValue
            tag.emoji = emoji
            tag.isCustom = isCustom
            tag.usageCount = 1
            tag.createdAt = Date()
            do {
                try backgroundContext.save()
                createdObjectID = tag.objectID
            } catch {
                Self.logger.error("Failed to create tag: \(error.localizedDescription)")
            }
        }

        if let objectID = createdObjectID,
           let tag = try? viewContext.existingObject(with: objectID) as? ActivityTag {
            return tag
        }

        // 降级：返回一个在主上下文中的标签
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

    // MARK: - 读取（主上下文）

    func fetchFrequentTags(limit: Int = 8) -> [ActivityTag] {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]
        request.fetchLimit = limit
        request.fetchBatchSize = limit
        do {
            return try viewContext.fetch(request)
        } catch {
            Self.logger.error("Fetch frequent tags failed: \(error.localizedDescription)")
            return []
        }
    }

    func fetchCustomTags() -> [ActivityTag] {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]
        request.fetchBatchSize = 20
        do {
            return try viewContext.fetch(request)
        } catch {
            Self.logger.error("Fetch custom tags failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - 写入（后台上下文）

    func createCustomTag(name: String, category: TagCategory, emoji: String) throws -> ActivityTag {
        var createdObjectID: NSManagedObjectID?
        var createError: MoodDataError?

        backgroundContext.performAndWait {
            let tag = ActivityTag(context: backgroundContext)
            tag.id = UUID()
            tag.name = name
            tag.category = category.rawValue
            tag.emoji = emoji
            tag.isCustom = true
            tag.usageCount = 0
            tag.createdAt = Date()
            do {
                try backgroundContext.save()
                createdObjectID = tag.objectID
            } catch {
                Self.logger.error("Failed to create custom tag: \(error.localizedDescription)")
                createError = .tagCreationFailed(error.localizedDescription)
            }
        }

        if let createError = createError {
            throw createError
        }

        guard let objectID = createdObjectID,
              let tag = try? viewContext.existingObject(with: objectID) as? ActivityTag else {
            throw MoodDataError.tagCreationFailed("Failed to fetch created tag")
        }
        return tag
    }

    func deleteCustomTag(_ tag: ActivityTag) throws {
        guard tag.isCustom else { return }

        let objectID = tag.objectID
        var deleteError: MoodDataError?

        backgroundContext.performAndWait {
            do {
                let bgTag = backgroundContext.object(with: objectID)
                backgroundContext.delete(bgTag)
                try backgroundContext.save()
            } catch {
                Self.logger.error("Failed to delete custom tag: \(error.localizedDescription)")
                deleteError = .deleteFailed(error.localizedDescription)
            }
        }

        if let deleteError = deleteError {
            throw deleteError
        }
    }

    // MARK: - 预设标签初始化

    func initializePresetTagsIfNeeded() {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        let count = (try? viewContext.count(for: request)) ?? 0
        guard count == 0 else { return }

        Self.logger.info("Initializing preset tags")

        backgroundContext.performAndWait {
            for category in TagCategory.allCases {
                for preset in category.presetTags {
                    let tag = ActivityTag(context: backgroundContext)
                    tag.id = UUID()
                    tag.name = preset.name
                    tag.category = category.rawValue
                    tag.emoji = preset.emoji
                    tag.isCustom = false
                    tag.usageCount = 0
                    tag.createdAt = Date()
                }
            }
            do {
                try backgroundContext.save()
                Self.logger.info("Preset tags initialized successfully")
            } catch {
                Self.logger.error("Failed to initialize preset tags: \(error.localizedDescription)")
            }
        }
    }
}