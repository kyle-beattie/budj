//
//  EmailConfirmationLink.swift
//  Budj
//

import Foundation

/// The redirect an address-confirmation email sends back to the app, read as
/// either a session or a refusal (D17).
///
/// Supabase answers the confirmation link with a redirect to
/// `budj://auth/confirm`, and its implicit flow puts the result in the URL's
/// **fragment** rather than its query:
///
/// ```
/// budj://auth/confirm#access_token=…&refresh_token=…&expires_in=3600&type=signup
/// budj://auth/confirm#error=access_denied&error_code=otp_expired&error_description=Email+link+…
/// ```
///
/// Both halves are read, because which one carries the values is Supabase's
/// choice and not ours, and a reader that only asks `URLComponents` for its
/// `queryItems` finds an empty link every time.
nonisolated enum EmailConfirmationLink: Equatable, Sendable {
    /// The address was confirmed and a session came back with it.
    case granted(refreshToken: String)

    /// The link was expired, already used, or otherwise refused. Not a failure
    /// of the app's, and not something a retry fixes.
    case refused(code: String?, message: String?)

    /// The host and path the app's own scheme reserves for this.
    static let host = "auth"
    static let path = "confirm"

    /// Returns `nil` for any URL that is not a confirmation redirect, so the
    /// caller can hand every incoming URL here and route on the answer. The
    /// bank callback will arrive on the same scheme.
    static func parse(_ url: URL) -> EmailConfirmationLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        guard components.host?.lowercased() == host else { return nil }
        guard components.path.trimmingCharacters(in: .init(charactersIn: "/")).lowercased() == path else {
            return nil
        }

        // The fragment wins where both carry the same name: it is where the
        // implicit flow puts the real answer.
        var values: [String: String] = [:]
        for (name, value) in fields(in: components.percentEncodedQuery) { values[name] = value }
        for (name, value) in fields(in: components.percentEncodedFragment) { values[name] = value }

        // A password-recovery link comes back on the same shape and carrying a
        // session of its own. Signing someone in and telling them their address
        // is confirmed is the wrong answer to "I forgot my password", so it is
        // refused here rather than mistaken for one. The server keeps the two
        // redirects apart; this is the second lock, one env var away from being
        // the only one. Only a `type` known to be wrong is rejected — an absent
        // one is ordinary and must not start failing on a shape change.
        if values["type"] == "recovery" { return nil }

        if let code = values["error_code"] ?? values["error"] {
            return .refused(code: code, message: values["error_description"])
        }
        if let refreshToken = values["refresh_token"], !refreshToken.isEmpty {
            return .granted(refreshToken: refreshToken)
        }
        // The right address, nothing usable on it. Treated as a refusal rather
        // than ignored, because the person is standing in front of the app
        // having just tapped the link and is owed an answer.
        return .refused(code: nil, message: nil)
    }

    // MARK: - Reading a form-encoded string

    private static func fields(in encoded: String?) -> [(String, String)] {
        guard let encoded, !encoded.isEmpty else { return [] }
        return encoded.split(separator: "&").compactMap { field in
            let halves = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard halves.count == 2,
                  let name = decode(String(halves[0])),
                  let value = decode(String(halves[1]))
            else { return nil }
            return (name, value)
        }
    }

    /// Form decoding, not URL decoding: Supabase writes spaces in
    /// `error_description` as `+`, which `removingPercentEncoding` leaves alone.
    private static func decode(_ value: String) -> String? {
        value.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
}
