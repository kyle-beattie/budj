//
//  InMemorySessionPersistence.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// A session store's backing, without the Keychain.
@MainActor
final class InMemorySessionPersistence: SessionPersistence {
    private(set) var stored: BudjSession?
    private(set) var storedRequiringBiometry = false
    private(set) var removeCount = 0

    /// Set to make `load()` fail the way a cancelled biometric prompt does.
    var loadError: (any Error)?

    init(stored: BudjSession? = nil) {
        self.stored = stored
    }

    func load() throws -> BudjSession? {
        if let loadError { throw loadError }
        return stored
    }

    func save(_ session: BudjSession, requiringBiometry: Bool) throws {
        stored = session
        storedRequiringBiometry = requiringBiometry
    }

    func remove() throws {
        stored = nil
        removeCount += 1
    }
}
