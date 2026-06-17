//
//  ReportExerciseViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.09.2024.
//

import Foundation
import SwiftUI
import Charts

class ReportExerciseViewModel: ObservableObject {
    
    enum ChartType: String, CaseIterable, Plottable {
        case weight = "Weight"
        case repeats = "Repeats"
        case distance = "Distance"
        case time = "Time"
        
        var color: Color {
            switch self {
            case .weight: return .green
            case .repeats: return .blue
            case .distance: return .purple
            case .time: return .red
            }
        }
    }

    struct ChartData: Identifiable {
        var id = UUID()
        var date: Date
        var value: Double
        var type: ChartType
    }
    
    @Published var sets = [ReportSetsModel]()
    
    @Published var chartData = [ChartData]()
    
    @Published var isShowAlert = false
    
    @Published var title: String
    
    var errorMessage: String? = nil
    
    var reportExercise: ReportExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    static var countExerciseViewModel = 0
    
//    private let log = LifecycleLogger(name: "ExerciseViewModel")
    
    init(reportExercise: ReportExerciseModel) {
        self.reportExercise = reportExercise
        title = reportExercise.titleExercise
    }
    
    func reloadData(complete: (()->())? = nil) {
        sets = reportExercise.sets.sorted(by: { $0.index < $1.index })
        fetchItems(complete: complete)
    }
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
//            if let model = await dataManager.fetchExercise(with: exercise.id).map({ ExerciseModel(model: $0) }) {
//                exercise = model
//                
//                DataContainer.shared.workoutManager.currentExercise(id: exercise.id)
//                
//                await MainActor.run {
//                    if paramsData.isEmpty {
//                        for param in exercise.type!.parameters {
//                            self.paramsData.append(ParamData(param: param))
//                        }
//                    }
//                    
//                    title = exercise.displayName
//                }
//            }
            
//            let items = await dataManager.fetchSets(for: reportExercise.exerciseId).map { SetsModel(model: $0) }
            
//            let reportExercise = await dataManager.fetchReportExercises(exerciseId: reportExercise.exerciseId)
//                .filter({ $0.reportSets.count > 0 })
//                .map { ReportExerciseModel(model: $0) }
//                .sorted(by: {
//                    guard let date1 = $0.date, let date2 = $1.date else {
//                        return false
//                    }
//                    return date1 < date2
//                })
            
            var reportSets = [ReportSetsModel]()
            
            await dataManager.fetchReportExercises(exerciseId: reportExercise.exerciseId)
                .filter({ $0.reportSets.count > 0 })
                .forEach {
                    reportSets.append(contentsOf: $0.reportSets.map({ ReportSetsModel(model: $0) }))
                }

            let chartData = reportSets.sorted(by: { $0.date < $1.date })
                .flatMap({ sets in /*ChartData(date: $0.date, value: Double($0.), title: <#T##String#>, color: <#T##Color#>)*/
                    
                    var data = [ChartData]()
                    sets.parameters.forEach({
                        switch $0 {
                        case .weight(let value):
                            data.append(
                                ChartData(date: sets.date, value: Double(value), type: .weight)
                            )
                        case .repeats(let value):
//                            data.append(
//                                ChartData(date: sets.date, value: Double(value), type: .repeats)
//                            )
                            break
                        case .distance(let value):
                            data.append(
                                ChartData(date: sets.date, value: Double(value), type: .distance)
                            )
                        case .time(let value):
                            data.append(
                                ChartData(date: sets.date, value: Double(value), type: .time)
                            )
                        }
                    })
                    return data
                })
            
            await MainActor.run { [chartData] in
                
//                self.reportExercises = reportExercise
                self.chartData = chartData
                
                if let complete = complete {
                    complete()
                }
            }
        }
    }
}
