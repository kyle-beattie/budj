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

    /// The direct Supabase call, or `nil` when the build carries no Supabase
    /// configuration. Provider sign-in is offered only when this exists, rather
    /// than showing a button that cannot work.
    private let identity: SupabaseIdentity?

    init(api: BudjAPI, session: SessionStore, identity: SupabaseIdentity? = nil) {
        self.api = api
        self.session = session
        self.identity = identity
    }

    var offersProviderSignIn: Bool { identity != nil }

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

    /// Turns what an address-confirmation link came back with into a session
    /// (D17).
    ///
    /// The link's refresh token is exchanged rather than its access token
    /// adopted, so the session arrives on the same route and in the same shape
    /// as every other one — nothing downstream can tell a just-confirmed address
    /// from an ordinary sign-in, and the app never decodes a JWT to find out who
    /// the user is.
    func completeEmailConfirmation(refreshToken: String) async throws {
        let established: BudjSession = try await api.send(
            .exchange(refreshToken: refreshToken),
            as: BudjSession.self
        )
        session.replace(with: established)
    }

    // MARK: - Sign in with Apple

    /// The two artifacts Apple hands back go to two different places, and
    /// neither substitutes for the other (D7):
    ///
    /// ```
    ///   identityToken ─────► Supabase      (never touches the Budj server)
    ///   authorizationCode ─► the Budj server (never touches Supabase)
    /// ```
    ///
    /// Getting this backwards produces an app that works perfectly and an
    /// account that can never be properly deleted, discovered in
    /// `add-account-deletion` months from now. `AppleSignInTests` is the
    /// assertion that stops it.
    ///
    /// The code is posted *after* the session exists, because that route is
    /// authenticated. A failure posting it does not fail sign-in: the user is
    /// already signed in, the code is single-use and cannot be retried, and
    /// refusing them entry over a deletion concern they will not meet for
    /// months would be the wrong trade.
    @discardableResult
    func signInWithApple(_ credential: AppleCredential) async throws -> Bool {
        guard let identity else {
            throw APIError.decoding("This build carries no Supabase configuration")
        }

        let established = try await identity.signIn(
            provider: .apple,
            identityToken: credential.identityToken,
            // Present on the first authorisation and never again. Absent is
            // ordinary, and never a reason to invent one from the address.
            fullName: credential.fullName
        )
        session.replace(with: established)

        return await postAppleGrant(credential.authorizationCode)
    }

    /// Best-effort, and the return value is for tests and logging rather than
    /// for routing. Returns whether the server stored the grant.
    private func postAppleGrant(_ authorizationCode: String) async -> Bool {
        do {
            let outcome: AppleGrant = try await api.send(
                .appleGrant(authorizationCode: authorizationCode),
                as: AppleGrant.self
            )
            if !outcome.stored {
                // The server answers 200 even when Apple refuses the exchange,
                // because the caller is signed in and there is nothing to retry.
                print("[identity] Apple grant not stored: \(outcome.reason ?? "no reason given")")
            }
            return outcome.stored
        } catch {
            print("[identity] Apple grant post failed: \(error)")
            return false
        }
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
