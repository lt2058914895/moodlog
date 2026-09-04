//
//  MainTabView.swift
//  moodlog
//
//  Created by deppon on 2026/6/26.
//

import SwiftUI

/// 主导航TabView
struct MainTabView: View {
    @State private var selectedTab: Tab = .checkin
    @StateObject private var dataManager = MoodDataManager.shared

    enum Tab: Int, CaseIterable {
        case checkin = 0
        case records = 1
        case insight = 2
        case profile = 3

        var title: String {
            switch self {
            case .checkin: return L.localized("tab.checkin")
            case .records: return L.localized("tab.records")
            case .insight: return L.localized("tab.insight")
            case .profile: return L.localized("tab.profile")
            }
        }

        var icon: String {
            switch self {
            case .checkin: return "heart.circle"
            case .records: return "list.bullet.clipboard"
            case .insight: return "chart.bar"
            case .profile: return "person.circle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .checkin: return "heart.circle.fill"
            case .records: return "list.bullet.clipboard.fill"
            case .insight: return "chart.bar.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 心情
            NavigationStack {
                MoodCheckinView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == .checkin ? Tab.checkin.selectedIcon : Tab.checkin.icon)
                Text(Tab.checkin.title)
            }
            .tag(Tab.checkin)

            // 记录
            NavigationStack {
                MoodRecordsView(onNavigateToCheckin: {
                    selectedTab = .checkin
                })
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == .records ? Tab.records.selectedIcon : Tab.records.icon)
                Text(Tab.records.title)
            }
            .tag(Tab.records)

            // 回顾
            MoodInsightView()
                .tabItem {
                    Image(systemName: selectedTab == .insight ? Tab.insight.selectedIcon : Tab.insight.icon)
                    Text(Tab.insight.title)
                }
                .tag(Tab.insight)

            // 我的
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == .profile ? Tab.profile.selectedIcon : Tab.profile.icon)
                    Text(Tab.profile.title)
                }
                .tag(Tab.profile)
        }
        .tint(Color("AccentColor"))
        .onAppear {
            // 首次启动初始化预设标签
            dataManager.initializePresetTagsIfNeeded()
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
