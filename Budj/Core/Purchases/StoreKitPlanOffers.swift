//
//  StoreKitPlanOffers.swift
//  Budj
//

import Foundation
import StoreKit

/// `PlanOfferLoading` over StoreKit 2.
///
/// The whole of the app's contact with `Product` is here, so `displayPrice`
/// cannot be bypassed somewhere else: nothing downstream is given a number to
/// format (D9).
///
/// In a debug build this reads Xcode's StoreKit configuration file rather than
/// the App Store, so the paywall can be exercised in the simulator with no App
/// Store Connect record, no sandbox account, and no money. See `Budj.storekit`.
nonisolated struct StoreKitPlanOffers: PlanOfferLoading {
    func offers(for identifiers: [String]) async throws -> [PlanOffer] {
        let products = try await Product.products(for: identifiers)

        // Requested order, not the order the store answered in — the paywall's
        // ordering is a design decision and StoreKit makes no promise about its
        // own.
        return identifiers.compactMap { identifier in
            guard let product = products.first(where: { $0.id == identifier }) else { return nil }
            return PlanOffer(
                id: product.id,
                name: product.displayName,
                detail: product.description,
                displayPrice: product.displayPrice,
                cadence: Self.cadence(of: product.subscription?.subscriptionPeriod)
            )
        }
    }

    /// The renewal period as a noun — "month", "3 months".
    ///
    /// Spelled out here rather than taken from `Unit.localizedDescription` so
    /// the plural agrees with the value, which that property has no way to know.
    private static func cadence(of period: Product.SubscriptionPeriod?) -> String? {
        guard let period else { return nil }

        let unit: String? = switch period.unit {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        // A period this build has never heard of is left unsaid rather than
        // guessed at — the price is still correct without it.
        @unknown default: nil
        }

        guard let unit else { return nil }
        return period.value == 1 ? unit : "\(period.value) \(unit)s"
    }
}
