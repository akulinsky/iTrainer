//
//  ExerciseTypeViewModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.08.2024.
//

import Foundation
import Combine

enum ExerciseTypeViewMode: Int {
    case showing, selecting
}

typealias SelectedExerciseTypesBlock = (Set<String>)->()

class ExerciseTypeViewModel: ObservableObject {
    
    @Published var categories = [ExerciseCategory]()
    
    @Published var exercises = [ExerciseTypeModel]()
    
    @Published var searchQuery = ""
    
    @Published var searchQueryExercise = ""
    
    @Published var countSelectedExercises = 0
    
    let mode: ExerciseTypeViewMode
    
    var categoryId: Int?
    
    var categoryTitle: String {
        guard let categoryId = self.categoryId, 
                let category = ExerciseCategory(rawValue: categoryId) else {
            return ""
        }
        return category.title
    }
    
    private var completeBlock: SelectedExerciseTypesBlock?
    
    private var selectionExercises = Set<String>()
    
    private var cancellable = Set<AnyCancellable>()
    
//    private var arrayExercises = ExerciseTypeModel.createExercises
    private var arrayExercises = [ExerciseTypeModel]()
    
    init(mode: ExerciseTypeViewMode = .showing, completeBlock: (SelectedExerciseTypesBlock)? = nil) {
        categories = ExerciseCategory.allCases
        
        self.mode = mode
        
        self.completeBlock = completeBlock
        
        $searchQuery.sink { search in
            self.fetchItems()
        }
        .store(in: &cancellable)
        
        $searchQueryExercise.sink { search in
            self.fetchItems()
        }
        .store(in: &cancellable)
        
        DataContainer.shared.$arrayExercises.sink(receiveValue: { array in
            self.arrayExercises = array
            self.fetchItems()
        })
        .store(in: &cancellable)
    }
    
    private func fetchItems() {
        
//        Task {
//            
//            var result: [ExerciseTypeModel] = []
//            
//            if let categoryId = self.categoryId,
//               let category = ExerciseCategory(rawValue: categoryId) {
//                result = ExerciseTypeModel.createExercises.filter {
//                    $0.type == category
//                }
//            }
//            
//            if !searchQuery.isEmpty {
//                result = ExerciseTypeModel.createExercises
//                
////                result = ExerciseTypeModel.createExercises.filter {
////                    $0.title.lowercased().contains(searchQuery.lowercased())
////                }
//            } else if !searchQueryExercise.isEmpty, !result.isEmpty {
//                result = ExerciseTypeModel.createExercises
//                
////                result = result.filter {
////                    $0.title.lowercased().contains(searchQueryExercise.lowercased())
////                }
//            }
//            
//            await MainActor.run { [result] in
//                self.exercises = result
//            }
//        }
        
        
        var result: [ExerciseTypeModel] = []
        
        if let categoryId = self.categoryId,
           let category = ExerciseCategory(rawValue: categoryId) {
            result = arrayExercises.filter {
                $0.type == category
            }
        }
        
        if !searchQuery.isEmpty {
            result = arrayExercises.filter {
                $0.title.lowercased().contains(searchQuery.lowercased())
            }
        } else if !searchQueryExercise.isEmpty, !result.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(searchQueryExercise.lowercased())
            }
        }
        
        self.exercises = result
    }
    
    func reloadExercises() {
        fetchItems()
    }
    
    func toggleSelectExercise(with id: String) {
        
        if selectionExercises.contains(id) {
            selectionExercises.remove(id)
        } else {
            selectionExercises.insert(id)
        }
        
        countSelectedExercises = selectionExercises.count
    }
    
    func isSelectedExercise(with id: String) -> Bool {
        selectionExercises.contains(id)
    }
    
    func clearSelectedExercise() {
        print("DBG_ clear exercises")
        selectionExercises.removeAll()
        countSelectedExercises = selectionExercises.count
    }
    
    func addExercise() {
        print("DBG_ ADD \(selectionExercises.count) exercise !!!!")
        if let completeBlock = completeBlock {
            completeBlock(selectionExercises)
        }
//        clearSelectedExercise()
    }
}
