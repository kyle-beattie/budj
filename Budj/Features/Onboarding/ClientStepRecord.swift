//
//  ClientStepRecord.swift
//  Budj
//

import Foundation

/// Which client-only steps have been offered.
///
/// A protocol so the router's "never offer twice" rule can be tested without
/// touching the real defaults, which persist between test runs and would make
/// the second run of a test disagree with the first.
protocol ClientStepRecord {
    func hasOffered(_ step: ClientOnlyStep) -> Bool
    func recordOffered(_ step: ClientOnlyStep)
}

/// The real one.
///
/// User defaults rather than the Keychain: this is a boolean about whether a
/// question was asked, not a credential, and nothing here is worth protecting.
/// Keys are named for the step, never for what the step turns on, so nothing in
/// the defaults reads like a secret.
struct DefaultsStepRecord: ClientStepRecord {
    private static let prefix = "nz.app.Budj.onboarding.offered."

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasOffered(_ step: ClientOnlyStep) -> Bool {
        defaults.bool(forKey: Self.prefix + step.rawValue)
    }

    func recordOffered(_ step: ClientOnlyStep) {
        defaults.set(true, forKey: Self.prefix + step.rawValue)
    }
}
