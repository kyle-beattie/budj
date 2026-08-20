//
//  PaywallModelTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

@MainActor
struct PaywallModelTests {

    private static let plan = PlanOffer.stub(
        id: SubscriptionCatalogue.yearly,
        name: "Budj",
        displayPrice: "$199.00",
        cadence: "year"
    )

    @Test func asksForTheOneProductTheServerKnows() async {
        let loader = StubPlanOffers(offers: [Self.plan])
        let model = PaywallModel(loader: loader)

        await model.load()

        // This identifier is the join key the server resolves a submitted
        // transaction back to a plan with. A product the app invents is a
        // purchase the server cannot place.
        #expect(loader.requested == ["com.budj.standard.yearly"])
    }

    @Test func thePriceComesFromTheStore() async {
        let model = PaywallModel(loader: StubPlanOffers(offers: [Self.plan]))

        await model.load()

        #expect(model.state == .loaded(Self.plan))
        #expect(model.offer?.displayPrice == "$199.00")
    }

    @Test func aStoreThatCannotBeAskedLeavesThePriceUnknown() async {
        let model = PaywallModel(loader: StubPlanOffers(error: URLError(.notConnectedToInternet)))

        await model.load()

        // Not a failed screen: the plan exists whether or not the App Store is
        // reachable, so only the price is missing.
        #expect(model.state == .priceUnavailable)
        #expect(model.offer == nil)
    }

    @Test func aStoreThatKnowsNoSuchProductIsTheSameOutcomeAsOneThatRefused() async {
        let model = PaywallModel(loader: StubPlanOffers(offers: []))

        await model.load()

        #expect(model.state == .priceUnavailable)
    }

    @Test func aRetryRecoversThePrice() async {
        let loader = StubPlanOffers(error: URLError(.timedOut))
        let model = PaywallModel(loader: loader)
        await model.load()
        #expect(model.state == .priceUnavailable)

        loader.error = nil
        loader.offers = [Self.plan]
        await model.load()

        #expect(model.state == .loaded(Self.plan))
    }
}
