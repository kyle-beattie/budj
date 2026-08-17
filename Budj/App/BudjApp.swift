//
//  BudjApp.swift
//  Budj
//
//  Created by Kyle Beattie on 05/08/2026.
//

import SwiftUI

@main
struct BudjApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
            .onOpenURL { url in
              // Your deep-link handling logic lives here
              print("App opened via URL: \(url)")
            }
        }
    }
}
