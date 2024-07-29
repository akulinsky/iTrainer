//
//  WorkoutModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class WorkoutModelDB: DataItemProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    
    @Relationship (inverse: \WorkoutGroupModelDB.workout) var workoutGroups: [WorkoutGroupModelDB] = []
    
    init() {
        
    }
}

extension WorkoutModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: WorkoutModelDB.self)
    }
}

// Predicates
extension WorkoutModelDB {
    func predicateSelf() -> Predicate<WorkoutModelDB> {
        let id = self.id
        return #Predicate<WorkoutModelDB> {
            $0.id == id
        }
    }
}
