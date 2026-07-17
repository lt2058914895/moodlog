//
//  CacheManager.swift
//  moodlog
//
//  Created by deppon on 2026/7/1.
//

import Foundation

/// 缓存键
enum CacheKey {
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
    static func dayRecordCount(year: Int, month: Int) -> String {
        "day_count_\(year)_\(month)"
    }
    static func dayPrimaryMood(year: Int, month: Int) -> String {
        "day_mood_\(year)_\(month)"
    }
}

/// 缓存管理协议
protocol CacheManaging {
    func cacheSet(_ key: String, data: Any)
    func cacheGet<T>(_ key: String, type: T.Type) -> T?
    func clearCache()
}

/// 缓存管理器
class CacheManager: CacheManaging {
    private let cache = NSCache<NSString, CacheWrapper>()

    init(countLimit: Int = 50) {
        cache.countLimit = countLimit
    }

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

    func cacheSet(_ key: String, data: Any) {
        cache.setObject(CacheWrapper(data: data), forKey: key as NSString)
    }

    func cacheGet<T>(_ key: String, type: T.Type) -> T? {
        guard let wrapper = cache.object(forKey: key as NSString),
              !wrapper.isExpired,
              let data = wrapper.data as? T else {
            return nil
        }
        return data
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}