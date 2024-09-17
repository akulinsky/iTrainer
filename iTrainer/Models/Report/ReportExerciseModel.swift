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
    
    var date: Date?
    
    var sets = [ReportSetsModel]()
    
    init(model: ReportExerciseModelDB) {
        self.id = model.id
        self.titleExercise = model.titleExercise
        self.exerciseId = model.exerciseId
        self.index = model.index
        self.typeId = model.typeId
        self.date = model.report?.startDate
        
        self.sets = model.reportSets.map { ReportSetsModel(model: $0) }.sorted(by: { $0.date > $1.date })
        for (idx, _) in self.sets.enumerated() {
            self.sets[idx].index = self.sets.count - idx
        }
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
