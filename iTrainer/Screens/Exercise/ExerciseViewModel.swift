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
    
    @Published var isShowAlert = false
    
    @Published var isEditSets = false
    
    @Published var isEditExercise = false
    
    @Published var title: String
    
    @Published var restTime: TimeInterval = 2.0
    
    @Published var progressRestTime: Double = 1.0
    
    var paramsData = [ParamData]()
    
    
    var editSets: SetsModel?
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    private var isRunTimer = false
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        title = exercise.title ?? ""
    }
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            if let model = await dataManager.fetchExercise(for: exercise.id).map({ ExerciseModel(model: $0) }) {
                exercise = model
                
                await MainActor.run {
                    isRunTimer = false
                    restTime = exercise.restTime
                    progressRestTime = 1.0
                    
                    if paramsData.isEmpty {
                        for param in exercise.type!.parameters {
                            self.paramsData.append(ParamData(param: param))
                        }
                    }
                    
                    title = exercise.displayName
                }
            }
            
            let items = await dataManager.fetchSets(for: exercise.id).map { SetsModel(model: $0) }
            await MainActor.run {
                
                sets = items
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    func fire() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) {
            
            if !self.isRunTimer {
                return
            }
            
            if self.restTime <= 0 {
                self.restTime = self.exercise.restTime
                self.progressRestTime = 1.0
                self.isRunTimer = false
            } else {
                self.restTime -= 0.1
            }
            
            self.progressRestTime = self.restTime / self.exercise.restTime
            self.fire()
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
        isRunTimer.toggle()
        if isRunTimer {
            fire()
        }
    }
    
    func save() {
//        var resultWeight: Float = 0.0
//        var resultReps: Int = 0
        
        for param in paramsData {
            
            if let weight = Float(param.value), weight > 0 {
//                resultWeight = weight
            } else {
                param.shake.send()
                return
            }
        }
    }
}
