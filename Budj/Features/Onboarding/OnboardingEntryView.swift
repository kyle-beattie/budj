//
//  OnboardingEntryView.swift
//  Budj
//

import SwiftUI

/// The way into onboarding, and the owner of the state behind it.
///
/// It switches on the step the launch gate resolved, with sign-in as the case
/// that runs when there is no session yet. The value-driven router that
/// replaces this switch, and the real screens behind each step, are tasks 9.2
/// and 9.3.
struct OnboardingEntryView: View {
    /// The server's step, or `nil` when nobody is signed in.
    var resuming: OnboardingStatus.Step?

    @Environment(Authenticator.self) private var authenticator
    @Environment(AppModel.self) private var app

    @State private var model: EmailSignInModel?

    var body: some View {
        Group {
            if let resuming {
                OnboardingStepPlaceholder(step: resuming)
            } else if let model {
                EmailSignInView(model: model) {
                    // The gate decides where signing in lands, so this does not
                    // set a phase of its own.
                    Task { await app.signedIn() }
                }
            } else {
                BudjColor.background.ignoresSafeArea()
            }
        }
        .onAppear {
            // Built here rather than in an initialiser so it takes the
            // authenticator from the environment the app actually assembled.
            if model == nil {
                model = EmailSignInModel(authenticator: authenticator)
            }
        }
    }
}
