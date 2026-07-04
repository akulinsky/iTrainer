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
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var appState = appState
        
        TabView {
            WorkoutGroupListView(viewModel: WorkoutGroupListViewModel())
                .tabItem {
                    Label("Workouts", image: "icTabPlans")
                }
            ExerciseTypeView()
                .tabItem {
                    Label("Exercises", image: "icTabExercises")
                }
            ReportDashboardView()
                .tabItem {
                    Label("Reports", image: "icTabReports")
                }
        }
        .tint(AppColor.brandPrimary)
        .preferredColorScheme(.light)
        .fullScreenCover(item: $appState.reportToPresent) { report in
            PresentedReportView(report: report) {
                appState.reportToPresent = nil
            }
        }
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

private struct PresentedReportView: View {
    let report: ReportWorkoutModel
    let onClose: () -> Void
    
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ReportView(viewModel: ReportViewModel(report: report), onClose: onClose, onDelete: onClose)
                .environment(\.navigation, navigationManager)
                .navigationDestination(for: ReportsRoute.self) { route in
                    switch route {
                    case .reportsView:
                        ReportsView()
                            .environment(\.navigation, navigationManager)
                    case .reportView(let report):
                        ReportView(viewModel: ReportViewModel(report: report), onClose: onClose, onDelete: onClose)
                            .environment(\.navigation, navigationManager)
                    case .reportExerciseView(let exercise):
                        ReportExerciseView(viewModel: ReportExerciseViewModel(reportExercise: exercise))
                            .environment(\.navigation, navigationManager)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: onClose) {
                                        Image(systemName: "xmark")
                                    }
                                    .accessibilityLabel("Close")
                                }
                            }
                    case .exerciseStatisticsView(let exercise):
                        ExerciseStatisticsView(exercise: exercise)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: onClose) {
                                        Image(systemName: "xmark")
                                    }
                                    .accessibilityLabel("Close")
                                }
                            }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
