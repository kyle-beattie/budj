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

    /// The onboarding router. Owned here because this is what resolves a launch
    /// destination into a step, and two objects seeding it is two objects that
    /// can disagree.
    let onboarding: OnboardingModel

    private let session: SessionStore
    private let gate: LaunchGateModel

    init(session: SessionStore, gate: LaunchGateModel, onboarding: OnboardingModel) {
        self.session = session
        self.gate = gate
        self.onboarding = onboarding
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
    /// app.
    func signedIn() async {
        endedUnexpectedly = false
        await start()
    }

    /// Called when the router reaches its last step.
    func onboardingFinished() {
        phase = .ready
    }

    /// Called when the user asks to leave.
    func signedOut() {
        endedUnexpectedly = false
        onboarding.seed(serverStep: nil)
        phase = .onboarding
    }

    // MARK: - Applying a destination

    private func apply(_ destination: LaunchDestination) {
        // `mustUpdate` is terminal and outranks everything, including a
        // destination resolved before the refusal that produced it arrived.
        guard phase != .mustUpdate else { return }

        switch destination {
        case .signIn:
            onboarding.seed(serverStep: nil)
            phase = .onboarding

        case let .onboarding(step):
            onboarding.seed(serverStep: step)
            phase = .onboarding

        case .ready:
            onboarding.seed(serverStep: .ready)
            // The push step is invisible to the server, so `ready` from the
            // gate is not necessarily ready to the router. Somebody who
            // connected their bank and relaunched before being asked about
            // notifications still gets asked.
            phase = onboarding.step == .ready ? .ready : .onboarding

        case .unreachable:
            phase = .unreachable

        case .mustUpdate:
            phase = .mustUpdate
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
            onboarding.seed(serverStep: nil)
            phase = .onboarding
        case .entitlementLost:
            // Back to billing, and the step says why rather than reappearing
            // unexplained.
            onboarding.seed(serverStep: .billing, entitlementLapsed: true)
            phase = .onboarding
        }
    }
}

#if DEBUG
extension AppModel {
    /// A model wired to an empty store, for previews. It resolves nothing,
    /// because a preview has no server to ask.
    static func preview() -> AppModel {
        let session = SessionStore()
        let api = BudjAPI(session: session)
        return AppModel(
            session: session,
            gate: LaunchGateModel(api: api, session: session),
            onboarding: OnboardingModel(api: api)
        )
    }
}
#endif
