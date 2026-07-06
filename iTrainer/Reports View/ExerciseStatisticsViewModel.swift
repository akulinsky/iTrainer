//
//  ExerciseStatisticsViewModel.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import SwiftUI

final class ExerciseStatisticsViewModel: ObservableObject {
    static let trophyGold = Color(red: 0.85, green: 0.64, blue: 0.25)
    
    @Published var selectedMetric: ExerciseMetricSegment = .weight
    @Published var selectedPeriod: ExerciseStatisticsPeriod = .oneMonth
    @Published private var localReports = [ReportExerciseModel]()
    @Published private var globalReports = [ReportExerciseModel]()
    
    let scope: ExerciseStatisticsScope
    
    init(exercise: ReportExerciseModel) {
        self.scope = .local(exercise)
        self.localReports = [exercise]
        self.globalReports = [exercise]
    }
    
    init(exerciseType: ExerciseTypeModel) {
        self.scope = .global(exerciseType)
    }
    
    var title: String {
        switch scope {
        case .local(let exercise):
            exercise.titleExercise
        case .global(let exerciseType):
            exerciseType.displayName
        }
    }
    
    var contextText: String {
        switch scope {
        case .local(let exercise):
            [exercise.titleWorkout, exercise.titleWorkoutGroup]
                .compactMap { value in
                    guard let value, !value.isEmpty else { return nil }
                    return value
                }
                .joined(separator: " · ")
        case .global:
            "Across all workouts"
        }
    }
    
    var showsBestResult: Bool {
        scope.isGlobal
    }
    
    var hasAnyReports: Bool {
        !allGraphPoints.isEmpty
    }
    
    var hasPeriodGraphPoints: Bool {
        !periodGraphPoints.isEmpty
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
    
    var bestResult: BestResultSummary {
        let bestPoint: ExerciseStatisticsPoint?
        
        if selectedMetric == .repetitions {
            bestPoint = bestSetResult()
        } else {
            bestPoint = globalAllGraphPoints.max(by: { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.date < rhs.date
                }
                return lhs.value < rhs.value
            })
        }
        
        guard let bestPoint else {
            return BestResultSummary(title: selectedMetric.bestResultTitle,
                                     valueText: "-",
                                     dateText: "-",
                                     subtitle: "Across all workouts")
        }
        
        return BestResultSummary(title: selectedMetric.bestResultTitle,
                                 valueText: bestPoint.formattedValue,
                                 dateText: bestPoint.date.formatted(.dateTime.month(.abbreviated).day().year()),
                                 subtitle: "Across all workouts")
    }
    
    func visibleGraphPoints(maxCount: Int) -> [ExerciseStatisticsPoint] {
        sample(points: periodGraphPoints, maxCount: maxCount)
    }
    
    func maxVisiblePoints(for width: CGFloat) -> Int {
        min(max(Int(width / 28) + 4, 8), 22)
    }
    
    func yDomain(for points: [ExerciseStatisticsPoint]) -> ClosedRange<Double> {
        let values = points.map(\.value)
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
        
        switch scope {
        case .local(let exercise):
            let local = await dataManager.fetchReportExercises(exerciseId: exercise.exerciseId)
                .map { ReportExerciseModel(model: $0) }
            let global = await dataManager.fetchReportExercises(typeId: exercise.typeId)
                .map { ReportExerciseModel(model: $0) }
            
            localReports = mergedReports(local, fallback: exercise)
            globalReports = mergedReports(global, fallback: exercise)
        case .global(let exerciseType):
            let global = await dataManager.fetchReportExercises(typeId: exerciseType.id)
                .map { ReportExerciseModel(model: $0) }
            
            localReports = []
            globalReports = global
        }
    }
    
    private var allGraphPoints: [ExerciseStatisticsPoint] {
        activeReports.compactMap { point(for: $0) }
            .sorted { $0.date < $1.date }
    }
    
    private var globalAllGraphPoints: [ExerciseStatisticsPoint] {
        globalReports.compactMap { point(for: $0) }
            .sorted { $0.date < $1.date }
    }
    
