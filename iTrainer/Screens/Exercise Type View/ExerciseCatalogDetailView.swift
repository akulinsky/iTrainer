//
//  ExerciseCatalogDetailView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 23.06.2026.
//

import SwiftUI

struct ExerciseCatalogDetailView: View {
    
    let model: ExerciseTypeModel
    
    private let iconHeight: CGFloat = 280
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let icon = model.icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: iconHeight)
                        .padding(.top, 16)
                }
                
                VStack(spacing: 8) {
                    Text(model.displayName)
                        .font(AppFont.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(model.type.displayName)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 12) {
                    metadataRow(title: "Category", value: model.type.displayName)
                    metadataRow(title: "Parameters", value: parametersText)
                }
                .padding(16)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func metadataRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: 16)
            Text(value)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private var parametersText: String {
        model.parameters.map { $0.title }.joined(separator: " · ")
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
    ExerciseCatalogDetailView(model: ExerciseTypeModel(devTitle: "Жим лежа",
                                                       type: category,
                                                       parameters: [.weight(), .repeats()]
                                                      ))
}
