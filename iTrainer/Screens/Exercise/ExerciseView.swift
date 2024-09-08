//
//  ExerciseView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 29.07.2024.
//

import SwiftUI
import Combine

struct ExerciseView: View {
    
    @StateObject var viewModel: ExerciseViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    private var heightHeader: CGFloat = 50.0
    
    @State private var showAnimation = false
    
    init(viewModel: ExerciseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    @State var progress: Double = 0.65
    
    var body: some View {
        
        ScrollView {
            
            VStack {
                headerView
                    .frame(height: heightHeader)
                    .padding([.top, .leading, .trailing])
                
                restTimeView
                
                setsView
                    .padding()
                
                setDataView
                    .padding()
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
            .sheet(isPresented: $viewModel.isEditExercise, onDismiss: {
                viewModel.reloadData {
                    showAnimation.toggle()
                }
            }, content: {
                editExercise()
                    .presentationDetents([.large])
            })
        }
        .animation(.easeInOut, value: showAnimation)
        .safeAreaPadding(.bottom, 20)
        .dismissKeyboardOnTap()
        .scrollDismissesKeyboard(.immediately)
    }
    
    private var color: Color {
        switch colorScheme {
        case .light:
            Color(UIColor.gray)
        default:
            Color(UIColor.lightGray)
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            if let icon = viewModel.exercise.type?.icon {
                icon
                    .resizable()
                    .frame(width: heightHeader)
            } else {
                Color.red.frame(width: heightHeader)
            }
            VStack {
                Text(viewModel.title).leadingAlignment()
            }
        }
    }
    
    @ViewBuilder
    private var restTimeView: some View {
        HStack {
            CircularProgressView(progress: viewModel.progressRestTime)
                .frame(width: 60, height: 60)
                .overlay {
                    Text("\(viewModel.restTime.minuteSecond)")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .bold()
                }
        }
        .onTapGesture {
            viewModel.tapToTimer()
        }
    }
    
    @ViewBuilder
    private var setsView: some View {
        VStack {
            ForEach(viewModel.sets) { item in
                SetsCell(model: item) {
                    switch $0 {
                    case .update(let updateModel):
                        viewModel.edit(sets: updateModel)
                    case .selected(let selectedModel):
                        viewModel.addResult(with: selectedModel.parameters)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var setDataView: some View {
        HStack(spacing: 12) {
            
            ForEach($viewModel.paramsData) { $item in
                TextField(item.param.title, text: $item.value, onEditingChanged: { focused in
                    self.viewModel.focused(focused, paramData: item)
                })
                
                .padding([.leading, .trailing])
                .frame(maxHeight: .infinity)
                .shakeAnimation(item.shake)
                .keyboardType(item.keyboardType)
                .foregroundStyle(Color(UIColor.darkGray))
                .background {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(UIColor.lightGray))
                                .opacity(0.3)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 1)
                        }
                    }
                }
            }
            
            Button {
                prepareToSave()
            } label: {
                ZStack {
                    HStack {
                        Spacer()
                        Image(systemName: "plus.app")
                            .font(.largeTitle)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
            .foregroundStyle(color)
            .frame(width: 40, height: 40)
        }
        .frame(height: 40)
    }
    
    private func prepareToSave() {
        viewModel.save()
    }
    
    @ViewBuilder
    private func editSets() -> some View {
        EditSetsView(title: viewModel.editSets == nil ? "New sets" : "Edit sets",
                     params: viewModel.editSets?.parameters ?? []) {
            
            switch $0 {
            case .save(let params):
                viewModel.update(params: params)
            default:
                break
            }
        }
    }
    
    @ViewBuilder
    private func editExercise() -> some View {
        ExerciseEditView(viewModel: ExerciseEditViewModel(exercise: viewModel.exercise))
    }
    
    private func clickBtnEditint() {
        viewModel.isEditExercise = true
    }
    
    private func clickBtnNewSets() {
        viewModel.editSets = nil
        viewModel.isEditSets = true
    }
    
    private func refresh() {
        viewModel.refreshData()
    }
}

#Preview {
    ExerciseView(viewModel: ExerciseViewModel(exercise: ExerciseModel(title: "fff", typeId: "0")))
}
