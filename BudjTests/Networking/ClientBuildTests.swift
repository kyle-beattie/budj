//
//  ClientBuildTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

struct ClientBuildTests {

    /// The one that catches a real project misconfiguration: a `CFBundleVersion`
    /// of `1.0` parses as nothing, and every request the app makes is then
    /// refused as an unidentifiable client.
    @Test func theBundlesBuildNumberIsAnInteger() {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        #expect(raw.flatMap(Int.init) != nil, "CFBundleVersion must be an integer, found \(raw ?? "nothing")")
    }

    @Test func theBuildNumberComesFromTheBundle() {
        #expect(ClientBuild.read(from: StubBundle(values: ["CFBundleVersion": "412"])) == 412)
    }
}
