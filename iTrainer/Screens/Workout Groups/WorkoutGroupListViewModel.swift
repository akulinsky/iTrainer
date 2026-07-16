//
//  WorkoutGroupListModelView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class WorkoutGroupListViewModel: ObservableObject {
    
    @Published var workoutGroups = [WorkoutGroupModel]()
    
    @Published private var exerciseCountsByGroupId = [UUID: Int]()
    
    @Published private var lastCompletedWorkoutGroupId: UUID?
    
    @Published private var lastCompletedProgressByGroupId = [UUID: Double]()
    
    @Published var isShowAlert = false
    
    @Published var isEditGroup = false
    
    @Published var isSelectWorkoutPresented = false
    
    var editGroup: WorkoutGroupModel?
    
    var errorMessage: String? = nil
    
    var workout: WorkoutModel?
    
    init(workout: WorkoutModel? = nil) {
        self.workout = workout
    }
    
    func fetchItems(complete: (()->())? = nil) {
        Task {
            
            guard let workout else { return }
            
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let items = await dataManager.fetchWorkoutGroups(for: workout.id).map { WorkoutGroupModel(model: $0) }
            let exerciseCountsByGroupId = await exerciseCounts(for: items, dataManager: dataManager)
            let lastCompletedReport = await dataManager.fetchLatestCompletedReportWorkout(for: workout.id)
            let lastCompletedWorkoutGroupId = lastCompletedReport?.workoutGroupId
            let lastCompletedProgressByGroupId = await progressByGroupId(for: items, dataManager: dataManager)
            await MainActor.run {
                workoutGroups = items
                self.exerciseCountsByGroupId = exerciseCountsByGroupId
                self.lastCompletedWorkoutGroupId = lastCompletedWorkoutGroupId
                self.lastCompletedProgressByGroupId = lastCompletedProgressByGroupId
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
    func reloadData(complete: (()->())? = nil) {
        if workout == nil {
            fetchSelectedWorkout(complete: complete)
        } else {
            fetchItems(complete: complete)
        }
    }
    
    func refreshData() {
        
    }
    
    func edit(group: WorkoutGroupModel) {
        guard workout != nil else { return }
        
        editGroup = group
        isEditGroup = true
    }
    
    func showWorkoutPicker() {
        isSelectWorkoutPresented = true
    }
    
    func select(workout: WorkoutModel) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.selectWorkout(with: workout.id)
            let selectedData = await selectedWorkoutData(from: dataManager)
            
            await MainActor.run {
                self.workout = selectedData.workout
                self.workoutGroups = selectedData.groups
                self.exerciseCountsByGroupId = selectedData.exerciseCountsByGroupId
                self.lastCompletedWorkoutGroupId = selectedData.lastCompletedWorkoutGroupId
                self.lastCompletedProgressByGroupId = selectedData.lastCompletedProgressByGroupId
                self.isSelectWorkoutPresented = false
            }
        }
    }
    
    func update(name: String) {
        guard workout != nil else { return }
        
        if var editGroup = editGroup {
            editGroup.title = name
            update(item: editGroup)
        } else {
            update(item: WorkoutGroupModel(title: name))
        }
        editGroup = nil
    }
    
    private func fetchSelectedWorkout(complete: (()->())? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            let selectedData = await selectedWorkoutData(from: dataManager)
            
            await MainActor.run {
                self.workout = selectedData.workout
                self.workoutGroups = selectedData.groups
                self.exerciseCountsByGroupId = selectedData.exerciseCountsByGroupId
                self.lastCompletedWorkoutGroupId = selectedData.lastCompletedWorkoutGroupId
                self.lastCompletedProgressByGroupId = selectedData.lastCompletedProgressByGroupId
                complete?()
            }
        }
    }
    
    private func selectedWorkoutData(from dataManager: DataManagerBackground) async -> (workout: WorkoutModel?, groups: [WorkoutGroupModel], exerciseCountsByGroupId: [UUID: Int], lastCompletedWorkoutGroupId: UUID?, lastCompletedProgressByGroupId: [UUID: Double]) {
        guard let selectedWorkoutDB = await dataManager.fetchSelectedWorkout() else {
            return (nil, [], [:], nil, [:])
        }
        
        let selectedWorkout = WorkoutModel(model: selectedWorkoutDB)
        let groups = await dataManager.fetchWorkoutGroups(for: selectedWorkout.id).map { WorkoutGroupModel(model: $0) }
        var exerciseCountsByGroupId = [UUID: Int]()
        for group in groups {
            exerciseCountsByGroupId[group.id] = await dataManager.fetchFlattenedExercises(for: group.id).count
        }
        let lastCompletedReport = await dataManager.fetchLatestCompletedReportWorkout(for: selectedWorkout.id)
        let lastCompletedProgressByGroupId = await progressByGroupId(for: groups, dataManager: dataManager)
        return (selectedWorkout,
                groups,
                exerciseCountsByGroupId,
                lastCompletedReport?.workoutGroupId,
                lastCompletedProgressByGroupId)
    }
    
    func exerciseCount(for groupId: UUID) -> Int {
        exerciseCountsByGroupId[groupId] ?? 0
    }
    
    func isLastCompletedGroup(_ groupId: UUID) -> Bool {
        lastCompletedWorkoutGroupId == groupId
    }
    
    func lastCompletedProgress(for groupId: UUID) -> Double {
        lastCompletedProgressByGroupId[groupId] ?? 0
    }
    
    private func exerciseCounts(for groups: [WorkoutGroupModel], dataManager: DataManagerBackground) async -> [UUID: Int] {
        var counts = [UUID: Int]()
        for group in groups {
            counts[group.id] = await dataManager.fetchFlattenedExercises(for: group.id).count
        }
        return counts
    }
    
    private func progressByGroupId(for groups: [WorkoutGroupModel], dataManager: DataManagerBackground) async -> [UUID: Double] {
        var progressById = [UUID: Double]()
        
        for group in groups {
            guard let report = await dataManager.fetchLatestCompletedReportWorkout(forWorkoutGroupId: group.id) else {
                continue
            }
            
            progressById[group.id] = progress(from: report,
                                              fallbackTargetCount: exerciseCountsByGroupId[group.id] ?? 0)
        }
        
        return progressById
    }
    
    private func progress(from report: ReportWorkoutModelDB, fallbackTargetCount: Int) -> Double {
        let targetCount = report.targetExercisesCount > 0 ? report.targetExercisesCount : fallbackTargetCount
        guard targetCount > 0 else {
            return 0
        }
        
        let completedCount = report.exercises.flattenedReportExerciseItems().count
        return min(Double(completedCount) / Double(targetCount), 1)
    }
    
    func update(item: WorkoutGroupModel) {
        Task {
            guard let workout else { return }
            
            await DataManagerBackground(container: DataContainer.shared.sharedModelContainer).update(group:item, workoutId: workout.id)
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    func moveItem(source: IndexSet, destination: Int) {
        Task {
            
            guard let workout else { return }
            
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var models = await dataManager.fetchWorkoutGroups(for: workout.id)
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
        guard workout != nil else { return }
        
        let item = self.workoutGroups[index]
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeWorkoutGroup(with: item.id)
//            print("DBG_ --------------")
//            print("DBG_  WorkoutModelDB count: \(await WorkoutModelDB.count())")
//            print("DBG_  WorkoutGroupModelDB count: \(await WorkoutGroupModelDB.count())")
//            print("DBG_  ExerciseModelDB count: \(await ExerciseModelDB.count())")
//            print("DBG_  SetsModelDB count: \(await SetsModelDB.count())")
            await MainActor.run {
                fetchItems()
            }
        }
    }
    
    private func addNewWorkoutGroupToBase(_ workoutGroupModel: WorkoutGroupModel, dataManager: DataManagerBackground) async {
        let item = WorkoutGroupModelDB()
        
        await dataManager.insert(model: item)
        item.index = workoutGroupModel.index
        item.title = workoutGroupModel.title
    }
}
