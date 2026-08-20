//
//  GlassWaveView.swift
//  Budj
//
//  Created by Kyle Beattie on 20/08/2026.
//

import SwiftUI

struct WaveShape: Shape {
    var offset: Double
    var strength: Double = 15.0
    var frequency: Double = 0.5

    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // The wave is the bottom edge of the shape: the fill runs from the top
        // of the rect down to the sine curve, so the view can sit at the top
        // of the screen with the waves breaking downwards into the content.
        let baseline = rect.minY

        path.move(to: CGPoint(x: 0, y: baseline))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * width * frequency * .pi / 180 + offset)
            let y = height / 2 + strength * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: baseline))
        path.addLine(to: CGPoint(x: 0, y: baseline))
        path.closeSubpath()

        return path
    }
}


struct GlassWaveView: View {
  @State private var waveOffset = 0.0
  @State private var timer: Timer?

  let isAnimating: Bool

  var body: some View {
    ZStack {
      VStack {

        ZStack {
          WaveShape(offset: waveOffset)
            .fill(BudjColor.blue)
            .frame(height: 200)
            .blur(radius: 10)


          WaveShape(offset: waveOffset * 1.5)
            .fill(BudjColor.accent)
            .frame(height: 100)
            .blur(radius: 5)

          WaveShape(offset: waveOffset * 3)
            .offset(x: 0, y: -15)
            .fill(BudjColor.mint)
            .frame(height: 200)
            .blur(radius: 3)
        }
        Spacer()
      }
      .ignoresSafeArea(edges: .top)
    }
    .onAppear {
      if isAnimating {
        startWave()
      }
    }
    .onDisappear {
      stopWave()
    }
    .onChange(of: isAnimating) { _, newValue in
      if newValue {
        startWave()
      } else {
        stopWave()
        withAnimation(.easeOut(duration: 2.0)) {
          waveOffset = -1.4
        }
      }
    }
  }

  func startWave() {
    stopWave()
    timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
      waveOffset += 0.01
    }
  }

  func stopWave() {
    timer?.invalidate()
    timer = nil
  }
}

#Preview("GlassWaveView") {
  GlassWaveView(isAnimating: true)
}


struct HeaderView: View {
  @State private var isAnimating: Bool = true

  var body: some View {
    ZStack {
      GlassWaveView(isAnimating: isAnimating)
    }
  }

  private func toggleAnimation() {
    isAnimating = !isAnimating
  }
}

#Preview("HeaderView") {
  HeaderView()
}

