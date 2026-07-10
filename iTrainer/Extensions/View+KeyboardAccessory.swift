//
//  View+KeyboardAccessory.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 10.07.2026.
//

import SwiftUI

struct KeyboardAccessoryView<CenterContent: View>: View {
    let onClear: () -> Void
    let onDone: () -> Void
    @ViewBuilder let centerContent: () -> CenterContent
    
    var body: some View {
        HStack(spacing: 12) {
            Button("Clear") {
                onClear()
            }
            .font(AppFont.rowTitle)
            .foregroundStyle(AppColor.brandPrimary)
            
            Spacer(minLength: 0)
            
            centerContent()
            
            Spacer(minLength: 0)
            
            Button("Done") {
                onDone()
            }
            .font(AppFont.rowTitle)
            .foregroundStyle(AppColor.brandPrimary)
        }
        .padding(.horizontal, 18)
        .frame(height: 50)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

private struct KeyboardAccessoryModifier<CenterContent: View>: ViewModifier {
    let isPresented: Bool
    let onClear: () -> Void
    let onDone: () -> Void
    @ViewBuilder let centerContent: () -> CenterContent
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isPresented {
                    KeyboardAccessoryView(onClear: onClear,
                                          onDone: onDone,
                                          centerContent: centerContent)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
    }
}

extension View {
    func keyboardAccessory(isPresented: Bool,
                           onClear: @escaping () -> Void,
                           onDone: @escaping () -> Void) -> some View {
        modifier(KeyboardAccessoryModifier(isPresented: isPresented,
                                           onClear: onClear,
                                           onDone: onDone) {
            EmptyView()
        })
    }
    
    func keyboardAccessory<CenterContent: View>(isPresented: Bool,
                                                onClear: @escaping () -> Void,
                                                onDone: @escaping () -> Void,
                                                @ViewBuilder centerContent: @escaping () -> CenterContent) -> some View {
        modifier(KeyboardAccessoryModifier(isPresented: isPresented,
                                           onClear: onClear,
                                           onDone: onDone,
                                           centerContent: centerContent))
    }
}
