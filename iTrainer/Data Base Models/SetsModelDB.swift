//
//  SetsModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class SetsModelDB: DataSetItemProtocol, DataParamsProtocol, PersistentProtocol {
    @Attribute(.unique) var id = UUID()
    var index: Int = 0
    var reps: Int?
    var weight: Float?
    var distance: Float?
    var time: TimeInterval?
    
    var exercise: ExerciseModelDB?
    
    var reportExercise: ReportExerciseModelDB?
    
    init() {
        
    }
    
    func copy() -> SetsModelDB {
        let copy = SetsModelDB()
        copy.index = self.index
        copy.reps = self.reps
        copy.weight = self.weight
        copy.distance = self.distance
        copy.time = self.time
        return copy
    }
}
