//
//  OnboardingStep.swift
//  Budj
//

import Foundation

/// The step the app is showing, which is the server's step with the app's own
/// steps interleaved.
///
/// The server knows about `billing`, `bank` and `ready` and derives them from
/// stored facts. Welcome, Face ID and push are invisible to it, so the app owns
/// their placement — and owns remembering that the permission steps were
/// offered, since nothing else can (D5).
nonisolated enum OnboardingStep: Equatable {
    /// The first-run screen: what Budj does, and a way in. Shown whenever there
    /// is no session, including after signing out.
    case welcome

    /// Email and password, in whichever mode the welcome screen's action chose.
    case signIn

    /// Client-only, and the first thing after signing in — it is about the
    /// session that was just established, so it is asked while that is still
    /// what the user is thinking about.
    case biometrics

    /// The paywall. There is no free tier, so this is unconditional.
    case billing

    /// The bank hand-off.
    case bank

    /// Client-only. After the bank, where the reason for it is concrete.
    case push

    /// Onboarding is finished.
    case ready
}
