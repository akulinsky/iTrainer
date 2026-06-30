//
//  SetsModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation

struct SetsModel: DataSetItemProtocol, Equatable, Hashable {
    
    var id: UUID
    var index: Int
    
    var parameters = [SetsParameter]()
    
    init(model: SetsModelDB) {
        self.id = model.id
        self.index = model.index
        
        if let value = model.weight {
            parameters.append(.weight(value))
        }
        
        if let value = model.reps {
            parameters.append(.repeats(value))
        }
        
        if let value = model.distance {
            parameters.append(.distance(value))
        }
        
        if let value = model.time {
            parameters.append(.time(value))
        }
    }
    
    init(id: UUID = UUID(),
         index: Int = 0,
         params: [SetsParameter] = []) {
        
        self.id = id
        self.index = index
        self.parameters = params
    }
}
