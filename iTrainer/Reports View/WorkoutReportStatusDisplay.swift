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
            count > 1 ? "\(count) New Personal Records" : "New Personal Record"
        case .progress:
            "Progress"
        case .workoutIncomplete:
            "Workout Incomplete"
        case .goalsAchieved:
            "Goals Achieved"
        case .goalsNotAchieved:
            "Goals Not Achieved"
        case .workoutComplete:
            "Workout Complete"
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
