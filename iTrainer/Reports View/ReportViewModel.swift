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
    
    // MARK: - properties
    
//    @Published var reports = [ReportWorkoutModel]()
    
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
            let exercisesCount = report.exercises.count
            let reportModels = createReportModels(exersices: report.exercises)
            let reportExercises = report.exercises.map({ ReportExerciseModel(model: $0) })
                .sorted(by: { $0.index < $1.index })
            
            await MainActor.run {
                
                if let startDate,
                    let endDate {
                    self.reportDate = startDate.formatted(date: .complete, time: .omitted)
                    self.reportRangeTime = "\(startDate.formatted(date: .omitted, time: .shortened)) - \(endDate.formatted(date: .omitted, time: .shortened))"
                    self.workoutTime = "\((endDate.timeIntervalSinceNow - startDate.timeIntervalSinceNow).timeForDisplay)"
                    
                    self.reportModels = reportModels
                }
                self.titleWorkout = titleWorkout
                self.titleWorkoutGroup = titleWorkoutGroup
                self.reportExercises = reportExercises
                
                if targetExercisesCount > 0 {
                    self.progressWorkout = Double(exercisesCount) / Double(targetExercisesCount)
                    self.percentageProgressWorkout = "\(Int(self.progressWorkout * 100))%"
                }
                
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    private func createReportModels(exersices: [ReportExerciseModelDB]) -> [ReportModel] {
        
        var targetWeight: Float = 0.0
        var targetReps: Int = 0
        var targetDistance: Float = 0.0
        var targetTime: TimeInterval = 0.0
        
        var weight: Float = 0.0
        var reps: Int = 0
        var distance: Float = 0.0
        var time: TimeInterval = 0.0
        
        for exercise in exersices {
            
            for target in exercise.targetSets {
                
                if let weight = target.weight, 
                    let reps = target.reps {
                    targetWeight += weight * Float(reps)
                } else {
                    targetWeight += target.weight ?? 0
                }
                targetReps += target.reps ?? 0
                targetDistance += target.distance ?? 0
                targetTime += target.time ?? 0
            }
            
            for report in exercise.reportSets {
                if let weightReport = report.weight,
                    let repsReport = report.reps {
                    weight += weightReport * Float(repsReport)
                } else {
                    weight += report.weight ?? 0
                }
                reps += report.reps ?? 0
                distance += report.distance ?? 0
                time += report.time ?? 0
            }
        }
        
        var result = [ReportModel]()
        
        if targetWeight > 0 {
            let percentage = Double(weight) / Double(targetWeight)
            result.append(ReportModel(primary: "Weight",
                                      secondary: "\(Int(weight)) from \(Int(targetWeight))",
                                      progress: percentage,
                                      percentageProgress: "\(Int(percentage * 100))%"))
        }
        
        if targetReps > 0 {
            let percentage = Double(reps) / Double(targetReps)
            result.append(ReportModel(primary: "Repetitions",
                                      secondary: "\(reps) from \(targetReps)",
                                      progress: percentage,
                                      percentageProgress: "\(Int(percentage * 100))%"))
        }
        
        if targetDistance > 0 {
            let percentage = Double(distance) / Double(targetDistance)
            result.append(ReportModel(primary: "Distance",
                                      secondary: "\(Int(distance)) from \(Int(targetDistance))",
                                      progress: percentage,
                                      percentageProgress: "\(Int(percentage * 100))%"))
        }
        
        if targetTime > 0 {
            let percentage = Double(time) / Double(targetTime)
            result.append(ReportModel(primary: "Time",
                                      secondary: "\(time.timeForDisplay) from \(targetTime.timeForDisplay)",
                                      progress: percentage,
                                      percentageProgress: "\(Int(percentage * 100))%"))
        }
        
        return result
    }
    
    // MARK: - Public methods
    
    func reloadData(complete: (()->())? = nil) {
        self.fetchItems(complete: complete)
    }
    
    func refreshData() {
        
    }
}
