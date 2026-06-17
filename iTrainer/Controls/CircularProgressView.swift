//
//  CircularProgressView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 21.08.2024.
//

import SwiftUI

struct CircularProgressView: View {
    
    var lineWidth: CGFloat = 5
    
    var progress: Double = 0.75
    
    var body: some View {
        ZStack {
            Circle()
                .stroke( // 1
                    Color.gray.opacity(0.5),
                    lineWidth: lineWidth
                )
            Circle() // 2
                .trim(from: 0.0, to: progress)
                .stroke(
                    Color.gray,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round // round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

#Preview {
    CircularProgressView()
        .frame(width: 50, height: 50)
}
