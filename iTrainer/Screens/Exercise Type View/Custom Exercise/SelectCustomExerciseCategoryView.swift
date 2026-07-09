//
//  SelectCustomExerciseCategoryView.swift
//  iTrainer
//
//  Created by Codex on 09.07.2026.
//

import SwiftUI

struct SelectCustomExerciseCategoryView: View {
    @ObservedObject var viewModel: CreateCustomExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let iconSize: CGFloat = 72
    private let cardCornerRadius: CGFloat = 14
    
    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                Button {
                    viewModel.selectCategory(category)
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        category.icon
                            .resizable()
                            .scaledToFill()
                            .frame(width: iconSize, height: iconSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        Text(category.displayName)
                            .font(AppFont.workoutWidgetTitle)
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: isSelected(category) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected(category) ? AppColor.brandPrimary : AppColor.textSecondary.opacity(0.35))
                    }
                    .padding(12)
                    .frame(minHeight: 96)
                    .background(AppColor.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                            .stroke(AppColor.separatorSoft, lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(AppColor.backgroundPrimary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColor.brandPrimary)
    }
    
    private func isSelected(_ category: ExerciseCategory) -> Bool {
        viewModel.selectedCategoryId == category.id
    }
}

#Preview {
    NavigationStack {
        SelectCustomExerciseCategoryView(viewModel: CreateCustomExerciseViewModel())
    }
}
