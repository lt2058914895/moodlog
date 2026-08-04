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
        case calendar = 2
        case insight = 3

        var title: String {
            switch self {
            case .checkin: return L.localized("tab.checkin")
            case .records: return L.localized("tab.records")
            case .calendar: return L.localized("tab.calendar")
            case .insight: return L.localized("tab.insight")
            }
        }

        var icon: String {
            switch self {
            case .checkin: return "heart.circle"
            case .records: return "list.bullet.clipboard"
            case .calendar: return "calendar"
            case .insight: return "chart.bar"
            }
        }

        var selectedIcon: String {
            switch self {
            case .checkin: return "heart.circle.fill"
            case .records: return "list.bullet.clipboard.fill"
            case .calendar: return "calendar"
            case .insight: return "chart.bar.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 情绪记录
            NavigationView {
                MoodCheckinView()
                    .navigationTitle(L.localized("tab.checkin"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(L.localized("tab.checkin"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
            }
            .tabItem {
                Image(systemName: selectedTab == .checkin ? Tab.checkin.selectedIcon : Tab.checkin.icon)
                Text(Tab.checkin.title)
            }
            .tag(Tab.checkin)

            // 记录列表
            NavigationView {
                MoodRecordsView()
                    .navigationTitle(L.localized("tab.records"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(L.localized("tab.records"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
            }
            .tabItem {
                Image(systemName: selectedTab == .records ? Tab.records.selectedIcon : Tab.records.icon)
                Text(Tab.records.title)
            }
            .tag(Tab.records)

            // 日历视图
            NavigationView {
                MoodCalendarView()
                    .navigationTitle(L.localized("tab.calendar"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(L.localized("tab.calendar"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
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
