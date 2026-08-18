//
//  LaunchDestination.swift
//  Budj
//

import Foundation

/// Where launch decided to send someone, as the five answers D6 defines.
///
/// It is exhaustive on purpose. The thing a launch gate must never do is guess:
/// assuming `billing` when the status request failed shows a paywall to a paying
/// customer, which is the worst available guess. Every way of not knowing lands
/// on `unreachable` instead, which is retryable and says so.
nonisolated enum LaunchDestination: Equatable {
    /// No session, or one the server refused. The entry point.
    case signIn

    /// A session, and the server says onboarding is not finished. Carries the
    /// server's own step so nothing local has to remember where anyone was.
    case onboarding(OnboardingStatus.Step)

    /// A session, and onboarding is finished.
    case ready

    /// A session, and the server could not be asked. Retryable, and never a
    /// step.
    case unreachable

    /// The server has stopped serving this build. Outranks all of the above.
    case mustUpdate
}
