//
//  BudjAPITests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct BudjAPITests {

    // MARK: - Fixtures

    private static let configuration = APIConfiguration(baseURL: URL(string: "https://api.example.test")!)

    private func makeAPI(
        transport: StubTransport,
        session: StubSessionStore? = nil,
        handler: RecordingInterruptionHandler? = nil,
        build: Int = 412
    ) -> BudjAPI {
        let api = BudjAPI(
            configuration: Self.configuration,
            transport: transport,
            session: session ?? StubSessionStore(),
            build: build
        )
        api.interruptionHandler = handler
        return api
    }

    private func failure(_ code: String, _ message: String = "no", details: Any? = nil) -> [String: Any] {
        var error: [String: Any] = ["code": code, "message": message]
        if let details { error["details"] = details }
        return ["error": error]
    }

    private var status: [String: Any] {
        [
            "step": "billing",
            "subscriptionActive": false,
            "planCode": NSNull(),
            "bankConnected": false,
            "pushRegistered": false,
        ]
    }

    // MARK: - The build number

    @Test func everyRequestCarriesTheBuildNumber() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, status)]
        let api = makeAPI(transport: transport)

        _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)

        #expect(transport.buildHeaders == ["412"])
    }

    @Test func theBuildNumberIsCarriedByRoutesThatNeedNoToken() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, status)]
        let api = makeAPI(transport: transport, session: StubSessionStore(current: nil))

        _ = try await api.send(.get("/api/billing/plans", requiresAuthorization: false), as: OnboardingStatus.self)

        #expect(transport.buildHeaders == ["412"])
        #expect(transport.requests[0].value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func authorizedRoutesCarryTheBearerToken() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, status)]
        let api = makeAPI(transport: transport)

        _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)

        #expect(transport.requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
    }

    // MARK: - Error mapping

    @Test(arguments: [
        (402, "SUBSCRIPTION_REQUIRED", APIError.subscriptionRequired),
        (426, "CLIENT_UPDATE_REQUIRED", APIError.updateRequired),
        (409, "CLIENT_BUILD_BLOCKED", APIError.buildBlocked),
    ])
    func distinctCausesProduceDistinctCases(status code: Int, serverCode: String, expected: APIError) async throws {
        let transport = StubTransport()
        transport.answers = [.json(code, failure(serverCode))]
        let api = makeAPI(transport: transport)

        await #expect(throws: expected) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }
    }

    @Test func planLimitCarriesWhatTheUpgradeScreenNeeds() async throws {
        let transport = StubTransport()
        transport.answers = [.json(403, failure(
            "PLAN_LIMIT_EXCEEDED",
            details: ["limit": 2, "current": 2, "planCode": "starter"]
        ))]
        let api = makeAPI(transport: transport)

        await #expect(throws: APIError.planLimitExceeded(PlanLimit(limit: 2, current: 2, planCode: "starter"))) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }
    }

    @Test func anUnknownCodeDegradesToAServerFailure() async throws {
        let transport = StubTransport()
        transport.answers = [.json(500, failure("TEAPOT_ON_FIRE", "something new"))]
        let api = makeAPI(transport: transport)

        await #expect(throws: APIError.server(status: 500, code: "TEAPOT_ON_FIRE", message: "something new")) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }
    }

    /// Case is part of the identifier. A code in the wrong casing is not the
    /// code, and must not quietly send someone to the paywall.
    @Test func aCodeInTheWrongCasingDoesNotMatch() async throws {
        let transport = StubTransport()
        transport.answers = [.json(402, failure("subscription_required"))]
        let api = makeAPI(transport: transport)

        await #expect(throws: APIError.server(status: 402, code: "subscription_required", message: "no")) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }
    }

    @Test func aFailureOutsideTheEnvelopeIsADecodingFailure() async throws {
        let transport = StubTransport()
        transport.answers = [.status(503, body: Data("<html>gateway</html>".utf8))]
        let api = makeAPI(transport: transport)

        do {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
            Issue.record("A response outside the envelope must not be treated as anything else")
        } catch let error as APIError {
            guard case .decoding = error else {
                Issue.record("Expected a decoding failure, got \(error)")
                return
            }
        }
    }

    @Test func aFailedRequestIsNotMistakenForAnOutage() async throws {
        let transport = StubTransport()
        transport.answers = [.failure(URLError(.notConnectedToInternet))]
        let api = makeAPI(transport: transport)

        await #expect(throws: APIError.network(URLError(.notConnectedToInternet))) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }
    }

    // MARK: - Refreshing

    @Test func anExpiredTokenIsRefreshedAndTheRequestReissuedOnce() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .json(200, BudjSession.stubJSON(accessToken: "access-2", refreshToken: "refresh-2")),
            .json(200, status),
        ]
        let session = StubSessionStore()
        let api = makeAPI(transport: transport, session: session)

        let result = try await api.send(.onboardingStatus, as: OnboardingStatus.self)

        #expect(result.step == .billing)
        #expect(transport.requests.count == 3)
        #expect(transport.requests(toPathContaining: "/api/auth/refresh").count == 1)
        // The reissued request carries the new token, not the expired one.
        #expect(transport.requests[2].value(forHTTPHeaderField: "Authorization") == "Bearer access-2")
        #expect(session.current?.accessToken == "access-2")
        #expect(session.clearCount == 0)
    }

    @Test func theRefreshItselfCarriesTheBuildNumber() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .json(200, BudjSession.stubJSON(accessToken: "access-2", refreshToken: "refresh-2")),
            .json(200, status),
        ]
        let api = makeAPI(transport: transport)

        _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)

        #expect(transport.buildHeaders == ["412", "412", "412"])
    }

    @Test func aRejectedRefreshTokenEndsTheSession() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .json(401, failure("UNAUTHORIZED")),
        ]
        let session = StubSessionStore()
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, session: session, handler: handler)

        await #expect(throws: APIError.unauthorized) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }

        #expect(session.current == nil)
        #expect(handler.interruptions == [.sessionEnded])
    }

    @Test func noFurtherRefreshIsAttemptedForASpentSession() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .json(401, failure("UNAUTHORIZED")),
            .json(401, failure("UNAUTHORIZED")),
        ]
        let api = makeAPI(transport: transport)

        await #expect(throws: APIError.unauthorized) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }
        await #expect(throws: APIError.unauthorized) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }

        // Two attempts on the original route, one refresh, and nothing after
        // the refresh was refused.
        #expect(transport.requests(toPathContaining: "/api/auth/refresh").count == 1)
        #expect(transport.requests.count == 3)
    }

    /// A token that was never presented cannot have been rejected. Losing the
    /// network must not sign anyone out.
    @Test func aRefreshThatCannotReachTheServerKeepsTheSession() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .failure(URLError(.timedOut)),
        ]
        let session = StubSessionStore()
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, session: session, handler: handler)

        await #expect(throws: APIError.network(URLError(.timedOut))) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }

        #expect(session.current?.accessToken == "access-1")
        #expect(session.clearCount == 0)
        #expect(handler.interruptions.isEmpty)
    }

    @Test func concurrentFailuresShareOneRefresh() async throws {
        let transport = StubTransport()
        transport.answers = [
            .json(401, failure("UNAUTHORIZED")),
            .json(401, failure("UNAUTHORIZED")),
            .json(200, BudjSession.stubJSON(accessToken: "access-2", refreshToken: "refresh-2")),
            .json(200, status),
            .json(200, status),
        ]
        let api = makeAPI(transport: transport)

        async let first = api.send(.onboardingStatus, as: OnboardingStatus.self)
        async let second = api.send(.onboardingStatus, as: OnboardingStatus.self)
        _ = try await (first, second)

        #expect(transport.requests(toPathContaining: "/api/auth/refresh").count == 1)
        // Both retries used the refreshed token, including the one that merely
        // waited for someone else's refresh.
        let retried = transport.requests.suffix(2).map { $0.value(forHTTPHeaderField: "Authorization") }
        #expect(retried == ["Bearer access-2", "Bearer access-2"])
    }

    @Test func aRequestWithNoSessionAtAllDoesNotAttemptARefresh() async throws {
        let transport = StubTransport()
        transport.answers = [.json(401, failure("UNAUTHORIZED"))]
        let session = StubSessionStore(current: nil)
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, session: session, handler: handler)

        await #expect(throws: APIError.unauthorized) {
            _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
        }

        #expect(transport.requests.count == 1)
        #expect(handler.interruptions == [.sessionEnded])
    }

    // MARK: - Central handling

    @Test func anUnsupportedBuildIsAnnouncedWhicheverCallProducedIt() async throws {
        let transport = StubTransport()
        transport.answers = [.json(426, failure("CLIENT_UPDATE_REQUIRED"))]
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, handler: handler)

        _ = try? await api.send(.appleGrant(authorizationCode: "code"))

        #expect(handler.interruptions == [.updateRequired])
    }

    @Test func lostEntitlementIsAnnouncedWhicheverCallProducedIt() async throws {
        let transport = StubTransport()
        transport.answers = [.json(402, failure("SUBSCRIPTION_REQUIRED"))]
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, handler: handler)

        _ = try? await api.send(.get("/api/accounts"), as: OnboardingStatus.self)

        #expect(handler.interruptions == [.entitlementLost])
    }

    /// A 401 from sign-in means the password was wrong, not that a session
    /// ended — there was no session. Announcing one would bounce someone out of
    /// the screen they are trying to sign in on.
    @Test func aRefusedSignInDoesNotAnnounceThatTheSessionEnded() async throws {
        let transport = StubTransport()
        transport.answers = [.json(401, failure("UNAUTHORIZED", "Invalid email or password"))]
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, session: StubSessionStore(current: nil), handler: handler)

        await #expect(throws: APIError.unauthorized) {
            _ = try await api.send(
                .signIn(email: "someone@example.com", password: "wrong"),
                as: BudjSession.self
            )
        }

        #expect(handler.interruptions.isEmpty)
    }

    @Test func anOrdinaryFailureInterruptsNothing() async throws {
        let transport = StubTransport()
        transport.answers = [.json(500, failure("INTERNAL_ERROR"))]
        let handler = RecordingInterruptionHandler()
        let api = makeAPI(transport: transport, handler: handler)

        _ = try? await api.send(.onboardingStatus, as: OnboardingStatus.self)

        #expect(handler.interruptions.isEmpty)
    }

    // MARK: - Envelopes

    @Test func aCollectionIsReadWithItsPaginationMetadata() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, [
            "data": [status, status],
            "meta": ["total": 9, "limit": 2, "offset": 0],
        ])]
        let api = makeAPI(transport: transport)

        let page = try await api.send(.get("/api/accounts"), collectionOf: OnboardingStatus.self)

        #expect(page.data.count == 2)
        #expect(page.meta == Pagination(total: 9, limit: 2, offset: 0))
    }

    @Test func aCollectionWithoutPaginationStillDecodes() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, ["data": [status]])]
        let api = makeAPI(transport: transport)

        let page = try await api.send(.get("/api/billing/plans"), collectionOf: OnboardingStatus.self)

        #expect(page.data.count == 1)
        #expect(page.meta == nil)
    }

    // MARK: - The base address

    @Test func pathsAreJoinedToTheConfiguredAddress() async throws {
        let transport = StubTransport()
        transport.answers = [.json(200, status)]
        let api = makeAPI(transport: transport)

        _ = try await api.send(.onboardingStatus, as: OnboardingStatus.self)

        #expect(transport.requests[0].url?.absoluteString == "https://api.example.test/api/onboarding/status")
    }

    @Test func aTrailingSlashOnTheBaseAddressDoesNotDoubleUp() throws {
        let bundle = StubBundle(values: ["BudjAPIBaseURL": "https://api.example.test/"])
        let configuration = APIConfiguration.read(from: bundle)

        #expect(configuration.baseURL.absoluteString == "https://api.example.test")
    }
}
