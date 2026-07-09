//
//  DataManagerBackground.swift
//  AjaxTestSwiftUI
//
//  Created by Andrey Kulinskiy on 25.07.2024.
//

import Foundation
import SwiftData



public actor DataManagerBackground: ModelActor {
    
    public let modelContainer: ModelContainer
    public let modelExecutor: any ModelExecutor
    
    private var context: ModelContext { modelExecutor.modelContext }
    
//    private let log = LifecycleLogger(name: "DataManagerBackground")
    
    public init(container: ModelContainer) {
        self.modelContainer = container
        let context = ModelContext(modelContainer)
        modelExecutor = DefaultSerialModelExecutor(
            modelContext: context
        )
    }
    
    public func fetchModels<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) -> [T] {
        
        do {
            let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
            let list: [T] = try context.fetch(fetchDescriptor)
            return list
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func fetchItem<T: PersistentModel>(predicate: Predicate<T>) -> T? {
        do {
            return try context.fetch(FetchDescriptor<T>(predicate: predicate)).first
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func count<T: PersistentModel>(type: T.Type) -> Int {
        do {
            let descriptor = FetchDescriptor<T>()
            return try context.fetchCount(descriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func insert<T: PersistentModel>(model: T) {
        let context = model.modelContext ?? context
        context.insert(model)
    }
    
    func update<T: PersistentModel>(predicate: Predicate<T>, block: (T?)->()) {
        
        if let model = self.fetchItem(predicate: predicate) {
            block(model)
            save()
        } else {
            block(nil)
        }
    }
    
    public func remove<T: PersistentModel>(predicate: Predicate<T>) {

        if let model = self.fetchItem(predicate: predicate) {
            context.delete(model)
//            save()
        }
    }
    
    public func remove<T: PersistentModel>(model: T) {
        context.delete(model)
    }
    
    func removeAll<T: PersistentModel>(type: T.Type) {
        
        do {
            let descriptor = FetchDescriptor<T>()
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public func save() {
        do {
            try context.save()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}

// MARK: - Request

extension DataManagerBackground {
    
    // MARK: - Fetch
    
    func fetchAllWorkouts() -> [WorkoutModelDB] {
        return fetchModels(sortBy: [SortDescriptor(\WorkoutModelDB.index, order: .forward)])
    }
    
    func fetchSelectedWorkout() -> WorkoutModelDB? {
        return fetchItem(predicate: #Predicate<WorkoutModelDB> { $0.isSelected == true })
    }
    
    func selectWorkout(with id: UUID) {
        let workouts = fetchAllWorkouts()
        for workout in workouts {
            workout.isSelected = workout.id == id
        }
        save()
    }
    
    func fetchWorkoutGroups(for workoutId: UUID) -> [WorkoutGroupModelDB] {
        return fetchModels(predicate: #Predicate<WorkoutGroupModelDB> { $0.workout?.id == workoutId },
                           sortBy: [SortDescriptor(\WorkoutGroupModelDB.index, order: .forward)])
    }
    
    func fetchWorkoutGroup(with id: UUID) -> WorkoutGroupModelDB? {
        let uuid = id
        return fetchItem(predicate: #Predicate<WorkoutGroupModelDB> { $0.id == uuid })
    }
    
    func fetchExercises(for workoutGroupId: UUID) -> [ExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ExerciseModelDB> { $0.workoutGroup?.id == workoutGroupId && !$0.isArchived },
                           sortBy: [SortDescriptor(\ExerciseModelDB.index, order: .forward)])
    }
    
    func fetchHiddenExercises(for workoutGroupId: UUID) -> [ExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ExerciseModelDB> { $0.workoutGroup?.id == workoutGroupId && $0.isArchived },
                           sortBy: [SortDescriptor(\ExerciseModelDB.archivedAt, order: .reverse),
                                    SortDescriptor(\ExerciseModelDB.index, order: .forward)])
    }
    
    func fetchAllExercises(for workoutGroupId: UUID) -> [ExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ExerciseModelDB> { $0.workoutGroup?.id == workoutGroupId },
                           sortBy: [SortDescriptor(\ExerciseModelDB.index, order: .forward)])
    }
    
    func fetchExercise(with exerciseId: UUID) -> ExerciseModelDB? {
        let uuid = exerciseId
        return fetchItem(predicate: #Predicate<ExerciseModelDB> { $0.id == uuid })
    }
    
    func fetchSets(for exerciseId: UUID) -> [SetsModelDB] {
        return fetchModels(predicate: #Predicate<SetsModelDB> { $0.exercise?.id == exerciseId },
                           sortBy: [SortDescriptor(\SetsModelDB.index, order: .forward)])
    }
    
    func fetchStartedWorkout() -> ReportWorkoutModelDB? {
        return fetchItem(predicate: #Predicate<ReportWorkoutModelDB> { $0.endDate == nil })
    }
    
    func fetchCustomExerciseTypes() -> [CustomExerciseTypeModelDB] {
        fetchModels(sortBy: [SortDescriptor(\CustomExerciseTypeModelDB.createdAt, order: .forward)])
    }
    
    func createCustomExercise(title: String,
                              categoryId: String,
                              trackingType: ExerciseTrackingType,
                              descriptionText: String?) -> String {
        let item = CustomExerciseTypeModelDB(id: "custom_\(UUID().uuidString)",
                                             title: title,
                                             categoryId: categoryId,
                                             trackingTypeId: trackingType.rawValue,
                                             descriptionText: descriptionText,
                                             iconSystemName: trackingType.iconSystemName,
                                             sortOrder: count(type: CustomExerciseTypeModelDB.self) + 1)
        insert(model: item)
        save()
        return item.id
    }
    
    func deleteCustomExerciseTemplate(typeId: String) {
        let templates = fetchModels(predicate: #Predicate<CustomExerciseTypeModelDB> { $0.id == typeId })
        templates.forEach { remove(model: $0) }
        removeExercises(typeId: typeId, withSaving: false)
        save()
    }
    
    func fetchLatestCompletedReportWorkout(for workoutId: UUID) -> ReportWorkoutModelDB? {
        let uuid = workoutId
        return fetchModels(predicate: #Predicate<ReportWorkoutModelDB> { $0.workoutId == uuid && $0.endDate != nil },
                           sortBy: [SortDescriptor(\ReportWorkoutModelDB.endDate, order: .reverse)]).first
    }
    
    func fetchLatestCompletedReportWorkout(forWorkoutGroupId workoutGroupId: UUID) -> ReportWorkoutModelDB? {
        let uuid = workoutGroupId
        return fetchModels(predicate: #Predicate<ReportWorkoutModelDB> { $0.workoutGroupId == uuid && $0.endDate != nil },
                           sortBy: [SortDescriptor(\ReportWorkoutModelDB.endDate, order: .reverse)]).first
    }
    
    /// Reports
    
    func fetchAllReportWorkout() -> [ReportWorkoutModelDB] {
        return fetchModels(sortBy: [SortDescriptor(\ReportWorkoutModelDB.startDate, order: .forward)])
    }
    
    func fetchCompletedReportDashboardSnapshots() -> [ReportDashboardWorkoutSnapshot] {
        fetchModels(predicate: #Predicate<ReportWorkoutModelDB> { $0.endDate != nil },
                    sortBy: [SortDescriptor(\ReportWorkoutModelDB.startDate, order: .forward)])
            .map { report in
                ReportDashboardWorkoutSnapshot(id: report.id,
                                               titleWorkout: report.titleWorkout,
                                               workoutId: report.workoutId,
                                               titleWorkoutGroup: report.titleWorkoutGroup,
                                               workoutGroupId: report.workoutGroupId,
                                               startDate: report.startDate,
                                               endDate: report.endDate,
                                               targetExercisesCount: report.targetExercisesCount,
                                               exercises: report.exercises.map { exercise in
                    ReportDashboardExerciseSnapshot(id: exercise.id,
                                                    titleExercise: exercise.titleExercise,
                                                    exerciseId: exercise.exerciseId,
                                                    index: exercise.index,
                                                    typeId: exercise.typeId,
                                                    trackingTypeId: exercise.trackingTypeId,
                                                    restTime: exercise.restTime,
                                                    date: report.startDate,
                                                    workoutId: report.workoutId,
                                                    workoutGroupId: report.workoutGroupId,
                                                    titleWorkout: report.titleWorkout,
                                                    titleWorkoutGroup: report.titleWorkoutGroup,
                                                    sets: exercise.reportSets.map { set in
                        ReportDashboardSetSnapshot(id: set.id,
                                                   index: 0,
                                                   date: set.date,
                                                   reps: set.reps,
                                                   weight: set.weight,
                                                   distance: set.distance,
                                                   time: set.time)
                    },
                                                    targetSets: exercise.targetSets.map { set in
                        ReportDashboardTargetSetSnapshot(id: set.id,
                                                         index: set.index,
                                                         reps: set.reps,
                                                         weight: set.weight,
                                                         distance: set.distance,
                                                         time: set.time)
                    })
                })
            }
    }
    
    func fetchReportWorkout(id: UUID) -> ReportWorkoutModelDB? {
        let uuid = id
        return fetchItem(predicate: #Predicate<ReportWorkoutModelDB> { $0.id == uuid })
    }
    
    func fetchReportExercises(for workoutId: UUID) -> [ReportExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ReportExerciseModelDB> { $0.report?.id == workoutId },
                           sortBy: [SortDescriptor(\ReportExerciseModelDB.index, order: .forward)])
    }
    
    func fetchReportExercise(id: UUID) -> ReportExerciseModelDB? {
        let uuid = id
        return fetchItem(predicate: #Predicate<ReportExerciseModelDB> { $0.id == uuid })
    }
    
    func fetchReportExercise(exerciseId: UUID) -> ReportExerciseModelDB? {
        let uuid = exerciseId
        return fetchItem(predicate: #Predicate<ReportExerciseModelDB> { $0.exerciseId == uuid })
    }
    
    func fetchReportExercises(exerciseId: UUID) -> [ReportExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ReportExerciseModelDB> { $0.exerciseId == exerciseId })
            .sorted { ($0.report?.startDate ?? .distantPast) < ($1.report?.startDate ?? .distantPast) }
    }
    
    func fetchReportExercises(typeId: String) -> [ReportExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ReportExerciseModelDB> { $0.typeId == typeId })
            .sorted { ($0.report?.startDate ?? .distantPast) < ($1.report?.startDate ?? .distantPast) }
    }
    
    func fetchRecentReportExercises(exerciseId: UUID, dayLimit: Int) -> [ReportExerciseModelDB] {
        let reports = fetchModels(predicate: #Predicate<ReportExerciseModelDB> { $0.exerciseId == exerciseId })
            .sorted { ($0.report?.startDate ?? .distantPast) > ($1.report?.startDate ?? .distantPast) }
        guard dayLimit > 0 else {
            return []
        }
        
        var result = [ReportExerciseModelDB]()
        var days = Set<Date>()
        let calendar = Calendar.current
        
        for report in reports where !report.reportSets.isEmpty {
            guard let reportDate = report.report?.startDate else {
                continue
            }
            
            let day = calendar.startOfDay(for: reportDate)
            if days.contains(day) {
                result.append(report)
                continue
            }
            
            guard days.count < dayLimit else {
                break
            }
            
            days.insert(day)
            result.append(report)
        }
        
        return result
    }
    
    func fetchReportSet(id: UUID) -> ReportSetsModelDB? {
        let uuid = id
        return fetchItem(predicate: #Predicate<ReportSetsModelDB> { $0.id == uuid })
    }
    
    func fetchReportSets(for exerciseId: UUID) -> [ReportSetsModelDB] {
        return fetchModels(predicate: #Predicate<ReportSetsModelDB> { $0.reportExercise?.id == exerciseId },
                           sortBy: [SortDescriptor(\ReportSetsModelDB.date, order: .forward)])
    }
    
    // MARK: - Remove
    
    func removeWorkout(with id: UUID, withSaving: Bool = true) {
        
        guard let item = fetchItem(predicate: #Predicate<WorkoutModelDB> { $0.id == id }) else {
            return
        }
        
        item.workoutGroups.forEach { removeWorkoutGroup(with: $0.id, withSaving: false) }
        remove(model: item)
        if withSaving {
            save()
        }
    }
    
    func removeWorkoutGroup(with id: UUID, withSaving: Bool = true) {
        guard let item = fetchItem(predicate: #Predicate<WorkoutGroupModelDB> { $0.id == id }) else {
            return
        }
        
        item.exercises.forEach { removeExercise(with: $0.id, withSaving: false) }
        remove(model: item)
        if withSaving {
            save()
        }
    }
    
    func removeExercise(with id: UUID, withSaving: Bool = true) {
        guard let item = fetchItem(predicate: #Predicate<ExerciseModelDB> { $0.id == id }) else {
            return
        }
        
        item.sets.forEach { removeSets(with: $0.id, withSaving: false) }
        remove(model: item)
        if withSaving {
            save()
        }
    }
    
    func removeSets(with id: UUID, withSaving: Bool = true) {
        guard let removeItem = fetchItem(predicate: #Predicate<SetsModelDB> { $0.id == id }) else {
            return
        }
        remove(model: removeItem)
        
        let udid = removeItem.exercise?.id
        let sets = fetchModels(predicate: #Predicate<SetsModelDB> { $0.exercise?.id == udid },
                               sortBy: [SortDescriptor(\SetsModelDB.index, order: .forward)])
        
        for (index, value) in sets.enumerated() {
            value.index = index + 1
        }
        
        if withSaving {
            save()
        }
    }
    
    func removeSets(with ids: [UUID]) {
        for id in ids {
            removeSets(with: id, withSaving: false)
        }
    }
    
    func removeExercises(typeId: String, withSaving: Bool = true) {
        let items = fetchModels(predicate: #Predicate<ExerciseModelDB> { $0.typeId == typeId })
        items.forEach { removeExercise(with: $0.id, withSaving: false) }
        if withSaving {
            save()
        }
    }
    
    /// Reports
    
    func removeReportWorkout(with id: UUID, withSaving: Bool = true) {
        
        guard let item = fetchItem(predicate: #Predicate<ReportWorkoutModelDB> { $0.id == id }) else {
            return
        }
        
        item.exercises.forEach { removeReportExercise(with: $0.id, withSaving: false) }
        remove(model: item)
        if withSaving {
            save()
        }
    }
    
    func removeReportExercise(with id: UUID, withSaving: Bool = true) {
        guard let item = fetchItem(predicate: #Predicate<ReportExerciseModelDB> { $0.id == id }) else {
            return
        }
        
        item.reportSets.forEach { removeReportSets(with: $0.id, withSaving: false) }
        remove(model: item)
        if withSaving {
            save()
        }
    }
    
    func removeReportSets(with id: UUID, withSaving: Bool = true) {
        guard let removeItem = fetchItem(predicate: #Predicate<ReportSetsModelDB> { $0.id == id }) else {
            return
        }
        remove(model: removeItem)
        
        if withSaving {
            save()
        }
    }
    
    // MARK: - Updates
    
    func update(workout: WorkoutModel) {
        
        let uuid = workout.id
        
        if let item = fetchItem(predicate: #Predicate<WorkoutModelDB> { $0.id == uuid }) {
            item.title = workout.title
            item.isSelected = workout.isSelected
        } else {
            let item = WorkoutModelDB()
            self.insert(model: item)
            item.index = count(type: WorkoutModelDB.self) + 1
            item.title = workout.title
            item.isSelected = workout.isSelected
        }
        self.save()
    }
    
    func update(group: WorkoutGroupModel, workoutId: UUID? = nil) {
        
        let uuid = group.id
        
        if let item = fetchItem(predicate: #Predicate<WorkoutGroupModelDB> { $0.id == uuid }) {
            item.title = group.title
        } else if let workoutId = workoutId,
                    let workoutModel = fetchItem(predicate: #Predicate<WorkoutModelDB> { $0.id == workoutId }) {
            let item = WorkoutGroupModelDB()
            item.workout = workoutModel
            self.insert(model: item)
            item.index = workoutModel.workoutGroups.count
            item.title = group.title
        } else {
            assertionFailure("Can't update the WorkoutGroupModel, because the workoutId == nil")
        }
        
        self.save()
    }
    
    func update(exercise: ExerciseModel, groupId: UUID? = nil, withSaving: Bool = true) {
        let uuid = exercise.id
        if let item = fetchItem(predicate: #Predicate<ExerciseModelDB> { $0.id == uuid }) {
            item.title = exercise.title
            item.restTime = exercise.restTime
            item.isArchived = exercise.isArchived
            item.archivedAt = exercise.archivedAt
        } else if let groupId = groupId,
                    let groupModel = fetchItem(predicate: #Predicate<WorkoutGroupModelDB> { $0.id == groupId }) {
            let item = ExerciseModelDB()
            item.workoutGroup = groupModel
            self.insert(model: item)
            item.index = groupModel.exercises.count
            item.title = exercise.title
            item.restTime = exercise.restTime
            item.typeId = exercise.typeId
            item.isHeadline = exercise.isHeadline
            item.isArchived = exercise.isArchived
            item.archivedAt = exercise.archivedAt
        } else {
            assertionFailure("Can't update the ExerciseModel, because the groupId == nil")
        }
        
        if withSaving {
            self.save()
        }
    }
    
    func update(exercises: [ExerciseModel], groupId: UUID? = nil) {
        for model in exercises {
            update(exercise: model, groupId: groupId, withSaving: false)
        }
        save()
    }
    
    func addExercises(typeIds: [String], groupId: UUID) -> [UUID] {
        guard let groupModel = fetchItem(predicate: #Predicate<WorkoutGroupModelDB> { $0.id == groupId }) else {
            assertionFailure("Can't add exercises, because group was not found")
            return []
        }
        
        let activeExercises = fetchExercises(for: groupId)
        var nextIndex = (activeExercises.map(\.index).max() ?? 0) + 1
        var createdIds = [UUID]()
        
        for typeId in typeIds {
            let item = ExerciseModelDB()
            item.workoutGroup = groupModel
            insert(model: item)
            item.index = nextIndex
            item.typeId = typeId
            item.isHeadline = false
            item.isArchived = false
            item.archivedAt = nil
            createdIds.append(item.id)
            nextIndex += 1
        }
        
        save()
        return createdIds
    }
    
    func hideExercise(with id: UUID) {
        guard let item = fetchItem(predicate: #Predicate<ExerciseModelDB> { $0.id == id }) else {
            return
        }
        item.isArchived = true
        item.archivedAt = Date()
        save()
    }
    
    func restoreExercise(with id: UUID) -> UUID? {
        guard let item = fetchItem(predicate: #Predicate<ExerciseModelDB> { $0.id == id }),
              let groupId = item.workoutGroup?.id else {
            return nil
        }
        
        let activeExercises = fetchExercises(for: groupId)
        item.index = (activeExercises.map(\.index).max() ?? 0) + 1
        item.isArchived = false
        item.archivedAt = nil
        save()
        return item.id
    }
    
    func hiddenExercise(typeId: String, groupId: UUID) -> ExerciseModelDB? {
        fetchHiddenExercises(for: groupId).first { $0.typeId == typeId && !$0.isHeadline }
    }
    
    func activeExercise(typeId: String, groupId: UUID) -> ExerciseModelDB? {
        fetchExercises(for: groupId).first { $0.typeId == typeId && !$0.isHeadline }
    }
    
    func update(sets: SetsModel, exerciseId: UUID, withSaving: Bool = true) {
        let uuid = sets.id
        if let item = fetchItem(predicate: #Predicate<SetsModelDB> { $0.id == uuid }) {
            for param in sets.parameters {
                switch param {
                case .weight(let value):
                    item.weight = value
                case .repeats(let value):
                    item.reps = value
                case .distance(let value):
                    item.distance = value
                case .time(let value):
                    item.time = value
                }
            }
            
            if withSaving {
                self.save()
            }
        } else if let exerciseModel = fetchItem(predicate: #Predicate<ExerciseModelDB> { $0.id == exerciseId }) {
            let item = SetsModelDB()
            item.exercise = exerciseModel
            self.insert(model: item)
            item.index = exerciseModel.sets.count
            for param in sets.parameters {
                switch param {
                case .weight(let value):
                    item.weight = value
                case .repeats(let value):
                    item.reps = value
                case .distance(let value):
                    item.distance = value
                case .time(let value):
                    item.time = value
                }
            }
        } else {
            assertionFailure("Can't update the SetsModelDB, because the groupId == nil")
        }
    }
    
    func update(sets: [SetsModel], exerciseId: UUID) {
        for model in sets {
            update(sets: model, exerciseId: exerciseId, withSaving: false)
        }
        save()
    }
    
    func updateReport(sets: ReportSetsModel, withSaving: Bool = true) {
        let uuid = sets.id
        if let item = fetchItem(predicate: #Predicate<ReportSetsModelDB> { $0.id == uuid }) {
            for param in sets.parameters {
                switch param {
                case .weight(let value):
                    item.weight = value
                case .repeats(let value):
                    item.reps = value
                case .distance(let value):
                    item.distance = value
                case .time(let value):
                    item.time = value
                }
            }
            
            if withSaving {
                self.save()
            }
        } else {
            assertionFailure("Can't update the SetsModelDB, because the groupId == nil")
        }
    }
    
    func updateReport(sets: [ReportSetsModel]) {
        for model in sets {
            updateReport(sets: model, withSaving: false)
        }
        save()
    }
}
