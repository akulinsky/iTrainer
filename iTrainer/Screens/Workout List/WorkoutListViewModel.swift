//
//  WorkoutListModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Alamofire
import Combine

class WorkoutListViewModel: ObservableObject {
    
    //WorkoutModel
    
    // MARK: - properties
    
    @EnvironmentObject var dataContainer: DataContainer
    
    @Published var workouts = [WorkoutModel]()
    
    @Published var isShowAlert = false
    
    @Published var pinnedWorkout: WorkoutModel?
    
    @Published var isEditWorkout = false
    
    var editWorkout: WorkoutModel?
    
    var errorMessage: String? = nil
    
    private let networkClient = ServiceNetworkClient()
    
    func setup() {
//        Task {
//            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
//            let items = await dataManager.fetchAllWorkouts().map { WorkoutModel(model: $0) }
//            await MainActor.run {
//                pinnedWorkout = items[1]
//            }
//        }
        
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
        addTestModels()
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
    
    func delete(index: Int) {
        let item = self.workouts[index]
        Task {
            
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeWorkout(with: item.id)
            
//            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
//            await dataManager.removeWorkout(with: item.id)
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
    
    private func addNewWorkoutToBase(_ workoutModel: WorkoutModel, dataManager: DataManagerBackground) async {
        let item = WorkoutModelDB()
        
        await dataManager.insert(model: item)
        item.index = workoutModel.index
        item.title = workoutModel.title
    }
    
    private func addTestModels() {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            print("DBG_ --------------")
            print("DBG_  WorkoutModelDB was count: \(await WorkoutModelDB.count())")
            print("DBG_  WorkoutGroupModelDB was count: \(await WorkoutGroupModelDB.count())")
            print("DBG_  ExerciseModelDB was count: \(await ExerciseModelDB.count())")
            print("DBG_  SetsModelDB was count: \(await SetsModelDB.count())")
            await dataManager.removeAll(type: WorkoutModelDB.self)
            print("DBG_ --------------")
            print("DBG_  WorkoutModelDB removed count: \(await WorkoutModelDB.count())")
            print("DBG_  WorkoutGroupModelDB removed count: \(await WorkoutGroupModelDB.count())")
            print("DBG_  ExerciseModelDB removed count: \(await ExerciseModelDB.count())")
            print("DBG_  SetsModelDB removed count: \(await SetsModelDB.count())")
            
            for index in 1...5 {
                let item = WorkoutModelDB()
                await dataManager.insert(model: item)
                item.index = index
                item.title = "Workout \(index)"
                
                await addTestGroup(for: item, dataManager: dataManager)
            }
            
            print("DBG_ --------------")
            print("DBG_  WorkoutModelDB now count: \(await WorkoutModelDB.count())")
            print("DBG_  WorkoutGroupModelDB now count: \(await WorkoutGroupModelDB.count())")
            print("DBG_  ExerciseModelDB now count: \(await ExerciseModelDB.count())")
            print("DBG_  SetsModelDB now count: \(await SetsModelDB.count())")
            reloadData()
        }
    }
    
    private func addTestGroup(for workout: WorkoutModelDB, dataManager: DataManagerBackground) async {
        for index in 1...4 {
            let item = WorkoutGroupModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout group \(index)"
            item.workout = workout
            
            await addTestExercise(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestExercise(for group: WorkoutGroupModelDB, dataManager: DataManagerBackground) async {
        for index in 0..<5 {
            let item = ExerciseModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.typeId = DataContainer.shared.arrayExercises[index].id
            item.workoutGroup = group
            
            await addTestSets(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestSets(for exercise: ExerciseModelDB, dataManager: DataManagerBackground) async {
        for index in 1...3 {
            let item = SetsModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.reps = 10 - (index-1)
            item.weight = 50.0 + Float((index-2))*10.0
            item.exercise = exercise
        }
    }
}
