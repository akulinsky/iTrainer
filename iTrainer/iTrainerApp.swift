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
    
    var dataContainer = DataContainer.shared

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(dataContainer).environmentObject(dataContainer.workoutManager)
        }
    }
}
