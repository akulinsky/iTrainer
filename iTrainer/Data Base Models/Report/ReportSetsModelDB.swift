//
//  ReportSetsModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation
import SwiftData

@Model
class ReportSetsModelDB: ReportSetDataProtocol, DataParamsProtocol, PersistentProtocol {
    
    @Attribute (.unique) var id = UUID()
    
    var date: Date
    
    // MARK: - Params
    
    var reps: Int?
    
    var weight: Float?
    
    var distance: Float?
    
    var time: TimeInterval?
    
    // MARK: -
    
    var reportExercise: ReportExerciseModelDB?
    
    init(date: Date) {
        self.date = date
    }
}
