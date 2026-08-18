//
//  BudjButtonStyle.swift
//  Budj
//

import SwiftUI

/// The app's three button weights.
///
/// Fully rounded, because the corner system says so, and the accent glow belongs
/// to `primary` alone — a screen with two glowing buttons has no primary action.
struct BudjButtonStyle: ButtonStyle {
    enum Variant {
        /// The action the screen is for. One per screen.
        case primary
        /// A real alternative, of equal standing — "skip" on the push step is
        /// this, not a text link.
        case secondary
        /// A tertiary action that should not compete: "use a different address".
        case quiet
    }

    let variant: Variant
    var isLoading = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BudjTypography.label)
            .foregroundStyle(foreground)
            // Hidden rather than removed, so the button keeps its size and the
            // layout does not jump while a request is in flight.
            .opacity(isLoading ? 0 : 1)
            .overlay { if isLoading { ProgressView().tint(foreground) } }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BudjSpacing.regular)
            .padding(.horizontal, BudjSpacing.loose)
            .background(background)
            .overlay(border)
            .clipShape(.capsule)
            .shadow(
                color: variant == .primary && isEnabled ? BudjColor.accent.opacity(0.35) : .clear,
                radius: 18,
                y: 6
            )
            .opacity(isEnabled ? 1 : 0.5)
            .pressScale(configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary: BudjColor.onAccent
        case .secondary: BudjColor.textPrimary
        case .quiet: BudjColor.textSecondary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary: BudjColor.accent
        case .secondary: BudjColor.surface
        case .quiet: Color.clear
        }
    }

    @ViewBuilder
    private var border: some View {
        switch variant {
        case .primary, .quiet:
            EmptyView()
        case .secondary:
            Capsule().strokeBorder(BudjColor.borderSubtle, lineWidth: 1)
        }
    }
}

extension ButtonStyle where Self == BudjButtonStyle {
    static var budjPrimary: BudjButtonStyle { BudjButtonStyle(variant: .primary) }
    static var budjSecondary: BudjButtonStyle { BudjButtonStyle(variant: .secondary) }
    static var budjQuiet: BudjButtonStyle { BudjButtonStyle(variant: .quiet) }

    static func budjPrimary(isLoading: Bool) -> BudjButtonStyle {
        BudjButtonStyle(variant: .primary, isLoading: isLoading)
    }
}

#Preview("Variants") {
    VStack(spacing: BudjSpacing.snug) {
        Button("Continue") {}.buttonStyle(.budjPrimary)
        Button("Continue") {}.buttonStyle(.budjPrimary(isLoading: true))
        Button("Continue") {}.buttonStyle(.budjPrimary).disabled(true)
        Button("Skip for now") {}.buttonStyle(.budjSecondary)
        Button("Use a different address") {}.buttonStyle(.budjQuiet)
    }
    .padding(BudjSpacing.loose)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(BudjColor.background)
}
