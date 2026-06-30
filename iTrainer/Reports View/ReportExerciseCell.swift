//
//  ReportExerciseCell.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.09.2024.
//

import SwiftUI

enum ReportExerciseStatus {
    case personalRecord
    case progress
    case goalAchieved
    case goalMissed
    case complete
    
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
    var status: ReportExerciseStatus
    
    private let iconSize: CGFloat = 72
    
    init(model: ReportExerciseModel,
         status: ReportExerciseStatus = .complete) {
        self.model = model
        self.status = status
    }
    
    var body: some View {
        HStack(spacing: 14) {
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
        .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
        .frame(minHeight: 96)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
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
