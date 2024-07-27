//
//  WorkoutGroupModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class WorkoutGroupModelDB: DataItemIndexProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    
    var workout: WorkoutModelDB?
    
    @Relationship (inverse: \ExerciseModelDB.workoutGroup) var exercises: [ExerciseModelDB] = []
    
    init() {
        
    }
}
