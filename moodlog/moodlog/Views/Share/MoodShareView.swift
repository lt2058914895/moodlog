//
//  MoodShareView.swift
//  moodlog
//
//  阶段二：情绪分享图生成（去敏感化，仅展示聚合统计，不含原始备注）
//

import SwiftUI
import UIKit

// MARK: - 分享/导出通用辅助

/// 弹出系统分享面板（UIActivityViewController）
@MainActor
func presentShareSheet(items: [Any]) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first?.rootViewController else { return }
    let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // iPad 兼容
    if let pop = activity.popoverPresentationController {
        pop.sourceView = root.view
        pop.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
        pop.permittedArrowDirections = []
    }
    root.present(activity, animated: true)
}

/// 将 SwiftUI 视图渲染为 UIImage（iOS 15+ 兼容，基于 UIHostingController + UIGraphicsImageRenderer）
@MainActor
func renderImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
    let controller = UIHostingController(rootView: AnyView(view))
    controller.view.bounds = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear
    controller.view.sizeToFit()
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        controller.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
}

// MARK: - 分享卡片数据

struct MoodShareData {
    let dateRangeText: String
    let totalRecords: Int
    let streakDays: Int
    let dominantMood: MoodType
    let dominantPercentage: Int
}

// MARK: - 分享卡片视图（去敏感化：仅 emoji + 聚合统计，无原始备注/具体时间）

struct MoodShareCardView: View {
    let data: MoodShareData

    var body: some View {
        ZStack {
            // 背景渐变：主导情绪色 → 强调色
            LinearGradient(
                colors: [data.dominantMood.color.opacity(0.9), Color("AccentColor").opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 6) {
                    Text(L.localized("share.card_title"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                    Text(data.dateRangeText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                // 主导情绪
                VStack(spacing: 8) {
                    Image(data.dominantMood.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.2), radius: 6)
                    Text(data.dominantMood.displayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text(String(format: L.localized("share.dominant"), data.dominantPercentage))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)

                // 统计
                HStack(spacing: 0) {
                    statCell(value: "\(data.totalRecords)", label: L.localized("share.records"))
                    divider
                    statCell(value: "\(data.streakDays)", label: L.localized("share.streak"))
                    divider
                    statCell(value: "\(data.dominantPercentage)%", label: L.localized("share.share_rate"))
                }
                .padding(.horizontal, 8)

                // 底部 tagline
                Text(L.localized("share.tagline"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
        }
        .frame(width: 320, height: 460)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 32)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 分享 Sheet（预览 + 分享按钮）

struct MoodShareSheet: View {
    @StateObject private var dataManager = MoodDataManager.shared
    @State private var shareData: MoodShareData?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let data = shareData {
                        MoodShareCardView(data: data)
                            .scaleEffect(0.95)
                    } else {
                        ProgressView().frame(height: 460)
                    }

                    Button {
                        guard let data = shareData,
                              let image = renderImage(MoodShareCardView(data: data), size: CGSize(width: 320, height: 460)) else { return }
                        presentShareSheet(items: [image])
                    } label: {
                        Label(L.localized("share.save_share"), systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .disabled(shareData == nil)
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
            .task { buildData() }
        }
    }

    private func buildData() {
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.dateInterval(of: .weekOfYear, for: now)?.start ?? cal.startOfDay(for: now)
        let dist = dataManager.fetchMoodDistribution(from: weekStart, to: now.endOfDay)
        let total = dist.values.reduce(0, +)
        let dom = dist.max(by: { $0.value < $1.value })?.key ?? .happy
        let pct = total > 0 ? Int(round(Double(dist[dom] ?? 0) / Double(total) * 100)) : 0

        let fmt = DateFormatter()
        fmt.locale = Locale.current
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMMdd", options: 0, locale: Locale.current)
        let rangeText = "\(fmt.string(from: weekStart)) - \(fmt.string(from: now))"

        shareData = MoodShareData(
            dateRangeText: rangeText,
            totalRecords: total,
            streakDays: dataManager.fetchStreakDays(),
            dominantMood: dom,
            dominantPercentage: pct
        )
    }
}

#Preview {
    MoodShareSheet()
}
