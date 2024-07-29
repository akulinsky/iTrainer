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
    
    func fetchItem<T: PersistentModel>(predicate: Predicate<T>? = nil) -> T? {
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
            save()
        }
    }
    
    public func remove<T: PersistentModel>(model: T) {
        context.delete(model)
        save()
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
            save()
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

extension DataManagerBackground {
    
    func fetchAllWorkouts() -> [WorkoutModelDB] {
        return fetchModels(sortBy: [SortDescriptor(\WorkoutModelDB.index, order: .forward)])
    }
    
    func fetchWorkoutGroups(for workoutId: UUID) -> [WorkoutGroupModelDB] {
        return fetchModels(predicate: #Predicate<WorkoutGroupModelDB> { $0.workout?.id == workoutId },
                           sortBy: [SortDescriptor(\WorkoutGroupModelDB.index, order: .forward)])
    }
    
    func fetchExercise(for workoutGroupId: UUID) -> [ExerciseModelDB] {
        return fetchModels(predicate: #Predicate<ExerciseModelDB> { $0.workoutGroup?.id == workoutGroupId },
                           sortBy: [SortDescriptor(\ExerciseModelDB.index, order: .forward)])
    }
    
    func fetchSets(for exerciseId: UUID) -> [SetsModelDB] {
        return fetchModels(predicate: #Predicate<SetsModelDB> { $0.exercise?.id == exerciseId },
                           sortBy: [SortDescriptor(\SetsModelDB.index, order: .forward)])
    }
}
