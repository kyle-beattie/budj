//
//  BiometricUnlock.swift
//  Budj
//

import Foundation

/// The result of asking for biometry, as the two answers a caller can act on.
///
/// There is deliberately no error case and no third state. A cancelled prompt,
/// a failed match, a changed enrolment, and a device with no biometry at all
/// are the same answer — sign in again — and a caller that has to tell them
/// apart is a caller that will eventually get one of them wrong. There is no
/// retry counter and no lockout, because the only thing behind the prompt is a
/// token that signing in reissues.
nonisolated enum BiometricUnlock: Equatable {
    case unlocked
    case fallBackToSignIn
}
