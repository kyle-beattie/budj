//
//  InMemoryBiometricPreference.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// The biometric preference, without the real defaults — which persist between
/// runs and would make a test's second run disagree with its first.
@MainActor
final class InMemoryBiometricPreference: BiometricPreferenceStore {
    private(set) var requiresBiometry: Bool

    init(requiresBiometry: Bool = false) {
        self.requiresBiometry = requiresBiometry
    }

    func setRequiresBiometry(_ required: Bool) {
        requiresBiometry = required
    }
}
