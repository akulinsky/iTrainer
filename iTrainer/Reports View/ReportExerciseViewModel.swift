//
//  ReportExerciseViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.09.2024.
//

import Foundation
import SwiftUI

final class ReportExerciseViewModel: ObservableObject {
    struct SetComparisonRow: Identifiable {
        enum State {
            case achieved
            case missed
            case recorded
            case extra
        }
        
        let id = UUID()
        let title: String
        let target: String
        let result: String
        let state: State
    }
    
    struct SummaryCard: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let systemImage: String
    }
    
    struct StatusMetric: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let color: Color
    }
    
    struct VolumeBreakdownRow: Identifiable {
        let id = UUID()
        let text: String
        let deltaText: String?
        
        var showsImprovementDot: Bool {
            deltaText != nil
        }
    }
    
    @Published var title: String
    @Published var workoutContext: String = ""
    @Published var reportDate: String = ""
    @Published var status: ExerciseReportStatus = .complete
    @Published var statusMetrics = [StatusMetric]()
    @Published var setRows = [SetComparisonRow]()
    @Published var summaryCards = [SummaryCard]()
    @Published var volumeBreakdown = [VolumeBreakdownRow]()
    @Published var isShowAlert = false
    
    var errorMessage: String? = nil
    var reportExercise: ReportExerciseModel
    
    init(reportExercise: ReportExerciseModel) {
        self.reportExercise = reportExercise
        self.title = reportExercise.titleExercise
        self.workoutContext = Self.contextText(for: reportExercise)
        self.reportDate = Self.dateText(for: reportExercise.date)
        rebuildPresentation(history: [])
    }
    
    func reloadData(complete: (() -> Void)? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let history = await dataManager.fetchReportExercises(typeId: reportExercise.typeId)
                .map { ReportExerciseModel(model: $0) }
            
            await MainActor.run {
                self.rebuildPresentation(history: history)
                complete?()
            }
        }
    }
    
    private func rebuildPresentation(history: [ReportExerciseModel]) {
        title = reportExercise.titleExercise
        workoutContext = Self.contextText(for: reportExercise)
        reportDate = Self.dateText(for: reportExercise.date)
        let statusResult = ReportStatusService.calculateExerciseStatusResult(report: reportExercise, history: history)
        status = statusResult.status
        statusMetrics = makeStatusMetrics(statusResult: statusResult)
        setRows = makeSetRows()
        summaryCards = makeSummaryCards()
        volumeBreakdown = makeVolumeBreakdown(statusResult: statusResult, history: history)
    }
    
    private func makeStatusMetrics(statusResult: ExerciseStatusResult) -> [StatusMetric] {
        switch statusResult.status {
        case .personalRecord:
            return comparisonMetrics(statusResult.comparison, previousTitle: "Previous best", improvementColor: AppColor.restAmber)
        case .progress:
            return comparisonMetrics(statusResult.comparison, previousTitle: "Previous", improvementColor: AppColor.progressGreen)
        case .goalAchieved:
            return [
                StatusMetric(title: "Goal", value: "Achieved", color: AppColor.progressGreen),
                StatusMetric(title: "Targets", value: "\(achievedTargetCount()) / \(reportExercise.targetSets.count)", color: AppColor.textPrimary)
            ]
        case .goalMissed:
            return [
                StatusMetric(title: "Goal", value: "Missed", color: AppColor.progressAmber),
                StatusMetric(title: "Targets", value: "\(achievedTargetCount()) / \(reportExercise.targetSets.count)", color: AppColor.textPrimary)
            ]
        case .complete:
            return [
                StatusMetric(title: "Recorded", value: "Complete", color: AppColor.progressGreen),
                StatusMetric(title: "Sets", value: "\(reportExercise.sets.count)", color: AppColor.textPrimary)
            ]
        }
    }
    
    private func comparisonMetrics(_ comparison: ExerciseStatusComparison?,
                                   previousTitle: String,
                                   improvementColor: Color) -> [StatusMetric] {
        guard let comparison else { return [] }
        
        return [
            StatusMetric(title: "Metric", value: comparison.type.displayTitle, color: AppColor.textPrimary),
            StatusMetric(title: "Current", value: formattedCurrentValue(for: comparison), color: AppColor.textPrimary),
            StatusMetric(title: previousTitle, value: formattedPreviousValue(for: comparison), color: AppColor.textPrimary),
            StatusMetric(title: "Improvement", value: formattedImprovementValue(for: comparison), color: improvementColor)
        ]
    }
    
    private func makeSetRows() -> [SetComparisonRow] {
        let targetSets = reportExercise.targetSets.sorted { $0.index < $1.index }
        let actualSets = reportExercise.sets.sorted { $0.index < $1.index }
        
        if targetSets.isEmpty {
            return actualSets.enumerated().map { index, actual in
                SetComparisonRow(title: "Set \(index + 1)",
                                 target: "-",
                                 result: parametersText(actual.parameters),
                                 state: .recorded)
            }
        }
        
        let totalRows = max(targetSets.count, actualSets.count)
        return (0..<totalRows).map { index in
            let target = index < targetSets.count ? targetSets[index] : nil
            let actual = index < actualSets.count ? actualSets[index] : nil
            let state: SetComparisonRow.State
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
            
            return SetComparisonRow(title: title,
                                    target: target.map { parametersText($0.parameters) } ?? "-",
                                    result: actual.map { parametersText($0.parameters) } ?? "-",
                                    state: state)
        }
    }
    
    private func makeSummaryCards() -> [SummaryCard] {
        [
            SummaryCard(title: "Volume", value: formattedKilograms(exerciseVolume(reportExercise)), systemImage: "dumbbell.fill"),
            SummaryCard(title: "Repetitions", value: "\(totalReps(reportExercise))", systemImage: "chart.bar.fill"),
            SummaryCard(title: "Rest Time", value: reportExercise.restTime?.timeForDisplay ?? "-", systemImage: "clock")
        ]
    }
    
    private func makeVolumeBreakdown(statusResult: ExerciseStatusResult, history: [ReportExerciseModel]) -> [VolumeBreakdownRow] {
        let baselineVolumes = volumeBreakdownBaseline(statusResult: statusResult, history: history)
            .map { setVolumes(for: $0) }
        
        return reportExercise.sets
            .sorted { $0.index < $1.index }
            .enumerated()
            .compactMap { index, set in
                guard let weight = weight(for: set.parameters),
                      let reps = reps(for: set.parameters),
                      let volume = setBreakdownVolume(set.parameters) else {
                    return nil
                }
                let previousVolume = baselineVolumes.flatMap { index < $0.count ? $0[index] : nil }
                let delta = previousVolume.map { volume - $0 } ?? (baselineVolumes == nil ? nil : volume)
                let deltaText = delta.flatMap { $0 > 0 ? "+\(formattedKilograms($0))" : nil }
                return VolumeBreakdownRow(text: "\(formattedNumber(weight)) x \(reps) = \(formattedKilograms(volume))",
                                          deltaText: deltaText)
            }
    }
    
    private func volumeBreakdownBaseline(statusResult: ExerciseStatusResult,
                                         history: [ReportExerciseModel]) -> ReportExerciseModel? {
        guard statusResult.comparison?.type == .volume else { return nil }
        let previousReports = previousReports(in: history)
        
        switch statusResult.status {
        case .personalRecord:
            return previousReports.max(by: { exerciseVolume($0) < exerciseVolume($1) })
        case .progress:
            return previousReports
                .filter { $0.exerciseId == reportExercise.exerciseId }
                .max(by: { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) })
        case .goalAchieved, .goalMissed, .complete:
            return nil
        }
    }
    
    private func previousReports(in history: [ReportExerciseModel]) -> [ReportExerciseModel] {
        history.filter { item in
            guard item.id != reportExercise.id else { return false }
            guard item.typeId == reportExercise.typeId else { return false }
            guard let reportDate = reportExercise.date else { return true }
            guard let itemDate = item.date else { return false }
            return itemDate < reportDate
        }
    }
    
    private func setVolumes(for exercise: ReportExerciseModel) -> [Float] {
        exercise.sets
            .sorted { $0.index < $1.index }
            .compactMap { setBreakdownVolume($0.parameters) }
    }
    
    private func setBreakdownVolume(_ parameters: [SetsParameter]) -> Float? {
        guard let weight = weight(for: parameters), let reps = reps(for: parameters) else {
            return nil
        }
        return weight * Float(reps)
    }
    
    private func achievedTargetCount() -> Int {
        let targetSets = reportExercise.targetSets.sorted { $0.index < $1.index }
        let actualSets = reportExercise.sets.sorted { $0.index < $1.index }
        
        return targetSets.enumerated().reduce(0) { count, item in
            let (index, target) = item
            guard index < actualSets.count else { return count }
            return isAchieved(target: target.parameters, actual: actualSets[index].parameters) ? count + 1 : count
        }
    }
    
    private func value(for type: PersonalRecordType, in exercise: ReportExerciseModel) -> Float {
        switch type {
        case .weight:
            return maxWeight(exercise) ?? 0
        case .repetitions:
            guard let bestWeight = maxWeight(exercise) else { return 0 }
            return Float(bestReps(at: bestWeight, in: exercise))
        case .volume:
            return exerciseVolume(exercise)
        }
    }
    
    private func formattedCurrentValue(for comparison: ExerciseStatusComparison) -> String {
        formattedComparisonValue(comparison.current, for: comparison)
    }
    
    private func formattedPreviousValue(for comparison: ExerciseStatusComparison) -> String {
        formattedComparisonValue(comparison.previous, for: comparison)
    }
    
    private func formattedImprovementValue(for comparison: ExerciseStatusComparison) -> String {
        switch comparison.type {
        case .repetitions:
            return "+\(Int(comparison.improvement)) reps"
        case .weight, .volume:
            return "+\(formatted(value: comparison.improvement, for: comparison.type))"
        }
    }
    
    private func formattedComparisonValue(_ value: Float, for comparison: ExerciseStatusComparison) -> String {
        if comparison.type == .repetitions, let contextWeight = comparison.contextWeight {
            return "\(formattedNumber(contextWeight)) kg x \(Int(value))"
        }
        return formatted(value: value, for: comparison.type)
    }
    
    private func formatted(value: Float, for type: PersonalRecordType) -> String {
        switch type {
        case .weight:
            return formattedKilograms(value)
        case .repetitions:
            return "\(Int(value))"
        case .volume:
            return formattedKilograms(value)
        }
    }
    
    private func parametersText(_ parameters: [SetsParameter]) -> String {
        let weightValue = weight(for: parameters).map { "\(formattedNumber($0)) kg" }
        let repsValue = reps(for: parameters).map { "\($0)" }
        let distanceValue = distance(for: parameters).map { $0.distanceForDisplay }
        let timeValue = time(for: parameters).map { $0.timeForDisplay }
        
        if let weightValue, let repsValue {
            return "\(weightValue) x \(repsValue)"
        }
        
        return [weightValue, repsValue, distanceValue, timeValue]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
    
    private func isAchieved(target: [SetsParameter], actual: [SetsParameter]) -> Bool {
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
    
    private func exerciseVolume(_ exercise: ReportExerciseModel) -> Float {
        exercise.sets.reduce(Float.zero) { $0 + setVolume($1.parameters) }
    }
    
    private func setVolume(_ parameters: [SetsParameter]) -> Float {
        let weight = weight(for: parameters) ?? 0
        let reps = reps(for: parameters).map(Float.init) ?? 1
        return weight * reps
    }
    
    private func totalReps(_ exercise: ReportExerciseModel) -> Int {
        exercise.sets.reduce(0) { $0 + (reps(for: $1.parameters) ?? 0) }
    }
    
    private func maxWeight(_ exercise: ReportExerciseModel) -> Float? {
        exercise.sets.compactMap { weight(for: $0.parameters) }.max()
    }
    
    private func bestReps(at weight: Float, in exercise: ReportExerciseModel) -> Int {
        exercise.sets.reduce(0) { currentBest, set in
            guard let setWeight = self.weight(for: set.parameters), setWeight == weight else {
                return currentBest
            }
            return max(currentBest, reps(for: set.parameters) ?? 0)
        }
    }
    
    private func weight(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .weight(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private func reps(for parameters: [SetsParameter]) -> Int? {
        for parameter in parameters {
            if case .repeats(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private func distance(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .distance(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private func time(for parameters: [SetsParameter]) -> TimeInterval? {
        for parameter in parameters {
            if case .time(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private func formattedKilograms(_ value: Float) -> String {
        "\(formattedNumber(value)) kg"
    }
    
    private func formattedNumber(_ value: Float) -> String {
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
    
    private static func dateText(for date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(date: .complete, time: .omitted)
    }
}

private extension PersonalRecordType {
    var displayTitle: String {
        switch self {
        case .weight:
            "Weight"
        case .repetitions:
            "Repetitions"
        case .volume:
            "Volume"
        }
    }
}
