//
//  StubBiometricEvaluator.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// Biometry without hardware, an enrolment, or a face.
@MainActor
final class StubBiometricEvaluator: BiometricEvaluating {
    var enrolled: BiometricKind?
    var result = false

    private(set) var evaluateCount = 0
    private(set) var lastReason: String?

    init(enrolled: BiometricKind? = .faceID, result: Bool = true) {
        self.enrolled = enrolled
        self.result = result
    }

    func enrolledBiometry() -> BiometricKind? {
        enrolled
    }

    func evaluate(reason: String) async -> Bool {
        evaluateCount += 1
        lastReason = reason
        return result
    }
}
