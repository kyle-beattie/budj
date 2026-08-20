//
//  WelcomeView.swift
//  Budj
//

import SwiftUI

/// The front door: what Budj does, and two ways in.
///
/// The copy addresses somebody self-employed, because that is who this is for.
/// Salary is the one case Budj is *not* for: a fixed amount on a fixed date is
/// already solved by an automatic payment at the bank, for free. The problem
/// only exists when the amount and the timing are unknown in advance, which is
/// exactly what a scheduled transfer cannot express and a rule can.
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
            title: "Split it before you spend it",
            subtitle: "Budj watches for money landing and sets aside what isn't yours — tax, GST, whatever you decide — the moment it arrives."
        ) {
            VStack(alignment: .leading, spacing: BudjSpacing.regular) {
                point(
                    symbol: "arrow.trianglehead.branch",
                    title: "Built for irregular income",
                    detail: "Different payers, different amounts, different days. Set your percentages once and Budj applies them to whatever lands."
                )
                point(
                    symbol: "building.columns",
                    title: "Connected to your bank",
                    detail: "Read-only access through open banking, and you can revoke it whenever you like."
                )
                point(
                    symbol: "bolt",
                    title: "No mental arithmetic",
                    detail: "No flicking between your banking app and a spreadsheet to work out what is actually yours to spend."
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
