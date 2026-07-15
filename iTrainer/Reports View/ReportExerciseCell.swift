//
//  ReportExerciseCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.09.2024.
//

import SwiftUI

extension ExerciseReportStatus {
    var title: String {
        switch self {
        case .personalRecord:
            "New Personal Record"
        case .progress:
            "Progress"
        case .goalAchieved:
            "Goal Achieved"
        case .goalMissed:
            "Goal Missed"
        case .complete:
            "Complete"
        }
    }
    
    var systemImage: String {
        switch self {
        case .personalRecord:
            "trophy.fill"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .goalAchieved, .complete:
            "checkmark.circle"
        case .goalMissed:
            "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .personalRecord:
            AppColor.restAmber
        case .progress, .goalAchieved, .complete:
            AppColor.progressGreen
        case .goalMissed:
            AppColor.progressRed
        }
    }
}

struct ReportExerciseCell: View {
    
    var model: ReportExerciseModel
    var status: ExerciseReportStatus
    var childStatusById: [UUID: ExerciseReportStatus]
    var onChildTap: ((ReportExerciseModel) -> Void)?
    
    private let iconSize: CGFloat = 72
    private var children: [ReportExerciseModel] {
        model.sortedSupersetExercises
    }
    
    init(model: ReportExerciseModel,
         status: ExerciseReportStatus = .complete,
         childStatusById: [UUID: ExerciseReportStatus] = [:],
         onChildTap: ((ReportExerciseModel) -> Void)? = nil) {
        self.model = model
        self.status = status
        self.childStatusById = childStatusById
        self.onChildTap = onChildTap
    }
    
    var body: some View {
        if model.isSupersetItem {
            supersetCell
        } else {
            exerciseRow(model: model,
                        status: status,
                        backgroundColor: AppColor.surfacePrimary)
        }
    }
    
    private var supersetCell: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(model.titleExercise)
                    .font(AppFont.workoutGroupCardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            
            if children.isEmpty {
                Text("No exercises")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.horizontal, 4)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ReportSupersetPathIcon(height: childConnectorHeight)
                        .frame(width: 32)
                        .padding(.top, 28)
                    
                    VStack(spacing: 10) {
                        ForEach(children) { child in
                            Button {
                                onChildTap?(child)
                            } label: {
                                exerciseRow(model: child,
                                            status: childStatusById[child.id] ?? .complete,
                                            iconSize: 62,
                                            minHeight: 84,
                                            backgroundColor: AppColor.backgroundPrimary,
                                            cornerRadius: 12,
                                            contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 8))
                            }
                            .buttonStyle(.plain)
                            .disabled(onChildTap == nil)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private func exerciseRow(model: ReportExerciseModel,
                             status: ExerciseReportStatus,
                             iconSize: CGFloat = 72,
                             minHeight: CGFloat = 96,
                             backgroundColor: Color,
                             cornerRadius: CGFloat = 14,
                             contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) -> some View {
        HStack(spacing: 14) {
            ExerciseTypeIconView(exerciseType: model.type,
                                 size: iconSize,
                                 cornerRadius: 12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(model.titleExercise)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                
                HStack(spacing: 8) {
                    Image(systemName: status.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(status.title)
                        .font(AppFont.rowSubtitle)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(status.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(contentPadding)
        .frame(minHeight: minHeight)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var childConnectorHeight: CGFloat {
        guard children.count > 1 else { return 32 }
        return CGFloat(children.count - 1) * 94 + 32
    }
}

private struct ReportSupersetPathIcon: View {
    let height: CGFloat
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(AppColor.brandPrimary)
                .frame(width: 3, height: max(height - 16, 12))
            
            VStack {
                Circle()
                    .fill(AppColor.brandPrimary)
                    .frame(width: 12, height: 12)
                Spacer(minLength: 0)
                Circle()
                    .fill(AppColor.brandPrimary)
                    .frame(width: 12, height: 12)
            }
            .frame(height: height)
        }
    }
}

#Preview {
    ReportExerciseCell(model: ReportExerciseModel(titleExercise: "Title",
                                                  exerciseId: UUID(),
                                                  index: 1,
                                                  typeId: ""),
                       status: .goalMissed)
}
