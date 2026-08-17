//
//  PlanLimit.swift
//  Budj
//

import Foundation

/// What the server sends with `PLAN_LIMIT_EXCEEDED`: enough to say "you are on
/// 2 of 2" without asking a second question.
nonisolated struct PlanLimit: Decodable, Equatable, Sendable {
    let limit: Int
    let current: Int
    let planCode: String
}
