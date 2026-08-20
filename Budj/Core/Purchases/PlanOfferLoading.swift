//
//  PlanOfferLoading.swift
//  Budj
//

import Foundation

/// The seam between the paywall and StoreKit.
///
/// It exists so `PaywallModel` can be exercised without a store: `SKTestSession`
/// needs a running StoreKit environment, which a Swift Testing suite over a pure
/// model should not have to stand up. The real implementation is
/// `StoreKitPlanOffers`.
protocol PlanOfferLoading: Sendable {
    /// Offers for the given product identifiers, in the order requested.
    ///
    /// Identifiers the store does not know are dropped rather than reported: a
    /// product still propagating through App Store Connect is not a reason to
    /// show nobody a paywall.
    func offers(for identifiers: [String]) async throws -> [PlanOffer]
}
