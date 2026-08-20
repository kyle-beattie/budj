//
//  ConnectBankView.swift
//  Budj
//

import SwiftUI

/// The bank step.
///
/// **Partly built.** The copy and the layout are real; the hand-off is not.
/// Asking the server for an authorisation URL, presenting it with
/// `@Environment(\.webAuthenticationSession)`, and re-fetching status on any
/// return is task 12.1–12.2, so the primary action is present and disabled
/// rather than opening something that cannot complete.
///
/// It takes a closure and holds no reference to the router, because the same
/// screen connects a second institution from settings later (12.3). Nothing here
/// assumes it is the first connection or that onboarding is what is happening.
struct ConnectBankView: View {
    /// Called when a connection exists — which, once 12.2 lands, means the
    /// server said so rather than the web session appearing to succeed.
    var onConnected: () -> Void

    var body: some View {
        StepScaffold(
            title: "Connect your bank",
            subtitle: "Budj watches for payments landing so it can split them the moment they arrive. You'll sign in with your bank, not with us."
        ) {
            VStack(alignment: .leading, spacing: BudjSpacing.snug) {
                AccessPoint(
                    symbol: "eye",
                    text: "Budj reads your accounts and transactions. That's all it asks for."
                )
                AccessPoint(
                    symbol: "hand.raised",
                    text: "It can't move money through this connection."
                )
                AccessPoint(
                    symbol: "xmark.circle",
                    text: "You can revoke access at any time, from Budj or from your bank."
                )
            }
        } actions: {
            // Disabled until 12.1 gives it a URL to present.
            Button("Connect your bank") {}
                .buttonStyle(.budjPrimary)
                .disabled(true)

            #if DEBUG
            DebugStepSkip(title: "Continue without connecting", action: onConnected)
            #endif
        }
    }
}

/// One line of what the connection does and does not grant.
///
/// A `View` struct rather than a computed property, so it previews and reuses.
private struct AccessPoint: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: BudjSpacing.snug) {
            Image(systemName: symbol)
                .foregroundStyle(BudjColor.accent)
                // The symbol repeats what the text says; announcing it as well
                // reads the row twice.
                .accessibilityHidden(true)
                .frame(width: BudjSpacing.loose, alignment: .center)

            Text(text)
                .font(BudjTypography.body)
                .foregroundStyle(BudjColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ConnectBankView {}
}
