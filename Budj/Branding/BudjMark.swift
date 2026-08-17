//
//  BudjMark.swift
//  Budj
//

import SwiftUI

/// The Budj app mark, drawn as vectors so it stays crisp at any size.
///
/// This is the artwork from `budj.icon` without its rounded-square tile — the
/// tile's fill and `BackgroundColor` are all but identical in both appearances,
/// so the mark reads as the app icon floating on the app background.
struct BudjMark: View {
    var body: some View {
        ZStack {
            BudjMarkShape(layer: .stem)
                .fill(Color.markStem)                
            BudjMarkShape(layer: .backCoin)
                .fill(Color.markBackCoin.opacity(0.8))
            BudjMarkShape(layer: .frontCoin)
                .fill(Color.markFrontCoin)
        }
        .aspectRatio(BudjMarkShape.aspectRatio, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

extension Color {
    static let markStem = Color(red: 0, green: 0.773, blue: 0.980)
    static let markBackCoin = Color(red: 1, green: 0.718, blue: 0)
    static let markFrontCoin = Color(red: 0, green: 0.929, blue: 0.604)
}

#Preview {
    BudjMark()
        .frame(height: 160)
        .padding(64)
        .background(Color.background)
}
