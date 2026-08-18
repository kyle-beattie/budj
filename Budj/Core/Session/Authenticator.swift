//
//  Authenticator.swift
//  Budj
//

import Foundation
import Observation

/// Everything that starts or ends a session.
///
/// It is the one place that turns a successful authentication into a stored
/// session, so no screen has to remember to persist what it just obtained. The
/// provider flows will join it here; email and password came first because they
/// need nothing but the server.
///
/// `@Observable` for the sake of `@Environment(Authenticator.self)` rather than
/// because it holds state worth observing — it holds none.
@Observable
final class Authenticator {
    private let api: BudjAPI
    private let session: SessionStore

    init(api: BudjAPI, session: SessionStore) {
        self.api = api
        self.session = session
    }

    // MARK: - Email and password

    func signIn(email: String, password: String) async throws {
        let established: BudjSession = try await api.send(
            .signIn(email: email, password: password),
            as: BudjSession.self
        )
        session.replace(with: established)
    }

    /// Creates an account. A project with email confirmation switched on issues
    /// no session until the address is confirmed, so the caller must handle
    /// being registered and not signed in.
    func register(email: String, password: String, displayName: String? = nil) async throws -> Registration {
        let registration: Registration = try await api.send(
            .signUp(email: email, password: password, displayName: displayName),
            as: Registration.self
        )
        if let established = registration.session {
            session.replace(with: established)
        }
        return registration
    }

    // MARK: - Ending it

    /// Ends the session everywhere it can, and locally regardless.
    ///
    /// The server call is best-effort on purpose: someone signing out on a
    /// train has still signed out, and leaving them signed in because the
    /// request failed would be the wrong answer to the wrong question. The
    /// tokens expire on their own.
    func signOut() async {
        _ = try? await api.send(.signOut)
        session.clear()
    }

    // MARK: - Passwords

    func requestPasswordReset(email: String) async throws {
        _ = try await api.send(.requestPasswordReset(email: email))
    }
}
