//
//  DataItemsProtocol.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

protocol DataIdProtocol: Identifiable {
    var id: UUID { get }
}

protocol DataItemProtocol: DataIdProtocol {
    var index: Int { get }
    var title: String? { get }
}

protocol DataSetItemProtocol: DataIdProtocol {
    var index: Int { get }
}

protocol DataParamsProtocol {
    var reps: Int? { get }
    var weight: Float? { get }
    var distance: Float? { get }
    var time: TimeInterval? { get }
}

protocol ReportWorkoutDataProtocol: DataIdProtocol {
    var workoutId: UUID { get }
    var titleWorkout: String { get }
    var workoutGroupId: UUID { get }
    var titleWorkoutGroup: String { get }
    var startDate: Date? { get }
    var endDate: Date? { get }
}

protocol ReportExerciseDataProtocol: DataIdProtocol {
    var titleExercise: String { get }
    var exerciseId: UUID { get }
    var index: Int { get }
    var typeId: String { get }
}

protocol ReportSetDataProtocol: DataIdProtocol {
    var date: Date { get }
}

protocol PersistentProtocol: PersistentModel, DataIdProtocol {
    associatedtype Model: PersistentModel
    
    static func count() async -> Int
    
    func predicateSelf() -> Predicate<Model>
}

extension PersistentProtocol {
    
    static func count() async -> Int {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).count(type: self.self)
    }
    
    func predicateSelf() -> Predicate<WorkoutModelDB> {
        let id = self.id
        return #Predicate<WorkoutModelDB> { $0.id == id }
    }
}
