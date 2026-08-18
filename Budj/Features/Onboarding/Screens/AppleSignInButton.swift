//
//  AppleSignInButton.swift
//  Budj
//

import AuthenticationServices
import SwiftUI

/// Sign in with Apple, asking for the two scopes the profile needs.
///
/// `.fullName` is requested even though Apple supplies it only on the very
/// first authorisation: it is the single opportunity to seed a display name,
/// and not asking means never having it.
///
/// The button is Apple's own rather than a `BudjButtonStyle` one. Its
/// appearance is prescribed by the Human Interface Guidelines and re-skinning
/// it is a review rejection, so this is the one place in the app where a
/// control does not come from the design system.
struct AppleSignInButton: View {
    let onCredential: (AppleCredential) -> Void
    let onFailure: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case let .success(authorization):
                guard
                    let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                    let mapped = AppleCredential(credential)
                else {
                    onFailure("Apple didn't return what we needed. Try again, or use your email address.")
                    return
                }
                onCredential(mapped)

            case let .failure(error):
                // Cancelling is not a failure worth saying anything about —
                // the person closed a sheet they opened.
                if (error as? ASAuthorizationError)?.code == .canceled { return }
                onFailure("That didn't work. Try again, or use your email address.")
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .clipShape(Capsule())
    }
}

#Preview {
    AppleSignInButton(onCredential: { _ in }, onFailure: { _ in })
        .padding()
}
