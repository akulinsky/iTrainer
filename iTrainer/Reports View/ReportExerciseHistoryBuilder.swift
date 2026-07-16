//
//  ReportExerciseHistoryBuilder.swift
//  iTrainer
//
//  Created by Codex on 08.07.2026.
//

import Foundation

enum ReportExerciseHistoryBuilder {
    static func previousLocalReports(in history: [ReportExerciseModel], current: ReportExerciseModel) -> [ReportExerciseModel] {
        history
            .filter { item in
                guard item.id != current.id else { return false }
                guard item.exerciseId == current.exerciseId else { return false }
                
                if let reportDate = current.date {
                    guard let itemDate = item.date else { return false }
                    return itemDate < reportDate
                }
                
                return true
            }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
    
    static func historyGroups(from reports: [ReportExerciseModel],
                              unitFormatter: UnitFormatter = UnitFormatter(settings: AppSettings.shared)) -> [ReportExerciseViewModel.HistoryGroup] {
        reports.map { item in
            ReportExerciseViewModel.HistoryGroup(id: item.id,
                                                 dateText: shortDateText(for: item.date),
                                                 contextText: contextText(for: item),
                                                 rows: makeSetRows(for: item, unitFormatter: unitFormatter))
        }
    }
    
    private static func makeSetRows(for exercise: ReportExerciseModel,
                                    unitFormatter: UnitFormatter) -> [ReportExerciseViewModel.SetComparisonRow] {
        let targetSets = exercise.targetSets.sorted { $0.index < $1.index }
        let actualSets = exercise.sets.sorted { $0.index < $1.index }
        
        if targetSets.isEmpty {
            return actualSets.enumerated().map { index, actual in
                ReportExerciseViewModel.SetComparisonRow(title: "Set \(index + 1)",
                                                         target: "-",
                                                         result: parametersText(actual.parameters, unitFormatter: unitFormatter),
                                                         state: .recorded)
            }
        }
        
        let totalRows = max(targetSets.count, actualSets.count)
        return (0..<totalRows).map { index in
            let target = index < targetSets.count ? targetSets[index] : nil
            let actual = index < actualSets.count ? actualSets[index] : nil
            let state: ReportExerciseViewModel.SetComparisonRow.State
            let title: String
            
            if let target, let actual {
                state = isAchieved(target: target.parameters, actual: actual.parameters) ? .achieved : .missed
                title = "Set \(index + 1)"
            } else if target != nil {
                state = .missed
                title = "Set \(index + 1)"
            } else {
                state = .extra
                title = "Extra set"
            }
            
            return ReportExerciseViewModel.SetComparisonRow(title: title,
                                                            target: target.map { parametersText($0.parameters, unitFormatter: unitFormatter) } ?? "-",
                                                            result: actual.map { parametersText($0.parameters, unitFormatter: unitFormatter) } ?? "-",
                                                            state: state)
        }
    }
    
    private static func parametersText(_ parameters: [SetsParameter], unitFormatter: UnitFormatter) -> String {
        let weightValue = weight(for: parameters).map { unitFormatter.weightTextWithUnit(kilograms: $0) }
        let repsValue = reps(for: parameters).map { "\($0)" }
        let distanceValue = distance(for: parameters).map { unitFormatter.distanceText(meters: $0) }
        let timeValue = time(for: parameters).map { $0.timeForDisplay }
        
        if let weightValue, let repsValue {
            return "\(weightValue) x \(repsValue)"
        }
        
        return [weightValue, repsValue, distanceValue, timeValue]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
    
    private static func isAchieved(target: [SetsParameter], actual: [SetsParameter]) -> Bool {
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
                guard let actualValue = reps(for: actual), actualValue >= targetValue else { return false }
            case .time(let targetValue):
                guard let actualValue = time(for: actual), actualValue >= targetValue else { return false }
            case .distance(let targetValue):
                guard let actualValue = distance(for: actual), actualValue >= targetValue else { return false }
            }
        }
        return true
    }
    
    private static func weight(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .weight(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private static func reps(for parameters: [SetsParameter]) -> Int? {
        for parameter in parameters {
            if case .repeats(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private static func distance(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .distance(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private static func time(for parameters: [SetsParameter]) -> TimeInterval? {
        for parameter in parameters {
            if case .time(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private static func formattedNumber(_ value: Float) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
    
    private static func contextText(for exercise: ReportExerciseModel) -> String {
        [exercise.titleWorkout, exercise.titleWorkoutGroup]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }
    
    private static func shortDateText(for date: Date?) -> String {
        guard let date else { return "-" }
        return date.formatted(date: .complete, time: .omitted)
    }
}
