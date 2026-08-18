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
              BudjColor.background,
              BudjColor.borderSubtle],
            startPoint: startAnimation ? .topLeading : .bottomLeading,
            endPoint: startAnimation ? .bottomTrailing : .topTrailing
        )
        // Animation to toggle the gradient colors
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever()) {
                startAnimation.toggle()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    BackgroundView()
}
