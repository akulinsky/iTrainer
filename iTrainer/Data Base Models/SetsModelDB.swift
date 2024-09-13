//
//  SetsModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class SetsModelDB: DataSetItemProtocol, DataParamsProtocol {
    @Attribute (.unique) var id = UUID()
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

extension SetsModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: SetsModelDB.self)
    }
}

// Predicates
extension SetsModelDB {
    func predicateSelf() -> Predicate<SetsModelDB> {
        let id = self.id
        return #Predicate<SetsModelDB> {
            $0.id == id
        }
    }
}
