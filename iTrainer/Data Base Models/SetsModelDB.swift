//
//  SetsModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class SetsModelDB: DataSetItemProtocol {
    @Attribute (.unique) var id = UUID()
    var index: Int = 0
    var reps: Int = 0
    var weight: Int = 0
    
    var exercise: ExerciseModelDB?
    
    init() {
        
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
