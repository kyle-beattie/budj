//
//  RootView.swift
//  Budj
//

import SwiftUI

/// Holds the launch screen over the app while it works out where to start, then
/// shows whatever `AppModel` resolved.
struct RootView: View {
    /// A floor rather than a delay: the launch screen is dismissed when the work
    /// is done or this has elapsed, whichever is later, so a fast path does not
    /// flash rather than being padded to a fixed interval.
    private static let minimumHold: Duration = .milliseconds(600)

    @Environment(AppModel.self) private var app
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
            app.start()
            try? await floor
            isLaunching = false
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch app.phase {
        case .launching:
            // Nothing behind the launch screen yet; the mark is already there.
            BudjColor.background.ignoresSafeArea()
        case .onboarding:
            OnboardingEntryView()
        case .ready:
            PlaceholderView()
        case .mustUpdate:
            MustUpdateView()
        }
    }
}

#Preview {
    RootView()
        .environment(AppModel(session: SessionStore()))
}
