//
//  WorkoutListModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class WorkoutListViewModel: ObservableObject {
    
    // MARK: - properties
    
    @Published var workouts = [WorkoutModel]()
    
    @Published var isShowAlert = false
    
    @Published var pinnedWorkout: WorkoutModel?
    
    @Published var isEditWorkout = false
    
    var editWorkout: WorkoutModel?
    
    var errorMessage: String? = nil
    
    func setup() {
        
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchAllWorkouts().map { WorkoutModel(model: $0) }
            await MainActor.run {
                workouts = items
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
        reloadData()
    }
    
    func edit(workout: WorkoutModel) {
        editWorkout = workout
        isEditWorkout = true
    }
    
    func update(name: String) {
        if var editWorkout = editWorkout {
            editWorkout.title = name
            update(item: editWorkout)
        } else {
            update(item: WorkoutModel(title: name))
        }
        editWorkout = nil
    }
    
    func update(item: WorkoutModel) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(workout:item)
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func delete(offsets: IndexSet, activeWorkoutGroupId: UUID?, onBlocked: (() -> Void)? = nil) {
        let items = offsets.compactMap { index in
            workouts.indices.contains(index) ? workouts[index] : nil
        }
        guard !items.isEmpty else { return }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            
            if let activeWorkoutGroupId {
                for item in items {
                    let groups = await dataManager.fetchWorkoutGroups(for: item.id)
                    if groups.contains(where: { $0.id == activeWorkoutGroupId }) {
                        await MainActor.run {
                            onBlocked?()
                        }
                        return
                    }
                }
            }
            
            for item in items {
                await dataManager.removeWorkout(with: item.id)
            }
            
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
    
    func delete(index: Int) {
        delete(offsets: IndexSet(integer: index), activeWorkoutGroupId: nil)
    }
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchAllWorkouts()
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
}
