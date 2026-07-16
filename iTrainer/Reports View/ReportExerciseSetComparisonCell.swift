//
//  ReportExerciseSetComparisonCell.swift
//  iTrainer
//
//  Created by OpenAI on 01.07.2026.
//

import SwiftUI

struct ReportExerciseSetComparisonCell: View {
    let row: ReportExerciseViewModel.SetComparisonRow
    let isHeader: Bool
    
    init(row: ReportExerciseViewModel.SetComparisonRow, isHeader: Bool = false) {
        self.row = row
        self.isHeader = isHeader
    }
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .frame(width: 34)
            
            Text(row.title)
                .font(isHeader ? AppFont.caption : .system(size: 16, weight: .semibold))
                .foregroundStyle(isHeader ? AppColor.textSecondary : AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            valueText(row.target, color: AppColor.textSecondary, alignment: .leading)
            
            valueText(row.result, color: resultColor, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, isHeader ? 12 : 14)
        .frame(minHeight: isHeader ? 44 : 62)
    }
    
    @ViewBuilder
    private func valueText(_ value: String, color: Color, alignment: Alignment) -> some View {
        if !isHeader, let lines = distanceTimeLines(from: value) {
            VStack(alignment: horizontalAlignment(for: alignment), spacing: 2) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .lineLimit(1)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: alignment)
        } else {
            Text(value)
                .font(isHeader ? AppFont.caption : .system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: alignment)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
    
    private func distanceTimeLines(from value: String) -> [String]? {
        let parts = value.components(separatedBy: " · ")
        guard parts.count == 2,
              isDistanceText(parts[0]),
              parts[1].contains(":") else {
            return nil
        }
        return parts
    }
    
    private func isDistanceText(_ value: String) -> Bool {
        value.hasSuffix(" m") || value.hasSuffix(" km") || value.hasSuffix(" ft") || value.hasSuffix(" mi")
    }
    
    private func horizontalAlignment(for alignment: Alignment) -> HorizontalAlignment {
        alignment == .trailing ? .trailing : .leading
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        if isHeader {
            Text("Set")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor)
        }
    }
    
    private var systemImage: String {
        switch row.state {
        case .achieved:
            "checkmark.circle"
        case .missed:
            "exclamationmark.triangle"
        case .recorded:
            "checkmark.circle"
        case .extra:
            "plus.circle"
        }
    }
    
    private var iconColor: Color {
        switch row.state {
        case .achieved, .recorded:
            AppColor.progressGreen
        case .missed:
            AppColor.progressAmber
        case .extra:
            AppColor.textSecondary
        }
    }
    
    private var resultColor: Color {
        switch row.state {
        case .achieved:
            AppColor.progressGreen
        case .missed:
            AppColor.progressAmber
        case .recorded, .extra:
            AppColor.textSecondary
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ReportExerciseSetComparisonCell(row: .init(title: "", target: "Target", result: "Result", state: .extra), isHeader: true)
        ReportExerciseSetComparisonCell(row: .init(title: "Set 1", target: "120 kg x 8", result: "120 kg x 8", state: .achieved))
        ReportExerciseSetComparisonCell(row: .init(title: "Set 2", target: "100 kg x 8", result: "97.5 kg x 8", state: .missed))
        ReportExerciseSetComparisonCell(row: .init(title: "Set 3", target: "-", result: "80 kg x 10", state: .recorded))
        ReportExerciseSetComparisonCell(row: .init(title: "Extra set", target: "-", result: "80 kg x 10", state: .extra))
    }
    .background(AppColor.surfacePrimary)
}
