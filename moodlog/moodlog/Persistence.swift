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
        let moodTypes: [(type: String, subType: String, intensity: Int16)] = [
            ("happy", "joyful", 8),
            ("sad", "lonely", 4),
            ("anxious", "worried", 6),
            ("happy", "excited", 9),
            ("neutral", "bored", 3),
            ("love", "warm", 7),
            ("angry", "irritated", 5),
            ("happy", "peaceful", 6),
            ("anxious", "tense", 7),
            ("thinking", "reflective", 4),
        ]

        for (index, mood) in moodTypes.enumerated() {
            let record = MoodRecord(context: viewContext)
            record.id = UUID()
            record.moodType = mood.type
            record.moodSubType = mood.subType
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

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "moodlog")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        // merge policy handled automatically
    }
}