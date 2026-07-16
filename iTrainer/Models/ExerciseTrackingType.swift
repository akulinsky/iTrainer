//
//  ExerciseTrackingType.swift
//  iTrainer
//
//  Created by Codex on 08.07.2026.
//

import Foundation

enum ExerciseTrackingType: String, CaseIterable, Hashable, Sendable, Codable {
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
    
    var displayTitle: String {
        switch self {
        case .weightedReps:
            String(localized: "tracking_type.weighted_reps.title")
        case .repsOnly:
            String(localized: "tracking_type.reps_only.title")
        case .timed:
            String(localized: "tracking_type.timed.title")
        case .distance:
            String(localized: "tracking_type.distance.title")
        case .distanceTime:
            String(localized: "tracking_type.distance_time.title")
        }
    }
    
    var descriptionText: String {
        switch self {
        case .weightedReps:
            String(localized: "tracking_type.weighted_reps.description")
        case .repsOnly:
            String(localized: "tracking_type.reps_only.description")
        case .timed:
            String(localized: "tracking_type.timed.description")
        case .distance:
            String(localized: "tracking_type.distance.description")
        case .distanceTime:
            String(localized: "tracking_type.distance_time.description")
        }
    }
    
    var iconSystemName: String {
        switch self {
        case .weightedReps:
            "dumbbell.fill"
        case .repsOnly:
            "figure.strengthtraining.traditional"
        case .timed:
            "timer"
        case .distance:
            "point.topleft.down.curvedto.point.bottomright.up"
        case .distanceTime:
            "figure.run"
        }
    }
    
    var parameters: [SetsParameter] {
        switch self {
        case .weightedReps:
            [.weight(), .repeats()]
        case .repsOnly:
            [.repeats()]
        case .timed:
            [.time()]
        case .distance:
            [.distance()]
        case .distanceTime:
            [.distance(), .time()]
        }
    }
}

extension ExerciseTypeModel {
    var trackingType: ExerciseTrackingType? {
        ExerciseTrackingType(parameters: parameters)
    }
}
