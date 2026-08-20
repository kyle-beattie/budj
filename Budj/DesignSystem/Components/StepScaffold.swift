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


    @State private var currentOffset: CGFloat = 0
    let maxHeight: CGFloat = 80
    let minHeight: CGFloat = 40

    var body: some View {

      ZStack {
        BackgroundView()
        // The action area is a bottom safe-area inset rather than a sibling in
        // a VStack. As a sibling it took its intrinsic height first and the
        // scroll view got whatever was left — which in landscape with the
        // keyboard up was nothing, so the form was laid out and then clipped to
        // zero height. As an inset the scroll view always has the full
        // container, and its content is simply pushed clear of the buttons.
        HeaderView()
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
        .safeAreaInset(edge: .bottom) {
          VStack(spacing: BudjSpacing.snug) {
            actions()
          }
          .padding(.horizontal, BudjSpacing.loose)
          .padding(.top, BudjSpacing.loose)
          .padding(.bottom, BudjSpacing.loose)
          // The action area floats over the content it scrolls past, which is
          // exactly the case glass is reserved for.
          .glassEffect(.clear, in: .rect)
        }
        // Onboarding stays a single column on iPad rather than stretching a
        // form to 13 inches.
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
      }
    }


  // Safely calculate the frame height based on scrolling direction
  private var currentHeight: CGFloat {
      let calculated = maxHeight - currentOffset
      return max(minHeight, min(maxHeight, calculated))
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
