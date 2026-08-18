//
//  RootView.swift
//  Budj
//

import SwiftUI

/// Holds the launch screen over the launch gate's work, then shows whatever it
/// resolved.
struct RootView: View {
    /// A floor rather than a delay: the launch screen is dismissed when the work
    /// is done or this has elapsed, whichever is later, so a fast path does not
    /// flash rather than being padded to a fixed interval. A slow one is not cut
    /// short — nothing renders a step the gate has not resolved.
    private static let minimumHold: Duration = .milliseconds(600)

    @Environment(AppModel.self) private var app
    @Environment(EmailConfirmationModel.self) private var confirmation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isLaunching = true

    var body: some View {
        ZStack {
            destination
            if isLaunching {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .animation(BudjMotion.transition, value: isLaunching)
        .animation(reduceMotion ? .none : BudjMotion.transition, value: app.phase)
        .task {
            async let floor: Void = Task.sleep(for: Self.minimumHold)
            await app.start()
            try? await floor
            isLaunching = false
        }
        // Presented here rather than from the sign-in screen: the confirmation
        // link can arrive on a cold start, by which point the screen that
        // started the flow has never been shown (D17).
        .sheet(isPresented: isShowingConfirmation) {
            ConfirmEmailSheet(model: confirmation, onClose: closeConfirmation)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(BudjRadius.extraLarge)
                .presentationBackground(BudjColor.background)
                .animation(BudjMotion.springy, value: confirmation.phase)
        }
    }

    // MARK: - Confirmation

    private var isShowingConfirmation: Binding<Bool> {
        Binding(
            get: { confirmation.isPresented },
            // A swipe closes it the same way the button does, so a confirmed
            // session is not stranded behind a gesture.
            set: { if !$0 { closeConfirmation() } }
        )
    }

    /// One exit for the sheet. Closing it after a successful confirmation means
    /// signing in — the session already exists, so this asks the gate where it
    /// lands rather than picking a step itself.
    private func closeConfirmation() {
        let didConfirm = confirmation.didConfirm
        confirmation.dismiss()
        guard didConfirm else { return }
        Task { await app.signedIn() }
    }

    @ViewBuilder
    private var destination: some View {
        switch app.phase {
        case .launching:
            // Nothing behind the launch screen yet; the mark is already there.
            BudjColor.background.ignoresSafeArea()
        case .onboarding:
            OnboardingFlowView(model: app.onboarding)
        case .ready:
            PlaceholderView()
        case .unreachable:
            UnreachableView()
        case .mustUpdate:
            MustUpdateView()
        }
    }
}

//#Preview {
//    RootView()
//        .environment(AppModel.preview())
//}
