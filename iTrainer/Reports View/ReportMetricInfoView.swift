//
//  ReportMetricInfoView.swift
//  iTrainer
//
//  Created by OpenAI on 10.07.2026.
//

import SwiftUI

struct ReportMetricInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let formula: String?
    let example: String?
    
    static let volume = ReportMetricInfo(
        id: "volume",
        title: "Volume",
        description: "Total work for weighted sets. It combines weight and repetitions into one number.",
        formula: "Sum of weight x reps for completed sets.",
        example: "80 kg x 10 reps + 70 kg x 8 reps = 1,360 kg"
    )
    
    static let volumeGoal = ReportMetricInfo(
        id: "volume-goal",
        title: "Volume Goal",
        description: "Compares completed volume with planned target volume for weighted exercises. Volume is total weighted work: weight x reps across completed sets.",
        formula: "Actual volume / target volume.",
        example: "Actual 1,360 kg, target 1,500 kg = 91%"
    )
    
    static let density = ReportMetricInfo(
        id: "density",
        title: "Density",
        description: "Shows how much weighted work was completed per minute of workout time.",
        formula: "Total volume / workout duration in minutes.",
        example: "4,800 kg / 40 min = 120 kg/min"
    )
    
    static let pace = ReportMetricInfo(
        id: "pace",
        title: "Pace",
        description: "Shows how long it takes to cover 1 km. Lower pace is better.",
        formula: "Total time / total distance.",
        example: "15:00 / 2 km = 7:30/km"
    )
    
    static let paceGoal = ReportMetricInfo(
        id: "pace-goal",
        title: "Pace Goal",
        description: "Compares actual pace with target pace. Pace is time per 1 km, so lower pace means better performance.",
        formula: "Target pace / actual pace.",
        example: "Target 8:00/km, actual 7:30/km = goal exceeded"
    )
    
    static let recordMetric = ReportMetricInfo(
        id: "record-metric",
        title: "Record Type",
        description: "Shows which metric caused the personal record or progress result.",
        formula: nil,
        example: "Volume means the total weight x reps was higher than before. Pace means the time per km improved."
    )
    
    static let improvement = ReportMetricInfo(
        id: "improvement",
        title: "Improvement",
        description: "Shows the difference between the current result and the previous comparison result.",
        formula: "For most metrics: current - previous. For pace: previous - current because lower pace is better.",
        example: "Previous pace 8:00/km, current 7:30/km = -0:30 improvement"
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
        .accessibilityLabel("About \(info.title)")
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
                
                Button("Done") {
                    dismiss()
                }
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.brandPrimary)
            }
            
            metricInfoBlock(title: "Meaning", text: info.description)
            
            if let formula = info.formula {
                metricInfoBlock(title: "Formula", text: formula)
            }
            
            if let example = info.example {
                metricInfoBlock(title: "Example", text: example)
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
