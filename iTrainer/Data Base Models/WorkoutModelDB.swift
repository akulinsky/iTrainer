//
//  WorkoutModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class WorkoutModelDB: DataItemProtocol, PersistentProtocol {
    @Attribute(.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    var isSelected: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutGroupModelDB.workout) 
    var workoutGroups: [WorkoutGroupModelDB] = []
    
    init() {
        
    }
}
