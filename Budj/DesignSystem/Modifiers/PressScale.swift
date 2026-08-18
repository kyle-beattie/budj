//
//  PressScale.swift
//  Budj
//

import SwiftUI

/// The press feedback every control in the app shares.
///
/// Reduce Motion removes the scale rather than the feedback: the control still
/// dims, so a press is still visibly acknowledged.
struct PressScale: ViewModifier {
    let isPressed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion || !isPressed ? 1 : 0.96)
            .opacity(isPressed ? 0.86 : 1)
            .animation(BudjMotion.press, value: isPressed)
    }
}

extension View {
    func pressScale(_ isPressed: Bool) -> some View {
        modifier(PressScale(isPressed: isPressed))
    }
}
