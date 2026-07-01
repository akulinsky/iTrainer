//
//  ReportExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.09.2024.
//

import SwiftUI

struct ReportExerciseView: View {
    @StateObject var viewModel: ReportExerciseViewModel
    @Environment(\.navigation) private var navigationManager
    
    private let horizontalPadding: CGFloat = 20
    
    init(viewModel: ReportExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                statusCard
                targetResultSection
                summarySection
                statisticsButton
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Exercise Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.reloadData()
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.title)
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            if !viewModel.workoutContext.isEmpty {
                Text(viewModel.workoutContext)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
            
            if !viewModel.reportDate.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 22)
                    Text(viewModel.reportDate)
                        .font(AppFont.rowSubtitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(AppColor.textSecondary)
            }
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
    
    private var statusCard: some View {
        Group {
            if isCompactStatus {
                compactStatusCardContent
            } else {
                detailedStatusCardContent
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(viewModel.status.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(viewModel.status.color.opacity(0.35), lineWidth: 1)
        }
    }
    
    private var detailedStatusCardContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            statusHeader
            statusMetricsGrid
            
            if shouldShowVolumeBreakdown {
                Divider()
                volumeBreakdownView
            }
        }
    }
    
    private var compactStatusCardContent: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle()
                    .fill(viewModel.status.color.opacity(0.12))
                Image(systemName: viewModel.status.systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(viewModel.status.color)
            }
            .frame(width: 58, height: 58)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.status.title)
                    .font(AppFont.workoutWidgetTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                
                Text(compactStatusSubtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 88)
    }
    
    private var statusHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            if isCompactStatus {
                Spacer(minLength: 0)
            }
            
            Image(systemName: viewModel.status.systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(viewModel.status.color)
                .frame(width: 34)
            
            Text(viewModel.status.title)
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.brandPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            Spacer(minLength: 0)
            
            if let metricPillText {
                Text(metricPillText)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.status.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(viewModel.status.color.opacity(0.18), lineWidth: 1)
                    }
            }
        }
    }
    
    private var statusMetricsGrid: some View {
        HStack(spacing: 0) {
            if isCompactStatus {
                Spacer(minLength: 0)
            }
            
            statusMetricsContent
                .frame(maxWidth: isCompactStatus ? 230 : .infinity)
                .padding(.vertical, isCompactStatus ? 0 : 14)
                .padding(.horizontal, isCompactStatus ? 0 : 10)
                .background {
                    if !isCompactStatus {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppColor.surfacePrimary.opacity(0.45))
                    }
                }
                .overlay {
                    if !isCompactStatus {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(viewModel.status.color.opacity(0.18), lineWidth: 1)
                    }
                }
            
            if isCompactStatus {
                Spacer(minLength: 0)
            }
        }
    }
    
    private var statusMetricsContent: some View {
        HStack(spacing: 0) {
            ForEach(Array(displayStatusMetrics.enumerated()), id: \.element.id) { index, metric in
                statusMetricView(metric)
                
                if index < displayStatusMetrics.count - 1 {
                    Divider()
                        .frame(height: 44)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
    
    private func statusMetricView(_ metric: ReportExerciseViewModel.StatusMetric) -> some View {
        VStack(spacing: 8) {
            Text(metric.title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(height: 30, alignment: .center)
            
            Text(metric.value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(metric.color)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .multilineTextAlignment(.center)
                .frame(height: 24, alignment: .top)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var volumeBreakdownView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Breakdown")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            ForEach(viewModel.volumeBreakdown, id: \.self) { line in
                Text(line)
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }
    
    private var targetResultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Target vs Result")
            
            VStack(spacing: 0) {
                ReportExerciseSetComparisonCell(row: .init(title: "", target: "Target", result: "Result", state: .extra), isHeader: true)
                
                ForEach(viewModel.setRows) { row in
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
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Exercise Summary")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(viewModel.summaryCards) { card in
                    summaryCard(card)
                }
            }
        }
    }
    
    private func summaryCard(_ card: ReportExerciseViewModel.SummaryCard) -> some View {
        VStack(spacing: 12) {
            Image(systemName: card.systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColor.progressGreen)
                .frame(height: 32)
            
            Text(card.title)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            
            Text(card.value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 142)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var statisticsButton: some View {
        Button {
            navigationManager.path.append(ReportsRoute.exerciseStatisticsView(item: viewModel.reportExercise))
        } label: {
            HStack(spacing: 16) {
                Image("icTabReports")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(AppColor.brandPrimary)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Statistics")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("History, records, and long-term progress")
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(18)
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
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 21, weight: .bold))
            .foregroundStyle(AppColor.brandPrimary)
            .padding(.horizontal, 4)
    }
    
    private var isCompactStatus: Bool {
        switch viewModel.status {
        case .goalAchieved, .goalMissed, .complete:
            true
        case .personalRecord, .progress:
            false
        }
    }
    
    private var metricPillText: String? {
        guard !isCompactStatus,
              let metric = viewModel.statusMetrics.first,
              metric.title == "Metric" || metric.title == "Record type" else {
            return nil
        }
        return "\(metric.title): \(metric.value)"
    }
    
    private var displayStatusMetrics: [ReportExerciseViewModel.StatusMetric] {
        guard metricPillText != nil else { return viewModel.statusMetrics }
        return Array(viewModel.statusMetrics.dropFirst())
    }
    
    private var compactStatusSubtitle: String {
        switch viewModel.status {
        case .goalAchieved:
            "All planned sets completed successfully."
        case .goalMissed:
            missedTargetsText
        case .complete:
            "Exercise completed without target sets."
        case .personalRecord, .progress:
            ""
        }
    }
    
    private var missedTargetsText: String {
        guard let targets = viewModel.statusMetrics.first(where: { $0.title == "Targets" })?.value else {
            return "Some target sets were missed."
        }
        
        let parts = targets.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let achieved = Int(parts[0]),
              let total = Int(parts[1]) else {
            return "Some target sets were missed."
        }
        
        let missed = max(total - achieved, 0)
        return "\(missed) of \(total) targets missed."
    }
    
    private var shouldShowVolumeBreakdown: Bool {
        if case .personalRecord(.volume) = viewModel.status {
            return !viewModel.volumeBreakdown.isEmpty
        }
        return false
    }
}

#Preview {
    NavigationStack {
        ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: ReportExerciseModel(titleExercise: "Bench Press",
                                                                                                  exerciseId: UUID(),
                                                                                                  index: 1,
                                                                                                  typeId: "chest_bench_press",
                                                                                                  titleWorkout: "Heavy Workout",
                                                                                                  titleWorkoutGroup: "Chest & Back",
                                                                                                  restTime: 120,
                                                                                                  date: .now,
                                                                                                  sets: [
                                                                                                    ReportSetsModel(date: .now, params: [.weight(120), .repeats(8)]),
                                                                                                    ReportSetsModel(date: .now, params: [.weight(110), .repeats(8)])
                                                                                                  ],
                                                                                                  targetSets: [
                                                                                                    SetsModel(index: 1, params: [.weight(120), .repeats(8)]),
                                                                                                    SetsModel(index: 2, params: [.weight(110), .repeats(8)])
                                                                                                  ])))
    }
}
