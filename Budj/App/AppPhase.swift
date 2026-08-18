//
//  AppPhase.swift
//  Budj
//

import Foundation

/// The four things the app can be showing at the top level.
///
/// Sign-in lives inside `onboarding` rather than beside it: signing in is the
/// first onboarding step, and treating it as a separate mode produces two
/// routers that have to agree.
nonisolated enum AppPhase: Equatable {
    /// Restoring the session and working out where to go.
    case launching

    /// Anywhere before the app is usable — sign in, and the steps after it.
    case onboarding

    /// Onboarding is finished.
    case ready

    /// This build is no longer served. Terminal.
    case mustUpdate
}
