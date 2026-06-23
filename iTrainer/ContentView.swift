//
//  ContentView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    
    var body: some View {
        TabView {
            WorkoutGroupListView(viewModel: WorkoutGroupListViewModel())
                .tabItem {
                    Label("Workouts", image: "icTabPlans")
                }
            ExerciseTypeView()
                .tabItem {
                    Label("Exercises", image: "icTabExercises")
                }
            ReportsView()
                .tabItem {
                    Label("Reports", image: "icTabReports")
                }
        }
        .tint(AppColor.brandPrimary)
        .preferredColorScheme(.light)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppColor.surfacePrimary)
            appearance.shadowColor = UIColor(AppColor.separatorSoft)

            let normalColor = UIColor(AppColor.textSecondary)
            let selectedColor = UIColor(AppColor.brandPrimary)
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = normalColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            itemAppearance.selected.iconColor = selectedColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().tintColor = selectedColor
            UITabBar.appearance().unselectedItemTintColor = normalColor
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
