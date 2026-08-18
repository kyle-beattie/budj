//
//  AppleSignInTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

/// Task 10.4, and the highest-value test in the change.
///
/// Apple hands back two artifacts that look alike and go to opposite places.
/// Swapping them yields an app that signs people in perfectly and an account
/// that can never be properly deleted — a defect with no symptom until
/// `add-account-deletion`, months later. Nothing about using the product would
/// reveal it. These assertions are the only thing that would.
@MainActor
struct AppleSignInTests {

    // MARK: - Fixtures

    private static let budjBase = URL(string: "https://api.example.test")!
    private static let supabaseBase = URL(string: "https://supabase.example.test")!

    private static let identityToken = "IDENTITY-TOKEN-eyJhbGciOiJub25lIn0"
    private static let authorizationCode = "AUTHORIZATION-CODE-c8a1f2"

    private func credential(fullName: String? = nil, email: String? = nil) -> AppleCredential {
        AppleCredential(
            identityToken: Self.identityToken,
            authorizationCode: Self.authorizationCode,
            fullName: fullName,
            email: email
        )
    }

    /// One transport for both services, so a test can see everything the app
    /// sent and to whom — which is the only way to assert that an artifact did
    /// *not* reach somewhere.
    private func makeAuthenticator(
        transport: StubTransport,
        session: SessionStore? = nil
    ) -> (Authenticator, SessionStore) {
        let session = session ?? SessionStore(persistence: InMemorySessionPersistence())
        let api = BudjAPI(
            configuration: APIConfiguration(baseURL: Self.budjBase),
            transport: transport,
            session: session,
            build: 412
        )
        let identity = SupabaseIdentity(
            configuration: SupabaseConfiguration(baseURL: Self.supabaseBase, anonKey: "anon-key"),
            transport: transport
        )
        return (Authenticator(api: api, session: session, identity: identity), session)
    }

    private var goTrueSession: [String: Any] {
        [
            "access_token": "access-from-supabase",
            "refresh_token": "refresh-from-supabase",
            "token_type": "bearer",
            "expires_in": 3600,
            "expires_at": 1_800_000_000,
            "user": [
                "id": "user-1",
                "email": "someone@privaterelay.appleid.com",
                "email_confirmed_at": "2026-08-18T03:00:00.123456Z",
            ],
        ]
    }

    private func body(of request: URLRequest) -> [String: Any] {
        guard
            let data = request.httpBody,
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return object
    }

    // MARK: - The assertion this file exists for

