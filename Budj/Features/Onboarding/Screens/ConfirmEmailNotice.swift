//
//  ConfirmEmailNotice.swift
//  Budj
//

import SwiftUI

/// Shown when an account was created but the address has to be confirmed before
/// it can be used.
///
/// Its own type because it is a thing with a name and a state, and because the
/// case it covers — registered, but no session — is the one most likely to be
/// mistaken for a failure by whoever reads this next.
struct ConfirmEmailNotice: View {
    let email: String

    var body: some View {
        HStack(alignment: .top, spacing: BudjSpacing.snug) {
            Image(systemName: "envelope.badge")
                .foregroundStyle(BudjColor.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: BudjSpacing.hair) {
                Text("Confirm your email address")
                    .font(BudjTypography.title)
                    .foregroundStyle(BudjColor.textPrimary)

                Text("Your account is created. Open the link sent to \(email), then sign in.")
                    .font(BudjTypography.caption)
                    .foregroundStyle(BudjColor.textSecondary)
            }
        }
        .padding(BudjSpacing.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BudjColor.surface, in: .rect(cornerRadius: BudjRadius.large))
    }
}

#Preview {
    ConfirmEmailNotice(email: "someone@example.com")
        .padding(BudjSpacing.loose)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BudjColor.background)
}
