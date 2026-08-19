//
//  ClientOnlyStep.swift
//  Budj
//

import Foundation

/// The two steps the server has no opinion on.
///
/// Both are permission prompts, and both are asked exactly once. A declined
/// permission asked again on every launch is hostile, and for notifications the
/// system will not re-prompt in any case — so an app that keeps offering is an
/// app showing a button that cannot work.
nonisolated enum ClientOnlyStep: String, CaseIterable, Sendable {
    case biometrics
    case push

    /// How widely "asked once" reaches.
    ///
    /// **Not the same answer for both**, which is what the first version got
    /// wrong. Notification permission belongs to the app on the device: iOS will
    /// not re-prompt whoever is signed in, so asking per user would show a
    /// button that cannot work. Biometric unlock is about *the session*, and a
    /// second account signing in on the same device has a session of its own
    /// that nobody has been asked about — recording it per install meant they
    /// were never offered it at all.
    enum Scope {
        case device
        case user
    }

    var scope: Scope {
        switch self {
        case .biometrics: .user
        case .push: .device
        }
    }
}
