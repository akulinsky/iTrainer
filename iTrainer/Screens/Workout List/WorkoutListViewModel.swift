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
    
    // MARK: - properties
    
    @Published var workouts = [WorkoutModel]()
    
    @Published var isShowAlert = false
    
    @Published var pinnedWorkout: WorkoutModel?
    
    @Published var isEditWorkout = false
    
    var editWorkout: WorkoutModel?
    
    var errorMessage: String? = nil
    
    private let networkClient = ServiceNetworkClient()
    
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
            
            await dataManager.removeAll(type: WorkoutModelDB.self)
            await dataManager.removeAll(type: WorkoutGroupModelDB.self)
            await dataManager.removeAll(type: ExerciseModelDB.self)
            await dataManager.removeAll(type: SetsModelDB.self)
            
            await dataManager.removeAll(type: ReportWorkoutModelDB.self)
            await dataManager.removeAll(type: ReportExerciseModelDB.self)
            await dataManager.removeAll(type: ReportSetsModelDB.self)
            
            await addTestWorkout(dataManager: dataManager)
            await dataManager.save()
            
            print("DBG_ --------------")
            print("DBG_  WorkoutModelDB count: \(await WorkoutModelDB.count())")
            print("DBG_  WorkoutGroupModelDB count: \(await WorkoutGroupModelDB.count())")
            print("DBG_  ExerciseModelDB count: \(await ExerciseModelDB.count())")
            print("DBG_  SetsModelDB count: \(await SetsModelDB.count())")
            
            print("DBG_  ReportWorkoutModelDB: \(await ReportWorkoutModelDB.count())")
            print("DBG_  ReportExerciseModelDB: \(await ReportExerciseModelDB.count())")
            print("DBG_  ReportSetsModelDB: \(await ReportSetsModelDB.count())")
            print("DBG_  SetsModelDB count: \(await SetsModelDB.count())")
            
            reloadData()
        }
    }
    
    private func addTestWorkout(dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = WorkoutModelDB()
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout \(index)"
            
            await addTestGroup(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestGroup(for workout: WorkoutModelDB, dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = WorkoutGroupModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout group \(index)"
            item.workout = workout
            
            await addTestExercise(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestExercise(for group: WorkoutGroupModelDB, dataManager: DataManagerBackground) async {
        for index in 0..<DataContainer.shared.arrayExercises.count {
            let item = ExerciseModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.typeId = DataContainer.shared.arrayExercises[index].id
            item.workoutGroup = group
            
            await addTestSets(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestSets(for exercise: ExerciseModelDB, dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = SetsModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            let typeExercise = DataContainer.shared.arrayExercises.first { $0.id == exercise.typeId }
            for param in typeExercise!.parameters {
                switch param {
                case .weight(_):
                    item.weight = 50.0 + Float((index-2))*10.0
                case .repeats(_):
                    item.reps = 10 - (index-1)
                case .distance(_):
                    item.distance = 500 * Float(index)
                case .time(_):
                    item.time = TimeInterval(60 * index)
                }
            }
            
            item.exercise = exercise
        }
    }
}
