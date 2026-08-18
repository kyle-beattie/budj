//
//  AuthenticatorTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct AuthenticatorTests {

    private func makeAuthenticator(
        transport: StubTransport,
        session: SessionStore
    ) -> Authenticator {
        let api = BudjAPI(
            configuration: APIConfiguration(baseURL: URL(string: "https://api.example.test")!),
            transport: transport,
            session: session,
            build: 412
        )
        return Authenticator(api: api, session: session)
    }

    private func makeSession() -> SessionStore {
        SessionStore(persistence: InMemorySessionPersistence())
    }

    // MARK: - Signing in

    @Test func signingInStoresTheSession() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, BudjSession.stubJSON(accessToken: "access-9", refreshToken: "refresh-9"))]
        let session = makeSession()

        try await makeAuthenticator(transport: transport, session: session)
            .signIn(email: "someone@example.com", password: "hunter22")

        #expect(session.current?.accessToken == "access-9")
        #expect(transport.requests[0].url?.path() == "/api/auth/sign-in")
    }

    @Test func signingInSendsNoBearerTokenAndStillSendsTheBuild() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, BudjSession.stubJSON(accessToken: "a", refreshToken: "r"))]

        try await makeAuthenticator(transport: transport, session: makeSession())
            .signIn(email: "someone@example.com", password: "hunter22")

        #expect(transport.requests[0].value(forHTTPHeaderField: "Authorization") == nil)
        #expect(transport.buildHeaders == ["412"])
    }

    @Test func badCredentialsLeaveNoSession() async throws {
        let transport = StubTransport()
        transport.answers = [.json(401, ["error": ["code": "UNAUTHORIZED", "message": "Invalid email or password"]])]
        let session = makeSession()

        await #expect(throws: APIError.unauthorized) {
            try await makeAuthenticator(transport: transport, session: session)
                .signIn(email: "someone@example.com", password: "wrong")
        }

        #expect(session.current == nil)
    }

    // MARK: - Registering

    @Test func registeringWithAnImmediateSessionSignsTheUserIn() async throws {
        let transport = StubTransport()
        transport.answers = [.json(201, [
            "session": BudjSession.stubJSON(accessToken: "access-new", refreshToken: "refresh-new"),
            "confirmationRequired": false,
        ])]
        let session = makeSession()

        let registration = try await makeAuthenticator(transport: transport, session: session)
            .register(email: "someone@example.com", password: "hunter22")

        #expect(registration.confirmationRequired == false)
        #expect(session.current?.accessToken == "access-new")
    }

    /// The case most likely to be mistaken for a failure: the account was
    /// created perfectly, and there is no session because the address has to be
    /// confirmed first.
    @Test func registeringWithoutASessionIsNotAFailure() async throws {
        let transport = StubTransport()
        transport.answers = [.json(201, ["session": NSNull(), "confirmationRequired": true])]
        let session = makeSession()

        let registration = try await makeAuthenticator(transport: transport, session: session)
            .register(email: "someone@example.com", password: "hunter22")

        #expect(registration.confirmationRequired)
        #expect(registration.session == nil)
        #expect(session.current == nil)
    }

    // MARK: - Signing out

    @Test func signingOutTellsTheServerAndClearsTheSession() async throws {
        let transport = StubTransport()
        transport.answers = [.status(204, body: Data())]
        let session = makeSession()
        session.replace(with: .stub())

        await makeAuthenticator(transport: transport, session: session).signOut()

        #expect(transport.requests[0].url?.path() == "/api/auth/sign-out")
        #expect(transport.requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
        #expect(session.current == nil)
    }

    /// Someone signing out on a train has still signed out. Leaving them signed
    /// in because a request failed answers the wrong question.
    @Test func signingOutClearsTheSessionEvenWhenTheServerCannotBeReached() async throws {
        let transport = StubTransport()
        transport.answers = [.failure(URLError(.notConnectedToInternet))]
        let session = makeSession()
        session.replace(with: .stub())

        await makeAuthenticator(transport: transport, session: session).signOut()

        #expect(session.current == nil)
    }

    @Test func signingOutClearsTheSessionEvenWhenTheServerRefuses() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, ["error": ["code": "UNAUTHORIZED", "message": "no"]]),
            .json(401, ["error": ["code": "UNAUTHORIZED", "message": "no"]]),
        ]
        let session = makeSession()
        session.replace(with: .stub())

        await makeAuthenticator(transport: transport, session: session).signOut()

        #expect(session.current == nil)
    }
}
