//
//  ReportExerciseModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation

struct ReportExerciseModel: ReportExerciseDataProtocol {
    
    var id: UUID
    
    var titleExercise: String
    
    var exerciseId: UUID
    
    var index: Int
    
    var typeId: String
    
    init(model: ReportExerciseModelDB) {
        self.id = model.id
        self.titleExercise = model.titleExercise
        self.exerciseId = model.exerciseId
        self.index = model.index
        self.typeId = model.typeId
    }
    
    init(id: UUID = UUID(),
         titleExercise: String,
         exerciseId: UUID,
         index: Int,
         typeId: String) {
        
        self.id = id
        self.titleExercise = titleExercise
        self.exerciseId = exerciseId
        self.index = index
        self.typeId = typeId
    }
}

extension ReportExerciseModel {
    var type: ExerciseTypeModel? {
        DataContainer.shared.arrayExercises.filter({ $0.id == typeId }).first
    }
}
