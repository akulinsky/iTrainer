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
        let colorProgress: Double?
        let systemImage: String?
    }
    
    struct ReportExerciseSummary: Identifiable {
        let id: UUID
        let model: ReportExerciseModel
        let status: ExerciseReportStatus
    }
    
    // MARK: - properties
    
    @Published var isShowAlert = false
    
    @Published var isLoading = true
    
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
    
    @Published var workoutStatus: WorkoutReportStatus = .workoutComplete
    
    var errorMessage: String? = nil
    
    private var hasLoadedReport = false
    
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
                await MainActor.run {
                    self.isLoading = false
                    if let complete = complete {
                        complete()
                    }
                }
                return
            }
            
            let reportWorkout = ReportWorkoutModel(model: report)
            let startDate = report.startDate
            let endDate = report.endDate
            let titleWorkout = report.titleWorkout
            let titleWorkoutGroup = report.titleWorkoutGroup
            let reportExercises = report.exercises.map({ ReportExerciseModel(model: $0) })
                .sorted(by: { $0.index < $1.index })
            var exerciseHistories = [UUID: [ReportExerciseModel]]()
            for exercise in reportExercises {
                exerciseHistories[exercise.id] = await dataManager.fetchReportExercises(typeId: exercise.typeId)
                    .map { ReportExerciseModel(model: $0) }
            }
            
            let exerciseSummaries = reportExercises.map { exercise in
                let status = ReportStatusService.calculateExerciseStatus(report: exercise,
                                                                         history: exerciseHistories[exercise.id] ?? [])
                return ReportExerciseSummary(id: exercise.id,
                                             model: exercise,
                                             status: status)
            }
            let exerciseStatuses = exerciseSummaries.map(\.status)
            let workoutStatus = ReportStatusService.calculateWorkoutStatus(report: reportWorkout,
                                                                           exercises: reportExercises,
                                                                           exerciseStatuses: exerciseStatuses)
            let metrics = createReportMetrics(report: reportWorkout,
                                              exercises: reportExercises,
                                              workoutStatus: workoutStatus,
                                              startDate: startDate,
                                              endDate: endDate)
            let reportModels = createReportModels(from: metrics)
            
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
                self.workoutStatus = workoutStatus
                self.progressWorkout = metrics.exerciseProgress
                self.percentageProgressWorkout = metrics.exercisePercentText
                self.hasLoadedReport = true
                self.isLoading = false
                
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    private func createReportMetrics(report: ReportWorkoutModel,
                                     exercises: [ReportExerciseModel],
                                     workoutStatus: WorkoutReportStatus,
                                     startDate: Date?,
                                     endDate: Date?) -> ReportMetrics {
        let completedExercisesCount = exercises.filter { !$0.sets.isEmpty }.count
        let plannedExercisesCount = report.targetExercisesCount > 0 ? report.targetExercisesCount : completedExercisesCount
        let exerciseProgress = progressValue(actual: Double(completedExercisesCount), target: Double(plannedExercisesCount))
        let exercisePercentText = percentText(for: exerciseProgress)
        let actualVolume = ReportStatusService.totalVolume(for: exercises)
        let actualReps = ReportStatusService.totalReps(for: exercises)
        let targetVolume = ReportStatusService.targetVolume(for: exercises)
        let targetReps = ReportStatusService.targetReps(for: exercises)
        let density = densityValue(actualVolume: actualVolume,
                                   startDate: startDate,
                                   endDate: endDate)
        let rawVolumeProgress = targetVolume > 0 ? rawProgressValue(actual: Double(actualVolume), target: Double(targetVolume)) : nil
        let volumeProgress = rawVolumeProgress.map(cappedProgressValue)
        let rawRepsProgress = targetReps > 0 ? rawProgressValue(actual: Double(actualReps), target: Double(targetReps)) : nil
        let repsProgress = rawRepsProgress.map(cappedProgressValue)
        
        return ReportMetrics(exerciseProgress: exerciseProgress,
                             exercisePercentText: exercisePercentText,
                             summaryCards: [
                                SummaryCard(title: "Exercises",
                                            value: exercisePercentText,
                                            detail: "\(completedExercisesCount) / \(plannedExercisesCount)",
                                            progress: exerciseProgress,
                                            colorProgress: exerciseProgress,
                                            systemImage: nil),
                                SummaryCard(title: "Density",
                                            value: density.map { "\($0)" } ?? "-",
                                            detail: "kg/min",
                                            progress: nil,
                                            colorProgress: nil,
                                            systemImage: "gauge.with.dots.needle.67percent"),
                                SummaryCard(title: "Volume Goal",
                                            value: rawVolumeProgress.map { percentText(for: $0, isCapped: false) } ?? "-",
                                            detail: targetVolume > 0 ? "\(Int(actualVolume)) / \(Int(targetVolume)) kg" : "\(Int(actualVolume)) kg",
                                            progress: volumeProgress,
                                            colorProgress: rawVolumeProgress,
                                            systemImage: nil),
                                SummaryCard(title: "Repetition Goal",
                                            value: rawRepsProgress.map { percentText(for: $0, isCapped: false) } ?? "-",
                                            detail: targetReps > 0 ? "\(actualReps) / \(targetReps) reps" : "\(actualReps) reps",
                                            progress: repsProgress,
                                            colorProgress: rawRepsProgress,
                                            systemImage: nil)
                             ],
                             workoutStatus: workoutStatus,
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
    
    private func densityValue(actualVolume: Float, startDate: Date?, endDate: Date?) -> Int? {
        guard let startDate, let endDate else { return nil }
        
        let durationMinutes = endDate.timeIntervalSince(startDate) / 60.0
        guard durationMinutes > 0 else { return nil }
        
        return Int((Double(actualVolume) / durationMinutes).rounded())
    }
    
    private func progressValue(actual: Double, target: Double) -> Double {
        cappedProgressValue(rawProgressValue(actual: actual, target: target))
    }
    
    private func rawProgressValue(actual: Double, target: Double) -> Double {
        guard target > 0 else { return 1 }
        return max(actual / target, 0)
    }
    
    private func cappedProgressValue(_ progress: Double) -> Double {
        min(max(progress, 0), 1)
    }
    
    private func percentText(for progress: Double, isCapped: Bool = true) -> String {
        let displayProgress = isCapped ? cappedProgressValue(progress) : max(progress, 0)
        return "\(Int((displayProgress * 100).rounded()))%"
    }
    
    // MARK: - Public methods
    
    func reloadData(force: Bool = false, complete: (()->())? = nil) {
        guard force || !hasLoadedReport else {
            complete?()
            return
        }
        
        isLoading = true
        self.fetchItems(complete: complete)
    }
    
    func refreshData() {
        
    }
    
    func deleteReport(complete: (() -> Void)? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeReportWorkout(with: self.reportWorkout.id)
            await MainActor.run {
                complete?()
            }
        }
    }
}

private struct ReportMetrics {
    let exerciseProgress: Double
    let exercisePercentText: String
    let summaryCards: [ReportViewModel.SummaryCard]
    let workoutStatus: WorkoutReportStatus
    let actualVolume: Float
    let targetVolume: Float
    let actualReps: Int
    let targetReps: Int
}
