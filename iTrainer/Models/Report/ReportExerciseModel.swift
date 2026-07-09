//
//  ReportExerciseModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 08.09.2024.
//

import Foundation

struct ReportExerciseModel: ReportExerciseDataProtocol, Hashable {
    
    var id: UUID
    
    var titleExercise: String
    
    var exerciseId: UUID
    
    var index: Int
    
    var typeId: String
    
    var trackingTypeId: String?
    
    var workoutId: UUID?
    
    var workoutGroupId: UUID?
    
    var titleWorkout: String?
    
    var titleWorkoutGroup: String?
    
    var restTime: TimeInterval?
    
    var date: Date?
    
    var sets = [ReportSetsModel]()
    
    var targetSets = [SetsModel]()
    
    init(model: ReportExerciseModelDB) {
        self.id = model.id
        self.titleExercise = model.titleExercise
        self.exerciseId = model.exerciseId
        self.index = model.index
        self.typeId = model.typeId
        self.trackingTypeId = model.trackingTypeId
        self.workoutId = model.report?.workoutId
        self.workoutGroupId = model.report?.workoutGroupId
        self.titleWorkout = model.report?.titleWorkout
        self.titleWorkoutGroup = model.report?.titleWorkoutGroup
        self.restTime = model.restTime
        self.date = model.report?.startDate
        
        self.sets = model.reportSets.map { ReportSetsModel(model: $0) }.sorted(by: { $0.date > $1.date })
        for (idx, _) in self.sets.enumerated() {
            self.sets[idx].index = self.sets.count - idx
        }
        
        self.targetSets = model.targetSets.map { SetsModel(model: $0) }.sorted(by: { $0.index < $1.index })
    }
    
    init(id: UUID = UUID(),
         titleExercise: String,
         exerciseId: UUID,
         index: Int,
         typeId: String,
         trackingTypeId: String? = nil,
         workoutId: UUID? = nil,
         workoutGroupId: UUID? = nil,
         titleWorkout: String? = nil,
         titleWorkoutGroup: String? = nil,
         restTime: TimeInterval? = nil,
         date: Date? = nil,
         sets: [ReportSetsModel] = [],
         targetSets: [SetsModel] = []) {
        
        self.id = id
        self.titleExercise = titleExercise
        self.exerciseId = exerciseId
        self.index = index
        self.typeId = typeId
        self.trackingTypeId = trackingTypeId
        self.workoutId = workoutId
        self.workoutGroupId = workoutGroupId
        self.titleWorkout = titleWorkout
        self.titleWorkoutGroup = titleWorkoutGroup
        self.restTime = restTime
        self.date = date
        self.sets = sets
        self.targetSets = targetSets
    }
}

extension ReportExerciseModel {
    var type: ExerciseTypeModel? {
        DataContainer.shared.arrayExercises.filter({ $0.id == typeId }).first
    }
}
