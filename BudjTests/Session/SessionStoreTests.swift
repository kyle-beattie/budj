//
//  SessionStoreTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct SessionStoreTests {

    @Test func restoringReadsAStoredSession() {
        let persistence = InMemorySessionPersistence(stored: .stub())
        let store = SessionStore(persistence: persistence)

        #expect(store.restore())
        #expect(store.current?.accessToken == "access-1")
        #expect(store.isLocked == false)
    }

    @Test func restoringWithNothingStoredIsNotAFailure() {
        let store = SessionStore(persistence: InMemorySessionPersistence())

        #expect(store.restore() == false)
        #expect(store.current == nil)
        #expect(store.isLocked == false)
    }

    /// A cancelled or failed biometric prompt is a definite "sign in again",
    /// not an error the caller has to interpret and not a locked state.
    @Test func anItemThatCannotBeUnlockedLeavesNoSession() {
        let persistence = InMemorySessionPersistence(stored: .stub())
        persistence.loadError = KeychainError.notUnlocked
        let store = SessionStore(persistence: persistence)

        #expect(store.restore() == false)
        #expect(store.current == nil)
        #expect(store.isLocked)
    }

    @Test func replacingPersistsTheNewSession() {
        let persistence = InMemorySessionPersistence()
        let store = SessionStore(persistence: persistence)

        store.replace(with: .stub(accessToken: "access-2", refreshToken: "refresh-2"))

        #expect(persistence.stored?.accessToken == "access-2")
        #expect(store.current?.refreshToken == "refresh-2")
    }

    @Test func clearingRemovesTheStoredItem() {
        let persistence = InMemorySessionPersistence(stored: .stub())
        let store = SessionStore(persistence: persistence)
        store.restore()

        store.clear()

        #expect(store.current == nil)
        #expect(persistence.stored == nil)
        #expect(persistence.removeCount == 1)
    }

    /// Declining biometrics is a supported configuration, not a degraded one:
    /// the session is still written and a relaunch still resumes.
    @Test func decliningBiometricsStillPersistsTheSession() {
        let persistence = InMemorySessionPersistence()
        let store = SessionStore(persistence: persistence, preference: InMemoryBiometricPreference())

        store.replace(with: .stub())

        #expect(persistence.stored != nil)
        #expect(persistence.storedRequiringBiometry == false)
    }

    @Test func turningBiometryOnRewritesTheStoredSession() {
        let persistence = InMemorySessionPersistence()
        let store = SessionStore(persistence: persistence)
        store.replace(with: .stub())

        store.setRequiresBiometry(true)

        #expect(persistence.storedRequiringBiometry)
        #expect(persistence.stored?.accessToken == "access-1")
    }
}
