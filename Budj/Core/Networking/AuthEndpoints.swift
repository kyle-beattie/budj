//
//  AuthEndpoints.swift
//  Budj
//

import Foundation

/// The email and password routes, which are the fallback for people who do not
/// use a provider.
///
/// These go to the Budj server rather than to Supabase — the server owns
/// password sign-in, registration and refresh, which is most of why the app
/// carries no Supabase SDK.
nonisolated extension Endpoint {
    static func signIn(email: String, password: String) -> Endpoint {
        .post(
            "/api/auth/sign-in",
            body: CredentialsRequest(email: email, password: password),
            requiresAuthorization: false
        )
    }

    static func signUp(email: String, password: String, displayName: String?) -> Endpoint {
        .post(
            "/api/auth/sign-up",
            body: RegistrationRequest(email: email, password: password, displayName: displayName),
            requiresAuthorization: false
        )
    }

    /// Revokes the tokens server-side. Answers `204` with no body.
    static var signOut: Endpoint {
        .post("/api/auth/sign-out")
    }

    /// Always accepted, whether or not the address is registered — the response
    /// must not be usable to find out who has an account.
    static func requestPasswordReset(email: String) -> Endpoint {
        .post("/api/auth/password/reset", body: EmailRequest(email: email), requiresAuthorization: false)
    }

    private struct CredentialsRequest: Encodable {
        let email: String
        let password: String
    }

    private struct RegistrationRequest: Encodable {
        let email: String
        let password: String
        let displayName: String?
    }

    private struct EmailRequest: Encodable {
        let email: String
    }
}
