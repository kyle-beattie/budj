//
//  OnboardingStatus.swift
//  Budj
//

import Foundation

/// Where the server says this user is, derived on every request from what it
/// actually knows. The app routes on this rather than on a cursor of its own,
/// so there is nothing to advance and nothing that can drift.
nonisolated struct OnboardingStatus: Decodable, Equatable, Sendable {
    /// The step the app should be showing. `pushRegistered` is deliberately not
    /// part of it: declining notifications must not hold anyone back.
    nonisolated enum Step: String, Decodable, Sendable {
        case billing
        case bank
        case ready
    }

    let step: Step
    let subscriptionActive: Bool
    let planCode: String?
    let bankConnected: Bool

    /// Advisory. Worth acting on — a rule that cannot notify cannot be approved
    /// — but never a reason to keep someone out of the app.
    let pushRegistered: Bool
}
