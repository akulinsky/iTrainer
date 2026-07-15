//
//  SupersetEditViewModel.swift
//  iTrainer
//
//  Created by Codex on 15.07.2026.
//

import Foundation

class SupersetEditViewModel: ObservableObject {
    @Published var superset: ExerciseModel
    @Published var title: String
    @Published var switchRest = false {
        didSet {
            guard oldValue != switchRest else { return }
            if switchRest {
                if restTimeSeconds > 0 {
                    previousRestTimeSeconds = restTimeSeconds
                }
                restTimeSeconds = 0
            } else if restTimeSeconds == 0 {
                restTimeSeconds = previousRestTimeSeconds
            }
        }
    }
    @Published var restTimeSeconds: Int
    @Published var children = [ExerciseModel]()
    @Published var availableExercises = [ExerciseModel]()
    @Published var isPickerPresented = false
    @Published var isDeleteConfirmationPresented = false
    @Published var isLoading = false
    private(set) var isDeleted = false
    let isActiveWorkoutLocked: Bool
    
    private var previousRestTimeSeconds = 120
    private let groupId: UUID
    
    init(superset: ExerciseModel, groupId: UUID, isActiveWorkoutLocked: Bool = false) {
        self.superset = superset
        self.groupId = groupId
        self.isActiveWorkoutLocked = isActiveWorkoutLocked
        self.title = superset.title ?? superset.displayName
        self.restTimeSeconds = Int(superset.restTime)
        self.switchRest = superset.restTime <= 0
        self.previousRestTimeSeconds = superset.restTime > 0 ? Int(superset.restTime) : 120
        self.children = superset.sortedSupersetExercises
    }
    
    var restTimeDisplay: String {
        switchRest ? "No rest" : TimeInterval(restTimeSeconds).minuteSecond
    }
    
    func setRestTime(seconds: Int) {
        let clampedSeconds = min(max(seconds, 0), 600)
        guard clampedSeconds > 0 else {
            switchRest = true
            return
        }
        restTimeSeconds = clampedSeconds
        previousRestTimeSeconds = clampedSeconds
        switchRest = false
    }
    
    func reloadData() {
        Task {
            await reloadDataAsync()
        }
    }
    
    @MainActor
    func moveChild(source: IndexSet, destination: Int) {
        guard !isActiveWorkoutLocked else { return }
        
        children.move(fromOffsets: source, toOffset: destination)
        saveChildOrder(reloadAfterSave: true)
    }
    
    @MainActor
    func moveChild(draggedId: UUID, to targetId: UUID) {
        guard !isActiveWorkoutLocked,
              draggedId != targetId,
              let sourceIndex = children.firstIndex(where: { $0.id == draggedId }),
              let destinationIndex = children.firstIndex(where: { $0.id == targetId }) else {
            return
        }
        
        let draggedChild = children.remove(at: sourceIndex)
        children.insert(draggedChild, at: destinationIndex)
        saveChildOrder(reloadAfterSave: false)
    }
    
    func save(complete: (() -> Void)? = nil) {
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            var updated = superset
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.title = trimmedTitle.isEmpty ? superset.displayName : trimmedTitle
            updated.restTime = switchRest ? 0 : TimeInterval(restTimeSeconds)
            await dataManager.update(exercise: updated)
            await reloadDataAsync()
            await MainActor.run {
                complete?()
            }
        }
    }
    
    func addSelectedExercises(ids: Set<UUID>) {
        guard !isActiveWorkoutLocked, !ids.isEmpty else { return }
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.addExercisesToSuperset(exerciseIds: Array(ids), supersetId: superset.id)
            await reloadDataAsync()
        }
    }
    
    func removeChild(_ child: ExerciseModel) {
        guard !isActiveWorkoutLocked else { return }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeExerciseFromSuperset(exerciseId: child.id)
            await reloadDataAsync()
        }
    }
    
    func hideChild(_ child: ExerciseModel) {
        guard !isActiveWorkoutLocked else { return }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.hideExercise(with: child.id)
            await reloadDataAsync()
        }
    }
    
    func deleteSuperset(complete: (() -> Void)? = nil) {
        guard !isActiveWorkoutLocked else { return }
        
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.removeExercise(with: superset.id)
            await MainActor.run {
                isDeleted = true
                complete?()
            }
        }
    }
    
    private func reloadDataAsync() async {
        await MainActor.run {
            isLoading = true
        }
        let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
        let currentSuperset = await dataManager.fetchExercise(with: superset.id).map { ExerciseModel(model: $0) }
        let available = await dataManager.fetchExercises(for: groupId)
            .filter { $0.isExerciseItem && $0.parentSuperset == nil && $0.id != superset.id }
            .map { ExerciseModel(model: $0) }
        
        await MainActor.run {
            if let currentSuperset {
                superset = currentSuperset
                title = currentSuperset.title ?? currentSuperset.displayName
                restTimeSeconds = Int(currentSuperset.restTime)
                switchRest = currentSuperset.restTime <= 0
                previousRestTimeSeconds = currentSuperset.restTime > 0 ? Int(currentSuperset.restTime) : 120
                children = currentSuperset.sortedSupersetExercises
            }
            availableExercises = available
            isLoading = false
        }
    }
    
    private func saveChildOrder(reloadAfterSave: Bool) {
        let orderedIds = children.map(\.id)
        Task {
            let dataManager = DataManagerBackground(container: DataContainer.shared.sharedModelContainer)
            await dataManager.reorderSupersetExercises(supersetId: superset.id, orderedIds: orderedIds)
            if reloadAfterSave {
                await reloadDataAsync()
            }
        }
    }
}
