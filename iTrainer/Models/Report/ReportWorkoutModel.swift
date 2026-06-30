//
//  ReportWorkoutModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation

struct ReportWorkoutModel: ReportWorkoutDataProtocol, Hashable {
    
    var id: UUID
    
    var titleWorkout: String
    
    var workoutId: UUID
    
    var titleWorkoutGroup: String
    
    var workoutGroupId: UUID
    
    var startDate: Date?
    
    var endDate: Date?
    
    var targetExercisesCount = 0
    
    init(model: ReportWorkoutModelDB) {
        self.id = model.id
        self.titleWorkout = model.titleWorkout
        self.workoutId = model.workoutId
        self.workoutGroupId = model.workoutGroupId
        self.titleWorkoutGroup = model.titleWorkoutGroup
        self.startDate = model.startDate
        self.endDate = model.endDate
        self.targetExercisesCount = model.targetExercisesCount
    }
    
    init(id: UUID = UUID(), 
         titleWorkout: String,
         workoutId: UUID,
         titleWorkoutGroup: String,
         workoutGroupId: UUID,
         startDate: Date? = nil,
         endDate: Date? = nil) {
        
        self.id = id
        self.titleWorkout = titleWorkout
        self.workoutId = workoutId
        self.workoutGroupId = workoutGroupId
        self.titleWorkoutGroup = titleWorkoutGroup
        self.startDate = startDate
        self.endDate = endDate
    }
}
