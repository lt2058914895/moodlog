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
    func fetchTagByName(_ name: String) -> ActivityTag?
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

    func getOrCreateTag(name: String, category: TagCategory = .lifeEvent, emoji: String = "📋", isCustom: Bool = false) -> ActivityTag {
        // 先在主上下文查找已有标签
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        if let existing = try? viewContext.fetch(request).first {
            // 更新使用次数和最后使用时间在后台上下文
            let objectID = existing.objectID
            backgroundContext.performAndWait {
                let bgTag = backgroundContext.object(with: objectID) as? ActivityTag
                bgTag?.usageCount += 1
                bgTag?.lastUsedAt = Date()
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
            tag.lastUsedAt = Date()
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
        tag.lastUsedAt = Date()
        tag.createdAt = Date()
        try? viewContext.save()
        return tag
    }

    // MARK: - 读取（主上下文）

    func fetchFrequentTags(limit: Int = 8) -> [ActivityTag] {
        // 1. 先获取有使用记录的标签，按最近使用排序
        let usedRequest: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        usedRequest.predicate = NSPredicate(format: "lastUsedAt != nil")
        usedRequest.sortDescriptors = [NSSortDescriptor(key: "lastUsedAt", ascending: false)]
        usedRequest.fetchLimit = limit
        do {
            let usedTags = try viewContext.fetch(usedRequest)
            if usedTags.count >= limit {
                return Array(usedTags.prefix(limit))
            }
            // 2. 已用标签不足8个时，用默认标签补充（排除已使用的）
            let usedNames = Set(usedTags.compactMap { $0.name })
            let defaultTags = fetchDefaultTags(limit: limit - usedTags.count, excluding: usedNames)
            return usedTags + defaultTags
        } catch {
            Self.logger.error("Fetch frequent tags failed: \(error.localizedDescription)")
            return fetchDefaultTags(limit: limit, excluding: [])
        }
    }

    /// 获取默认标签（每个分类取第一个预设标签，排除已使用的）
    private func fetchDefaultTags(limit: Int = 8, excluding: Set<String> = []) -> [ActivityTag] {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == NO")
        request.sortDescriptors = [
            NSSortDescriptor(key: "category", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        request.fetchBatchSize = 100
        do {
            let allPresets = try viewContext.fetch(request)
            // 按分类分组，每组取第一个（排除已使用的标签名）
            var seenCategories = Set<String>()
            var defaultTags: [ActivityTag] = []
            for tag in allPresets {
                guard let category = tag.category, !seenCategories.contains(category) else { continue }
                guard let name = tag.name, !excluding.contains(name) else { continue }
                seenCategories.insert(category)
                defaultTags.append(tag)
                if defaultTags.count >= limit { break }
            }
            return defaultTags
        } catch {
            Self.logger.error("Fetch default tags failed: \(error.localizedDescription)")
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

    func fetchTagByName(_ name: String) -> ActivityTag? {
        let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
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

        if count == 0 {
            // 首次启动：全量初始化
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
        } else {
            // 已有标签：执行增量更新
            migrateSelfCareToLifeEvent()
            syncPresetTagsIncremental()
        }
    }

    // MARK: - selfCare → lifeEvent 数据迁移

    /// 将已有 selfCare 分类的标签迁移到 lifeEvent 分类
    private func migrateSelfCareToLifeEvent() {
        backgroundContext.performAndWait {
            let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", "selfCare")
            guard let selfCareTags = try? backgroundContext.fetch(request), !selfCareTags.isEmpty else {
                return
            }
            Self.logger.info("Migrating \(selfCareTags.count) selfCare tags to lifeEvent")
            for tag in selfCareTags {
                tag.category = "lifeEvent"
            }
            do {
                try backgroundContext.save()
                Self.logger.info("selfCare → lifeEvent migration completed")
            } catch {
                Self.logger.error("Failed to migrate selfCare tags: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 增量同步预设标签

    /// 补充新增的预设标签，删除已移除的预设标签
    private func syncPresetTagsIncremental() {
        backgroundContext.performAndWait {
            // 获取所有非自定义标签名称
            let request: NSFetchRequest<ActivityTag> = ActivityTag.fetchRequest()
            request.predicate = NSPredicate(format: "isCustom == NO")
            guard let existingPresets = try? backgroundContext.fetch(request) else { return }
            let existingNames = Set(existingPresets.map { $0.name ?? "" })

            // 构建当前应有的预设标签集合
            var currentPresets: Set<String> = []
            for category in TagCategory.allCases {
                for preset in category.presetTags {
                    currentPresets.insert(preset.name)
                }
            }

            // 添加新增的预设标签
            var addedCount = 0
            for category in TagCategory.allCases {
                for preset in category.presetTags {
                    if !existingNames.contains(preset.name) {
                        let tag = ActivityTag(context: backgroundContext)
                        tag.id = UUID()
                        tag.name = preset.name
                        tag.category = category.rawValue
                        tag.emoji = preset.emoji
                        tag.isCustom = false
                        tag.usageCount = 0
                        tag.createdAt = Date()
                        addedCount += 1
                    }
                }
            }

            // 删除已移除的预设标签（未被用户使用过的）
            var removedCount = 0
            for tag in existingPresets {
                guard let name = tag.name, !currentPresets.contains(name) else { continue }
                // 只删除未被使用的标签（usageCount == 0）
                if tag.usageCount == 0 {
                    backgroundContext.delete(tag)
                    removedCount += 1
                } else {
                    // 被使用过的标签保留，但更新分类到 lifeEvent（兜底）
                    if tag.category == "selfCare" {
                        tag.category = "lifeEvent"
                    }
                }
            }

            if addedCount > 0 || removedCount > 0 {
                do {
                    try backgroundContext.save()
                    Self.logger.info("Preset tags sync: added \(addedCount), removed \(removedCount)")
                } catch {
                    Self.logger.error("Failed to sync preset tags: \(error.localizedDescription)")
                }
            }
        }
    }
}