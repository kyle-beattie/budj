//
//  AppModel.swift
//  Budj
//

import Foundation
import Observation

/// What the app is showing, and the one place that decides it.
///
/// It is also the app's `APIInterruptionHandler`: the three refusals that mean
/// the same thing wherever they arrive are answered here, once, rather than by
/// every screen that might provoke one.
@Observable
final class AppModel: APIInterruptionHandler {
    private(set) var phase: AppPhase = .launching

    /// Set when a session ended under someone rather than because they asked.
    /// The sign-in screen says so instead of appearing for no reason.
    private(set) var endedUnexpectedly = false

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    /// Resolves where to start from.
    ///
    /// Reading the stored session is the whole of it for now. The rest of the
    /// launch gate — unlocking a biometry-protected item, fetching onboarding
    /// status, and the retryable failure that comes with it — is task 8.1, and
    /// until it exists a restored session goes straight to `ready`.
    func start() {
        phase = session.restore() ? .ready : .onboarding
    }

    /// Called when authentication produced a session.
    func signedIn() {
        endedUnexpectedly = false
        phase = .ready
    }

    /// Called when the user asks to leave.
    func signedOut() {
        endedUnexpectedly = false
        phase = .onboarding
    }

    // MARK: - APIInterruptionHandler

    func handle(_ interruption: APIInterruption) {
        switch interruption {
        case .updateRequired:
            // Outranks everything: by definition nothing else the app does is
            // trustworthy once the server has stopped serving this build.
            phase = .mustUpdate
        case .sessionEnded:
            endedUnexpectedly = true
            phase = .onboarding
        case .entitlementLost:
            // Returns to onboarding, where the billing step will explain it once
            // the paywall exists (task 11.x).
            phase = .onboarding
        }
    }
}
