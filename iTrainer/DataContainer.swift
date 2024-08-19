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
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutModelDB.self,
            WorkoutGroupModelDB.self,
            ExerciseModelDB.self,
            SetsModelDB.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        
    }
}
