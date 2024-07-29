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
    
//    func update(person: PersonModelDB) {
//
//    }
    
//    func delete(index: Int) {
//
//    }
    
    private func addNewExerciseToBase(_ setsModel: SetsModel, dataManager: DataManagerBackground) async {
        let item = SetsModelDB()
        
        await dataManager.insert(model: item)
        item.index = setsModel.index
        item.reps = setsModel.reps
        item.weight = setsModel.weight
    }
}
