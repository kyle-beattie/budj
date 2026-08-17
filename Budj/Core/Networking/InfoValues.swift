//
//  InfoValues.swift
//  Budj
//

import Foundation

/// The build-time values the app reads out of its own bundle.
///
/// A protocol so that what is read — the build number, the server's address —
/// can be tested against a value that is not this process's bundle. `Bundle`
/// itself cannot be stood in for.
nonisolated protocol InfoValues {
    func stringValue(forInfoKey key: String) -> String?
}

nonisolated extension Bundle: InfoValues {
    func stringValue(forInfoKey key: String) -> String? {
        object(forInfoDictionaryKey: key) as? String
    }
}
