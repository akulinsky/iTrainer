//
//  ExerciseTypeCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import SwiftUI

struct ExerciseTypeCell: View {
    
    private let model: ExerciseTypeModel
    private let mode: ExerciseTypeViewMode
    private let isSelected: Bool
    private let toggleBlock: () -> Void
    
    private let iconSize: CGFloat = 72
    private let cardCornerRadius: CGFloat = 14
    private let iconCornerRadius: CGFloat = 12
    
    init(model: ExerciseTypeModel, mode: ExerciseTypeViewMode, isSelected: Bool, toggleBlock: @escaping () -> Void) {
        self.model = model
        self.mode = mode
        self.isSelected = isSelected
        self.toggleBlock = toggleBlock
    }
    
    var body: some View {
        HStack(spacing: 14) {
            if mode == .selecting {
                selectionIcon
            }
            
            exerciseIcon
            
            VStack(alignment: .leading, spacing: 6) {
                Text(model.displayName)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                
                Text(model.type.displayName)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            Spacer(minLength: 8)
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
        ExerciseTypeIconView(exerciseType: model,
                             size: iconSize,
                             cornerRadius: iconCornerRadius,
                             symbolSize: 30)
    }
    
    private var selectionIcon: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .foregroundStyle(isSelected ? AppColor.brandPrimary : AppColor.textSecondary.opacity(0.45))
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .onTapGesture {
                toggleBlock()
            }
    }
}

#Preview {
    let category = ExerciseCategory(id: "chest",
                                    titleKey: "exercise.category.chest",
                                    defaultTitle: "Chest",
                                    kind: "muscleGroup",
                                    iconName: "icMissingImage",
                                    sortOrder: 0)
    ExerciseTypeCell(model: ExerciseTypeModel(titleKey: "exercise.chest.bench_press",
                                              defaultTitle: "Bench Press",
                                              type: category,
                                              parameters: [.weight(), .repeats()]
                                             ),
                     mode: .showing,
                     isSelected: false,
                     toggleBlock: {})
}
