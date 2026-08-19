//
//  BiometricPreference.swift
//  Budj
//

import Foundation

/// Whether the stored session is kept behind biometry.
///
/// **This has to outlive the launch.** The access control lives on the Keychain
/// item, but the app decides on every write whether to reapply it, and a value
/// that resets to `false` when the process starts means the first write after a
/// relaunch — a token refresh, which happens within seconds — silently rewrites
/// the session without protection. Face ID is then never asked for again, and
/// nothing anywhere says so.
///
/// A protocol so `SessionStore` can be tested without touching the real
/// defaults, which persist between test runs.
protocol BiometricPreferenceStore {
    var requiresBiometry: Bool { get }
    func setRequiresBiometry(_ required: Bool)
}

/// The real one.
///
/// User defaults rather than the Keychain: this is a boolean about a setting,
/// not a credential. The key is named for what it turns on and never for what it
/// protects, so task 7.4's assertion about credential-shaped key names keeps
/// holding.
///
/// Device-scoped rather than per user, because the item it describes is: the
/// session in the Keychain is one item, and whoever is signed in is behind
/// biometry or is not. Signing out deliberately leaves it standing — it is a
/// statement about this device, and the opt-in step asks each new user anyway.
struct DefaultsBiometricPreference: BiometricPreferenceStore {
    private static let key = "nz.app.Budj.session.unlocksWithBiometry"

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var requiresBiometry: Bool {
        defaults.bool(forKey: Self.key)
    }

    func setRequiresBiometry(_ required: Bool) {
        defaults.set(required, forKey: Self.key)
    }
}
