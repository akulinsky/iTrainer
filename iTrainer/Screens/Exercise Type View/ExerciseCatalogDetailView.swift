//
//  ExerciseCatalogDetailView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 23.06.2026.
//

import SwiftUI

struct ExerciseCatalogDetailView: View {
    
    let model: ExerciseTypeModel
    
    @State private var isStatisticsPresented = false
    @State private var isDeleteAlertPresented = false
    @State private var hasActiveWorkout = true
    @State private var isBookmarked: Bool
    
    private let horizontalPadding: CGFloat = 20
    private let cardCornerRadius: CGFloat = 14
    private let exerciseInfo: ExerciseInfo?
    private let onOpenStatistics: (() -> Void)?
    private let onBookmarkChanged: ((Bool) -> Void)?
    private let onDelete: (() -> Void)?
    
    init(model: ExerciseTypeModel,
         onOpenStatistics: (() -> Void)? = nil,
         onBookmarkChanged: ((Bool) -> Void)? = nil,
         onDelete: (() -> Void)? = nil) {
        self.model = model
        self.exerciseInfo = model.isCustom ? nil : ExerciseInfoLoader.info(for: model.id)
        self.onOpenStatistics = onOpenStatistics
        self.onBookmarkChanged = onBookmarkChanged
        self.onDelete = onDelete
        _isBookmarked = State(initialValue: model.bookmark)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ExerciseMediaView(model: model,
                                  cornerRadius: cardCornerRadius)
                ExerciseTitleCard(title: model.displayName,
                                  category: model.type.displayName,
                                  cornerRadius: cardCornerRadius)
                ExerciseBasicInfoCard(category: model.type.displayName,
                                      parameters: parametersText,
                                      cornerRadius: cardCornerRadius)
                ExerciseStatisticsNavigationCard(cornerRadius: cardCornerRadius,
                                                 action: openStatistics)
                
                if exerciseInfo == nil && !model.isCustom {
                    ExerciseMissingInfoCard(exerciseId: model.id,
                                            cornerRadius: cardCornerRadius)
                }
                
                if let descriptionText {
                    ExerciseDescriptionCard(text: descriptionText,
                                            cornerRadius: cardCornerRadius)
                }
                
                if !techniqueTexts.isEmpty {
                    ExerciseTechniqueCard(items: techniqueTexts,
                                          cornerRadius: cardCornerRadius)
                }
                
                if model.isCustom && !hasActiveWorkout {
                    DeleteCustomExerciseCard(cornerRadius: cardCornerRadius) {
                        isDeleteAlertPresented = true
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(model.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .foregroundStyle(isBookmarked ? AppColor.brandPrimary : AppColor.textSecondary)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
            }
        }
        .navigationDestination(isPresented: $isStatisticsPresented) {
            ExerciseStatisticsView(exerciseType: model)
        }
        .alert("Delete this exercise?", isPresented: $isDeleteAlertPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExercise()
            }
        } message: {
            Text("This exercise will be removed from the catalog and all workouts. Past reports will stay unchanged.")
        }
        .task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            hasActiveWorkout = await dataManager.fetchStartedWorkout() != nil
        }
    }
    
    private func openStatistics() {
        if let onOpenStatistics {
            onOpenStatistics()
        } else {
            isStatisticsPresented = true
        }
    }
    
    private func toggleBookmark() {
        let newValue = !isBookmarked
        isBookmarked = newValue
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.setExerciseTypeBookmark(typeId: model.id, isBookmarked: newValue)
            await MainActor.run {
                DataContainer.shared.reloadExerciseCatalog()
                onBookmarkChanged?(newValue)
            }
        }
    }
    
    private func deleteExercise() {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.deleteCustomExerciseTemplate(typeId: model.id)
            await MainActor.run {
                DataContainer.shared.reloadExerciseCatalog()
                onDelete?()
            }
        }
    }
    
    private var parametersText: String {
        model.parameters.map { $0.title }.joined(separator: " · ")
    }
    
    private var descriptionText: String? {
        if model.isCustom {
            guard let text = model.customDescriptionText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return nil
            }
            return text
        }
        
        guard let exerciseInfo else { return nil }
        return localizedText(for: exerciseInfo.descriptionKey)
    }
    
    private var techniqueTexts: [String] {
        guard let exerciseInfo else { return [] }
        return exerciseInfo.techniqueKeys.map(localizedText)
    }
    
    private func localizedText(for key: String) -> String {
        String(localized: String.LocalizationValue(key), table: "ExerciseInfo")
    }
}

