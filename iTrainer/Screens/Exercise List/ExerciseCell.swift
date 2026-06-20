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
    
    private let frameSize: CGFloat = 80
    
    @Environment(\.editMode) var editMode
    
    init(model: ExerciseModel, actionBlock: @escaping ActionBlock) {
        self.model = model
        self.actionBlock = actionBlock
    }
    
    private var heightCell: CGFloat {
        if model.isHeadline, 
            let editMode = editMode?.wrappedValue,
            editMode != .active {
            return 25
        }
        return frameSize
    }
    
    var body: some View {
        
        let view = ZStack {
            HStack {
                if !model.isHeadline {
                    if let icon = model.type?.icon {
                        icon
                            .resizable()
                            .frame(width: heightCell)
                    } else {
                        Color.red.frame(width: heightCell)
                    }
                }
                VStack {
                    let text = Text(model.displayName).leadingAlignment()
                    if model.isHeadline {
                        text.padding(.leading, 20)
                            .foregroundStyle(.white)
                            .font(.subheadline)
                            .bold()
                            .shadow(color: .black, radius: 1, x: 1.0, y: 1.0)
                    } else {
                        text
                    }
                    
                }
            }
            .frame(height: heightCell)
            
            Button("") {
                actionBlock(.update(model))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        if model.isHeadline {
            view
                .listRowInsets(EdgeInsets.init(top: 0, leading: 0,
                                            bottom: 0, trailing: 0))
                .listRowBackground(Color(uiColor: .systemGray3))
            
        } else {
            view
        }
    }
}

#Preview {
    ExerciseCell(model: ExerciseModel(title: "TEST", typeId: "0")) { action in }
}
