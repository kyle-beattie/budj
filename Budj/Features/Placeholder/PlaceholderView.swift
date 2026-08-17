//
//  PlaceholderView.swift
//  Budj
//

import SwiftUI

/// Where `ready` lands until the tabs exist. Nothing here is product surface —
/// it is the mark on the background, so that finishing onboarding lands
/// somewhere deliberate rather than on a blank screen.
struct PlaceholderView: View {
    var body: some View {
        ZStack {
            Color.background
            BudjMark()
                .frame(height: 148)
        }
        .ignoresSafeArea()
        .accessibilityElement()
        .accessibilityLabel("budj.")
    }
}

#Preview {
    PlaceholderView()
}
