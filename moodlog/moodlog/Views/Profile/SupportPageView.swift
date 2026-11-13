//
//  SupportPageView.swift
//  moodlog
//
//  "我的"页二级页面：问题反馈与邮件联系
//

import SwiftUI
import UIKit

// MARK: - TabBar 显隐控制（进入二级页隐藏，返回恢复）

private enum TabBarVisibility {
    private static weak var cachedTabBar: UITabBar?

    static func hide(from responder: UIResponder?) {
        cachedTabBar = findTabBar(from: responder)
        cachedTabBar?.isHidden = true
    }

    static func show() {
        cachedTabBar?.isHidden = false
    }

    private static func findTabBar(from responder: UIResponder?) -> UITabBar? {
        var current: UIResponder? = responder
        while let candidate = current {
            if let tabBarController = candidate as? UITabBarController {
                return tabBarController.tabBar
            }
            current = candidate.next
        }
        return nil
    }
}

private struct TabBarHider: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            TabBarVisibility.hide(from: controller)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: UIViewController,
                                          coordinator: ()) {
        DispatchQueue.main.async {
            TabBarVisibility.show()
        }
    }
}

// MARK: - 问题反馈页

struct SupportPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false

    private let supportEmail = "2058914895@qq.com"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text(L.localized("feedback.help_title"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(L.localized("feedback.help_message"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)

                Button(action: copyEmail) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color("AccentColor").opacity(0.14))
                                .frame(width: 48, height: 48)

                            Image(systemName: "envelope.fill")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(Color("AccentColor"))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L.localized("feedback.contact_title"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)

                            Text(supportEmail)
                                .font(.subheadline)
                                .foregroundColor(Color("AccentColor"))
                        }

                        Spacer(minLength: 12)

                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("AccentColor"))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L.localized("feedback.copy_email"))

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 36)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                Text(L.localized("feedback.copied"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(UIColor.systemBackground))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.label).opacity(0.9))
                    )
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(L.localized("profile.feedback"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .background(TabBarHider())
        .onDisappear {
            TabBarVisibility.show()
        }
    }

    private func copyEmail() {
        UIPasteboard.general.string = supportEmail
        withAnimation(.easeOut(duration: 0.2)) {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SupportPageView()
    }
}
