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

struct WorkoutListView: View {
    
    @StateObject var viewModel = WorkoutListViewModel()
    
    @State private var editMode = EditMode.inactive
    
    @State private var path = NavigationPath()
    
    var body: some View {
        
        NavigationStack(path: $path) {
            if let workout = viewModel.pinnedWorkout {
                WorkoutGroupListView(viewModel: WorkoutGroupListViewModel(workout: workout))
            } else {
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
            }
        }
        .task {
            viewModel.setup()
        }
    }
    
    private func cells(for item: WorkoutModel) -> some View {
        switch editMode {
        case .active:
            return AnyView(
                ZStack {
                    WorkoutListCell(model: item) {
                        switch $0 {
                        case .update(let updateModel):
                            viewModel.edit(workout: updateModel)
                            break
                        default:
                            break
                        }
                    }
                }
            )
        default:
            return AnyView(
                NavigationLink {
                    WorkoutGroupListView(viewModel: WorkoutGroupListViewModel(workout: item))
                    
                } label: {
                    WorkoutListCell(model: item) {
                        switch $0 {
                        case .update(_):
                            break
                        default:
                            break
                        }
                    }
                }
            )
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
