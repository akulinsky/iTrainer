//
//  WorkoutGroupListModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Alamofire
import Combine

class WorkoutGroupListViewModel: ObservableObject {
    
    @Published var workoutGroups = [WorkoutGroupModel]()
    
    @Published var isShowAlert = false
    
    @Published var isEditGroup = false
    
    var editGroup: WorkoutGroupModel?
    
    var errorMessage: String? = nil
    
    var workout: WorkoutModel
    
    private let networkClient = ServiceNetworkClient()
    
    init(workout: WorkoutModel) {
        self.workout = workout
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchWorkoutGroups(for: workout.id).map { WorkoutGroupModel(model: $0) }
            await MainActor.run {
                workoutGroups = items
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
    
    func edit(group: WorkoutGroupModel) {
        editGroup = group
        isEditGroup = true
    }
    
    func update(name: String) {
        if var editGroup = editGroup {
            editGroup.title = name
            update(item: editGroup)
        } else {
            update(item: WorkoutGroupModel(title: name))
        }
        editGroup = nil
    }
    
    func update(item: WorkoutGroupModel) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(group:item, workoutId: workout.id)
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchWorkoutGroups(for: workout.id)
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
        let item = self.workoutGroups[index]
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeWorkoutGroup(with: item.id)
//            print("DBG_ --------------")
//            print("DBG_  WorkoutModelDB count: \(await WorkoutModelDB.count())")
//            print("DBG_  WorkoutGroupModelDB count: \(await WorkoutGroupModelDB.count())")
//            print("DBG_  ExerciseModelDB count: \(await ExerciseModelDB.count())")
//            print("DBG_  SetsModelDB count: \(await SetsModelDB.count())")
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    private func addNewWorkoutGroupToBase(_ workoutGroupModel: WorkoutGroupModel, dataManager: DataManagerBackground) async {
        let item = WorkoutGroupModelDB()
        
        await dataManager.insert(model: item)
        item.index = workoutGroupModel.index
        item.title = workoutGroupModel.title
    }
}
