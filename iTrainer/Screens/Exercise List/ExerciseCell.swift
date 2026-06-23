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
    
    private let iconSize: CGFloat = 72
    
    @Environment(\.editMode) var editMode
    
    init(model: ExerciseModel, actionBlock: @escaping ActionBlock) {
        self.model = model
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        let view = ZStack {
            if model.isHeadline, editMode?.wrappedValue != .active {
                HStack {
                    Text(model.displayName)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .textCase(.uppercase)
                    
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 4)
                .frame(minHeight: 28)
            } else {
                HStack(spacing: 14) {
                    if !model.isHeadline {
                        if let icon = model.type?.icon {
                            icon
                                .resizable()
                                .scaledToFill()
                                .frame(width: iconSize, height: iconSize)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            Image("icMissingImage")
                                .resizable()
                                .scaledToFill()
                                .frame(width: iconSize, height: iconSize)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.displayName)
                            .font(AppFont.rowTitle)
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)
                        
                        if let type = model.type {
                            Text(type.type.displayName)
                                .font(AppFont.rowSubtitle)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    
                    Spacer(minLength: 8)
                }
                .padding(12)
                .frame(minHeight: 96)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColor.separatorSoft, lineWidth: 1)
                }
            }
            
            Button("") {
                actionBlock(.update(model))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        view
    }
}

#Preview {
    ExerciseCell(model: ExerciseModel(title: "TEST", typeId: "0")) { action in }
}
