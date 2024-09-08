//
//  ReportWorkoutModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 07.09.2024.
//

import Foundation
import SwiftData

@Model
class ReportWorkoutModelDB: ReportDataItemProtocol {
    @Attribute (.unique) var id = UUID()
    var title: String?
    var startDate: Date?
    var endDate: Date?
    
//    @Relationship (deleteRule: .cascade, inverse: \WorkoutGroupModelDB.report)
//    var workoutGroups: [WorkoutGroupModelDB] = []
    
    init() {
        
    }
}

extension ReportWorkoutModelDB {
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: ReportWorkoutModelDB.self)
    }
}

// Predicates
extension ReportWorkoutModelDB {
    func predicateSelf() -> Predicate<ReportWorkoutModelDB> {
        let id = self.id
        return #Predicate<ReportWorkoutModelDB> {
            $0.id == id
        }
    }
}
