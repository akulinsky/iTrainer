//
//  WorkoutReportStatusDisplay.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import SwiftUI

struct WorkoutReportStatusDisplay: Hashable {
    let title: String
    let systemImage: String
    let color: Color
}

extension WorkoutReportStatus {
    var display: WorkoutReportStatusDisplay {
        WorkoutReportStatusDisplay(title: title,
                                   systemImage: systemImage,
                                   color: color)
    }
    
    var title: String {
        switch self {
        case .personalRecord(let count):
            count > 1
                ? String.localizedStringWithFormat(String(localized: "reports.workout_status.personal_records"), count)
                : String(localized: "reports.workout_status.personal_record")
        case .progress:
            String(localized: "reports.workout_status.progress")
        case .workoutIncomplete:
            String(localized: "reports.workout_status.incomplete")
        case .goalsAchieved:
            String(localized: "reports.workout_status.goals_achieved")
        case .goalsNotAchieved:
            String(localized: "reports.workout_status.goals_not_achieved")
        case .workoutComplete:
            String(localized: "reports.workout_status.complete")
        }
    }
    
    var systemImage: String {
        switch self {
        case .personalRecord:
            "trophy.fill"
        case .progress:
            "chart.line.uptrend.xyaxis"
        case .goalsAchieved, .workoutComplete:
            "checkmark.circle.fill"
        case .goalsNotAchieved, .workoutIncomplete:
            "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .personalRecord:
            AppColor.restAmber
        case .progress, .goalsAchieved, .workoutComplete:
            AppColor.progressGreen
        case .goalsNotAchieved:
            AppColor.progressRed
        case .workoutIncomplete:
            AppColor.progressAmber
        }
    }
}
