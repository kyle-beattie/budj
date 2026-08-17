//
//  RecordingInterruptionHandler.swift
//  BudjTests
//

import Foundation
@testable import Budj

/// Stands in for whatever owns the app's phase, and remembers what it was told.
@MainActor
final class RecordingInterruptionHandler: APIInterruptionHandler {
    private(set) var interruptions: [APIInterruption] = []

    func handle(_ interruption: APIInterruption) {
        interruptions.append(interruption)
    }
}
