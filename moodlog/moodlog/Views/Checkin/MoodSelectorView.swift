//
//  MoodSelectorView.swift
//  moodlog
//
//  从 MoodCheckinView.swift 拆分而来
//

import SwiftUI

// MARK: - 情绪选择器
struct MoodSelectorView: View {
    @ObservedObject var viewModel: MoodCheckinViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(spacing: 16) {
            // 情绪网格
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MoodType.allCases, id: \.self) { moodType in
                    MoodTypeCell(
                        moodType: moodType,
                        isSelected: viewModel.selectedMoodType == moodType,
                        onTap: { viewModel.selectMoodType(moodType) }
                    )
                }
            }
        }
    }
}

// MARK: - 一级情绪单元格
struct MoodTypeCell: View {
    let moodType: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(moodType.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isSelected ? 62 : 54, height: isSelected ? 62 : 54)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(moodType.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? moodType.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? moodType.color.opacity(0.15) : Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? moodType.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
