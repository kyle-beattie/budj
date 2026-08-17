//
//  APIInterruption.swift
//  Budj
//

import Foundation

/// The three refusals that mean the same thing wherever they arrive, and so are
/// answered once at the top of the app rather than by every call site.
///
/// A screen may still catch these itself where it has something better to say —
/// the connect-bank step handles a lost entitlement in place — but nothing is
/// *required* to, and nothing can be missed by forgetting to.
nonisolated enum APIInterruption: Equatable, Sendable {
    /// The server no longer serves this build. Terminal: the update prompt.
    case updateRequired

    /// The subscription went away mid-session — a refund, an expiry — and the
    /// server has already revoked the bank connection with it.
    case entitlementLost

    /// The session is over and a refresh could not save it. Back to sign-in.
    case sessionEnded
}

/// Implemented once, by whatever owns the app's phase.
protocol APIInterruptionHandler: AnyObject {
    func handle(_ interruption: APIInterruption)
}
