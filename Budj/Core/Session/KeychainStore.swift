//
//  KeychainStore.swift
//  Budj
//

import Foundation
import Security

/// The Keychain, as three operations over one service.
///
/// Everything written here is `ThisDeviceOnly`: a session restored from an
/// iCloud backup onto a second device is not a session this app wants to
/// resume. Biometric protection is optional per write, because declining it is
/// a supported configuration rather than a degraded one — the item is simply
/// written without the access control and the app still resumes.
struct KeychainStore {
    let service: String

    init(service: String = "nz.app.Budj.session") {
        self.service = service
    }

    // MARK: - Reading

    /// Reads an item, prompting for biometry if the item was written with it.
    ///
    /// A missing item is `nil` rather than an error: not being signed in is an
    /// ordinary state, not a failure.
    func read(_ account: String) throws -> Data? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        case errSecUserCanceled, errSecAuthFailed, errSecInteractionNotAllowed:
            throw KeychainError.notUnlocked
        default:
            throw KeychainError.unhandled(status: status)
        }
    }

    // MARK: - Writing

    /// Writes an item, replacing whatever was there.
    ///
    /// Delete-then-add rather than update, because the access control cannot be
    /// changed by an update — turning biometry on for an existing session would
    /// silently do nothing.
    func write(_ data: Data, to account: String, requiringBiometry: Bool) throws {
        try delete(account)

        var attributes = baseQuery(for: account)
        attributes[kSecValueData as String] = data

        if requiringBiometry {
            var error: Unmanaged<CFError>?
            // `.biometryCurrentSet` rather than `.biometryAny`: enrolling a new
            // face or fingerprint invalidates the item and the user signs in
            // again. That failure is legible; silently extending trust to a
            // biometric nobody enrolled for this is not.
            let control = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryCurrentSet,
                &error
            )
            guard let control else {
                throw KeychainError.unhandled(status: errSecParam)
            }
            attributes[kSecAttrAccessControl as String] = control
        } else {
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status: status)
        }
    }

    // MARK: - Deleting

    func delete(_ account: String) throws {
        let status = SecItemDelete(baseQuery(for: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status: status)
        }
    }

    // MARK: - Query

    private func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
