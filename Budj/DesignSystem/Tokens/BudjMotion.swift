//
//  BudjMotion.swift
//  Budj
//

import SwiftUI

/// Two curves and three durations, and nothing else.
///
/// Every animation in the app names the value driving it — `.animation(_:value:)`
/// rather than an implicit `withAnimation` around whatever happens to change —
/// so that an unrelated state change cannot animate something it has nothing to
/// do with.
enum BudjMotion {
    /// Press feedback. Short enough to feel like the control responded rather
    /// than played.
    static let pressDuration: TimeInterval = 0.12
    /// The default for a state change.
    static let defaultDuration: TimeInterval = 0.2
    /// Sheets, and moving between steps.
    static let transitionDuration: TimeInterval = 0.34

    /// The standard curve. Most things use this.
    static let standard = Animation.easeInOut(duration: defaultDuration)

    /// Press feedback, on the same curve but faster.
    static let press = Animation.easeOut(duration: pressDuration)

    /// The springier one, for toggles and sheet presentation — the places where
    /// a little overshoot reads as physical rather than decorative.
    static let springy = Animation.spring(response: transitionDuration, dampingFraction: 0.78)

    /// Moving between onboarding steps.
    static let transition = Animation.easeInOut(duration: transitionDuration)

    /// The same transition, honouring Reduce Motion: movement becomes a
    /// cross-fade rather than disappearing entirely, because a step that swaps
    /// with no transition at all reads as a glitch.
    static func stepTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
    }
}
