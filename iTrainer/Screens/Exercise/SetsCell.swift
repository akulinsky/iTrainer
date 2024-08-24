//
//  SetsCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct SetsCell: View {
    
    enum Action {
        case selected(SetsModel)
        case update(SetsModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    var model: SetsModel
    
    init(model: SetsModel, actionBlock: @escaping ActionBlock) {
        self.model = model
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            Text("# \(model.index):")
                .font(.footnote)
                .bold()
            Text("Weight:")
                .font(.footnote)
            Text(String(format: "%.1f", model.weight ?? 0)).bold()
            
            Text("Reps:")
                .font(.footnote)
            Text("\(model.reps ?? 0)").bold()
            
            Spacer()
            
            Button {
                actionBlock(.update(model))
            } label: {
                
                HStack {
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.title2)
                }
                .contentShape(Rectangle())
            }
            .frame(maxWidth: 50, maxHeight: .infinity, alignment: .trailing)
        }
        .foregroundStyle(.gray)
        .frame(height: 30)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .onTapGesture {
            actionBlock(.selected(model))
        }
    }
}

#Preview {
    SetsCell(model: SetsModel(reps: 10, weight: 100)) { action in }
}
