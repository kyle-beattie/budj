//
//  LaunchGateModelTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

/// Every outcome in D6, including the two that are unreachable by hand: a
/// signed-in user against a server that is down, and a build the server has
/// stopped serving.
@MainActor
struct LaunchGateModelTests {

    // MARK: - Fixtures

    private static let configuration = APIConfiguration(baseURL: URL(string: "https://api.example.test")!)

    private func makeGate(
        transport: StubTransport,
        stored: BudjSession? = nil
    ) -> (LaunchGateModel, SessionStore, InMemorySessionPersistence) {
        let persistence = InMemorySessionPersistence(stored: stored)
        let session = SessionStore(persistence: persistence)
        let api = BudjAPI(
            configuration: Self.configuration,
            transport: transport,
            session: session,
            build: 412
        )
        return (LaunchGateModel(api: api, session: session), session, persistence)
    }

    private func status(step: String) -> [String: Any] {
        [
            "step": step,
            "subscriptionActive": step != "billing",
            "planCode": NSNull(),
            "bankConnected": step == "ready",
            "pushRegistered": false,
        ]
    }

    private func failure(_ code: String) -> [String: Any] {
        ["error": ["code": code, "message": "no"]]
    }

    // MARK: - No session

    @Test func noStoredSessionGoesToSignIn() async {
        let transport = StubTransport()
        let (gate, _, _) = makeGate(transport: transport)

        #expect(await gate.resolve() == .signIn)
        // Nothing is asked of the server on behalf of nobody.
        #expect(transport.requests.isEmpty)
    }

    /// A cancelled biometric prompt is not a locked state and not an error.
    @Test func anUnreadableItemGoesToSignIn() async {
        let transport = StubTransport()
        let (gate, _, persistence) = makeGate(transport: transport, stored: .stub())
        persistence.loadError = KeychainError.notUnlocked

        #expect(await gate.resolve() == .signIn)
        #expect(transport.requests.isEmpty)
    }

    // MARK: - A session, and an answer

    @Test func anUnfinishedStepIsTheServersStep() async {
        let transport = StubTransport()
        transport.answers = [.json(200, status(step: "bank"))]
        let (gate, _, _) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .onboarding(.bank))
    }

    @Test func aFinishedOnboardingIsReady() async {
        let transport = StubTransport()
        transport.answers = [.json(200, status(step: "ready"))]
        let (gate, _, _) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .ready)
    }

    // MARK: - A session, and no usable answer

    /// The whole point of the retryable state: assuming `billing` here shows a
    /// paywall to somebody who has already paid.
    @Test func anUnreachableServerNeverProducesAStep() async {
        let transport = StubTransport()
        transport.answers = [.failure(URLError(.notConnectedToInternet))]
        let (gate, _, _) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .unreachable)
    }

    @Test func aServerFailureIsAlsoNotAStep() async {
        let transport = StubTransport()
        transport.answers = [.json(500, failure("INTERNAL_ERROR"))]
        let (gate, _, _) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .unreachable)
    }

    @Test func aBodyThisBuildCannotReadIsNotAStep() async {
        let transport = StubTransport()
        transport.answers = [.json(200, ["step": "somethingNewer"])]
        let (gate, _, _) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .unreachable)
    }

    // MARK: - A session the server will not have

    @Test func aRefusedSessionIsClearedRatherThanRetried() async {
        let transport = StubTransport()
        // The 401, then the refresh attempt, which is also refused.
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .json(401, failure("UNAUTHORIZED")),
        ]
        let (gate, session, persistence) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .signIn)
        #expect(session.current == nil)
        #expect(persistence.stored == nil)
        #expect(persistence.removeCount >= 1)
    }

    // MARK: - The override

    /// Outranks every other destination, because once the server has stopped
    /// serving this build nothing else the app does is trustworthy.
    @Test func anUnsupportedBuildOutranksTheStep() async {
        let transport = StubTransport()
        transport.answers = [.json(426, failure("CLIENT_UPDATE_REQUIRED"))]
        let (gate, session, _) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .mustUpdate)
        // The session is not thrown away over it: updating the app resumes it.
        #expect(session.current != nil)
    }

    // MARK: - Retrying

    /// The retry behind `UnreachableView` runs the same gate. Re-reading the
    /// Keychain would raise a second Face ID prompt for an unlock that already
    /// happened.
    @Test func retryingDoesNotReadTheKeychainAgain() async {
        let transport = StubTransport()
        transport.answers = [
            .failure(URLError(.timedOut)),
            .json(200, status(step: "ready")),
        ]
        let (gate, _, persistence) = makeGate(transport: transport, stored: .stub())

        #expect(await gate.resolve() == .unreachable)
        let readsAfterFirst = persistence.loadCount

        #expect(await gate.resolve() == .ready)
        #expect(persistence.loadCount == readsAfterFirst)
    }
}
