//
//  OnboardingEntryView.swift
//  Budj
//

import SwiftUI

/// The way into onboarding, and the owner of the state behind it.
///
/// Today that is one screen. When the server-derived step router arrives (task
/// 9.2) it switches here, with sign-in as the case that runs when there is no
/// session yet.
struct OnboardingEntryView: View {
    @Environment(Authenticator.self) private var authenticator
    @Environment(AppModel.self) private var app

    @State private var model: EmailSignInModel?

    var body: some View {
        Group {
            if let model {
                EmailSignInView(model: model, onSignedIn: app.signedIn)
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
