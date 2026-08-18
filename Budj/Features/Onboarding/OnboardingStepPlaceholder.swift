//
//  OnboardingStepPlaceholder.swift
//  Budj
//

import SwiftUI

/// Where a resumed onboarding step lands until the step's own screen exists.
///
/// The launch gate can already route to `billing` and `bank`; the screens are
/// tasks 9.3, 11.x and 12.x. This names the step rather than pretending to be
/// it, so an unbuilt step is visibly unbuilt instead of looking like a broken
/// version of the real thing.
struct OnboardingStepPlaceholder: View {
    let step: OnboardingStatus.Step

    var body: some View {
        StepScaffold(title: title, subtitle: subtitle) {
        } actions: {
        }
    }

    private var title: String {
        switch step {
        case .billing: "Choose your plan"
        case .bank: "Connect your bank"
        case .ready: "You're set up"
        }
    }

    private var subtitle: String {
        switch step {
        case .billing: "This step is still being built. The server says you're up to choosing a plan."
        case .bank: "This step is still being built. The server says your plan is sorted and your bank is next."
        case .ready: "This step is still being built."
        }
    }
}

#Preview("Billing") {
    OnboardingStepPlaceholder(step: .billing)
}

#Preview("Bank") {
    OnboardingStepPlaceholder(step: .bank)
}
