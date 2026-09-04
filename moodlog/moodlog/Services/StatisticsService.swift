//
//  StatisticsService.swift
//  moodlog
//
//  Created by deppon on 2026/7/1.
//

import CoreData
import Foundation
import os.log

/// 统计查询协议
protocol StatisticsProviding {
    func fetchMoodDistribution(from startDate: Date, to endDate: Date) -> [MoodType: Int]
    func fetchTopTags(from startDate: Date, to endDate: Date, limit: Int) -> [(name: String, count: Int)]
    func fetchAvailableYears() -> [Int]
    func fetchStreakDays() -> Int
    func fetchDayRecordCounts(year: Int, month: Int) -> [Date: Int]
    func fetchDayPrimaryMoods(year: Int, month: Int) -> [Date: MoodType]
    func fetchDayAverageIntensities(year: Int, month: Int) -> [Date: Double]
    func performQuery<T>(on queue: DispatchQueue, query: @escaping (NSManagedObjectContext) -> T, completion: @escaping (T) -> Void)
}

/// 统计查询服务（带缓存 + 数据库端聚合）
class StatisticsService: StatisticsProviding {
    let viewContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private let cache: CacheManaging

    private static let logger = Logger(subsystem: "com.moodlog.app", category: "StatisticsService")

    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
         backgroundContext: NSManagedObjectContext = PersistenceController.shared.backgroundContext,
         cache: CacheManaging = CacheManager()) {
        self.viewContext = viewContext
        self.backgroundContext = backgroundContext
        self.cache = cache
    }

    // MARK: - 情绪分布

    func fetchMoodDistribution(from startDate: Date, to endDate: Date) -> [MoodType: Int] {
        let key = CacheKey.moodDistribution(start: startDate, end: endDate)
        if let cached = cache.cacheGet(key, type: [MoodType: Int].self) {
            return cached
        }

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
            Self.logger.error("DB aggregation for mood distribution failed, falling back: \(error.localizedDescription)")
            return fetchMoodDistributionFallback(from: startDate, to: endDate)
        }

        cache.cacheSet(key, data: result)
        return result
    }

    private func fetchMoodDistributionFallback(from startDate: Date, to endDate: Date) -> [MoodType: Int] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        var distribution: [MoodType: Int] = [:]
        do {
            let records = try viewContext.fetch(request)
            for record in records {
                if let moodType = MoodType(rawValue: record.moodType ?? "happy") {
                    distribution[moodType, default: 0] += 1
                }
            }
        } catch {
            Self.logger.error("Fallback mood distribution query failed: \(error.localizedDescription)")
        }
        return distribution
    }

    // MARK: - 标签频次

    func fetchTopTags(from startDate: Date, to endDate: Date, limit: Int = 10) -> [(name: String, count: Int)] {
        let key = CacheKey.topTags(start: startDate, end: endDate, limit: limit)
        if let cached = cache.cacheGet(key, type: [(name: String, count: Int)].self) {
            return cached
        }

        // 通过 tags 关系聚合，避免在 UI 层加载完整记录字段
        let result = fetchTopTagsLightweight(from: startDate, to: endDate, limit: limit)
        cache.cacheSet(key, data: result)
        return result
    }

    /// 标签频次聚合：通过 tags 关系统计
    private func fetchTopTagsLightweight(from startDate: Date, to endDate: Date, limit: Int) -> [(name: String, count: Int)] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        // 预取 tags 关系，避免逐条触发 faults（N+1 查询）
        request.relationshipKeyPathsForPrefetching = ["tags"]
        request.fetchBatchSize = 50

        var tagCount: [String: Int] = [:]
        do {
            let records = try viewContext.fetch(request)
            for record in records {
                for name in MoodRecordRepository.tagNamesFromRecord(record) {
                    tagCount[name, default: 0] += 1
                }
            }
        } catch {
            Self.logger.error("Top tags query failed: \(error.localizedDescription)")
        }

        return tagCount.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }
    }

    // MARK: - 可用年份

    func fetchAvailableYears() -> [Int] {
        if let cached = cache.cacheGet(CacheKey.availableYears, type: [Int].self) {
            return cached
        }

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.resultType = .dictionaryResultType

        let dateDesc = NSExpressionDescription()
        dateDesc.name = "createdDate"
        dateDesc.expression = NSExpression(forKeyPath: "createdAt")
        dateDesc.expressionResultType = .dateAttributeType

        request.propertiesToFetch = [dateDesc]

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var years = Set<Int>()
        years.insert(currentYear)

        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            for dict in results {
                if let date = dict["createdDate"] as? Date {
                    let year = calendar.component(.year, from: date)
                    years.insert(year)
                }
            }
        } catch {
            Self.logger.error("Lightweight query for available years failed: \(error.localizedDescription)")
            let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
            if let records = try? viewContext.fetch(request) {
                for record in records {
                    if let createdAt = record.createdAt {
                        let year = calendar.component(.year, from: createdAt)
                        years.insert(year)
                    }
                }
            }
        }

        let result = years.sorted(by: >)
        // 可用年份极少变化，使用1小时长缓存
        cache.cacheSet(CacheKey.availableYears, data: result, expiry: 3600)
        return result
    }

    // MARK: - 连续记录天数

    func fetchStreakDays() -> Int {
        if let cached = cache.cacheGet(CacheKey.streakDays, type: Int.self) {
            return cached
        }

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.resultType = .dictionaryResultType
        let dateDesc = NSExpressionDescription()
        dateDesc.name = "createdDate"
        dateDesc.expression = NSExpression(forKeyPath: "createdAt")
        dateDesc.expressionResultType = .dateAttributeType
        request.propertiesToFetch = [dateDesc]
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            let recordDates = Set(results.compactMap { dict -> Date? in
                guard let date = dict["createdDate"] as? Date else { return nil }
                return calendar.startOfDay(for: date)
            })
            let sortedDates = recordDates.sorted(by: >)

            guard let latestDate = sortedDates.first else {
                cache.cacheSet(CacheKey.streakDays, data: 0)
                return 0
            }

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
        } catch {
            Self.logger.error("Fetch streak days failed: \(error.localizedDescription)")
        }

        cache.cacheSet(CacheKey.streakDays, data: streak)
        return streak
    }

    // MARK: - 日历轻量查询

    func fetchDayRecordCounts(year: Int, month: Int) -> [Date: Int] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let monthStart = calendar.date(from: components) else { return [:] }
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [:] }

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            monthStart as CVarArg,
            monthEnd as CVarArg
        )
        request.resultType = .dictionaryResultType

        let dateDesc = NSExpressionDescription()
        dateDesc.name = "createdDate"
        dateDesc.expression = NSExpression(forKeyPath: "createdAt")
        dateDesc.expressionResultType = .dateAttributeType

        request.propertiesToFetch = [dateDesc]

        var result: [Date: Int] = [:]
        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            for dict in results {
                if let date = dict["createdDate"] as? Date {
                    let dayStart = calendar.startOfDay(for: date)
                    result[dayStart, default: 0] += 1
                }
            }
        } catch {
            Self.logger.error("Fetch day record counts failed: \(error.localizedDescription)")
        }
        return result
    }

    func fetchDayPrimaryMoods(year: Int, month: Int) -> [Date: MoodType] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let monthStart = calendar.date(from: components) else { return [:] }
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [:] }

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            monthStart as CVarArg,
            monthEnd as CVarArg
        )
        request.resultType = .dictionaryResultType

        let dateDesc = NSExpressionDescription()
        dateDesc.name = "createdDate"
        dateDesc.expression = NSExpression(forKeyPath: "createdAt")
        dateDesc.expressionResultType = .dateAttributeType

        let moodDesc = NSExpressionDescription()
        moodDesc.name = "moodTypeValue"
        moodDesc.expression = NSExpression(forKeyPath: "moodType")
        moodDesc.expressionResultType = .stringAttributeType

        let intensityDesc = NSExpressionDescription()
        intensityDesc.name = "intensityValue"
        intensityDesc.expression = NSExpression(forKeyPath: "intensity")
        intensityDesc.expressionResultType = .integer16AttributeType

        request.propertiesToFetch = [dateDesc, moodDesc, intensityDesc]
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        var result: [Date: MoodType] = [:]
        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            for dict in results {
                if let date = dict["createdDate"] as? Date,
                   let moodStr = dict["moodTypeValue"] as? String,
                   let moodType = MoodType(rawValue: moodStr) {
                    let dayStart = calendar.startOfDay(for: date)
                    if result[dayStart] == nil {
                        result[dayStart] = moodType
                    }
                }
            }
        } catch {
            Self.logger.error("Fetch day primary moods failed: \(error.localizedDescription)")
        }
        return result
    }

    func fetchDayAverageIntensities(year: Int, month: Int) -> [Date: Double] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let monthStart = calendar.date(from: components) else { return [:] }
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [:] }

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            monthStart as CVarArg,
            monthEnd as CVarArg
        )
        request.resultType = .dictionaryResultType

        let dateDesc = NSExpressionDescription()
        dateDesc.name = "createdDate"
        dateDesc.expression = NSExpression(forKeyPath: "createdAt")
        dateDesc.expressionResultType = .dateAttributeType

        let intensityDesc = NSExpressionDescription()
        intensityDesc.name = "intensityValue"
        intensityDesc.expression = NSExpression(forKeyPath: "intensity")
        intensityDesc.expressionResultType = .integer16AttributeType

        request.propertiesToFetch = [dateDesc, intensityDesc]

        var dailyData: [Date: [Int]] = [:]
        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            for dict in results {
                if let date = dict["createdDate"] as? Date,
                   let intensity = dict["intensityValue"] as? Int {
                    let dayStart = calendar.startOfDay(for: date)
                    dailyData[dayStart, default: []].append(intensity)
                }
            }
        } catch {
            Self.logger.error("Fetch day average intensities failed: \(error.localizedDescription)")
        }

        return dailyData.mapValues { intensities in
            Double(intensities.reduce(0, +)) / Double(intensities.count)
        }
    }

    // MARK: - 后台查询

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
}
