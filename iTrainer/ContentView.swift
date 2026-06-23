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
            WorkoutGroupListView(viewModel: WorkoutGroupListViewModel())
                .tabItem {
                    Label("Plans", systemImage: "list.dash")
                }
            ExerciseTypeView()
                .tabItem {
                    Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                }
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "calendar")
                }
        }
        .tint(AppColor.brandPrimary)
        .preferredColorScheme(.light)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColor.surfacePrimary)
            appearance.shadowColor = UIColor(AppColor.separatorSoft)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
