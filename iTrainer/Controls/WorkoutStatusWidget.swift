//
//  WorkoutStatusWidget.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 23.06.2026.
//

import SwiftUI

struct WorkoutStatusWidget: View {
    let title: String
    let workoutTime: TimeInterval
    let restTime: TimeInterval?
    let restProgress: Double
    let workoutProgress: Double
    let onWorkoutTap: () -> Void
    let onRestTap: () -> Void
    let onProgressTap: () -> Void
    
    init(title: String = String(localized: "active_workout.title"),
         workoutTime: TimeInterval,
         restTime: TimeInterval? = nil,
         restProgress: Double = 0,
         workoutProgress: Double,
         onWorkoutTap: @escaping () -> Void = {},
         onRestTap: @escaping () -> Void = {},
         onProgressTap: @escaping () -> Void = {}) {
        self.title = title
        self.workoutTime = workoutTime
        self.restTime = restTime
        self.restProgress = restProgress
        self.workoutProgress = workoutProgress
        self.onWorkoutTap = onWorkoutTap
        self.onRestTap = onRestTap
        self.onProgressTap = onProgressTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.workoutWidgetTitle)
                .foregroundStyle(AppColor.textPrimary)
            
            HStack(alignment: .top, spacing: isRestVisible ? 14 : 7) {
                WorkoutStatusMetricView(title: String(localized: "active_workout.metric.workout"),
                                        value: workoutTime.workoutStatusDisplayTime,
                                        color: AppColor.workoutGreen,
                                        progress: 1,
                                        isFullRing: true,
                                        action: onWorkoutTap)
                
                WorkoutStatusMetricView(title: String(localized: "active_workout.metric.rest"),
                                        value: restTime?.minuteSecond ?? "0:00",
                                        color: AppColor.restAmber,
                                        progress: restProgress,
                                        isFullRing: false,
                                        action: onRestTap)
                .frame(width: isRestVisible ? nil : 0)
                .scaleEffect(isRestVisible ? 1 : 0.18)
                .opacity(isRestVisible ? 1 : 0)
                .clipped()
                .allowsHitTesting(isRestVisible)
                .accessibilityHidden(!isRestVisible)
                .zIndex(1)
                
                WorkoutStatusMetricView(title: String(localized: "active_workout.metric.progress"),
                                        value: "\(workoutProgressPercent)%",
                                        color: workoutProgressColor,
                                        progress: workoutProgress,
                                        isFullRing: false,
                                        action: onProgressTap)
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.72), value: isRestVisible)
        }
        .padding(18)
        .background(AppColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
    
    private var isRestVisible: Bool {
        restTime != nil
    }
    
    private var workoutProgressPercent: Int {
        Int((workoutProgress.clampedProgress * 100).rounded())
    }
    
    private var workoutProgressColor: Color {
        switch workoutProgressPercent {
        case 0...32:
            AppColor.progressRed
        case 33...65:
            AppColor.progressAmber
        default:
            AppColor.progressGreen
        }
    }
    
}

struct WorkoutStartCard: View {
    let workoutTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.workoutGreen)

                VStack(alignment: .leading, spacing: 4) {
                    Text("exercise_list.start_workout")
                        .font(AppFont.workoutGroupCardTitle)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(workoutTitle)
                        .font(AppFont.rowSubtitle)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColor.separatorSoft, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ActiveWorkoutContextNoticeCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColor.progressAmber)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("active_workout.other_context.title")
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)

                Text("active_workout.other_context.message")
                    .font(AppFont.rowSubtitle)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppColor.progressAmber.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColor.progressAmber.opacity(0.35), lineWidth: 1)
        }
    }
}

private struct WorkoutStatusMetricView: View {
    let title: String
    let value: String
    let color: Color
    let progress: Double
    let isFullRing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    WorkoutStatusRing(progress: progress,
                                      color: color,
                                      isFullRing: isFullRing)
                    
                    Text(value)
                        .font(AppFont.workoutWidgetValue)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .padding(.horizontal, 12)
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 110)
                
                Text(title)
                    .font(AppFont.workoutWidgetLabel)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct WorkoutStatusRing: View {
    let progress: Double
    let color: Color
    let isFullRing: Bool
    
    private let lineWidth: CGFloat = 5
    
    var body: some View {
        ZStack {
            if isFullRing {
                Circle()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            } else {
                Circle()
                    .stroke(AppColor.progressTrack, lineWidth: lineWidth)
                
                Circle()
                    .trim(from: 0, to: progress.clampedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress.clampedProgress)
            }
        }
        .padding(lineWidth / 2)
    }
}

private extension Double {
    var clampedProgress: Double {
        min(max(self, 0), 1)
    }
}

private extension TimeInterval {
    var workoutStatusDisplayTime: String {
        let safeValue = max(self, 0)
        let hours = Int(safeValue / 3600)
        let minutes = Int(safeValue / 60) % 60
        let seconds = Int(safeValue) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ZStack {
        AppColor.backgroundPrimary
            .ignoresSafeArea()
        
        WorkoutStatusWidget(title: "Push Day",
                            workoutTime: 9805,
                            restTime: 38,
                            restProgress: 0.72,
                            workoutProgress: 0.64)
            .padding(20)
    }
    .preferredColorScheme(.light)
}
