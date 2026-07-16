//
//  HiddenExerciseCell.swift
//  iTrainer
//
//  Created by Codex on 07.07.2026.
//

import SwiftUI

struct HiddenExerciseCell: View {
    let model: ExerciseModel
    let onRestore: () -> Void
    
    private let iconSize: CGFloat = 72
    private let cardCornerRadius: CGFloat = 14
    private let iconCornerRadius: CGFloat = 12
    
    var body: some View {
        HStack(spacing: 14) {
            exerciseIcon
            
            VStack(alignment: .leading, spacing: 6) {
                Text(model.displayName)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                
                if let type = model.type {
                    Text(type.type.displayName)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("common.restore", action: onRestore)
                .font(AppFont.rowSubtitle.weight(.semibold))
                .foregroundStyle(AppColor.progressGreen)
                .buttonStyle(.plain)
        }
        .padding(12)
        .frame(minHeight: 96)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var exerciseIcon: some View {
        ExerciseTypeIconView(exerciseType: model.type,
                             size: iconSize,
                             cornerRadius: iconCornerRadius)
    }
}

#Preview {
    HiddenExerciseCell(model: ExerciseModel(title: "Bench Press", typeId: "chest_bench_press"),
                       onRestore: {})
        .padding()
        .background(AppColor.backgroundPrimary)
}
