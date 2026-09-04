//
//  ProfileView.swift
//  moodlog
//
//  阶段二："我的"页，托管数据导出 / 成就 / 分享卡片
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var dataManager = MoodDataManager.shared
    @StateObject private var exportService = DataExportService()
    @StateObject private var achievementService = AchievementService()

    @State private var showShareSheet = false
    @State private var exportFormat: ExportFormat?
    @State private var exportToast: String?

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard
                    achievementsCard
                    exportCard
                    aboutCard
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
                Circle().fill(Color("AccentColor").opacity(0.15)).frame(width: 64, height: 64)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color("AccentColor"))
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
            HStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color("WarningColor"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.localized("profile.achievements"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(String(format: L.localized("achievement.summary_count"),
                                achievementService.earnedCount, achievementService.totalCount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 数据导出

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L.localized("profile.export"), systemImage: "square.and.arrow.down.on.square")
                .font(.headline)

            ForEach(ExportFormat.allCases, id: \.self) { fmt in
                Button { exportFormat = fmt } label: {
                    HStack {
                        Image(systemName: fmt == .csv ? "tablecells" : "curlybraces")
                            .foregroundColor(Color("AccentColor"))
                        Text(String(format: L.localized("profile.export_format"), fmt.displayName))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - 分享卡片

    private var shareCard: some View {
        Button { showShareSheet = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundColor(Color("AccentColor"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.localized("profile.share_card"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(L.localized("profile.share_card_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var aboutCard: some View {
        VStack(spacing: 8) {
            shareCard
            HStack {
                Text(String(format: L.localized("profile.version"), appVersionString))
                    .font(.caption2)
                Spacer()
                Text(L.localized("profile.tagline"))
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
        }
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    // MARK: - 导出执行

    private func performExport(_ fmt: ExportFormat) {
        let content = exportService.exportAllRecords(format: fmt)
        let filename = "moodlog_export_\(Int(Date().timeIntervalSince1970)).\(fmt.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let data: Data
        if fmt == .json {
            data = Data(content.utf8)
        } else {
            data = Data(content.utf8)
        }
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
