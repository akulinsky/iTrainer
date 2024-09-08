//
//  ExerciseEditView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 22.08.2024.
//

import SwiftUI

struct ExerciseEditView: View {
    
    @StateObject var viewModel: ExerciseEditViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var strWeight: String = ""
    
    @State private var strReps: String = ""
    
    private var heightHeader: CGFloat = 50.0
    
    @State private var showAnimation = false
    
    private var color: Color {
        switch colorScheme {
        case .light:
            Color(UIColor.darkGray)
        default:
            Color(UIColor.lightGray)
        }
    }
    
    init(viewModel: ExerciseEditViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    titleView
                        .padding([.leading, .top, .trailing], 20)
                    
                    restTimeView
                        .padding([.leading, .top, .trailing], 20)
                    
                    setsView
                        .padding([.leading, .top, .trailing], 20)
                    
                    Color.clear
                        .frame(height: 60)
                }
            }
            .animation(.easeInOut, value: showAnimation)
            .safeAreaPadding(.bottom, 20)
            .dismissKeyboardOnTap()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(viewModel.exercise.type?.type.title ?? "Exercise")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                if presentationMode.wrappedValue.isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            cancel()
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            save()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.reloadData()
            }
        }
    }
    
    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func save() {
        viewModel.save { isSuccess in
            if isSuccess {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    @ViewBuilder
    private var titleView: some View {
        VStack {
            TextField("New title...", text: $viewModel.title)
                .padding([.leading, .trailing])
                .frame(height: 50)
                .foregroundStyle(color)
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
    }
    
    @ViewBuilder
    private var restTimeView: some View {
        VStack {
            HStack {
                Text("Rest time")
                    .foregroundStyle(.gray)
                
                Spacer()
            }
            
            HStack {
                TextField("Rest time", text: $viewModel.restTime, onEditingChanged: { focused in
                    viewModel.focusedRestTime(focused)
                })
                .textFieldStyle(AKTextFieldStyle())
                .frame(width: 75)
                .foregroundStyle(color)
                .keyboardType(.numberPad)
                
//                Spacer()
            }
            .opacity(viewModel.switchRest ? 0.3 : 1.0)
            .allowsHitTesting(!viewModel.switchRest)
//            .padding(.leading, 55)
            
            Toggle("Without rest", isOn: $viewModel.switchRest)
                .foregroundStyle(.gray)
        }
    }
    
    @ViewBuilder
    private var setsView: some View {
        VStack {
            HStack {
                Text("Sets")
                    .foregroundStyle(.gray)
                
                Spacer()
            }
            
            ForEach(viewModel.setsViewModels) { item in
                SetEditCell(viewModel: item) {
                    switch $0 {
                    case .delete(let item):
                        viewModel.delete(setsViewModel: item)
                        showAnimation.toggle()
                    default:
                        break
                    }
                }.transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            
            Button {
                addSet()
            } label: {
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: 1)
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.title)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .padding(.top, 10)
            }
            .foregroundStyle(color)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
//            .padding([.leading, .trailing], 40)
        }
    }
    
    private func addSet() {
        viewModel.add()
        showAnimation.toggle()
    }
}

#Preview {
    ExerciseEditView(viewModel: ExerciseEditViewModel(exercise: ExerciseModel(title: "Exercise GYM", typeId: "0")))
}
