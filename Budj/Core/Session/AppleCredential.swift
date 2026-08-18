//
//  AppleCredential.swift
//  Budj
//

import AuthenticationServices
import Foundation

/// What Sign in with Apple hands back, reduced to the four things the app does
/// something with.
///
/// It exists so the sign-in path can be tested. `ASAuthorizationAppleIDCredential`
/// cannot be constructed outside of a real authorisation, which would put the
/// one assertion that matters most here — that the identity token and the
/// authorization code go to *different places* — out of reach of the test suite.
nonisolated struct AppleCredential: Equatable, Sendable {
    /// Goes to Supabase, and never to the Budj server.
    let identityToken: String

    /// Goes to the Budj server, and never to Supabase. Single-use, expires in
    /// about five minutes, and is supplied only during authorisation — there is
    /// no later opportunity to collect it.
    let authorizationCode: String

    /// Apple supplies this on the very first authorisation and never again.
    /// `nil` on every subsequent sign-in, which is ordinary and not a failure.
    let fullName: String?

    /// Carried for completeness. Deliberately never used to derive a name.
    let email: String?
}

nonisolated extension AppleCredential {
    /// Maps Apple's credential, or `nil` when either load-bearing artifact is
    /// missing — which is a failed sign-in rather than a partial one.
    init?(_ credential: ASAuthorizationAppleIDCredential) {
        guard
            let identityData = credential.identityToken,
            let identityToken = String(data: identityData, encoding: .utf8),
            let codeData = credential.authorizationCode,
            let authorizationCode = String(data: codeData, encoding: .utf8)
        else { return nil }

        self.init(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            fullName: Self.name(from: credential.fullName),
            email: credential.email
        )
    }

    /// Apple's name components, joined the way the user's locale writes them.
    ///
    /// There is deliberately no fallback to the email address. A private-relay
    /// address is a random string at `privaterelay.appleid.com`, and greeting
    /// somebody by it is worse than not greeting them at all — the server's
    /// identity spec forbids it outright.
    static func name(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatted = PersonNameComponentsFormatter.localizedString(
            from: components,
            style: .default
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        return formatted.isEmpty ? nil : formatted
    }
}
