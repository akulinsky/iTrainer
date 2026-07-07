//
//  ExerciseStatisticsViewModel.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import SwiftUI

final class ExerciseStatisticsViewModel: ObservableObject {
    static let trophyGold = Color(red: 0.85, green: 0.64, blue: 0.25)
    
    @Published var selectedMetric: ExerciseMetricSegment = .weight {
        didSet {
            guard oldValue != selectedMetric else { return }
            scheduleStatisticsPreparation()
        }
    }
    
    @Published var selectedPeriod: ExerciseStatisticsPeriod = .oneMonth {
        didSet {
            guard oldValue != selectedPeriod else { return }
            scheduleStatisticsPreparation()
        }
    }
    
    @Published private(set) var isPreparingStatistics = true
    @Published private var localReports = [ReportExerciseModel]()
    @Published private var globalReports = [ReportExerciseModel]()
    @Published private var allGraphPoints = [ExerciseStatisticsPoint]()
    @Published private var globalAllGraphPoints = [ExerciseStatisticsPoint]()
    @Published private var periodGraphPoints = [ExerciseStatisticsPoint]()
    @Published private var cachedPeriodSummary = PeriodSummary.empty
    @Published private var cachedCurrentPrevious = CurrentPreviousSummary.empty
    @Published private var cachedBestResult = BestResultSummary.empty(title: ExerciseMetricSegment.weight.bestResultTitle)
    
    let scope: ExerciseStatisticsScope
    
    private var statisticsTask: Task<Void, Never>?
    
    init(exercise: ReportExerciseModel) {
        self.scope = .local(exercise)
        self.localReports = [exercise]
        self.globalReports = [exercise]
        scheduleStatisticsPreparation()
    }
    
    init(exerciseType: ExerciseTypeModel) {
        self.scope = .global(exerciseType)
        scheduleStatisticsPreparation()
    }
    
    deinit {
        statisticsTask?.cancel()
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
        cachedPeriodSummary
    }
    
    var currentPrevious: CurrentPreviousSummary {
        cachedCurrentPrevious
    }
    
    var bestResult: BestResultSummary {
        cachedBestResult
    }
    
    func visibleGraphPoints(maxCount: Int) -> [ExerciseStatisticsPoint] {
        Self.sample(points: periodGraphPoints, maxCount: maxCount, metric: selectedMetric)
    }
    
    func maxVisiblePoints(for width: CGFloat) -> Int {
        min(max(Int(width / 28) + 4, 8), 22)
    }
    
    func maxExpandedVisiblePoints(for width: CGFloat) -> Int {
        min(max(Int(width / 18) + 8, 18), 48)
    }
    
    func xDomain(for points: [ExerciseStatisticsPoint]) -> ClosedRange<Date> {
        guard let firstDate = points.first?.date,
              let lastDate = points.last?.date else {
            let now = Date()
            return now...now.addingTimeInterval(1)
        }
        
        let day: TimeInterval = 24 * 60 * 60
        let span = max(lastDate.timeIntervalSince(firstDate), day)
        let padding = max(span * 0.04, day * 0.35)
        
        return firstDate.addingTimeInterval(-padding)...lastDate.addingTimeInterval(padding)
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
            
            localReports = Self.mergedReports(local, fallback: exercise)
            globalReports = Self.mergedReports(global, fallback: exercise)
        case .global(let exerciseType):
            let global = await dataManager.fetchReportExercises(typeId: exerciseType.id)
                .map { ReportExerciseModel(model: $0) }
            
            localReports = []
            globalReports = global
        }
        
