//
//  OnboardingFlowView.swift
//  Budj
//

import SwiftUI

/// The router: one switch over the step, with a transition driven by the value.
///
/// Deliberately not a `NavigationStack` (D13). There is no back button in
/// onboarding — you cannot return to the paywall after buying, and you cannot
/// un-connect a bank by swiping back — and a stack would create a back stack
/// that has to be suppressed everywhere, which is a fight with the framework.
/// Where a step needs internal depth it owns that itself and does not leak it
/// here.
struct OnboardingFlowView: View {
    @Environment(Authenticator.self) private var authenticator
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let model: OnboardingModel

    @State private var signIn: EmailSignInModel?

    var body: some View {
        ZStack {
            step
                .transition(BudjMotion.stepTransition(reduceMotion: reduceMotion))
        }
        // Named value rather than an implicit animation, so an unrelated change
        // cannot animate the step out from under someone.
        .animation(BudjMotion.transition, value: model.step)
        .onAppear {
            // Built here rather than in an initialiser so it takes the
            // authenticator from the environment the app actually assembled.
            if signIn == nil {
                signIn = EmailSignInModel(authenticator: authenticator)
            }
        }
        .onChange(of: model.step) { _, step in
            switch step {
            case .signIn:
                // The welcome action decides which way round the screen opens.
                signIn?.setMode(model.startsRegistering ? .register : .signIn)
            case .ready:
                // The flow's only exit. `ready` is a step of the router like any
                // other; leaving is the app's business, not the router's.
                app.onboardingFinished()
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var step: some View {
        switch model.step {
        case .welcome:
            WelcomeView(
                onCreateAccount: { model.beginSignIn(registering: true) },
                onSignIn: { model.beginSignIn(registering: false) }
            )

        case .signIn:
            if let signIn {
                EmailSignInView(model: signIn) {
                    // The gate decides where signing in lands, so this does not
                    // pick a step of its own.
                    Task { await app.signedIn() }
                }
            } else {
                BudjColor.background.ignoresSafeArea()
            }

        case .billing:
            // Task 11.x.
            OnboardingStepPlaceholder(step: .billing, entitlementLapsed: model.entitlementLapsed)

        case .biometrics:
            if let kind = BiometricGate().enrolledBiometry {
                BiometricOptInView(kind: kind) { model.offered(.biometrics) }
            } else {
                // The model does not route here without an enrolment; this is
                // the case where one disappeared between the two checks.
                Color.clear.onAppear { model.offered(.biometrics) }
            }

        case .bank:
            // Task 12.x.
            OnboardingStepPlaceholder(step: .bank)

        case .push:
            // Task 13.x.
            OnboardingStepPlaceholder(step: .push)

        case .ready:
            // Held for the instant between the step changing and the app
            // leaving onboarding.
            BudjColor.background.ignoresSafeArea()
        }
    }
}
