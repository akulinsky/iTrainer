//
//  ExerciseTypeIconView.swift
//  iTrainer
//
//  Created by Codex on 09.07.2026.
//

import SwiftUI

struct ExerciseTypeIconView: View {
    let exerciseType: ExerciseTypeModel?
    let size: CGFloat
    let cornerRadius: CGFloat
    let symbolSize: CGFloat
    
    init(exerciseType: ExerciseTypeModel?,
         size: CGFloat,
         cornerRadius: CGFloat = 12,
         symbolSize: CGFloat? = nil) {
        self.exerciseType = exerciseType
        self.size = size
        self.cornerRadius = cornerRadius
        self.symbolSize = symbolSize ?? max(size * 0.42, 20)
    }
    
    var body: some View {
        Group {
            if let exerciseType, exerciseType.isCustom, let systemName = exerciseType.customIconSystemName {
                customIcon(systemName)
            } else if let icon = exerciseType?.icon {
                assetIcon(icon)
            } else {
                assetIcon(Image("icMissingImage"))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private func customIcon(_ systemName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColor.brandPrimary)
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private func assetIcon(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
    }
}

#Preview {
    let category = ExerciseCategory(id: "chest",
                                    titleKey: "exercise.category.chest",
                                    defaultTitle: "Chest",
                                    devTitle: "Chest",
                                    kind: "muscleGroup",
                                    iconName: "icMissingImage",
                                    sortOrder: 0)
    HStack {
        ExerciseTypeIconView(exerciseType: ExerciseTypeModel(devTitle: "Bench Press",
                                                            iconName: "icMissingImage",
                                                            type: category,
                                                            parameters: [.weight(), .repeats()]),
                             size: 72)
        ExerciseTypeIconView(exerciseType: ExerciseTypeModel(devTitle: "Custom Exercise",
                                                            type: category,
                                                            parameters: [.weight(), .repeats()],
                                                            isCustom: true,
                                                            customIconSystemName: "dumbbell.fill"),
                             size: 72)
    }
    .padding()
    .background(AppColor.backgroundPrimary)
}
