//
//  ReportSetsModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation

struct ReportSetsModel: ReportSetDataProtocol {
    
    var id: UUID
    
    var date: Date
    
    var parameters = [SetsParameter]()
    
    init(model: ReportSetsModelDB) {
        self.id = model.id
        self.date = model.date
        
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
         date: Date,
         params: [SetsParameter] = []) {
        
        self.id = id
        self.date = date
        self.parameters = params
    }
}
