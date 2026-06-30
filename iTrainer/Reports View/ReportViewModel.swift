//
//  ReportViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 19.09.2024.
//

import Foundation

class ReportViewModel: ObservableObject {
    
    struct ReportModel: Identifiable {
        var id = UUID()
        let primary: String
        let secondary: String
        let progress: Double
        let percentageProgress: String
    }
    
    struct SummaryCard: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let detail: String
        let progress: Double?
        let systemImage: String?
    }
    
    struct ReportExerciseSummary: Identifiable {
        let id: UUID
        let model: ReportExerciseModel
        let status: ReportExerciseStatus
    }
    
    enum ReportBannerStyle {
        case personalRecord
        case progress
        case goalsAchieved
        case goalsNotAchieved
        case workoutIncomplete
        case complete
        
        var title: String {
            switch self {
            case .personalRecord:
                "New Personal Record"
            case .progress:
                "Progress"
            case .goalsAchieved:
                "Goals Achieved"
            case .goalsNotAchieved:
                "Goals Not Achieved"
            case .workoutIncomplete:
                "Workout Incomplete"
            case .complete:
                "Workout Complete"
            }
        }
        
        var systemImage: String {
            switch self {
            case .personalRecord:
                "trophy.fill"
            case .progress:
                "chart.line.uptrend.xyaxis"
            case .goalsAchieved, .complete:
                "checkmark.circle.fill"
            case .goalsNotAchieved, .workoutIncomplete:
                "exclamationmark.triangle.fill"
            }
        }
    }
    
    // MARK: - properties
    
    @Published var isShowAlert = false
    
    @Published var reportDate: String = ""
    
    @Published var reportRangeTime: String = ""
    
    @Published var titleWorkout: String = ""
    
    @Published var titleWorkoutGroup: String = ""
    
    @Published var progressWorkout: Double = 1.0
    
    @Published var percentageProgressWorkout: String = "0%"
    
    @Published var workoutTime: String = "0:00"
    
    @Published var reportModels = [ReportModel]()
    
    @Published var reportExercises = [ReportExerciseModel]()
    
    @Published var summaryCards = [SummaryCard]()
    
    @Published var exerciseSummaries = [ReportExerciseSummary]()
    
    @Published var bannerStyle: ReportBannerStyle = .complete
    
    var errorMessage: String? = nil
    
    private var reportWorkout: ReportWorkoutModel
    
    // MARK: - Init
    
    init(report: ReportWorkoutModel) {
        self.reportWorkout = report
    }
    
    // MARK: - Private methods
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            guard let report = await dataManager.fetchReportWorkout(id: self.reportWorkout.id) else {
                if let complete = complete {
                    complete()
                }
                return
            }
            
            let startDate = report.startDate
            let endDate = report.endDate
            let titleWorkout = report.titleWorkout
            let titleWorkoutGroup = report.titleWorkoutGroup
            let targetExercisesCount = report.targetExercisesCount
            let reportExercises = report.exercises.map({ ReportExerciseModel(model: $0) })
                .sorted(by: { $0.index < $1.index })
            let metrics = createReportMetrics(exercises: reportExercises,
                                              targetExercisesCount: targetExercisesCount,
                                              startDate: startDate,
                                              endDate: endDate)
            let reportModels = createReportModels(from: metrics)
            let exerciseSummaries = reportExercises.map { exercise in
                ReportExerciseSummary(id: exercise.id,
                                      model: exercise,
                                      status: status(for: exercise))
            }
            
            await MainActor.run {
                if let startDate,
                    let endDate {
                    self.reportDate = startDate.formatted(date: .complete, time: .omitted)
                    self.reportRangeTime = "\(startDate.formatted(date: .omitted, time: .shortened)) - \(endDate.formatted(date: .omitted, time: .shortened))"
                    self.workoutTime = endDate.timeIntervalSince(startDate).timeForDisplay
                }
                
                self.titleWorkout = titleWorkout
                self.titleWorkoutGroup = titleWorkoutGroup
                self.reportExercises = reportExercises
                self.exerciseSummaries = exerciseSummaries
                self.reportModels = reportModels
                self.summaryCards = metrics.summaryCards
                self.bannerStyle = metrics.bannerStyle
                self.progressWorkout = metrics.exerciseProgress
                self.percentageProgressWorkout = metrics.exercisePercentText
                
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    private func createReportMetrics(exercises: [ReportExerciseModel],
                                     targetExercisesCount: Int,
                                     startDate: Date?,
                                     endDate: Date?) -> ReportMetrics {
        let completedExercisesCount = exercises.count
        let plannedExercisesCount = targetExercisesCount > 0 ? targetExercisesCount : completedExercisesCount
        let exerciseProgress = progressValue(actual: Double(completedExercisesCount), target: Double(plannedExercisesCount))
        let exercisePercentText = percentText(for: exerciseProgress)
        
        let actualVolume = exercises.reduce(Float.zero) { partialResult, exercise in
            partialResult + exercise.sets.reduce(Float.zero) { $0 + volume(for: $1.parameters) }
        }
        let actualReps = exercises.reduce(0) { partialResult, exercise in
            partialResult + exercise.sets.reduce(0) { $0 + reps(for: $1.parameters) }
        }
        let targetVolume = exercises.reduce(Float.zero) { partialResult, exercise in
            partialResult + exercise.targetSets.reduce(Float.zero) { $0 + volume(for: $1.parameters) }
        }
        let targetReps = exercises.reduce(0) { partialResult, exercise in
            partialResult + exercise.targetSets.reduce(0) { $0 + reps(for: $1.parameters) }
        }
        
        let density = densityValue(actualVolume: actualVolume,
                                   startDate: startDate,
                                   endDate: endDate)
        let volumeProgress = targetVolume > 0 ? progressValue(actual: Double(actualVolume), target: Double(targetVolume)) : nil
        let repsProgress = targetReps > 0 ? progressValue(actual: Double(actualReps), target: Double(targetReps)) : nil
        let hasStrengthGoals = targetVolume > 0 || targetReps > 0
        let missedGoals = exercises.contains { status(for: $0) == .goalMissed }
        
        let bannerStyle: ReportBannerStyle
        if targetExercisesCount > 0 && completedExercisesCount < targetExercisesCount {
            bannerStyle = .workoutIncomplete
        } else if hasStrengthGoals && missedGoals {
            bannerStyle = .goalsNotAchieved
        } else if hasStrengthGoals {
            bannerStyle = .goalsAchieved
        } else {
            bannerStyle = .complete
        }
        
        return ReportMetrics(exerciseProgress: exerciseProgress,
                             exercisePercentText: exercisePercentText,
                             summaryCards: [
                                SummaryCard(title: "Exercises",
                                            value: exercisePercentText,
                                            detail: "\(completedExercisesCount) / \(plannedExercisesCount)",
                                            progress: exerciseProgress,
                                            systemImage: nil),
                                SummaryCard(title: "Density",
                                            value: density.map { "\($0)" } ?? "-",
                                            detail: "kg/min",
                                            progress: nil,
                                            systemImage: "gauge.with.dots.needle.67percent"),
                                SummaryCard(title: "Volume Goal",
                                            value: volumeProgress.map { percentText(for: $0) } ?? "-",
                                            detail: targetVolume > 0 ? "\(Int(actualVolume)) / \(Int(targetVolume)) kg" : "\(Int(actualVolume)) kg",
                                            progress: volumeProgress,
                                            systemImage: nil),
                                SummaryCard(title: "Repetition Goal",
                                            value: repsProgress.map { percentText(for: $0) } ?? "-",
                                            detail: targetReps > 0 ? "\(actualReps) / \(targetReps) reps" : "\(actualReps) reps",
                                            progress: repsProgress,
                                            systemImage: nil)
                             ],
                             bannerStyle: bannerStyle,
                             actualVolume: actualVolume,
                             targetVolume: targetVolume,
                             actualReps: actualReps,
                             targetReps: targetReps)
    }
    
    private func createReportModels(from metrics: ReportMetrics) -> [ReportModel] {
        var result = [ReportModel]()
        
        if metrics.targetVolume > 0 {
            let progress = progressValue(actual: Double(metrics.actualVolume), target: Double(metrics.targetVolume))
            result.append(ReportModel(primary: "Weight",
                                      secondary: "\(Int(metrics.actualVolume)) from \(Int(metrics.targetVolume))",
                                      progress: progress,
                                      percentageProgress: percentText(for: progress)))
        }
        
        if metrics.targetReps > 0 {
            let progress = progressValue(actual: Double(metrics.actualReps), target: Double(metrics.targetReps))
            result.append(ReportModel(primary: "Repetitions",
                                      secondary: "\(metrics.actualReps) from \(metrics.targetReps)",
                                      progress: progress,
                                      percentageProgress: percentText(for: progress)))
        }
        
        return result
    }
    
    private func status(for exercise: ReportExerciseModel) -> ReportExerciseStatus {
        let targets = exercise.targetSets.filter { hasStrengthParameters($0.parameters) }
        guard !targets.isEmpty else { return .complete }
        
        let actualSets = exercise.sets.sorted(by: { $0.index < $1.index })
        for (index, target) in targets.enumerated() {
            guard index < actualSets.count else { return .goalMissed }
            if !isAchieved(target: target.parameters, actual: actualSets[index].parameters) {
                return .goalMissed
            }
        }
        
        return .goalAchieved
    }
    
    private func isAchieved(target: [SetsParameter], actual: [SetsParameter]) -> Bool {
        if let targetWeight = weight(for: target), targetWeight > 0 {
            guard let actualWeight = weight(for: actual), actualWeight >= targetWeight else { return false }
        }
        
        if let targetReps = optionalReps(for: target), targetReps > 0 {
            guard let actualReps = optionalReps(for: actual), actualReps >= targetReps else { return false }
        }
        
        return true
    }
    
    private func hasStrengthParameters(_ parameters: [SetsParameter]) -> Bool {
        weight(for: parameters) != nil || optionalReps(for: parameters) != nil
    }
    
    private func volume(for parameters: [SetsParameter]) -> Float {
        let weight = weight(for: parameters) ?? 0
        let reps = optionalReps(for: parameters).map(Float.init) ?? 1
        return weight * reps
    }
    
    private func reps(for parameters: [SetsParameter]) -> Int {
        optionalReps(for: parameters) ?? 0
    }
    
    private func weight(for parameters: [SetsParameter]) -> Float? {
        for parameter in parameters {
            if case .weight(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private func optionalReps(for parameters: [SetsParameter]) -> Int? {
        for parameter in parameters {
            if case .repeats(let value) = parameter {
                return value
            }
        }
        return nil
    }
    
    private func densityValue(actualVolume: Float, startDate: Date?, endDate: Date?) -> Int? {
        guard let startDate, let endDate else { return nil }
        
        let durationMinutes = endDate.timeIntervalSince(startDate) / 60.0
        guard durationMinutes > 0 else { return nil }
        
        return Int((Double(actualVolume) / durationMinutes).rounded())
    }
    
    private func progressValue(actual: Double, target: Double) -> Double {
        guard target > 0 else { return 1 }
        return min(max(actual / target, 0), 1)
    }
    
    private func percentText(for progress: Double) -> String {
        "\(Int((min(max(progress, 0), 1) * 100).rounded()))%"
    }
    
    // MARK: - Public methods
    
    func reloadData(complete: (()->())? = nil) {
        self.fetchItems(complete: complete)
    }
    
    func refreshData() {
        
    }
}

private struct ReportMetrics {
    let exerciseProgress: Double
    let exercisePercentText: String
    let summaryCards: [ReportViewModel.SummaryCard]
    let bannerStyle: ReportViewModel.ReportBannerStyle
    let actualVolume: Float
    let targetVolume: Float
    let actualReps: Int
    let targetReps: Int
}
