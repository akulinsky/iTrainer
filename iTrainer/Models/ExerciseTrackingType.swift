//
//  ExerciseTrackingType.swift
//  iTrainer
//
//  Created by Codex on 08.07.2026.
//

import Foundation

enum ExerciseTrackingType: String, Hashable, Sendable, Codable {
    case weightedReps
    case repsOnly
    case timed
    case distance
    case distanceTime
    
    init?(parameters: [SetsParameter]) {
        let parameterIds = Set(parameters.map(\.id))
        
        switch parameterIds {
        case Set([SetsParameter.weight().id, SetsParameter.repeats().id]):
            self = .weightedReps
        case Set([SetsParameter.repeats().id]):
            self = .repsOnly
        case Set([SetsParameter.time().id]):
            self = .timed
        case Set([SetsParameter.distance().id]):
            self = .distance
        case Set([SetsParameter.distance().id, SetsParameter.time().id]):
            self = .distanceTime
        default:
            assertionFailure("Unsupported exercise tracking parameter combination: \(parameterIds.sorted())")
            return nil
        }
    }
    
    init?(typeId: String) {
        guard let exerciseType = DataContainer.shared.arrayExercises.first(where: { $0.id == typeId }) else {
            assertionFailure("Missing exercise type for tracking type id: \(typeId)")
            return nil
        }
        self.init(parameters: exerciseType.parameters)
    }
    
    var usesStrengthVolume: Bool {
        self == .weightedReps
    }
    
    var usesRepetitions: Bool {
        switch self {
        case .weightedReps, .repsOnly:
            true
        case .timed, .distance, .distanceTime:
            false
        }
    }
    
    var usesTimedDuration: Bool {
        self == .timed
    }
    
    var usesDistance: Bool {
        switch self {
        case .distance, .distanceTime:
            true
        case .weightedReps, .repsOnly, .timed:
            false
        }
    }
    
    var usesPace: Bool {
        self == .distanceTime
    }
}

extension ExerciseTypeModel {
    var trackingType: ExerciseTrackingType? {
        ExerciseTrackingType(parameters: parameters)
    }
}
