//
//  OnboardingModelTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct OnboardingModelTests {

    // MARK: - Fixtures

    private static let configuration = APIConfiguration(baseURL: URL(string: "https://api.example.test")!)

    /// The stubs are optional rather than defaulted: a default argument is
    /// evaluated in a nonisolated context, and these are main-actor types.
    private func makeModel(
        transport: StubTransport? = nil,
        record: InMemoryStepRecord? = nil,
        biometricsAvailable: Bool = true
    ) -> OnboardingModel {
        let transport = transport ?? StubTransport()
        let record = record ?? InMemoryStepRecord()
        let session = SessionStore(persistence: InMemorySessionPersistence(stored: .stub()))
        let api = BudjAPI(
            configuration: Self.configuration,
            transport: transport,
            session: session,
            build: 412
        )
        return OnboardingModel(api: api, record: record, biometricsAvailable: biometricsAvailable)
    }

    private func status(step: String, subscribed: Bool? = nil, pushRegistered: Bool = false) -> [String: Any] {
        [
            "step": step,
            "subscriptionActive": subscribed ?? (step != "billing"),
            "planCode": NSNull(),
            "bankConnected": step == "ready",
            "pushRegistered": pushRegistered,
        ]
    }

    private func failure(_ code: String) -> [String: Any] {
        ["error": ["code": code, "message": "no"]]
    }

    // MARK: - Seeding

    @Test func noSessionOpensOnWelcome() {
        let model = makeModel()
        model.seed(serverStep: nil)

        #expect(model.step == .welcome)
    }

    @Test func aWelcomeActionOpensSignInTheWayItChose() {
        let model = makeModel()
        model.seed(serverStep: nil)

        model.beginSignIn(registering: true)

        #expect(model.step == .signIn)
        #expect(model.startsRegistering)
    }

    /// Welcome is the entry point, not a step completed once. Signing out puts
    /// somebody back at the front door rather than on a bare sign-in form.
    @Test func signingOutReturnsToWelcome() {
        let model = makeModel()
        model.seed(serverStep: nil)
        model.beginSignIn(registering: false)
        #expect(model.step == .signIn)

        model.seed(serverStep: nil)

        #expect(model.step == .welcome)
    }

    @Test func theServersStepIsTheStepShown() {
        let record = InMemoryStepRecord(offered: [.biometrics])
        let model = makeModel(record: record)
        model.seed(serverStep: .billing)

        #expect(model.step == .billing)
    }

    // MARK: - Interleaving the client-only steps

    /// Face ID comes before the paywall, not after it. Meeting the price is
    /// not the first thing that should happen after signing in.
    @Test func biometricsIsOfferedBeforeBilling() {
        let model = makeModel()
        model.seed(serverStep: .billing)

        #expect(model.step == .biometrics)
    }

    /// Keyed off the first server step rather than off `billing` specifically,
    /// so a reinstall by somebody who already subscribed still gets asked.
    @Test func biometricsIsOfferedBeforeWhicheverStepIsFirst() {
        let model = makeModel()
        model.seed(serverStep: .bank)

        #expect(model.step == .biometrics)
    }

    @Test func pushIsOfferedBeforeReady() {
        let model = makeModel(record: InMemoryStepRecord(offered: [.biometrics]))
        model.seed(serverStep: .ready)

        #expect(model.step == .push)
    }

    /// The requirement this exists for: a declined offer is not repeated.
    @Test func aStepAlreadyOfferedIsNotOfferedAgain() {
        let record = InMemoryStepRecord(offered: [.biometrics])
        let model = makeModel(record: record)
        model.seed(serverStep: .billing)

        #expect(model.step == .billing)
    }

    /// The whole order, in one pass.
    @Test func theStepsRunInOrder() async {
        let transport = StubTransport()
        transport.answers = [
            .json(200, status(step: "bank")),
            .json(200, status(step: "ready")),
        ]
        let model = makeModel(transport: transport)

        model.seed(serverStep: nil)
        #expect(model.step == .welcome)

        model.beginSignIn(registering: true)
        #expect(model.step == .signIn)

        model.seed(serverStep: .billing)
        #expect(model.step == .biometrics)

        model.offered(.biometrics)
        #expect(model.step == .billing)

        await model.refresh()
        #expect(model.step == .bank)

        await model.refresh()
        #expect(model.step == .push)

        model.offered(.push)
        #expect(model.step == .ready)
    }

    @Test func answeringAClientStepMovesPastItWithoutAskingTheServer() {
        let transport = StubTransport()
        let model = makeModel(transport: transport)
        model.seed(serverStep: .billing)
        #expect(model.step == .biometrics)

        model.offered(.biometrics)

        #expect(model.step == .billing)
        // Face ID changes nothing the server can see, so asking it again could
        // not produce a different answer.
        #expect(transport.requests.isEmpty)
    }

    @Test func decliningIsRecordedTheSameAsAccepting() {
        let record = InMemoryStepRecord(offered: [.biometrics])
        let model = makeModel(record: record)
        model.seed(serverStep: .ready)

        model.offered(.push)

        #expect(record.hasOffered(.push))
        #expect(model.step == .ready)
    }

    /// A step that cannot be completed is not a step worth showing.
    @Test func aDeviceWithoutBiometryIsNotOfferedIt() {
        let record = InMemoryStepRecord()
        let model = makeModel(record: record, biometricsAvailable: false)
        model.seed(serverStep: .billing)

        #expect(model.step == .billing)
        // Not recorded: a device that gains an enrolment can still be asked.
        #expect(record.hasOffered(.biometrics) == false)
    }

    // MARK: - Refreshing

    @Test func refreshingRendersWhateverTheServerReports() async {
        let transport = StubTransport()
        transport.answers = [.json(200, status(step: "ready", pushRegistered: true))]
        let record = InMemoryStepRecord(offered: [.biometrics, .push])
        let model = makeModel(transport: transport, record: record)
        model.seed(serverStep: .billing)

        await model.refresh()

        #expect(model.step == .ready)
        #expect(model.pushOutstanding == false)
    }

    /// The rule the whole design rests on: a local success is not progress.
    @Test func aRefreshThatStillReportsBillingLeavesTheUserOnBilling() async {
        let transport = StubTransport()
        transport.answers = [.json(200, status(step: "billing"))]
        let model = makeModel(transport: transport, record: InMemoryStepRecord(offered: [.biometrics]))
        model.seed(serverStep: .billing)

        await model.refresh()

        #expect(model.step == .billing)
    }

    /// A failed refresh is not progress either. The step on screen stays put
    /// rather than being replaced by a guess.
    @Test func aFailedRefreshDoesNotMoveAnyone() async {
        let transport = StubTransport()
        transport.answers = [.failure(URLError(.notConnectedToInternet))]
        let record = InMemoryStepRecord(offered: [.biometrics])
        let model = makeModel(transport: transport, record: record)
        model.seed(serverStep: .bank)

        await model.refresh()

        #expect(model.step == .bank)
    }

    // MARK: - Entitlement

    @Test func aSubscriptionRequiredRefusalReturnsToBillingAndSaysWhy() async {
        let transport = StubTransport()
        transport.answers = [.json(402, failure("SUBSCRIPTION_REQUIRED"))]
        let record = InMemoryStepRecord(offered: [.biometrics])
        let model = makeModel(transport: transport, record: record)
        model.seed(serverStep: .bank)

        await model.refresh()

        #expect(model.step == .billing)
        #expect(model.entitlementLapsed)
    }

    @Test func aConfirmedSubscriptionClearsTheExplanation() async {
        let transport = StubTransport()
        transport.answers = [.json(200, status(step: "bank"))]
        let record = InMemoryStepRecord(offered: [.biometrics])
        let model = makeModel(transport: transport, record: record)
        model.seed(serverStep: .billing, entitlementLapsed: true)
        #expect(model.entitlementLapsed)

        await model.refresh()

        #expect(model.entitlementLapsed == false)
        #expect(model.step == .bank)
    }
}
