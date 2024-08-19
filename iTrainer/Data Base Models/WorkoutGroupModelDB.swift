//
//  WorkoutGroupModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class WorkoutGroupModelDB: DataItemProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    
    var workout: WorkoutModelDB?
    
    @Relationship (deleteRule: .cascade, inverse: \ExerciseModelDB.workoutGroup) 
    var exercises: [ExerciseModelDB] = []
    
    init() {
        
    }
}

extension WorkoutGroupModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: WorkoutGroupModelDB.self)
    }
}

// Predicates
extension WorkoutGroupModelDB {
    func predicateSelf() -> Predicate<WorkoutGroupModelDB> {
        let id = self.id
        return #Predicate<WorkoutGroupModelDB> {
            $0.id == id
        }
    }
}
