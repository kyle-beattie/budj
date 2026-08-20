//
//  PlanOffer.swift
//  Budj
//

import Foundation

/// One purchasable plan, reduced to what the paywall renders.
///
/// `displayPrice` is carried as a string because that is what StoreKit hands
/// over, already localised and already carrying the storefront's currency. There
/// is deliberately no numeric price and no currency code on this type: a price
/// the app can do arithmetic on is a price the app will eventually format, and a
/// paywall that disagrees with the App Store sheet is a review rejection (D9).
nonisolated struct PlanOffer: Identifiable, Equatable, Sendable {
    /// The App Store product identifier, which is also the join key the server's
    /// plan catalogue uses.
    let id: String

    let name: String
    let detail: String

    /// Exactly `Product.displayPrice`. Never constructed.
    let displayPrice: String

    /// How often that price recurs — "month", "year". Nil for a product with no
    /// subscription period, which none of ours are, but the type does not need
    /// to insist on that.
    let cadence: String?
}
