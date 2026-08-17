//
//  BudjSession.swift
//  Budj
//

import Foundation

/// A signed-in session, in the shape the server publishes.
///
/// The same shape arrives from password sign-in, from registration, and from a
/// refresh, and it is what the provider flows are translated into — so
/// everything downstream of sign-in reads one type and cannot tell how the user
/// got here.
nonisolated struct BudjSession: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let expiresAt: Date?
    let user: User

    nonisolated struct User: Codable, Equatable, Sendable {
        let id: String
        let email: String?
        let emailConfirmed: Bool
    }
}
