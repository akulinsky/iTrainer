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
    let trackingType: ExerciseTrackingType?
    
    private var statisticsTask: Task<Void, Never>?
    
    init(exercise: ReportExerciseModel) {
        self.scope = .local(exercise)
        self.trackingType = ReportStatusService.trackingTypeValue(for: exercise)
        self.localReports = [exercise]
        self.globalReports = [exercise]
        self.selectedMetric = Self.defaultMetric(for: trackingType)
        scheduleStatisticsPreparation()
    }
    
    init(exerciseType: ExerciseTypeModel) {
        self.scope = .global(exerciseType)
        self.trackingType = exerciseType.trackingType
        self.selectedMetric = Self.defaultMetric(for: trackingType)
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
            String(localized: "reports.statistics.across_all_workouts")
        }
    }
    
    var showsBestResult: Bool {
        scope.isGlobal
    }
    
    var availableMetrics: [ExerciseMetricSegment] {
        Self.availableMetrics(for: trackingType)
    }
    
    var selectedMetricSubtitle: String {
        if selectedMetric == .repetitions, trackingType == .repsOnly {
            return String(localized: "reports.statistics.metric.repetitions.total_subtitle")
        }
        return selectedMetric.subtitle
    }
    
    var selectedMetricAxisUnit: String {
        selectedMetric.axisUnit(unitFormatter: UnitFormatter(settings: AppSettings.shared))
    }
    
    var showsPeriodSummary: Bool {
        if selectedMetric == .repetitions {
            return trackingType == .repsOnly
        }
        return selectedMetric.showsPeriodSummary
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
    
    func yAxisLabel(for value: Double) -> String {
        Self.formatted(value: Float(value), for: selectedMetric, unitFormatter: UnitFormatter(settings: AppSettings.shared))
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
        let unitFormatter = UnitFormatter(settings: AppSettings.shared)
        let allGraphPoints = activeReports
            .compactMap { point(for: $0, metric: metric, history: globalReports, unitFormatter: unitFormatter) }
            .sorted { $0.date < $1.date }
        let globalAllGraphPoints = globalReports
            .compactMap { point(for: $0, metric: metric, history: globalReports, unitFormatter: unitFormatter) }
            .sorted { $0.date < $1.date }
        let cutoffDate = period.cutoffDate(relativeTo: allGraphPoints.last?.date ?? Date())
        let periodGraphPoints = cutoffDate.map { cutoff in
            allGraphPoints.filter { $0.date >= cutoff }
        } ?? allGraphPoints
        let periodSummary = makePeriodSummary(points: periodGraphPoints, metric: metric, unitFormatter: unitFormatter)
        let currentPrevious = makeCurrentPrevious(points: allGraphPoints, metric: metric, unitFormatter: unitFormatter)
        let bestResult = makeBestResult(points: globalAllGraphPoints,
                                        reports: globalReports,
                                        metric: metric,
                                        history: globalReports,
                                        unitFormatter: unitFormatter)
        
        return PreparedStatistics(allGraphPoints: allGraphPoints,
                                  globalAllGraphPoints: globalAllGraphPoints,
                                  periodGraphPoints: periodGraphPoints,
                                  periodSummary: periodSummary,
                                  currentPrevious: currentPrevious,
                                  bestResult: bestResult)
    }
    
    private static func defaultMetric(for trackingType: ExerciseTrackingType?) -> ExerciseMetricSegment {
        availableMetrics(for: trackingType).first ?? .repetitions
    }
    
    private static func availableMetrics(for trackingType: ExerciseTrackingType?) -> [ExerciseMetricSegment] {
        switch trackingType {
        case .weightedReps:
            return [.weight, .volume, .repetitions]
        case .repsOnly:
            return [.repetitions]
        case .timed:
            return [.time]
        case .distance:
            return [.distance]
        case .distanceTime:
            return [.distance, .time, .pace]
        case nil:
            return [.repetitions]
        }
    }
    
    private static func makePeriodSummary(points: [ExerciseStatisticsPoint],
                                          metric: ExerciseMetricSegment,
                                          unitFormatter: UnitFormatter) -> PeriodSummary {
        guard !points.isEmpty else { return .empty }
        
        let average = points.reduce(Float.zero) { $0 + $1.value } / Float(points.count)
        let change = points.count > 1 ? points[points.count - 1].value - points[0].value : nil
        
        return PeriodSummary(averageText: formatted(value: average, for: metric, unitFormatter: unitFormatter),
                             changeText: change.map { formattedChange($0, for: metric, unitFormatter: unitFormatter) } ?? "-",
                             changeColor: color(for: change, metric: metric))
    }
    
    private static func makeCurrentPrevious(points: [ExerciseStatisticsPoint],
                                            metric: ExerciseMetricSegment,
                                            unitFormatter: UnitFormatter) -> CurrentPreviousSummary {
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
                                      changeText: formattedChange(change, for: metric, unitFormatter: unitFormatter),
                                      changeColor: color(for: change, metric: metric))
    }
    
    private static func makeBestResult(points: [ExerciseStatisticsPoint],
                                       reports: [ReportExerciseModel],
                                       metric: ExerciseMetricSegment,
                                       history: [ReportExerciseModel],
                                       unitFormatter: UnitFormatter) -> BestResultSummary {
        let bestPoint: ExerciseStatisticsPoint?
        
        if metric == .repetitions {
            bestPoint = bestSetResult(reports: reports, history: history, unitFormatter: unitFormatter)
        } else if metric.isLowerValueBetter {
            bestPoint = points.min(by: { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.date < rhs.date
                }
                return lhs.value < rhs.value
            })
        } else {
            bestPoint = points.max(by: { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.date > rhs.date
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
                                 subtitle: String(localized: "reports.statistics.across_all_workouts"))
    }
    
    private static func point(for report: ReportExerciseModel,
                              metric: ExerciseMetricSegment,
                              history: [ReportExerciseModel],
                              unitFormatter: UnitFormatter) -> ExerciseStatisticsPoint? {
        guard let date = report.date else { return nil }
        
        switch metric {
        case .weight:
            let sets = performedStrengthSets(in: report)
            guard !sets.isEmpty else { return nil }
            guard let weight = sets.map(\.weight).max() else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: weight,
                                           formattedValue: formattedKilograms(weight, unitFormatter: unitFormatter),
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        case .volume:
            let sets = performedStrengthSets(in: report)
            guard !sets.isEmpty else { return nil }
            let volume = sets.reduce(Float.zero) { $0 + ($1.weight * Float($1.reps)) }
            guard volume > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: volume,
                                           formattedValue: formattedKilograms(volume, unitFormatter: unitFormatter),
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        case .repetitions:
            if let weightedRepetitionPoint = weightedRepetitionPoint(for: report, date: date, history: history, unitFormatter: unitFormatter) {
                return weightedRepetitionPoint
            }
            return bodyweightRepetitionPoint(for: report, date: date, history: history, unitFormatter: unitFormatter)
        case .time:
            let value = performedTime(in: report)
            guard value > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: Float(value),
                                           formattedValue: value.timeForDisplay,
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        case .distance:
            let value = performedDistance(in: report)
            guard value > 0 else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: value,
                                           formattedValue: unitFormatter.distanceText(meters: value),
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        case .pace:
            guard let value = performedPace(in: report) else { return nil }
            return ExerciseStatisticsPoint(reportId: report.id,
                                           date: date,
                                           value: value,
                                           formattedValue: formattedPace(value, unitFormatter: unitFormatter),
                                           isPersonalRecord: isPersonalRecord(report, history: history))
        }
    }
    
    private static func weightedRepetitionPoint(for report: ReportExerciseModel,
                                                date: Date,
                                                history: [ReportExerciseModel],
                                                unitFormatter: UnitFormatter) -> ExerciseStatisticsPoint? {
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
                                       formattedValue: "\(unitFormatter.weightText(kilograms: weight)) \(unitFormatter.weightUnit.symbol) x \(unitFormatter.repetitionsText(reps))",
                                       isPersonalRecord: isPersonalRecord(report, history: history))
    }
    
    private static func bodyweightRepetitionPoint(for report: ReportExerciseModel,
                                                  date: Date,
                                                  history: [ReportExerciseModel],
                                                  unitFormatter: UnitFormatter) -> ExerciseStatisticsPoint? {
        let reps = performedRepsOnlySets(in: report).reduce(0, +)
        guard reps > 0 else { return nil }
        
        return ExerciseStatisticsPoint(reportId: report.id,
                                       date: date,
                                       value: Float(reps),
                                       formattedValue: unitFormatter.repetitionsText(reps),
                                       isPersonalRecord: isPersonalRecord(report, history: history))
    }
    
    private static func bestSetResult(reports: [ReportExerciseModel],
                                      history: [ReportExerciseModel],
                                      unitFormatter: UnitFormatter) -> ExerciseStatisticsPoint? {
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
                                               formattedValue: "\(unitFormatter.weightText(kilograms: bestSet.set.weight)) \(unitFormatter.weightUnit.symbol) x \(unitFormatter.repetitionsText(bestSet.set.reps))",
                                               isPersonalRecord: isPersonalRecord(bestSet.report, history: history))
            }
        }
        
        return reports
            .compactMap { report -> ExerciseStatisticsPoint? in
                guard let date = report.date else { return nil }
                return bodyweightRepetitionPoint(for: report, date: date, history: history, unitFormatter: unitFormatter)
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
    
    private static func performedTime(in report: ReportExerciseModel) -> TimeInterval {
        report.sets.reduce(TimeInterval.zero) { partialResult, set in
            partialResult + (ReportStatusService.timeValue(for: set.parameters) ?? 0)
        }
    }
    
    private static func performedDistance(in report: ReportExerciseModel) -> Float {
        report.sets.reduce(Float.zero) { partialResult, set in
            partialResult + (ReportStatusService.distanceValue(for: set.parameters) ?? 0)
        }
    }
    
    private static func performedPace(in report: ReportExerciseModel) -> Float? {
        let distance = performedDistance(in: report)
        let time = performedTime(in: report)
        guard distance > 0, time > 0 else { return nil }
        return Float(time) / distance
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
        case .time:
            return difference < 1
        case .distance:
            let baseline = max(abs(lhs), abs(rhs), 1)
            return difference / baseline < 0.02
        case .pace:
            return difference < 0.01
        }
    }
    
    private static func formatted(value: Float, for metric: ExerciseMetricSegment, unitFormatter: UnitFormatter) -> String {
        switch metric {
        case .weight, .volume:
            formattedKilograms(value, unitFormatter: unitFormatter)
        case .repetitions:
            "\(Int(value.rounded()))"
        case .time:
            TimeInterval(value).timeForDisplay
        case .distance:
            unitFormatter.distanceText(meters: value)
        case .pace:
            formattedPace(value, unitFormatter: unitFormatter)
        }
    }
    
    private static func formattedChange(_ value: Float,
                                        for metric: ExerciseMetricSegment,
                                        unitFormatter: UnitFormatter) -> String {
        guard value != 0 else { return "0 \(metric.changeUnit(unitFormatter: unitFormatter))" }
        let isImprovement = metric.isLowerValueBetter ? value < 0 : value > 0
        let sign = isImprovement ? "+" : "-"
        let absValue = abs(value)
        
        switch metric {
        case .weight, .volume:
            return "\(sign)\(formattedKilograms(absValue, unitFormatter: unitFormatter))"
        case .repetitions:
            return "\(sign)\(unitFormatter.repetitionsText(Int(absValue.rounded())))"
        case .time:
            return "\(sign)\(TimeInterval(absValue).timeForDisplay)"
        case .distance:
            return "\(sign)\(unitFormatter.distanceText(meters: absValue))"
        case .pace:
            return "\(sign)\(formattedPace(absValue, unitFormatter: unitFormatter))"
        }
    }
    
    private static func formattedKilograms(_ value: Float, unitFormatter: UnitFormatter) -> String {
        unitFormatter.weightTextWithUnit(kilograms: value)
    }
    
    private static func formattedNumber(_ value: Float) -> String {
        let number = Double(value)
        if number.rounded() == number {
            return Int(number).formatted(.number)
        }
        return number.formatted(.number.precision(.fractionLength(1)))
    }
    
    private static func formattedPace(_ value: Float, unitFormatter: UnitFormatter) -> String {
        unitFormatter.paceText(secondsPerMeter: value)
    }
    
    private static func color(for change: Float?, metric: ExerciseMetricSegment? = nil) -> Color {
        guard let change else { return AppColor.textSecondary }
        let isLowerValueBetter = metric?.isLowerValueBetter == true
        if isLowerValueBetter {
            if change < 0 { return AppColor.progressGreen }
            if change > 0 { return AppColor.progressRed }
        } else {
            if change > 0 { return AppColor.progressGreen }
            if change < 0 { return AppColor.progressRed }
        }
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
    case time
    case distance
    case pace
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .weight:
            String(localized: "reports.summary.weight")
        case .volume:
            String(localized: "reports.summary.volume")
        case .repetitions:
            String(localized: "reports.summary.repetitions")
        case .time:
            String(localized: "reports.summary.time")
        case .distance:
            String(localized: "reports.summary.distance")
        case .pace:
            String(localized: "reports.summary.pace")
        }
    }
    
    var subtitle: String {
        switch self {
        case .weight:
            String(localized: "reports.statistics.metric.weight.subtitle")
        case .volume:
            String(localized: "reports.statistics.metric.volume.subtitle")
        case .repetitions:
            String(localized: "reports.statistics.metric.repetitions.subtitle")
        case .time:
            String(localized: "reports.statistics.metric.time.subtitle")
        case .distance:
            String(localized: "reports.statistics.metric.distance.subtitle")
        case .pace:
            String(localized: "reports.statistics.metric.pace.subtitle")
        }
    }
    
    var bestResultTitle: String {
        switch self {
        case .weight:
            String(localized: "reports.statistics.best.weight")
        case .volume:
            String(localized: "reports.statistics.best.volume")
        case .repetitions:
            String(localized: "reports.statistics.best.set")
        case .time:
            String(localized: "reports.statistics.best.time")
        case .distance:
            String(localized: "reports.statistics.best.distance")
        case .pace:
            String(localized: "reports.statistics.best.pace")
        }
    }
    
    func axisUnit(unitFormatter: UnitFormatter) -> String {
        switch self {
        case .weight, .volume:
            unitFormatter.weightUnit.symbol
        case .repetitions:
            unitFormatter.repetitionsUnitText
        case .time:
            String(localized: "reports.statistics.axis.time")
        case .distance:
            unitFormatter.distanceUnit == .metric ? "m" : "ft"
        case .pace:
            unitFormatter.distanceUnit == .metric ? String(localized: "reports.statistics.axis.pace_km") : String(localized: "reports.statistics.axis.pace_mi")
        }
    }
    
    func changeUnit(unitFormatter: UnitFormatter) -> String {
        switch self {
        case .weight, .volume:
            unitFormatter.weightUnit.symbol
        case .repetitions:
            unitFormatter.repetitionsUnitText
        case .time:
            String(localized: "reports.statistics.axis.time")
        case .distance:
            unitFormatter.distanceUnit == .metric ? "m" : "ft"
        case .pace:
            unitFormatter.distanceUnit == .metric ? String(localized: "reports.statistics.axis.pace_km") : String(localized: "reports.statistics.axis.pace_mi")
        }
    }
    
    var showsPeriodSummary: Bool {
        self != .repetitions
    }
    
    var isLowerValueBetter: Bool {
        self == .pace
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
            String(localized: "reports.statistics.period.all")
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
                          subtitle: String(localized: "reports.statistics.across_all_workouts"))
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
