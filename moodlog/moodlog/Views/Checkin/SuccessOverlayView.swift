//
//  SuccessOverlayView.swift
//  moodlog
//
//  从 MoodCheckinView.swift 拆分而来
//

import SwiftUI

// MARK: - 成功动画覆盖层
struct SuccessOverlayView: View {
    let onDismiss: () -> Void
    @State private var showCheckmark = false
    @State private var showText = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color("SuccessColor"))
                    .scaleEffect(showCheckmark ? 1.0 : 0.1)
                    .opacity(showCheckmark ? 1 : 0)

                Text(L.localized("checkin.success"))
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .opacity(showText ? 1 : 0)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 20)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                showText = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }
}
