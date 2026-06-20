//
//  DatabaseSeeder.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.06.2026.
//

import Foundation

enum DatabaseSeedMode {
    case production
    case clean
    case testData
}

struct DatabaseSeeder {
    
    let dataContainer: DataContainer
    
    func run(_ mode: DatabaseSeedMode) async {
        switch mode {
        case .production:
            break
        case .clean:
            await cleanDatabase()
        case .testData:
            await cleanDatabase()
            await seedTestData()
        }
    }
    
    private func cleanDatabase() async {
        let dataManager = DataManagerBackground(container: dataContainer.sharedModelContainer)
        
        await dataManager.removeAll(type: WorkoutModelDB.self)
        await dataManager.removeAll(type: WorkoutGroupModelDB.self)
        await dataManager.removeAll(type: ExerciseModelDB.self)
        await dataManager.removeAll(type: SetsModelDB.self)
        
        await dataManager.removeAll(type: ReportWorkoutModelDB.self)
        await dataManager.removeAll(type: ReportExerciseModelDB.self)
        await dataManager.removeAll(type: ReportSetsModelDB.self)
        await dataManager.save()
    }
    
    private func seedTestData() async {
        let dataManager = DataManagerBackground(container: dataContainer.sharedModelContainer)
        await addTestWorkout(dataManager: dataManager)
        await dataManager.save()
    }
    
    private func addTestWorkout(dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = WorkoutModelDB()
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout \(index)"
            item.isSelected = index == 1
            
            await addTestGroup(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestGroup(for workout: WorkoutModelDB, dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = WorkoutGroupModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.title = "Workout group \(index)"
            item.workout = workout
            
            await addTestExercise(for: item, dataManager: dataManager)
        }
    }
    
    private func addTestExercise(for group: WorkoutGroupModelDB, dataManager: DataManagerBackground) async {
        let exerciseIds = [
            "chest_bench_press",
            "chest_incline_dumbbell_press",
            "chest_dips",
            "back_pull_up",
            "back_barbell_row",
            "shoulders_seated_dumbbell_press"
        ]
        
        var currentCategoryId: String?
        var index = 0
        
        for exerciseId in exerciseIds {
            guard let exerciseType = dataContainer.arrayExercises.first(where: { $0.id == exerciseId }) else {
                assertionFailure("Missing test exercise with id: \(exerciseId)")
                continue
            }
            
            if currentCategoryId != exerciseType.type.id {
                let headline = ExerciseModelDB()
                
                await dataManager.insert(model: headline)
                headline.index = index
                headline.title = exerciseType.type.displayName
                headline.isHeadline = true
                headline.workoutGroup = group
                
                currentCategoryId = exerciseType.type.id
                index += 1
            }
            
            let item = ExerciseModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            item.typeId = exerciseId
            item.workoutGroup = group
            item.restTime = 120.0
            
            await addTestSets(for: item, dataManager: dataManager)
            index += 1
        }
    }
    
    private func addTestSets(for exercise: ExerciseModelDB, dataManager: DataManagerBackground) async {
        for index in 1...1 {
            let item = SetsModelDB()
            
            await dataManager.insert(model: item)
            item.index = index
            guard let typeExercise = dataContainer.arrayExercises.first(where: { $0.id == exercise.typeId }) else {
                assertionFailure("Missing exercise type with id: \(exercise.typeId)")
                continue
            }
            
            for param in typeExercise.parameters {
                switch param {
                case .weight(_):
                    item.weight = 50.0 + Float((index - 2)) * 10.0
                case .repeats(_):
                    item.reps = 10 - (index - 1)
                case .distance(_):
                    item.distance = 500 * Float(index)
                case .time(_):
                    item.time = TimeInterval(60 * index)
                }
            }
            
            item.exercise = exercise
        }
    }
}
