//
//  EditNameView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 31.07.2024.
//

import SwiftUI
import Combine

struct EditNameView: View {
    
    enum Result {
        case save(String)
        case cancel
    }
    
    typealias ResultBlock = (Result)->()
    
    @State private var value: String = ""
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @FocusState private var focused: Bool
    
    var shake = PassthroughSubject<Void, Never>()
    
    private var placeholder: String
    
    private var title: String
    
    private var complete: ResultBlock
    
    init(value: String = "", 
         title: String = "",
         placeholder: String = "New name",
         complete: @escaping ResultBlock) {
        
        _value = State(wrappedValue: value)
        self.title = title
        self.placeholder = placeholder
        self.complete = complete
    }
    
    var body: some View {
        NavigationStack {
            VStack {
//                Spacer()
                TextField(placeholder, text: $value)
                    .padding(.top, 30)
                    .focused($focused)
                    .textFieldStyle(.roundedBorder)
//                    .shakeAnimation(shake, intensity: 6, duration: 0.08)
                    .shakeAnimation(shake)
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        complete(.cancel)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if value.isEmpty {
                            shake.send()
                        } else {
                            complete(.save(value))
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            focused = true
        }
    }
}

#Preview {
    EditNameView(value: "Test name",
                 title: "Title Name",
                 placeholder: "Add new name") { result in }
}
