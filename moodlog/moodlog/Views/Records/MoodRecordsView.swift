//
//  MoodRecordsView.swift
//  moodlog
//
//  Created by deppon on 2026/7/31.
//

import SwiftUI

/// 记录列表视图（独立Tab）
struct MoodRecordsView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var recordToEdit: MoodRecord?
    @State private var recordToDelete: MoodRecord?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.groupedRecords.isEmpty {
                // 空状态
                VStack(spacing: 12) {
                    Spacer()
                    Text("📝")
                        .font(.system(size: 48))
                    Text(L.localized("records.empty"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.groupedRecords, id: \.date) { group in
                        Section {
                            ForEach(group.records, id: \.id) { record in
                                MoodRecordListRow(record: record, onEdit: {
                                    recordToEdit = record
                                }, onDelete: {
                                    recordToDelete = record
                                    showDeleteConfirmation = true
                                })
                            }
                        } header: {
                            recordsSectionHeader(group.date, count: group.records.count)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(item: $recordToEdit) { record in
            EditMoodRecordView(record: record)
        }
        .alert(L.localized("checkin.delete_confirm"), isPresented: $showDeleteConfirmation, presenting: recordToDelete) { record in
            Button(L.localized("checkin.delete"), role: .destructive) {
                deleteRecord(record)
            }
            Button(L.localized("checkin.cancel"), role: .cancel) {}
        }
        .alert(L.localized("checkin.alert_title"), isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button(L.localized("checkin.alert_ok"), role: .cancel) {
                errorMessage = nil
            }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - 记录列表分组头部
    private func recordsSectionHeader(_ date: Date, count: Int) -> some View {
        HStack {
            Text(viewModel.sectionDateTitle(date))
                .font(.subheadline.bold())
                .foregroundColor(Color(hex: "6C5CE7"))
            Spacer()
            Text(L.localizedInt("calendar.records_count", value: count))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func deleteRecord(_ record: MoodRecord) {
        do {
            try viewModel.deleteRecord(record)
            viewModel.loadGroupedRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    MoodRecordsView()
}