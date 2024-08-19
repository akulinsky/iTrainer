//
//  SetsCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct SetsCell: View {
    
    enum Action {
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
        
        ZStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Weight:")
                    .font(.footnote)
                Text(String(format: "%.1f", model.weight ?? 0)).bold()
                Text("x")
                Text("Reps:")
                    .font(.footnote)
                Text("\(model.reps ?? 0)").bold()
            }
            .foregroundStyle(.gray)
            .frame(height: 30)
            
            Button("") {
                actionBlock(.update(model))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SetsCell(model: SetsModel(reps: 10, weight: 100)) { action in }
}
