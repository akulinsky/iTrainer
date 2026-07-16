//
//  CreateCustomExerciseViewModel.swift
//  iTrainer
//
//  Created by Codex on 09.07.2026.
//

import Foundation

@MainActor
final class CreateCustomExerciseViewModel: ObservableObject {
    struct ValidationErrors {
        var name: String?
        var category: String?
        var trackingType: String?
        
        var hasAnyError: Bool {
            name != nil || category != nil || trackingType != nil
        }
    }
    
    @Published var nameInput = "" {
        didSet { validationErrors.name = nil }
    }
    @Published var descriptionText = ""
    @Published private(set) var generatedDefaultName = CreateCustomExerciseViewModel.defaultName(number: 1)
    @Published private(set) var selectedCategoryId: String? {
        didSet { validationErrors.category = nil }
    }
    @Published private(set) var selectedTrackingType: ExerciseTrackingType? {
        didSet { validationErrors.trackingType = nil }
    }
    @Published private(set) var validationErrors = ValidationErrors()
    @Published private(set) var isSaving = false
    
    var categories: [ExerciseCategory] {
        DataContainer.shared.categories
    }
    
    var effectiveTitle: String {
        let trimmedInput = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedInput.isEmpty ? generatedDefaultName : trimmedInput
    }
    
    var selectedCategory: ExerciseCategory? {
        guard let selectedCategoryId else { return nil }
        return categories.first { $0.id == selectedCategoryId }
    }
    
    var categoryTitle: String {
        selectedCategory?.displayName ?? String(localized: "common.not_selected")
    }
    
    var trackingTypeTitle: String {
        selectedTrackingType?.displayTitle ?? String(localized: "common.not_selected")
    }
    
    var isCategoryPlaceholder: Bool {
        selectedCategoryId == nil
    }
    
    var isTrackingTypePlaceholder: Bool {
        selectedTrackingType == nil
    }
    
    var previewSubtitle: String {
        let category = selectedCategory?.displayName ?? String(localized: "custom_exercise.select_category")
        let tracking = selectedTrackingType?.displayTitle ?? String(localized: "custom_exercise.select_tracking_type")
        return "\(category) · \(tracking)"
    }
    
    var previewIconSystemName: String {
        selectedTrackingType?.iconSystemName ?? "dumbbell.fill"
    }
    
    func loadInitialData() async {
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let customExercises = await dataManager.fetchCustomExerciseTypes()
        generatedDefaultName = Self.nextDefaultName(from: customExercises.map(\.title))
    }
    
    func selectCategory(_ category: ExerciseCategory) {
        selectedCategoryId = category.id
    }
    
    func selectTrackingType(_ trackingType: ExerciseTrackingType) {
        selectedTrackingType = trackingType
    }
    
    func save() async -> String? {
        guard validate() else { return nil }
        guard let selectedCategoryId, let selectedTrackingType else { return nil }
        
        isSaving = true
        defer { isSaving = false }
        
        let description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let id = await dataManager.createCustomExercise(title: effectiveTitle,
                                                        categoryId: selectedCategoryId,
                                                        trackingType: selectedTrackingType,
                                                        descriptionText: description.isEmpty ? nil : description)
        DataContainer.shared.reloadExerciseCatalog()
        return id
    }
    
    private func validate() -> Bool {
        var errors = ValidationErrors()
        
        if selectedCategoryId == nil {
            errors.category = String(localized: "custom_exercise.error.category_required")
        }
        
        if selectedTrackingType == nil {
            errors.trackingType = String(localized: "custom_exercise.error.tracking_type_required")
        }
        
        if let selectedCategoryId, hasDuplicateName(title: effectiveTitle, categoryId: selectedCategoryId) {
            errors.name = String(localized: "custom_exercise.error.duplicate_name")
        }
        
        validationErrors = errors
        return !errors.hasAnyError
    }
    
    private func hasDuplicateName(title: String, categoryId: String) -> Bool {
        let normalizedTitle = Self.normalized(title)
        return DataContainer.shared.arrayExercises.contains { exercise in
            exercise.type.id == categoryId && Self.normalized(exercise.displayName) == normalizedTitle
        }
    }
    
    private static func normalized(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private static func nextDefaultName(from titles: [String]) -> String {
        let prefix = String(localized: "custom_exercise.generated_name_prefix")
        let maxNumber = titles.compactMap { title -> Int? in
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix(prefix) else { return nil }
            return Int(trimmed.dropFirst(prefix.count))
        }
        .max() ?? 0
        
        return defaultName(number: maxNumber + 1)
    }
    
    private static func defaultName(number: Int) -> String {
        String.localizedStringWithFormat(String(localized: "custom_exercise.generated_name"), number)
    }
}
