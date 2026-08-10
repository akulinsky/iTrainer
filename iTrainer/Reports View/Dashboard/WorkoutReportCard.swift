//
//  WorkoutReportCard.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import SwiftUI

struct WorkoutReportCard: View {
    let item: WorkoutReportCardItem
    let action: () -> Void
    
    private var statusDisplay: WorkoutReportStatusDisplay {
        item.status.display
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    
                    Text(item.groupTitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(systemImage: "calendar", text: item.dateText)
                        infoRow(systemImage: "clock", text: item.timeText)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 16)
                
                statusRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var statusRow: some View {
        HStack(spacing: 12) {
            Image(systemName: statusDisplay.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 28)
            Text(statusDisplay.title)
                .font(.system(size: 17, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(statusDisplay.color)
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(statusDisplay.color.opacity(0.08))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(statusDisplay.color.opacity(0.22))
                .frame(height: 1)
        }
    }
    
    private func infoRow(systemImage: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24)
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(AppColor.textSecondary)
    }
}

#Preview {
    WorkoutReportCard(item: WorkoutReportCardItem(id: UUID(),
                                                  report: ReportWorkoutModel(id: UUID(),
                                                                             titleWorkout: "Heavy Workout",
                                                                             workoutId: UUID(),
                                                                             titleWorkoutGroup: "Chest & Back",
                                                                             workoutGroupId: UUID()),
                                                  title: "Heavy Workout",
                                                  groupTitle: "Chest & Back",
                                                  dateText: "Thursday, May 28, 2026",
                                                  timeText: "18:42 – 19:31 • 49 min",
                                                  status: .personalRecord(count: 1)),
                      action: {})
    .padding(20)
    .background(AppColor.backgroundPrimary)
}
