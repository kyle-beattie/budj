//
//  KeychainStoreTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

/// The real Keychain, on its own service so it cannot collide with the app's.
@MainActor
struct KeychainStoreTests {
    private let store = KeychainStore(service: "nz.app.Budj.tests")

    @Test func anItemSurvivesAWriteAndARead() throws {
        let account = "roundtrip-\(UUID().uuidString)"
        defer { try? store.delete(account) }

        try store.write(Data("hello".utf8), to: account, requiringBiometry: false)

        #expect(try store.read(account) == Data("hello".utf8))
    }

    @Test func aMissingItemReadsAsNothingRatherThanFailing() throws {
        #expect(try store.read("absent-\(UUID().uuidString)") == nil)
    }

    /// Delete-then-add, not update: writing twice must leave one item, not fail
    /// with a duplicate.
    @Test func writingTwiceReplacesRatherThanDuplicates() throws {
        let account = "replace-\(UUID().uuidString)"
        defer { try? store.delete(account) }

        try store.write(Data("first".utf8), to: account, requiringBiometry: false)
        try store.write(Data("second".utf8), to: account, requiringBiometry: false)

        #expect(try store.read(account) == Data("second".utf8))
    }

    @Test func deletingSomethingAbsentIsNotAnError() throws {
        try store.delete("absent-\(UUID().uuidString)")
    }

    @Test func aDeletedItemIsGone() throws {
        let account = "delete-\(UUID().uuidString)"
        try store.write(Data("x".utf8), to: account, requiringBiometry: false)

        try store.delete(account)

        #expect(try store.read(account) == nil)
    }

    /// The session is encoded and decoded by the same coders the API uses, so a
    /// shape the server sends is a shape that survives a relaunch.
    @Test func aSessionSurvivesTheRoundTripThroughPersistence() throws {
        let keychain = KeychainStore(service: "nz.app.Budj.tests.session-\(UUID().uuidString)")
        let persistence = KeychainSessionPersistence(keychain: keychain)
        defer { try? persistence.remove() }

        try persistence.save(.stub(accessToken: "access-9"), requiringBiometry: false)

        #expect(try persistence.load() == BudjSession.stub(accessToken: "access-9"))
    }
}
