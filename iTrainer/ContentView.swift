//
//  ContentView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    var body: some View {
        
        TabView {
            WorkoutListView()
                .tabItem {
                    Label("Workouts", systemImage: "list.dash")
                }
            ExerciseTypeView()
                .tabItem {
                    Text("Exercises")
                    Image(systemName: "figure.disc.sports")
                }
            ReportsView()
                .tabItem {
                    Text("Reports")
                    Image(systemName: "calendar")
                }
        }
        .onAppear(perform: {
            UITabBar.appearance().backgroundColor = .systemGray4.withAlphaComponent(0.4)
        })
    }
}

#Preview {
    ContentView()
}
