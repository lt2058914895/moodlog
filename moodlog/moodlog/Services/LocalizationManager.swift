//
//  LocalizationManager.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import Foundation

/// 本地化辅助类
enum L {
    /// 获取本地化字符串
    static func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    /// 获取带参数的本地化字符串
    static func localized(_ key: String, args: CVarArg...) -> String {
        return String(format: NSLocalizedString(key, comment: ""), args)
    }
    
    /// 获取带Int参数的本地化字符串
    static func localizedInt(_ key: String, value: Int) -> String {
        return String(format: NSLocalizedString(key, comment: ""), value)
    }
}