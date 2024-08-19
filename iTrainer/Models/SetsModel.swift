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
    
    var reps: Int?
    var weight: Float?
    var distance: Float?
    var timer: Date?
    
    var parameters = [ParameterValue<Any>]()
    
    init(model: SetsModelDB) {
        self.id = model.id
        self.index = model.index
        
        self.reps = model.reps
        self.weight = model.weight
        self.distance = model.distance
        self.timer = model.timer
    }
    
    init(id: UUID = UUID(),
         index: Int = 0,
         reps: Int? = nil,
         weight: Float? = nil,
         distance: Float? = nil,
         timer: Date? = nil) {
        
        self.id = id
        self.index = index
        self.reps = reps
        self.weight = weight
        self.distance = distance
        self.timer = timer
    }
}
