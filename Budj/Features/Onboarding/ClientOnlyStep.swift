//
//  ClientOnlyStep.swift
//  Budj
//

import Foundation

/// The two steps the server has no opinion on.
///
/// Both are permission prompts, and both are asked exactly once. A declined
/// permission asked again on every launch is hostile, and for notifications the
/// system will not re-prompt in any case — so an app that keeps offering is an
/// app showing a button that cannot work.
nonisolated enum ClientOnlyStep: String, CaseIterable, Sendable {
    case biometrics
    case push
}
