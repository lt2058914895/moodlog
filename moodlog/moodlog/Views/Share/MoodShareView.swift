//
//  MoodShareView.swift
//  moodlog
//
//  阶段二：情绪分享图生成（去敏感化，仅展示聚合统计，不含原始备注）
//

import SwiftUI
import UIKit
import Photos

// MARK: - 分享/导出通用辅助

/// 弹出系统分享面板（UIActivityViewController）
@MainActor
func presentShareSheet(items: [Any]) {
    guard let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let window = scene.keyWindow ?? scene.windows.first,
          var topController = window.rootViewController else { return }
    // sheet/弹窗之上再弹分享面板，必须找最顶层控制器，否则会被 UIKit 静默拒绝
    while let presented = topController.presentedViewController {
        topController = presented
    }
    let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // iPad 兼容
    if let pop = activity.popoverPresentationController {
        pop.sourceView = topController.view
        pop.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
        pop.permittedArrowDirections = []
    }
    topController.present(activity, animated: true)
}

/// 将 SwiftUI 视图渲染为 UIImage（透明底、@3x，圆角由视图自身 clipShape 保证）
@MainActor
func renderImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
    let imageRenderer = ImageRenderer(content: AnyView(view))
    imageRenderer.scale = 3
    return imageRenderer.uiImage
}

// MARK: - 保存到相册回调

final class PhotoSaveCoordinator: NSObject {
    private let onSuccess: () -> Void
    private let onFailure: () -> Void

    init(onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    @objc func image(_ image: UIImage,
                     didFinishSavingWithError error: Error?,
                     contextInfo: UnsafeRawPointer?) {
        if error == nil {
            onSuccess()
        } else {
            onFailure()
        }
    }
}

// MARK: - 分享卡片数据

struct MoodShareMoodEntry {
    let mood: MoodType
    let percentage: Int
}

struct MoodShareData {
    let dateRangeText: String
    let totalRecords: Int
    let dominantMood: MoodType
    let moodEntries: [MoodShareMoodEntry]
}

// MARK: - 分享时段（与回顾页 InsightTimeRange 的日期口径保持一致）

enum MoodSharePeriod: String, CaseIterable, Identifiable {
    case today
    case week
    case month
    case quarter
    case year

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .today: return "share.period.today"
        case .week: return "share.period.week"
        case .month: return "share.period.month"
        case .quarter: return "share.period.quarter"
        case .year: return "share.period.year"
        }
    }

    func dateRange(now: Date = Date()) -> (start: Date, end: Date) {
        insightRange.dateRange(at: now)
    }

    private var insightRange: InsightTimeRange {
        switch self {
        case .today: return .today
        case .week: return .week
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        }
    }
}

// MARK: - 分享卡片视图（去敏感化：仅 emoji + 聚合统计，无原始备注/具体时间）

struct MoodShareCardView: View {
    let data: MoodShareData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [data.dominantMood.color.opacity(0.95), Color("AccentColor").opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 240, height: 240)
                .offset(x: 130, y: -170)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: -140, y: 190)

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Label(L.localized("share.card_title"), systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                    Text(data.dateRangeText)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 6) {
                    Image(data.dominantMood.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 96, height: 96)
                        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    Text(data.dominantMood.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)

                VStack(spacing: 10) {
                    ForEach(data.moodEntries, id: \.mood) { entry in
                        moodBar(entry)
                    }
                }
                .padding(.top, 20)

                Text("\(L.localized("share.records")) · \(data.totalRecords)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.14))
                    )
                    .padding(.top, 20)

                Text(L.localized("share.tagline"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.top, 18)
            }
            .padding(26)
        }
        .frame(width: 340, height: 460)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
    }

    private func moodBar(_ entry: MoodShareMoodEntry) -> some View {
        HStack(spacing: 10) {
            Image(entry.mood.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
            Text(entry.mood.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.2))
                    Capsule()
                        .fill(Color.white)
                        .frame(width: proxy.size.width * CGFloat(entry.percentage) / 100)
                }
            }
            .frame(height: 8)
            .frame(maxWidth: .infinity)
            Text("\(entry.percentage)%")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - 分享 Sheet（时段选择 + 预览 + 保存/分享）

