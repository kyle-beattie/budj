//
//  BiometricGateTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct BiometricGateTests {

    @Test func aDeviceWithNothingEnrolledOffersNothing() {
        let gate = BiometricGate(evaluator: StubBiometricEvaluator(enrolled: nil))

        #expect(gate.isAvailable == false)
        #expect(gate.enrolledBiometry == nil)
    }

    @Test func availabilityNamesTheBiometry() {
        let gate = BiometricGate(evaluator: StubBiometricEvaluator(enrolled: .touchID))

        #expect(gate.isAvailable)
        #expect(gate.enrolledBiometry?.name == "Touch ID")
    }

    @Test func passingThePromptUnlocks() async {
        let gate = BiometricGate(evaluator: StubBiometricEvaluator(result: true))

        #expect(await gate.unlock() == .unlocked)
    }

    /// The whole point of the two-case result: a cancelled or failed prompt is
    /// a route, not an error the caller has to interpret.
    @Test func failingThePromptFallsBackToSignIn() async {
        let gate = BiometricGate(evaluator: StubBiometricEvaluator(result: false))

        #expect(await gate.unlock() == .fallBackToSignIn)
    }

    /// Nothing enrolled means the answer is already known, so nobody is shown a
    /// prompt they cannot pass.
    @Test func nothingEnrolledFallsBackWithoutPrompting() async {
        let evaluator = StubBiometricEvaluator(enrolled: nil, result: true)
        let gate = BiometricGate(evaluator: evaluator)

        #expect(await gate.unlock() == .fallBackToSignIn)
        #expect(evaluator.evaluateCount == 0)
    }

    /// The prompt says what unlocking gets you. It must not read as approving
    /// a payment, which is a thing this unlock cannot do.
    @Test func theReasonDoesNotImplyAuthorisingMoney() async throws {
        let evaluator = StubBiometricEvaluator()
        let gate = BiometricGate(evaluator: evaluator)

        _ = await gate.unlock()

        let reason = try #require(evaluator.lastReason)
        #expect(reason == BiometricGate.unlockReason)
        for word in ["confirm", "approve", "authorise", "pay", "transfer"] {
            #expect(reason.localizedCaseInsensitiveContains(word) == false)
        }
    }
}
