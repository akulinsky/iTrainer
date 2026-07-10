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
    
    @StateObject var viewModel: SetEditCellViewModel
    
    @State private var updateUI = false
    
    private var focusedInputId: FocusState<String?>.Binding
    
    init(viewModel: SetEditCellViewModel,
         focusedInputId: FocusState<String?>.Binding,
         actionBlock: @escaping ActionBlock) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.focusedInputId = focusedInputId
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image("icTargetSet")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppColor.workoutGreen)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Set \(viewModel.model.index)")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                
                ForEach(viewModel.paramsData) { item in
                    SetEditParameterSummary(viewModel: viewModel, paramId: item.id)
                }
            }
            .frame(minWidth: 92, alignment: .leading)
            
            Spacer(minLength: 6)
            
            HStack(alignment: .center, spacing: 6) {
                ForEach(viewModel.paramsData) { item in
                    SetEditParameterInput(item: item, focusedInputId: focusedInputId) { focused, item, complete in
                        viewModel.focused(focused, paramData: item, complete: complete)
                        updateUI.toggle()
                    }
                }
            }
            
            Button {
                actionBlock(.delete(viewModel))
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppColor.accentCoral)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
}

private struct SetEditParameterSummary: View {
    @ObservedObject var viewModel: SetEditCellViewModel
    let paramId: Int
    
    var body: some View {
        Text(viewModel.summaryText(for: paramId))
            .font(AppFont.rowSubtitle)
            .foregroundStyle(AppColor.textSecondary)
    }
}

private struct SetEditParameterInput: View {
    @ObservedObject var item: SetEditCellViewModel.ParamData
    var focusedInputId: FocusState<String?>.Binding
    let onEditingChanged: (Bool, SetEditCellViewModel.ParamData, (() -> Void)?) -> Void
    
    @State private var updateUI = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if item.value.isEmpty {
                    Text(item.param.title)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .padding(.horizontal, 6)
                        .allowsHitTesting(false)
                }
                
                TextField("", text: $item.value, onEditingChanged: { focused in
                    onEditingChanged(focused, item) {
                        updateUI.toggle()
                    }
                })
                .id(updateUI)
                .textFieldStyle(.plain)
                .font(AppFont.rowTitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, 8)
                .shakeAnimation(item.shake)
                .keyboardType(item.keyboardType)
                .focused(focusedInputId, equals: item.focusId)
            }
            .frame(width: 66, height: 48)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            
            Text(item.param.unitText)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 66, height: 18)
        }
    }
}

#Preview {
    SetEditCellPreview()
}

private struct SetEditCellPreview: View {
    @FocusState private var focusedInputId: String?
    
    var body: some View {
        let category = ExerciseCategory(id: "chest",
                                        titleKey: "exercise.category.chest",
                                        defaultTitle: "Chest",
                                        devTitle: "Грудь",
                                        kind: "muscleGroup",
                                        iconName: "icMissingImage",
                                        sortOrder: 0)
        SetEditCell(viewModel: SetEditCellViewModel(model: SetsModel(params: [.weight(50), .repeats(10)]),
                                                    exerciseType: ExerciseTypeModel(devTitle: "Test",
                                                                                    type: category,
                                                                                    parameters: [.weight(), .repeats()])),
                    focusedInputId: $focusedInputId,
                    actionBlock: {_ in })
    }
}
