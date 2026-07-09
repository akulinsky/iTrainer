//
//  ReportExerciseModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation
import SwiftData

@Model
class ReportExerciseModelDB: ReportExerciseDataProtocol, PersistentProtocol {
    
    @Attribute(.unique) var id = UUID()
    
    var titleExercise: String
    
    var exerciseId: UUID
    
    var index: Int
    
    var typeId: String
    
    var trackingTypeId: String?
    
    var restTime: TimeInterval?
    
    var report: ReportWorkoutModelDB?
    
    @Relationship(deleteRule: .cascade, inverse: \ReportSetsModelDB.reportExercise)
    var reportSets: [ReportSetsModelDB] = []
    
    @Relationship(deleteRule: .cascade, inverse: \SetsModelDB.reportExercise)
    var targetSets: [SetsModelDB] = []
    
    init(titleExercise: String,
         exerciseId: UUID,
         index: Int,
         typeId: String,
         trackingTypeId: String? = nil,
         restTime: TimeInterval? = nil) {
        self.titleExercise = titleExercise
        self.exerciseId = exerciseId
        self.index = index
        self.typeId = typeId
        self.trackingTypeId = trackingTypeId
        self.restTime = restTime
    }
}
