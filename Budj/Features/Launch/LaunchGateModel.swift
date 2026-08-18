//
//  LaunchGateModel.swift
//  Budj
//

import Foundation

/// The work the launch screen is held over: read the session, ask the server
/// where this person is, and resolve one destination.
///
/// It holds no state and renders nothing, so every outcome in D6 — including
/// the two nobody exercises by hand — is reachable from a test with a stubbed
/// transport.
struct LaunchGateModel {
    private let api: BudjAPI
    private let session: SessionStore

    init(api: BudjAPI, session: SessionStore) {
        self.api = api
        self.session = session
    }

    func resolve() async -> LaunchDestination {
        // Reading the item *is* the biometric prompt: an item written with the
        // access control raises it inside `SecItemCopyMatching`, and
        // `SessionStore` turns a cancelled or failed prompt into no session.
        // Asking `BiometricGate` first would prompt twice for the same unlock.
        if session.current == nil {
            guard session.restore() else { return .signIn }
        }

        do {
            let status = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
            return switch status.step {
            case .billing: .onboarding(.billing)
            case .bank: .onboarding(.bank)
            case .ready: .ready
            }
        } catch APIError.updateRequired {
            return .mustUpdate
        } catch APIError.unauthorized {
            // A refresh token Supabase no longer honours is not recoverable
            // here. Clearing it is what makes the next launch an ordinary one
            // rather than a repeat of this.
            session.clear()
            return .signIn
        } catch APIError.subscriptionRequired {
            // Not a guess: the server naming the reason is the server naming
            // the step.
            return .onboarding(.billing)
        } catch {
            // Offline, a 500, a body in a shape this build does not understand.
            // They differ in cause and not in what the app can do about them,
            // and none of them is grounds for picking a step.
            return .unreachable
        }
    }
}
