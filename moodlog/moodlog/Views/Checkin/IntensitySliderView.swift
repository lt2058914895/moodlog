//
//  IntensitySliderView.swift
//  moodlog
//
//  从 MoodCheckinView.swift 拆分而来
//

import SwiftUI

// MARK: - 情绪强度滑块
struct IntensitySliderView: View {
    @ObservedObject var viewModel: MoodCheckinViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L.localized("checkin.intensity"))
                    .font(.subheadline.bold())
                Spacer()
                Text("\(viewModel.intensity)")
                    .font(.title2.bold())
                    .foregroundColor(intensityGradientColor)
            }

            Slider(value: Binding(
                get: { Double(viewModel.intensity) },
                set: { viewModel.intensity = Int($0) }
            ), in: 1...10, step: 1)
            .tint(intensityGradientColor)

            HStack {
                Text(L.localized("checkin.intensity.light"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(L.localized("checkin.intensity.strong"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var intensityGradientColor: Color {
        let colors = viewModel.intensityColor
        if viewModel.intensity <= 3 {
            return colors.start.color
        } else if viewModel.intensity <= 6 {
            return colors.end.color
        } else {
            return colors.end.color
        }
    }
}
