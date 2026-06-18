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
