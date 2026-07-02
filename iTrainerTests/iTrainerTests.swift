//
//  iTrainerTests.swift
//  iTrainerTests
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import XCTest
@testable import iTrainer

final class iTrainerTests: XCTestCase {
    
    func testPersonalRecordHasPriorityOverProgress() {
        let ids = ContextIds()
        let previous = exercise(exerciseId: ids.exercise,
                                workoutId: ids.workout,
                                workoutGroupId: ids.group,
                                date: .now.addingTimeInterval(-86_400),
                                sets: [reportSet(weight: 100, reps: 1)])
        let current = exercise(exerciseId: ids.exercise,
                               workoutId: ids.workout,
                               workoutGroupId: ids.group,
                               date: .now,
                               sets: [reportSet(weight: 105, reps: 1)],
                               targets: [targetSet(weight: 100, reps: 1)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [previous, current])
        
        XCTAssertEqual(status, .personalRecord(type: .weight))
    }
    
    func testProgressHasPriorityOverGoalMissed() {
        let ids = ContextIds()
        let otherGroup = UUID()
        let previousGlobalBest = exercise(exerciseId: ids.exercise,
                                          workoutId: ids.workout,
                                          workoutGroupId: otherGroup,
                                          date: .now.addingTimeInterval(-172_800),
                                          sets: [reportSet(weight: 100, reps: 8)])
        let previousLocal = exercise(exerciseId: ids.exercise,
                                     workoutId: ids.workout,
                                     workoutGroupId: ids.group,
                                     date: .now.addingTimeInterval(-86_400),
                                     sets: [reportSet(weight: 50, reps: 8)])
        let current = exercise(exerciseId: ids.exercise,
                               workoutId: ids.workout,
                               workoutGroupId: ids.group,
                               date: .now,
                               sets: [reportSet(weight: 60, reps: 8)],
                               targets: [targetSet(weight: 65, reps: 8)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current,
                                                                 history: [previousGlobalBest, previousLocal, current])
        
        XCTAssertEqual(status, .progress)
    }
    
    func testGoalAchieved() {
        let current = exercise(sets: [reportSet(weight: 50, reps: 10)],
                               targets: [targetSet(weight: 50, reps: 10)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [current])
        
        XCTAssertEqual(status, .goalAchieved)
    }
    
    func testGoalMissedWhenFewerPerformedSetsThanTargets() {
        let current = exercise(sets: [reportSet(weight: 50, reps: 10)],
                               targets: [targetSet(weight: 50, reps: 10), targetSet(weight: 55, reps: 8)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [current])
        
        XCTAssertEqual(status, .goalMissed)
    }
    
    func testCompleteWithoutGoals() {
        let current = exercise(sets: [reportSet(weight: 60, reps: 8)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [current])
        
        XCTAssertEqual(status, .complete)
    }
    
    func testExtraSetsDoNotAffectGoalStatus() {
        let current = exercise(sets: [
            reportSet(weight: 50, reps: 10, index: 1),
            reportSet(weight: 55, reps: 5, index: 2),
            reportSet(weight: 100, reps: 1, index: 3)
        ], targets: [
            targetSet(weight: 50, reps: 10, index: 1),
            targetSet(weight: 60, reps: 5, index: 2)
        ])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [current])
        
        XCTAssertEqual(status, .goalMissed)
    }
    
    func testExtraSetsAffectVolumePersonalRecord() {
        let ids = ContextIds()
        let previous = exercise(exerciseId: ids.exercise,
                                date: .now.addingTimeInterval(-86_400),
                                sets: [reportSet(weight: 100, reps: 1)])
        let current = exercise(exerciseId: ids.exercise,
                               date: .now,
                               sets: [
                                reportSet(weight: 50, reps: 1, index: 1),
                                reportSet(weight: 90, reps: 2, index: 2)
                               ])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [previous, current])
        
        XCTAssertEqual(status, .personalRecord(type: .volume))
    }
    
    func testWorkoutIncomplete() {
        let report = workoutReport(targetExercisesCount: 3)
        let exercises = [exercise(sets: [reportSet(weight: 10, reps: 1)]),
                         exercise(sets: [reportSet(weight: 20, reps: 1)])]
        let statuses: [ExerciseReportStatus] = [.complete, .complete]
        
        let status = ReportStatusService.calculateWorkoutStatus(report: report,
                                                                exercises: exercises,
                                                                exerciseStatuses: statuses)
        
        XCTAssertEqual(status, .workoutIncomplete(completed: 2, total: 3))
    }
    
    func testGoalsAchievedWorkoutStatus() {
        let report = workoutReport(targetExercisesCount: 1)
        let exercises = [exercise(sets: [reportSet(weight: 50, reps: 10)],
                                  targets: [targetSet(weight: 50, reps: 10)])]
        
        let status = ReportStatusService.calculateWorkoutStatus(report: report,
                                                                exercises: exercises,
                                                                exerciseStatuses: [.goalAchieved])
        
        XCTAssertEqual(status, .goalsAchieved)
    }
    
    func testGoalsNotAchievedWorkoutStatus() {
        let report = workoutReport(targetExercisesCount: 1)
        let exercises = [exercise(sets: [reportSet(weight: 45, reps: 10)],
                                  targets: [targetSet(weight: 50, reps: 10)])]
        
        let status = ReportStatusService.calculateWorkoutStatus(report: report,
                                                                exercises: exercises,
                                                                exerciseStatuses: [.goalMissed])
        
        XCTAssertEqual(status, .goalsNotAchieved)
    }
    
    func testWorkoutCompleteWithoutGoals() {
        let report = workoutReport(targetExercisesCount: 1)
        let exercises = [exercise(sets: [reportSet(weight: 50, reps: 10)])]
        
        let status = ReportStatusService.calculateWorkoutStatus(report: report,
                                                                exercises: exercises,
                                                                exerciseStatuses: [.complete])
        
        XCTAssertEqual(status, .workoutComplete)
    }
    
    func testProgressIsLocalByWorkoutAndGroup() {
        let ids = ContextIds()
        let otherGroup = UUID()
        let previousGlobal = exercise(exerciseId: ids.exercise,
                                      workoutId: ids.workout,
                                      workoutGroupId: otherGroup,
                                      date: .now.addingTimeInterval(-172_800),
                                      sets: [reportSet(weight: 80, reps: 8)])
        let previousLocal = exercise(exerciseId: ids.exercise,
                                     workoutId: ids.workout,
                                     workoutGroupId: ids.group,
                                     date: .now.addingTimeInterval(-86_400),
                                     sets: [reportSet(weight: 50, reps: 8)])
        let current = exercise(exerciseId: ids.exercise,
                               workoutId: ids.workout,
                               workoutGroupId: ids.group,
                               date: .now,
                               sets: [reportSet(weight: 60, reps: 8)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current,
                                                                 history: [previousGlobal, previousLocal, current])
        
        XCTAssertEqual(status, .progress)
    }
    
    func testPersonalRecordIsGlobalByTypeId() {
        let previousExerciseId = UUID()
        let currentExerciseId = UUID()
        let typeId = "bench_press"
        let previous = exercise(exerciseId: previousExerciseId,
                                typeId: typeId,
                                date: .now.addingTimeInterval(-86_400),
                                sets: [reportSet(weight: 100, reps: 1)])
        let current = exercise(exerciseId: currentExerciseId,
                               typeId: typeId,
                               date: .now,
                               sets: [reportSet(weight: 105, reps: 1)])
        
        let status = ReportStatusService.calculateExerciseStatus(report: current, history: [previous, current])
        
        XCTAssertEqual(status, .personalRecord(type: .weight))
    }
    
    func testProgressResultUsesImprovedMetric() {
        let ids = ContextIds()
        let otherGroup = UUID()
        let previousGlobalBest = exercise(exerciseId: ids.exercise,
                                          workoutId: ids.workout,
                                          workoutGroupId: otherGroup,
                                          date: .now.addingTimeInterval(-172_800),
                                          sets: [reportSet(weight: 80, reps: 10)])
        let previousLocal = exercise(exerciseId: ids.exercise,
                                     workoutId: ids.workout,
                                     workoutGroupId: ids.group,
                                     date: .now.addingTimeInterval(-86_400),
                                     sets: [reportSet(weight: 80, reps: 6)])
        let current = exercise(exerciseId: ids.exercise,
                               workoutId: ids.workout,
                               workoutGroupId: ids.group,
                               date: .now,
                               sets: [reportSet(weight: 80, reps: 8)])
        
        let result = ReportStatusService.calculateExerciseStatusResult(report: current,
                                                                       history: [previousGlobalBest, previousLocal, current])
        
        XCTAssertEqual(result.status, .progress)
        XCTAssertEqual(result.comparison?.type, .repetitions)
        XCTAssertEqual(result.comparison?.current, 8)
        XCTAssertEqual(result.comparison?.previous, 6)
    }
}

private struct ContextIds {
    let exercise = UUID()
    let workout = UUID()
    let group = UUID()
}

private func workoutReport(targetExercisesCount: Int) -> ReportWorkoutModel {
    var report = ReportWorkoutModel(titleWorkout: "Workout",
                                    workoutId: UUID(),
                                    titleWorkoutGroup: "Group",
                                    workoutGroupId: UUID(),
                                    startDate: .now.addingTimeInterval(-3_600),
                                    endDate: .now)
    report.targetExercisesCount = targetExercisesCount
    return report
}

private func exercise(id: UUID = UUID(),
                      exerciseId: UUID = UUID(),
                      typeId: String = "",
                      workoutId: UUID? = UUID(),
                      workoutGroupId: UUID? = UUID(),
                      date: Date? = .now,
                      sets: [ReportSetsModel] = [],
                      targets: [SetsModel] = []) -> ReportExerciseModel {
    ReportExerciseModel(id: id,
                        titleExercise: "Exercise",
                        exerciseId: exerciseId,
                        index: 0,
                        typeId: typeId,
                        workoutId: workoutId,
                        workoutGroupId: workoutGroupId,
                        date: date,
                        sets: sets,
                        targetSets: targets)
}

private func reportSet(weight: Float? = nil,
                       reps: Int? = nil,
                       time: TimeInterval? = nil,
                       distance: Float? = nil,
                       index: Int = 0) -> ReportSetsModel {
    var model = ReportSetsModel(date: .now, params: params(weight: weight,
                                                          reps: reps,
                                                          time: time,
                                                          distance: distance))
    model.index = index
    return model
}

private func targetSet(weight: Float? = nil,
                       reps: Int? = nil,
                       time: TimeInterval? = nil,
                       distance: Float? = nil,
                       index: Int = 0) -> SetsModel {
    SetsModel(index: index, params: params(weight: weight,
                                           reps: reps,
                                           time: time,
                                           distance: distance))
}

private func params(weight: Float?,
                    reps: Int?,
                    time: TimeInterval?,
                    distance: Float?) -> [SetsParameter] {
    var result = [SetsParameter]()
    if let weight { result.append(.weight(weight)) }
    if let reps { result.append(.repeats(reps)) }
    if let time { result.append(.time(time)) }
    if let distance { result.append(.distance(distance)) }
    return result
}