    private var activeReports: [ReportExerciseModel] {
        switch scope {
        case .local:
            localReports
        case .global:
            globalReports
        }
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
            let sets = performedStrengthSets(in: report)
            guard !sets.isEmpty else { return nil }
            guard let weight = sets.map(\.weight).max() else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: weight,
                                           formattedValue: formattedKilograms(weight),
                                           isPersonalRecord: isPersonalRecord(report))
        case .volume:
            let sets = performedStrengthSets(in: report)
            guard !sets.isEmpty else { return nil }
            let volume = sets.reduce(Float.zero) { $0 + ($1.weight * Float($1.reps)) }
            guard volume > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: volume,
                                           formattedValue: formattedKilograms(volume),
                                           isPersonalRecord: isPersonalRecord(report))
        case .repetitions:
            if let weightedRepetitionPoint = weightedRepetitionPoint(for: report, date: date) {
                return weightedRepetitionPoint
            }
            return bodyweightRepetitionPoint(for: report, date: date)
        }
    }
    
    private func weightedRepetitionPoint(for report: ReportExerciseModel, date: Date) -> ExerciseStatisticsPoint? {
        let sets = performedStrengthSets(in: report)
        guard let weight = sets.map(\.weight).max() else { return nil }
        let reps = sets
            .filter { $0.weight == weight }
            .map(\.reps)
            .max() ?? 0
        guard reps > 0 else { return nil }
        
        return ExerciseStatisticsPoint(reportId: report.id,
                                       date: date,
                                       value: Float(reps),
                                       formattedValue: "\(formattedNumber(weight)) kg x \(reps)",
                                       isPersonalRecord: isPersonalRecord(report))
    }
    
    private func bodyweightRepetitionPoint(for report: ReportExerciseModel, date: Date) -> ExerciseStatisticsPoint? {
        let reps = performedRepsOnlySets(in: report).max() ?? 0
        guard reps > 0 else { return nil }
        
        return ExerciseStatisticsPoint(reportId: report.id,
                                       date: date,
                                       value: Float(reps),
                                       formattedValue: "\(reps)",
                                       isPersonalRecord: isPersonalRecord(report))
    }
    
    private func bestSetResult() -> ExerciseStatisticsPoint? {
        let weightedSets = globalReports.flatMap { report -> [(report: ReportExerciseModel, date: Date, set: PerformedStrengthSet)] in
            guard let date = report.date else { return [] }
            return performedStrengthSets(in: report).map { (report: report, date: date, set: $0) }
        }
        
        if let bestWeight = weightedSets.map({ $0.set.weight }).max() {
            let bestSet = weightedSets
                .filter { $0.set.weight == bestWeight }
                .max { lhs, rhs in
                    if lhs.set.reps == rhs.set.reps {
                        return lhs.date < rhs.date
                    }
                    return lhs.set.reps < rhs.set.reps
                }
            
            if let bestSet {
                return ExerciseStatisticsPoint(reportId: bestSet.report.id,
                                               date: bestSet.date,
                                               value: Float(bestSet.set.reps),
                                               formattedValue: "\(formattedNumber(bestSet.set.weight)) kg x \(bestSet.set.reps)",
                                               isPersonalRecord: isPersonalRecord(bestSet.report))
            }
        }
        
        return globalAllGraphPoints.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.date < rhs.date
            }
            return lhs.value < rhs.value
        }
    }
    
    private func performedStrengthSets(in report: ReportExerciseModel) -> [PerformedStrengthSet] {
        report.sets.compactMap { set in
            guard let weight = ReportStatusService.weightValue(for: set.parameters),
                  let reps = ReportStatusService.repsValue(for: set.parameters),
                  weight > 0,
                  reps > 0 else {
                return nil
            }
            return PerformedStrengthSet(weight: weight, reps: reps)
        }
    }
    
    private func performedRepsOnlySets(in report: ReportExerciseModel) -> [Int] {
        report.sets.compactMap { set in
            guard ReportStatusService.weightValue(for: set.parameters) == nil,
                  let reps = ReportStatusService.repsValue(for: set.parameters),
                  reps > 0 else {
                return nil
            }
            return reps
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
        let compressedPoints = compressPlateaus(points)
        guard compressedPoints.count > maxCount else { return compressedPoints }
        
        var selected = Set<UUID>()
        selected.insert(compressedPoints[0].id)
        selected.insert(compressedPoints[compressedPoints.count - 1].id)
        
        let extremeSlots = max(maxCount / 2, 1)
        evenlySample(localExtremes(in: compressedPoints), maxCount: extremeSlots)
            .forEach { selected.insert($0.id) }
        
        let remainingSlots = max(maxCount - selected.count, 0)
        if remainingSlots > 0 {
            let candidates = compressedPoints.filter { !selected.contains($0.id) }
            evenlySample(candidates, maxCount: remainingSlots)
                .forEach { selected.insert($0.id) }
        }
        
        return compressedPoints.filter { selected.contains($0.id) }
    }
    
    private func compressPlateaus(_ points: [ExerciseStatisticsPoint]) -> [ExerciseStatisticsPoint] {
        guard points.count > 2 else { return points }
        
        var result = [ExerciseStatisticsPoint]()
        var index = 0
        
        while index < points.count {
            let plateauStart = index
            var plateauEnd = index
            
            while plateauEnd + 1 < points.count,
                  areSimilar(points[plateauEnd + 1].value, points[plateauStart].value) {
                plateauEnd += 1
            }
            
            result.append(points[plateauStart])
            if plateauEnd > plateauStart {
                result.append(points[plateauEnd])
            }
            
            index = plateauEnd + 1
        }
        
        return result
    }
    
    private func localExtremes(in points: [ExerciseStatisticsPoint]) -> [ExerciseStatisticsPoint] {
        guard points.count > 2 else { return [] }
        
        return (1..<(points.count - 1)).compactMap { index in
            let previous = points[index - 1].value
            let current = points[index].value
            let next = points[index + 1].value
            
            let isPeak = current > previous && current > next
            let isDip = current < previous && current < next
            return isPeak || isDip ? points[index] : nil
        }
    }
    
    private func evenlySample(_ points: [ExerciseStatisticsPoint], maxCount: Int) -> [ExerciseStatisticsPoint] {
        guard maxCount > 0, points.count > maxCount else { return points }
        
        return (0..<maxCount).map { slot in
            let index = Int((Double(slot) / Double(max(maxCount - 1, 1))) * Double(points.count - 1))
            return points[index]
        }
    }
    
    private func areSimilar(_ lhs: Float, _ rhs: Float) -> Bool {
        let difference = abs(lhs - rhs)
        
        switch selectedMetric {
        case .weight:
            return difference < 1
        case .volume:
            let baseline = max(abs(lhs), abs(rhs), 1)
            return difference / baseline < 0.02
        case .repetitions:
            return difference == 0
        }
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

enum ExerciseStatisticsScope {
    case local(ReportExerciseModel)
    case global(ExerciseTypeModel)
    
    var isGlobal: Bool {
        if case .global = self {
            return true
        }
        return false
    }
}

enum ExerciseMetricSegment: CaseIterable, Identifiable {
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
    
    var bestResultTitle: String {
        switch self {
        case .weight:
            "Best Weight"
        case .volume:
            "Best Volume"
        case .repetitions:
            "Best Set"
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

enum ExerciseStatisticsPeriod: CaseIterable, Identifiable {
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

struct ExerciseStatisticsPoint: Identifiable {
    let reportId: UUID
    let date: Date
    let value: Float
    let formattedValue: String
    let isPersonalRecord: Bool
    
    var id: UUID { reportId }
}

struct PerformedStrengthSet {
    let weight: Float
    let reps: Int
}

struct PeriodSummary {
    let averageText: String
    let changeText: String
    let changeColor: Color
}

struct CurrentPreviousSummary {
    let currentText: String
    let previousText: String
    let changeText: String
    let changeColor: Color
}

struct BestResultSummary {
    let title: String
    let valueText: String
    let dateText: String
    let subtitle: String
}
