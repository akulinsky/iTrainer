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
    
    var trackColor: Color = Color.gray.opacity(0.5)
    
    var progressColor: Color = Color.gray
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    trackColor,
                    lineWidth: lineWidth
                )
            Circle()
                .trim(from: 0.0, to: min(max(progress, 0), 1))
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
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
