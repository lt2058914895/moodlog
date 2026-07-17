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
    func fetchDailyAverageIntensity(from startDate: Date, to endDate: Date) -> [(date: Date, intensity: Double)]
    func fetchMonthlyAverageIntensity(for year: Int) -> [(month: Int, intensity: Double)]
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

        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        var tagCount: [String: Int] = [:]
        do {
            let records = try viewContext.fetch(request)
            for record in records {
                if let tagNamesStr = record.tagNames {
                    let names = tagNamesStr.components(separatedBy: ",").filter { !$0.isEmpty }
                    for name in names {
                        tagCount[name, default: 0] += 1
                    }
                }
            }
        } catch {
            Self.logger.error("Fetch top tags failed: \(error.localizedDescription)")
        }

        let result = tagCount.sorted { $0.value > $1.value }.prefix(limit).map { (name: $0.key, count: $0.value) }
        cache.cacheSet(key, data: result)
        return result
    }

    // MARK: - 日均强度

    func fetchDailyAverageIntensity(from startDate: Date, to endDate: Date) -> [(date: Date, intensity: Double)] {
        let key = CacheKey.dailyIntensity(start: startDate, end: endDate)
        if let cached = cache.cacheGet(key, type: [(date: Date, intensity: Double)].self) {
            return cached
        }

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
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
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchBatchSize = 100

        let calendar = Calendar.current
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
            Self.logger.error("Lightweight query for daily intensity failed: \(error.localizedDescription)")
            return fetchDailyAverageIntensityFallback(from: startDate, to: endDate)
        }

        let result = dailyData.map { (date: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }

        cache.cacheSet(key, data: result)
        return result
    }

    private func fetchDailyAverageIntensityFallback(from startDate: Date, to endDate: Date) -> [(date: Date, intensity: Double)] {
        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        let calendar = Calendar.current
        var dailyData: [Date: [Int]] = [:]
        do {
            let records = try viewContext.fetch(request)
            for record in records {
                if let createdAt = record.createdAt {
                    let dayStart = calendar.startOfDay(for: createdAt)
                    dailyData[dayStart, default: []].append(Int(record.intensity))
                }
            }
        } catch {
            Self.logger.error("Fallback daily intensity query failed: \(error.localizedDescription)")
        }
        return dailyData.map { (date: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - 月均强度

    func fetchMonthlyAverageIntensity(for year: Int) -> [(month: Int, intensity: Double)] {
        let key = CacheKey.monthlyIntensity(year: year)
        if let cached = cache.cacheGet(key, type: [(month: Int, intensity: Double)].self) {
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

        let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "MoodRecord")
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            yearStart as CVarArg,
            yearEnd as CVarArg
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
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.fetchBatchSize = 100

        var monthlyData: [Int: [Int]] = [:]
        do {
            let results = try viewContext.fetch(request) as? [[String: Any]] ?? []
            for dict in results {
                if let date = dict["createdDate"] as? Date,
                   let intensity = dict["intensityValue"] as? Int {
                    let month = calendar.component(.month, from: date)
                    monthlyData[month, default: []].append(intensity)
                }
            }
        } catch {
            Self.logger.error("Lightweight query for monthly intensity failed: \(error.localizedDescription)")
            return fetchMonthlyAverageIntensityFallback(for: year)
        }

        let result = monthlyData.map { (month: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.month < $1.month }

        cache.cacheSet(key, data: result)
        return result
    }

    private func fetchMonthlyAverageIntensityFallback(for year: Int) -> [(month: Int, intensity: Double)] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        guard let yearStart = calendar.date(from: components) else { return [] }
        components.year = year + 1
        guard let yearEnd = calendar.date(from: components) else { return [] }

        let request: NSFetchRequest<MoodRecord> = MoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            yearStart as CVarArg,
            yearEnd as CVarArg
        )
        var monthlyData: [Int: [Int]] = [:]
        do {
            let records = try viewContext.fetch(request)
            for record in records {
                if let createdAt = record.createdAt {
                    let month = calendar.component(.month, from: createdAt)
                    monthlyData[month, default: []].append(Int(record.intensity))
                }
            }
        } catch {
            Self.logger.error("Fallback monthly intensity query failed: \(error.localizedDescription)")
        }
        return monthlyData.map { (month: $0.key, intensity: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.month < $1.month }
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
        request.fetchBatchSize = 100

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
        cache.cacheSet(CacheKey.availableYears, data: result)
        return result
    }

    // MARK: - 连续打卡天数

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
        request.fetchBatchSize = 100

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
        request.fetchBatchSize = 100

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
        request.fetchBatchSize = 100

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
        request.fetchBatchSize = 100

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