//
//  PlaceholderView.swift
//  Budj
//

import SwiftUI

/// Where `ready` lands until the tabs exist.
///
/// It carries sign-out because sign-out has to live somewhere reachable to be
/// testable, and this is the only signed-in screen there is. It moves to
/// settings when settings exists.
struct PlaceholderView: View {
    @Environment(Authenticator.self) private var authenticator
    @Environment(SessionStore.self) private var session
    @Environment(AppModel.self) private var app

    @State private var isSigningOut = false

    var body: some View {
        StepScaffold(title: "You're signed in", subtitle: subtitle) {
        } actions: {
            Button("Sign out") { signOut() }
                .buttonStyle(BudjButtonStyle(variant: .secondary, isLoading: isSigningOut))
                .disabled(isSigningOut)
        }
    }

    private var subtitle: String {
        if let email = session.current?.user.email {
            "As \(email). Onboarding is done. Rules, and the rest of the app, are still being built."
        } else {
            "Onboarding is done. Rules, and the rest of the app, are still being built."
        }
    }

    private func signOut() {
        guard !isSigningOut else { return }
        isSigningOut = true
        Task {
            await authenticator.signOut()
            isSigningOut = false
            app.signedOut()
        }
    }
}
