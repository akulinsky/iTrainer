//
//  ExerciseListModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Alamofire
import Combine

enum ExerciseAddConflict: Identifiable {
    case activeDuplicate(title: String)
    case hiddenDuplicate(title: String)
    
    var id: String {
        switch self {
        case .activeDuplicate(let title):
            "active-\(title)"
        case .hiddenDuplicate(let title):
            "hidden-\(title)"
        }
    }
    
    var title: String {
        switch self {
        case .activeDuplicate:
            "Exercise already exists"
        case .hiddenDuplicate:
            "Exercise is hidden"
        }
    }
    
    var message: String {
        switch self {
        case .activeDuplicate(let title):
            "\(title) is already in this workout. Add another copy?"
        case .hiddenDuplicate(let title):
            "\(title) is hidden in this workout. Restore it instead?"
        }
    }
}

class ExerciseListViewModel: ObservableObject {
    
    @Published var exercises = [ExerciseModel]()
    @Published var hiddenExercises = [ExerciseModel]()
    
    @Published private var lastCompletedProgressByExerciseId = [UUID: Double]()
    
    @Published var isShowAlert = false
    
    @Published var isEditExercise = false
    
    @Published var isAddNewExercise = false
    @Published var isHiddenExercisesPresented = false
    @Published var pendingScrollExerciseId: UUID?
    @Published var addConflict: ExerciseAddConflict?
    
    var editExercise: ExerciseModel?
    
    var errorMessage: String? = nil
    
    var group: WorkoutGroupModel
    
    var isEditHeadline = false
    
    var hasHiddenExercises: Bool {
        !hiddenExercises.isEmpty
    }
    
    private var pendingAddTypeIds = [String]()
    private var pendingHiddenRestoreIds = [UUID]()
    
    init(group: WorkoutGroupModel) {
        self.group = group
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchExercises(for: group.id).map { ExerciseModel(model: $0) }
            let hiddenItems = await dataManager.fetchHiddenExercises(for: group.id).map { ExerciseModel(model: $0) }
            let lastCompletedReport = await dataManager.fetchLatestCompletedReportWorkout(forWorkoutGroupId: group.id)
            let lastCompletedProgressByExerciseId = progressByExerciseId(from: lastCompletedReport)
            
            await MainActor.run {
                exercises = items
                hiddenExercises = hiddenItems
                self.lastCompletedProgressByExerciseId = lastCompletedProgressByExerciseId
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    func reloadData(complete: (()->())? = nil) {
        self.fetchItems(complete: complete)
    }
    
    func refreshData() {
        
    }
    
    func lastCompletedProgress(for exerciseId: UUID) -> Double? {
        lastCompletedProgressByExerciseId[exerciseId]
    }
    
    func edit(exercise: ExerciseModel) {
        guard !exercise.isSupersetItem else { return }
        
        editExercise = exercise
        if exercise.isHeadlineItem {
            isEditHeadline = true
        }
        isEditExercise = true
    }
    
    func addNewExercises(with typeIDs: Set<String>) {
        let orderedTypeIds = orderedTypeIds(from: typeIDs)
        guard !orderedTypeIds.isEmpty else { return }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let activeExercises = await dataManager.fetchFlattenedExercises(for: group.id)
            let hiddenExercises = await dataManager.fetchHiddenExercises(for: group.id).filter { $0.isExerciseItem }
            let hiddenMatches = hiddenExercises.filter { orderedTypeIds.contains($0.typeId) }
            let activeMatches = activeExercises.filter { orderedTypeIds.contains($0.typeId) }
            
            if let hiddenMatch = hiddenMatches.first {
                let hiddenRestoreIds = hiddenMatches.map(\.id)
                let hiddenTitle = ExerciseModel(model: hiddenMatch).displayName
                await MainActor.run {
                    pendingAddTypeIds = orderedTypeIds
                    pendingHiddenRestoreIds = hiddenRestoreIds
                    addConflict = .hiddenDuplicate(title: hiddenTitle)
                }
                return
            }
            
            if let activeMatch = activeMatches.first {
                let activeTitle = ExerciseModel(model: activeMatch).displayName
                await MainActor.run {
                    pendingAddTypeIds = orderedTypeIds
                    pendingHiddenRestoreIds = []
                    addConflict = .activeDuplicate(title: activeTitle)
                }
                return
            }
            
            await addExercises(typeIds: orderedTypeIds)
        }
    }
    
    func addPendingExercisesAnyway() {
        let typeIds = pendingAddTypeIds
        clearPendingAddConflict()
        Task {
            await addExercises(typeIds: typeIds)
        }
    }
    
    func restorePendingHiddenExercises() {
        let restoreIds = pendingHiddenRestoreIds
        let typeIds = pendingAddTypeIds
        clearPendingAddConflict()
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var restoredIds = [UUID]()
            var restoredTypeIds = Set<String>()
            
            for id in restoreIds {
                guard let restoredId = await dataManager.restoreExercise(with: id),
                      let restoredExercise = await dataManager.fetchExercise(with: restoredId) else {
                    continue
                }
                restoredIds.append(restoredId)
                restoredTypeIds.insert(restoredExercise.typeId)
            }
            
            let typeIdsToAdd = typeIds.filter { !restoredTypeIds.contains($0) }
            let createdIds = await dataManager.addExercises(typeIds: typeIdsToAdd, groupId: group.id)
            let scrollId = createdIds.last ?? restoredIds.last
            await reloadDataAndScroll(to: scrollId)
        }
    }
    
