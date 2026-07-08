//
//  ReportStatusService.swift
//  iTrainer
//
//  Created by OpenAI on 30.06.2026.
//

import Foundation

enum PersonalRecordType: Hashable, Sendable {
    case weight
    case repetitions
    case volume
    case time
    case distance
    case pace
}

struct ExerciseStatusComparison: Hashable, Sendable {
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
        if type.isLowerValueBetter {
            return max(previous - current, 0)
        }
        return max(current - previous, 0)
    }
}

struct ExerciseStatusResult: Hashable, Sendable {
    let status: ExerciseReportStatus
    let comparison: ExerciseStatusComparison?
}

enum ExerciseReportStatus: Hashable, Sendable {
    case personalRecord(type: PersonalRecordType)
    case progress
    case goalAchieved
    case goalMissed
    case complete
}

enum WorkoutReportStatus: Hashable, Sendable {
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
            $0.exerciseId == report.exerciseId
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
            guard trackingType(for: exercise) == .weightedReps else { return partialResult }
            return partialResult + exerciseVolume(for: exercise)
        }
    }
    
    static func totalReps(for exercises: [ReportExerciseModel]) -> Int {
        exercises.reduce(0) { partialResult, exercise in
            guard trackingType(for: exercise)?.usesRepetitions == true else { return partialResult }
            return partialResult + exercise.sets.reduce(0) { $0 + reps(for: $1.parameters) }
        }
    }
    
    static func targetVolume(for exercises: [ReportExerciseModel]) -> Float {
        exercises.reduce(Float.zero) { partialResult, exercise in
            guard trackingType(for: exercise) == .weightedReps else { return partialResult }
            return partialResult + exercise.targetSets.reduce(Float.zero) { $0 + volume(for: $1.parameters) }
        }
    }
    
    static func targetReps(for exercises: [ReportExerciseModel]) -> Int {
        exercises.reduce(0) { partialResult, exercise in
            guard trackingType(for: exercise)?.usesRepetitions == true else { return partialResult }
            return partialResult + exercise.targetSets.reduce(0) { $0 + reps(for: $1.parameters) }
        }
    }
    
    static func totalTimedDuration(for exercises: [ReportExerciseModel]) -> TimeInterval {
        exercises.reduce(TimeInterval.zero) { partialResult, exercise in
            guard trackingType(for: exercise) == .timed else { return partialResult }
            return partialResult + totalTime(for: exercise)
        }
    }
    
    static func targetTimedDuration(for exercises: [ReportExerciseModel]) -> TimeInterval {
        exercises.reduce(TimeInterval.zero) { partialResult, exercise in
            guard trackingType(for: exercise) == .timed else { return partialResult }
            return partialResult + exercise.targetSets.reduce(TimeInterval.zero) { $0 + (time(for: $1.parameters) ?? 0) }
        }
    }
    
    static func totalDistance(for exercises: [ReportExerciseModel]) -> Float {
        exercises.reduce(Float.zero) { partialResult, exercise in
            guard trackingType(for: exercise)?.usesDistance == true else { return partialResult }
            return partialResult + totalDistance(for: exercise)
        }
    }
    
    static func targetDistance(for exercises: [ReportExerciseModel]) -> Float {
        exercises.reduce(Float.zero) { partialResult, exercise in
            guard trackingType(for: exercise)?.usesDistance == true else { return partialResult }
            return partialResult + exercise.targetSets.reduce(Float.zero) { $0 + (distance(for: $1.parameters) ?? 0) }
        }
    }
    
    static func hasGoals(in exercises: [ReportExerciseModel]) -> Bool {
        exercises.contains { !$0.targetSets.isEmpty }
    }
    
    static func exerciseVolumeValue(for exercise: ReportExerciseModel) -> Float {
        exerciseVolume(for: exercise)
    }
    
    static func maxWeightValue(for exercise: ReportExerciseModel) -> Float? {
        maxWeight(for: exercise)
    }
    
    static func bestRepsValue(at weight: Float, in exercise: ReportExerciseModel) -> Int {
        bestReps(at: weight, in: exercise)
    }
    
    static func weightValue(for parameters: [SetsParameter]) -> Float? {
        weight(for: parameters)
    }
    
    static func repsValue(for parameters: [SetsParameter]) -> Int? {
        optionalReps(for: parameters)
    }
    
    static func timeValue(for parameters: [SetsParameter]) -> TimeInterval? {
        time(for: parameters)
    }
    
    static func distanceValue(for parameters: [SetsParameter]) -> Float? {
        distance(for: parameters)
    }
    
    static func trackingTypeValue(for exercise: ReportExerciseModel) -> ExerciseTrackingType? {
        trackingType(for: exercise)
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
        
        switch trackingType(for: report) {
        case .weightedReps:
            return weightedRepsPersonalRecordComparison(for: report, comparedTo: previousReports)
        case .repsOnly:
            return repsOnlyPersonalRecordComparison(for: report, comparedTo: previousReports)
        case .timed:
            return timedPersonalRecordComparison(for: report, comparedTo: previousReports)
        case .distance:
            return distancePersonalRecordComparison(for: report, comparedTo: previousReports)
        case .distanceTime:
            return distanceTimePersonalRecordComparison(for: report, comparedTo: previousReports)
        case nil:
            return nil
        }
    }
    
    static func weightedRepsPersonalRecordComparison(for report: ReportExerciseModel,
                                                     comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
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
        } else {
            let currentReps = maxRepsWithoutWeight(for: report)
            let previousReps = previousReports.map(maxRepsWithoutWeight(for:)).max() ?? 0
            if currentReps > 0 && currentReps > previousReps {
                return ExerciseStatusComparison(type: .repetitions,
                                                current: Float(currentReps),
                                                previous: Float(previousReps))
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
    
    static func repsOnlyPersonalRecordComparison(for report: ReportExerciseModel,
                                                 comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
        let currentReps = totalReps(for: report)
        let previousReps = previousReports.map(totalReps(for:)).max() ?? 0
        guard currentReps > 0, currentReps > previousReps else { return nil }
        return ExerciseStatusComparison(type: .repetitions,
                                        current: Float(currentReps),
                                        previous: Float(previousReps))
    }
    
    static func timedPersonalRecordComparison(for report: ReportExerciseModel,
                                              comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
        let currentTime = totalTime(for: report)
        let previousTime = previousReports.map(totalTime(for:)).max() ?? 0
        guard currentTime > 0, currentTime > previousTime else { return nil }
        return ExerciseStatusComparison(type: .time,
                                        current: Float(currentTime),
                                        previous: Float(previousTime))
    }
    
    static func distancePersonalRecordComparison(for report: ReportExerciseModel,
                                                 comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
        let currentDistance = totalDistance(for: report)
        let previousDistance = previousReports.map(totalDistance(for:)).max() ?? 0
        guard currentDistance > 0, currentDistance > previousDistance else { return nil }
        return ExerciseStatusComparison(type: .distance,
                                        current: currentDistance,
                                        previous: previousDistance)
    }
    
    static func distanceTimePersonalRecordComparison(for report: ReportExerciseModel,
                                                     comparedTo previousReports: [ReportExerciseModel]) -> ExerciseStatusComparison? {
        if let distanceComparison = distancePersonalRecordComparison(for: report, comparedTo: previousReports) {
            return distanceComparison
        }
        
        guard let currentPace = pace(for: report),
              let previousBestPace = previousReports.compactMap(pace(for:)).min(),
              currentPace < previousBestPace else {
            return nil
        }
        return ExerciseStatusComparison(type: .pace,
                                        current: currentPace,
                                        previous: previousBestPace)
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
        
        switch trackingType(for: report) {
        case .weightedReps:
            return weightedRepsProgressComparison(for: report, comparedTo: previousReport)
        case .repsOnly:
            return repsOnlyProgressComparison(for: report, comparedTo: previousReport)
        case .timed:
            return timedProgressComparison(for: report, comparedTo: previousReport)
        case .distance:
            return distanceProgressComparison(for: report, comparedTo: previousReport)
        case .distanceTime:
            return distanceTimeProgressComparison(for: report, comparedTo: previousReport)
        case nil:
            return nil
        }
    }
    
    static func weightedRepsProgressComparison(for report: ReportExerciseModel,
                                               comparedTo previousReport: ReportExerciseModel) -> ExerciseStatusComparison? {
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
        } else if maxWeight(for: report) == nil {
            let currentReps = maxRepsWithoutWeight(for: report)
            let previousReps = maxRepsWithoutWeight(for: previousReport)
            if currentReps > 0 && currentReps > previousReps {
                return ExerciseStatusComparison(type: .repetitions,
                                                current: Float(currentReps),
                                                previous: Float(previousReps))
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
    
    static func repsOnlyProgressComparison(for report: ReportExerciseModel,
                                           comparedTo previousReport: ReportExerciseModel) -> ExerciseStatusComparison? {
        let currentReps = totalReps(for: report)
        let previousReps = totalReps(for: previousReport)
        guard currentReps > 0, currentReps > previousReps else { return nil }
        return ExerciseStatusComparison(type: .repetitions,
                                        current: Float(currentReps),
                                        previous: Float(previousReps))
    }
    
    static func timedProgressComparison(for report: ReportExerciseModel,
                                        comparedTo previousReport: ReportExerciseModel) -> ExerciseStatusComparison? {
        let currentTime = totalTime(for: report)
        let previousTime = totalTime(for: previousReport)
        guard currentTime > 0, currentTime > previousTime else { return nil }
        return ExerciseStatusComparison(type: .time,
                                        current: Float(currentTime),
                                        previous: Float(previousTime))
    }
    
    static func distanceProgressComparison(for report: ReportExerciseModel,
                                           comparedTo previousReport: ReportExerciseModel) -> ExerciseStatusComparison? {
        let currentDistance = totalDistance(for: report)
        let previousDistance = totalDistance(for: previousReport)
        guard currentDistance > 0, currentDistance > previousDistance else { return nil }
        return ExerciseStatusComparison(type: .distance,
                                        current: currentDistance,
                                        previous: previousDistance)
    }
    
    static func distanceTimeProgressComparison(for report: ReportExerciseModel,
                                               comparedTo previousReport: ReportExerciseModel) -> ExerciseStatusComparison? {
        if let distanceComparison = distanceProgressComparison(for: report, comparedTo: previousReport) {
            return distanceComparison
        }
        
        guard let currentPace = pace(for: report),
              let previousPace = pace(for: previousReport),
              currentPace < previousPace else {
            return nil
        }
        return ExerciseStatusComparison(type: .pace,
                                        current: currentPace,
                                        previous: previousPace)
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
        if distance(for: target) != nil, time(for: target) != nil {
            guard let targetDistance = distance(for: target),
                  let actualDistance = distance(for: actual),
                  actualDistance >= targetDistance,
                  let targetTime = time(for: target),
                  let actualTime = time(for: actual),
                  actualTime <= targetTime else {
                return false
            }
            return true
        }
        
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
    
    static func totalReps(for exercise: ReportExerciseModel) -> Int {
        exercise.sets.reduce(0) { $0 + reps(for: $1.parameters) }
    }
    
    static func totalTime(for exercise: ReportExerciseModel) -> TimeInterval {
        exercise.sets.reduce(TimeInterval.zero) { $0 + (time(for: $1.parameters) ?? 0) }
    }
    
    static func totalDistance(for exercise: ReportExerciseModel) -> Float {
        exercise.sets.reduce(Float.zero) { $0 + (distance(for: $1.parameters) ?? 0) }
    }
    
    static func pace(for exercise: ReportExerciseModel) -> Float? {
        let distance = totalDistance(for: exercise)
        let time = totalTime(for: exercise)
        guard distance > 0, time > 0 else { return nil }
        return Float(time) / distance
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
    
    static func maxRepsWithoutWeight(for exercise: ReportExerciseModel) -> Int {
        exercise.sets.reduce(0) { currentBest, set in
            guard weight(for: set.parameters) == nil else {
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
    
    static func trackingType(for exercise: ReportExerciseModel) -> ExerciseTrackingType? {
        if let trackingType = ExerciseTrackingType(typeId: exercise.typeId) {
            return trackingType
        }
        
        if let parameters = exercise.targetSets.first?.parameters ?? exercise.sets.first?.parameters {
            return ExerciseTrackingType(parameters: parameters)
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

extension PersonalRecordType {
    var isLowerValueBetter: Bool {
        self == .pace
    }
}
