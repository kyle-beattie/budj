//
//  ContentView.swift
//  Budj
//
//  Created by Kyle Beattie on 05/08/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      Color.background.ignoresSafeArea()
      .overlay(
        VStack {
          Image(systemName: "globe")
            .imageScale(.large)
            .foregroundStyle(.tint)
          Text("Hello, world!")
        }
      )
  }
}

#Preview {
    ContentView()
}
