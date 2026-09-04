//
//  AchievementView.swift
//  moodlog
//
//  阶段二：成就徽章展示
//

import SwiftUI

struct AchievementView: View {
    @StateObject private var service = AchievementService()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                summaryHeader
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(service.fetchAllStatuses()) { status in
                        BadgeCell(status: status)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(L.localized("achievement.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundColor(Color("WarningColor"))
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: L.localized("achievement.summary_count"), service.earnedCount, service.totalCount))
                    .font(.title2.bold())
                Text(L.localized("achievement.summary_desc"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color("AccentColor").opacity(0.12), Color("AccentLightColor").opacity(0.08)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
    }
}

struct BadgeCell: View {
    let status: AchievementStatus

    private var color: Color { status.isEarned ? Color("WarningColor") : Color.gray.opacity(0.5) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: status.achievement.icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            .overlay {
                if status.isEarned {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundColor(Color("SuccessColor"))
                        .background(Circle().fill(Color(UIColor.systemBackground)))
                        .offset(x: 22, y: -22)
                }
            }

            Text(L.localized(status.achievement.titleKey))
                .font(.caption.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if !status.isEarned {
                Text(String(format: L.localized("achievement.progress"), status.currentValue, status.achievement.requirement))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(status.isEarned ? color.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView { AchievementView() }
}
