//
//  ReportStatusService.swift
//  iTrainer
//
//  Created by OpenAI on 30.06.2026.
//

import Foundation

enum PersonalRecordType: Hashable {
    case weight
    case repetitions
    case volume
}

struct ExerciseStatusComparison: Hashable {
    let type: PersonalRecordType
    let current: Float
    let previous: Float
    let contextWeight: Float?
    
    init(type: PersonalRecordType,
         current: Float,
         previous: Float,
         contextWeight: Float? = nil) {
        self.type = type
        self.current = current
        self.previous = previous
        self.contextWeight = contextWeight
    }
    
    var improvement: Float {
        max(current - previous, 0)
    }
}

struct ExerciseStatusResult: Hashable {
    let status: ExerciseReportStatus
    let comparison: ExerciseStatusComparison?
}

enum ExerciseReportStatus: Hashable {
    case personalRecord(type: PersonalRecordType)
    case progress
    case goalAchieved
    case goalMissed
    case complete
}

enum WorkoutReportStatus: Hashable {
    case personalRecord(count: Int)
    case progress
    case workoutIncomplete(completed: Int, total: Int)
    case goalsAchieved
    case goalsNotAchieved
    case workoutComplete
}

struct ReportStatusService {
    static func calculateExerciseStatus(report: ReportExerciseModel,
                                        history: [ReportExerciseModel]) -> ExerciseReportStatus {
        calculateExerciseStatusResult(report: report, history: history).status
    }
    
    static func calculateExerciseStatusResult(report: ReportExerciseModel,
                                              history: [ReportExerciseModel]) -> ExerciseStatusResult {
        let previousReports = previousReports(for: report, in: history)
        
        if let personalRecordComparison = personalRecordComparison(for: report, comparedTo: previousReports) {
            return ExerciseStatusResult(status: .personalRecord(type: personalRecordComparison.type),
                                        comparison: personalRecordComparison)
        }
        
        let localPreviousReports = previousReports.filter {
            $0.workoutId == report.workoutId && $0.workoutGroupId == report.workoutGroupId
        }
        if let progressComparison = progressComparison(for: report, comparedTo: localPreviousReports) {
            return ExerciseStatusResult(status: .progress,
                                        comparison: progressComparison)
        }
        
        return ExerciseStatusResult(status: goalStatus(for: report), comparison: nil)
    }
    
    static func calculateWorkoutStatus(report: ReportWorkoutModel,
                                       exercises: [ReportExerciseModel],
                                       exerciseStatuses: [ExerciseReportStatus]) -> WorkoutReportStatus {
        let personalRecordCount = exerciseStatuses.filter { $0.isPersonalRecord }.count
        if personalRecordCount > 0 {
            return .personalRecord(count: personalRecordCount)
        }
        
        if exerciseStatuses.contains(.progress) {
            return .progress
        }
        
        let completedExercises = exercises.filter { !$0.sets.isEmpty }.count
        let plannedExercises = report.targetExercisesCount
        if plannedExercises > 0 && completedExercises < plannedExercises {
            return .workoutIncomplete(completed: completedExercises, total: plannedExercises)
        }
        
        let hasGoals = exercises.contains { !$0.targetSets.isEmpty }
        if hasGoals {
            return exerciseStatuses.contains(.goalMissed) ? .goalsNotAchieved : .goalsAchieved
        }
        
        return .workoutComplete
    }
    
    static func totalVolume(for exercises: [ReportExerciseModel]) -> Float {
        exercises.reduce(Float.zero) { partialResult, exercise in
            partialResult + exerciseVolume(for: exercise)
        }
    }
    
    static func totalReps(for exercises: [ReportExerciseModel]) -> Int {
        exercises.reduce(0) { partialResult, exercise in
            partialResult + exercise.sets.reduce(0) { $0 + reps(for: $1.parameters) }
        }
    }
    
    static func targetVolume(for exercises: [ReportExerciseModel]) -> Float {
        exercises.reduce(Float.zero) { partialResult, exercise in
            partialResult + exercise.targetSets.reduce(Float.zero) { $0 + volume(for: $1.parameters) }
        }
    }
    
    static func targetReps(for exercises: [ReportExerciseModel]) -> Int {
        exercises.reduce(0) { partialResult, exercise in
            partialResult + exercise.targetSets.reduce(0) { $0 + reps(for: $1.parameters) }
        }
    }
    
    static func hasGoals(in exercises: [ReportExerciseModel]) -> Bool {
        exercises.contains { !$0.targetSets.isEmpty }
    }
}

private extension ReportStatusService {
    static func previousReports(for report: ReportExerciseModel,
                                in history: [ReportExerciseModel]) -> [ReportExerciseModel] {
        history.filter { historyItem in
            guard historyItem.id != report.id else { return false }
            guard historyItem.typeId == report.typeId else { return false }
            guard let reportDate = report.date else { return true }
            guard let historyDate = historyItem.date else { return false }
            return historyDate < reportDate
        }
    }
    
