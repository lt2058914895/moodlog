//
//  ProfileView.swift
//  moodlog
//
//  "我的"页：成就 / 数据导出 / 分享卡片 / 支持
//

import SwiftUI

/// App 对外链接常量
private enum AppLinks {
    /// 技术支持页面地址
    static let support = URL(string: "https://lt2058914895.github.io/moodlog/support.html")!
    /// App Store 地址
    static let appStore = URL(string: "https://apps.apple.com/app/id6791829175")!
    /// App Store 评分页（直接跳转撰写评价）
    static let appStoreReview = URL(string: "itms-apps://apps.apple.com/app/id6791829175?action=write-review")!
}

struct ProfileView: View {
    @StateObject private var dataManager = MoodDataManager.shared
    @StateObject private var exportService = DataExportService()
    @StateObject private var achievementService = AchievementService()

    @Environment(\.openURL) private var openURL

    @State private var showShareSheet = false
    @State private var exportFormat: ExportFormat?
    @State private var exportToast: String?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerCard
                    achievementsCard
                    dataSection
                    supportSection
                    footerView
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(L.localized("profile.title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) { MoodShareSheet() }
            .overlay(alignment: .top) {
                if let toast = exportToast {
                    Text(toast)
                        .font(.subheadline)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color(UIColor.label).opacity(0.9)))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .onChange(of: exportFormat) { fmt in
                guard let fmt = fmt else { return }
                performExport(fmt)
                exportFormat = nil
            }
        }
    }

    // MARK: - 头部

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color("AccentColor"), Color("AccentLightColor")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                Image(systemName: "cat.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(L.localized("app.name"))
                    .font(.title2.bold())
                Text(String(format: L.localized("profile.records_total"), dataManager.fetchRecordCount()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
    }

    // MARK: - 成就

    private var achievementsCard: some View {
        NavigationLink {
            AchievementView()
        } label: {
            settingRow(icon: "trophy.fill",
                       iconColor: Color("WarningColor"),
                       title: L.localized("profile.achievements"),
                       subtitle: String(format: L.localized("achievement.summary_count"),
                                        achievementService.earnedCount, achievementService.totalCount),
                       showChevron: true)
        }
        .buttonStyle(.plain)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 数据管理

    private var dataSection: some View {
        sectionContainer(title: L.localized("profile.section_data")) {
            VStack(spacing: 0) {
                ForEach(ExportFormat.allCases, id: \.self) { fmt in
                    Button { exportFormat = fmt } label: {
                        settingRow(icon: fmt == .csv ? "tablecells" : "curlybraces",
                                   iconColor: Color("AccentColor"),
                                   title: String(format: L.localized("profile.export_format"), fmt.displayName),
                                   showChevron: true)
                    }
                    .buttonStyle(.plain)
                    if fmt != ExportFormat.allCases.last {
                        rowDivider
                    }
                }
                rowDivider
                Button { showShareSheet = true } label: {
                    settingRow(icon: "square.and.arrow.up",
                               iconColor: Color("AccentColor"),
                               title: L.localized("profile.share_card"),
                               subtitle: L.localized("profile.share_card_desc"),
                               showChevron: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 支持与反馈

    private var supportSection: some View {
        sectionContainer(title: L.localized("profile.section_support")) {
            VStack(spacing: 0) {
                Button {
                    presentShareSheet(items: [appShareText])
                } label: {
                    settingRow(icon: "square.and.arrow.up.on.square",
                               iconColor: Color("InfoColor"),
                               title: L.localized("profile.share_app"),
                               showChevron: true)
                }
                .buttonStyle(.plain)
                rowDivider
                Button {
                    requestAppReview()
                } label: {
                    settingRow(icon: "star.bubble",
                               iconColor: Color("WarningColor"),
                               title: L.localized("profile.rate_app"),
                               showChevron: true)
                }
                .buttonStyle(.plain)
                rowDivider
                NavigationLink {
                    SupportPageView(url: AppLinks.support)
                } label: {
                    settingRow(icon: "envelope",
                               iconColor: Color("SuccessColor"),
                               title: L.localized("profile.feedback"),
                               showChevron: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 页脚

    private var footerView: some View {
        VStack(spacing: 4) {
            Text(String(format: L.localized("profile.version"), appVersionString))
                .font(.caption2)
            Text(L.localized("profile.tagline"))
                .font(.caption2)
        }
        .foregroundColor(.secondary)
        .padding(.top, 4)
    }

    // MARK: - 通用组件

    private func sectionContainer<Content: View>(title: String,
                                                 @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            content()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
        }
    }

    private func settingRow(icon: String,
                            iconColor: Color,
                            title: String,
                            subtitle: String? = nil,
                            showChevron: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 62)
    }

    // MARK: - 数据

    private var appShareText: String {
        String(format: L.localized("profile.share_app_text"), AppLinks.appStore.absoluteString)
    }

    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: - 操作

    private func requestAppReview() {
        openURL(AppLinks.appStoreReview)
    }

    private func performExport(_ fmt: ExportFormat) {
        let content = exportService.exportAllRecords(format: fmt)
        let filename = "moodlog_export_\(Int(Date().timeIntervalSince1970)).\(fmt.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let data = Data(content.utf8)
        do {
            try data.write(to: tempURL, options: .atomic)
            presentShareSheet(items: [tempURL])
        } catch {
            exportToast = L.localized("profile.export_failed")
            clearToast()
        }
    }

    private func clearToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { exportToast = nil }
    }
}

#Preview {
    ProfileView()
}