        scheduleStatisticsPreparation()
    }
    
    private func scheduleStatisticsPreparation() {
        statisticsTask?.cancel()
        
        let metric = selectedMetric
        let period = selectedPeriod
        let activeReports = activeReportsSnapshot
        let globalReports = globalReports
        
        isPreparingStatistics = true
        statisticsTask = Task { [weak self] in
            let prepared = await Task.detached(priority: .userInitiated) {
                Self.prepareStatistics(activeReports: activeReports,
                                       globalReports: globalReports,
                                       metric: metric,
                                       period: period)
            }.value
            
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.allGraphPoints = prepared.allGraphPoints
                self.globalAllGraphPoints = prepared.globalAllGraphPoints
                self.periodGraphPoints = prepared.periodGraphPoints
                self.cachedPeriodSummary = prepared.periodSummary
                self.cachedCurrentPrevious = prepared.currentPrevious
                self.cachedBestResult = prepared.bestResult
                self.isPreparingStatistics = false
            }
        }
    }
    
    private var activeReportsSnapshot: [ReportExerciseModel] {
        switch scope {
        case .local:
            localReports
        case .global:
            globalReports
        }
    }
    
    private static func prepareStatistics(activeReports: [ReportExerciseModel],
                                          globalReports: [ReportExerciseModel],
                                          metric: ExerciseMetricSegment,
                                          period: ExerciseStatisticsPeriod) -> PreparedStatistics {
        let allGraphPoints = activeReports
            .compactMap { point(for: $0, metric: metric, history: globalReports) }
            .sorted { $0.date < $1.date }
        let globalAllGraphPoints = globalReports
            .compactMap { point(for: $0, metric: metric, history: globalReports) }
            .sorted { $0.date < $1.date }
        let cutoffDate = period.cutoffDate(relativeTo: allGraphPoints.last?.date ?? Date())
        let periodGraphPoints = cutoffDate.map { cutoff in
            allGraphPoints.filter { $0.date >= cutoff }
        } ?? allGraphPoints
        let periodSummary = makePeriodSummary(points: periodGraphPoints, metric: metric)
        let currentPrevious = makeCurrentPrevious(points: allGraphPoints, metric: metric)
        let bestResult = makeBestResult(points: globalAllGraphPoints,
                                        reports: globalReports,
                                        metric: metric,
                                        history: globalReports)
        
        return PreparedStatistics(allGraphPoints: allGraphPoints,
                                  globalAllGraphPoints: globalAllGraphPoints,
                                  periodGraphPoints: periodGraphPoints,
                                  periodSummary: periodSummary,
                                  currentPrevious: currentPrevious,
                                  bestResult: bestResult)
    }
    
    private static func makePeriodSummary(points: [ExerciseStatisticsPoint], metric: ExerciseMetricSegment) -> PeriodSummary {
        guard !points.isEmpty else { return .empty }
        
        let average = points.reduce(Float.zero) { $0 + $1.value } / Float(points.count)
        let change = points.count > 1 ? points[points.count - 1].value - points[0].value : nil
        
        return PeriodSummary(averageText: formatted(value: average, for: metric),
                             changeText: change.map { formattedChange($0, for: metric) } ?? "-",
                             changeColor: color(for: change))
    }
    
    private static func makeCurrentPrevious(points: [ExerciseStatisticsPoint], metric: ExerciseMetricSegment) -> CurrentPreviousSummary {
        guard let current = points.last else { return .empty }
        
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
                                      changeText: formattedChange(change, for: metric),
                                      changeColor: color(for: change))
    }
    
    private static func makeBestResult(points: [ExerciseStatisticsPoint],
                                       reports: [ReportExerciseModel],
                                       metric: ExerciseMetricSegment,
                                       history: [ReportExerciseModel]) -> BestResultSummary {
        let bestPoint: ExerciseStatisticsPoint?
        
        if metric == .repetitions {
            bestPoint = bestSetResult(reports: reports, history: history)
        } else {
            bestPoint = points.max(by: { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.date < rhs.date
                }
                return lhs.value < rhs.value
            })
        }
        
        guard let bestPoint else {
            return .empty(title: metric.bestResultTitle)
        }
        
        return BestResultSummary(title: metric.bestResultTitle,
                                 valueText: bestPoint.formattedValue,
                                 dateText: bestPoint.date.formatted(.dateTime.month(.abbreviated).day().year()),
                                 subtitle: "Across all workouts")
    }
    
    private static func point(for report: ReportExerciseModel,
                              metric: ExerciseMetricSegment,
                              history: [ReportExerciseModel]) -> ExerciseStatisticsPoint? {
        guard let date = report.date else { return nil }
        
        switch metric {
        case .weight:
            let sets = performedStrengthSets(in: report)
            guard !sets.isEmpty else { return nil }
            guard let weight = sets.map(\.weight).max() else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: weight,
                                           formattedValue: formattedKilograms(weight),
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        case .volume:
            let sets = performedStrengthSets(in: report)
            guard !sets.isEmpty else { return nil }
            let volume = sets.reduce(Float.zero) { $0 + ($1.weight * Float($1.reps)) }
            guard volume > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: volume,
                                           formattedValue: formattedKilograms(volume),
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        case .repetitions:
            if let weightedRepetitionPoint = weightedRepetitionPoint(for: report, date: date, history: history) {
                return weightedRepetitionPoint
            }
            return bodyweightRepetitionPoint(for: report, date: date, history: history)
        }
    }
    
    private static func weightedRepetitionPoint(for report: ReportExerciseModel,
                                                date: Date,
                                                history: [ReportExerciseModel]) -> ExerciseStatisticsPoint? {
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
                                       isPersonalRecord: isPersonalRecord(report, history: history))
    }
    
    private static func bodyweightRepetitionPoint(for report: ReportExerciseModel,
                                                  date: Date,
                                                  history: [ReportExerciseModel]) -> ExerciseStatisticsPoint? {
        let reps = performedRepsOnlySets(in: report).max() ?? 0
        guard reps > 0 else { return nil }
        
        return ExerciseStatisticsPoint(reportId: report.id,
                                       date: date,
                                       value: Float(reps),
                                       formattedValue: "\(reps)",
                                       isPersonalRecord: isPersonalRecord(report, history: history))
    }
    
    private static func bestSetResult(reports: [ReportExerciseModel], history: [ReportExerciseModel]) -> ExerciseStatisticsPoint? {
        let weightedSets = reports.flatMap { report -> [(report: ReportExerciseModel, date: Date, set: PerformedStrengthSet)] in
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
                                               isPersonalRecord: isPersonalRecord(bestSet.report, history: history))
            }
        }
        
        return reports
            .compactMap { report -> ExerciseStatisticsPoint? in
                guard let date = report.date else { return nil }
                return bodyweightRepetitionPoint(for: report, date: date, history: history)
            }
            .max { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.date < rhs.date
                }
                return lhs.value < rhs.value
            }
    }
    
    private static func performedStrengthSets(in report: ReportExerciseModel) -> [PerformedStrengthSet] {
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
    
    private static func performedRepsOnlySets(in report: ReportExerciseModel) -> [Int] {
        report.sets.compactMap { set in
            guard ReportStatusService.weightValue(for: set.parameters) == nil,
                  let reps = ReportStatusService.repsValue(for: set.parameters),
                  reps > 0 else {
                return nil
            }
            return reps
        }
    }
    
    private static func isPersonalRecord(_ report: ReportExerciseModel, history: [ReportExerciseModel]) -> Bool {
        ReportStatusService.calculateExerciseStatusResult(report: report, history: history).status.isPersonalRecord
    }
    
    private static func mergedReports(_ reports: [ReportExerciseModel], fallback: ReportExerciseModel) -> [ReportExerciseModel] {
        var result = reports
        if !result.contains(where: { $0.id == fallback.id }) {
            result.append(fallback)
        }
        return result.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }
    
    private static func sample(points: [ExerciseStatisticsPoint], maxCount: Int, metric: ExerciseMetricSegment) -> [ExerciseStatisticsPoint] {
        let compressedPoints = compressPlateaus(points, metric: metric)
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
    
    private static func compressPlateaus(_ points: [ExerciseStatisticsPoint], metric: ExerciseMetricSegment) -> [ExerciseStatisticsPoint] {
        guard points.count > 2 else { return points }
        
        var result = [ExerciseStatisticsPoint]()
        var index = 0
        
        while index < points.count {
            let plateauStart = index
            var plateauEnd = index
            
            while plateauEnd + 1 < points.count,
                  areSimilar(points[plateauEnd + 1].value, points[plateauStart].value, metric: metric) {
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
    
    private static func localExtremes(in points: [ExerciseStatisticsPoint]) -> [ExerciseStatisticsPoint] {
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
    
    private static func evenlySample(_ points: [ExerciseStatisticsPoint], maxCount: Int) -> [ExerciseStatisticsPoint] {
        guard maxCount > 0, points.count > maxCount else { return points }
        
        return (0..<maxCount).map { slot in
            let index = Int((Double(slot) / Double(max(maxCount - 1, 1))) * Double(points.count - 1))
            return points[index]
        }
    }
    
    private static func areSimilar(_ lhs: Float, _ rhs: Float, metric: ExerciseMetricSegment) -> Bool {
        let difference = abs(lhs - rhs)
        
        switch metric {
        case .weight:
            return difference < 1
        case .volume:
            let baseline = max(abs(lhs), abs(rhs), 1)
            return difference / baseline < 0.02
        case .repetitions:
            return difference == 0
        }
    }
    
    private static func formatted(value: Float, for metric: ExerciseMetricSegment) -> String {
        switch metric {
        case .weight, .volume:
            formattedKilograms(value)
        case .repetitions:
            "\(Int(value.rounded()))"
        }
    }
    
    private static func formattedChange(_ value: Float, for metric: ExerciseMetricSegment) -> String {
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
    
    private static func formattedKilograms(_ value: Float) -> String {
        "\(formattedNumber(value)) kg"
    }
    
    private static func formattedNumber(_ value: Float) -> String {
        let number = Double(value)
        if number.rounded() == number {
            return Int(number).formatted(.number)
        }
        return number.formatted(.number.precision(.fractionLength(1)))
    }
    
    private static func color(for change: Float?) -> Color {
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
    
    static let empty = PeriodSummary(averageText: "-",
                                     changeText: "-",
                                     changeColor: AppColor.textSecondary)
}

struct CurrentPreviousSummary {
    let currentText: String
    let previousText: String
    let changeText: String
    let changeColor: Color
    
    static let empty = CurrentPreviousSummary(currentText: "-",
                                              previousText: "-",
                                              changeText: "-",
                                              changeColor: AppColor.textSecondary)
}

struct BestResultSummary {
    let title: String
    let valueText: String
    let dateText: String
    let subtitle: String
    
    static func empty(title: String) -> BestResultSummary {
        BestResultSummary(title: title,
                          valueText: "-",
                          dateText: "-",
                          subtitle: "Across all workouts")
    }
}

private struct PreparedStatistics {
    let allGraphPoints: [ExerciseStatisticsPoint]
    let globalAllGraphPoints: [ExerciseStatisticsPoint]
    let periodGraphPoints: [ExerciseStatisticsPoint]
    let periodSummary: PeriodSummary
    let currentPrevious: CurrentPreviousSummary
    let bestResult: BestResultSummary
}
