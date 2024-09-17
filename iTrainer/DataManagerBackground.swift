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
    
//    func fetchItems(sort: PersonSorting = .firstName, predicate: Predicate<PersonModelDB>? = nil) -> [PersonModelDB] {
//        do {
//            let keys = (sort == .firstName) ? \PersonModelDB.firstName : \PersonModelDB.lastName
//            let sort = SortDescriptor(keys, order: .forward)
//            return try context.fetch(FetchDescriptor<PersonModelDB>(predicate: predicate, sortBy: [sort]))
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//    }
    
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
//        save()
        /*
        do {
            
        } catch {
            fatalError(error.localizedDescription)
        }
         */
    }
    
    func removeAll<T: PersistentModel>(type: T.Type) {
        
        do {
            let descriptor = FetchDescriptor<T>()
            let results = try context.fetch(descriptor)
            for item in results {
                context.delete(item)
            }
//            save()
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
    
    func fetchWorkoutGroups(for workoutId: UUID) -> [WorkoutGroupModelDB] {
        return fetchModels(predicate: #Predicate<WorkoutGroupModelDB> { $0.workout?.id == workoutId },
                           sortBy: [SortDescriptor(\WorkoutGroupModelDB.index, order: .forward)])
    }
    
    func fetchWorkoutGroup(with id: UUID) -> WorkoutGroupModelDB? {
        let uuid = id
        return fetchItem(predicate: #Predicate<WorkoutGroupModelDB> { $0.id == uuid })
    }
    
    func fetchExercises(for workoutGroupId: UUID) -> [ExerciseModelDB] {
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
    
    func fetchAllReportWorkout() -> [ReportWorkoutModelDB] {
        return fetchModels(sortBy: [SortDescriptor(\ReportWorkoutModelDB.startDate, order: .forward)])
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
        return fetchModels(predicate: #Predicate<ReportExerciseModelDB> { $0.exerciseId == exerciseId },
                           sortBy: [SortDescriptor(\ReportExerciseModelDB.report?.startDate, order: .forward)])
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
        } else {
            let item = WorkoutModelDB()
            self.insert(model: item)
            item.index = count(type: WorkoutModelDB.self) + 1
            item.title = workout.title
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
