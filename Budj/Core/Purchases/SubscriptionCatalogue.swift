//
//  SubscriptionCatalogue.swift
//  Budj
//

import Foundation

/// The subscription this build asks the App Store about.
///
/// **One plan, deliberately.** Rule and connection counts are a proxy for value
/// rather than value itself: a plan that cannot initiate a transfer is not a
/// cheaper Budj, it is a broken one, and the upstream cost of an open-banking
/// connection is per user rather than per rule. So there is nothing to choose
/// between, and the paywall does not ask.
///
/// This must match the plan catalogue in `budj-server`, which is what resolves a
/// submitted transaction's product back to a plan. A mismatch here is a purchase
/// the server cannot place.
nonisolated enum SubscriptionCatalogue {
    /// The only product. Yearly rather than monthly: the buyer is a business
    /// buying a business tool, the renewal aligns with a tax year, and annual
    /// billing turns the flow's worst churn risk into cash up front.
    static let yearly = "com.budj.standard.yearly"

    static let productIDs = [yearly]
}
