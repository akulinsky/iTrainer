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
    
    var editSets: SetsModel?
    
    var errorMessage: String? = nil
    
    var exercise: ExerciseModel
    
    private let networkClient = ServiceNetworkClient()
    
    init(exercise: ExerciseModel) {
        self.exercise = exercise
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
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
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchSets(for: exercise.id)
            models.move(fromOffsets: source, toOffset: destination)
            var index = 1
            for item in models {
                item.index = index
                index += 1
            }
            await dataManager.save()
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func delete(index: Int) {
        let item = self.sets[index]
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeSets(with: item.id)
            print("DBG_ --------------")
            print("DBG_  SetsModelDB count: \(await SetsModelDB.count())")
            await MainActor.run {
                fetchItems()
            }
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
