//
//  PlanSummaryCard.swift
//  Budj
//

import SwiftUI

/// The plan and its price.
///
/// Not a button and not selectable: there is one plan, so presenting it as a
/// choice would be theatre. It replaced a two-row chooser when the tiers went —
/// counting rules and connections described what a plan cost to run, not what it
/// was worth, and the tier that could not move money was not a cheaper product.
///
/// A solid surface rather than glass. Glass is for surfaces floating over
/// content; this is the content.
struct PlanSummaryCard: View {
    /// Nil while the store has not answered. The plan is still worth showing —
    /// it exists whether or not the App Store is reachable — so only the price
    /// line depends on this.
    let offer: PlanOffer?

    var body: some View {
        VStack(alignment: .leading, spacing: BudjSpacing.snug) {
            Text("Budj")
                .font(BudjTypography.title)
                .foregroundStyle(BudjColor.textPrimary)

            price

            Text("Every feature, with no limit on rules or bank connections.")
                .font(BudjTypography.caption)
                .foregroundStyle(BudjColor.textSecondary)
        }
        .padding(BudjSpacing.loose)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BudjColor.surface, in: .rect(cornerRadius: BudjRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: BudjRadius.large)
                .strokeBorder(BudjColor.borderSubtle, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var price: some View {
        if let offer {
            HStack(alignment: .firstTextBaseline, spacing: BudjSpacing.tight) {
                // Straight from StoreKit, which in New Zealand means GST is
                // already in it — Apple collects and remits it as the merchant
                // of record, and consumer prices here must be shown inclusive.
                // Nothing in the app formats a price.
                Text(offer.displayPrice)
                    .font(BudjTypography.display)
                    .monospacedDigit()
                    .foregroundStyle(BudjColor.textPrimary)

                if let cadence = offer.cadence {
                    Text("a \(cadence), including GST")
                        .font(BudjTypography.caption)
                        .foregroundStyle(BudjColor.textSecondary)
                }
            }
        } else {
            Text("The price couldn't be loaded from the App Store.")
                .font(BudjTypography.body)
                .foregroundStyle(BudjColor.textSecondary)
        }
    }
}

#Preview("Priced") {
    PlanSummaryCard(
        offer: PlanOffer(
            id: SubscriptionCatalogue.yearly,
            name: "Budj",
            detail: "Every payment split the moment it lands.",
            displayPrice: "$199.00",
            cadence: "year"
        )
    )
    .padding(BudjSpacing.loose)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(BudjColor.background)
}

#Preview("No price") {
    PlanSummaryCard(offer: nil)
        .padding(BudjSpacing.loose)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BudjColor.background)
}
