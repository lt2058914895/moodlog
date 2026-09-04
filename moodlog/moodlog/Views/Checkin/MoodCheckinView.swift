//
//  MoodCheckinView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 情绪记录主页面
struct MoodCheckinView: View {
    @StateObject private var viewModel = MoodCheckinViewModel()
    @StateObject private var dataManager = MoodDataManager.shared
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 标题区域
                headerSection

                // 连续打卡卡片
                streakCard

                // 情绪选择器
                MoodSelectorView(viewModel: viewModel)

                // 情绪强度滑块
                if viewModel.selectedMoodType != nil {
                    IntensitySliderView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 活动标签选择
                if viewModel.selectedMoodType != nil {
                    TagSelectorView(viewModel: viewModel, dataManager: dataManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 备注
                if viewModel.selectedMoodType != nil {
                    noteField
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 记录按钮
                if viewModel.selectedMoodType != nil {
                    submitButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedMoodType != nil)
        .onTapGesture {
            isNoteFocused = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .moodDataDidChange)) { _ in
            viewModel.refreshStats()
        }
        .overlay {
            if viewModel.showSuccessAnimation {
                SuccessOverlayView {
                    viewModel.showSuccessAnimation = false
                }
            }
        }
        .alert(L.localized("checkin.alert_title"), isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(L.localized("checkin.alert_ok")) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 标题区域
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(viewModel.currentTimeImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)

                Text(viewModel.currentGreeting)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text(L.localized("checkin.subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 48)
    }

    // MARK: - 状态卡片
    private var streakCard: some View {
        HStack(spacing: 12) {
            // 左侧：上次记录
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: lastRecordIcon)
                        .font(.system(size: 18))
                        .foregroundColor(lastRecordColor)
                    Text(lastRecordText)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                }
                Text(lastRecordSubtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 右侧：总记录数
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("AccentColor"))
                    Text("\(viewModel.totalRecords)")
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                }
                Text(L.localized("checkin.total_records"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AccentColor").opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("AccentColor").opacity(0.2), lineWidth: 1)
        )
    }

    private var lastRecordIcon: String {
        if viewModel.totalRecords == 0 {
            return "heart.fill"
        } else if viewModel.daysSinceLastRecord == 0 {
            return "checkmark.circle.fill"
        } else if viewModel.daysSinceLastRecord <= 3 {
            return "clock.fill"
        } else {
            return "arrow.clockwise"
        }
    }

    private var lastRecordColor: Color {
        if viewModel.totalRecords == 0 {
            return Color("AccentColor")
        } else if viewModel.daysSinceLastRecord == 0 {
            return Color("SuccessColor")
        } else if viewModel.daysSinceLastRecord <= 3 {
            return Color("WarningColor")
        } else {
            return Color("InfoColor")
        }
    }

    private var lastRecordText: String {
        if viewModel.totalRecords == 0 {
            return L.localized("checkin.first_record")
        } else if viewModel.daysSinceLastRecord == 0 {
            return L.localized("checkin.recorded_today")
        } else if viewModel.daysSinceLastRecord == 1 {
            return L.localized("checkin.recorded_yesterday")
        } else {
            return String(format: L.localized("checkin.recorded_days_ago"), viewModel.daysSinceLastRecord)
        }
    }

    private var lastRecordSubtitle: String {
        if viewModel.totalRecords == 0 {
            return L.localized("checkin.record_subtitle_first")
        } else if viewModel.daysSinceLastRecord == 0 {
            return L.localized("checkin.record_subtitle_today")
        } else {
            return L.localized("checkin.record_subtitle_return")
        }
    }

    // MARK: - 备注
    private var noteField: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.note_title"))
                    .font(.subheadline.bold())
                Spacer()
            }

            if #available(iOS 16.0, *) {
                TextField("", text: $viewModel.note, prompt: Text(L.localized("checkin.note_placeholder")).foregroundColor(.secondary), axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
                    .focused($isNoteFocused)
            } else {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.note)
                        .font(.subheadline)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                        .focused($isNoteFocused)

                    if viewModel.note.isEmpty {
                        Text(L.localized("checkin.note_placeholder"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 提交按钮
    private var submitButton: some View {
        Button(action: viewModel.submitRecord) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text(L.localized("checkin.submit"))
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color("AccentColor"), Color("AccentLightColor")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.top, 8)
    }
}


#Preview {
    MoodCheckinView()
}
