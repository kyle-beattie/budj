//
//  OnboardingModel.swift
//  Budj
//

import Foundation
import Observation

/// The router's state: the server's step, the two client-only steps interleaved
/// into it, and the advisory push flag.
///
/// There is no `advance()`. The step moves when the server is asked again, or
/// when a client-only step is recorded as offered, and by no other means — a
/// local cursor that says `bank` while the server says `billing` is a person
/// stuck on a screen that will never let them through (D5).
@Observable
final class OnboardingModel {
    private(set) var step: OnboardingStep = .signIn

    /// Advisory, from the same response. Worth acting on — a rule that cannot
    /// notify cannot be approved — but never a reason to hold anyone back.
    private(set) var pushOutstanding = false

    /// Set when a request was refused for want of a subscription. The billing
    /// step says why rather than reappearing unexplained.
    private(set) var entitlementLapsed = false

    private(set) var isRefreshing = false

    private let api: BudjAPI
    private let record: any ClientStepRecord

    /// Set by tests. Production leaves it `nil` and asks the device, because
    /// enrolment can change while the app is running — somebody who sets up
    /// Face ID in Settings and comes back should be offered it, and a value
    /// captured when the app launched would say otherwise.
    private let biometricsAvailableOverride: Bool?

    /// Whether this device can offer biometric unlock at all. A step that
    /// cannot be completed is not a step worth showing.
    private var biometricsAvailable: Bool {
        biometricsAvailableOverride ?? BiometricGate().isAvailable
    }

    /// The server's own answer, held so the interleaving can be recomputed when
    /// a client-only step is recorded without asking again.
    private var serverStep: OnboardingStatus.Step?

    /// Whether the welcome screen has been left. Deliberately not persisted:
    /// signing out returns you to the front door, and so does relaunching while
    /// signed out. It is the entry point, not a step that is completed once.
    private var leftWelcome = false

    init(
        api: BudjAPI,
        record: (any ClientStepRecord)? = nil,
        biometricsAvailable: Bool? = nil
    ) {
        self.api = api
        // Not a default argument: those are evaluated in a nonisolated
        // context, which main-actor types cannot be.
        self.record = record ?? DefaultsStepRecord()
        self.biometricsAvailableOverride = biometricsAvailable
    }

    // MARK: - Seeding

    /// Applies what the launch gate already resolved, so the flow does not ask
    /// the server a question it has just been answered.
    func seed(serverStep: OnboardingStatus.Step?, entitlementLapsed: Bool = false) {
        self.serverStep = serverStep
        if serverStep == nil { leftWelcome = false }
        if entitlementLapsed { self.entitlementLapsed = true }
        resolve()
    }

    /// The welcome screen's two actions. Both lead to the same screen; the mode
    /// only decides which way round it starts.
    func beginSignIn(registering: Bool) {
        startsRegistering = registering
        leftWelcome = true
        resolve()
    }

    /// Which way the sign-in screen opens, set by whichever welcome action was
    /// tapped. Presentation rather than routing, but it belongs with the
    /// decision that produced it.
    private(set) var startsRegistering = false

    // MARK: - Asking the server

    /// The only thing that moves a server-visible step.
    ///
    /// Called after a purchase is submitted and after the bank session returns,
    /// and after nothing else (9.4). Face ID and push change nothing the server
    /// can see, so refreshing for them would be a round trip that cannot
    /// produce a different answer.
    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let status = try await api.send(.onboardingStatus, as: OnboardingStatus.self)
            serverStep = status.step
            pushOutstanding = !status.pushRegistered
            // Only a confirmed subscription clears the explanation. A refusal
            // for any other reason leaves it standing.
            if status.subscriptionActive { entitlementLapsed = false }
            resolve()
        } catch APIError.subscriptionRequired {
            // A refund or an expiry mid-flow. Back to billing, saying why.
            serverStep = .billing
            entitlementLapsed = true
            resolve()
        } catch {
            // A failed refresh is not progress. The step already on screen
            // stays there rather than being replaced by a guess.
        }
    }

    // MARK: - The client-only steps

    /// Records that a step was offered, whichever way it was answered.
    ///
    /// Accepting and declining are the same fact to the router: it was asked.
    /// The difference is in what the screen did before calling this — turning
    /// biometry on, registering for notifications — not in whether to ask again.
    func offered(_ clientStep: ClientOnlyStep) {
        record.recordOffered(clientStep)
        resolve()
    }

    // MARK: - Interleaving

    private func resolve() {
        guard let serverStep else {
            step = leftWelcome ? .signIn : .welcome
            return
        }

        // Face ID comes first, before whatever the server's step is. It is
        // about the session that was just established rather than a stage of
        // onboarding, and putting the paywall in front of it means meeting the
        // price before anything else has happened. Keying it off the first
        // server step rather than off `billing` specifically also covers the
        // reinstall: somebody who already subscribed signs in, lands on `bank`,
        // and still gets asked.
        if shouldOffer(.biometrics) {
            step = .biometrics
            return
        }

        step = switch serverStep {
        case .billing:
            .billing
        case .bank:
            .bank
        case .ready:
            shouldOffer(.push) ? .push : .ready
        }
    }

    private func shouldOffer(_ clientStep: ClientOnlyStep) -> Bool {
        if record.hasOffered(clientStep) { return false }
        // Nothing is gained by offering an unlock this device cannot perform,
        // and the record is left alone so a device that gains an enrolment can
        // still be asked.
        if clientStep == .biometrics, !biometricsAvailable { return false }
        return true
    }
}
