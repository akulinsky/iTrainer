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
            
            HStack(spacing: 8) {
                Circle()
                    .fill(ExerciseStatisticsViewModel.trophyGold)
                    .frame(width: 12, height: 12)
                Text("PR")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
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
    
    @ViewBuilder
    private var chartArea: some View {
        let points = viewModel.visibleGraphPoints
        
        if points.isEmpty {
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
                    .symbolSize(point.isPersonalRecord ? 110 : 62)
                }
                .chartLegend(.hidden)
                .chartYScale(domain: viewModel.yDomain)
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

private final class ExerciseStatisticsViewModel: ObservableObject {
    static let trophyGold = Color(red: 0.85, green: 0.64, blue: 0.25)
    
    @Published var selectedMetric: ExerciseMetricSegment = .weight
    @Published var selectedPeriod: ExerciseStatisticsPeriod = .oneMonth
    @Published private var localReports = [ReportExerciseModel]()
    @Published private var globalReports = [ReportExerciseModel]()
    
    let exercise: ReportExerciseModel
    
    init(exercise: ReportExerciseModel) {
        self.exercise = exercise
        self.localReports = [exercise]
        self.globalReports = [exercise]
    }
    
    var title: String {
        exercise.titleExercise
    }
    
    var contextText: String {
        [exercise.titleWorkout, exercise.titleWorkoutGroup]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }
    
    var hasAnyReports: Bool {
        !allGraphPoints.isEmpty
    }
    
    var visibleGraphPoints: [ExerciseStatisticsPoint] {
        sample(points: periodGraphPoints, maxCount: 50)
    }
    
    var periodSummary: PeriodSummary {
        let points = periodGraphPoints
        guard !points.isEmpty else {
            return PeriodSummary(averageText: "-", changeText: "-", changeColor: AppColor.textSecondary)
        }
        
        let average = points.reduce(Float.zero) { $0 + $1.value } / Float(points.count)
        let change = points.count > 1 ? points[points.count - 1].value - points[0].value : nil
        
        return PeriodSummary(averageText: formatted(value: average, for: selectedMetric),
                             changeText: change.map { formattedChange($0, for: selectedMetric) } ?? "-",
                             changeColor: color(for: change))
    }
    
    var currentPrevious: CurrentPreviousSummary {
        let points = allGraphPoints
        guard let current = points.last else {
            return CurrentPreviousSummary(currentText: "-",
                                          previousText: "-",
                                          changeText: "-",
                                          changeColor: AppColor.textSecondary)
        }
        
        guard points.count > 1 else {
            return CurrentPreviousSummary(currentText: current.formattedValue,
                                          previousText: "-",
                                          changeText: "-",
                                          changeColor: AppColor.textSecondary)
        }
        
        let previous = points[points.count - 2]
        let change = current.value - previous.value
        
        return CurrentPreviousSummary(currentText: current.formattedValue,
                                      previousText: previous.formattedValue,
                                      changeText: formattedChange(change, for: selectedMetric),
                                      changeColor: color(for: change))
    }
    
    var yDomain: ClosedRange<Double> {
        let values = visibleGraphPoints.map(\.value)
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 0...1
        }
        
        guard minValue != maxValue else {
            let padding = max(abs(minValue) * 0.1, 1)
            return Double(minValue - padding)...Double(maxValue + padding)
        }
        
        let padding = max((maxValue - minValue) * 0.12, 1)
        return Double(max(minValue - padding, 0))...Double(maxValue + padding)
    }
    
    @MainActor
    func reloadData() async {
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let local = await dataManager.fetchReportExercises(exerciseId: exercise.exerciseId)
            .map { ReportExerciseModel(model: $0) }
        let global = await dataManager.fetchReportExercises(typeId: exercise.typeId)
            .map { ReportExerciseModel(model: $0) }
        
        localReports = mergedReports(local, fallback: exercise)
        globalReports = mergedReports(global, fallback: exercise)
    }
    
    private var allGraphPoints: [ExerciseStatisticsPoint] {
        localReports.compactMap { point(for: $0) }
            .sorted { $0.date < $1.date }
    }
    
    private var periodGraphPoints: [ExerciseStatisticsPoint] {
        let points = allGraphPoints
        guard let cutoffDate = selectedPeriod.cutoffDate(relativeTo: points.last?.date ?? Date()) else {
            return points
        }
        return points.filter { $0.date >= cutoffDate }
    }
    
    private func point(for report: ReportExerciseModel) -> ExerciseStatisticsPoint? {
        guard let date = report.date else { return nil }
        
        switch selectedMetric {
        case .weight:
            guard let weight = ReportStatusService.maxWeightValue(for: report) else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: weight,
                                           formattedValue: formattedKilograms(weight),
                                           isPersonalRecord: isPersonalRecord(report))
        case .volume:
            let volume = ReportStatusService.exerciseVolumeValue(for: report)
            guard volume > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: volume,
                                           formattedValue: formattedKilograms(volume),
                                           isPersonalRecord: isPersonalRecord(report))
        case .repetitions:
            guard let weight = ReportStatusService.maxWeightValue(for: report) else { return nil }
            let reps = ReportStatusService.bestRepsValue(at: weight, in: report)
            guard reps > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: Float(reps),
                                           formattedValue: "\(formattedNumber(weight)) kg x \(reps)",
                                           isPersonalRecord: isPersonalRecord(report))
        }
    }
    
    private func isPersonalRecord(_ report: ReportExerciseModel) -> Bool {
        ReportStatusService.calculateExerciseStatusResult(report: report, history: globalReports).status.isPersonalRecord
    }
    
    private func mergedReports(_ reports: [ReportExerciseModel], fallback: ReportExerciseModel) -> [ReportExerciseModel] {
        var result = reports
        if !result.contains(where: { $0.id == fallback.id }) {
            result.append(fallback)
        }
        return result.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }
    
    private func sample(points: [ExerciseStatisticsPoint], maxCount: Int) -> [ExerciseStatisticsPoint] {
        guard points.count > maxCount else { return points }
        
        var selected = Set<UUID>()
        selected.insert(points[0].id)
        selected.insert(points[points.count - 1].id)
        points.filter(\.isPersonalRecord).forEach { selected.insert($0.id) }
        
        let remainingSlots = max(maxCount - selected.count, 0)
        if remainingSlots > 0 {
            let candidates = points.filter { !selected.contains($0.id) }
            if !candidates.isEmpty {
                for slot in 0..<remainingSlots {
                    let index = Int((Double(slot) / Double(max(remainingSlots - 1, 1))) * Double(candidates.count - 1))
                    selected.insert(candidates[index].id)
                }
            }
        }
        
        return points.filter { selected.contains($0.id) }
    }
    
    private func formatted(value: Float, for metric: ExerciseMetricSegment) -> String {
        switch metric {
        case .weight, .volume:
            formattedKilograms(value)
        case .repetitions:
            "\(Int(value.rounded()))"
        }
    }
    
    private func formattedChange(_ value: Float, for metric: ExerciseMetricSegment) -> String {
        guard value != 0 else { return "0 \(metric.changeUnit)" }
        let sign = value > 0 ? "+" : "-"
        let absValue = abs(value)
        
        switch metric {
        case .weight, .volume:
            return "\(sign)\(formattedKilograms(absValue))"
        case .repetitions:
            let unit = Int(absValue.rounded()) == 1 ? "rep" : "reps"
            return "\(sign)\(Int(absValue.rounded())) \(unit)"
        }
    }
    
    private func formattedKilograms(_ value: Float) -> String {
        "\(formattedNumber(value)) kg"
    }
    
    private func formattedNumber(_ value: Float) -> String {
        let number = Double(value)
        if number.rounded() == number {
            return Int(number).formatted(.number)
        }
        return number.formatted(.number.precision(.fractionLength(1)))
    }
    
    private func color(for change: Float?) -> Color {
        guard let change else { return AppColor.textSecondary }
        if change > 0 { return AppColor.progressGreen }
        if change < 0 { return AppColor.progressRed }
        return AppColor.textSecondary
    }
}

