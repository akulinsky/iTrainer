//
//  CreateCustomExerciseView.swift
//  iTrainer
//
//  Created by Codex on 09.07.2026.
//

import SwiftUI

struct CreateCustomExerciseView: View {
    @StateObject private var viewModel = CreateCustomExerciseViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    let onSave: (String) -> Void
    
    private let horizontalPadding: CGFloat = 20
    private let cardCornerRadius: CGFloat = 14
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    previewCard
                    nameInputCard
                    selectionCard
                    descriptionCard
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(AppColor.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Create Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppColor.brandPrimary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColor.brandPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .foregroundStyle(AppColor.brandPrimary)
                    .disabled(viewModel.isSaving)
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .navigationDestination(for: CustomExerciseCreationRoute.self) { route in
                switch route {
                case .category:
                    SelectCustomExerciseCategoryView(viewModel: viewModel)
                case .trackingType:
                    SelectCustomExerciseTrackingTypeView(viewModel: viewModel)
                }
            }
        }
    }
    
    private var previewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppColor.brandPrimary)
                Image(systemName: viewModel.previewIconSystemName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 78, height: 78)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.effectiveTitle)
                    .font(AppFont.workoutWidgetTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(viewModel.previewSubtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: cardCornerRadius)
    }
    
    private var nameInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(viewModel.generatedDefaultName, text: $viewModel.nameInput)
                .font(AppFont.workoutGroupCardSubtitle)
                .foregroundStyle(AppColor.textPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($focusedField, equals: .name)
            
            if let error = viewModel.validationErrors.name {
                validationText(error)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: cardCornerRadius,
                        strokeColor: viewModel.validationErrors.name == nil ? AppColor.separatorSoft : AppColor.progressRed.opacity(0.65))
    }
    
    private var selectionCard: some View {
        VStack(spacing: 0) {
            NavigationLink(value: CustomExerciseCreationRoute.category) {
                selectionRow(title: "Category",
                             value: viewModel.categoryTitle,
                             error: viewModel.validationErrors.category)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                focusedField = nil
            })
            
            Divider()
                .padding(.vertical, 16)
            
            NavigationLink(value: CustomExerciseCreationRoute.trackingType) {
                selectionRow(title: "Tracking Type",
                             value: viewModel.trackingTypeTitle,
                             error: viewModel.validationErrors.trackingType)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                focusedField = nil
            })
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: cardCornerRadius,
                        strokeColor: selectionStrokeColor)
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(AppFont.workoutGroupCardSubtitle)
                .fontWeight(.semibold)
                .foregroundStyle(AppColor.textPrimary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.descriptionText)
                    .font(AppFont.workoutGroupCardSubtitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .background(AppColor.surfacePrimary)
                    .focused($focusedField, equals: .description)
                
                if viewModel.descriptionText.isEmpty {
                    Text("Optional")
                        .font(AppFont.workoutGroupCardSubtitle)
                        .foregroundStyle(AppColor.textSecondary.opacity(0.75))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(10)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: cardCornerRadius)
    }
    
    private var selectionStrokeColor: Color {
        if viewModel.validationErrors.category != nil || viewModel.validationErrors.trackingType != nil {
            return AppColor.progressRed.opacity(0.65)
        }
        return AppColor.separatorSoft
    }
    
    private func selectionRow(title: String, value: String, error: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(title)
                    .font(AppFont.workoutGroupCardSubtitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(value)
                    .font(AppFont.workoutGroupCardSubtitle)
                    .foregroundStyle(value == "Not selected" ? AppColor.textSecondary : AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            if let error {
                validationText(error)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
    
    private func validationText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.caption)
            .foregroundStyle(AppColor.progressRed)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func save() {
        Task {
            if let newExerciseId = await viewModel.save() {
                onSave(newExerciseId)
                dismiss()
            }
        }
    }
}

enum CustomExerciseCreationRoute: Hashable {
    case category
    case trackingType
}

private enum Field: Hashable {
    case name
    case description
}

private extension View {
    func cardBackground(cornerRadius: CGFloat, strokeColor: Color = AppColor.separatorSoft) -> some View {
        background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            }
    }
}

#Preview {
    CreateCustomExerciseView { _ in }
}
