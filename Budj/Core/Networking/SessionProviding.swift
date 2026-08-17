//
//  SessionProviding.swift
//  Budj
//

import Foundation

/// What the API client needs of the session: read it, replace it after a
/// refresh, and clear it when the server stops accepting it.
///
/// A protocol rather than the store itself, so the client can be tested without
/// a Keychain and so `Core/Networking` does not depend on `Core/Session`.
protocol SessionProviding: AnyObject {
    var current: BudjSession? { get }
    func replace(with session: BudjSession)
    func clear()
}
