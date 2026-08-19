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
struct BudjLogo: View {
    let height: CGFloat

    let stemShape = BudjMarkShape(layer: .stem)
    let backCoinShape = BudjMarkShape(layer: .backCoin)
    let frontCoinShape = BudjMarkShape(layer: .frontCoin)

    var body: some View {
      ZStack {
        BudjMarkShape(layer: .stem)
          .fill(Color.markStem)
        BudjMarkShape(layer: .backCoin)
          .fill(Color.markBackCoin.opacity(0.8))
        BudjMarkShape(layer: .frontCoin)
          .fill(Color.markFrontCoin)


        Rectangle()
            .fill(.clear)
            .glassEffect(.clear, in: stemShape)
            .frame(height: height)
//        Rectangle()
//            .fill(.clear)
//            .glassEffect(.clear, in: backCoinShape)
//            .frame(height: height)
        Rectangle()
            .fill(.clear)
            .glassEffect(.clear, in: frontCoinShape)
            .frame(height: height)
      }
      .aspectRatio(BudjMarkShape.aspectRatio, contentMode: .fit)
      .accessibilityHidden(true)
      .frame(height: height)
    }
}

extension Color {
    static let markStem = Color(red: 0, green: 0.773, blue: 0.980)
    static let markBackCoin = Color(red: 1, green: 0.718, blue: 0)
    static let markFrontCoin = Color(red: 0, green: 0.929, blue: 0.604)
}

#Preview {
    BudjLogo(height: 160)
        .padding(64)
}
