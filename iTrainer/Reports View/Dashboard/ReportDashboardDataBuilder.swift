//
//  ReportDashboardDataBuilder.swift
//  iTrainer
//
//  Created by Codex on 04.07.2026.
//

import Foundation

struct ReportDashboardWorkoutSnapshot: Hashable, Sendable {
    let id: UUID
    let titleWorkout: String
    let workoutId: UUID
    let titleWorkoutGroup: String
    let workoutGroupId: UUID
    let startDate: Date?
    let endDate: Date?
    let targetExercisesCount: Int
    let exercises: [ReportDashboardExerciseSnapshot]
    
    var reportModel: ReportWorkoutModel {
        var model = ReportWorkoutModel(id: id,
                                       titleWorkout: titleWorkout,
                                       workoutId: workoutId,
                                       titleWorkoutGroup: titleWorkoutGroup,
                                       workoutGroupId: workoutGroupId,
                                       startDate: startDate,
                                       endDate: endDate)
        model.targetExercisesCount = targetExercisesCount
        return model
    }
}

struct ReportDashboardExerciseSnapshot: Hashable, Sendable {
    let id: UUID
    let titleExercise: String
    let exerciseId: UUID
    let index: Int
    let typeId: String
    let trackingTypeId: String?
    let restTime: TimeInterval?
    let date: Date?
    let workoutId: UUID?
    let workoutGroupId: UUID?
    let titleWorkout: String?
    let titleWorkoutGroup: String?
    let sets: [ReportDashboardSetSnapshot]
    let targetSets: [ReportDashboardTargetSetSnapshot]
    
    var reportExerciseModel: ReportExerciseModel {
        var reportSets = sets
            .map(\.reportSetModel)
            .sorted { $0.date > $1.date }
        for index in reportSets.indices {
            reportSets[index].index = reportSets.count - index
        }
        
        return ReportExerciseModel(id: id,
                                   titleExercise: titleExercise,
                                   exerciseId: exerciseId,
                                   index: index,
                                   typeId: typeId,
                                   trackingTypeId: trackingTypeId,
                                   workoutId: workoutId,
                                   workoutGroupId: workoutGroupId,
                                   titleWorkout: titleWorkout,
                                   titleWorkoutGroup: titleWorkoutGroup,
                                   restTime: restTime,
                                   date: date,
                                   sets: reportSets,
                                   targetSets: targetSets.map(\.setsModel).sorted { $0.index < $1.index })
    }
}

struct ReportDashboardSetSnapshot: Hashable, Sendable {
    let id: UUID
    let index: Int
    let date: Date
    let reps: Int?
    let weight: Float?
    let distance: Float?
    let time: TimeInterval?
    
    var reportSetModel: ReportSetsModel {
        ReportSetsModel(id: id,
                        date: date,
                        params: parameters)
    }
    
    private var parameters: [SetsParameter] {
        var result = [SetsParameter]()
        if let weight {
            result.append(.weight(weight))
        }
        if let reps {
            result.append(.repeats(reps))
        }
        if let distance {
            result.append(.distance(distance))
        }
        if let time {
            result.append(.time(time))
        }
        return result
    }
}

struct ReportDashboardTargetSetSnapshot: Hashable, Sendable {
    let id: UUID
    let index: Int
    let reps: Int?
    let weight: Float?
    let distance: Float?
    let time: TimeInterval?
    
    var setsModel: SetsModel {
        SetsModel(id: id,
                  index: index,
                  params: parameters)
    }
    
    private var parameters: [SetsParameter] {
        var result = [SetsParameter]()
        if let weight {
            result.append(.weight(weight))
        }
        if let reps {
            result.append(.repeats(reps))
        }
        if let distance {
            result.append(.distance(distance))
        }
        if let time {
            result.append(.time(time))
        }
        return result
    }
}

struct ReportDashboardPreparedRow: Hashable, Sendable {
    let report: ReportDashboardWorkoutSnapshot
    let exerciseStatuses: [ExerciseReportStatus]
    let workoutStatus: WorkoutReportStatus
    let totalVolume: Float
}

struct ReportDashboardDataBuilder {
    func buildRows(from snapshots: [ReportDashboardWorkoutSnapshot]) -> [ReportDashboardPreparedRow] {
        let completedSnapshots = snapshots.filter { $0.endDate != nil }
        let reportRows = completedSnapshots.map { snapshot in
            DashboardReportBuildRow(report: snapshot,
                                    exercises: snapshot.exercises
                                        .map(\.reportExerciseModel)
                                        .sorted { $0.index < $1.index })
        }
        let exerciseHistoryByType = Dictionary(grouping: reportRows.flatMap(\.exercises), by: \.typeId)
        
        return reportRows.map { row in
            let exerciseStatuses = row.exercises.map { exercise in
                ReportStatusService.calculateExerciseStatus(report: exercise,
                                                            history: exerciseHistoryByType[exercise.typeId] ?? [])
            }
            let workoutStatus = ReportStatusService.calculateWorkoutStatus(report: row.report.reportModel,
                                                                           exercises: row.exercises,
                                                                           exerciseStatuses: exerciseStatuses)
            return ReportDashboardPreparedRow(report: row.report,
                                              exerciseStatuses: exerciseStatuses,
                                              workoutStatus: workoutStatus,
                                              totalVolume: ReportStatusService.totalVolume(for: row.exercises))
        }
    }
}

private struct DashboardReportBuildRow {
    let report: ReportDashboardWorkoutSnapshot
    let exercises: [ReportExerciseModel]
}