    @Test func eachArtifactGoesToItsOwnPlace() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential())

        let toSupabase = try #require(
            transport.requests.first { $0.url?.host() == Self.supabaseBase.host() }
        )
        let toBudj = try #require(
            transport.requests.first { $0.url?.host() == Self.budjBase.host() }
        )

        // The identity token goes to Supabase, and the code does not.
        #expect(body(of: toSupabase)["id_token"] as? String == Self.identityToken)
        #expect(body(of: toSupabase)["provider"] as? String == "apple")

        // The authorization code goes to our server, and the identity token
        // does not.
        #expect(body(of: toBudj)["authorizationCode"] as? String == Self.authorizationCode)
        #expect(toBudj.url?.path().contains("/api/auth/apple/grant") == true)
    }

    /// The negative half, stated separately because it is the half that would
    /// still pass if the two values happened to be equal in a fixture.
    @Test func noIdentityTokenEverReachesTheBudjServer() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential())

        for request in transport.requests where request.url?.host() == Self.budjBase.host() {
            let rendered = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            #expect(!rendered.contains(Self.identityToken), "An identity token reached the Budj server")
        }
    }

    @Test func noAuthorizationCodeEverReachesSupabase() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential())

        for request in transport.requests where request.url?.host() == Self.supabaseBase.host() {
            let rendered = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            #expect(!rendered.contains(Self.authorizationCode), "An authorization code reached Supabase")
        }
    }

    // MARK: - Ordering

    /// The grant route is authenticated, so the code cannot be posted until the
    /// session exists.
    @Test func theCodeIsPostedAfterTheSessionExists() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential())

        #expect(transport.requests.count == 2)
        #expect(transport.requests[0].url?.host() == Self.supabaseBase.host())
        let grant = transport.requests[1]
        #expect(grant.value(forHTTPHeaderField: "Authorization") == "Bearer access-from-supabase")
    }

    // MARK: - The session

    @Test func supabasesShapeBecomesAnOrdinarySession() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, session) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential())

        #expect(session.current?.accessToken == "access-from-supabase")
        #expect(session.current?.refreshToken == "refresh-from-supabase")
        // GoTrue reports a timestamp where the contract has a boolean, and
        // emits fractional seconds that `.iso8601` refuses.
        #expect(session.current?.user.emailConfirmed == true)
        #expect(session.current?.expiresIn == 3600)
    }

    // MARK: - A failed exchange does not fail sign-in

    @Test func aRefusedGrantLeavesTheUserSignedIn() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(500, ["error": ["code": "INTERNAL_ERROR", "message": "no"]]),
        ]
        let (authenticator, session) = makeAuthenticator(transport: transport)

        let stored = try await authenticator.signInWithApple(credential())

        #expect(stored == false)
        #expect(session.current != nil, "A failed grant must not undo the sign-in")
    }

    @Test func aGrantTheServerCouldNotStoreIsNotAFailedSignIn() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": false, "reason": "apple_refused"]),
        ]
        let (authenticator, session) = makeAuthenticator(transport: transport)

        let stored = try await authenticator.signInWithApple(credential())

        #expect(stored == false)
        #expect(session.current != nil)
    }

    /// The other direction: Supabase refusing *is* a failed sign-in, and must
    /// not leave a half-session behind.
    @Test func aRefusedIdentityTokenLeavesNoSession() async {
        let transport = StubTransport()
        transport.answers = [.json(401, ["error": "invalid token"])]
        let (authenticator, session) = makeAuthenticator(transport: transport)

        await #expect(throws: (any Error).self) {
            try await authenticator.signInWithApple(credential())
        }
        #expect(session.current == nil)
        // Nothing was posted to our server on the strength of a failed sign-in.
        #expect(transport.requests.allSatisfy { $0.url?.host() == Self.supabaseBase.host() })
    }

    // MARK: - Names

    @Test func aNameIsForwardedWhenAppleSuppliesOne() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential(fullName: "Aroha Ngata"))

        let toSupabase = try #require(
            transport.requests.first { $0.url?.host() == Self.supabaseBase.host() }
        )
        let data = body(of: toSupabase)["data"] as? [String: Any]
        #expect(data?["full_name"] as? String == "Aroha Ngata")
    }

    /// Apple supplies a name only on the very first authorisation. Every sign-in
    /// after it carries none, and that is ordinary.
    @Test func noNameIsSentWhenAppleSuppliesNone() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)

        try await authenticator.signInWithApple(credential(email: "someone@example.com"))

        let toSupabase = try #require(
            transport.requests.first { $0.url?.host() == Self.supabaseBase.host() }
        )
        #expect(body(of: toSupabase)["data"] == nil)
    }

    /// The case the spec calls out by name. A private-relay address is a random
    /// string; greeting somebody by it is worse than not greeting them at all.
    @Test func aPrivateRelayAddressIsNeverTurnedIntoAName() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(200, goTrueSession),
            .json(200, ["stored": true]),
        ]
        let (authenticator, _) = makeAuthenticator(transport: transport)
        let relay = "x9k2m4p7q1@privaterelay.appleid.com"

        try await authenticator.signInWithApple(credential(email: relay))

        let toSupabase = try #require(
            transport.requests.first { $0.url?.host() == Self.supabaseBase.host() }
        )
        let rendered = String(data: toSupabase.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body(of: toSupabase)["data"] == nil)
        #expect(!rendered.contains("privaterelay"), "A relay address was sent as profile data")
        #expect(!rendered.contains("x9k2m4p7q1"))
    }

    /// Empty components are not a name either — Apple returns a populated but
    /// blank `PersonNameComponents` more often than you would like.
    @Test func blankNameComponentsAreNotAName() {
        var components = PersonNameComponents()
        components.givenName = "  "

        #expect(AppleCredential.name(from: components) == nil)
        #expect(AppleCredential.name(from: nil) == nil)
    }

    @Test func nameComponentsAreJoined() throws {
        var components = PersonNameComponents()
        components.givenName = "Aroha"
        components.familyName = "Ngata"

        let name = try #require(AppleCredential.name(from: components))
        #expect(name.contains("Aroha"))
        #expect(name.contains("Ngata"))
    }
}
