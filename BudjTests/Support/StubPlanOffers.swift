//
//  StubPlanOffers.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// A `PlanOfferLoading` with no store behind it.
///
/// StoreKit's own test seam, `SKTestSession`, needs a running StoreKit
/// environment; `PaywallModel` is a pure model and should not need one to be
/// exercised.
///
/// A class rather than a struct so a test can change what the store answers
/// between two loads, which is what a retry and a withdrawn product look like.
final class StubPlanOffers: PlanOfferLoading, @unchecked Sendable {
    private let lock = NSLock()
    private var _offers: [PlanOffer]
    private var _error: (any Error)?
    private var _requested: [String]?

    init(offers: [PlanOffer] = [], error: (any Error)? = nil) {
        self._offers = offers
        self._error = error
    }

    /// What the store will answer next.
    var offers: [PlanOffer] {
        get { lock.withLock { _offers } }
        set { lock.withLock { _offers = newValue } }
    }

    var error: (any Error)? {
        get { lock.withLock { _error } }
        set { lock.withLock { _error = newValue } }
    }

    /// The identifiers the model asked for, so a test can assert it asked for
    /// the catalogue rather than a list of its own.
    var requested: [String]? { lock.withLock { _requested } }

    func offers(for identifiers: [String]) async throws -> [PlanOffer] {
        lock.withLock { _requested = identifiers }
        if let error { throw error }
        return offers
    }
}

extension PlanOffer {
    static func stub(
        id: String = SubscriptionCatalogue.yearly,
        name: String = "Budj",
        detail: String = "Every payment split the moment it lands.",
        displayPrice: String = "$199.00",
        cadence: String? = "year"
    ) -> PlanOffer {
        PlanOffer(id: id, name: name, detail: detail, displayPrice: displayPrice, cadence: cadence)
    }
}
