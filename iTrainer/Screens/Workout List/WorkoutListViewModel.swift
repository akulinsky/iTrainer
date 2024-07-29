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
    @EnvironmentObject var dataContainer: DataContainer
    
    @Published var workouts = [WorkoutModel]()
    
    @Published var isShowAlert = false
    
    var errorMessage: String? = nil
    
    private let networkClient = ServiceNetworkClient()
    
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
    
//    func update(person: PersonModelDB) {
//
//    }
    
//    func delete(index: Int) {
//
//    }
    
    private func addNewWorkoutToBase(_ workoutModel: WorkoutModel, dataManager: DataManagerBackground) async {
        let item = WorkoutModelDB()
        
        await dataManager.insert(model: item)
        item.index = workoutModel.index
        item.title = workoutModel.title
    }
    
    private func addTestModels() {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            print("DBG_  WorkoutModelDB was count: \(await WorkoutModelDB.count())")
            print("DBG_  WorkoutGroupModelDB was count: \(await WorkoutGroupModelDB.count())")
            print("DBG_  ExerciseModelDB was count: \(await ExerciseModelDB.count())")
            print("DBG_  SetsModelDB was count: \(await SetsModelDB.count())")
            await dataManager.removeAll(type: WorkoutModelDB.self)
            await dataManager.removeAll(type: WorkoutGroupModelDB.self)
            await dataManager.removeAll(type: ExerciseModelDB.self)
            await dataManager.removeAll(type: SetsModelDB.self)
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
            
            print("DBG_  WorkoutModelDB now count: \(await WorkoutModelDB.count())")
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
        for index in 1...5 {
            let item = ExerciseModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Exercise \(index)"
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
            item.weight = 50 + (index-2)*10
            item.exercise = exercise
        }
    }
}
