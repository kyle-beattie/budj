//
//  InMemoryStepRecord.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// The client-only step record, without the real defaults — which persist
/// between runs and would make a test's second run disagree with its first.
@MainActor
final class InMemoryStepRecord: ClientStepRecord {
    private(set) var offered: Set<ClientOnlyStep>

    init(offered: Set<ClientOnlyStep> = []) {
        self.offered = offered
    }

    func hasOffered(_ step: ClientOnlyStep) -> Bool {
        offered.contains(step)
    }

    func recordOffered(_ step: ClientOnlyStep) {
        offered.insert(step)
    }
}
