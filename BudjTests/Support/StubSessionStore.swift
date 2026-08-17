//
//  StubSessionStore.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// A session held in memory, so the client can be tested without a Keychain.
@MainActor
final class StubSessionStore: SessionProviding {
    private(set) var current: BudjSession?
    private(set) var clearCount = 0

    init(current: BudjSession? = .stub()) {
        self.current = current
    }

    func replace(with session: BudjSession) {
        current = session
    }

    func clear() {
        current = nil
        clearCount += 1
    }
}

extension BudjSession {
    static func stub(
        accessToken: String = "access-1",
        refreshToken: String = "refresh-1"
    ) -> BudjSession {
        BudjSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: nil,
            user: BudjSession.User(id: "user-1", email: "someone@example.com", emailConfirmed: true)
        )
    }

    /// The same shape the server publishes, as JSON, so a refresh can be
    /// answered without hand-building a dictionary at each call site.
    static func stubJSON(accessToken: String, refreshToken: String) -> [String: Any] {
        [
            "accessToken": accessToken,
            "refreshToken": refreshToken,
            "tokenType": "bearer",
            "expiresIn": 3600,
            "expiresAt": NSNull(),
            "user": ["id": "user-1", "email": "someone@example.com", "emailConfirmed": true],
        ]
    }
}
