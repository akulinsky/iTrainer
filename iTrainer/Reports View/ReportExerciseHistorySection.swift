//
//  ReportExerciseHistorySection.swift
//  iTrainer
//
//  Created by Codex on 08.07.2026.
//

import SwiftUI

struct ReportExerciseHistorySection: View {
    let groups: [ReportExerciseViewModel.HistoryGroup]
    let onShowAll: (() -> Void)?
    
    init(groups: [ReportExerciseViewModel.HistoryGroup], onShowAll: (() -> Void)? = nil) {
        self.groups = groups
        self.onShowAll = onShowAll
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("reports.history.title")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(AppColor.brandPrimary)
                
                Spacer(minLength: 12)
                
                if let onShowAll {
                    Button("reports.history.show_all", action: onShowAll)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.brandPrimary)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(groups) { group in
                    historyGroup(group)
                }
            }
        }
    }
    
    private func historyGroup(_ group: ReportExerciseViewModel.HistoryGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.dateText)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                
                if !group.contextText.isEmpty {
                    Text(group.contextText)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
            
                    ReportExerciseSetComparisonCell(row: .init(title: "",
                                                               target: String(localized: "reports.common.target"),
                                                               result: String(localized: "reports.common.result"),
                                                               state: .extra),
                                                    isHeader: true)
            
            ForEach(group.rows) { row in
                Divider()
                ReportExerciseSetComparisonCell(row: row)
            }
        }
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}
