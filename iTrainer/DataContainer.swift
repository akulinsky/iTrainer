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
    
    @Published var arrayExercises = ExerciseTypeModel.createExercises
    
    let workoutManager = WorkoutManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutModelDB.self,
            WorkoutGroupModelDB.self,
            ExerciseModelDB.self,
            SetsModelDB.self
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
        
    }
}
