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
        case calendar = 1
        case insight = 2

        var title: String {
            switch self {
            case .checkin: return L.localized("tab.checkin")
            case .calendar: return L.localized("tab.calendar")
            case .insight: return L.localized("tab.insight")
            }
        }

        var icon: String {
            switch self {
            case .checkin: return "heart.circle"
            case .calendar: return "calendar"
            case .insight: return "chart.bar"
            }
        }

        var selectedIcon: String {
            switch self {
            case .checkin: return "heart.circle.fill"
            case .calendar: return "calendar"
            case .insight: return "chart.bar.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 情绪打卡
            NavigationView {
                MoodCheckinView()
                    .navigationTitle(L.localized("app.name"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: selectedTab == .checkin ? Tab.checkin.selectedIcon : Tab.checkin.icon)
                Text(Tab.checkin.title)
            }
            .tag(Tab.checkin)

            // 日历视图
            NavigationView {
                MoodCalendarView()
                    .navigationTitle(L.localized("tab.calendar"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: selectedTab == .calendar ? Tab.calendar.selectedIcon : Tab.calendar.icon)
                Text(Tab.calendar.title)
            }
            .tag(Tab.calendar)

            // 数据洞察
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