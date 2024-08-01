//
//  ExerciseListModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Alamofire
import Combine

class ExerciseListViewModel: ObservableObject {
    
    @EnvironmentObject var dataContainer: DataContainer
    
    @Published var exercises = [ExerciseModel]()
    
    @Published var isShowAlert = false
    
    @Published var isEditExercise = false
    
    var editExercise: ExerciseModel?
    
    var errorMessage: String? = nil
    
    var group: WorkoutGroupModel
    
    private let networkClient = ServiceNetworkClient()
    
    init(group: WorkoutGroupModel) {
        self.group = group
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchExercise(for: group.id).map { ExerciseModel(model: $0) }
            await MainActor.run {
                exercises = items
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
    
    func edit(exercise: ExerciseModel) {
        editExercise = exercise
        isEditExercise = true
    }
    
    func update(name: String) {
        if var editExercise = editExercise {
            editExercise.title = name
            update(item: editExercise)
        } else {
            update(item: ExerciseModel(title: name))
        }
        editExercise = nil
    }
    
    func update(item: ExerciseModel) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(exercise: item, groupId: group.id)
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchExercise(for: group.id)
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
        let item = self.exercises[index]
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeExercise(with: item.id)
            print("DBG_ --------------")
            print("DBG_  ExerciseModelDB count: \(await ExerciseModelDB.count())")
            print("DBG_  SetsModelDB count: \(await SetsModelDB.count())")
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    private func addNewExerciseToBase(_ exerciseModel: ExerciseModel, dataManager: DataManagerBackground) async {
        let item = ExerciseModelDB()
        
        await dataManager.insert(model: item)
        item.index = exerciseModel.index
        item.title = exerciseModel.title
    }
}
