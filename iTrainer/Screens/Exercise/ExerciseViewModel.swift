//
//  ExerciseModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Alamofire
import Combine

class ExerciseViewModel: ObservableObject {
    
    private let reportHistoryDayLimit = 10
    
    @Observable
    class ParamData: Identifiable {
        var id: Int = 0
        var value: String = ""
        var shake = PassthroughSubject<Void, Never>()
        
        var param: SetsParameter
        
        let keyboardType: UIKeyboardType
        
        init(param: SetsParameter) {
            self.param = param
            self.id = param.id
            
            switch param {
            case .weight(_):
                keyboardType = .decimalPad
            case .repeats(_):
                keyboardType = .numberPad
            case .distance(_):
                keyboardType = .numberPad
            case .time(_):
                keyboardType = .numberPad
            }
        }
    }
    
    @Published var sets = [SetsModel]()
    
    @Published var reportExercises = [ReportExerciseModel]()
    
    @Published var isShowAlert = false
    
    @Published var isEditSets = false
    
    @Published var isEditReportSets = false
    
    @Published var isEditExercise = false
    
    @Published var title: String
    
    @Published var isActiveWorkoutExercise = false
    
    @Published var activeReportSetCount = 0
    
    @Published var nextExercise: ExerciseModel?
    
    var hasTargetSets: Bool {
        !sets.isEmpty
    }
    
    var isTargetCompleted: Bool {
        hasTargetSets && activeReportSetCount >= sets.count
    }
    
    var shouldShowCompletedGoalActions: Bool {
        isActiveWorkoutExercise && isTargetCompleted
    }
    
    var paramsData = [ParamData]()
    
    var editSets: SetsModel?
    
