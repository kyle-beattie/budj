//
//  AppPhase.swift
//  Budj
//

import Foundation

/// The five things the app can be showing at the top level.
///
/// Sign-in lives inside `onboarding` rather than beside it: signing in is the
/// first onboarding step, and treating it as a separate mode produces two
/// routers that have to agree.
nonisolated enum AppPhase: Equatable {
    /// Restoring the session and working out where to go.
    case launching

    /// Anywhere before the app is usable. `resuming` is the step the server
    /// reported, or `nil` when nobody is signed in yet and the flow starts at
    /// its beginning. It is never `.ready` — that outcome is `ready` below.
    case onboarding(resuming: OnboardingStatus.Step?)

    /// Onboarding is finished.
    case ready

    /// There is a session, but the server could not be asked where this person
    /// is. Retryable, and deliberately not a step.
    case unreachable

    /// This build is no longer served. Terminal.
    case mustUpdate
}
