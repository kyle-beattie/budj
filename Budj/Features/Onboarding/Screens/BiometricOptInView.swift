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

    var body: some View {
        StepScaffold(
            title: "Unlock with \(kind.name)?",
            subtitle: "Your sign-in stays on this device either way. \(kind.name) just means you don't have to type your password when you come back."
        ) {
            Image(systemName: symbol)
                .font(.system(size: 56))
                .foregroundStyle(BudjColor.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BudjSpacing.section)
                .accessibilityHidden(true)
        } actions: {
            Button("Use \(kind.name)") { turnOn() }
                .buttonStyle(.budjPrimary)

            Button("Not now") { onAnswered() }
                .buttonStyle(BudjButtonStyle(variant: .secondary))
        }
    }

    private var symbol: String {
        switch kind {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        }
    }

    private func turnOn() {
        // Rewrites the stored session behind the access control. Turning it on
        // cannot be done by updating the existing item, which is why this goes
        // through the store rather than the Keychain directly.
        session.setRequiresBiometry(true)
        onAnswered()
    }
}

#Preview {
    BiometricOptInView(kind: .faceID) {}
        .environment(SessionStore())
}
