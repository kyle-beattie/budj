//
//  EmailSignInView.swift
//  Budj
//

import SwiftUI

/// Sign in or create an account with an email address.
///
/// One screen for both, because they ask for the same two things and a person
/// who mistypes their address on the sign-in screen should not have to find a
/// different screen to fix it.
struct EmailSignInView: View {
    @Bindable var model: EmailSignInModel
    let onSignedIn: () -> Void

    @Environment(Authenticator.self) private var authenticator

    @FocusState private var focus: Field?
    @State private var isSigningInWithApple = false
    @State private var appleError: String?

    private enum Field { case email, password }

    var body: some View {
        StepScaffold(title: title, subtitle: subtitle) {
            VStack(alignment: .leading, spacing: BudjSpacing.regular) {
                BudjTextField(
                    label: "Email",
                    placeholder: "you@example.com",
                    text: $model.email,
                    error: model.emailError,
                    textContentType: .username,
                    keyboardType: .emailAddress,
                    submitLabel: .next,
                    onSubmit: { focus = .password }
                )
                .focused($focus, equals: .email)

                BudjTextField(
                    label: "Password",
                    placeholder: passwordPlaceholder,
                    text: $model.password,
                    isSecure: true,
                    error: model.passwordError,
                    // `.newPassword` on registration, so iOS offers to
                    // generate and save a strong one. Note for anyone writing a
                    // UI test against this screen: it hands the field to
                    // Automatic Strong Password, which XCUITest cannot type
                    // into — that is an automation limit, not a defect.
                    textContentType: model.mode == .register ? .newPassword : .password,
                    submitLabel: .go,
                    onSubmit: { submit() }
                )
                .focused($focus, equals: .password)

                if let formError = model.formError {
                    Text(formError)
                        .font(BudjTypography.caption)
                        .foregroundStyle(BudjColor.danger)
                        .transition(.opacity)
                }

                if let appleError {
                    Text(appleError)
                        .font(BudjTypography.caption)
                        .foregroundStyle(BudjColor.danger)
                        .transition(.opacity)
                }

                if model.outcome == .confirmationRequired {
                    ConfirmEmailNotice(email: model.email)
                }
            }
            .animation(BudjMotion.standard, value: model.formError)
            .animation(BudjMotion.standard, value: model.outcome)
            .animation(BudjMotion.standard, value: appleError)
        } actions: {
            if authenticator.offersProviderSignIn {
                AppleSignInButton(
                    onCredential: signInWithApple,
                    onFailure: { appleError = $0 }
                )
                .disabled(isSigningInWithApple || model.isWorking)

                Text("or")
                    .font(BudjTypography.caption)
                    .foregroundStyle(BudjColor.textSecondary)
            }

            Button(primaryActionTitle) { submit() }
                .buttonStyle(.budjPrimary(isLoading: model.isWorking))
                .disabled(!model.canSubmit || isSigningInWithApple)

            Button(switchActionTitle) { model.setMode(model.mode.other) }
                .buttonStyle(.budjQuiet)
                .disabled(model.isWorking || isSigningInWithApple)
        }
        .animation(BudjMotion.standard, value: model.mode)
        .onChange(of: model.outcome) { _, outcome in
            if outcome == .signedIn { onSignedIn() }
        }
    }

    // MARK: - Actions

    private func submit() {
        focus = nil
        Task { await model.submit() }
    }

    private func signInWithApple(_ credential: AppleCredential) {
        guard !isSigningInWithApple else { return }
        focus = nil
        appleError = nil
        isSigningInWithApple = true
        Task {
            do {
                try await authenticator.signInWithApple(credential)
                isSigningInWithApple = false
                onSignedIn()
            } catch {
                isSigningInWithApple = false
                appleError = "We couldn't finish signing you in. Try again, or use your email address."
            }
        }
    }

    // MARK: - Copy

    private var title: String {
        model.mode == .signIn ? "Sign in" : "Create your account"
    }

    private var subtitle: String {
        switch model.mode {
        case .signIn: "Use the email address you signed up with."
        case .register: "Budj runs your rules and moves money when they fire."
        }
    }

    private var passwordPlaceholder: String {
        model.mode == .signIn
            ? "Your password"
            : "At least \(EmailSignInModel.minimumPasswordLength) characters"
    }

    private var primaryActionTitle: String {
        model.mode == .signIn ? "Sign in" : "Create account"
    }

    private var switchActionTitle: String {
        model.mode == .signIn ? "Create an account instead" : "I already have an account"
    }
}
