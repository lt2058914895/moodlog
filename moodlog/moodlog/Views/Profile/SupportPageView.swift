//
//  SupportPageView.swift
//  moodlog
//
//  "我的"页二级页面：App 内 WebView 加载技术支持页
//

import SwiftUI
import WebKit

// MARK: - WKWebView 包装

private struct SupportWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.systemGroupedBackground
        webView.scrollView.backgroundColor = UIColor.systemGroupedBackground
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

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
    let url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SupportWebView(url: url)
            .ignoresSafeArea(edges: .bottom)
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
}

#Preview {
    NavigationStack {
        SupportPageView(url: URL(string: "https://example.com")!)
    }
}
