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
    var onNavigateToCheckin: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.groupedRecords.isEmpty {
                emptyStateView
            } else {
                // 操作提示
                Text(L.localized("calendar.long_press_hint"))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.top, 0)
                    .padding(.bottom, 2)
                    .frame(maxWidth: .infinity)

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

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.text.square")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "6C5CE7").opacity(0.6))
            Text(L.localized("records.empty"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: {
                onNavigateToCheckin?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text(L.localized("records.empty_action"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
