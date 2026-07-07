//
//  iTrainerApp.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI
import SwiftData

@main
struct iTrainerApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    private let environment = AppEnvironment.live
    
#if DEBUG
private let seedMode: DatabaseSeedMode = .production
#else
private let seedMode: DatabaseSeedMode = .production
#endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appEnvironment, environment)
                .environment(environment.appState)
                .environmentObject(environment.dataContainer)
                .environmentObject(environment.dataContainer.workoutManager)
                .task {
                    await environment.databaseSeeder.run(seedMode)
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        environment.dataContainer.workoutManager.appDidBecomeActive()
                    case .background:
                        environment.dataContainer.workoutManager.appDidEnterBackground()
                    case .inactive:
                        environment.dataContainer.workoutManager.persistSessionState()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
