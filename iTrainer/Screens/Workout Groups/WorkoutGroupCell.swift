//
//  WorkoutGroupCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

enum WorkoutGroupStatus {
    case active
    case lastCompleted
    case normal
}

struct WorkoutGroupCell: View {
    
    enum Action {
        case update(WorkoutGroupModel)
        case cancel
    }
    
    typealias ActionBlock = (Action)->()
    
    private var actionBlock: ActionBlock
    
    var model: WorkoutGroupModel
    private let progress: Double
    private let status: WorkoutGroupStatus
    private let exerciseCount: Int
    
    init(model: WorkoutGroupModel,
         progress: Double = 0,
         status: WorkoutGroupStatus = .normal,
         exerciseCount: Int = 0,
         actionBlock: @escaping ActionBlock) {
        self.model = model
        self.progress = progress
        self.status = status
        self.exerciseCount = exerciseCount
        self.actionBlock = actionBlock
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 18) {
                progressRing
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.title ?? "--")
                        .font(AppFont.workoutGroupCardTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    
                    HStack(alignment: .center, spacing: 8) {
                        Text(exercisesText)
                            .font(AppFont.workoutGroupCardSubtitle)
                            .foregroundStyle(AppColor.textSecondary)
                        
                        Spacer(minLength: 8)
                        
                        statusBadge
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.init(top: 16, leading: 16, bottom: 16, trailing: 8))
            .frame(minHeight: 114)
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
    
    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AppColor.progressTrack, lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: progress.clampedProgress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(progressPercent)%")
                .font(AppFont.workoutGroupProgressValue)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 72, height: 72)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .active:
            Text("Active")
                .font(AppFont.workoutGroupStatus)
                .foregroundStyle(AppColor.progressAmber)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppColor.progressAmber.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .lastCompleted:
            Text("Last")
                .font(AppFont.workoutGroupStatus)
                .foregroundStyle(AppColor.progressGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppColor.progressGreen.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        case .normal:
            EmptyView()
        }
    }
    
    private var exercisesText: String {
        "\(exerciseCount) exercises"
    }
    
    private var progressPercent: Int {
        Int((progress.clampedProgress * 100).rounded())
    }
    
    private var progressColor: Color {
        switch progressPercent {
        case 0:
            AppColor.progressTrack
        case 1...32:
            AppColor.progressRed
        case 33...65:
            AppColor.progressAmber
        default:
            AppColor.progressGreen
        }
    }
}

#Preview {
    WorkoutGroupCell(model: WorkoutGroupModel(title: "Push Day"),
                     progress: 0.64,
                     status: .active,
                     exerciseCount: 6) { action in }
}

private extension Double {
    var clampedProgress: Double {
        min(max(self, 0), 1)
    }
}
