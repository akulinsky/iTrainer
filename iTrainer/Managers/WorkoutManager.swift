//
//  WorkoutManager.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 10.09.2024.
//

import Foundation

final class WorkoutManager: ObservableObject {
    
    // MARK: - Properties
    
    private enum Constants {
        static let sessionSnapshotKey = "activeWorkoutSessionSnapshot"
    }
    
    private struct WorkoutSessionSnapshot: Codable {
        let reportWorkoutId: UUID
        let workoutGroupId: UUID
        let workoutStartedAt: Date
        let activeExerciseId: UUID?
        let restStartedAt: Date?
        let restDuration: TimeInterval?
        let lastSavedAt: Date
    }
    
    private var workoutId: UUID?
    
    private var workoutGroupId: UUID?
    
    /// Workout time
    private var workoutTimer: DispatchSourceTimer?
    private var workoutTimeInterval: TimeInterval = 0.0
    private var workoutStartedAt: Date?
    private var isRunningWorkoutTimer = false
    
    /// Rest time
    private var isRunningRestTime = false
    private var restTimeInterval: TimeInterval = 0.0
    private var restTimeIntervalExercise: TimeInterval = 0.0
    private var currentRestTimeIntervalExercise: TimeInterval?
    private var restStartedAt: Date?
    
    @Published var restTime: String = ""
    
    @Published var progressRestTime: Double = 1.0
    
    @Published var workoutTime: String = ""
    
    @Published private(set) var isWorkoutInProgress = false
    
    @Published private(set) var workoutElapsedTime: TimeInterval = 0
    
    @Published private(set) var currentRestTime: TimeInterval?
    
    @Published private(set) var workoutProgress: Double = 0
    
    @Published private(set) var currentWorkoutTitle: String = "Active workout"
    
    @Published private(set) var currentWorkoutGroupId: UUID?
    
    @Published private(set) var activeExerciseId: UUID?
    
    @Published private(set) var reportedExerciseIds = Set<UUID>()
    
    @Published private(set) var exerciseProgressById = [UUID: Double]()
    
    var finishWorkoutAlertMessage: String {
        guard isWorkoutInProgress,
              targetExercisesCount > 0,
              completedExercisesCount < targetExercisesCount else {
            return "Current workout will be closed."
        }
        
        return "You completed \(completedExercisesCount) of \(targetExercisesCount) exercises. Finish anyway?"
    }
    
    private var completedExercisesCount = 0
    
    private var targetExercisesCount = 0
    
    // MARK: - Init
    
    init() {
        setup()
    }
    
    private func setup() {
        print("DBG_ WorkoutManager setup")
        restoreSessionIfNeeded()
        
        Task {
            print("DBG_ --------------")
            print("DBG_  ReportWorkoutModelDB: \(await ReportWorkoutModelDB.count())")
            print("DBG_  ReportExerciseModelDB: \(await ReportExerciseModelDB.count())")
            print("DBG_  ReportSetsModelDB: \(await ReportSetsModelDB.count())")
        }
    }
    
    // MARK: - Private methods
    
    private func updateWorkoutTime() {
        if let workoutStartedAt, isRunningWorkoutTimer {
            workoutTimeInterval = max(Date().timeIntervalSince(workoutStartedAt), 0)
        }
        
        Task {
            await MainActor.run {
                if !self.isRunningWorkoutTimer {
                    self.workoutTime = ""
                    self.workoutElapsedTime = 0
                } else if self.workoutTimeInterval > 3600 {
                    self.workoutTime = self.workoutTimeInterval.hourMinuteSecond
                    self.workoutElapsedTime = self.workoutTimeInterval
                } else {
                    self.workoutTime = self.workoutTimeInterval.minuteSecond
                    self.workoutElapsedTime = self.workoutTimeInterval
                }
            }
        }
    }
    
    private func startTimer(startDate: Date = Date()) {
        if isRunningWorkoutTimer {
            workoutStartedAt = startDate
            updateWorkoutTime()
            return
        }
        
        workoutTimer?.cancel()
        workoutTimer = DispatchSource.makeTimerSource()
        
        let deadline = DispatchTime.now().advanced(by: DispatchTimeInterval.seconds(0))
        workoutTimer?.schedule(deadline: deadline, repeating: DispatchTimeInterval.milliseconds(500))
        workoutTimer?.setEventHandler { [weak self] in self?.fire() }
        
        workoutStartedAt = startDate
        workoutTimeInterval = max(Date().timeIntervalSince(startDate), 0)
        isRunningWorkoutTimer = true
        isWorkoutInProgress = true
        updateWorkoutTime()
        
        workoutTimer?.activate()
    }
    
