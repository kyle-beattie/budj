//
//  InMemoryStepRecord.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// The client-only step record, without the real defaults — which persist
/// between runs and would make a test's second run disagree with its first.
///
/// It keys the way the real one does, so a test can tell a step recorded for one
/// user from the same step recorded for another.
@MainActor
final class InMemoryStepRecord: ClientStepRecord {
    private(set) var offered: Set<String>

    init(offered: Set<ClientOnlyStep> = [], userID: String? = nil) {
        self.offered = Set(offered.map { Self.key($0, userID) })
    }

    func hasOffered(_ step: ClientOnlyStep, userID: String?) -> Bool {
        offered.contains(Self.key(step, userID))
    }

    func recordOffered(_ step: ClientOnlyStep, userID: String?) {
        offered.insert(Self.key(step, userID))
    }

    private static func key(_ step: ClientOnlyStep, _ userID: String?) -> String {
        guard step.scope == .user, let userID, !userID.isEmpty else { return step.rawValue }
        return "\(step.rawValue).\(userID)"
    }
}
