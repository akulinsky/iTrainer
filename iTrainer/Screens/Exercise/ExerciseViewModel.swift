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
    
    @EnvironmentObject var dataContainer: DataContainer
    
    @Published var sets = [SetsModel]()
    
    @Published var isShowAlert = false
    
    @Published var isEditSets = false
    
    @Published var isEditExercise = false
    
    @Published var title: String
    
    
    @Published var strWeight: String = ""
    
    @Published var strReps: String = ""
    
    @Published var shakeWeight = PassthroughSubject<Void, Never>()
    
    @Published var shakeReps = PassthroughSubject<Void, Never>()
    
    
    var editSets: SetsModel?
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
        title = exercise.title ?? ""
    }
    
    private func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            if let model = await dataManager.fetchExercise(for: exercise.id).map({ ExerciseModel(model: $0) }) {
                exercise = model
            }
            
            title = exercise.displayName
            
            let items = await dataManager.fetchSets(for: exercise.id).map { SetsModel(model: $0) }
            await MainActor.run {
                sets = items
                if let complete = complete {
                    complete()
                }
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
    
    func update(weight: Float, reps: Int) {
        if var editSets = editSets {
            editSets.reps = reps
            editSets.weight = weight
            update(item: editSets)
        } else {
            update(item: SetsModel(reps: reps, weight: weight))
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
    
    func save() {
        var resultWeight: Float = 0.0
        var resultReps: Int = 0
        
        
        if let weight = Float(strWeight), weight > 0 {
            resultWeight = weight
        } else {
            shakeWeight.send()
            return
        }
        
        if let reps = Int(strReps), reps > 0 {
            resultReps = reps
        } else {
            shakeReps.send()
            return
        }
    }
    
    private func addNewExerciseToBase(_ setsModel: SetsModel, dataManager: DataManagerBackground) async {
        let item = SetsModelDB()
        
        await dataManager.insert(model: item)
        item.index = setsModel.index
        item.reps = setsModel.reps
        item.weight = setsModel.weight
    }
}
