//
//  View+Utils.swift
//  iWidget
//
//  Created by Huy Nguyen on 9/25/20.
//

import SwiftUI
import Combine
 
// MARK: - LeadingAlignmentModifier

struct LeadingAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            content
            Spacer(minLength: 0)
        }
    }
}

extension View {
    func leadingAlignment() -> some View {
        modifier(LeadingAlignmentModifier())
    }
}

// MARK: - TrailingAlignmentModifier

struct TrailingAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            content
        }
    }
}

extension View {
    func trailingAlignment() -> some View {
        modifier(TrailingAlignmentModifier())
    }
}

// MARK: - TopAlignmentModifier

struct TopAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            Spacer(minLength: 0)
        }
    }
}

extension View {
    func topAlignment() -> some View {
        modifier(TrailingAlignmentModifier())
    }
}

// MARK: - BottomAlignmentModifier

struct BottomAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            Spacer(minLength: 0)
        }
    }
}

extension View {
    func bottomAlignment() -> some View {
        modifier(TrailingAlignmentModifier())
    }
}

// MARK: - MultilineModifier

struct MultilineModifier: ViewModifier {
    let lineLimit: Int?
    
    func body(content: Content) -> some View {
        content.lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func multiline(lineLimit: Int? = nil) -> some View {
        modifier(MultilineModifier(lineLimit: lineLimit))
    }
}

// MARK: - Debug
extension View {
    func debugView(_ action: () -> Void) -> some View {
        action()
        return EmptyView()
    }
}

// MARK: - ClearButtonModifier
fileprivate struct ClearButtonModifier: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            
            Button(action: {
                text = ""
            }) {
                Image(systemName: "multiply.circle.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

extension View {
    func clearButton(text: Binding<String>) -> some View {
        modifier(ClearButtonModifier(text: text))
    }
}

// MARK: - DismissingKeyboard

struct DismissingKeyboard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        return modifier(DismissingKeyboard())
    }
}

// MARK: - ViewDidLoadModifier
struct ViewDidLoadModifier: ViewModifier {
    @State private var isViewDidLoad = false
    private let action: (() -> Void)

    init(perform action: @escaping (() -> Void)) {
        self.action = action
    }

    func body(content: Content) -> some View {
        content.onAppear {
            if isViewDidLoad == false {
                isViewDidLoad = true
                action()
            }
        }
    }
}

extension View {
    func onLoad(perform action: @escaping (() -> Void)) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}

// MARK: - Corner radius with border

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func roundedCornerWithBorder(lineWidth: CGFloat,
                                 borderColor: Color,
                                 radius: CGFloat = 5.0,
                                 corners: UIRectCorner = .allCorners) -> some View {
        
        clipShape(RoundedCorner(radius: radius, corners: corners) )
            .overlay(RoundedCorner(radius: radius, corners: corners)
                .stroke(borderColor, lineWidth: lineWidth))
    }
}

// MARK: - Shake View

struct ShakeViewModifier: ViewModifier {
    var sink: PassthroughSubject<Void, Never>
    let intensity: CGFloat
    let duration: CGFloat
    @State private var shake: Bool = false
    @State private var xIntensity: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? xIntensity : -xIntensity, y: 0)
            .onReceive(sink) { _ in
                self.xIntensity = intensity
                withAnimation(.easeInOut(duration: duration).repeatCount(5)) {
                    shake.toggle()
                } completion: {
                    withAnimation(.easeInOut(duration: duration)) {
                        self.xIntensity = 0
                    }
                }
            }
    }
}

extension View {
    func shakeAnimation(_ sink: PassthroughSubject<Void, Never>, intensity: CGFloat = 8, duration: CGFloat = 0.08) -> some View {
        modifier(ShakeViewModifier(sink: sink, intensity: intensity, duration: duration))
    }
}

// MARK: - apply If, use for modifiers

extension View {
    @ViewBuilder
    func applyIf<T: View>(_ condition: Bool, apply: (Self) -> T) -> some View {
        if condition {
            apply(self)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    func contentSelf<T: View>(content: (Self) -> T) -> some View {
        content(self)
    }
}

struct DistanceUnitPicker: View {
    let selectedUnit: DistanceInputUnit
    var units: [DistanceInputUnit] = DistanceInputUnit.metricUnits
    let onSelect: (DistanceInputUnit) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(units) { unit in
                Button {
                    onSelect(unit)
                } label: {
                    Text(unit.title)
                        .font(.system(size: 14, weight: selectedUnit == unit ? .bold : .semibold))
                        .foregroundStyle(selectedUnit == unit ? .white : AppColor.brandPrimary)
                        .frame(width: 58, height: 30)
                        .background {
                            if selectedUnit == unit {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppColor.brandPrimary)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(AppColor.backgroundPrimary.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppColor.separatorSoft, lineWidth: 1)
        }
    }
}

extension View {
    func keyboardAccessory(isPresented: Bool,
                           onClear: @escaping () -> Void,
                           onDone: @escaping () -> Void) -> some View {
        modifier(KeyboardAccessoryModifier(isPresented: isPresented,
                                           onClear: onClear,
                                           onDone: onDone) {
            EmptyView()
        })
    }
    
    func keyboardAccessory<CenterContent: View>(isPresented: Bool,
                                                onClear: @escaping () -> Void,
                                                onDone: @escaping () -> Void,
                                                @ViewBuilder centerContent: @escaping () -> CenterContent) -> some View {
        modifier(KeyboardAccessoryModifier(isPresented: isPresented,
                                           onClear: onClear,
                                           onDone: onDone,
                                           centerContent: centerContent))
    }
}
