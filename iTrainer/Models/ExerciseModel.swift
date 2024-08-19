//
//  ExerciseModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation

struct ExerciseModel: DataItemProtocol, Identifiable {
    var id: UUID
    var index: Int
    var title: String?
    var isHeadline: Bool
    
    init(model: ExerciseModelDB) {
        self.id = model.id
        self.index = model.index
        self.title = model.title
        self.isHeadline = model.isHeadline
    }
    
    init(id: UUID = UUID(), index: Int = 0, title: String, isHeadline: Bool = false) {
        self.id = id
        self.index = index
        self.title = title
        self.isHeadline = isHeadline
    }
    
    var displayName: String {
        title ?? "--"
    }
    
}
