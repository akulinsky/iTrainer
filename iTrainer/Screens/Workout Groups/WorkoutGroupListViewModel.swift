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
    
    @EnvironmentObject var dataContainer: DataContainer
    
    @Published var workoutGroups = [WorkoutGroupModel]()
    
    @Published var isShowAlert = false
    
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
    
//    func update(person: PersonModelDB) {
//
//    }
    
//    func delete(index: Int) {
//
//    }
    
    private func addNewWorkoutGroupToBase(_ workoutGroupModel: WorkoutGroupModel, dataManager: DataManagerBackground) async {
        let item = WorkoutGroupModelDB()
        
        await dataManager.insert(model: item)
        item.index = workoutGroupModel.index
        item.title = workoutGroupModel.title
    }
}
