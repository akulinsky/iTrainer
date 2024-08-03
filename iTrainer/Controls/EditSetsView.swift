//
//  EditSetsView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 02.08.2024.
//

import SwiftUI
import Combine

struct EditSetsView: View {
    
    enum Result {
        case save(Float, Int)
        case cancel
    }
    
    typealias ResultBlock = (Result)->()
    
    @State private var strWeight: String = ""
    
    @State private var strReps: String = ""
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    private var weight: Float
    private var reps: Int
    
    private var placeholderWeight: String {
        weight > 0 ? String(format: "%.1f", weight) : "Weight"
    }
    
    private var placeholderReps: String {
        reps > 0 ? String(reps) : "Reps"
    }
    
    private var shakeReps = PassthroughSubject<Void, Never>()
    private var shakeWeight = PassthroughSubject<Void, Never>()
    
    private var title: String
    
    private var complete: ResultBlock
    
    init(title: String = "",
         weight: Float = 0,
         reps: Int = 0,
         complete: @escaping ResultBlock) {
        
        self.title = title
        self.weight = weight
        self.reps = reps
        self.complete = complete
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline) {
                            if weight > 0 {
                                Text("Weight:")
                                    .font(.caption)
                                Text("\(String(format: "%.1f", weight))")
                                    .font(.footnote.bold())
                            }
                        }
                        .frame(height: 30)
                        .padding([.leading, .trailing])
                        .foregroundStyle(.gray)
                        
                        HStack {
                            TextField(placeholderWeight, text: $strWeight)
                                .padding([.leading, .trailing])
                                .textFieldStyle(.roundedBorder)
                                .shakeAnimation(shakeWeight)
                                .keyboardType(.numberPad)
                            
                            Text("x")
                                .foregroundStyle(Color(UIColor.lightGray))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        
                        HStack(alignment: .firstTextBaseline) {
                            if reps > 0 {
                                Text("Reps:")
                                    .font(.caption)
                                Text("\(reps)").bold()
                                    .font(.footnote.bold())
                            }
                        }
                        .frame(height: 30)
                        .padding([.leading, .trailing])
                        .foregroundStyle(.gray)
                        
                        TextField(placeholderReps, text: $strReps)
                            .padding([.leading, .trailing])
                            .textFieldStyle(.roundedBorder)
                            .shakeAnimation(shakeReps)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .padding()
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        cancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        prepareToSave()
                    }
                }
            }
        }
    }
    
    private func prepareToSave() {
        
        var resultWeight: Float = 0.0
        var resultReps: Int = 0
        
        
        if strWeight.isEmpty, weight > 0 {
            resultWeight = weight
        } else if let weight = Float(strWeight), weight > 0 {
            resultWeight = weight
        } else {
            shakeWeight.send()
            return
        }
        
        if strReps.isEmpty, reps > 0 {
            resultReps = reps
        } else if let reps = Int(strReps), reps > 0 {
            resultReps = reps
        } else {
            shakeReps.send()
            return
        }
        
        complete(.save(resultWeight, resultReps))
        presentationMode.wrappedValue.dismiss()
    }
    
    private func cancel() {
        complete(.cancel)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditSetsView(title: "Add new sets", weight: 100, reps: 8) { result in }
}
