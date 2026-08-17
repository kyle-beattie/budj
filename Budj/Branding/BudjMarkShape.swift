//
//  BudjMarkShape.swift
//  Budj
//

import SwiftUI

/// The individual shapes that make up the Budj lettermark.
///
/// Geometry is transcribed from the vector layers in `budj.icon`, which are
/// authored on a 1024×1024 canvas. The two coins carry the `translation-in-points`
/// offsets declared in `icon.json` (y is measured downwards, matching SwiftUI).
struct BudjMarkShape: Shape {
    enum Layer {
        /// The blue "b" — a rounded stem falling into a bowl.
        case stem
        /// The coin sitting behind, offset to the left.
        case backCoin
        /// The coin sitting in front.
        case frontCoin
    }

    let layer: Layer

    /// The bounding box of the composed mark within the icon's 1024pt canvas.
    static let designBounds = CGRect(x: 241, y: 176, width: 590, height: 672)

    /// Width-to-height ratio of the composed mark, for `aspectRatio(_:contentMode:)`.
    static var aspectRatio: CGFloat { designBounds.width / designBounds.height }

    func path(in rect: CGRect) -> Path {
        designPath.applying(transform(for: rect))
    }

    private var designPath: Path {
        switch layer {
        case .stem: Self.stemPath
        case .backCoin: Self.coinPath(centerX: 643.5)
        case .frontCoin: Self.coinPath(centerX: 671.5)
        }
    }

    /// Fits the design canvas into `rect`, preserving the mark's aspect ratio.
    private func transform(for rect: CGRect) -> CGAffineTransform {
        let bounds = Self.designBounds
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        let x = rect.midX - bounds.midX * scale
        let y = rect.midY - bounds.midY * scale
        return CGAffineTransform(translationX: x, y: y).scaledBy(x: scale, y: scale)
    }

    private static func coinPath(centerX: CGFloat) -> Path {
        let radius: CGFloat = 159.5
        let center = CGPoint(x: centerX, y: 688.5)
        return Path(
            ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
    }

    private static let stemPath: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 372.5, y: 176))
        path.addCurve(
            to: CGPoint(x: 504, y: 307.5),
            control1: CGPoint(x: 445.125, y: 176),
            control2: CGPoint(x: 504, y: 234.875)
        )
        path.addLine(to: CGPoint(x: 504, y: 413.311))
        path.addCurve(
            to: CGPoint(x: 680, y: 628.5),
            control1: CGPoint(x: 604.39, y: 433.493),
            control2: CGPoint(x: 680, y: 522.167)
        )
        path.addCurve(
            to: CGPoint(x: 460.5, y: 848),
            control1: CGPoint(x: 680, y: 749.727),
            control2: CGPoint(x: 581.727, y: 848)
        )
        path.addCurve(
            to: CGPoint(x: 242.087, y: 650.479),
            control1: CGPoint(x: 346.691, y: 848),
            control2: CGPoint(x: 253.113, y: 761.385)
        )
        path.addCurve(
            to: CGPoint(x: 241, y: 633.5),
            control1: CGPoint(x: 241.37, y: 644.92),
            control2: CGPoint(x: 241, y: 639.253)
        )
        path.addLine(to: CGPoint(x: 241, y: 307.5))
        path.addCurve(
            to: CGPoint(x: 372.5, y: 176),
            control1: CGPoint(x: 241, y: 234.875),
            control2: CGPoint(x: 299.875, y: 176)
        )
        path.closeSubpath()
        return path
    }()
}


struct AnimatingBudjMarkShape: View {
    @State private var pulse: CGFloat = 1
    @State private var opacity: CGFloat = 1
    @State private var backCoinColor = Color.markBackCoin.opacity(0.8)
    @State private var frontCoinColor = Color.mint

    var body: some View {
      ZStack {
          BudjMarkShape(layer: .stem)
              .fill(Color.markStem)
          BudjMarkShape(layer: .backCoin)
              .fill(backCoinColor)
              .frame(height: 148)
              .offset(x: pulse, y: 0)
              .opacity(opacity)
              .onAppear{
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    pulse = 10
                    opacity = 0.8;
                  backCoinColor = Color.mint
                  }
              }
          BudjMarkShape(layer: .frontCoin)
              .fill(frontCoinColor)
              .frame(height: 148)
              .offset(x: -pulse, y: 0)
              .opacity(opacity)
              .onAppear{
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    pulse = -10
                    opacity = 0.8;
                    frontCoinColor = Color.markBackCoin.opacity(0.8)
                  }
              }
      }
      .aspectRatio(BudjMarkShape.aspectRatio, contentMode: .fit)
      .accessibilityHidden(true)
    }
}

struct AnimatingBudjMarkShape_Previews: PreviewProvider {
    static var previews: some View {
      AnimatingBudjMarkShape()
    }
}
