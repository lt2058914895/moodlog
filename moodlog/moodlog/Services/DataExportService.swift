//
//  DataExportService.swift
//  moodlog
//
//  阶段二：数据导出（CSV / JSON），为心理咨询辅助场景铺路
//

import Foundation

enum ExportFormat: String, CaseIterable {
    case csv
    case json

    var fileExtension: String { rawValue }
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        }
    }
}

/// 数据导出服务：将情绪记录导出为 CSV / JSON 字符串
class DataExportService: ObservableObject {
    private let dataManager: any MoodDataManaging

    init(dataManager: any MoodDataManaging = MoodDataManager.shared) {
        self.dataManager = dataManager
    }

    /// 导出全部记录（按时间正序），返回字符串
    func exportAllRecords(format: ExportFormat) -> String {
        let records = dataManager.fetchRecords(from: Date.distantPast, to: Date()).sorted {
            ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
        }
        switch format {
        case .csv: return toCSV(records)
        case .json: return toJSON(records)
        }
    }

    // MARK: - CSV

    private func toCSV(_ records: [MoodRecord]) -> String {
        var rows: [String] = []
        rows.append("\u{FEFF}时间,情绪,强度,标签,备注")  // BOM 头，兼容 Excel 中文
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        for r in records {
            let time = formatter.string(from: r.createdAt ?? Date())
            let mood = r.moodType ?? "unknown"
            let intensity = String(r.intensity)
            let tags = MoodDataManager.tagNamesFromRecord(r).joined(separator: " | ")
            let note = (r.note ?? "").replacingOccurrences(of: "\n", with: " ")
            rows.append(csvRow(time, mood, intensity, tags, note))
        }
        return rows.joined(separator: "\n")
    }

    /// CSV 单行转义：字段含逗号/引号/换行时用双引号包裹
    private func csvRow(_ fields: String...) -> String {
        fields.map { f -> String in
            if f.contains(",") || f.contains("\"") || f.contains("\n") {
                return "\"" + f.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            return f
        }.joined(separator: ",")
    }

    // MARK: - JSON

    private func toJSON(_ records: [MoodRecord]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dicts: [[String: Any]] = records.map { r in
            [
                "createdAt": formatter.string(from: r.createdAt ?? Date()),
                "moodType": r.moodType ?? "unknown",
                "intensity": r.intensity,
                "tags": MoodDataManager.tagNamesFromRecord(r),
                "note": r.note ?? ""
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
    }
}
