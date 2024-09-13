//
//  ReportWorkoutModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 07.09.2024.
//

import Foundation
import SwiftData

@Model
class ReportWorkoutModelDB: ReportWorkoutDataProtocol {
    
    @Attribute (.unique) var id = UUID()
    
    var titleWorkout: String
    
    var workoutId: UUID
    
    var workoutGroupId: UUID
    
    var titleWorkoutGroup: String
    
    var startDate: Date?
    
    var endDate: Date?
    
    var targetExercisesCount = 0
    
    @Relationship (deleteRule: .cascade, inverse: \ReportExerciseModelDB.report)
    var exercises: [ReportExerciseModelDB] = []
    
    init(titleWorkout: String,
         workoutId: UUID,
         workoutGroupId: UUID,
         titleWorkoutGroup: String) {
        
        self.titleWorkout = titleWorkout
        self.workoutId = workoutId
        self.workoutGroupId = workoutGroupId
        self.titleWorkoutGroup = titleWorkoutGroup
    }
}

extension ReportWorkoutModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: ReportWorkoutModelDB.self)
    }
}

// Predicates
extension ReportWorkoutModelDB {
    func predicateSelf() -> Predicate<ReportWorkoutModelDB> {
        let id = self.id
        return #Predicate<ReportWorkoutModelDB> {
            $0.id == id
        }
    }
}
