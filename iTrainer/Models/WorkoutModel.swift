//
//  WorkoutModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation

struct WorkoutModel: DataItemProtocol, Hashable {
    var id: UUID
    var index: Int
    var title: String?
    var isSelected: Bool
    
    init(model: WorkoutModelDB) {
        self.id = model.id
        self.index = model.index
        self.title = model.title
        self.isSelected = model.isSelected
    }
    
    init(id: UUID = UUID(), index: Int = 0, title: String, isSelected: Bool = false) {
        self.id = id
        self.index = index
        self.title = title
        self.isSelected = isSelected
    }
}