struct MoodShareSheet: View {
    @StateObject private var dataManager = MoodDataManager.shared
    @State private var period: MoodSharePeriod = .week
    @State private var shareData: MoodShareData?
    @State private var toast: String?
    @State private var saveCoordinator: PhotoSaveCoordinator?
    @State private var showPermissionAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Picker("", selection: $period) {
                        ForEach(MoodSharePeriod.allCases) { period in
                            Text(L.localized(period.titleKey)).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: period) { _ in buildData() }

                    if let data = shareData {
                        MoodShareCardView(data: data)
                            .scaleEffect(0.92)
                    } else {
                        ProgressView().frame(height: 460)
                    }

                    HStack(spacing: 12) {
                        Button {
                            saveToAlbum()
                        } label: {
                            Label(L.localized("share.save_album"), systemImage: "square.and.arrow.down")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("AccentColor").opacity(0.12))
                                .foregroundColor(Color("AccentColor"))
                                .cornerRadius(14)
                        }

                        Button {
                            shareCard()
                        } label: {
                            Label(L.localized("share.share_action"), systemImage: "square.and.arrow.up")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(L.localized("share.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.localized("share.close")) { dismiss() }
                }
            }
            .overlay(alignment: .top) {
                if let toast = toast {
                    Text(toast)
                        .font(.subheadline)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Color(UIColor.label).opacity(0.9)))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
            .alert(L.localized("share.permission_alert_title"), isPresented: $showPermissionAlert) {
                Button(L.localized("share.permission_go_settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(L.localized("share.permission_cancel"), role: .cancel) {}
            } message: {
                Text(String(format: L.localized("share.permission_alert_message"), L.localized("app.name")))
            }
            .task { buildData() }
        }
    }

    private func renderedCardImage() -> UIImage? {
        guard let data = shareData else { return nil }
        return renderImage(MoodShareCardView(data: data), size: CGSize(width: 340, height: 460))
    }

    private func saveToAlbum() {
        guard let image = renderedCardImage() else { return }
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            performSave(image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        performSave(image)
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            performSave(image)
        }
    }

    private func performSave(_ image: UIImage) {
        let coordinator = PhotoSaveCoordinator(
            onSuccess: { showToast(L.localized("share.saved_success")) },
            onFailure: { showToast(L.localized("share.saved_failed")) }
        )
        saveCoordinator = coordinator
        UIImageWriteToSavedPhotosAlbum(image, coordinator, #selector(PhotoSaveCoordinator.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    private func shareCard() {
        guard let image = renderedCardImage() else { return }
        presentShareSheet(items: [image])
    }

    private func showToast(_ message: String) {
        withAnimation {
            toast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                toast = nil
            }
        }
    }

    private func buildData() {
        let now = Date()
        let range = period.dateRange(now: now)
        let dist = dataManager.fetchMoodDistribution(from: range.start, to: range.end)
        let total = dist.values.reduce(0, +)

        let entries: [MoodShareMoodEntry] = dist
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { mood, count in
                let pct = total > 0 ? Int(round(Double(count) / Double(total) * 100)) : 0
                return MoodShareMoodEntry(mood: mood, percentage: pct)
            }

        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMdd", options: 0, locale: Locale.current)
        let rangeText: String
        if period == .today {
            rangeText = fmt.string(from: now)
        } else {
            rangeText = "\(fmt.string(from: range.start)) - \(fmt.string(from: now))"
        }

        shareData = MoodShareData(
            dateRangeText: rangeText,
            totalRecords: total,
            dominantMood: entries.first?.mood ?? .happy,
            moodEntries: entries
        )
    }
}

#Preview {
    MoodShareSheet()
}
