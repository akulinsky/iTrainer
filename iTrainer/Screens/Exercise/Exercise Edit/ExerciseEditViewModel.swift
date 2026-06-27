//
//  ExerciseEditViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.08.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Alamofire
import Combine

enum ExerciseEditFocusId {
    static let title = "exercise-title"
}

class ExerciseEditViewModel: ObservableObject {
    
    // MARK: - Properties
    
    typealias SaveingBlock = (Bool)->()
    
    @Published var setsViewModels = [SetEditCellViewModel]()
    
    @Published var isShowAlert = false
    
    @Published var title: String
    
    @Published var switchRest = false
    
    @Published var restTime = ""
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    private var isFirstTime = true
    private var deletedSets = [SetEditCellViewModel]()
    
    private var restTimeInterval: TimeInterval {
        var time = TimeInterval(0)
        
        let value = restTime.replacingOccurrences(of: ":", with: "")
        
        if let value = Double(value), value >= 0 {
            var value = TimeInterval.timeForSet(value: value)
            if value > 600 {
                value = 600
            }
            time = value
        }
        return time
    }
    
    // MARK: - Init
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        title = exercise.title ?? ""
        restTime = exercise.restTime.minuteSecond
    }
    
    // MARK: - Private methods
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            
            guard let type = self.exercise.type else {
                return
            }
            
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchSets(for: exercise.id).map { SetEditCellViewModel(model: SetsModel(model: $0), exerciseType: type) }
            await MainActor.run {
                setsViewModels = items
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    // MARK: - Public methods
    
    func reloadData(complete: (()->())? = nil) {
        if isFirstTime {
            isFirstTime = false
            self.fetchItems(complete: complete)
        }
    }
    
    func add() {
        
        guard let params = exercise.type?.parameters else {
            return
        }
        
        var set = SetsModel()
        set.index = setsViewModels.count + 1
        
        for param in params {
            set.parameters.append(param)
        }
        
        if let type = exercise.type {
            setsViewModels.append(SetEditCellViewModel(model: set, exerciseType: type))
        }
    }
    
    func delete(setsViewModel: SetEditCellViewModel) {
        setsViewModels.removeAll { setsViewModel.model.id == $0.model.id }
        deletedSets.append(setsViewModel)
        
        for (index, value) in setsViewModels.enumerated() {
            value.model.index = index + 1
            setsViewModels[index] = value
        }
    }
    
    var restTimeSeconds: Int {
        Int(restTimeInterval)
    }
    
    func setRestTime(seconds: Int) {
        let clampedSeconds = min(max(seconds, 0), 600)
        restTime = TimeInterval(clampedSeconds).minuteSecond
    }
    
    func focusedRestTime(_ focused: Bool) {
        if focused {
            return
        }
        
        DispatchQueue.main.async {
            self.restTime = self.restTimeInterval.minuteSecond
        }
    }
    
    func clearFocusedInput(id: String) {
        if id == ExerciseEditFocusId.title {
            title = ""
            return
        }
        
        for setViewModel in setsViewModels {
            if setViewModel.clearInput(id: id) {
                return
            }
        }
    }
    
    func save(completeBlock: @escaping SaveingBlock) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            exercise.title = title.isEmpty ? nil : title
            
            exercise.restTime = self.restTimeInterval
            
            await dataManager.update(exercise: exercise)
            
            await dataManager.removeSets(with: deletedSets.map({ $0.model.id }))
            
            await dataManager.update(sets: setsViewModels.map({ $0.model }), exerciseId: exercise.id)
            
            await MainActor.run {
                completeBlock(true)
            }
        }
    }
}

class SetEditCellViewModel: ObservableObject, Identifiable {
    
    class ParamData: ObservableObject, Identifiable {
        var id: Int
        @Published var value: String = ""
        var shake = PassthroughSubject<Void, Never>()
        
        let focusId: String
        let param: SetsParameter
        
        let keyboardType: UIKeyboardType
        
