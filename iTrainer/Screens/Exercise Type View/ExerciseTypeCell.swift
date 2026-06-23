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
    
    private let iconSize: CGFloat = 64
    
    init(model: ExerciseTypeModel, mode: ExerciseTypeViewMode, isSelected: Bool, toggleBlock: @escaping () -> Void) {
        self.model = model
        self.mode = mode
        self.isSelected = isSelected
        self.toggleBlock = toggleBlock
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if mode == .selecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppColor.brandPrimary : AppColor.textSecondary.opacity(0.45))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleBlock()
                    }
            }
            
            if let icon = model.icon {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(model.displayName)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                
                Text(model.type.displayName)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            Spacer(minLength: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    let category = ExerciseCategory(id: "chest",
                                    titleKey: "exercise.category.chest",
                                    defaultTitle: "Chest",
                                    devTitle: "Грудь",
                                    kind: "muscleGroup",
                                    iconName: "icMissingImage",
                                    sortOrder: 0)
    ExerciseTypeCell(model: ExerciseTypeModel(devTitle: "Жим лежа",
                                              type: category,
                                              parameters: [.weight(), .repeats()]
                                             ),
                     mode: .showing,
                     isSelected: false,
                     toggleBlock: {})
}
