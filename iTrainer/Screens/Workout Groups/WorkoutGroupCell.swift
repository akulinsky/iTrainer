//
//  WorkoutGroupCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct WorkoutGroupCell: View {
    
    enum Action {
        case update(WorkoutGroupModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    var model: WorkoutGroupModel
    
    init(model: WorkoutGroupModel, actionBlock: @escaping ActionBlock) {
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
    WorkoutGroupCell(model: WorkoutGroupModel(title: "TEST")) { action in }
}
