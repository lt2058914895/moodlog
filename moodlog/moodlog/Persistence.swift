//
//  Persistence.swift
//  moodlog
//
//  Created by deppon on 2026/6/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // 创建示例情绪记录
        let moodTypes: [(type: String, intensity: Int16)] = [
            ("happy", 8),
            ("sad", 4),
            ("anxious", 6),
            ("happy", 9),
            ("neutral", 3),
            ("happy", 7),
            ("angry", 5),
            ("happy", 6),
            ("anxious", 7),
            ("relaxed", 4),
        ]

        for (index, mood) in moodTypes.enumerated() {
            let record = MoodRecord(context: viewContext)
            record.id = UUID()
            record.moodType = mood.type
            record.intensity = mood.intensity
            record.createdAt = Calendar.current.date(byAdding: .hour, value: -index * 3, to: Date())
            record.updatedAt = record.createdAt
            record.isSynced = false
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    /// 后台上下文，用于耗时的查询操作
    private(set) var backgroundContext: NSManagedObjectContext

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "moodlog")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // 启用自动轻量迁移
        container.persistentStoreDescriptions.first?.setOption(true as NSObject, forKey: NSMigratePersistentStoresAutomaticallyOption)
        container.persistentStoreDescriptions.first?.setOption(true as NSObject, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        // 配置主上下文
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // 配置后台上下文
        backgroundContext = container.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// 在后台上下文中执行操作
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}