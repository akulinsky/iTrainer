//
//  WorkoutGroupModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class WorkoutGroupModelDB: DataItemProtocol, PersistentProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    
    var workout: WorkoutModelDB?
    
    @Relationship (deleteRule: .cascade, inverse: \ExerciseModelDB.workoutGroup) 
    var exercises: [ExerciseModelDB] = []
    
    init() {
        
    }
}
