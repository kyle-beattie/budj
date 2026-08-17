//
//  StubBundle.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// Build-time values, without a build.
struct StubBundle: InfoValues {
    let values: [String: String]

    func stringValue(forInfoKey key: String) -> String? {
        values[key]
    }
}
