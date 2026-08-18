//
//  BudjAPI.swift
//  Budj
//

import Foundation

/// The one way the app talks to its server.
///
/// Two rules hold this together. Every request carries the build number and,
/// where the route needs one, the bearer token — applied here, so there is no
/// code path that can forget either. And the three refusals that mean the same
/// thing wherever they arrive are answered once, in `interruptionHandler`,
/// rather than at each call site.
final class BudjAPI {
    private let configuration: APIConfiguration
    private let transport: any HTTPTransport
    private let session: any SessionProviding
    private let build: Int

    /// Set once, by whatever owns the app's phase.
    weak var interruptionHandler: (any APIInterruptionHandler)?

    /// In flight while a refresh is happening, so several requests that all
    /// expire at once await one refresh rather than each starting another.
    private var refresh: Task<BudjSession, any Error>?

    /// Set when a refresh has been refused, so a session that is definitively
    /// over is not asked about again.
    private var refreshIsSpent = false

    init(
        configuration: APIConfiguration = .current,
        transport: any HTTPTransport = URLSessionTransport(),
        session: any SessionProviding,
        build: Int = ClientBuild.current
    ) {
        self.configuration = configuration
        self.transport = transport
        self.session = session
        self.build = build
    }

    // MARK: - Sending

    /// Send a request and decode its response.
    func send<Response: Decodable>(
        _ endpoint: Endpoint,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await data(for: endpoint)
        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    /// Send a request whose response body the caller does not read.
    @discardableResult
    func send(_ endpoint: Endpoint) async throws -> Data {
        try await data(for: endpoint)
    }

    /// Send a request and decode the items of a collection envelope.
    func send<Element: Decodable>(
        _ endpoint: Endpoint,
        collectionOf type: Element.Type
    ) async throws -> CollectionEnvelope<Element> {
        try await send(endpoint, as: CollectionEnvelope<Element>.self)
    }

    // MARK: - The one path every request takes

    private func data(for endpoint: Endpoint) async throws -> Data {
        do {
            return try await perform(endpoint, allowingRefresh: true)
        } catch let error as APIError {
            notify(about: error, carriedAuthorization: endpoint.requiresAuthorization)
            throw error
        }
    }

    private func perform(_ endpoint: Endpoint, allowingRefresh: Bool) async throws -> Data {
        let request = try makeRequest(for: endpoint)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        } catch {
            throw APIError.network(URLError(.unknown))
        }

        guard (200..<300).contains(response.statusCode) else {
            let failure = decodeFailure(from: data, status: response.statusCode)

            // An access token expires on a much shorter timer than the session
            // it belongs to. One refresh, then the original request again —
            // treating expiry as rejection would sign people out mid-use.
            if failure == .unauthorized,
               endpoint.requiresAuthorization,
               allowingRefresh {
                try await refreshSession()
                return try await perform(endpoint, allowingRefresh: false)
            }

            throw failure
        }

        return data
    }

    // MARK: - Building

    /// The single place a request is constructed. The build number is applied
    /// here rather than on the session's additional headers so that a test can
    /// see it: a header added by `URLSession` itself is invisible to everything
    /// that could assert it is there.
    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: configuration.baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        )
        if !endpoint.query.isEmpty {
            components?.queryItems = endpoint.query
        }
        guard let url = components?.url else {
            throw APIError.decoding("Could not build a URL for \(endpoint.path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue(String(build), forHTTPHeaderField: ClientBuildHeader.name)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let encodeBody = endpoint.encodeBody {
            do {
                request.httpBody = try encodeBody(Self.encoder)
            } catch {
                throw APIError.decoding(String(describing: error))
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if endpoint.requiresAuthorization, let token = session.current?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Refreshing

    /// One refresh, shared. A caller that arrives while one is running awaits
    /// the same task rather than spending a second refresh token on the same
    /// expiry.
    private func refreshSession() async throws {
        // A session the server has already refused is not asked about again.
        if refreshIsSpent { throw APIError.unauthorized }

        let task: Task<BudjSession, any Error>
        let isOwner: Bool

        if let refresh {
            task = refresh
            isOwner = false
        } else {
            guard let refreshToken = session.current?.refreshToken else {
                endSession()
                throw APIError.unauthorized
            }
            task = makeRefreshTask(refreshToken: refreshToken)
            refresh = task
            isOwner = true
        }

        defer { if isOwner { refresh = nil } }

        do {
            _ = try await task.value
        } catch let error as APIError {
            // Only a refusal ends the session. A network failure leaves it
            // intact, because a token that was never presented cannot have been
            // rejected.
            if case .network = error { throw error }
            refreshIsSpent = true
            endSession()
            throw APIError.unauthorized
        }
    }

    /// The new session is written by the task itself, so that a request which
    /// merely awaited someone else's refresh is guaranteed to see the new token
    /// when it retries.
    private func makeRefreshTask(refreshToken: String) -> Task<BudjSession, any Error> {
        Task {
            var request = URLRequest(url: configuration.baseURL.appending(path: "/api/auth/refresh"))
            request.httpMethod = Endpoint.Method.post.rawValue
            request.setValue(String(build), forHTTPHeaderField: ClientBuildHeader.name)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody = try Self.encoder.encode(RefreshRequest(refreshToken: refreshToken))

            let data: Data
            let response: HTTPURLResponse
            do {
                (data, response) = try await transport.send(request)
            } catch let urlError as URLError {
                throw APIError.network(urlError)
            }

            guard (200..<300).contains(response.statusCode) else {
                throw APIError.unauthorized
            }

            let refreshed: BudjSession
            do {
                refreshed = try Self.decoder.decode(BudjSession.self, from: data)
            } catch {
                throw APIError.decoding(String(describing: error))
            }

            session.replace(with: refreshed)
            return refreshed
        }
    }

    private func endSession() {
        session.clear()
    }

    // MARK: - Failures

    private func decodeFailure(from data: Data, status: Int) -> APIError {
        guard let envelope = try? Self.decoder.decode(FailureEnvelope.self, from: data) else {
            // A failure that does not match the published envelope is not
            // quietly treated as anything else.
            return .decoding("A \(status) response did not match the failure envelope")
        }

        let failure = envelope.error
        switch ServerErrorCode(rawValue: failure.code) {
        case .unauthorized: return .unauthorized
        case .subscriptionRequired: return .subscriptionRequired
        case .planLimitExceeded: return .planLimitExceeded(failure.planLimit)
        case .clientUpdateRequired: return .updateRequired
        case .clientBuildBlocked: return .buildBlocked
        case nil: return .server(status: status, code: failure.code, message: failure.message)
        }
    }

    private func notify(about error: APIError, carriedAuthorization: Bool) {
        switch error {
        case .updateRequired:
            interruptionHandler?.handle(.updateRequired)
        case .subscriptionRequired:
            interruptionHandler?.handle(.entitlementLost)
        case .unauthorized where carriedAuthorization:
            interruptionHandler?.handle(.sessionEnded)
        default:
            break
        }
        // A 401 from sign-in means the password was wrong, not that a session
        // ended — there was no session. Announcing one would bounce someone out
        // of the screen they are trying to sign in on.
    }

    // MARK: - Coding

    /// Configured once. The contract publishes camelCase keys and ISO-8601
    /// timestamps, so nothing is restated per model.
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private struct RefreshRequest: Encodable {
        let refreshToken: String
    }
}
