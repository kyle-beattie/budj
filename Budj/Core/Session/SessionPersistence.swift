//
//  SessionPersistence.swift
//  Budj
//

import Foundation

/// Where a session is kept between launches.
///
/// A protocol so `SessionStore`'s behaviour can be tested without the Keychain,
/// which needs an entitlement, a device state, and a person's face.
protocol SessionPersistence {
    func load() throws -> BudjSession?
    func save(_ session: BudjSession, requiringBiometry: Bool) throws
    func remove() throws
}

/// The real one.
struct KeychainSessionPersistence: SessionPersistence {
    private static let account = "session"

    let keychain: KeychainStore

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    func load() throws -> BudjSession? {
        guard let data = try keychain.read(Self.account) else { return nil }
        // A session that no longer decodes — a shape change between builds — is
        // not a crash and not a half-session. It is nobody signed in.
        return try? BudjAPI.decoder.decode(BudjSession.self, from: data)
    }

    func save(_ session: BudjSession, requiringBiometry: Bool) throws {
        let data = try BudjAPI.encoder.encode(session)
        try keychain.write(data, to: Self.account, requiringBiometry: requiringBiometry)
    }

    func remove() throws {
        try keychain.delete(Self.account)
    }
}
