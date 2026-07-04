//
//  ExerciseStatisticsView.swift
//  iTrainer
//
//  Created by OpenAI on 01.07.2026.
//

import SwiftUI
import Charts

struct ExerciseStatisticsView: View {
    @StateObject private var viewModel: ExerciseStatisticsViewModel
    
    init(exercise: ReportExerciseModel) {
        _viewModel = StateObject(wrappedValue: ExerciseStatisticsViewModel(exercise: exercise))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                graphCard
                
                if viewModel.selectedMetric.showsPeriodSummary {
                    periodSummaryCard
                }
                
                currentVsPreviousCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(AppColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.reloadData()
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.title)
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
            
            if !viewModel.contextText.isEmpty {
                Text(viewModel.contextText)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
            
            Divider()
                .padding(.top, 4)
            
            metricSegmentedControl
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
    
    private var metricSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseMetricSegment.allCases) { metric in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedMetric = metric
                    }
                } label: {
                    Text(metric.title)
                        .font(.system(size: 14, weight: viewModel.selectedMetric == metric ? .bold : .regular))
                        .foregroundStyle(viewModel.selectedMetric == metric ? Color.white : AppColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if viewModel.selectedMetric == metric {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppColor.brandPrimary)
                            }
                        }
                }
                .buttonStyle(.plain)
                
                if metric != ExerciseMetricSegment.allCases.last {
                    Divider()
                        .opacity(viewModel.selectedMetric == metric ? 0 : 1)
                }
            }
        }
        .padding(2)
        .background(AppColor.backgroundPrimary.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.selectedMetric.title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(AppColor.brandPrimary)
                Text(viewModel.selectedMetric.subtitle)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
            }
            
            chartArea
            
            HStack(spacing: 18) {
                chartLegendItem(color: AppColor.brandPrimary, title: "Workout")
                chartLegendItem(color: ExerciseStatisticsViewModel.trophyGold, title: "Personal Record")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            periodFilter
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
    
    private func chartLegendItem(color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
    
    @ViewBuilder
    private var chartArea: some View {
        if !viewModel.hasPeriodGraphPoints {
            VStack(spacing: 8) {
                Text(viewModel.hasAnyReports ? "No data for this period" : "No statistics yet")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                Text(viewModel.hasAnyReports ? "Try a wider period." : "Reports will appear after completing this exercise.")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.selectedMetric.axisUnit)
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                
                GeometryReader { proxy in
                    let points = viewModel.visibleGraphPoints(maxCount: viewModel.maxVisiblePoints(for: proxy.size.width))
                    
                    Chart(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value(viewModel.selectedMetric.title, point.value)
                        )
                        .interpolationMethod(.linear)
                        .foregroundStyle(AppColor.brandPrimary)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(viewModel.selectedMetric.title, point.value)
                        )
                        .foregroundStyle(point.isPersonalRecord ? ExerciseStatisticsViewModel.trophyGold : AppColor.brandPrimary)
                        .symbolSize(point.isPersonalRecord ? 80 : 62)
                    }
                    .chartLegend(.hidden)
                    .chartYScale(domain: viewModel.yDomain(for: points))
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 6)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(AppColor.separatorSoft)
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(viewModel.selectedPeriod.axisLabel(for: date))
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(AppColor.separatorSoft)
                            AxisValueLabel()
                                .foregroundStyle(AppColor.textPrimary)
                        }
                    }
                    .chartPlotStyle { plotArea in
                        plotArea
                            .background(AppColor.surfacePrimary)
                    }
                }
                .frame(height: 220)
            }
        }
    }
    
    private var periodFilter: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseStatisticsPeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    Text(period.title)
                        .font(.system(size: 14, weight: viewModel.selectedPeriod == period ? .bold : .regular))
                        .foregroundStyle(viewModel.selectedPeriod == period ? Color.white : AppColor.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if viewModel.selectedPeriod == period {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppColor.brandPrimary)
                            }
                        }
                }
                .buttonStyle(.plain)
                
                if period != ExerciseStatisticsPeriod.allCases.last {
                    Divider()
                }
            }
        }
        .padding(2)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var periodSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Period Summary")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
            
            HStack(spacing: 0) {
                statisticColumn(title: "Average",
                                value: viewModel.periodSummary.averageText,
                                color: AppColor.textPrimary)
                
                Divider()
                    .frame(height: 54)
                    .padding(.horizontal, 18)
                
                statisticColumn(title: "Change",
                                value: viewModel.periodSummary.changeText,
                                color: viewModel.periodSummary.changeColor)
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
    
    private var currentVsPreviousCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current vs Previous")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(AppColor.brandPrimary)
            
            HStack(spacing: 0) {
                statisticColumn(title: "Current",
                                value: viewModel.currentPrevious.currentText,
                                color: AppColor.textPrimary)
                
                Divider()
                    .frame(height: 54)
                    .padding(.horizontal, 12)
                
                statisticColumn(title: "Previous",
                                value: viewModel.currentPrevious.previousText,
                                color: AppColor.textPrimary)
                
                Divider()
                    .frame(height: 54)
                    .padding(.horizontal, 12)
                
                statisticColumn(title: "Change",
                                value: viewModel.currentPrevious.changeText,
                                color: viewModel.currentPrevious.changeColor)
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
    
    private func statisticColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .allowsTightening(true)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ExerciseStatisticsView(exercise: ReportExerciseModel(titleExercise: "Bench Press",
                                                             exerciseId: UUID(),
                                                             index: 1,
                                                             typeId: "chest_bench_press",
                                                             titleWorkout: "Mass Phase",
                                                             titleWorkoutGroup: "Monday (Heavy Bench)",
                                                             date: .now,
                                                             sets: [
                                                                ReportSetsModel(date: .now, params: [.weight(205), .repeats(2)])
                                                             ]))
    }
}
