//
//  PaywallModel.swift
//  Budj
//

import Foundation
import Observation

/// What the paywall knows: the price, or that it could not be fetched.
///
/// There is one plan, so there is nothing to select and no selection state. What
/// the plan *is* — its name and what it includes — is Budj's own fact and lives
/// on the screen; the only thing this fetches is the price string, because that
/// is Apple's to state rather than ours (D9).
///
/// It deliberately stops there. Purchasing, submitting the signed transaction
/// and re-fetching status are tasks 11.2–11.5, which are **paused** pending the
/// decision between App Store billing and web billing — running two in-app
/// purchase systems for an iOS and an Android app costs 15–30% and two
/// verification paths, and that call is worth making before the purchase path is
/// built rather than after.
@Observable
final class PaywallModel {
    enum State: Equatable {
        case loading
        case loaded(PlanOffer)
        /// The store could not be asked. The plan is still shown — it exists
        /// whether or not the App Store is reachable — but without a price.
        case priceUnavailable
    }

    private(set) var state: State = .loading

    private let loader: any PlanOfferLoading
    private let identifier: String

    init(
        loader: (any PlanOfferLoading)? = nil,
        identifier: String = SubscriptionCatalogue.yearly
    ) {
        // Not a default argument: those are evaluated in a nonisolated context.
        self.loader = loader ?? StoreKitPlanOffers()
        self.identifier = identifier
    }

    var offer: PlanOffer? {
        if case let .loaded(offer) = state { return offer } else { return nil }
    }

    func load() async {
        state = .loading
        do {
            // A store that answers with nothing is a store that could not tell
            // us the price, which is the same outcome as one that refused.
            guard let offer = try await loader.offers(for: [identifier]).first else {
                state = .priceUnavailable
                return
            }
            state = .loaded(offer)
        } catch {
            state = .priceUnavailable
        }
    }
}
