//
//  PaywallView.swift
//  Budj
//

import SwiftUI

/// The billing step.
///
/// **Partly built, and paused.** The plan and its price are real — the price
/// comes from StoreKit, which in a debug build means Xcode's `Budj.storekit`
/// configuration rather than the App Store (11.1, 11.8). Purchasing is not, and
/// is not being built for now: with an Android app needed to reach the trades,
/// two in-app purchase systems cost 15–30% and two receipt-verification paths
/// against one web checkout that serves both, and that decision is worth making
/// before the purchase path exists rather than after (11.2–11.7).
///
/// Until then the primary action is present and disabled rather than doing
/// something that looks like buying, and `DebugStepSkip` is what gets past it.
///
/// Nothing in this file writes a currency symbol or formats a number. The only
/// price it can render is `PlanOffer.displayPrice` (D9).
struct PaywallView: View {
    let model: PaywallModel

    /// Set when a request was refused for want of a subscription, so the step
    /// says why it is being shown again rather than reappearing unexplained.
    var entitlementLapsed = false

    /// What to do once billing is satisfied. A closure rather than a reference
    /// to the router, so the screen makes no assumption about what follows it.
    var onSubscribed: () -> Void

    var body: some View {
        StepScaffold(title: "Subscribe to Budj", subtitle: subtitle) {
            content
        } actions: {
            actions
        }
        .task { await model.load() }
    }

    private var subtitle: String {
        if entitlementLapsed {
            "Your subscription is no longer active, so you'll need to start it again before Budj can keep splitting what lands."
        } else {
            "One plan, billed yearly. Budj splits every payment as it arrives, so the money you owe is never money you've already spent."
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: BudjSpacing.regular) {
            if case .loading = model.state {
                HStack(spacing: BudjSpacing.snug) {
                    ProgressView()
                    Text("Loading the price")
                        .font(BudjTypography.body)
                        .foregroundStyle(BudjColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                PlanSummaryCard(offer: model.offer)
            }

            // Required by App Review, and true regardless: Budj has no way to
            // cancel a subscription, so it does not offer to (D9).
            Text("Your subscription renews automatically. You can cancel it in App Store settings.")
                .font(BudjTypography.caption)
                .foregroundStyle(BudjColor.textTertiary)
        }
    }

    @ViewBuilder
    private var actions: some View {
        // Disabled until 11.2 gives it something to do. It is left on screen
        // rather than hidden so the shape of the finished step is visible.
        Button("Subscribe") {}
            .buttonStyle(.budjPrimary)
            .disabled(true)

        if case .priceUnavailable = model.state {
            Button("Try again") { Task { await model.load() } }
                .buttonStyle(.budjSecondary)
        }

        #if DEBUG
        DebugStepSkip(title: "Continue without subscribing", action: onSubscribed)
        #endif
    }
}

#if DEBUG
/// An offer without a store behind it, so the previews render every state.
private struct StubOffers: PlanOfferLoading {
    var stubbed: [PlanOffer] = []
    var fails = false

    func offers(for identifiers: [String]) async throws -> [PlanOffer] {
        if fails { throw CancellationError() }
        return stubbed
    }
}

private let stubbedLoader = StubOffers(stubbed: [
    PlanOffer(
        id: SubscriptionCatalogue.yearly,
        name: "Budj",
        detail: "Every payment split the moment it lands.",
        displayPrice: "$199.00",
        cadence: "year"
    )
])

#Preview("Priced") {
    PaywallView(model: PaywallModel(loader: stubbedLoader)) {}
}

#Preview("Lapsed") {
    PaywallView(model: PaywallModel(loader: stubbedLoader), entitlementLapsed: true) {}
}

#Preview("No price") {
    PaywallView(model: PaywallModel(loader: StubOffers(fails: true))) {}
}
#endif
