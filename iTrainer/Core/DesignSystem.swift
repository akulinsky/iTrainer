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
}

enum AppFont {
    static let largeTitle: Font = .system(size: 34, weight: .bold)
    static let screenTitle: Font = .system(size: 28, weight: .bold)
    static let rowTitle: Font = .system(size: 17, weight: .semibold)
    static let rowSubtitle: Font = .system(size: 14, weight: .regular)
    static let caption: Font = .system(size: 12, weight: .medium)
}
