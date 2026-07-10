//
//  ReportMetricInfoView.swift
//  iTrainer
//
//  Created by OpenAI on 10.07.2026.
//

import SwiftUI

private func reportMetricLocalized(_ key: String) -> String {
    String(localized: String.LocalizationValue(key))
}

private func reportMetricLocalizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: reportMetricLocalized(key), arguments: arguments)
}

struct ReportMetricInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let formula: String?
    let example: String?
    
    static let volume = ReportMetricInfo(
        id: "volume",
        title: reportMetricLocalized("report.metric.volume.title"),
        description: reportMetricLocalized("report.metric.volume.description"),
        formula: reportMetricLocalized("report.metric.volume.formula"),
        example: reportMetricLocalized("report.metric.volume.example")
    )
    
    static let volumeGoal = ReportMetricInfo(
        id: "volume-goal",
        title: reportMetricLocalized("report.metric.volume_goal.title"),
        description: reportMetricLocalized("report.metric.volume_goal.description"),
        formula: reportMetricLocalized("report.metric.volume_goal.formula"),
        example: reportMetricLocalized("report.metric.volume_goal.example")
    )
    
    static let density = ReportMetricInfo(
        id: "density",
        title: reportMetricLocalized("report.metric.density.title"),
        description: reportMetricLocalized("report.metric.density.description"),
        formula: reportMetricLocalized("report.metric.density.formula"),
        example: reportMetricLocalized("report.metric.density.example")
    )
    
    static let pace = ReportMetricInfo(
        id: "pace",
        title: reportMetricLocalized("report.metric.pace.title"),
        description: reportMetricLocalized("report.metric.pace.description"),
        formula: reportMetricLocalized("report.metric.pace.formula"),
        example: reportMetricLocalized("report.metric.pace.example")
    )
    
    static let paceGoal = ReportMetricInfo(
        id: "pace-goal",
        title: reportMetricLocalized("report.metric.pace_goal.title"),
        description: reportMetricLocalized("report.metric.pace_goal.description"),
        formula: reportMetricLocalized("report.metric.pace_goal.formula"),
        example: reportMetricLocalized("report.metric.pace_goal.example")
    )
    
    static let recordMetric = ReportMetricInfo(
        id: "record-metric",
        title: reportMetricLocalized("report.metric.record_type.title"),
        description: reportMetricLocalized("report.metric.record_type.description"),
        formula: nil,
        example: reportMetricLocalized("report.metric.record_type.example")
    )
    
    static let improvement = ReportMetricInfo(
        id: "improvement",
        title: reportMetricLocalized("report.metric.improvement.title"),
        description: reportMetricLocalized("report.metric.improvement.description"),
        formula: reportMetricLocalized("report.metric.improvement.formula"),
        example: reportMetricLocalized("report.metric.improvement.example")
    )
}

struct MetricInfoButton: View {
    let info: ReportMetricInfo
    let size: CGFloat
    let iconSize: CGFloat
    @State private var isPresented = false
    
    init(info: ReportMetricInfo, size: CGFloat = 32, iconSize: CGFloat = 17) {
        self.info = info
        self.size = size
        self.iconSize = iconSize
    }
    
    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reportMetricLocalizedFormat("report.metric.info.accessibility.about", info.title))
        .sheet(isPresented: $isPresented) {
            MetricInfoSheet(info: info)
                .presentationDetents([.height(330)])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct MetricInfoSheet: View {
    let info: ReportMetricInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                Text(info.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppColor.brandPrimary)
                
                Spacer(minLength: 12)
                
                Button(reportMetricLocalized("report.metric.info.done")) {
                    dismiss()
                }
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.brandPrimary)
            }
            
            metricInfoBlock(title: reportMetricLocalized("report.metric.info.meaning"), text: info.description)
            
            if let formula = info.formula {
                metricInfoBlock(title: reportMetricLocalized("report.metric.info.formula"), text: formula)
            }
            
            if let example = info.example {
                metricInfoBlock(title: reportMetricLocalized("report.metric.info.example"), text: example)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .background(AppColor.backgroundPrimary)
    }
    
    private func metricInfoBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .textCase(.uppercase)
            
            Text(text)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
