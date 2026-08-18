//
//  WelcomeView.swift
//  Budj
//

import SwiftUI

/// The front door: what Budj does, and two ways in.
///
/// It exists because there is no free tier and the paywall arrives early. Being
/// asked to create an account, and then to pay, without having been told what
/// the thing does is a bad first thirty seconds. One screen buys the rest of
/// the flow the benefit of the doubt.
///
/// Both actions lead to the same screen; they differ only in which way round it
/// opens. Neither is subordinate — someone who already has an account is not a
/// second-class visitor, so "I already have an account" is a real button.
struct WelcomeView: View {
    let onCreateAccount: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        StepScaffold(
            title: "Money that moves itself",
            subtitle: "Set a condition and an action, and Budj does it the moment the condition is true."
        ) {
            VStack(alignment: .leading, spacing: BudjSpacing.regular) {
                point(
                    symbol: "arrow.trianglehead.branch",
                    title: "Rules, not reminders",
                    detail: "When your salary lands, move $200 to savings. No date to pick and nothing to remember."
                )
                point(
                    symbol: "building.columns",
                    title: "Connected to your bank",
                    detail: "Read-only access through open banking, and you can revoke it whenever you like."
                )
                point(
                    symbol: "bolt",
                    title: "Fires when it's true",
                    detail: "Not on the first of the month, but the moment your balance or your income says so."
                )
            }
            .padding(.vertical, BudjSpacing.tight)
        } actions: {
            Button("Create an account") { onCreateAccount() }
                .buttonStyle(.budjPrimary)

            Button("I already have an account") { onSignIn() }
                .buttonStyle(BudjButtonStyle(variant: .secondary))
        }
    }

    @ViewBuilder
    private func point(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: BudjSpacing.snug) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(BudjColor.accent)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: BudjSpacing.hair) {
                Text(title)
                    .font(BudjTypography.title)
                    .foregroundStyle(BudjColor.textPrimary)
                Text(detail)
                    .font(BudjTypography.caption)
                    .foregroundStyle(BudjColor.textSecondary)
            }
        }
        // One label per point, so VoiceOver reads a sentence rather than two
        // fragments and an icon.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WelcomeView(onCreateAccount: {}, onSignIn: {})
}
