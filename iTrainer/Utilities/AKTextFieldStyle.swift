//
//  AKTextFieldStyle.swift
//  iTrainer
//
//  Created by Andrey Kulinskiy on 24.08.2024.
//

import Foundation
import SwiftUI

struct AKTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .frame(height: 40)
            .padding([.leading, .trailing])
            .background {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(UIColor.lightGray))
                            .opacity(0.3)
                        
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.gray, lineWidth: 1)
                    }
                }
            }
    }
}
