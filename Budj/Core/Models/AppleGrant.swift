//
//  AppleGrant.swift
//  Budj
//

import Foundation

/// What the server says about Apple's authorization code.
///
/// The route answers 200 even when the exchange with Apple fails, because by
/// then the caller is signed in and the code is single-use — there is nothing
/// to retry and nothing the app can do. `stored` is therefore information to
/// log, not a result to route on.
nonisolated struct AppleGrant: Decodable, Equatable, Sendable {
    let stored: Bool
    let reason: String?
}
