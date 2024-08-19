//
//  SelectExerciseBarView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 16.08.2024.
//

import SwiftUI

struct SelectExerciseBarView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var countSelectedExercises: Int
    
    var addBlock: ()->()
    
    var clearBlock: ()->()
    
    private var color: Color {
        switch colorScheme {
        case .light:
            Color(UIColor.darkGray)
        default:
            Color(UIColor.lightGray)
        }
    }
    
    var body: some View {
        
        VStack(spacing: 5) {
            
            Text("Selected: \(countSelectedExercises)")
                .font(.subheadline)
                .foregroundStyle(color)
                .bold()
            
            HStack(spacing: 14) {
                
                Button {
                    clearBlock()
                } label: {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 1)
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                                .font(.title2)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                }
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(countSelectedExercises == 0)
                .buttonStyle(.plain)
                
                Button {
                    addBlock()
                } label: {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 1)
                        HStack {
                            Spacer()
                            Image(systemName: "plus.app")
                                .font(.title2)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                }
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .disabled(countSelectedExercises == 0)
                .buttonStyle(.plain)
            }
            .frame(height: 46)
        }
        .padding([.leading, .trailing, .bottom])
    }
}

#Preview {
    SelectExerciseBarView(countSelectedExercises: .constant(5), addBlock: {}, clearBlock: {})
}
