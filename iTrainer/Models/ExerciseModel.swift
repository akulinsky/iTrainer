//
//  ExerciseModel.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation

struct ExerciseModel: DataItemProtocol, Hashable {
    var id: UUID
    var index: Int
    var title: String?
    var typeId: String
    var kind: ExerciseItemKind
    var restTime: TimeInterval
    var isArchived: Bool
    var archivedAt: Date?
    var parentSupersetId: UUID?
    var supersetExercises: [ExerciseModel]
    
    init(model: ExerciseModelDB) {
        self.id = model.id
        self.index = model.index
        self.title = model.title
        self.typeId = model.typeId
        self.kind = model.kind
        self.restTime = model.restTime ?? 120
        self.isArchived = model.isArchived
        self.archivedAt = model.archivedAt
        self.parentSupersetId = model.parentSuperset?.id
        self.supersetExercises = model.supersetExercises
            .map { ExerciseModel(model: $0) }
            .sorted { $0.index < $1.index }
    }
    
    init(id: UUID = UUID(),
         index: Int = 0,
         title: String? = nil,
         typeId: String = "",
         kind: ExerciseItemKind = .exercise,
         restTime: TimeInterval = 120,
         isArchived: Bool = false,
         archivedAt: Date? = nil,
         parentSupersetId: UUID? = nil,
         supersetExercises: [ExerciseModel] = []) {
        
        self.id = id
        self.index = index
        self.title = title
        self.typeId = typeId
        self.kind = kind
        self.restTime = restTime
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.parentSupersetId = parentSupersetId
        self.supersetExercises = supersetExercises
    }
}

extension ExerciseModel {
    
    var isSuperset: Bool {
        kind == .superset
    }
    
    var isExercise: Bool {
        kind == .exercise
    }
    
    var displayName: String {
        title ?? type?.title ?? ""
    }
    
    var type: ExerciseTypeModel? {
        DataContainer.shared.arrayExercises.filter({ $0.id == typeId }).first
    }
}
