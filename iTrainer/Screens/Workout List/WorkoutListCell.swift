//
//  WorkoutListCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct WorkoutListCell: View {
    
    enum Action {
        case update(WorkoutModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    private var model: WorkoutModel
    
    init(model: WorkoutModel, actionBlock: @escaping ActionBlock) {
        self.model = model
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        
        ZStack {
            HStack(spacing: 14) {
                Image(systemName: "list.bullet.rectangle.fill")
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
                    
                    Text(model.isSelected ? "workouts.selected_plan" : "workouts.workout_plan")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                }
                
                Spacer(minLength: 8)
                
                if model.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColor.brandPrimary)
                }
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
    WorkoutListCell(model: WorkoutModel(title: "TEST")) { action in }
}
