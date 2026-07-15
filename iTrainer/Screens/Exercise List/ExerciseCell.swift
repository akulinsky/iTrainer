//
//  ExerciseCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

enum ExerciseProgressStatus {
    case active(progress: Double)
    case completed(progress: Double)
    case none
}

struct ExerciseRowContent: View {
    let model: ExerciseModel
    let progressStatus: ExerciseProgressStatus
    var iconSize: CGFloat = 72
    var minHeight: CGFloat = 96
    var showsProgress: Bool = true
    var showsIcon: Bool = true
    var contentPadding = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 8)
    
    var body: some View {
        HStack(spacing: 14) {
            if showsIcon {
                ExerciseTypeIconView(exerciseType: model.type,
                                     size: iconSize,
                                     cornerRadius: 12)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(model.displayName)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                
                if let type = model.type {
                    HStack(alignment: .center, spacing: 8) {
                        Text(type.type.displayName)
                            .font(AppFont.rowSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                        
                        Spacer(minLength: 8)
                        
                        if showsProgress {
                            progressStatusText
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(contentPadding)
        .frame(minHeight: minHeight)
    }
    
    @ViewBuilder
    private var progressStatusText: some View {
        switch progressStatus {
        case .active(let progress):
            Text(progressText(for: progress))
                .font(AppFont.exerciseProgressValue)
                .foregroundStyle(AppColor.progressAmber)
        case .completed(let progress):
            Text(progressText(for: progress))
                .font(AppFont.exerciseProgressValue)
                .foregroundStyle(AppColor.progressGreen)
        case .none:
            EmptyView()
        }
    }
    
    private func progressText(for progress: Double) -> String {
        "\(Int((progress.clampedProgress * 100).rounded()))%"
    }
}

struct ExerciseCell: View {
    
    enum Action {
        case update(ExerciseModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    var model: ExerciseModel
    private let progressStatus: ExerciseProgressStatus
    
    @Environment(\.editMode) var editMode
    
    init(model: ExerciseModel,
         progressStatus: ExerciseProgressStatus = .none,
         actionBlock: @escaping ActionBlock) {
        self.model = model
        self.progressStatus = progressStatus
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        let view = ZStack {
            if model.isHeadlineItem {
                headlineContent
            } else {
                ExerciseRowContent(model: model, progressStatus: progressStatus)
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
    
    private var headlineContent: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        return HStack {
            Text(model.displayName)
                .font(isEditing ? AppFont.rowTitle : AppFont.caption)
                .foregroundStyle(isEditing ? AppColor.textPrimary : AppColor.textSecondary)
                .textCase(.uppercase)
            
            Spacer(minLength: 8)
        }
        .padding(.horizontal, isEditing ? 14 : 4)
        .frame(minHeight: isEditing ? 54 : 28)
        .background {
            if isEditing {
                AppColor.surfacePrimary
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isEditing ? 14 : 0, style: .continuous))
        .overlay {
            if isEditing {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
    }
}

private extension Double {
    var clampedProgress: Double {
        min(max(self, 0), 1)
    }
}
