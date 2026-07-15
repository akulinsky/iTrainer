//
//  DatabaseSeeder.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.06.2026.
//

import Foundation

enum DatabaseSeedMode {
    case production
    case clean
    case cleanReports
    case testData
    case testReports
}

struct DatabaseSeeder {
    
    private enum ReportFixture {
        static let workoutTitle = "[Fixture] Workout Reports"
        static let chestBackTitle = "Chest & Back"
        static let shouldersLegsTitle = "Shoulders & Legs"
        static let reportWeeks = 104
        static let sessionsPerWeek = 3
        
        static let chestBackExerciseIds = [
            "chest_bench_press",
            "chest_incline_dumbbell_press",
            "back_barbell_row"
        ]
        
        static let shouldersLegsExerciseIds = [
            "shoulders_seated_dumbbell_press",
            "legs_barbell_squat",
            "legs_leg_press"
        ]
    }
    
    private struct FixtureExercisePlan {
        let typeId: String
        let baseWeight: Float
        let baseReps: Int
    }
    
    private struct FixtureSetPlan {
        let weight: Float
        let reps: Int
    }
    
    let dataContainer: DataContainer
    
    func run(_ mode: DatabaseSeedMode) async {
        switch mode {
        case .production:
            break
        case .clean:
            await cleanDatabase()
        case .cleanReports:
            await cleanReportFixtures()
        case .testData:
            await cleanDatabase()
            await seedTestData()
        case .testReports:
            await cleanReportFixtures()
            await seedReportFixtures()
        }
    }
    
    private func cleanDatabase() async {
        let dataManager = DataManagerBackground(container: dataContainer.sharedModelContainer)
        
        await dataManager.removeAll(type: WorkoutModelDB.self)
        await dataManager.removeAll(type: WorkoutGroupModelDB.self)
        await dataManager.removeAll(type: ExerciseModelDB.self)
        await dataManager.removeAll(type: SetsModelDB.self)
        
        await dataManager.removeAll(type: ReportWorkoutModelDB.self)
        await dataManager.removeAll(type: ReportExerciseModelDB.self)
        await dataManager.removeAll(type: ReportSetsModelDB.self)
        await dataManager.save()
    }
    
    private func cleanReportFixtures() async {
        let dataManager = DataManagerBackground(container: dataContainer.sharedModelContainer)
        let fixtureTitle = ReportFixture.workoutTitle
        
        let fixtureWorkouts = await dataManager.fetchModels(predicate: #Predicate<WorkoutModelDB> { workout in
            workout.title == fixtureTitle
        })
        let fixtureWorkoutIds = Set(fixtureWorkouts.map(\.id))
        
