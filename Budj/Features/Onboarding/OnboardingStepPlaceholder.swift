//
//  OnboardingStepPlaceholder.swift
//  Budj
//

import SwiftUI

/// Where a step lands until the step's own screen exists.
///
/// The router can already reach billing, bank and push; the screens are tasks
/// 11.x, 12.x and 13.x. This names the step rather than pretending to be it, so
/// an unbuilt step is visibly unbuilt instead of looking like a broken version
/// of the real thing.
struct OnboardingStepPlaceholder: View {
    let step: OnboardingStep

    /// Set when a request was refused for want of a subscription, so the
    /// billing step says why it is being shown again.
    var entitlementLapsed = false
    @Environment(Authenticator.self) private var authenticator
    @Environment(AppModel.self) private var app
    @State private var isSigningOut = false

    var body: some View {
        StepScaffold(title: title, subtitle: subtitle) {
        } actions: {
          Button("Sign out") { signOut() }
              .buttonStyle(BudjButtonStyle(variant: .secondary, isLoading: isSigningOut))
              .disabled(isSigningOut)
        }
    }

    private var title: String {
        switch step {
        case .billing: "Choose your plan"
        case .bank: "Connect your bank"
        case .push: "Get notified"
        default: "Still being built"
        }
    }

    private var subtitle: String {
        if step == .billing, entitlementLapsed {
            return "Your subscription is no longer active, so you'll need to choose a plan again. This step is still being built."
        }
        return switch step {
        case .billing: "This step is still being built. The server says you're up to choosing a plan."
        case .bank: "This step is still being built. The server says your plan is sorted and your bank is next."
        case .push: "This step is still being built. Your bank is connected, so notifications are the last thing."
        default: "This step is still being built."
        }
    }

    private func signOut() {
        guard !isSigningOut else { return }
        isSigningOut = true
        Task {
            await authenticator.signOut()
            isSigningOut = false
            app.signedOut()
        }
    }
}



#Preview("Billing") {
    OnboardingStepPlaceholder(step: .billing)
}

#Preview("Billing, lapsed") {
    OnboardingStepPlaceholder(step: .billing, entitlementLapsed: true)
}

#Preview("Bank") {
    OnboardingStepPlaceholder(step: .bank)
}