        init(param: SetsParameter, focusId: String) {
            self.param = param
            self.focusId = focusId
            self.id = param.id
            
            switch param {
            case .weight(let value):
                if value > 0 {
                    self.value = "\(value)"
                }
                keyboardType = .decimalPad
            case .repeats(let value):
                if value > 0 {
                    self.value = "\(value)"
                }
                keyboardType = .numberPad
            case .distance(let value):
                if value > 0 {
                    self.value = value.distanceForDisplay
                }
                keyboardType = .numberPad
            case .time(let value):
                if value > 0 {
                    self.value = value.timeForTextField
                }
                keyboardType = .numberPad
            }
        }
    }
    
    // MARK: - Properties
    
    private var cancellable = Set<AnyCancellable>()
    
    private var exerciseType: ExerciseTypeModel
    
    var id: UUID {
        model.id
    }
    
    var model: SetsModel
    
    var paramsData = [ParamData]()
    
    // MARK: - Init
    
    init(model: SetsModel, exerciseType: ExerciseTypeModel) {
        self.model = model
        self.exerciseType = exerciseType
        
        for param in self.model.parameters {
            let paramData = ParamData(param: param, focusId: "set-\(model.id.uuidString)-\(param.id)")
            paramsData.append(paramData)
            
            var ignore = false
            
            switch param {
            case .weight(_):
                paramData.$value.sink { value in
                    
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = NumberFormatter.Style.decimal
                    if let value = numberFormatter.number(from: value)?.floatValue, value > 0 {
                        if let index = self.model.parameters.firstIndex(where: { $0.id == param.id}) {
                            self.model.parameters.remove(at: index)
                            self.model.parameters.insert(.weight(value), at: index)
                        }
                    }
                }
                .store(in: &cancellable)
            case .repeats(_):
                paramData.$value.sink { value in
                    if let value = Int(value), value > 0 {
                        if let index = self.model.parameters.firstIndex(where: { $0.id == param.id}) {
                            self.model.parameters.remove(at: index)
                            self.model.parameters.insert(.repeats(value), at: index)
                        }
                    }
                }
                .store(in: &cancellable)
            case .distance(_):
                paramData.$value.sink { value in
                    if let value = Float(value), value > 0 {
                        if let index = self.model.parameters.firstIndex(where: { $0.id == param.id}) {
                            self.model.parameters.remove(at: index)
                            self.model.parameters.insert(.distance(value), at: index)
                        }
                    }
                }
                .store(in: &cancellable)
            case .time(_):
                paramData.$value.sink { value in
                    if ignore {
                        ignore = false
                        return
                    }
                    
                    let value = value.replacingOccurrences(of: ":", with: "")
                    if let value = Double(value), value > 0 {
                        let value = TimeInterval.timeForSet(value: value)
                        if let index = self.model.parameters.firstIndex(where: { $0.id == param.id}) {
                            
                            if case .time(let time) = self.model.parameters[index], value == time {
                                return
                            }
                            ignore = true
                            self.model.parameters.remove(at: index)
                            self.model.parameters.insert(.time(value), at: index)
                        }
                    }
                }
                .store(in: &cancellable)
            }
        }
    }
    
    func clearInput(id: String) -> Bool {
        guard let paramData = paramsData.first(where: { $0.focusId == id }),
              let index = model.parameters.firstIndex(where: { $0.id == paramData.id }) else {
            return false
        }
        
        switch model.parameters[index] {
        case .weight:
            model.parameters[index] = .weight(0)
        case .repeats:
            model.parameters[index] = .repeats(0)
        case .distance:
            model.parameters[index] = .distance(0)
        case .time:
            model.parameters[index] = .time(0)
        }
        
        paramData.value = ""
        return true
    }
    
    func focused(_ focused: Bool, paramData: ParamData, complete: (()->())? = nil) {
        if focused {
            return
        }
        
        switch paramData.param {
        case .time(_):
            if let index = self.model.parameters.firstIndex(where: { $0.id == paramData.id}) {
                if case .time(let time) = self.model.parameters[index] {
                    DispatchQueue.main.async {
                        paramData.value = time > 0 ? time.timeForTextField : ""
                        if let complete = complete {
                            complete()
                        }
                    }
                }
            }
           
        default:
            break
        }
    }
    
    // MARK: - Private methods
    
    // MARK: - Public methods
}
