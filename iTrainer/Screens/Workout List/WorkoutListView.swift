//
//  WorkoutListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI

//Avatar
//https://randomuser.me/api/portraits/men/38.jpg

struct WorkoutListView: View {
    
    @EnvironmentObject private var workoutManager: WorkoutManager
    
    @StateObject var viewModel = WorkoutListViewModel()
    
    @State private var editMode = EditMode.inactive
    
    @State private var isActiveWorkoutDeletionAlertPresented = false
    
    @StateObject private var navigationManager = NavigationManager()
    
    private let onSelectWorkout: ((WorkoutModel) -> Void)?
    
    init(onSelectWorkout: ((WorkoutModel) -> Void)? = nil) {
        self.onSelectWorkout = onSelectWorkout
    }
    
    var body: some View {
        
        NavigationStack(path: $navigationManager.path) {
            VStack(spacing: 0) {
                if viewModel.workouts.isEmpty {
                    emptyWorkoutView()
                } else {
                    List {
                        ForEach(viewModel.workouts) { item in
                            cells(for: item)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppColor.backgroundPrimary)
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppColor.backgroundPrimary)
                    .refreshable {
                        refresh()
                    }
                    .environment(\.editMode, $editMode)
                }
            }
            .background(AppColor.backgroundPrimary)
            .navigationTitle("workouts.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    optionButton()
                }
            }
            .task {
                viewModel.reloadData()
            }
            .sheet(isPresented: $viewModel.isEditWorkout, content: {
                editNameView()
                    .presentationDetents([.height(250)])
            })
            .alert(Text("active_workout.delete_blocked.title"), isPresented: $isActiveWorkoutDeletionAlertPresented) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text("active_workout.delete_blocked.message")
            }
        }
        .task {
            viewModel.setup()
        }
    }
    
    private func emptyWorkoutView() -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(AppColor.textSecondary)
            Text("workouts.empty.title")
                .font(AppFont.rowTitle)
                .foregroundStyle(AppColor.textPrimary)
            Button("workouts.new", action: clickBtnNewWorkout)
                .buttonStyle(.borderedProminent)
                .tint(AppColor.brandPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(AppColor.backgroundPrimary)
    }
    
    private func cells(for item: WorkoutModel) -> some View {
        
        WorkoutListCell(model: item) {
            switch $0 {
            case .update(let updateModel):
                switch editMode {
                case .active:
                    viewModel.edit(workout: updateModel)
                default:
                    onSelectWorkout?(item)
                    break
                }
            default:
                break
            }
        }
    }
    
    private func optionButton() -> some View {
        switch editMode {
        case .active:
            return AnyView(Button("common.done", action: clickBtnDone).bold())
        default:
            return AnyView(menuItem())
        }
    }
    
    private func menuItem() -> some View {
        Menu {
            Button("common.edit", systemImage: "pencil", action: clickBtnEditint)
                .disabled(viewModel.workouts.isEmpty)
//            Button("Edit", systemImage: "thermometer.sun.fill", action: clickBtnEditint)
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(.red, .yellow, .blue)
            Button("workouts.new", systemImage: "plus.square", action: clickBtnNewWorkout)
        } label: {
            VStack {
                Spacer()
                Image(systemName: "ellipsis")
                Spacer()
            }
        }
    }
    
    private func editNameView() -> some View {
        
        var title = ""
        if let value = viewModel.editWorkout?.title {
            title = value
        }
        
        return EditNameView(value: title.isEmpty ? "" : title,
                            title: viewModel.editWorkout == nil ? String(localized: "workouts.new") : String(localized: "workouts.edit"),
                            placeholder: String(localized: "workouts.name.placeholder")) {
            
            switch $0 {
            case .save(let name):
                viewModel.update(name: name)
            default:
                break
            }
        }
    }
    
    private func clickBtnEditint() {
        guard !viewModel.workouts.isEmpty else { return }
        
        withAnimation {
            editMode = .active
        }
    }
    
    private func clickBtnDone() {
        withAnimation {
            editMode = .inactive
        }
    }
    
    private func clickBtnNewWorkout() {
        viewModel.editWorkout = nil
        viewModel.isEditWorkout = true
    }
    
    private func refresh() {
        viewModel.refreshData()
    }

    private func deleteItems(offsets: IndexSet) {
        viewModel.delete(offsets: offsets,
                         activeWorkoutGroupId: workoutManager.currentWorkoutGroupId) {
            isActiveWorkoutDeletionAlertPresented = true
        }
    }
    
    private func moveItems(source: IndexSet, destination: Int) {
        viewModel.moveItem(source: source, destination: destination)
    }
}

#Preview {
    WorkoutListView()
        .environmentObject(DataContainer.shared.workoutManager)
}
