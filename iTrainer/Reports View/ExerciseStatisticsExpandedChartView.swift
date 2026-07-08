//
//  ExerciseStatisticsExpandedChartView.swift
//  iTrainer
//
//  Created by Codex on 07.07.2026.
//

import SwiftUI
import Charts

struct ExerciseStatisticsExpandedChartView: View {
    @ObservedObject var viewModel: ExerciseStatisticsViewModel
    let onClose: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var dimOpacity: Double = 0
    @State private var isClosing = false
    
    private let dimTargetOpacity = 0.28
    private let presentationAnimationDelay: UInt64 = 350_000_000
    private let dimAnimationDuration = 0.18
    
    var body: some View {
        GeometryReader { proxy in
            let chartWidth = max(proxy.size.height - 116, 320)
            let chartHeight = max(proxy.size.width - 78, 260)
            let points = viewModel.visibleGraphPoints(maxCount: viewModel.maxExpandedVisiblePoints(for: chartWidth))
            
            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(dimOpacity)
                
                rotatedChart(points: points,
                             chartWidth: chartWidth,
                             chartHeight: chartHeight)
                    .position(x: proxy.size.width / 2,
                              y: proxy.size.height / 2)
                    .offset(dragOffset)
            }
            .contentShape(Rectangle())
            .gesture(closeGesture)
        }
        .task {
            try? await Task.sleep(nanoseconds: presentationAnimationDelay)
            guard !Task.isCancelled, !isClosing else { return }
            withAnimation(.easeInOut(duration: dimAnimationDuration)) {
                dimOpacity = dimTargetOpacity
            }
        }
    }
    
    private func rotatedChart(points: [ExerciseStatisticsPoint], chartWidth: CGFloat, chartHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.selectedMetric.axisUnit)
                .font(AppFont.rowSubtitle)
                .foregroundStyle(AppColor.textSecondary)
            
            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(viewModel.selectedMetric.title, point.value)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(AppColor.brandPrimary)
                .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value(viewModel.selectedMetric.title, point.value)
                )
                .foregroundStyle(point.isPersonalRecord ? ExerciseStatisticsViewModel.trophyGold : AppColor.brandPrimary)
                .symbolSize(point.isPersonalRecord ? 95 : 74)
            }
            .chartLegend(.hidden)
            .chartXScale(domain: viewModel.xDomain(for: points))
            .chartYScale(domain: viewModel.yDomain(for: points))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(AppColor.separatorSoft)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(viewModel.selectedPeriod.axisLabel(for: date))
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(AppColor.separatorSoft)
                    AxisValueLabel()
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(AppColor.surfacePrimary)
            }
        }
        .padding(18)
        .frame(width: chartWidth, height: chartHeight)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
        .rotationEffect(.degrees(90))
    }
    
    private var closeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if distance > 90 {
                    close()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    private func close() {
        guard !isClosing else { return }
        isClosing = true
        
        dimOpacity = 0
        
        Task { @MainActor in
            onClose()
        }
    }
}

#Preview {
    ExerciseStatisticsExpandedChartView(
        viewModel: ExerciseStatisticsViewModel(exercise: ReportExerciseModel(titleExercise: "Bench Press",
                                                                             exerciseId: UUID(),
                                                                             index: 1,
                                                                             typeId: "chest_bench_press",
                                                                             titleWorkout: "Workout",
                                                                             titleWorkoutGroup: "Group",
                                                                             date: .now,
                                                                             sets: [ReportSetsModel(date: .now, params: [.weight(80), .repeats(5)])])),
        onClose: {}
    )
}
