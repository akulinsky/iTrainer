//
//  WorkoutManager.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 10.09.2024.
//

import Foundation

final class WorkoutManager: ObservableObject {
    
    // MARK: - Properties
    
    private var workoutId: UUID?
    
    private var workoutGroupId: UUID?
    
    /// Workout time
    private var workoutTimer: DispatchSourceTimer?
    private var workoutTimeInterval: TimeInterval = 0.0
    private var isRunningWorkoutTimer = false
    
    /// Rest time
    private var isRunningRestTime = false
    private var restTimeInterval: TimeInterval = 0.0
    private var restTimeIntervalExercise: TimeInterval = 0.0
    private var currentRestTimeIntervalExercise: TimeInterval?
    
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
    
    private var completedExercisesCount = 0
    
    private var targetExercisesCount = 0
    
    // MARK: - Init
    
    init() {
        setup()
    }
    
    private func setup() {
        print("DBG_ WorkoutManager setup")
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            if await dataManager.fetchStartedWorkout() != nil {
                endWorkout()
            }
            
            print("DBG_ --------------")
            print("DBG_  ReportWorkoutModelDB: \(await ReportWorkoutModelDB.count())")
            print("DBG_  ReportExerciseModelDB: \(await ReportExerciseModelDB.count())")
            print("DBG_  ReportSetsModelDB: \(await ReportSetsModelDB.count())")
            
//            await dataManager.removeAll(type: ReportWorkoutModelDB.self)
//            await dataManager.removeAll(type: ReportExerciseModelDB.self)
//            await dataManager.removeAll(type: ReportSetsModelDB.self)
//            await dataManager.save()
//            
//            print("DBG_  ReportWorkoutModelDB: \(await ReportWorkoutModelDB.count())")
//            print("DBG_  ReportExerciseModelDB: \(await ReportExerciseModelDB.count())")
//            print("DBG_  ReportSetsModelDB: \(await ReportSetsModelDB.count())")
        }
    }
    
    // MARK: - Private methods
    
    private func updateWorkoutTime() {
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
        
//        print("DBG_ workoutTime: \(self.workoutTime)")
    }
    
    private func startTimer() {
        
        if isRunningWorkoutTimer {
            return
        }
        
        workoutTimer = DispatchSource.makeTimerSource()
        
        let deadline = DispatchTime.now().advanced(by: DispatchTimeInterval.seconds(0))
        workoutTimer?.schedule(deadline: deadline, repeating: DispatchTimeInterval.milliseconds(100))
        workoutTimer?.setEventHandler { [weak self] in self?.fire() }
        
        workoutTimeInterval = 0.0
        isRunningWorkoutTimer = true
        isWorkoutInProgress = true
        updateWorkoutTime()
        
        workoutTimer?.activate()
    }
    
    private func stopTimer() {
        workoutTimeInterval = 0.0
        isRunningWorkoutTimer = false
        isWorkoutInProgress = false
        workoutElapsedTime = 0
        workoutProgress = 0
        currentWorkoutTitle = "Active workout"
        currentWorkoutGroupId = nil
        activeExerciseId = nil
        currentRestTimeIntervalExercise = nil
        reportedExerciseIds = []
        exerciseProgressById = [:]
        completedExercisesCount = 0
        targetExercisesCount = 0
        updateWorkoutTime()
        workoutTimer?.cancel()
        resetRestTime()
        updateRestTime()
    }
    
    private func fire() {
        workoutTimeInterval += 0.1
        updateWorkoutTime()
        
        if isRunningRestTime {
            if restTimeInterval > 0 {
                restTimeInterval -= 0.1
            } else {
                resetRestTime()
            }
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
            return
        }
        guard let reportWorkout = await createReportWorkout(with: groupId, dataManager: dataManager) else {
            print("Error: \(#file):\(#function) \(#line) reportWorkout == nil")
            return
        }
        reportWorkout.startDate = Date()
        let targetExercisesCount = await dataManager.fetchExercises(for: groupId).filter { !$0.isHeadline }.count
        await dataManager.save()
        
        let currentWorkoutTitle = reportWorkout.titleWorkoutGroup
        await MainActor.run {
            self.currentWorkoutTitle = currentWorkoutTitle
            self.currentWorkoutGroupId = groupId
            self.activeExerciseId = nil
            self.currentRestTimeIntervalExercise = nil
            self.targetExercisesCount = targetExercisesCount
            self.exerciseProgressById = [:]
            self.completedExercisesCount = 0
            self.reportedExerciseIds = []
            self.updateWorkoutProgress()
            startTimer()
        }
        print("DBG_ Workout was started")
    }
    
    private func startRestTime() {
        guard currentRestTimeIntervalExercise != nil else {
            return
        }
        self.isRunningRestTime = true
    }
    
    private func resetRestTime() {
        self.restTimeInterval = self.currentRestTimeIntervalExercise ?? 0.0
        self.restTimeIntervalExercise = self.currentRestTimeIntervalExercise ?? 0.0
        self.isRunningRestTime = false
        Task {
            await MainActor.run {
                self.progressRestTime = 1.0
                self.currentRestTime = self.currentRestTimeIntervalExercise
            }
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
    
    // MARK: - Public methods
    
    func startWorkout(with groupId: UUID) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await self.startWorkout(with: groupId, dataManager: dataManager)
        }
    }
    
    func endWorkout(complete: ((ReportWorkoutModel?) -> Void)? = nil) {
        
        stopTimer()
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            guard let reportWorkout = await self.reportWorkout(dataManager: dataManager) else {
                print("Error: \(#file):\(#function) \(#line) reportWorkout == nil")
                await MainActor.run {
                    complete?(nil)
                }
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
//                startWorkout(with: workoutGroupId)
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
        
        let currentWorkoutTitle = reportWorkout.titleWorkoutGroup
        let reportedExerciseIds = Set(reportWorkout.exercises.map(\.exerciseId))
        let exerciseProgressById = await exerciseProgressById(for: reportWorkout, dataManager: dataManager)
        let exercises = await dataManager.fetchExercises(for: workoutGroupId)
        let targetExercisesCount = exercises.filter { !$0.isHeadline }.count
        currentRestTimeIntervalExercise = exercise.restTime
        
        await MainActor.run {
            self.currentWorkoutTitle = currentWorkoutTitle
            self.currentWorkoutGroupId = workoutGroupId
            self.activeExerciseId = exerciseId
            self.reportedExerciseIds = reportedExerciseIds
            self.exerciseProgressById = exerciseProgressById
            self.completedExercisesCount = reportedExerciseIds.count
            self.targetExercisesCount = targetExercisesCount
            self.updateWorkoutProgress()
        }
        
        resetRestTime()
        startRestTime()
        updateRestTime()
        
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
