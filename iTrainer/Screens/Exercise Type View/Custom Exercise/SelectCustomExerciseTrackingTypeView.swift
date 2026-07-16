//
//  SelectCustomExerciseTrackingTypeView.swift
//  iTrainer
//
//  Created by Codex on 09.07.2026.
//

import SwiftUI

struct SelectCustomExerciseTrackingTypeView: View {
    @ObservedObject var viewModel: CreateCustomExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let cardCornerRadius: CGFloat = 14
    
    var body: some View {
        List {
            ForEach(ExerciseTrackingType.allCases, id: \.self) { trackingType in
                Button {
                    viewModel.selectTrackingType(trackingType)
                    dismiss()
                } label: {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trackingType.displayTitle)
                                .font(AppFont.workoutWidgetTitle)
                                .foregroundStyle(AppColor.textPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                            Text(trackingType.descriptionText)
                                .font(AppFont.rowSubtitle)
                                .foregroundStyle(AppColor.textSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: viewModel.selectedTrackingType == trackingType ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(viewModel.selectedTrackingType == trackingType ? AppColor.brandPrimary : AppColor.textSecondary.opacity(0.35))
                    }
                    .padding(20)
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
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(AppColor.backgroundPrimary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.backgroundPrimary)
        .navigationTitle("custom_exercise.select_tracking_type.title")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppColor.brandPrimary)
    }
}

#Preview {
    NavigationStack {
        SelectCustomExerciseTrackingTypeView(viewModel: CreateCustomExerciseViewModel())
    }
}
