//
//  WorkoutListView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 27.07.2024.
//

import SwiftUI
import SDWebImageSwiftUI

//Avatar
//https://randomuser.me/api/portraits/men/38.jpg

enum WorkoutListViewRoute: Hashable {
    case workoutGroupListView(item: WorkoutModel)
}

struct WorkoutListView: View {
    
    @StateObject var viewModel = WorkoutListViewModel()
    
    @State private var editMode = EditMode.inactive
    
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        
        NavigationStack(path: $navigationManager.path) {
            VStack {
                List {
                    ForEach(viewModel.workouts) { item in
                        cells(for: item)
                    }
                    .onDelete(perform: deleteItems)
                    .onMove(perform: moveItems)
                }
                .refreshable {
                    refresh()
                }
                .environment(\.editMode, $editMode)
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    optionButton()
                }
            }
            .task {
                viewModel.reloadData {
                    if viewModel.workouts.count == 0 {
                        refresh()
                    }
                }
            }
            .sheet(isPresented: $viewModel.isEditWorkout, content: {
                editNameView()
                    .presentationDetents([.height(250)])
            })
            .contentSelf(content: { view in
                contentViewNavigation(content: view)
            })
        }
        .task {
            viewModel.setup()
        }
    }
    
    @ViewBuilder
    private func contentViewNavigation<T: View>(content: T) -> some View {
        content
            .navigationDestination(for: WorkoutListViewRoute.self, destination: { item in
                switch item {
                case .workoutGroupListView(let model):
                    WorkoutGroupListView(viewModel: WorkoutGroupListViewModel(workout: model))
                        .environment(\.navigation, navigationManager)
                }
            })
    }
    
    
    private func cells(for item: WorkoutModel) -> some View {
        
        WorkoutListCell(model: item) {
            switch $0 {
            case .update(let updateModel):
                switch editMode {
                case .active:
                    viewModel.edit(workout: updateModel)
                default:
                    navigationManager.path.append(WorkoutListViewRoute.workoutGroupListView(item: item))
                }
            default:
                break
            }
        }
    }
    
    private func optionButton() -> some View {
        switch editMode {
        case .active:
            return AnyView(Button("Done", action: clickBtnDone).bold())
        default:
            return AnyView(menuItem())
        }
    }
    
    private func menuItem() -> some View {
        Menu {
            Button("Edit", systemImage: "pencil", action: clickBtnEditint)
//            Button("Edit", systemImage: "thermometer.sun.fill", action: clickBtnEditint)
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(.red, .yellow, .blue)
            Button("New workout", systemImage: "plus.square", action: clickBtnNewWorkout)
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
                            title: viewModel.editWorkout == nil ? "New workout" : "Edit workout",
                     placeholder: "New workout name") {
            
            switch $0 {
            case .save(let name):
                viewModel.update(name: name)
            default:
                break
            }
        }
    }
    
    private func clickBtnEditint() {
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
        withAnimation {
            for index in offsets {
                viewModel.delete(index: index)
            }
        }
    }
    
    private func moveItems(source: IndexSet, destination: Int) {
        viewModel.moveItem(source: source, destination: destination)
    }
}

#Preview {
    WorkoutListView()
}
