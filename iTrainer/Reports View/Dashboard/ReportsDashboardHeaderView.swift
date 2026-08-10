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
            VStack(spacing: 14) {
                monthRow
                Divider()
                    .background(AppColor.separatorSoft)
                workoutSummary
                Divider()
                    .background(AppColor.separatorSoft)
                bottomMetrics
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
    
    private var monthRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColor.brandPrimary.opacity(0.08))
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColor.brandPrimary)
            }
            .frame(width: 42, height: 42)
            
            HStack(spacing: 6) {
                Text(summary.monthTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.brandPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .layoutPriority(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.brandPrimary)
                    .accessibilityHidden(true)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var workoutSummary: some View {
        VStack(spacing: 5) {
            Text(summary.workoutCountValueText)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .layoutPriority(1)
            
            Text(summary.workoutCountTitleText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }
    
    private var bottomMetrics: some View {
        HStack(alignment: .center, spacing: 0) {
            metricColumn(value: summary.personalRecordValueText,
                         title: summary.personalRecordTitleText,
                         valueColor: AppColor.restAmber)
            
            Rectangle()
                .fill(AppColor.separatorSoft)
                .frame(width: 1)
                .padding(.vertical, 4)
            
            metricColumn(value: summary.totalVolumeValueText,
                         title: summary.totalVolumeTitleText,
                         valueColor: AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func metricColumn(value: String, title: String, valueColor: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .layoutPriority(1)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var accessibilityText: Text {
        Text("\(summary.monthTitle), \(summary.workoutCountValueText) \(summary.workoutCountTitleText), \(summary.personalRecordValueText) \(summary.personalRecordTitleText), \(summary.totalVolumeValueText) \(summary.totalVolumeTitleText)")
    }
}

#Preview {
    ReportsDashboardHeaderView(summary: ReportsMonthSummary(monthTitle: "July 2026",
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
