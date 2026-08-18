//
//  EmailSignInModelTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct EmailSignInModelTests {

    private func makeModel(
        transport: StubTransport,
        session: SessionStore? = nil
    ) -> EmailSignInModel {
        let session = session ?? SessionStore(persistence: InMemorySessionPersistence())
        let api = BudjAPI(
            configuration: APIConfiguration(baseURL: URL(string: "https://api.example.test")!),
            transport: transport,
            session: session,
            build: 412
        )
        return EmailSignInModel(authenticator: Authenticator(api: api, session: session))
    }

    private func failure(_ status: Int, _ code: String, _ message: String = "no") -> StubTransport.Answer {
        .json(status, ["error": ["code": code, "message": message]])
    }

    // MARK: - Validation

    @Test func anAddressWithoutAnAtSignIsRefusedBeforeAnyRequest() async {
        let transport = StubTransport()
        let model = makeModel(transport: transport)
        model.email = "someone.example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.emailError == "Enter a valid email address")
        #expect(transport.requests.isEmpty)
    }

    @Test func aShortPasswordIsRefusedWhenRegisteringButNotWhenSigningIn() async {
        let transport = StubTransport()
        transport.answers = [failure(401, "UNAUTHORIZED")]

        let registering = makeModel(transport: StubTransport())
        registering.setMode(.register)
        registering.email = "someone@example.com"
        registering.password = "short"
        await registering.submit()
        #expect(registering.passwordError == "Use at least 8 characters")

        // Signing in does not second-guess an existing password's length; the
        // rule only applies to one being chosen.
        let signingIn = makeModel(transport: transport)
        signingIn.email = "someone@example.com"
        signingIn.password = "short"
        await signingIn.submit()
        #expect(signingIn.passwordError == nil)
    }

    @Test func theAddressIsTrimmedBeforeItIsSent() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, BudjSession.stubJSON(accessToken: "a", refreshToken: "r"))]
        let model = makeModel(transport: transport)
        model.email = "  someone@example.com  "
        model.password = "hunter22"

        await model.submit()

        let body = try #require(transport.requests[0].httpBody)
        let sent = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(sent?["email"] as? String == "someone@example.com")
    }

    // MARK: - Outcomes

    @Test func aSuccessfulSignInReportsSignedIn() async {
        let transport = StubTransport()
        transport.answers = [.json(200, BudjSession.stubJSON(accessToken: "a", refreshToken: "r"))]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.outcome == .signedIn)
        #expect(model.formError == nil)
    }

    /// Registered, no session, and nothing went wrong. The screen must not say
    /// it did.
    @Test func registeringWithConfirmationPendingIsItsOwnOutcome() async {
        let transport = StubTransport()
        transport.answers = [.json(201, ["session": NSNull(), "confirmationRequired": true])]
        let model = makeModel(transport: transport)
        model.setMode(.register)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.outcome == .confirmationRequired)
        #expect(model.formError == nil)
    }

    // MARK: - Failures

    /// The message names neither half, because saying which one was wrong tells
    /// a stranger which addresses have accounts.
    @Test func badCredentialsProduceOneMessageThatBlamesNeitherField() async {
        let transport = StubTransport()
        transport.answers = [failure(401, "UNAUTHORIZED", "Invalid email or password")]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "wrong"

        await model.submit()

        #expect(model.formError == "That email and password do not match an account.")
        #expect(model.emailError == nil)
        #expect(model.passwordError == nil)
        #expect(model.outcome == nil)
    }

    @Test func anAddressThatAlreadyHasAnAccountSaysSoAndSuggestsSigningIn() async {
        let transport = StubTransport()
        transport.answers = [failure(409, "CONFLICT", "already registered")]
        let model = makeModel(transport: transport)
        model.setMode(.register)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.formError == "That email address already has an account. Sign in instead.")
    }

    @Test func beingUnreachableIsNotReportedAsBadCredentials() async {
        let transport = StubTransport()
        transport.answers = [.failure(URLError(.notConnectedToInternet))]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.formError == "Can't reach Budj. Check your connection and try again.")
    }

    /// The refusals the app answers centrally are already taking the user off
    /// this screen; a second message underneath the fields would be noise.
    @Test func aCentrallyHandledRefusalLeavesNoMessageOnTheForm() async {
        let transport = StubTransport()
        transport.answers = [failure(426, "CLIENT_UPDATE_REQUIRED")]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.formError == nil)
        #expect(model.outcome == nil)
    }

    // MARK: - Modes

    @Test func switchingModeClearsWhateverTheLastAttemptSaid() async {
        let transport = StubTransport()
        transport.answers = [failure(401, "UNAUTHORIZED")]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "hunter22"
        await model.submit()
        #expect(model.formError != nil)

        model.setMode(.register)

        #expect(model.formError == nil)
        #expect(model.mode == .register)
    }

    @Test func nothingIsSubmittedUntilBothFieldsHaveSomethingInThem() {
        let model = makeModel(transport: StubTransport())
        #expect(model.canSubmit == false)

        model.email = "someone@example.com"
        #expect(model.canSubmit == false)

        model.password = "hunter22"
        #expect(model.canSubmit)
    }

    // MARK: - The model outlives the screen

    /// The defect this exists for. The flow builds one `EmailSignInModel` and
    /// keeps it, so a second successful sign-in on the same instance left
    /// `outcome` on the value it already held. The screen reports its result by
    /// *changing* that, so nothing observed the second success and the person
    /// stayed on the account-creation screen with their account already made.
    ///
    /// Asserted through an attempt that never reaches the network: if `submit`
    /// clears the outcome up front, an invalid address leaves `nil` behind. If
    /// it does not, last time's success is still standing.
    @Test func aStaleSuccessDoesNotSurviveALaterAttempt() async {
        let transport = StubTransport()
        transport.answers = [.json(200, Self.session)]
        let model = makeModel(transport: transport)

        model.email = "someone@example.com"
        model.password = "hunter22"
        await model.submit()
        #expect(model.outcome == .signedIn)

        model.email = "not-an-address"
        model.password = "hunter22"
        await model.submit()

        #expect(model.outcome == nil, "A stale success survived the next attempt")
    }

    /// The observable half of the same fix: a failed second attempt must not
    /// leave the previous success standing.
    @Test func aFailedAttemptClearsAnEarlierSuccess() async {
        let transport = StubTransport()
        transport.answers = [
            .json(200, Self.registration),
            failure(401, "UNAUTHORIZED"),
        ]
        let model = makeModel(transport: transport)
        model.setMode(.register)

        model.email = "first@example.com"
        model.password = "hunter22"
        await model.submit()
        #expect(model.outcome == .signedIn)

        model.setMode(.signIn)
        model.email = "second@example.com"
        model.password = "hunter22"
        await model.submit()

        #expect(model.outcome == nil, "A stale success survived a failed attempt")
    }

    // MARK: - Emptying the fields

    @Test func switchingModeEmptiesTheFields() {
        let model = makeModel(transport: StubTransport())
        model.email = "someone@example.com"
        model.password = "hunter22"

        model.setMode(.register)

        #expect(model.email.isEmpty)
        #expect(model.password.isEmpty)
        #expect(model.outcome == nil)
    }

    @Test func aSuccessfulSignInEmptiesTheFields() async {
        let transport = StubTransport()
        transport.answers = [.json(200, Self.session)]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.outcome == .signedIn)
        #expect(model.email.isEmpty, "An address was left in the field after signing in")
        #expect(model.password.isEmpty, "A password was left in the field after signing in")
    }

    /// The one case that keeps the address: the notice that follows names it.
    @Test func confirmationRequiredKeepsTheAddressButNotThePassword() async {
        let transport = StubTransport()
        transport.answers = [.json(200, ["session": NSNull(), "confirmationRequired": true])]
        let model = makeModel(transport: transport)
        model.setMode(.register)
        model.email = "someone@example.com"
        model.password = "hunter22"

        await model.submit()

        #expect(model.outcome == .confirmationRequired)
        #expect(model.email == "someone@example.com")
        #expect(model.password.isEmpty)
    }

    @Test func resettingEmptiesEverything() async {
        let transport = StubTransport()
        transport.answers = [.json(200, Self.session)]
        let model = makeModel(transport: transport)
        model.email = "someone@example.com"
        model.password = "hunter22"
        await model.submit()

        model.reset()

        #expect(model.email.isEmpty)
        #expect(model.password.isEmpty)
        #expect(model.outcome == nil)
    }

    // MARK: - Fixtures

    private static let session: [String: Any] = [
        "accessToken": "a",
        "refreshToken": "r",
        "tokenType": "bearer",
        "expiresIn": 3600,
        "expiresAt": "2026-08-18T05:33:37.000Z",
        "user": ["id": "u", "email": "someone@example.com", "emailConfirmed": true],
    ]

    private static let registration: [String: Any] = [
        "session": session,
        "confirmationRequired": false,
    ]
}
