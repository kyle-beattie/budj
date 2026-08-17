//
//  LaunchScreenView.swift
//  Budj
//

import SwiftUI

/// The first thing you see. Matches the system launch screen — which is a flat
/// `BackgroundColor` fill — and adds the app mark, so the handover is seamless.
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.background
            AnimatingBudjMarkShape()
                .frame(height: 148)
        }
        .ignoresSafeArea()
        .accessibilityElement()
        .accessibilityLabel("budj.")
    }
}

#Preview {
    LaunchScreenView()
}
