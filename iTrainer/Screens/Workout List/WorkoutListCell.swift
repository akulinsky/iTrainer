//
//  WorkoutListCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct WorkoutListCell: View {
    
    enum Action {
        case update(WorkoutModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    private var model: WorkoutModel
    
    init(model: WorkoutModel, actionBlock: @escaping ActionBlock) {
        self.model = model
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        
        ZStack {
            HStack {
                VStack {
                    Text(model.title ?? "--").leadingAlignment()
                }
            }
            .frame(height: 60)
            
            Button("") {
//                print("DBG_ : \(model.title ?? "--")")
                actionBlock(.update(model))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    WorkoutListCell(model: WorkoutModel(title: "TEST")) { action in }
}
