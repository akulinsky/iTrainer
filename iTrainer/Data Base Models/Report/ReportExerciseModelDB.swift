//
//  ReportExerciseModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation
import SwiftData

@Model
class ReportExerciseModelDB: ReportExerciseDataProtocol {
    
    @Attribute (.unique) var id = UUID()
    
    var titleExercise: String
    
    var exerciseId: UUID
    
    var index: Int
    
    var typeId: String
    
    var report: ReportWorkoutModelDB?
    
    @Relationship (deleteRule: .cascade, inverse: \ReportSetsModelDB.exercise)
    var exercises: [ReportSetsModelDB] = []
    
    init(titleExercise: String, exerciseId: UUID, index: Int, typeId: String) {
        self.titleExercise = titleExercise
        self.exerciseId = exerciseId
        self.index = index
        self.typeId = typeId
    }
}

extension ReportExerciseModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: ReportExerciseModelDB.self)
    }
}

// Predicates
extension ReportWorkoutModelDB {
    func predicateSelf() -> Predicate<ReportExerciseModelDB> {
        let id = self.id
        return #Predicate<ReportExerciseModelDB> {
            $0.id == id
        }
    }
}
