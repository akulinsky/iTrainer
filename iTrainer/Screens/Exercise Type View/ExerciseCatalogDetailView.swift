//
//  ExerciseCatalogDetailView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 23.06.2026.
//

import SwiftUI

struct ExerciseCatalogDetailView: View {
    
    let model: ExerciseTypeModel
    
    private let iconHeight: CGFloat = 260
    private let cardCornerRadius: CGFloat = 16
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                titleCard
                metadataCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppColor.backgroundPrimary)
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var heroCard: some View {
        ZStack {
            AppColor.surfacePrimary
            
            if let icon = model.icon {
                icon
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var titleCard: some View {
        VStack(spacing: 8) {
            Text(model.displayName)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
            
            Text(model.type.displayName)
                .font(AppFont.categoryCardSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            metadataRow(title: "Category", value: model.type.displayName)
            metadataRow(title: "Parameters", value: parametersText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
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
