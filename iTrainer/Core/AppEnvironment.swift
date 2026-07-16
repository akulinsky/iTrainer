//
//  AppEnvironment.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 20.06.2026.
//

import SwiftUI

struct AppEnvironment {
    
    let dataContainer: DataContainer
    let appState: AppState
    let appSettings: AppSettings
    let databaseSeeder: DatabaseSeeder
    
    static let live = AppEnvironment(
        dataContainer: DataContainer.shared,
        appState: AppState(),
        appSettings: AppSettings.shared,
        databaseSeeder: DatabaseSeeder(dataContainer: DataContainer.shared)
    )
}

extension EnvironmentValues {
    
    private struct AppEnvironmentKey: EnvironmentKey {
        static let defaultValue = AppEnvironment.live
    }
    
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
