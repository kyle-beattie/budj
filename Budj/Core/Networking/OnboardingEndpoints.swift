//
//  OnboardingEndpoints.swift
//  Budj
//

import Foundation

/// The routes onboarding uses, named once so no path string is written twice.
nonisolated extension Endpoint {
    static var onboardingStatus: Endpoint {
        .get("/api/onboarding/status")
    }

    /// Apple's authorization code — not its identity token, which goes to
    /// Supabase and never here. See `AppleSignIn`.
    static func appleGrant(authorizationCode: String) -> Endpoint {
        .post("/api/auth/apple/grant", body: AppleGrantRequest(authorizationCode: authorizationCode))
    }

    private struct AppleGrantRequest: Encodable {
        let authorizationCode: String
    }
}
