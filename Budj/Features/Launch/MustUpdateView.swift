//
//  MustUpdateView.swift
//  Budj
//

import SwiftUI

/// Shown when the server has stopped serving this build.
///
/// Terminal on purpose: there is no dismissal, because every request this app
/// makes will now be refused. And it says the app must be updated rather than
/// that Budj is unavailable — someone told the wrong one of those waits for an
/// outage to end that is never going to end.
struct MustUpdateView: View {
    @Environment(\.openURL) private var openURL

    private static let appStoreURL = URL(string: "https://apps.apple.com/nz/app/budj/id0")!

    var body: some View {
        StepScaffold(
            title: "Update Budj to continue",
            subtitle: "This version is no longer supported. Install the latest one from the App Store."
        ) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 56))
                .foregroundStyle(BudjColor.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BudjSpacing.section)
                .accessibilityHidden(true)
        } actions: {
            Button("Open the App Store") { openURL(Self.appStoreURL) }
                .buttonStyle(.budjPrimary)
        }
    }
}

#Preview {
    MustUpdateView()
}
