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
         placeholder: String = String(localized: "common.name.placeholder"),
         complete: @escaping ResultBlock) {
        
        _value = State(wrappedValue: value)
        self.title = title
        self.placeholder = placeholder
        self.complete = complete
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("common.name")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                    
                    TextField(placeholder, text: $value)
                        .textFieldStyle(.plain)
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(height: 48)
                        .focused($focused)
                        .shakeAnimation(shake)
                        .background(AppColor.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(AppColor.separatorSoft, lineWidth: 1)
                        }
                }
                .padding(16)
                .background(AppColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColor.separatorSoft, lineWidth: 1)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            .background(AppColor.backgroundPrimary)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") {
                        cancel()
                    }
                    .foregroundStyle(AppColor.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.save") {
                        save()
                    }
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.brandPrimary)
                }
            }
            .keyboardAccessory(isPresented: focused,
                               onClear: { value = "" },
                               onDone: { focused = false })
        }
        .onAppear {
            focused = true
        }
    }
    
    private func cancel() {
        complete(.cancel)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func save() {
        if value.isEmpty {
            shake.send()
        } else {
            complete(.save(value))
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    EditNameView(value: "Test name",
                 title: "Title Name",
                 placeholder: "Add new name") { result in }
}
