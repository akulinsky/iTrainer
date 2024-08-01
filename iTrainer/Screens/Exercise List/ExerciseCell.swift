//
//  ExerciseCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseCell: View {
    
    enum Action {
        case update(ExerciseModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    var model: ExerciseModel
    
    init(model: ExerciseModel, actionBlock: @escaping ActionBlock) {
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
    ExerciseCell(model: ExerciseModel(title: "TEST")) { action in }
}
