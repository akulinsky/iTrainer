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

class ExerciseEditViewModel: ObservableObject {
    
    // MARK: - Properties
    
    typealias SaveingBlock = (Bool)->()
    
    @EnvironmentObject var dataContainer: DataContainer
    
    @Published var setsViewModels = [SetEditCellViewModel]()
    
    @Published var isShowAlert = false
    
    @Published var title: String
    
    @Published var switchBrake = false
    
    @Published var brakeTime: TimeInterval = 120.0
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    private var isFirstTime = true
    private var deletedSets = [SetEditCellViewModel]()
    
    // MARK: - Init
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        title = exercise.title ?? ""
    }
    
    // MARK: - Private methods
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchSets(for: exercise.id).map { SetEditCellViewModel(model: SetsModel(model: $0)) }
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
        var set = SetsModel()
        set.index = setsViewModels.count + 1
        setsViewModels.append(SetEditCellViewModel(model: set))
//        sets.append(set)
//        addedSets.append(set)
    }
    
    func delete(setsViewModel: SetEditCellViewModel) {
        setsViewModels.removeAll { setsViewModel.model.id == $0.model.id }
        deletedSets.append(setsViewModel)
        
        for (index, value) in setsViewModels.enumerated() {
            value.model.index = index + 1
            setsViewModels[index] = value
        }
    }
    
    func save(completeBlock: @escaping SaveingBlock) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            exercise.title = title.isEmpty ? nil : title
            
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
    
    // MARK: - Properties
    
    @Published var strWeight: String
    
    @Published var strReps: String
    
    private var cancellable = Set<AnyCancellable>()
    
    var id: UUID {
        model.id
    }
    
    var model: SetsModel
    
    // MARK: - Init
    
    init(model: SetsModel) {
        self.model = model
        
        if let value = model.weight, value > 0 {
            strWeight = String(format: "%.1f", model.weight ?? 0)
        } else {
            strWeight = ""
        }
        
        if let value = model.weight, value > 0 {
            strReps = String("\(model.reps ?? 0)")
        } else {
            strReps = ""
        }
        
        $strWeight.sink { value in
            if let value = Float(value), value > 0 {
                self.model.weight = value
            }
        }
        .store(in: &cancellable)
        
        $strReps.sink { value in
            if let value = Int(value), value > 0 {
                self.model.reps = value
            }
        }
        .store(in: &cancellable)
    }
    
    // MARK: - Private methods
    
    // MARK: - Public methods
}
