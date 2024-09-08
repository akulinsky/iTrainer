//
//  ExerciseModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation

struct ExerciseModel: DataItemProtocol {
    var id: UUID
    var index: Int
    var title: String?
    var typeId: String
    var isHeadline: Bool
    var restTime: TimeInterval
    
    init(model: ExerciseModelDB) {
        self.id = model.id
        self.index = model.index
        self.title = model.title
        self.typeId = model.typeId
        self.isHeadline = model.isHeadline
        self.restTime = model.restTime ?? 120
    }
    
    init(id: UUID = UUID(),
         index: Int = 0,
         title: String? = nil,
         typeId: String = "",
         isHeadline: Bool = false,
         restTime: TimeInterval = 120) {
        
        self.id = id
        self.index = index
        self.title = title
        self.typeId = typeId
        self.isHeadline = isHeadline
        self.restTime = restTime
    }
}

extension ExerciseModel {
    
    var displayName: String {
        title ?? type?.title ?? ""
    }
    
    var type: ExerciseTypeModel? {
        DataContainer.shared.arrayExercises.filter({ $0.id == typeId }).first
    }
}
