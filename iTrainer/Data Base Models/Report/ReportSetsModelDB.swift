//
//  ReportSetsModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation
import SwiftData

@Model
class ReportSetsModelDB: ReportSetDataProtocol, DataParamsProtocol {
    
    @Attribute (.unique) var id = UUID()
    
    var date: Date
    
    // MARK: - Params
    
    var reps: Int?
    
    var weight: Float?
    
    var distance: Float?
    
    var time: TimeInterval?
    
    // MARK: -
    
    var reportExercise: ReportExerciseModelDB?
    
    var exercise: ReportExerciseModelDB?
    
    init(date: Date) {
        self.date = date
    }
}

extension ReportSetsModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: ReportSetsModelDB.self)
    }
}

// Predicates
extension ReportSetsModelDB {
    func predicateSelf() -> Predicate<ReportSetsModelDB> {
        let id = self.id
        return #Predicate<ReportSetsModelDB> {
            $0.id == id
        }
    }
}