    private func stopTimer() {
        workoutTimeInterval = 0.0
        workoutId = nil
        workoutGroupId = nil
        workoutStartedAt = nil
        isRunningWorkoutTimer = false
        isWorkoutInProgress = false
        workoutElapsedTime = 0
        workoutProgress = 0
        currentWorkoutTitle = "Active workout"
        currentWorkoutGroupId = nil
        activeExerciseId = nil
        currentRestTimeIntervalExercise = nil
        restStartedAt = nil
        reportedExerciseIds = []
        exerciseProgressById = [:]
        completedExercisesCount = 0
        targetExercisesCount = 0
        updateWorkoutTime()
        workoutTimer?.cancel()
        workoutTimer = nil
        LocalNotificationManager.shared.cancelAllWorkoutNotifications()
        resetRestTime()
        updateRestTime()
    }
    
    private func fire() {
        updateWorkoutTime()
        
        if isRunningRestTime {
            updateRestTimeIntervalFromDates()
            updateRestTime()
        }
    }
    
    private func reportWorkout(dataManager: DataManagerBackground) async -> ReportWorkoutModelDB? {
        await dataManager.fetchStartedWorkout()
    }
    
    private func createReportWorkout(with groupId: UUID, dataManager: DataManagerBackground) async -> ReportWorkoutModelDB? {
        guard let group = await dataManager.fetchWorkoutGroup(with: groupId),
                let workout = group.workout else {
            print("Error: \(#file):\(#function) \(#line) group == nil or workout = nil")
            return nil
        }
        
        let reportWorkout = ReportWorkoutModelDB(titleWorkout: workout.title ?? "",
                                                 workoutId: workout.id,
                                                 workoutGroupId: group.id,
                                                 titleWorkoutGroup: group.title ?? "")
        await dataManager.insert(model: reportWorkout)
        
        return reportWorkout
    }
    
    private func startWorkout(with groupId: UUID, dataManager: DataManagerBackground) async {
        if await dataManager.fetchStartedWorkout() != nil {
            print("Error: \(#file):\(#function) \(#line) Workout was started")
            await restoreSession(dataManager: dataManager)
            return
        }
        guard let reportWorkout = await createReportWorkout(with: groupId, dataManager: dataManager) else {
            print("Error: \(#file):\(#function) \(#line) reportWorkout == nil")
            return
        }
        let startDate = Date()
        reportWorkout.startDate = startDate
        let targetExercisesCount = await dataManager.fetchExercises(for: groupId).filter { !$0.isHeadline }.count
        await dataManager.save()
        
        let reportWorkoutId = reportWorkout.id
        let currentWorkoutTitle = reportWorkout.titleWorkoutGroup
        await MainActor.run {
            self.workoutId = reportWorkoutId
            self.workoutGroupId = groupId
            self.currentWorkoutTitle = currentWorkoutTitle
            self.currentWorkoutGroupId = groupId
            self.activeExerciseId = nil
            self.currentRestTimeIntervalExercise = nil
            self.restStartedAt = nil
            self.targetExercisesCount = targetExercisesCount
            self.exerciseProgressById = [:]
            self.completedExercisesCount = 0
            self.reportedExerciseIds = []
            self.updateWorkoutProgress()
            LocalNotificationManager.shared.requestAuthorizationIfNeeded()
            self.startTimer(startDate: startDate)
        }
        saveSessionSnapshot(reportWorkoutId: reportWorkout.id)
        print("DBG_ Workout was started")
    }
    
    private func startRestTime(startedAt: Date = Date()) {
        guard currentRestTimeIntervalExercise != nil else {
            return
        }
        restStartedAt = startedAt
        isRunningRestTime = true
        updateRestTimeIntervalFromDates()
        if restTimeInterval > 0 {
            LocalNotificationManager.shared.scheduleRestFinishedNotification(after: restTimeInterval)
        }
    }
    
