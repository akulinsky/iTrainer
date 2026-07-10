//
//  DataContainer.swift
//  AjaxTestSwiftUI
//
//  Created by Andrey Kulinskiy on 25.07.2024.
//

import Foundation
import Combine
import SwiftData

final class DataContainer: ObservableObject {
    
    static let shared = DataContainer()
    
    @Published var categories = ExerciseSeedLoader.loadCategories()
    
    @Published var arrayExercises = ExerciseSeedLoader.loadExercises()
    
    lazy var workoutManager = WorkoutManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutModelDB.self,
            WorkoutGroupModelDB.self,
            ExerciseModelDB.self,
            SetsModelDB.self,
            CustomExerciseTypeModelDB.self,
            BookmarkedExerciseTypeModelDB.self,
            ReportWorkoutModelDB.self,
            ReportExerciseModelDB.self,
            ReportSetsModelDB.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//        print("DBG_ URL to database : \(modelConfiguration.url)")

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var thisTestProperty = "thisTestProperty"
    
    init() {
        resetDatabaseForStringExerciseSeedIfNeeded()
        reloadExerciseCatalog()
    }
    
    func reloadExerciseCatalog() {
        let bookmarkedTypeIds = fetchBookmarkedExerciseTypeIds()
        let seedExercises = ExerciseSeedLoader.loadExercises(categories: categories)
        let customExercises = fetchCustomExerciseTypes()
            .compactMap { ExerciseTypeModel(customModel: $0, categories: categories) }
        
        arrayExercises = (seedExercises + customExercises)
            .map { exercise in
                var exercise = exercise
                exercise.bookmark = bookmarkedTypeIds.contains(exercise.id)
                return exercise
            }
            .sorted { lhs, rhs in
                if lhs.type.sortOrder != rhs.type.sortOrder {
                    return lhs.type.sortOrder < rhs.type.sortOrder
                }
                if lhs.isCustom != rhs.isCustom {
                    return lhs.isCustom
                }
                if lhs.isCustom, rhs.isCustom {
                    return (lhs.createdAt ?? .distantPast) < (rhs.createdAt ?? .distantPast)
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }
    
    private func fetchCustomExerciseTypes() -> [CustomExerciseTypeModelDB] {
        do {
            let context = ModelContext(sharedModelContainer)
            let descriptor = FetchDescriptor<CustomExerciseTypeModelDB>(sortBy: [SortDescriptor(\CustomExerciseTypeModelDB.createdAt, order: .forward)])
            return try context.fetch(descriptor)
        } catch {
            assertionFailure("Could not fetch custom exercises: \(error)")
            return []
        }
    }
    
    private func fetchBookmarkedExerciseTypeIds() -> Set<String> {
        do {
            let context = ModelContext(sharedModelContainer)
            let descriptor = FetchDescriptor<BookmarkedExerciseTypeModelDB>()
            return Set(try context.fetch(descriptor).map(\.typeId))
        } catch {
            assertionFailure("Could not fetch bookmarked exercises: \(error)")
            return []
        }
    }
    
    private func resetDatabaseForStringExerciseSeedIfNeeded() {
        let resetKey = "didResetDatabaseForStringExerciseSeedV1"
        guard !UserDefaults.standard.bool(forKey: resetKey) else {
            return
        }
        
        do {
            let context = ModelContext(sharedModelContainer)
            try removeAll(ReportSetsModelDB.self, context: context)
            try removeAll(ReportExerciseModelDB.self, context: context)
            try removeAll(ReportWorkoutModelDB.self, context: context)
            try removeAll(SetsModelDB.self, context: context)
            try removeAll(ExerciseModelDB.self, context: context)
            try removeAll(WorkoutGroupModelDB.self, context: context)
            try removeAll(WorkoutModelDB.self, context: context)
            try context.save()
            UserDefaults.standard.set(true, forKey: resetKey)
        } catch {
            fatalError("Could not reset database for string exercise seed: \(error)")
        }
    }
    
    private func removeAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) throws {
        let descriptor = FetchDescriptor<T>()
        let items = try context.fetch(descriptor)
        for item in items {
            context.delete(item)
        }
    }
}
