//
//  ExerciseItemHelpers.swift
//  iTrainer
//
//  Created by Codex on 15.07.2026.
//

import Foundation

extension ExerciseModelDB {
    var isHeadlineItem: Bool {
        kind == .headline
    }
    
    var isExerciseItem: Bool {
        kind == .exercise
    }
    
    var isSupersetItem: Bool {
        kind == .superset
    }
    
    var isTopLevelWorkoutItem: Bool {
        parentSuperset == nil
    }
    
    var sortedSupersetExercises: [ExerciseModelDB] {
        supersetExercises.sortedByIndex()
    }
}

extension ReportExerciseModelDB {
    var isExerciseItem: Bool {
        kind == .exercise
    }
    
    var isSupersetItem: Bool {
        kind == .superset
    }
    
    var isTopLevelReportItem: Bool {
        superset == nil
    }
    
    var sortedSupersetExercises: [ReportExerciseModelDB] {
        supersetExercises.sortedByIndex()
    }
}

extension ExerciseModel {
    var isHeadlineItem: Bool {
        kind == .headline
    }
    
    var isExerciseItem: Bool {
        kind == .exercise
    }
    
    var isSupersetItem: Bool {
        kind == .superset
    }
    
    var isTopLevelWorkoutItem: Bool {
        parentSupersetId == nil
    }
    
    var sortedSupersetExercises: [ExerciseModel] {
        supersetExercises.sortedByIndex()
    }
}

extension ReportExerciseModel {
    var isExerciseItem: Bool {
        kind == .exercise
    }
    
    var isSupersetItem: Bool {
        kind == .superset
    }
    
    var isTopLevelReportItem: Bool {
        supersetId == nil
    }
    
    var sortedSupersetExercises: [ReportExerciseModel] {
        supersetExercises.sortedByIndex()
    }
}

extension Array where Element == ExerciseModelDB {
    func sortedByIndex() -> [ExerciseModelDB] {
        sorted { $0.index < $1.index }
    }
    
    func topLevelWorkoutItems() -> [ExerciseModelDB] {
        filter { $0.isTopLevelWorkoutItem }.sortedByIndex()
    }
    
    func flattenedExerciseItems() -> [ExerciseModelDB] {
        sortedByIndex().flatMap { item in
            switch item.kind {
            case .headline:
                return [ExerciseModelDB]()
            case .exercise:
                return [item]
            case .superset:
                return item.sortedSupersetExercises.filter { $0.isExerciseItem }
            }
        }
    }
}

extension Array where Element == ReportExerciseModelDB {
    func sortedByIndex() -> [ReportExerciseModelDB] {
        sorted { $0.index < $1.index }
    }
    
    func topLevelReportItems() -> [ReportExerciseModelDB] {
        filter { $0.isTopLevelReportItem }.sortedByIndex()
    }
    
    func flattenedReportExerciseItems() -> [ReportExerciseModelDB] {
        sortedByIndex().flatMap { item in
            switch item.kind {
            case .headline:
                return [ReportExerciseModelDB]()
            case .exercise:
                return [item]
            case .superset:
                return item.sortedSupersetExercises.filter { $0.isExerciseItem }
            }
        }
    }
}

extension Array where Element == ExerciseModel {
    func sortedByIndex() -> [ExerciseModel] {
        sorted { $0.index < $1.index }
    }
    
    func topLevelWorkoutItems() -> [ExerciseModel] {
        filter { $0.isTopLevelWorkoutItem }.sortedByIndex()
    }
    
    func flattenedExerciseItems() -> [ExerciseModel] {
        sortedByIndex().flatMap { item in
            switch item.kind {
            case .headline:
                return [ExerciseModel]()
            case .exercise:
                return [item]
            case .superset:
                return item.sortedSupersetExercises.filter { $0.isExerciseItem }
            }
        }
    }
}

extension Array where Element == ReportExerciseModel {
    func sortedByIndex() -> [ReportExerciseModel] {
        sorted { $0.index < $1.index }
    }
    
    func topLevelReportItems() -> [ReportExerciseModel] {
        filter { $0.isTopLevelReportItem }.sortedByIndex()
    }
    
    func flattenedReportExerciseItems() -> [ReportExerciseModel] {
        sortedByIndex().flatMap { item in
            switch item.kind {
            case .headline:
                return [ReportExerciseModel]()
            case .exercise:
                return [item]
            case .superset:
                return item.sortedSupersetExercises.filter { $0.isExerciseItem }
            }
        }
    }
}
