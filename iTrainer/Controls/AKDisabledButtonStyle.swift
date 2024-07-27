//
//  AKButtonStyle.swift
//  AjaxTestSwiftUI
//
//  Created by Andrey Kulinskiy on 24.07.2024.
//

import Foundation
import SwiftUI

struct AKDisabledButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(self.isEnabled ? 1 : 0.5)
            .contentShape(Rectangle())
    }
}