    private func resetRestTime() {
        LocalNotificationManager.shared.cancelRestFinishedNotification()
        self.restTimeInterval = self.currentRestTimeIntervalExercise ?? 0.0
        self.restTimeIntervalExercise = self.currentRestTimeIntervalExercise ?? 0.0
        self.isRunningRestTime = false
        self.restStartedAt = nil
        Task {
            await MainActor.run {
                self.progressRestTime = 1.0
                self.currentRestTime = self.currentRestTimeIntervalExercise
            }
        }
    }
    
    private func completeRestTime() {
        restTimeInterval = 0
        restTimeIntervalExercise = currentRestTimeIntervalExercise ?? 0
        isRunningRestTime = false
        restStartedAt = nil
        currentRestTimeIntervalExercise = nil
        Task {
            await MainActor.run {
                self.progressRestTime = 1.0
                self.currentRestTime = nil
                self.restTime = ""
            }
        }
    }
    
    private func updateRestTimeIntervalFromDates() {
        guard isRunningRestTime,
              let restStartedAt,
              let currentRestTimeIntervalExercise else {
            return
        }
        
        restTimeIntervalExercise = currentRestTimeIntervalExercise
        let elapsed = Date().timeIntervalSince(restStartedAt)
        restTimeInterval = max(currentRestTimeIntervalExercise - elapsed, 0)
        if restTimeInterval <= 0 {
            completeRestTime()
        }
    }
    
    private func updateRestTime() {
        Task {
            await MainActor.run {
                self.restTime = self.restTimeInterval.minuteSecond
                self.progressRestTime = self.restTimeIntervalExercise > 0 ? self.restTimeInterval / self.restTimeIntervalExercise : 1.0
                self.currentRestTime = self.currentRestTimeIntervalExercise == nil ? nil : self.restTimeInterval
            }
        }
    }
    
    @MainActor
    private func updateWorkoutProgress() {
        guard targetExercisesCount > 0 else {
            workoutProgress = 0
            return
        }
        workoutProgress = Double(completedExercisesCount) / Double(targetExercisesCount)
    }
    
