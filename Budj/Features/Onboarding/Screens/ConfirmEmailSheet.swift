//
//  ConfirmEmailSheet.swift
//  Budj
//

import SwiftUI

/// The address-confirmation flow, start to finish, in one sheet.
///
/// It opens saying the account exists and the address needs confirming, and the
/// same sheet is still the thing on screen when the link comes back — so the
/// person sees their answer where they left the question, rather than on a
/// screen they have to find again.
struct ConfirmEmailSheet: View {
    let model: EmailConfirmationModel

    /// Closes the sheet. Signing the person in afterwards is the caller's, from
    /// `didConfirm` — the sheet does not route.
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: BudjSpacing.loose) {
            VStack(spacing: BudjSpacing.regular) {
                icon
                    .font(BudjTypography.display)
                    .foregroundStyle(iconColour)
                    .accessibilityHidden(true)

                VStack(spacing: BudjSpacing.tight) {
                    Text(title)
                        .font(BudjTypography.headline)
                        .foregroundStyle(BudjColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(explanation)
                        .font(BudjTypography.body)
                        .foregroundStyle(BudjColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            .frame(maxHeight: .infinity)

            actions
        }
        .padding(.horizontal, BudjSpacing.loose)
        .padding(.vertical, BudjSpacing.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BudjColor.background)
        .animation(BudjMotion.standard, value: model.phase)
        // Nothing to cancel mid-exchange, and a swipe that lands between the
        // link arriving and the session existing would leave the app looking
        // signed out to someone who is not.
        .interactiveDismissDisabled(model.phase == .exchanging)
    }

    // MARK: - Per phase

    @ViewBuilder
    private var icon: some View {
        switch model.phase {
        case .confirmed:
            Image(systemName: "checkmark.circle.fill")
        case .refused:
            Image(systemName: "exclamationmark.triangle.fill")
        case .exchanging:
            ProgressView().controlSize(.large)
        default:
            Image(systemName: "envelope.badge")
        }
    }

    private var iconColour: Color {
        switch model.phase {
        case .confirmed: BudjColor.accent
        case .refused: BudjColor.warning
        default: BudjColor.accent
        }
    }

    private var title: String {
        switch model.phase {
        case .exchanging: "Confirming your email address"
        case .confirmed: "Email address confirmed"
        case .refused: "That link didn't work"
        default: "Confirm your email address"
        }
    }

    private var explanation: String {
        switch model.phase {
        case let .waiting(email):
            "Your account is created. Open the link we sent to \(email) and you'll come straight back here, signed in."
        case .exchanging:
            "This takes a moment."
        case .confirmed:
            "You're signed in. Let's finish setting up Budj."
        case let .refused(message):
            message
        case .none:
            ""
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch model.phase {
        case .confirmed:
            Button("Continue", action: onClose)
                .buttonStyle(.budjPrimary)
        case .refused:
            Button("Back to sign in", action: onClose)
                .buttonStyle(.budjPrimary)
        case .exchanging:
            // Deliberately nothing. There is no useful answer to a request in
            // flight, and a disabled button is a control asking to be pressed.
            EmptyView()
        default:
            Button("Done", action: onClose)
                .buttonStyle(.budjSecondary)
        }
    }
}

//#Preview("Waiting") {
//    ConfirmEmailSheet(model: .preview(.waiting(email: "someone@example.com")), onClose: {})
//}
//
//#Preview("Confirmed") {
//    ConfirmEmailSheet(model: .preview(.confirmed), onClose: {})
//}
//
//#Preview("Refused") {
//    ConfirmEmailSheet(
//        model: .preview(.refused("That link has expired. Create your account again to get a new one.")),
//        onClose: {}
//    )
//}
