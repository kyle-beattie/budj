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
///
/// `userID` is the session the question is being asked about, and is `nil`
/// before anybody is signed in. A step scoped to the device ignores it.
protocol ClientStepRecord {
    func hasOffered(_ step: ClientOnlyStep, userID: String?) -> Bool
    func recordOffered(_ step: ClientOnlyStep, userID: String?)
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

    func hasOffered(_ step: ClientOnlyStep, userID: String?) -> Bool {
        defaults.bool(forKey: Self.key(step, userID))
    }

    func recordOffered(_ step: ClientOnlyStep, userID: String?) {
        defaults.set(true, forKey: Self.key(step, userID))
    }

    /// A user-scoped step with nobody signed in has no key of its own to write.
    /// It falls back to the bare one rather than inventing a shared bucket that
    /// the next person to sign in would inherit.
    private static func key(_ step: ClientOnlyStep, _ userID: String?) -> String {
        guard step.scope == .user, let userID, !userID.isEmpty else {
            return prefix + step.rawValue
        }
        return "\(prefix)\(step.rawValue).\(userID)"
    }
}
