//
//  ContentView.swift
//  Budj
//
//  Created by Kyle Beattie on 05/08/2026.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
  @State private var authorizationResult: ASAuthorization? = nil
  @State private var error: Error? = nil
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
      ZStack {
          Color.background
          VStack {
            BudjMark()
              .frame(height: 148)

        }
      }
      .ignoresSafeArea()
      .accessibilityElement()
      .accessibilityLabel("budj.")
  }
}

#Preview {
    ContentView()
}

