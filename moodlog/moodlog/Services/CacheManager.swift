//
//  CacheManager.swift
//  moodlog
//
//  Created by deppon on 2026/7/1.
//

import Foundation

/// 缓存键
enum CacheKey {
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
    func cacheSet(_ key: String, data: Any, expiry: TimeInterval)
    func cacheGet<T>(_ key: String, type: T.Type) -> T?
    func clearCache()
}

/// 缓存管理器
class CacheManager: CacheManaging {
    private let cache = NSCache<NSString, CacheWrapper>()

    /// 默认缓存过期时间（5分钟）
    /// 数据变更时缓存会被主动清除，此处仅控制无变更场景下的过期
    static let defaultExpiry: TimeInterval = 300

    init(countLimit: Int = 50) {
        cache.countLimit = countLimit
    }

    /// 缓存包装器
    private class CacheWrapper {
        let data: Any
        let expiry: Date

        init(data: Any, expiry: TimeInterval) {
            self.data = data
            self.expiry = Date().addingTimeInterval(expiry)
        }

        var isExpired: Bool {
            Date() > expiry
        }
    }

    func cacheSet(_ key: String, data: Any) {
        cacheSet(key, data: data, expiry: CacheManager.defaultExpiry)
    }

    func cacheSet(_ key: String, data: Any, expiry: TimeInterval) {
        cache.setObject(CacheWrapper(data: data, expiry: expiry), forKey: key as NSString)
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