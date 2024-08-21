//
//  ExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI

struct ExerciseView: View {
    
    @StateObject var viewModel: ExerciseViewModel
    
    @State private var strWeight: String = ""
    
    private var heightHeader: CGFloat = 50.0
    
    init(viewModel: ExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    @State var progress: Double = 0.65
    
    var body: some View {
        
        VStack {
            HStack {
                if let icon = viewModel.exercise.type?.icon {
                    icon
                        .resizable()
                        .frame(width: heightHeader)
                } else {
                    Color.red.frame(width: heightHeader)
                }
                VStack {
                    Text(viewModel.exercise.displayName).leadingAlignment()
                }
            }
            .frame(height: heightHeader)
            .padding([.top, .leading, .trailing])
            
            CircularProgressView(progress: progress)
                .frame(width: 60, height: 60)
                .overlay {
                    Text("\(TimeInterval(progress * 100).minuteSecond)")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                        .bold()
                }
            
            List {
                ForEach(viewModel.sets) { item in
                    SetsCell(model: item) {
                        switch $0 {
                        case .update(let updateModel):
                            viewModel.edit(sets: updateModel)
                            break
                        default:
                            break
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .refreshable {
                refresh()
            }
        }
        
        .navigationTitle(viewModel.exercise.type?.type.title ?? "Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit", systemImage: "pencil", action: clickBtnEditint)
            }
        }
        .task {
            viewModel.reloadData {
                if viewModel.sets.count == 0 {
                    refresh()
                }
            }
        }
        .sheet(isPresented: $viewModel.isEditSets, content: {
            editSets()
                .presentationDetents([.height(250)])
        })
    }
    
    private func editSets() -> some View {
        
        return EditSetsView(title: viewModel.editSets == nil ? "New sets" : "Edit sets",
                            weight: Float(viewModel.editSets?.weight ?? 0),
                            reps: viewModel.editSets?.reps ?? 0) {
            
            switch $0 {
            case .save(let weight, let reps):
                viewModel.update(weight: weight, reps: reps)
            default:
                break
            }
        }
    }
    
    private func clickBtnEditint() {
        print("DBG_ Edit Exercise")
    }
    
    private func clickBtnNewSets() {
        viewModel.editSets = nil
        viewModel.isEditSets = true
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

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ExerciseView(viewModel: ExerciseViewModel(exercise: ExerciseModel(title: "fff", typeId: "0")))
}
