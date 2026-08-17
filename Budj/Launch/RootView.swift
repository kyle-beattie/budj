//
//  RootView.swift
//  Budj
//

import SwiftUI

/// Holds the launch screen over the app until the first frame has settled,
/// then fades it away.
struct RootView: View {
    private static let holdSeconds = 1.2
    private static let fadeSeconds = 0.35

    @State private var isLaunching = true

    var body: some View {
        ZStack {
            ContentView()
            if isLaunching {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(Self.holdSeconds))
            withAnimation(.easeOut(duration: Self.fadeSeconds)) {
                isLaunching = false
            }
        }
    }  
}

#Preview {
    RootView()
}
