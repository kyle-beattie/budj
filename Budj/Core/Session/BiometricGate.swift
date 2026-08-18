//
//  BiometricGate.swift
//  Budj
//

import Foundation

/// Whether biometry can be offered, and the prompt itself.
///
/// It unlocks a locally-held refresh token and nothing else. It is not a
/// payment authorisation and the server cannot verify it, so no copy anywhere
/// near this may imply that a transfer was approved by a face.
///
/// The gate does not read the session — `SessionStore.restore()` does that, and
/// the Keychain raises its own prompt for an item written behind the access
/// control. This is for the launch gate deciding whether to ask first, and for
/// the opt-in step deciding whether to offer at all.
struct BiometricGate {
    /// Shown under the system prompt's title. Sentence case, second person, and
    /// says what unlocking gets you rather than what it authorises.
    ///
    /// `nonisolated` because it is a default argument, and those are evaluated
    /// in a nonisolated context — main-actor-isolated by default, it warns
    /// today and fails to compile in the Swift 6 language mode (task 2.5).
    nonisolated static let unlockReason = "Unlock your saved sign-in."

    private let evaluator: any BiometricEvaluating

    init(evaluator: any BiometricEvaluating = LocalAuthenticationEvaluator()) {
        self.evaluator = evaluator
    }

    // MARK: - Availability

    /// What this device offers, or `nil` when the opt-in step has nothing to
    /// offer and should be skipped rather than shown and refused.
    var enrolledBiometry: BiometricKind? {
        evaluator.enrolledBiometry()
    }

    var isAvailable: Bool {
        enrolledBiometry != nil
    }

    // MARK: - Unlocking

    /// Asks, and answers with one of two routes.
    ///
    /// A device whose enrolment has since changed, or which never had biometry,
    /// is not asked at all: the answer is already sign-in.
    func unlock(reason: String = Self.unlockReason) async -> BiometricUnlock {
        guard isAvailable else { return .fallBackToSignIn }
        return await evaluator.evaluate(reason: reason) ? .unlocked : .fallBackToSignIn
    }
}
