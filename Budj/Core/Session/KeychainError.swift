//
//  KeychainError.swift
//  Budj
//

import Foundation

/// What can go wrong reading or writing the Keychain, separated into the two
/// cases the app treats differently.
enum KeychainError: Error, Equatable {
    /// The item exists but this person did not unlock it — a cancelled or
    /// failed biometric prompt, or an enrolment that has since changed. The
    /// answer is always to sign in again, never to retry.
    case notUnlocked

    /// Anything else the Security framework reported.
    case unhandled(status: OSStatus)
}
