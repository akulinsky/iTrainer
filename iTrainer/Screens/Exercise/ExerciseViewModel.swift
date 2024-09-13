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
    
    @Published var reportSets = [ReportSetsModel]()
    
    @Published var isShowAlert = false
    
    @Published var isEditSets = false
    
    @Published var isEditExercise = false
    
    @Published var title: String
    
    var paramsData = [ParamData]()
    
    var editSets: SetsModel?
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    static var countExerciseViewModel = 0
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        title = exercise.title ?? ""
        
        ExerciseViewModel.countExerciseViewModel += 1
        print("DBG_ countExerciseViewModel: \(ExerciseViewModel.countExerciseViewModel)")
    }
    
    deinit {
        ExerciseViewModel.countExerciseViewModel -= 1
        print("DBG_ countExerciseViewModel: \(ExerciseViewModel.countExerciseViewModel)")
    }
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            if let model = await dataManager.fetchExercise(with: exercise.id).map({ ExerciseModel(model: $0) }) {
                exercise = model
                
                DataContainer.shared.workoutManager.currentExercise(id: exercise.id)
                
                await MainActor.run {
                    if paramsData.isEmpty {
                        for param in exercise.type!.parameters {
                            self.paramsData.append(ParamData(param: param))
                        }
                    }
                    
                    title = exercise.displayName
                }
            }
            
            let items = await dataManager.fetchSets(for: exercise.id).map { SetsModel(model: $0) }
            var reportSets: [ReportSetsModel]?
            if let reportExercise = await dataManager.fetchReportExercise(exerciseId: exercise.id) {
                reportSets = reportExercise.reportSets.map { ReportSetsModel(model: $0) }.sorted(by: { $0.date > $1.date })
//                print("DBG_ -------- SETS --------")
//                for set in reportExercise.reportSets {
//                    print("DBG_ weight: \(String(describing: set.weight)) reps: \(String(describing: set.reps))")
//                }
            }
            
            await MainActor.run { [reportSets] in
                
                self.sets = items
                if let reportSets = reportSets {
                    self.reportSets = reportSets
                }
                
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
            update(item: editSets)
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
            update(item: SetsModel(params: result))
        }
        
        editSets = nil
    }
    
    func update(item: SetsModel) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(sets: item, exerciseId: exercise.id)
            await MainActor.run {
                fetchItems()
            }
        }
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
    
    func save() {
        
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
        DataContainer.shared.workoutManager.addReportSet(with: result, for: exercise.id)
    }
}