        let fixtureReports = await dataManager.fetchModels(predicate: #Predicate<ReportWorkoutModelDB> { report in
            report.titleWorkout == fixtureTitle
        })
        
        for report in fixtureReports {
            await dataManager.removeReportWorkout(with: report.id, withSaving: false)
        }
        
        if !fixtureWorkoutIds.isEmpty {
            let allReports = await dataManager.fetchAllReportWorkout()
            for report in allReports where fixtureWorkoutIds.contains(report.workoutId) {
                await dataManager.removeReportWorkout(with: report.id, withSaving: false)
            }
        }
        
        for workout in fixtureWorkouts {
            await dataManager.removeWorkout(with: workout.id, withSaving: false)
        }
        
        await dataManager.save()
    }
    
    private func seedTestData() async {
        let dataManager = DataManagerBackground(container: dataContainer.sharedModelContainer)
        await addTestWorkout(dataManager: dataManager)
        await dataManager.save()
    }
    
    private func addTestWorkout(dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = WorkoutModelDB()
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout \(index)"
            item.isSelected = index == 1
            
            await addTestGroup(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestGroup(for workout: WorkoutModelDB, dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = WorkoutGroupModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout group \(index)"
            item.workout = workout
            
            await addTestExercise(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestExercise(for group: WorkoutGroupModelDB, dataManager: DataManagerBackground) async {
        let exerciseIds = [
            "chest_bench_press",
            "chest_incline_dumbbell_press",
            "chest_dips",
            "back_pull_up",
            "back_barbell_row",
            "shoulders_seated_dumbbell_press"
        ]
        
        var currentCategoryId: String?
        var index = 0
        
        for exerciseId in exerciseIds {
            guard let exerciseType = dataContainer.arrayExercises.first(where: { $0.id == exerciseId }) else {
                assertionFailure("Missing test exercise with id: \(exerciseId)")
                continue
            }
            
            if currentCategoryId != exerciseType.type.id {
                let headline = ExerciseModelDB()
                
                await dataManager.insert(model: headline)
                headline.index = index
                headline.title = exerciseType.type.displayName
                headline.kind = .headline
                headline.workoutGroup = group
                
                currentCategoryId = exerciseType.type.id
                index += 1
            }
            
            let item = ExerciseModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.typeId = exerciseId
            item.workoutGroup = group
            item.restTime = 120.0
            
            await addTestSets(for: item, dataManager: dataManager)
            index += 1
        }
    }
    
    private func addTestSets(for exercise: ExerciseModelDB, dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = SetsModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            guard let typeExercise = dataContainer.arrayExercises.first(where: { $0.id == exercise.typeId }) else {
                assertionFailure("Missing exercise type with id: \(exercise.typeId)")
                continue
            }
            
            for param in typeExercise.parameters {
                switch param {
                case .weight(_):
                    item.weight = 50.0 + Float((index - 2)) * 10.0
                case .repeats(_):
                    item.reps = 10 - (index - 1)
                case .distance(_):
                    item.distance = 500 * Float(index)
                case .time(_):
                    item.time = TimeInterval(60 * index)
                }
            }
            
            item.exercise = exercise
        }
    }
    
    private func seedReportFixtures() async {
        let dataManager = DataManagerBackground(container: dataContainer.sharedModelContainer)
        let workout = await createReportFixtureWorkout(dataManager: dataManager)
        let groups = workout.workoutGroups.sorted { $0.index < $1.index }
        guard groups.count == 2 else {
            assertionFailure("Report fixture must contain exactly two workout groups")
            await dataManager.save()
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .weekOfYear,
                                              value: -ReportFixture.reportWeeks,
                                              to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let totalSessions = ReportFixture.reportWeeks * ReportFixture.sessionsPerWeek
        
        for sessionIndex in 0..<totalSessions {
            let group = groups[sessionIndex % groups.count]
            let sessionDate = fixtureSessionDate(startDate: startDate, sessionIndex: sessionIndex)
            let isFinalSession = sessionIndex >= totalSessions - 6
            let isIncompleteSession = sessionIndex == totalSessions - 2
            await createReportFixtureSession(for: workout,
                                             group: group,
                                             sessionIndex: sessionIndex,
                                             date: sessionDate,
                                             isFinalSession: isFinalSession,
                                             isIncompleteSession: isIncompleteSession,
                                             dataManager: dataManager)
        }
        
        await dataManager.save()
    }
    
    private func createReportFixtureWorkout(dataManager: DataManagerBackground) async -> WorkoutModelDB {
        let workout = WorkoutModelDB()
        await dataManager.insert(model: workout)
        workout.index = await dataManager.count(type: WorkoutModelDB.self)
        workout.title = ReportFixture.workoutTitle
        workout.isSelected = false
        
        let chestBack = await createReportFixtureGroup(title: ReportFixture.chestBackTitle,
                                                       index: 1,
                                                       exerciseIds: ReportFixture.chestBackExerciseIds,
                                                       workout: workout,
                                                       dataManager: dataManager)
        let shouldersLegs = await createReportFixtureGroup(title: ReportFixture.shouldersLegsTitle,
                                                           index: 2,
                                                           exerciseIds: ReportFixture.shouldersLegsExerciseIds,
                                                           workout: workout,
                                                           dataManager: dataManager)
        workout.workoutGroups = [chestBack, shouldersLegs]
        return workout
    }
    
    private func createReportFixtureGroup(title: String,
                                          index: Int,
                                          exerciseIds: [String],
                                          workout: WorkoutModelDB,
                                          dataManager: DataManagerBackground) async -> WorkoutGroupModelDB {
        let group = WorkoutGroupModelDB()
        await dataManager.insert(model: group)
        group.index = index
        group.title = title
        group.workout = workout
        
        for (exerciseIndex, exerciseId) in exerciseIds.enumerated() {
            guard dataContainer.arrayExercises.contains(where: { $0.id == exerciseId }) else {
                assertionFailure("Missing report fixture exercise with id: \(exerciseId)")
                continue
            }
            
            let exercise = ExerciseModelDB()
            await dataManager.insert(model: exercise)
            exercise.index = exerciseIndex + 1
            exercise.typeId = exerciseId
            exercise.workoutGroup = group
            exercise.restTime = 120.0
            await addReportFixtureTargetSets(for: exercise,
                                             plan: fixturePlan(for: exerciseId),
                                             dataManager: dataManager)
        }
        
        return group
    }
    
    private func addReportFixtureTargetSets(for exercise: ExerciseModelDB,
                                            plan: FixtureExercisePlan,
                                            dataManager: DataManagerBackground) async {
        let setPlans = targetSetPlans(for: plan)
        for (index, setPlan) in setPlans.enumerated() {
            let set = SetsModelDB()
            await dataManager.insert(model: set)
            set.index = index + 1
            set.weight = setPlan.weight
            set.reps = setPlan.reps
            set.exercise = exercise
        }
    }
    
    private func createReportFixtureSession(for workout: WorkoutModelDB,
                                            group: WorkoutGroupModelDB,
                                            sessionIndex: Int,
                                            date: Date,
                                            isFinalSession: Bool,
                                            isIncompleteSession: Bool,
                                            dataManager: DataManagerBackground) async {
        let reportWorkout = ReportWorkoutModelDB(titleWorkout: workout.title ?? ReportFixture.workoutTitle,
                                                 workoutId: workout.id,
                                                 workoutGroupId: group.id,
                                                 titleWorkoutGroup: group.title ?? "")
        await dataManager.insert(model: reportWorkout)
        reportWorkout.startDate = date
        reportWorkout.endDate = date.addingTimeInterval(52 * 60 + TimeInterval(sessionIndex % 9) * 90)
        reportWorkout.targetExercisesCount = group.exercises.topLevelWorkoutItems().flattenedExerciseItems().count
        
        let exercises = group.exercises
            .topLevelWorkoutItems()
            .flattenedExerciseItems()
        let completedExercises = isIncompleteSession ? Array(exercises.prefix(2)) : exercises
        
        for exercise in completedExercises {
            await createReportFixtureExercise(for: exercise,
                                              reportWorkout: reportWorkout,
                                              sessionIndex: sessionIndex,
                                              date: date,
                                              isFinalSession: isFinalSession,
                                              dataManager: dataManager)
        }
    }
    
    private func createReportFixtureExercise(for exercise: ExerciseModelDB,
                                             reportWorkout: ReportWorkoutModelDB,
                                             sessionIndex: Int,
                                             date: Date,
                                             isFinalSession: Bool,
                                             dataManager: DataManagerBackground) async {
        guard let exerciseType = dataContainer.arrayExercises.first(where: { $0.id == exercise.typeId }) else {
            assertionFailure("Missing exercise type with id: \(exercise.typeId)")
            return
        }
        
        let reportExercise = ReportExerciseModelDB(titleExercise: exerciseType.displayName,
                                                   exerciseId: exercise.id,
                                                   index: exercise.index,
                                                   typeId: exercise.typeId,
                                                   trackingTypeId: exerciseType.trackingType?.rawValue,
                                                   restTime: exercise.restTime)
        await dataManager.insert(model: reportExercise)
        reportExercise.report = reportWorkout
        
        for targetSet in exercise.sets.sorted(by: { $0.index < $1.index }) {
            let snapshot = targetSet.copy()
            await dataManager.insert(model: snapshot)
            snapshot.reportExercise = reportExercise
        }
        
        let setPlans = performedSetPlans(for: exercise.typeId,
                                         sessionIndex: sessionIndex,
                                         isFinalSession: isFinalSession)
        for (index, setPlan) in setPlans.enumerated() {
            let reportSet = ReportSetsModelDB(date: date.addingTimeInterval(TimeInterval(index * 4 * 60)))
            await dataManager.insert(model: reportSet)
            reportSet.weight = setPlan.weight
            reportSet.reps = setPlan.reps
            reportSet.reportExercise = reportExercise
        }
    }
    
    private func fixtureSessionDate(startDate: Date, sessionIndex: Int) -> Date {
        let week = sessionIndex / ReportFixture.sessionsPerWeek
        let dayOffset: Int
        switch sessionIndex % ReportFixture.sessionsPerWeek {
        case 0:
            dayOffset = 0
        case 1:
            dayOffset = 2
        default:
            dayOffset = 4
        }
        
        let date = Calendar.current.date(byAdding: .day,
                                         value: week * 7 + dayOffset,
                                         to: startDate) ?? startDate
        return Calendar.current.date(bySettingHour: 18 + (sessionIndex % 2),
                                     minute: 15,
                                     second: 0,
                                     of: date) ?? date
    }
    
    private func fixturePlan(for typeId: String) -> FixtureExercisePlan {
        switch typeId {
        case "chest_bench_press":
            FixtureExercisePlan(typeId: typeId, baseWeight: 70, baseReps: 10)
        case "chest_incline_dumbbell_press":
            FixtureExercisePlan(typeId: typeId, baseWeight: 32, baseReps: 10)
        case "back_barbell_row":
            FixtureExercisePlan(typeId: typeId, baseWeight: 65, baseReps: 10)
        case "shoulders_seated_dumbbell_press":
            FixtureExercisePlan(typeId: typeId, baseWeight: 26, baseReps: 10)
        case "legs_barbell_squat":
            FixtureExercisePlan(typeId: typeId, baseWeight: 95, baseReps: 8)
        case "legs_leg_press":
            FixtureExercisePlan(typeId: typeId, baseWeight: 150, baseReps: 12)
        default:
            FixtureExercisePlan(typeId: typeId, baseWeight: 50, baseReps: 10)
        }
    }
    
    private func targetSetPlans(for plan: FixtureExercisePlan) -> [FixtureSetPlan] {
        [
            FixtureSetPlan(weight: plan.baseWeight, reps: plan.baseReps),
            FixtureSetPlan(weight: plan.baseWeight + 5, reps: max(plan.baseReps - 1, 1)),
            FixtureSetPlan(weight: plan.baseWeight + 10, reps: max(plan.baseReps - 2, 1))
        ]
    }
    
    private func stableOffset(for value: String) -> Int {
        value.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
    }
    
    private func performedSetPlans(for typeId: String,
                                   sessionIndex: Int,
                                   isFinalSession: Bool) -> [FixtureSetPlan] {
        let plan = fixturePlan(for: typeId)
        let week = sessionIndex / ReportFixture.sessionsPerWeek
        let cycleNoise = Float((sessionIndex + stableOffset(for: typeId)) % 5 - 2) * 0.5
        let progression = Float(week) * 0.10 + cycleNoise
        let baseWeight = plan.baseWeight + progression
        let baseReps = plan.baseReps + (week / 18)
        
        if isFinalSession {
            switch typeId {
            case "chest_bench_press":
                return [
                    FixtureSetPlan(weight: plan.baseWeight + 42, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight + 35, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight + 30, reps: plan.baseReps - 1),
                    FixtureSetPlan(weight: plan.baseWeight + 20, reps: plan.baseReps + 2)
                ]
            case "chest_incline_dumbbell_press":
                return [
                    FixtureSetPlan(weight: plan.baseWeight + 16, reps: plan.baseReps + 1),
                    FixtureSetPlan(weight: plan.baseWeight + 14, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight + 12, reps: plan.baseReps)
                ]
            case "back_barbell_row":
                return [
                    FixtureSetPlan(weight: plan.baseWeight - 5, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight, reps: plan.baseReps - 2),
                    FixtureSetPlan(weight: plan.baseWeight + 5, reps: plan.baseReps - 3)
                ]
            case "shoulders_seated_dumbbell_press":
                return [
                    FixtureSetPlan(weight: plan.baseWeight + 8, reps: plan.baseReps + 1),
                    FixtureSetPlan(weight: plan.baseWeight + 6, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight + 4, reps: plan.baseReps)
                ]
            case "legs_barbell_squat":
                return [
                    FixtureSetPlan(weight: plan.baseWeight + 25, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight + 22, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight + 18, reps: plan.baseReps - 1),
                    FixtureSetPlan(weight: plan.baseWeight + 10, reps: plan.baseReps + 2)
                ]
            case "legs_leg_press":
                return [
                    FixtureSetPlan(weight: plan.baseWeight - 10, reps: plan.baseReps),
                    FixtureSetPlan(weight: plan.baseWeight - 5, reps: plan.baseReps - 2),
                    FixtureSetPlan(weight: plan.baseWeight, reps: plan.baseReps - 3)
                ]
            default:
                break
            }
        }
        
        return [
            FixtureSetPlan(weight: baseWeight, reps: baseReps),
            FixtureSetPlan(weight: baseWeight + 5, reps: max(baseReps - 1, 1)),
            FixtureSetPlan(weight: baseWeight + 10, reps: max(baseReps - 2, 1))
        ]
    }
}