    static func personalRecordComparison(for report: ReportExerciseModel,
                                         comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
        guard !previousReports.isEmpty else { return nil }
        
        if let currentMaxWeight = maxWeight(for: report),
           let previousMaxWeight = previousReports.compactMap(maxWeight(for:)).max(),
           currentMaxWeight > previousMaxWeight {
            return ExerciseStatusComparison(type: .weight,
                                            current: currentMaxWeight,
                                            previous: previousMaxWeight)
        }
        
        if let previousMaxWeight = previousReports.compactMap(maxWeight(for:)).max() {
            let currentReps = bestReps(at: previousMaxWeight, in: report)
            let previousReps = previousReports.map { bestReps(at: previousMaxWeight, in: $0) }.max() ?? 0
            if currentReps > previousReps {
                return ExerciseStatusComparison(type: .repetitions,
                                                current: Float(currentReps),
                                                previous: Float(previousReps),
                                                contextWeight: previousMaxWeight)
            }
        }
        
        let currentVolume = exerciseVolume(for: report)
        let previousBestVolume = previousReports.map(exerciseVolume(for:)).max() ?? 0
        if currentVolume > 0 && currentVolume > previousBestVolume {
            return ExerciseStatusComparison(type: .volume,
                                            current: currentVolume,
                                            previous: previousBestVolume)
        }
        
        return nil
    }
    
    static func isProgress(_ report: ReportExerciseModel,
                           comparedTo previousReports: [ReportExerciseModel]) -> Bool {
        progressComparison(for: report, comparedTo: previousReports) != nil
    }
    
    static func progressComparison(for report: ReportExerciseModel,
                                   comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
        guard let previousReport = previousReports.max(by: { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }) else {
            return nil
        }
        
        if let currentMaxWeight = maxWeight(for: report),
           let previousMaxWeight = maxWeight(for: previousReport),
           currentMaxWeight > previousMaxWeight {
            return ExerciseStatusComparison(type: .weight,
                                            current: currentMaxWeight,
                                            previous: previousMaxWeight)
        }
        
        if let previousMaxWeight = maxWeight(for: previousReport) {
            let currentReps = bestReps(at: previousMaxWeight, in: report)
            let previousReps = bestReps(at: previousMaxWeight, in: previousReport)
            if currentReps > previousReps {
                return ExerciseStatusComparison(type: .repetitions,
                                                current: Float(currentReps),
                                                previous: Float(previousReps),
                                                contextWeight: previousMaxWeight)
            }
        }
        
        let currentVolume = exerciseVolume(for: report)
        let previousVolume = exerciseVolume(for: previousReport)
        if currentVolume > 0 && currentVolume > previousVolume {
            return ExerciseStatusComparison(type: .volume,
                                            current: currentVolume,
                                            previous: previousVolume)
        }
        
        return nil
    }
    
    static func goalStatus(for report: ReportExerciseModel) -> ExerciseReportStatus {
        guard !report.targetSets.isEmpty else { return .complete }
        
        let actualSets = report.sets.sorted(by: { $0.index < $1.index })
        let targetSets = report.targetSets.sorted(by: { $0.index < $1.index })
        
        for (index, targetSet) in targetSets.enumerated() {
            guard index < actualSets.count else { return .goalMissed }
            if !isAchieved(target: targetSet.parameters, actual: actualSets[index].parameters) {
                return .goalMissed
            }
        }
        
        return .goalAchieved
    }
    
    static func isAchieved(target: [SetsParameter], actual: [SetsParameter]) -> Bool {
        for targetParameter in target {
            switch targetParameter {
            case .weight(let targetValue):
                guard let actualValue = weight(for: actual), actualValue >= targetValue else { return false }
            case .repeats(let targetValue):
                guard let actualValue = optionalReps(for: actual), actualValue >= targetValue else { return false }
            case .time(let targetValue):
                guard let actualValue = time(for: actual), actualValue >= targetValue else { return false }
            case .distance(let targetValue):
                guard let actualValue = distance(for: actual), actualValue >= targetValue else { return false }
            }
        }
        
        return true
    }
    
    static func exerciseVolume(for exercise: ReportExerciseModel) -> Float {
        exercise.sets.reduce(Float.zero) { $0 + volume(for: $1.parameters) }
    }
    
    static func volume(for parameters: [SetsParameter]) -> Float {
        let weight = weight(for: parameters) ?? 0
        let reps = optionalReps(for: parameters).map(Float.init) ?? 1
        return weight * reps
    }
    
    static func maxWeight(for exercise: ReportExerciseModel) -> Float? {
        exercise.sets.compactMap { weight(for: $0.parameters) }.max()
    }
    
    static func bestReps(at weight: Float, in exercise: ReportExerciseModel) -> Int {
        exercise.sets.reduce(0) { currentBest, set in
            guard let setWeight = Self.weight(for: set.parameters), setWeight == weight else {
                return currentBest
            }
            return max(currentBest, optionalReps(for: set.parameters) ?? 0)
        }
    }
    
    static func reps(for parameters: [SetsParameter]) -> Int {
        optionalReps(for: parameters) ?? 0
    }
    
    static func weight(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .weight(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    static func optionalReps(for parameters: [SetsParameter]) -> Int? {
        for parameter in parameters {
            if case .repeats(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    static func time(for parameters: [SetsParameter]) -> TimeInterval? {
        for parameter in parameters {
            if case .time(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    static func distance(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .distance(let value) = parameter {
                return value
            }
        }
        return nil
    }
}

extension ExerciseReportStatus {
    var isPersonalRecord: Bool {
        if case .personalRecord = self {
            return true
        }
        return false
    }
}
