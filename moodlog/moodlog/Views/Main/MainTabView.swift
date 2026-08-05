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

        var title: String {
            switch self {
            case .checkin: return L.localized("tab.checkin")
            case .records: return L.localized("tab.records")
            case .insight: return L.localized("tab.insight")
            }
        }

        var icon: String {
            switch self {
            case .checkin: return "heart.circle"
            case .records: return "list.bullet.clipboard"
            case .insight: return "chart.bar"
            }
        }

        var selectedIcon: String {
            switch self {
            case .checkin: return "heart.circle.fill"
            case .records: return "list.bullet.clipboard.fill"
            case .insight: return "chart.bar.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 心情
            NavigationView {
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
            NavigationView {
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
        }
        .tint(Color(hex: "6C5CE7"))
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
