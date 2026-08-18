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
    private let gate: LaunchGateModel

    init(session: SessionStore, gate: LaunchGateModel) {
        self.session = session
        self.gate = gate
    }

    /// Resolves where to start from, and where the retry behind
    /// `UnreachableView` goes too — the question is the same one, and asking it
    /// twice through two code paths is how the two answers start to differ.
    ///
    /// The phase is not reset to `launching` first: on a retry the failure
    /// screen stays put with its button spinning, rather than flashing back to
    /// the launch mark.
    func start() async {
        apply(await gate.resolve())
    }

    /// Called when authentication produced a session.
    ///
    /// It re-runs the gate rather than assuming `ready`, because the server
    /// decides the step and a fresh account's first step is billing, not the
    /// app. Task 9.4 owns the same refresh after purchase and after the bank
    /// session returns.
    func signedIn() async {
        endedUnexpectedly = false
        await start()
    }

    /// Called when the user asks to leave.
    func signedOut() {
        endedUnexpectedly = false
        phase = .onboarding(resuming: nil)
    }

    // MARK: - Applying a destination

    private func apply(_ destination: LaunchDestination) {
        // `mustUpdate` is terminal and outranks everything, including a
        // destination resolved before the refusal that produced it arrived.
        guard phase != .mustUpdate else { return }

        phase = switch destination {
        case .signIn: .onboarding(resuming: nil)
        case let .onboarding(step): .onboarding(resuming: step)
        case .ready: .ready
        case .unreachable: .unreachable
        case .mustUpdate: .mustUpdate
        }
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
            phase = .onboarding(resuming: nil)
        case .entitlementLost:
            // The billing step will explain it once the paywall exists (11.x).
            phase = .onboarding(resuming: .billing)
        }
    }
}

#if DEBUG
extension AppModel {
    /// A model wired to an empty store, for previews. It resolves nothing,
    /// because a preview has no server to ask.
    static func preview() -> AppModel {
        let session = SessionStore()
        return AppModel(session: session, gate: LaunchGateModel(api: BudjAPI(session: session), session: session))
    }
}
#endif
