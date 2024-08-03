//
//  SetsModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation

struct SetsModel: DataSetItemProtocol, Identifiable {
    var id: UUID
    var index: Int
    var reps: Int
    var weight: Float
    
    init(model: SetsModelDB) {
        self.id = model.id
        self.index = model.index
        self.reps = model.reps
        self.weight = model.weight
    }
    
    init(id: UUID = UUID(), index: Int = 0, reps: Int, weight: Float) {
        self.id = id
        self.index = index
        self.reps = reps
        self.weight = weight
    }
}
