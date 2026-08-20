//
//  BackgroundView.swift
//  Budj
//
//  Created by Kyle Beattie on 18/08/2026.
//

import SwiftUI

struct BackgroundView: View {
    @State private var startAnimation: Bool = false

    var body: some View {
        // Animated background using ZStack and LinearGradient

        LinearGradient(
            colors: [
              .black,
              .white
            ],
            startPoint: startAnimation ? .topLeading : .bottomLeading,
            endPoint: startAnimation ? .bottomTrailing : .topTrailing
        )
        .blendMode(.overlay)
        .opacity(0.3)

        // Animation to toggle the gradient colors
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever()) {
                startAnimation.toggle()
            }
        }
        .ignoresSafeArea()
        .background(BudjColor.background)
    }
}

#Preview {
    BackgroundView()
}
