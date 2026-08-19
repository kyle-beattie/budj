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
    private(set) var loadCount = 0

    /// Set to make `load()` fail the way a cancelled biometric prompt does.
    var loadError: (any Error)?

    /// Set to make the next `save()` fail the way a refused Keychain write
    /// does. Consumed, so a test can fail one write and let the next succeed.
    var failNextSave = false

    init(stored: BudjSession? = nil) {
        self.stored = stored
    }

    func load() throws -> BudjSession? {
        loadCount += 1
        if let loadError { throw loadError }
        return stored
    }

    func save(_ session: BudjSession, requiringBiometry: Bool) throws {
        if failNextSave {
            failNextSave = false
            throw KeychainError.unhandled(status: errSecIO)
        }
        stored = session
        storedRequiringBiometry = requiringBiometry
    }

    func remove() throws {
        stored = nil
        removeCount += 1
    }
}
