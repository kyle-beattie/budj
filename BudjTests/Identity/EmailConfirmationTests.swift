//
//  EmailConfirmationTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

/// Task 10.14. The address-confirmation link (D17).
///
/// The parse is where this goes wrong quietly: Supabase's implicit flow puts the
/// session in the URL *fragment*, and a reader that asks `URLComponents` for its
/// `queryItems` gets an empty answer and reports a perfectly good link as
/// broken. Half of these assertions exist for that one mistake.
@MainActor
struct EmailConfirmationTests {

    // MARK: - Fixtures

    private static let base = URL(string: "https://api.example.test")!

    private static let sessionBody: [String: Any] = [
        "accessToken": "access-after-confirming",
        "refreshToken": "refresh-after-confirming",
        "tokenType": "bearer",
        "expiresIn": 3600,
        "expiresAt": "2026-08-19T00:00:00Z",
        "user": ["id": "51f1e6a0-0000-4000-8000-000000000000", "email": "someone@example.com", "emailConfirmed": true],
    ]

    private func makeModel(
        transport: StubTransport
    ) -> (EmailConfirmationModel, SessionStore) {
        let session = SessionStore(persistence: InMemorySessionPersistence())
        let api = BudjAPI(
            configuration: APIConfiguration(baseURL: Self.base),
            transport: transport,
            session: session,
            build: 412
        )
        let authenticator = Authenticator(api: api, session: session)
        return (EmailConfirmationModel(authenticator: authenticator), session)
    }

    private func url(_ string: String) -> URL {
        URL(string: string)!
    }

    // MARK: - Parsing

    @Test("The session is read from the fragment, which is where Supabase puts it")
    func readsTheFragment() {
        let link = EmailConfirmationLink.parse(
            url("budj://auth/confirm#access_token=eyJhbGciOiJIUzI1NiJ9.body.sig&expires_at=1787000000&expires_in=3600&refresh_token=grant-abc123&token_type=bearer&type=signup")
        )
        #expect(link == .granted(refreshToken: "grant-abc123"))
    }

    @Test("A query-carried refusal is read too, because which half it arrives on is not ours to choose")
    func readsTheQuery() {
        let link = EmailConfirmationLink.parse(
            url("budj://auth/confirm?error=access_denied&error_code=otp_expired")
        )
        #expect(link == .refused(code: "otp_expired", message: nil))
    }

    @Test("An expired link is a refusal rather than a session")
    func expiredLink() {
        let link = EmailConfirmationLink.parse(
            url("budj://auth/confirm#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired")
        )
        #expect(link == .refused(code: "otp_expired", message: "Email link is invalid or has expired"))
    }

    @Test("A URL on another path is not ours", arguments: [
        "budj://bank/callback?code=abc",
        "budj://auth/reset#refresh_token=grant-abc123",
        "https://budj.app/auth/confirm#refresh_token=grant-abc123",
    ])
    func ignoresOtherURLs(_ string: String) {
        // The scheme's other callbacks arrive here too — task 12.2's among them —
        // and answering `nil` is what lets one `onOpenURL` serve all of them.
        #expect(EmailConfirmationLink.parse(url(string)) == nil)
    }