private enum ExerciseMetricSegment: CaseIterable, Identifiable {
    case weight
    case volume
    case repetitions
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .weight:
            "Weight"
        case .volume:
            "Volume"
        case .repetitions:
            "Repetitions"
        }
    }
    
    var subtitle: String {
        switch self {
        case .weight:
            "Highest weight per report"
        case .volume:
            "Total volume per report"
        case .repetitions:
            "Reps at relevant weight"
        }
    }
    
    var axisUnit: String {
        switch self {
        case .weight, .volume:
            "kg"
        case .repetitions:
            "reps"
        }
    }
    
    var changeUnit: String {
        switch self {
        case .weight, .volume:
            "kg"
        case .repetitions:
            "reps"
        }
    }
    
    var showsPeriodSummary: Bool {
        self != .repetitions
    }
}

private enum ExerciseStatisticsPeriod: CaseIterable, Identifiable {
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case all
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .oneMonth:
            "1M"
        case .threeMonths:
            "3M"
        case .sixMonths:
            "6M"
        case .oneYear:
            "1Y"
        case .all:
            "All"
        }
    }
    
    func cutoffDate(relativeTo date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: date)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: date)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: date)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: date)
        case .all:
            return nil
        }
    }
    
    func axisLabel(for date: Date) -> String {
        switch self {
        case .oneMonth:
            let components = Calendar.current.dateComponents([.day, .month], from: date)
            let day = components.day ?? 0
            let month = components.month ?? 0
            return String(format: "%d.%02d", day, month)
        case .threeMonths, .sixMonths, .oneYear:
            return date.formatted(.dateTime.month(.abbreviated))
        case .all:
            return date.formatted(.dateTime.month(.abbreviated).year(.twoDigits))
        }
    }
}

private struct ExerciseStatisticsPoint: Identifiable {
    let reportId: UUID
    let date: Date
    let value: Float
    let formattedValue: String
    let isPersonalRecord: Bool
    
    var id: UUID { reportId }
}

private struct PeriodSummary {
    let averageText: String
    let changeText: String
    let changeColor: Color
}

private struct CurrentPreviousSummary {
    let currentText: String
    let previousText: String
    let changeText: String
    let changeColor: Color
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