    func hide(exercise: ExerciseModel) {
        guard !exercise.isHeadlineItem else { return }
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.hideExercise(with: exercise.id)
            let items = await dataManager.fetchExercises(for: group.id).map { ExerciseModel(model: $0) }
            let hiddenItems = await dataManager.fetchHiddenExercises(for: group.id).map { ExerciseModel(model: $0) }
            let lastCompletedReport = await dataManager.fetchLatestCompletedReportWorkout(forWorkoutGroupId: group.id)
            let lastCompletedProgressByExerciseId = progressByExerciseId(from: lastCompletedReport)
            
            await MainActor.run {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                    exercises = items
                    hiddenExercises = hiddenItems
                    self.lastCompletedProgressByExerciseId = lastCompletedProgressByExerciseId
                }
            }
        }
    }
    
    func restore(exercise: ExerciseModel) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let restoredId = await dataManager.restoreExercise(with: exercise.id)
            await MainActor.run {
                isHiddenExercisesPresented = false
            }
            await reloadDataAndScroll(to: restoredId)
        }
    }
    
    func update(name: String) {
        if var editExercise = editExercise {
            editExercise.title = name
            update(items: [editExercise])
        } else {
            update(items: [ExerciseModel(title: name, kind: self.isEditHeadline ? .headline : .exercise)])
        }
        editExercise = nil
        self.isEditHeadline = false
    }
    
    private func update(items: [ExerciseModel]) {
        Task {
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(exercises: items, groupId: group.id)
        }
    }
    
    private func addExercises(typeIds: [String]) async {
        guard !typeIds.isEmpty else { return }
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let createdIds = await dataManager.addExercises(typeIds: typeIds, groupId: group.id)
        await reloadDataAndScroll(to: createdIds.last)
    }
    
    func addSuperset(complete: ((ExerciseModel?) -> Void)? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let supersetId = await dataManager.addSuperset(groupId: group.id)
            await reloadDataAndScroll(to: supersetId)
            let superset: ExerciseModel?
            if let supersetId,
               let model = await dataManager.fetchExercise(with: supersetId) {
                superset = ExerciseModel(model: model)
            } else {
                superset = nil
            }
            await MainActor.run {
                complete?(superset)
            }
        }
    }
    
    private func reloadDataAndScroll(to exerciseId: UUID?) async {
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let items = await dataManager.fetchExercises(for: group.id).map { ExerciseModel(model: $0) }
        let hiddenItems = await dataManager.fetchHiddenExercises(for: group.id).map { ExerciseModel(model: $0) }
        let lastCompletedReport = await dataManager.fetchLatestCompletedReportWorkout(forWorkoutGroupId: group.id)
        let lastCompletedProgressByExerciseId = progressByExerciseId(from: lastCompletedReport)
        
        await MainActor.run {
            exercises = items
            hiddenExercises = hiddenItems
            self.lastCompletedProgressByExerciseId = lastCompletedProgressByExerciseId
            pendingScrollExerciseId = exerciseId
        }
    }
    
    private func clearPendingAddConflict() {
        pendingAddTypeIds = []
        pendingHiddenRestoreIds = []
        addConflict = nil
    }
    
    private func orderedTypeIds(from typeIDs: Set<String>) -> [String] {
        let catalogOrder = DataContainer.shared.arrayExercises.map(\.id).filter { typeIDs.contains($0) }
        let orderedSet = Set(catalogOrder)
        let leftovers = typeIDs.filter { !orderedSet.contains($0) }.sorted()
        return catalogOrder + leftovers
    }
    
    private func progressByExerciseId(from report: ReportWorkoutModelDB?) -> [UUID: Double] {
        guard let report else {
            return [:]
        }
        
        var progressById = [UUID: Double]()
        for exercise in report.exercises.flattenedReportExerciseItems() {
            let targetSetCount = exercise.targetSets.count
            guard targetSetCount > 0 else {
                progressById[exercise.exerciseId] = 1
                continue
            }
            progressById[exercise.exerciseId] = min(Double(exercise.reportSets.count) / Double(targetSetCount), 1)
        }
        return progressById
    }
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchExercises(for: group.id)
            models.move(fromOffsets: source, toOffset: destination)
            var index = 1
            for item in models {
                item.index = index
                index += 1
            }
            await dataManager.save()
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func delete(index: Int) {
        let item = self.exercises[index]
        delete(exercise: item)
    }
    
    func delete(exercise: ExerciseModel) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeExercise(with: exercise.id)
            let items = await dataManager.fetchExercises(for: group.id).map { ExerciseModel(model: $0) }
            let hiddenItems = await dataManager.fetchHiddenExercises(for: group.id).map { ExerciseModel(model: $0) }
            let lastCompletedReport = await dataManager.fetchLatestCompletedReportWorkout(forWorkoutGroupId: group.id)
            let lastCompletedProgressByExerciseId = progressByExerciseId(from: lastCompletedReport)
            
            await MainActor.run {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
                    exercises = items
                    hiddenExercises = hiddenItems
                    self.lastCompletedProgressByExerciseId = lastCompletedProgressByExerciseId
                }
            }
        }
    }
    
    private func addNewExerciseToBase(_ exerciseModel: ExerciseModel, dataManager: DataManagerBackground) async {
        let item = ExerciseModelDB()
        
        await dataManager.insert(model: item)
        item.index = exerciseModel.index
        item.title = exerciseModel.title
    }
}
