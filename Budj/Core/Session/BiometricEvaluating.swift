//
//  BiometricEvaluating.swift
//  Budj
//

import Foundation
import LocalAuthentication

/// The device's biometry, as the two questions the app asks of it.
///
/// A protocol so `BiometricGate` can be tested at all: `LAContext` needs real
/// hardware, a real enrolment, and a real person's face, none of which a test
/// has.
protocol BiometricEvaluating {
    /// What this device offers right now, or `nil` when there is nothing to
    /// offer — no hardware, nothing enrolled, or biometry locked out.
    func enrolledBiometry() -> BiometricKind?

    /// Presents the prompt. `false` covers every way it can not succeed.
    func evaluate(reason: String) async -> Bool
}

/// The real one.
struct LocalAuthenticationEvaluator: BiometricEvaluating {
    func enrolledBiometry() -> BiometricKind? {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return nil
        }
        return switch context.biometryType {
        case .faceID: .faceID
        case .touchID: .touchID
        case .opticID: .opticID
        default: nil
        }
    }

    func evaluate(reason: String) async -> Bool {
        // A fresh context per evaluation. `LAContext` caches a successful
        // result for the life of the object, so a reused one can answer "yes"
        // without asking anybody anything.
        let context = LAContext()
        // No passcode fallback: failing falls back to signing in, which is a
        // route the user already has, rather than to a second lock screen.
        context.localizedFallbackTitle = ""

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
