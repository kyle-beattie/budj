//
//  SupabaseIdentity.swift
//  Budj
//

import Foundation

/// The one call the app makes to Supabase directly: exchanging a provider's
/// identity token for a session.
///
/// It lives in `Core/Session` rather than `Core/Networking` because it is the
/// one place `BudjAPI`'s rules do not apply — no bearer token, no
/// `X-Client-Build` — for the simple reason that it is not our server (D16).
/// Everything else, including refreshing the session this produces, goes
/// through the Budj server.
///
/// GoTrue's wire shape is not the Budj contract's: snake_case keys, a Unix
/// `expires_at`, and `email_confirmed_at` as a timestamp where the contract has
/// a boolean. The translation is done here, once, so that everything downstream
/// of sign-in reads `BudjSession` and cannot tell how the user got here.
final class SupabaseIdentity {
    /// The providers Supabase is asked about, spelled the way GoTrue spells
    /// them.
    nonisolated enum Provider: String, Sendable {
        case apple
        case google
    }

    private let configuration: SupabaseConfiguration
    private let transport: any HTTPTransport

    init(configuration: SupabaseConfiguration, transport: any HTTPTransport = URLSessionTransport()) {
        self.configuration = configuration
        self.transport = transport
    }

    /// Exchanges an identity token for a session.
    ///
    /// `fullName` is forwarded when the provider supplied it, which for Apple
    /// is the first authorisation and no other. It is never synthesised.
    func signIn(
        provider: Provider,
        identityToken: String,
        fullName: String? = nil
    ) async throws -> BudjSession {
        var components = URLComponents(
            url: configuration.baseURL.appending(path: "/auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "id_token")]

        guard let url = components?.url else {
            throw APIError.decoding("Could not build the Supabase token URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // GoTrue wants the publishable key both ways round.
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try Self.encoder.encode(
            TokenRequest(
                provider: provider.rawValue,
                idToken: identityToken,
                data: fullName.map { NameMetadata(fullName: $0) }
            )
        )

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let urlError as URLError {
            throw APIError.network(urlError)
        }

        guard (200..<300).contains(response.statusCode) else {
            // Supabase's failure shape is not the Budj server's, and nothing
            // here should be mistaken for one of the published refusals — least
            // of all `unauthorized`, which would announce that a session ended
            // when the truth is that one was never established.
            throw APIError.server(
                status: response.statusCode,
                code: "SUPABASE_SIGN_IN_FAILED",
                message: String(data: data, encoding: .utf8) ?? ""
            )
        }

        do {
            return try Self.decoder.decode(TokenResponse.self, from: data).session
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    // MARK: - Coding

    /// GoTrue's own coders. Separate from `BudjAPI`'s on purpose: this is a
    /// different service with different conventions, and sharing a decoder is
    /// how one service's shape change breaks the other.
    ///
    /// Timestamps are read as strings rather than dates because GoTrue emits
    /// fractional seconds inconsistently, which `.iso8601` refuses outright —
    /// and nothing here needs the value, only whether it is there.
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Wire types

    private nonisolated struct TokenRequest: Encodable {
        let provider: String
        let idToken: String
        let data: NameMetadata?

        enum CodingKeys: String, CodingKey {
            case provider
            case idToken = "id_token"
            case data
        }
    }

    private nonisolated struct NameMetadata: Encodable {
        let fullName: String

        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
        }
    }

    private nonisolated struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let tokenType: String
        let expiresIn: Int
        let expiresAt: TimeInterval?
        let user: User

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
            case user
        }

        struct User: Decodable {
            let id: String
            let email: String?
            let emailConfirmedAt: String?

            enum CodingKeys: String, CodingKey {
                case id
                case email
                case emailConfirmedAt = "email_confirmed_at"
            }
        }

        var session: BudjSession {
            BudjSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                tokenType: tokenType,
                expiresIn: expiresIn,
                expiresAt: expiresAt.map { Date(timeIntervalSince1970: $0) },
                user: BudjSession.User(
                    id: user.id,
                    email: user.email,
                    emailConfirmed: user.emailConfirmedAt != nil
                )
            )
        }
    }
}
