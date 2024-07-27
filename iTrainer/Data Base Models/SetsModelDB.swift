//
//  SetsModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class SetsModelDB: DataItemIndexProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var reps: Int = 0
    var weight: Int = 0
    
    var exercise: ExerciseModelDB?
    
    init() {
        
    }
}
