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
    
    @State private var updateUI = false
    
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
                        .frame(width: 35)
                }
            }
            .fixedSize()
            
            ForEach($viewModel.paramsData) { $item in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(item.param.title): \(item.value)")
                                .font(.caption)
                        
                    }
                    .frame(height: 30)
                    .padding([.leading, .trailing])
                    .foregroundStyle(.gray)
                    
                    HStack {
                        TextField(item.param.title, text: $item.value, onEditingChanged: { focused in
                            self.viewModel.focused(focused, paramData: item) {
                                self.updateUI.toggle()
                            }
                        })
                        .id(updateUI)
                        .textFieldStyle(AKTextFieldStyle())
                        .shakeAnimation(item.shake)
                        .keyboardType(item.keyboardType)
//                        .foregroundStyle(color)
                    }
                }
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
    SetEditCell(viewModel: SetEditCellViewModel(model: SetsModel(params: [.weight(50), .repeats(10)]),
                                                exerciseType: ExerciseTypeModel(title: "Test",
                                                                                type: .chest,
                                                                                parameters: [.weight(), .repeats()])), actionBlock: {_ in })
}
