//
//  SessionDecodingTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct SessionDecodingTests {

    /// The exact shape the server returns from sign-in, registration and
    /// refresh, captured from a live response.
    @Test func aSessionFromTheServerDecodes() throws {
        let json = """
        {
          "accessToken": "a",
          "refreshToken": "r",
          "tokenType": "bearer",
          "expiresIn": 3600,
          "expiresAt": "2026-08-18T05:33:37.000Z",
          "user": { "id": "u", "email": "someone@example.com", "emailConfirmed": true }
        }
        """.data(using: .utf8)!

        let session = try BudjAPI.decoder.decode(BudjSession.self, from: json)
        #expect(session.accessToken == "a")
        #expect(session.expiresAt != nil)
    }
}
