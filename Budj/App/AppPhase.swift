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
///
/// The step *within* onboarding is not here. `OnboardingModel` holds it, so
/// there is exactly one thing in the app that knows which step is showing.
nonisolated enum AppPhase: Equatable {
    /// Restoring the session and working out where to go.
    case launching

    /// Anywhere before the app is usable — sign in, and the steps after it.
    case onboarding

    /// Onboarding is finished.
    case ready

    /// There is a session, but the server could not be asked where this person
    /// is. Retryable, and deliberately not a step.
    case unreachable

    /// This build is no longer served. Terminal.
    case mustUpdate
}
