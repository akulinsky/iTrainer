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
            Button("common.clear") {
                onClear()
            }
            .font(AppFont.rowTitle)
            .foregroundStyle(AppColor.brandPrimary)
            
            Spacer(minLength: 0)
            
            centerContent()
            
            Spacer(minLength: 0)
            
            Button("common.done") {
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

struct KeyboardAccessoryModifier<CenterContent: View>: ViewModifier {
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
