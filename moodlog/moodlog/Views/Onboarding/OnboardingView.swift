//
//  OnboardingView.swift
//  moodlog
//
//  阶段二：首次引导流程，降低首日流失
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false

    @State private var page = 0

    private let pages: [(icon: String, titleKey: String, descKey: String, color: Color)] = [
        ("heart.circle.fill", "onboarding.page1_title", "onboarding.page1_desc", Color("AccentColor")),
        ("tag.fill", "onboarding.page2_title", "onboarding.page2_desc", Color("AccentLightColor")),
        ("chart.bar.fill", "onboarding.page3_title", "onboarding.page3_desc", Color("SuccessColor")),
        ("sparkles", "onboarding.page4_title", "onboarding.page4_desc", Color("AccentColor")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                if page < pages.count - 1 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text(L.localized("onboarding.next"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    Button {
                        hasCompleted = true
                    } label: {
                        Text(L.localized("onboarding.skip"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        hasCompleted = true
                    } label: {
                        Text(L.localized("onboarding.start"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("AccentColor"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func onboardingPage(_ index: Int) -> some View {
        let p = pages[index]
        return VStack(spacing: 24) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 80))
                .foregroundColor(p.color)
                .scaleEffect(page == index ? 1.0 : 0.85)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: page)

            VStack(spacing: 12) {
                Text(L.localized(p.titleKey))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                Text(L.localized(p.descKey))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
