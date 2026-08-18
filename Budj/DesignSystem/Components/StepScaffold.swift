//
//  StepScaffold.swift
//  Budj
//

import SwiftUI

/// The shell every onboarding screen is built on: a title, an optional line of
/// explanation, a body, and an action area pinned to the bottom.
///
/// Six screens sharing one shell is what makes the flow feel like one flow, and
/// it is where the safe areas, the spacing rhythm, and the glass under the
/// primary action are defined once instead of six times.
struct StepScaffold<Content: View, Actions: View>: View {
    let title: String
    var subtitle: String?

    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            BudjMark()
              .frame(height: 148)
              .frame(maxWidth: .infinity)
              .padding(.vertical, BudjSpacing.section)
              .accessibilityHidden(true)
            ScrollView {
                VStack(alignment: .leading, spacing: BudjSpacing.loose) {
                    VStack(alignment: .leading, spacing: BudjSpacing.tight) {
                        Text(title)
                            .font(BudjTypography.display)
                            .foregroundStyle(BudjColor.textPrimary)

                        if let subtitle {
                            Text(subtitle)
                                .font(BudjTypography.body)
                                .foregroundStyle(BudjColor.textSecondary)
                        }
                    }
                    .accessibilityAddTraits(.isHeader)

                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BudjSpacing.loose)
                .padding(.top, BudjSpacing.screen)
                .padding(.bottom, BudjSpacing.section)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: BudjSpacing.snug) {
                actions()
            }
            .padding(.horizontal, BudjSpacing.loose)
            .padding(.top, BudjSpacing.regular)
            .padding(.bottom, BudjSpacing.tight)
            // The action area floats over the content it scrolls past, which is
            // exactly the case glass is reserved for.
            .background(.regularMaterial)
        }
        // Onboarding stays a single column on iPad rather than stretching a
        // form to 13 inches.
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(BudjColor.background)
    }
}

#Preview {
    StepScaffold(
        title: "Create your account",
        subtitle: "Budj connects to your bank and moves money when your rules say so."
    ) {
        Text("Body content goes here.")
            .font(BudjTypography.body)
            .foregroundStyle(BudjColor.textPrimary)
    } actions: {
        Button("Continue") {}.buttonStyle(.budjPrimary)
        Button("I already have an account") {}.buttonStyle(.budjQuiet)
    }
}
