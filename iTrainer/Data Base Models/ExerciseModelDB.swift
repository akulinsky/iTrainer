//
//  ExerciseModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class ExerciseModelDB: DataItemProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    
    var workoutGroup: WorkoutGroupModelDB?
    
    @Relationship (inverse: \SetsModelDB.exercise) var sets: [SetsModelDB] = []
    
    init() {
        
    }
}

extension ExerciseModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: ExerciseModelDB.self)
    }
}

// Predicates
extension ExerciseModelDB {
    func predicateSelf() -> Predicate<ExerciseModelDB> {
        let id = self.id
        return #Predicate<ExerciseModelDB> {
            $0.id == id
        }
    }
}
