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
    @Published private(set) var generatedDefaultName = "Custom Exercise 1"
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
        selectedCategory?.displayName ?? "Not selected"
    }
    
    var trackingTypeTitle: String {
        selectedTrackingType?.displayTitle ?? "Not selected"
    }
    
    var previewSubtitle: String {
        let category = selectedCategory?.displayName ?? "Select category"
        let tracking = selectedTrackingType?.displayTitle ?? "Select tracking type"
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
            errors.category = "Select a category."
        }
        
        if selectedTrackingType == nil {
            errors.trackingType = "Select a tracking type."
        }
        
        if let selectedCategoryId, hasDuplicateName(title: effectiveTitle, categoryId: selectedCategoryId) {
            errors.name = "An exercise with this name already exists in this category."
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
        let prefix = "Custom Exercise "
        let maxNumber = titles.compactMap { title -> Int? in
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix(prefix) else { return nil }
            return Int(trimmed.dropFirst(prefix.count))
        }
        .max() ?? 0
        
        return "\(prefix)\(maxNumber + 1)"
    }
}