    @Test("A password-recovery link is not mistaken for a confirmation")
    func recoveryIsNotConfirmation() {
        // It carries a session just like a confirmation does, and acting on it
        // would sign someone in saying their address was confirmed when what
        // they asked for was a new password.
        #expect(EmailConfirmationLink.parse(
            url("budj://auth/confirm#refresh_token=grant-abc123&type=recovery")
        ) == nil)
    }

    @Test("A link with no type is still a confirmation, so a shape change does not break it")
    func absentTypeIsOrdinary() {
        #expect(EmailConfirmationLink.parse(
            url("budj://auth/confirm#refresh_token=grant-abc123")
        ) == .granted(refreshToken: "grant-abc123"))
    }

    @Test("A confirmation URL carrying nothing usable is still answered")
    func emptyLink() {
        #expect(EmailConfirmationLink.parse(url("budj://auth/confirm")) == .refused(code: nil, message: nil))
    }

    // MARK: - The model

    @Test("Registering without a session opens the sheet naming the address")
    func awaitingConfirmation() {
        let (model, _) = makeModel(transport: StubTransport())
        #expect(!model.isPresented)

        model.awaitConfirmation(of: "someone@example.com")

        #expect(model.isPresented)
        #expect(model.phase == .waiting(email: "someone@example.com"))
        #expect(!model.didConfirm)
    }

    @Test("A valid link is exchanged for a session and the sheet says so")
    func confirmsAndSignsIn() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, Self.sessionBody)]
        let (model, session) = makeModel(transport: transport)
        model.awaitConfirmation(of: "someone@example.com")

        #expect(model.open(url("budj://auth/confirm#refresh_token=grant-abc123&type=signup")))
        try await untilSettled(model)

        #expect(model.phase == .confirmed)
        #expect(model.didConfirm)
        // The session came back from the server's own route, so it is the same
        // shape as any other — nothing downstream can tell how it was obtained.
        #expect(session.current?.accessToken == "access-after-confirming")
        #expect(session.current?.user.emailConfirmed == true)
    }

    @Test("The refresh token is what is exchanged, not the access token beside it")
    func exchangesTheRefreshToken() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, Self.sessionBody)]
        let (model, _) = makeModel(transport: transport)

        _ = model.open(url("budj://auth/confirm#access_token=ACCESS-FROM-LINK&refresh_token=grant-abc123"))
        try await untilSettled(model)

        let request = try #require(transport.requests(toPathContaining: "/api/auth/refresh").first)
        let body = try #require(request.httpBody.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        #expect(body["refreshToken"] as? String == "grant-abc123")
        // The link's access token is not a credential this app presents to
        // anything; sending it would be adopting a session the server never
        // issued to us.
        #expect(String(data: request.httpBody!, encoding: .utf8)?.contains("ACCESS-FROM-LINK") == false)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("A refused exchange leaves the sheet with something to do rather than a session")
    func refusedExchange() async throws {
        let transport = StubTransport()
        transport.answers = [.json(401, ["error": ["code": "unauthorized", "message": "Refresh token is invalid"]])]
        let (model, session) = makeModel(transport: transport)

        _ = model.open(url("budj://auth/confirm#refresh_token=already-used"))
        try await untilSettled(model)

        #expect(!model.didConfirm)
        #expect(session.current == nil)
        guard case let .refused(message) = model.phase else {
            Issue.record("Expected a refusal, got \(String(describing: model.phase))")
            return
        }
        #expect(message.contains("Sign in"))
    }

    @Test("An expired link never reaches the server")
    func expiredLinkIsNotExchanged() {
        let transport = StubTransport()
        let (model, _) = makeModel(transport: transport)

        #expect(model.open(url("budj://auth/confirm#error=access_denied&error_code=otp_expired")))

        #expect(transport.requests.isEmpty)
        guard case let .refused(message) = model.phase else {
            Issue.record("Expected a refusal, got \(String(describing: model.phase))")
            return
        }
        #expect(message.contains("expired"))
    }

    @Test("A URL that is not ours opens no sheet")
    func unrelatedURL() {
        let (model, _) = makeModel(transport: StubTransport())
        #expect(!model.open(url("budj://bank/callback?code=abc")))
        #expect(!model.isPresented)
    }

    @Test("Dismissing forgets the phase, so the next registration starts clean")
    func dismissing() {
        let (model, _) = makeModel(transport: StubTransport())
        model.awaitConfirmation(of: "someone@example.com")
        model.dismiss()
        #expect(!model.isPresented)
        #expect(model.phase == nil)
    }

    // MARK: - Helpers

    /// The exchange runs in a task the model owns, so the assertions wait for it
    /// to leave `.exchanging` rather than for a fixed interval.
    private func untilSettled(_ model: EmailConfirmationModel, within: Duration = .seconds(2)) async throws {
        let deadline = ContinuousClock.now.advanced(by: within)
        while model.phase == .exchanging, ContinuousClock.now < deadline {
            await Task.yield()
        }
        #expect(model.phase != .exchanging, "The exchange never finished")
    }
}
