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
    
    @Published var switchRest = false {
        didSet {
            guard oldValue != switchRest else { return }
            
            if switchRest {
                if restTimeInterval > 0 {
                    previousRestTime = restTime
                }
                restTime = "0:00"
            } else {
                restTime = previousRestTime
            }
        }
    }
    
    @Published var restTime = ""
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    private var isFirstTime = true
    private var deletedSets = [SetEditCellViewModel]()
    private var previousRestTime = TimeInterval(120).minuteSecond
    
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
        switchRest = exercise.restTime <= 0
        restTime = switchRest ? "0:00" : exercise.restTime.minuteSecond
        previousRestTime = exercise.restTime > 0 ? exercise.restTime.minuteSecond : TimeInterval(120).minuteSecond
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
        guard let type = exercise.type else {
            return
        }
        
        var set = setsViewModels.last?.model ?? SetsModel()
        set.id = UUID()
        set.index = setsViewModels.count + 1
        
        if setsViewModels.isEmpty {
            set.parameters = type.parameters
        }
        
        setsViewModels.append(SetEditCellViewModel(model: set, exerciseType: type))
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
        switchRest ? 0 : Int(restTimeInterval)
    }
    
    var restTimeDisplay: String {
        switchRest ? "No rest" : restTime
    }
    
    func setRestTime(seconds: Int) {
        let clampedSeconds = min(max(seconds, 0), 600)
        guard clampedSeconds > 0 else {
            switchRest = true
            return
        }
        
        restTime = TimeInterval(clampedSeconds).minuteSecond
        previousRestTime = restTime
        switchRest = false
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
    
    private func validateTargetSets() -> Bool {
        setsViewModels.allSatisfy { $0.commitAllInputs() && $0.hasValidValues }
    }
    
    func save(completeBlock: @escaping SaveingBlock) {
        guard validateTargetSets() else {
            errorMessage = "Fill all target set values before saving."
            isShowAlert = true
            completeBlock(false)
            return
        }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            exercise.title = title.isEmpty ? nil : title
            
            exercise.restTime = self.switchRest ? 0 : self.restTimeInterval
            
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
        var valueBeforeEditing: SetsParameter?
        
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
                    self.value = value.distanceForTextField
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
    
    private var exerciseType: ExerciseTypeModel
    
    var id: UUID {
        model.id
    }
    
    @Published var model: SetsModel
    
    var paramsData = [ParamData]()
    
    var hasValidValues: Bool {
        model.parameters.allSatisfy { isValid(parameter: $0) }
    }
    
    // MARK: - Init
    
    init(model: SetsModel, exerciseType: ExerciseTypeModel) {
        self.model = model
        self.exerciseType = exerciseType
        
        for param in self.model.parameters {
            let paramData = ParamData(param: param, focusId: "set-\(model.id.uuidString)-\(param.id)")
            paramsData.append(paramData)
            
        }
    }
    
    private func parsedFloat(from value: String) -> Float {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        if let value = numberFormatter.number(from: value)?.floatValue {
            return value
        }
        return Float(value) ?? 0
    }
    
    func clearInput(id: String) -> Bool {
        guard let paramData = paramsData.first(where: { $0.focusId == id }) else {
            return false
        }
        
        paramData.value = ""
        return true
    }
    
    private func parameter(for paramId: Int) -> SetsParameter? {
        model.parameters.first(where: { $0.id == paramId })
    }
    
    private func updateParameter(_ parameter: SetsParameter) {
        guard let index = model.parameters.firstIndex(where: { $0.id == parameter.id }) else {
            return
        }
        
        var updatedModel = model
        updatedModel.parameters[index] = parameter
        model = updatedModel
    }
    
    private func isValid(parameter: SetsParameter) -> Bool {
        switch parameter {
        case .weight(let value):
            return value > 0
        case .repeats(let value):
            return value > 0
        case .distance(let value):
            return value > 0
        case .time(let value):
            return value > 0
        }
    }
    
    private func parameter(from paramData: ParamData) -> SetsParameter? {
        guard !paramData.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        switch paramData.param {
        case .weight:
            let value = parsedFloat(from: paramData.value)
            return value > 0 ? .weight(value) : nil
        case .repeats:
            guard let value = Int(paramData.value), value > 0 else {
                return nil
            }
            return .repeats(value)
        case .distance:
            let value = parsedFloat(from: paramData.value)
            return value > 0 ? .distance(value) : nil
        case .time:
            let textValue = paramData.value.replacingOccurrences(of: ":", with: "")
            guard let value = Double(textValue) else {
                return nil
            }
            let time = TimeInterval.timeForSet(value: value)
            return time > 0 ? .time(time) : nil
        }
    }
    
    @discardableResult
    private func commitInput(_ paramData: ParamData) -> SetsParameter? {
        guard let parameter = parameter(from: paramData) else {
            return nil
        }
        
        updateParameter(parameter)
        return parameter
    }
    
    func commitAllInputs() -> Bool {
        paramsData.allSatisfy { commitInput($0) != nil }
    }
    
    func summaryText(for paramId: Int) -> String {
        guard let parameter = parameter(for: paramId) else {
            return ""
        }
        
        let value = displayValue(for: parameter)
        return "\(parameter.title): \(value.isEmpty ? "-" : value)"
    }
    
    private func displayValue(for parameter: SetsParameter) -> String {
        switch parameter {
        case .weight(let value):
            return value > 0 ? "\(value)" : ""
        case .repeats(let value):
            return value > 0 ? "\(value)" : ""
        case .distance(let value):
            return value > 0 ? value.distanceForDisplay : ""
        case .time(let value):
            return value > 0 ? value.timeForTextField : ""
        }
    }
    
    private func textFieldValue(for parameter: SetsParameter) -> String {
        switch parameter {
        case .weight(let value):
            return value > 0 ? "\(value)" : ""
        case .repeats(let value):
            return value > 0 ? "\(value)" : ""
        case .distance(let value):
            return value > 0 ? value.distanceForTextField : ""
        case .time(let value):
            return value > 0 ? value.timeForTextField : ""
        }
    }
    
    func focused(_ focused: Bool, paramData: ParamData, complete: (()->())? = nil) {
        if focused {
            paramData.valueBeforeEditing = parameter(for: paramData.id)
            return
        }
        
        let parameter = commitInput(paramData) ?? self.parameter(for: paramData.id)
        
        guard let parameter else {
            return
        }
        
        DispatchQueue.main.async {
            paramData.value = self.textFieldValue(for: parameter)
            paramData.valueBeforeEditing = nil
            if let complete = complete {
                complete()
            }
        }
    }
    
    // MARK: - Private methods
    
    // MARK: - Public methods
}
