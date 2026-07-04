//
//  ReportsDashboardHeaderView.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import SwiftUI

struct ReportsDashboardHeaderView: View {
    let summary: ReportsMonthSummary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 18) {
                ZStack {
                    Circle()
                        .fill(AppColor.brandPrimary.opacity(0.08))
                    Image(systemName: "calendar")
                        .font(.system(size: 27, weight: .medium))
                        .foregroundStyle(AppColor.brandPrimary)
                }
                .frame(width: 64, height: 64)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(summary.monthTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColor.brandPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColor.brandPrimary)
                    }
                    
                    Text(summary.workoutCountText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                    
                    VStack(alignment: .leading, spacing: 7) {
                        Text(summary.personalRecordCountText)
                        Text(summary.totalVolumeText)
                    }
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
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
}

#Preview {
    ReportsDashboardHeaderView(summary: ReportsMonthSummary(monthTitle: "May 2026",
                                                            workoutCountText: "12 Workouts Completed",
                                                            personalRecordCountText: "3 Personal Records",
                                                            totalVolumeText: "52,400 kg Total Volume"),
                               action: {})
    .padding(20)
    .background(AppColor.backgroundPrimary)
}
