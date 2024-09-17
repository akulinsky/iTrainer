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
    
    @Published var exercises = [ExerciseModel]()
    
    @Published var isShowAlert = false
    
    @Published var isEditExercise = false
    
    @Published var isAddNewExercise = false
    
    var editExercise: ExerciseModel?
    
    var errorMessage: String? = nil
    
    var group: WorkoutGroupModel
    
    var isEditHeadline = false
    
    private let networkClient = ServiceNetworkClient()
    
    init(group: WorkoutGroupModel) {
        self.group = group
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchExercises(for: group.id).map { ExerciseModel(model: $0) }
            
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
        if exercise.isHeadline {
            isEditHeadline = true
        }
        isEditExercise = true
    }
    
    func addNewExercises(with typeIDs: Set<String>) {
        update(items: typeIDs.map { ExerciseModel(typeId: $0, isHeadline: false) })
    }
    
    func update(name: String) {
        if var editExercise = editExercise {
            editExercise.title = name
            update(items: [editExercise])
        } else {
            update(items: [ExerciseModel(title: name, isHeadline: self.isEditHeadline)])
        }
        editExercise = nil
        self.isEditHeadline = false
    }
    
    private func update(items: [ExerciseModel]) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(exercises: items, groupId: group.id)
        }
    }
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchExercises(for: group.id)
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
    
    private func addNewExerciseToBase(_ exerciseModel: ExerciseModel, dataManager: DataManagerBackground) async {
        let item = ExerciseModelDB()
        
        await dataManager.insert(model: item)
        item.index = exerciseModel.index
        item.title = exerciseModel.title
    }
}