    var editReportSets: ReportSetsModel?
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    static var countExerciseViewModel = 0
    
//    private let log = LifecycleLogger(name: "ExerciseViewModel")
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        title = exercise.title ?? ""
    }
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            if let model = await dataManager.fetchExercise(with: exercise.id) {
                let exerciseModel = ExerciseModel(model: model)
                let startedWorkout = await dataManager.fetchStartedWorkout()
                let workoutGroupId = model.workoutGroup?.id
                let isActiveWorkoutExercise = startedWorkout?.workoutGroupId == workoutGroupId
                let activeReportSetCount = startedWorkout?.exercises.first(where: { $0.exerciseId == model.id })?.reportSets.count ?? 0
                var nextExerciseModel: ExerciseModel?
                if isActiveWorkoutExercise, let workoutGroupId {
                    nextExerciseModel = await dataManager.fetchExercises(for: workoutGroupId)
                        .first { !$0.isHeadline && $0.index > model.index }
                        .map { ExerciseModel(model: $0) }
                }
                let resolvedNextExercise = nextExerciseModel
                
                await MainActor.run {
                    exercise = exerciseModel
                    self.isActiveWorkoutExercise = isActiveWorkoutExercise
                    self.activeReportSetCount = activeReportSetCount
                    self.nextExercise = isActiveWorkoutExercise ? resolvedNextExercise : nil
                    
                    if paramsData.isEmpty {
                        for param in exercise.type!.parameters {
                            self.paramsData.append(ParamData(param: param))
                        }
                    }
                    
                    title = exercise.displayName
                }
            }
            
            let items = await dataManager.fetchSets(for: exercise.id).map { SetsModel(model: $0) }
            
            let reportExercise = await dataManager.fetchRecentReportExercises(exerciseId: self.exercise.id,
                                                                               dayLimit: reportHistoryDayLimit)
                .map { ReportExerciseModel(model: $0) }
            
            await MainActor.run { [reportExercise] in
                
                self.sets = items
                self.reportExercises = reportExercise
                
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    func addResult(with params: [SetsParameter]) {
        for param in params {
            
            var result = ""
            switch param {
            case .weight(let value):
                result = "\(value)"
            case .repeats(let value):
                result = "\(value)"
            case .distance(let value):
                result = "\(value)"
            case .time(let value):
                result = value.minuteSecond
            }
            if let paramData = paramsData.first(where: { $0.param.id == param.id }) {
                paramData.value = result
            }
        }
    }
    
    func reloadData(complete: (()->())? = nil) {
        self.fetchItems(complete: complete)
    }
    
    func refreshData() {
        
    }
    
    func edit(sets: SetsModel) {
        editSets = sets
        isEditSets = true
    }
    
    func update(params: [SetsParameter]) {
        
        if var editSets = editSets {
            for param in params {
                var newParam: SetsParameter?
                
                switch param {
                case .weight(let value):
                    newParam = .weight(value)
                case .repeats(let value):
                    newParam = .repeats(value)
                case .distance(let value):
                    newParam = .distance(value)
                case .time(let value):
                    newParam = .time(value)
                }
                
                if let newParam = newParam,
                    let index = editSets.parameters.firstIndex(where: { $0.id == param.id}) {
                    editSets.parameters.remove(at: index)
                    editSets.parameters.insert(newParam, at: index)
                }
            }
            update(sets: editSets)
        } else {
            var result = [SetsParameter]()
            for param in params {
                var newParam: SetsParameter?
                
                switch param {
                case .weight(let value):
                    newParam = .weight(value)
                case .repeats(let value):
                    newParam = .repeats(value)
                case .distance(let value):
                    newParam = .distance(value)
                case .time(let value):
                    newParam = .time(value)
                }
                
                if let newParam = newParam {
                    result.append(newParam)
                }
            }
            update(sets: SetsModel(params: result))
        }
        
        editSets = nil
    }
    
    private func update(sets: SetsModel) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(sets: sets, exerciseId: exercise.id)
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func editReport(sets: ReportSetsModel) {
        editReportSets = sets
        isEditReportSets = true
    }
    
    func updateReport(params: [SetsParameter]) {
        if var editSets = editReportSets {
            for param in params {
                var newParam: SetsParameter?
                
                switch param {
                case .weight(let value):
                    newParam = .weight(value)
                case .repeats(let value):
                    newParam = .repeats(value)
                case .distance(let value):
                    newParam = .distance(value)
                case .time(let value):
                    newParam = .time(value)
                }
                
                if let newParam = newParam,
                   let index = editSets.parameters.firstIndex(where: { $0.id == param.id}) {
                    editSets.parameters.remove(at: index)
                    editSets.parameters.insert(newParam, at: index)
                }
            }
            updateReport(sets: editSets)
            editReportSets = nil
        }
    }
    
    private func updateReport(sets: ReportSetsModel) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).updateReport(sets: sets)
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func clearParamsDataValues() {
        paramsData.forEach { $0.value = "" }
    }
    
    func focused(_ focused: Bool, paramData: ParamData) {
        if focused {
            return
        }
        
        switch paramData.param {
        case .time(_):
            let value = paramData.value.replacingOccurrences(of: ":", with: "")
            if let value = Double(value), value > 0 {
                let time = TimeInterval.timeForSet(value: value)
                DispatchQueue.main.async {
                    paramData.value = time.timeForTextField
                }
            }
        default:
            break
        }
    }
    
    func tapToTimer() {
        print("DBG_ tapToTimer")
    }
    
    func save(complete: (()->())? = nil) {
        
        var result = [SetsParameter]()
        
        for param in paramsData {
            
            switch param.param {
            case .weight(_):
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                if let value = numberFormatter.number(from: param.value)?.floatValue, value >= 0 {
                    result.append(.weight(value))
                } else if let value = Float(param.value), value >= 0 {
                    result.append(.weight(value))
                } else {
                    param.shake.send()
                    return
                }
            case .repeats(_):
                if let value = Int(param.value), value >= 0 {
                    result.append(.repeats(value))
                } else {
                    param.shake.send()
                    return
                }
            case .distance(_):
                if let value = Float(param.value), value >= 0 {
                    result.append(.distance(value))
                } else {
                    param.shake.send()
                    return
                }
            case .time(_):
                let value = param.value.replacingOccurrences(of: ":", with: "")
                if let value = Double(value), value >= 0 {
                    let time = TimeInterval.timeForSet(value: value)
                    result.append(.time(time))
                } else {
                    param.shake.send()
                    return
                }
            }
        }
        
        Task { [result] in
            await DataContainer.shared.workoutManager.addReportSet(with: result, for: exercise.id)
            await MainActor.run {
                fetchItems()
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    func deleteReportSets(offsets: IndexSet, reportExerciseId: UUID) {
        
        guard let exercise = reportExercises.first(where: { $0.id == reportExerciseId }), 
            let index = offsets.first else {
            return
        }
        
        Task {
            let set = exercise.sets[index]
            await DataContainer.shared.workoutManager.removeReportSet(id: set.id)
            await MainActor.run {
                fetchItems()
            }
        }
    }
}
