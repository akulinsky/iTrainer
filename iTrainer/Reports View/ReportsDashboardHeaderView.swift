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
                    
                    summaryLine(value: summary.workoutCountValueText,
                                title: summary.workoutCountTitleText,
                                color: AppColor.progressGreen)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    
                    VStack(alignment: .leading, spacing: 7) {
                        summaryLine(value: summary.personalRecordValueText,
                                    title: summary.personalRecordTitleText,
                                    color: AppColor.restAmber)
                        summaryLine(value: summary.totalVolumeValueText,
                                    title: summary.totalVolumeTitleText,
                                    color: AppColor.textSecondary)
                    }
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
    
    private func summaryLine(value: String, title: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
            Text(title)
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundStyle(color)
    }
}

#Preview {
    ReportsDashboardHeaderView(summary: ReportsMonthSummary(monthTitle: "May 2026",
                                                            workoutCountValueText: "12",
                                                            workoutCountTitleText: "Workouts Completed",
                                                            personalRecordValueText: "3",
                                                            personalRecordTitleText: "Personal Records",
                                                            totalVolumeValueText: "52,400 kg",
                                                            totalVolumeTitleText: "Total Volume"),
                               action: {})
    .padding(20)
    .background(AppColor.backgroundPrimary)
}
