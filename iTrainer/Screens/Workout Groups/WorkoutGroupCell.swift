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
            HStack(spacing: 14) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.brandPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title ?? "--")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    
                    Text("Workout group")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
                
                Spacer(minLength: 8)
            }
            .padding(12)
            .frame(minHeight: 76)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            
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
