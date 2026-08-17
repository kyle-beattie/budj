//
//  ClientBuild.swift
//  Budj
//

import Foundation

/// The app's build number, as the server names it: `CFBundleVersion` as an
/// integer.
///
/// The server treats a request without this as an unsupported client rather
/// than an exempt one, so there is one value, read from the bundle, and nothing
/// hand-written to fall out of step with the build.
nonisolated enum ClientBuild {
    /// The value sent in `x-client-build`.
    static let current: Int = read(from: Bundle.main)

    /// Reading is exposed for the test that asserts the bundle's value parses.
    /// A build number that is not an integer is a project misconfiguration, and
    /// it fails loudly in debug. In release it degrades to `0`, which the server
    /// refuses — an app that says "update me" is a better outcome than one that
    /// invents a build it does not have.
    static func read(from bundle: some InfoValues) -> Int {
        let raw = bundle.stringValue(forInfoKey: "CFBundleVersion")
        guard let raw, let value = Int(raw) else {
            assertionFailure("CFBundleVersion must be an integer; found \(raw ?? "nothing")")
            return 0
        }
        return value
    }
}
