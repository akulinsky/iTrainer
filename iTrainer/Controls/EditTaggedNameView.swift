//
//  EditTaggedNameView.swift
//  iTrainer
//
//  Created by Codex on 24.07.2026.
//

import SwiftUI
import Combine

struct EditTaggedNameView: View {
    
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
    
    private var tags: [String]
    
    private var complete: ResultBlock
    
    init(value: String = "",
         title: String = "",
         placeholder: String = String(localized: "common.name.placeholder"),
         tags: [String],
         complete: @escaping ResultBlock) {
        
        _value = State(wrappedValue: value)
        self.title = title
        self.placeholder = placeholder
        self.tags = tags
        self.complete = complete
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focused = true
                            }
                    }
                    
                    tagList
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
    
    private var tagList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        append(tag: tag)
                    } label: {
                        Text(tag)
                            .font(AppFont.rowSubtitle)
                            .foregroundStyle(AppColor.textPrimary)
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(AppColor.backgroundPrimary)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(AppColor.separatorSoft, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private func cancel() {
        complete(.cancel)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func save() {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            shake.send()
        } else {
            complete(.save(trimmedValue))
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func append(tag: String) {
        let cleanTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTag.isEmpty else { return }
        
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !contains(tag: cleanTag, in: trimmedValue) else { return }
        
        if trimmedValue.isEmpty {
            value = cleanTag
        } else if trimmedValue.hasSuffix("&") {
            value = "\(trimmedValue) \(cleanTag)"
        } else if lastNamePartIsKnownTag(in: trimmedValue) {
            value = "\(trimmedValue) & \(cleanTag)"
        } else {
            value = "\(trimmedValue) \(cleanTag)"
        }
    }
    
    private func lastNamePartIsKnownTag(in text: String) -> Bool {
        let knownTags = Set(tags.map(normalized))
        let lastPart = text.components(separatedBy: "&").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastWord = lastPart.split(separator: " ").last.map(String.init) ?? ""
        
        return knownTags.contains(normalized(lastPart)) || knownTags.contains(normalized(lastWord))
    }
    
    private func contains(tag: String, in text: String) -> Bool {
        let normalizedTag = normalized(tag)
        let parts = text.components(separatedBy: "&").map { normalized($0) }
        let words = text.split { character in
            character.isWhitespace || character == "&"
        }.map { normalized(String($0)) }
        
        return parts.contains(normalizedTag) || words.contains(normalizedTag)
    }
    
    private func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

#Preview {
    EditTaggedNameView(value: "Chest",
                       title: "Title Name",
                       placeholder: "Add new name",
                       tags: ["Chest", "Back", "Triceps", "Legs"]) { result in }
}