    private func loadSessionSnapshot() -> WorkoutSessionSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: Constants.sessionSnapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WorkoutSessionSnapshot.self, from: data)
    }
    
    private func saveSessionSnapshot(reportWorkoutId: UUID? = nil) {
        guard let workoutStartedAt,
              let currentWorkoutGroupId,
              let reportWorkoutId = reportWorkoutId ?? workoutId else {
            clearSessionSnapshot()
            return
        }
        
        let snapshot = WorkoutSessionSnapshot(
            reportWorkoutId: reportWorkoutId,
            workoutGroupId: currentWorkoutGroupId,
            workoutStartedAt: workoutStartedAt,
            activeExerciseId: activeExerciseId,
            restStartedAt: isRunningRestTime ? restStartedAt : nil,
            restDuration: isRunningRestTime ? currentRestTimeIntervalExercise : nil,
            lastSavedAt: Date()
        )
        
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Constants.sessionSnapshotKey)
        }
    }
    
    private func clearSessionSnapshot() {
        UserDefaults.standard.removeObject(forKey: Constants.sessionSnapshotKey)
    }
    
    private func restoredActiveExerciseId(reportWorkout: ReportWorkoutModelDB, snapshot: WorkoutSessionSnapshot?) -> UUID? {
        if let activeExerciseId = snapshot?.activeExerciseId,
           reportWorkout.exercises.contains(where: { $0.exerciseId == activeExerciseId }) {
            return activeExerciseId
        }
        
        return reportWorkout.exercises
            .compactMap { reportExercise -> (UUID, Date)? in
                guard let latestSetDate = reportExercise.reportSets.map(\.date).max() else {
                    return nil
                }
                return (reportExercise.exerciseId, latestSetDate)
            }
            .max { $0.1 < $1.1 }?.0
    }
    
    private func restoreRestState(snapshot: WorkoutSessionSnapshot?) {
        guard let restStartedAt = snapshot?.restStartedAt,
              let restDuration = snapshot?.restDuration,
              restDuration > 0 else {
            LocalNotificationManager.shared.cancelRestFinishedNotification()
            completeRestTime()
            return
        }
        
        self.restStartedAt = restStartedAt
        currentRestTimeIntervalExercise = restDuration
        restTimeIntervalExercise = restDuration
        let remaining = max(restDuration - Date().timeIntervalSince(restStartedAt), 0)
        restTimeInterval = remaining
        isRunningRestTime = remaining > 0
        if remaining <= 0 {
            completeRestTime()
        } else {
            updateRestTime()
            LocalNotificationManager.shared.scheduleRestFinishedNotification(after: remaining)
        }
    }
    
    private func restoreSession(dataManager: DataManagerBackground) async {
        guard let reportWorkout = await dataManager.fetchStartedWorkout() else {
            await MainActor.run {
                stopTimer()
            }
            clearSessionSnapshot()
            return
        }
        
        let snapshot = loadSessionSnapshot()
        let reportWorkoutId = reportWorkout.id
        let workoutGroupId = reportWorkout.workoutGroupId
        let currentWorkoutTitle = reportWorkout.titleWorkoutGroup
        let startedAt = reportWorkout.startDate ?? snapshot?.workoutStartedAt ?? Date()
        let exercises = await dataManager.fetchExercises(for: workoutGroupId)
        let targetExercisesCount = exercises.filter { !$0.isHeadline }.count
        let exerciseProgressById = await exerciseProgressById(for: reportWorkout, dataManager: dataManager)
        let reportedExerciseIds = Set(reportWorkout.exercises.map(\.exerciseId))
        let activeExerciseId = restoredActiveExerciseId(reportWorkout: reportWorkout, snapshot: snapshot)
        
        await MainActor.run {
            self.workoutId = reportWorkoutId
            self.workoutGroupId = workoutGroupId
            self.currentWorkoutTitle = currentWorkoutTitle
            self.currentWorkoutGroupId = workoutGroupId
            self.activeExerciseId = activeExerciseId
            self.reportedExerciseIds = reportedExerciseIds
            self.exerciseProgressById = exerciseProgressById
            self.completedExercisesCount = reportedExerciseIds.count
            self.targetExercisesCount = targetExercisesCount
            self.updateWorkoutProgress()
            self.startTimer(startDate: startedAt)
            self.restoreRestState(snapshot: snapshot)
            self.updateWorkoutTime()
        }
        saveSessionSnapshot(reportWorkoutId: reportWorkoutId)
    }
    
    // MARK: - Public methods
    
    func startWorkout(with groupId: UUID) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await self.startWorkout(with: groupId, dataManager: dataManager)
        }
    }
    
    func restoreSessionIfNeeded() {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await restoreSession(dataManager: dataManager)
        }
    }
    
    func persistSessionState() {
        saveSessionSnapshot()
    }
    
    func appDidEnterBackground() {
        persistSessionState()
        guard isWorkoutInProgress else { return }
        LocalNotificationManager.shared.scheduleActiveWorkoutReminder(workoutTitle: currentWorkoutTitle)
    }
    
    func appDidBecomeActive() {
        LocalNotificationManager.shared.cancelActiveWorkoutReminder()
        restoreSessionIfNeeded()
    }
    
    func endWorkout(complete: ((ReportWorkoutModel?) -> Void)? = nil) {
        persistSessionState()
        stopTimer()
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            guard let reportWorkout = await self.reportWorkout(dataManager: dataManager) else {
                print("Error: \(#file):\(#function) \(#line) reportWorkout == nil")
                await MainActor.run {
                    complete?(nil)
                }
                clearSessionSnapshot()
                return
            }
            reportWorkout.endDate = Date()
            
            let reportExercises = reportWorkout.exercises
            
            guard !reportExercises.isEmpty else {
                await dataManager.remove(model: reportWorkout)
                await dataManager.save()
                print("DBG_ ReportExercises.count == 0")
                print("DBG_ Report was removed")
                await MainActor.run {
                    complete?(nil)
                }
                clearSessionSnapshot()
                return
            }
            
            let exercises = await dataManager.fetchExercises(for: reportWorkout.workoutGroupId)
            
            reportWorkout.targetExercisesCount = exercises.filter({ !$0.isHeadline }).count
            
            for exercise in exercises {
                if let reportExercise = reportExercises.first(where: { $0.exerciseId == exercise.id }) {
                    let targetSets = exercise.sets.map { $0.copy() }
                    
                    for set in targetSets {
                        await dataManager.insert(model: set)
                        set.reportExercise = reportExercise
                    }
                }
            }
            await dataManager.save()
            let report = ReportWorkoutModel(model: reportWorkout)
            print("DBG_ Workout was finished")
            await MainActor.run {
                complete?(report)
            }
            clearSessionSnapshot()
        }
    }
    
    func addReportSet(with params: [SetsParameter], for exerciseId: UUID) async {
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        
        guard let exercise = await dataManager.fetchExercise(with: exerciseId),
                let workoutGroupId = exercise.workoutGroup?.id else {
            print("Error: \(#file):\(#function) \(#line) Can't add report: exercise == nil or workoutGroupId == nil")
            return
        }
        
        var reportWorkout = await self.reportWorkout(dataManager: dataManager)
        
        /// Start the workout
        if reportWorkout == nil {
            await self.startWorkout(with: workoutGroupId, dataManager: dataManager)
            reportWorkout = await self.reportWorkout(dataManager: dataManager)
        }
        
        guard let reportWorkout = reportWorkout else {
            print("Error: \(#file):\(#function) \(#line) Can't add report: reportWorkout == nil")
            return
        }
        
        var reportExercise = reportWorkout.exercises.first(where: { $0.exerciseId == exerciseId })
        
        /// Create the report exercises
        if reportExercise == nil {
            reportExercise = ReportExerciseModelDB(titleExercise: ExerciseModel(model: exercise).displayName,
                                                    exerciseId: exercise.id,
                                                    index: exercise.index,
                                                    typeId: exercise.typeId,
                                                    restTime: exercise.restTime)
            await dataManager.insert(model: reportExercise!)
            reportExercise?.report = reportWorkout
        }
        
        guard let reportExercise = reportExercise else {
            print("Error: \(#file):\(#function) \(#line) reportExercise == nil")
            return
        }
        
        let report = ReportSetsModelDB(date: Date())
        await dataManager.insert(model: report)
        report.reportExercise = reportExercise
        
        for param in params {
            switch param {
            case .weight(let value):
                report.weight = value
            case .repeats(let value):
                report.reps = value
            case .distance(let value):
                report.distance = value
            case .time(let value):
                report.time = value
            }
        }
        
        await dataManager.save()
        
        let reportWorkoutId = reportWorkout.id
        let currentWorkoutTitle = reportWorkout.titleWorkoutGroup
        let reportedExerciseIds = Set(reportWorkout.exercises.map(\.exerciseId))
        let exerciseProgressById = await exerciseProgressById(for: reportWorkout, dataManager: dataManager)
        let exercises = await dataManager.fetchExercises(for: workoutGroupId)
        let targetExercisesCount = exercises.filter { !$0.isHeadline }.count
        let restDuration = exercise.restTime
        let restStartedAt = Date()
        
        await MainActor.run {
            self.workoutId = reportWorkoutId
            self.workoutGroupId = workoutGroupId
            self.currentWorkoutTitle = currentWorkoutTitle
            self.currentWorkoutGroupId = workoutGroupId
            self.activeExerciseId = exerciseId
            self.reportedExerciseIds = reportedExerciseIds
            self.exerciseProgressById = exerciseProgressById
            self.completedExercisesCount = reportedExerciseIds.count
            self.targetExercisesCount = targetExercisesCount
            self.currentRestTimeIntervalExercise = restDuration
            self.updateWorkoutProgress()
            self.resetRestTime()
            self.startRestTime(startedAt: restStartedAt)
            self.updateRestTime()
        }
        saveSessionSnapshot(reportWorkoutId: reportWorkout.id)
        
        print("DBG_ Report was added")
    }
    
    func removeReportSet(id: UUID) async {
        await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).removeReportSets(with: id)
    }
    
    private func exerciseProgressById(for reportWorkout: ReportWorkoutModelDB, dataManager: DataManagerBackground) async -> [UUID: Double] {
        var progressById = [UUID: Double]()
        
        for reportExercise in reportWorkout.exercises {
            guard let exercise = await dataManager.fetchExercise(with: reportExercise.exerciseId) else {
                continue
            }
            
            let targetSetCount = exercise.sets.count
            guard targetSetCount > 0 else {
                progressById[reportExercise.exerciseId] = 1
                continue
            }
            
            progressById[reportExercise.exerciseId] = min(Double(reportExercise.reportSets.count) / Double(targetSetCount), 1)
        }
        
        return progressById
    }
}
