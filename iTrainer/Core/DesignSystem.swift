//
//  DesignSystem.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 23.06.2026.
//

import SwiftUI

enum AppColor {
    static let brandPrimary = Color("brandPrimary")
    static let backgroundPrimary = Color("backgroundPrimary")
    static let surfacePrimary = Color("surfacePrimary")
    static let surfaceSecondary = Color("surfaceSecondary")
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let separatorSoft = Color("separatorSoft")
    static let accentCoral = Color("accentCoral")
    static let workoutGreen = Color("workoutGreen")
    static let restAmber = Color("restAmber")
    static let progressRed = Color("progressRed")
    static let progressAmber = Color("progressAmber")
    static let progressGreen = Color("progressGreen")
    static let progressTrack = Color("progressTrack")
}

enum AppFont {
    static let largeTitle: Font = .system(size: 34, weight: .bold)
    static let screenTitle: Font = .system(size: 28, weight: .bold)
    static let rowTitle: Font = .system(size: 17, weight: .semibold)
    static let rowSubtitle: Font = .system(size: 14, weight: .regular)
    static let categoryCardTitle: Font = .system(size: 24, weight: .bold)
    static let categoryCardSubtitle: Font = .system(size: 17, weight: .regular)
    static let workoutWidgetTitle: Font = .system(size: 18, weight: .bold)
    static let workoutWidgetValue: Font = .system(size: 18, weight: .bold)
    static let workoutWidgetLabel: Font = .system(size: 16, weight: .bold)
    static let workoutGroupCardTitle: Font = .system(size: 18, weight: .bold)
    static let workoutGroupCardSubtitle: Font = .system(size: 16, weight: .regular)
    static let workoutGroupProgressValue: Font = .system(size: 20, weight: .bold)
    static let workoutGroupStatus: Font = .system(size: 15, weight: .medium)
    static let exerciseProgressValue: Font = .system(size: 16, weight: .bold)
    static let caption: Font = .system(size: 12, weight: .medium)
}
