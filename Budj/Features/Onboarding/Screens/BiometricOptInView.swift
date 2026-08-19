//
//  BiometricOptInView.swift
//  Budj
//

import SwiftUI

/// Offers to keep the session behind Face ID.
///
/// Two rules from D8 shape the copy. It unlocks a locally-held token, so
/// nothing here may imply that a transfer was approved by a face. And declining
/// is a supported configuration rather than a degraded one — the session still
/// persists and relaunching still resumes — so the second action says what it
/// does rather than warning about what is being given up.
struct BiometricOptInView: View {
    let kind: BiometricKind
    let onAnswered: () -> Void

    @Environment(SessionStore.self) private var session

    @State private var isVerifying = false
    @State private var failure: String?

    var body: some View {
        StepScaffold(
            title: "Unlock with \(kind.name)?",
            subtitle: "Your sign-in stays on this device either way. \(kind.name) just means you don't have to type your password when you come back."
        ) {
            VStack(spacing: BudjSpacing.regular) {
                Image(systemName: symbol)
                    .font(.system(size: 56))
                    .foregroundStyle(BudjColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BudjSpacing.section)
                    .accessibilityHidden(true)

                if let failure {
                    Text(failure)
                        .font(BudjTypography.caption)
                        .foregroundStyle(BudjColor.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
            }
            .animation(BudjMotion.standard, value: failure)
        } actions: {
            Button("Use \(kind.name)") { turnOn() }
                .buttonStyle(.budjPrimary(isLoading: isVerifying))
                .disabled(isVerifying)

            Button("Not now") { decline() }
                .buttonStyle(BudjButtonStyle(variant: .secondary))
                .disabled(isVerifying)
        }
    }

    private var symbol: String {
        switch kind {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        }
    }

    // MARK: - Answers

    /// Asks for the biometric **before** claiming it is on.
    ///
    /// Writing the Keychain item behind the access control does not itself
    /// prompt — `SecItemAdd` never does; only reading raises the system prompt —
    /// so the first version turned biometry on with no visible sign that
    /// anything had happened, and the first proof it worked came a launch later.
    /// Evaluating here is what makes the button do what it says, and it confirms
    /// the enrolment can actually satisfy the item being written.
    ///
    /// The reason string is about the saved sign-in and nothing else: this
    /// unlocks a locally-held token, and the server cannot verify it (D8).
    private func turnOn() {
        guard !isVerifying else { return }
        failure = nil
        isVerifying = true

        Task {
            let outcome = await BiometricGate().unlock(
                reason: "Turn on \(kind.name) for your saved sign-in."
            )
            isVerifying = false

            switch outcome {
            case .unlocked:
                guard session.setRequiresBiometry(true) else {
                    // The prompt succeeded and the write did not. Saying so is
                    // the only honest option: the alternative is a screen that
                    // reports Face ID is on over a session that is not behind it.
                    failure = "\(kind.name) couldn't be turned on. You can carry on and set it up later."
                    return
                }
                onAnswered()

            case .fallBackToSignIn:
                // Cancelled, failed, or an enrolment that changed. None of them
                // is an error worth a dead end — the step is still answerable.
                failure = "\(kind.name) wasn't confirmed. Try again, or carry on without it."
            }
        }
    }

    /// Declining is an answer, and it is written through rather than merely
    /// recorded: the preference is device-scoped, so somebody signing in on a
    /// device where it was already on must be able to turn it off from here.
    private func decline() {
        session.setRequiresBiometry(false)
        onAnswered()
    }
}

#Preview {
    BiometricOptInView(kind: .faceID) {}
        .environment(SessionStore())
}
