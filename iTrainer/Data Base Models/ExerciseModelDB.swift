//
//  ExerciseModelDB.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import Foundation
import SwiftData

@Model
class ExerciseModelDB: DataItemProtocol, PersistentProtocol {
    @Attribute(.unique) var id = UUID()
    var index: Int = 0
    var title: String?
    var typeId: String = ""
    var restTime: TimeInterval?
    var isArchived: Bool = false
    var archivedAt: Date?
    
    @Attribute(originalName: "isHeadline")
    private var legacyHeadlineFlag: Bool?
    
    var kindRawValue: Int = ExerciseItemKind.exercise.rawValue
    
    var workoutGroup: WorkoutGroupModelDB?
    
    var parentSuperset: ExerciseModelDB?
    
    @Relationship(deleteRule: .nullify, inverse: \ExerciseModelDB.parentSuperset)
    var supersetExercises: [ExerciseModelDB] = []
    
    @Relationship(deleteRule: .cascade, inverse: \SetsModelDB.exercise) 
    var sets: [SetsModelDB] = []
    
    init() {
        
    }
}

extension ExerciseModelDB {
    var kind: ExerciseItemKind {
        get {
            return ExerciseItemKind(rawValue: kindRawValue) ?? .exercise
        }
        set {
            kindRawValue = newValue.rawValue
        }
    }
    
    var needsLegacyHeadlineKindMigration: Bool {
        legacyHeadlineFlag == true && kind != .headline
    }
    
    func migrateLegacyHeadlineKindIfNeeded() {
        if needsLegacyHeadlineKindMigration {
            kindRawValue = ExerciseItemKind.headline.rawValue
        }
        legacyHeadlineFlag = nil
    }
}
