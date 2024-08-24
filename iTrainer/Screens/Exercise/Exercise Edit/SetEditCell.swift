//
//  SetEditCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.08.2024.
//

import SwiftUI
import Combine

struct SetEditCell: View {
    
    enum Action {
        case delete(SetEditCellViewModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var viewModel: SetEditCellViewModel
    
    private var shakeReps = PassthroughSubject<Void, Never>()
    
    private var shakeWeight = PassthroughSubject<Void, Never>()
    
    private var color: Color {
        switch colorScheme {
        case .light:
            Color(UIColor.darkGray)
        default:
            Color(UIColor.lightGray)
        }
    }
    
    init(viewModel: SetEditCellViewModel, actionBlock: @escaping ActionBlock) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        HStack(spacing: 20) {
            
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(height: 30)
                HStack {
                    Text("# \(viewModel.model.index):")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .bold()
                }
            }
            .fixedSize()
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    
                        Text("Weight:")
                            .font(.caption)
                    
                }
                .frame(height: 30)
                .padding([.leading, .trailing])
                .foregroundStyle(.gray)
                
                HStack {
                    TextField("Weight", text: $viewModel.strWeight)
                        .textFieldStyle(AKTextFieldStyle())
                        .shakeAnimation(shakeWeight)
                        .keyboardType(.numberPad)
                        .foregroundStyle(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    
                        Text("Reps:")
                            .font(.caption)
                    
                }
                .frame(height: 30)
                .padding([.leading, .trailing])
                .foregroundStyle(.gray)
                
                HStack {
                    TextField("Reps", text: $viewModel.strReps)
                        .textFieldStyle(AKTextFieldStyle())
                        .shakeAnimation(shakeReps)
                        .keyboardType(.numberPad)
                        .foregroundStyle(color)
                }
                .contentShape(Rectangle())
            }
            
            Button {
                actionBlock(.delete(viewModel))
            } label: {
                
                ZStack {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                            .font(.title3)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
            .foregroundStyle(color)
            .frame(width: 20, height: 40)
            .offset(y: 14.0)
        }
    }
}

#Preview {
    SetEditCell(viewModel: SetEditCellViewModel(model: SetsModel(reps: 10, weight: 50)), actionBlock: {_ in })
}
