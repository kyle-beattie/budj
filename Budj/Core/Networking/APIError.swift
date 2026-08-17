//
//  APIError.swift
//  Budj
//

import Foundation

/// Every way a request can fail, as something the interface can switch over
/// rather than a message it has to read.
///
/// The first four are the server's published refusals, and each one leads
/// somewhere different. Collapsing any two of them sends someone to a screen
/// that cannot fix their problem.
nonisolated enum APIError: Error, Equatable {
    /// `426 CLIENT_UPDATE_REQUIRED` — this build is no longer served.
    case updateRequired

    /// `409 CLIENT_BUILD_BLOCKED` — this build may not move money, but the rest
    /// of the app keeps working. Nothing returns it yet.
    case buildBlocked

    /// `401 UNAUTHORIZED`, after a refresh attempt has already failed to save it.
    case unauthorized

    /// `402 SUBSCRIPTION_REQUIRED` — no active subscription. The purchase screen.
    case subscriptionRequired

    /// `403 PLAN_LIMIT_EXCEEDED` — subscribed, but at the plan's limit. An
    /// upgrade, not a purchase; they have already paid.
    case planLimitExceeded(PlanLimit?)

    /// A refusal the app does not have a case for. Carries the server's own code
    /// so it can be logged, but the app does not act on it.
    case server(status: Int, code: String, message: String)

    /// The request never got an answer.
    case network(URLError)

    /// An answer arrived in a shape the app does not understand — including a
    /// failure that did not match the published failure envelope.
    case decoding(String)
}
