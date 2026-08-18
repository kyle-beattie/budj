//
//  SessionSecrecyTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

/// Task 7.4: assert that nothing sensitive reaches user defaults, rather than
/// believing it. Nothing in the app writes there today, and this is what would
/// notice the day something does.
@MainActor
struct SessionSecrecyTests {

    @Test func signingInWritesNoTokenToUserDefaults() throws {
        let secrets = ["access-secret-\(UUID().uuidString)", "refresh-secret-\(UUID().uuidString)"]
        let store = SessionStore(persistence: InMemorySessionPersistence())

        store.replace(with: .stub(accessToken: secrets[0], refreshToken: secrets[1]))

        let defaults = UserDefaults.standard.dictionaryRepresentation()
        for (key, value) in defaults {
            let rendered = "\(key) \(value)"
            for secret in secrets {
                #expect(!rendered.contains(secret), "A token reached user defaults under \(key)")
            }
        }
    }

    @Test func noDefaultsKeyIsNamedForACredential() {
        let suspicious = ["token", "password", "secret", "refresh", "credential"]
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
            // Keys the system puts there itself are not ours to police.
            .filter { !$0.hasPrefix("Apple") && !$0.hasPrefix("NS") && !$0.hasPrefix("com.apple") }

        for key in keys {
            let lowered = key.lowercased()
            for word in suspicious {
                #expect(!lowered.contains(word), "A defaults key named \(key) looks like it holds a credential")
            }
        }
    }
}
