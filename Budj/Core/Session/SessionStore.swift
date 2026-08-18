//
//  SessionStore.swift
//  Budj
//

import Foundation
import Observation

/// The current session, and the only thing that writes it to disk.
///
/// It is the app's single answer to "is anyone signed in", so `BudjAPI` reads
/// its token from here and the root view routes on it, and neither keeps a copy
/// that could disagree.
@Observable
final class SessionStore: SessionProviding {
    private(set) var current: BudjSession?

    /// Set when the stored session exists but could not be unlocked — a
    /// cancelled biometric prompt, or an enrolment that changed since it was
    /// written. The launch gate shows sign-in rather than a locked state.
    private(set) var isLocked = false

    /// Whether the session is written behind biometry. Set by the biometric
    /// opt-in step; every write after that honours it.
    private(set) var requiresBiometry: Bool

    private let persistence: any SessionPersistence

    init(
        persistence: any SessionPersistence = KeychainSessionPersistence(),
        requiresBiometry: Bool = false
    ) {
        self.persistence = persistence
        self.requiresBiometry = requiresBiometry
    }

    // MARK: - Restoring

    /// Reads the stored session, if there is one. Returns whether a session is
    /// now held, so a caller can route without reading state back out.
    @discardableResult
    func restore() -> Bool {
        do {
            current = try persistence.load()
            isLocked = false
        } catch KeychainError.notUnlocked {
            // The item is there and this person did not open it. Nothing to
            // retry — the answer is to sign in again.
            current = nil
            isLocked = true
        } catch {
            current = nil
            isLocked = false
        }
        return current != nil
    }

    // MARK: - SessionProviding

    func replace(with session: BudjSession) {
        current = session
        isLocked = false
        try? persistence.save(session, requiringBiometry: requiresBiometry)
    }

    /// Forgets the session locally. This is the end of the session as far as the
    /// app is concerned, whether or not the server was successfully told.
    func clear() {
        current = nil
        isLocked = false
        try? persistence.remove()
    }

    // MARK: - Biometry

    /// Rewrites the stored session with or without the biometric access
    /// control. Turning it on cannot be done by updating the existing item, so
    /// this rewrites it.
    func setRequiresBiometry(_ required: Bool) {
        requiresBiometry = required
        guard let current else { return }
        try? persistence.save(current, requiringBiometry: required)
    }
}
