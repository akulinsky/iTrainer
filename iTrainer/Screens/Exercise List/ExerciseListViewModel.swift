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
    
//    func update(person: PersonModelDB) {
//
//    }
    
//    func delete(index: Int) {
//
//    }
    
    private func addNewExerciseToBase(_ exerciseModel: ExerciseModel, dataManager: DataManagerBackground) async {
        let item = ExerciseModelDB()
        
        await dataManager.insert(model: item)
        item.index = exerciseModel.index
        item.title = exerciseModel.title
    }
}