private struct ExerciseMediaView: View {
    let model: ExerciseTypeModel
    let cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            AppColor.surfacePrimary
            
            if model.isCustom {
                ExerciseTypeIconView(exerciseType: model,
                                     size: 160,
                                     cornerRadius: 28,
                                     symbolSize: 74)
                    .padding(.vertical, 42)
            } else if let icon = model.icon {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

private struct ExerciseTitleCard: View {
    let title: String
    let category: String
    let cornerRadius: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.82)
            
            Text(category)
                .font(AppFont.categoryCardSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

private struct ExerciseBasicInfoCard: View {
    let category: String
    let parameters: String
    let cornerRadius: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle("Basic Information")
            
            VStack(spacing: 0) {
                infoRow(title: "Category", value: category)
                Divider()
                    .padding(.vertical, 12)
                infoRow(title: "Parameters", value: parameters)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(AppFont.workoutGroupCardSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(AppFont.workoutGroupCardSubtitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ExerciseStatisticsNavigationCard: View {
    let cornerRadius: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppColor.progressGreen)
                    .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Statistics")
                        .font(AppFont.workoutWidgetTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("View global exercise statistics")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
                
                Spacer(minLength: 12)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Statistics")
        .accessibilityHint("View global exercise statistics")
    }
}

private struct ExerciseMissingInfoCard: View {
    let exerciseId: String
    let cornerRadius: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardTitle("Missing exercise info")
            Text("Missing exercise info for exercise id: \(exerciseId)")
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

private struct ExerciseDescriptionCard: View {
    let text: String
    let cornerRadius: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Description")
            Text(text)
                .font(AppFont.workoutGroupCardSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

private struct ExerciseTechniqueCard: View {
    let items: [String]
    let cornerRadius: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle("Technique")
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColor.progressGreen)
                            .padding(.top, 1)
                        Text(item)
                            .font(AppFont.workoutGroupCardSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

private struct DeleteCustomExerciseCard: View {
    let cornerRadius: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(role: .destructive, action: action) {
            Text("Delete Exercise")
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.progressRed)
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AppColor.progressRed.opacity(0.35), lineWidth: 1)
                }
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private func cardTitle(_ title: String) -> some View {
    Text(title)
        .font(AppFont.workoutWidgetTitle)
        .foregroundStyle(AppColor.textPrimary)
}

private struct ExerciseInfo: Decodable, Hashable {
    let exerciseId: String
    let descriptionKey: String
    let techniqueKeys: [String]
}

private enum ExerciseInfoLoader {
    private static let infoByExerciseId: [String: ExerciseInfo] = {
        guard let url = Bundle.main.url(forResource: "exercise_info", withExtension: "json") else {
            assertionFailure("Missing bundled resource: exercise_info.json")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([ExerciseInfo].self, from: data)
            return Dictionary(uniqueKeysWithValues: items.map { ($0.exerciseId, $0) })
        } catch {
            assertionFailure("Failed to decode exercise_info.json: \(error)")
            return [:]
        }
    }()
    
    static func info(for exerciseId: String) -> ExerciseInfo? {
        let info = infoByExerciseId[exerciseId]
        #if DEBUG
        if info == nil {
            print("Missing exercise info for exercise id: \(exerciseId)")
        }
        #endif
        return info
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
    NavigationStack {
        ExerciseCatalogDetailView(model: ExerciseTypeModel(id: "chest_bench_press",
                                                           titleKey: "exercise.chest.bench_press",
                                                           defaultTitle: "Bench Press",
                                                           devTitle: "Bench Press",
                                                           iconName: "icMissingImage",
                                                           type: category,
                                                           parameters: [.weight(), .repeats()]
                                                          ))
    }
}
