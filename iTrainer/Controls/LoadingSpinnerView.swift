//
//  LoadingSpinnerView.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 11.06.2026.
//

import SwiftUI

struct LoadingSpinnerView: View {
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let animationDuration: TimeInterval

    init(
        color: Color = Color(red: 1.0, green: 0.86, blue: 0.36),
        size: CGFloat = 64,
        lineWidth: CGFloat = 5.5,
        animationDuration: TimeInterval = 1.85
    ) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.animationDuration = animationDuration
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let animationStep = animationStep(for: timeline.date)
            let arc = arcBounds(for: animationStep)

            Circle()
                .trim(from: arc.start, to: arc.end)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(360 * animationStep.progress - 90))
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text("common.loading"))
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func animationStep(for date: Date) -> LoadingSpinnerAnimationStep {
        guard animationDuration > 0 else {
            return LoadingSpinnerAnimationStep(progress: 0, cycle: 0)
        }

        let time = date.timeIntervalSinceReferenceDate
        let cycle = floor(time / animationDuration)
        let progress = time.truncatingRemainder(dividingBy: animationDuration) / animationDuration
        return LoadingSpinnerAnimationStep(progress: progress, cycle: cycle)
    }

    private func arcBounds(for step: LoadingSpinnerAnimationStep) -> LoadingSpinnerArc {
        let minimumLength = 0.06 + (0.12 * randomUnitValue(for: step.cycle))
        let maximumLength = 0.90

        if step.progress < 0.5 {
            let progress = eased(step.progress / 0.5)
            let length = minimumLength + ((maximumLength - minimumLength) * progress)
            return LoadingSpinnerArc(start: 0, end: length)
        }

        let progress = eased((step.progress - 0.5) / 0.5)
        let length = maximumLength - ((maximumLength - minimumLength) * progress)
        let end = maximumLength + ((1 - maximumLength) * progress)
        return LoadingSpinnerArc(start: end - length, end: end)
    }

    private func eased(_ value: Double) -> CGFloat {
        let value = min(max(value, 0), 1)
        return value * value * (3 - 2 * value)
    }

    private func randomUnitValue(for cycle: Double) -> Double {
        let seed = sin(cycle * 12.9898 + 78.233) * 43758.5453
        return seed - floor(seed)
    }
}

private struct LoadingSpinnerAnimationStep {
    let progress: Double
    let cycle: Double
}

private struct LoadingSpinnerArc {
    let start: CGFloat
    let end: CGFloat
}

#Preview {
    ZStack {
        Color(red: 0.07, green: 0.08, blue: 0.10)
            .ignoresSafeArea()

        LoadingSpinnerView()
    }
}
