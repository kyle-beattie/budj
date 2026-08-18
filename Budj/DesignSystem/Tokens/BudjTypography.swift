//
//  BudjTypography.swift
//  Budj
//

import SwiftUI

/// The type roles, mapped onto Dynamic Type text styles.
///
/// The system font throughout, and no fixed point sizes — a hard-coded size
/// ignores the type size a person chose in Settings, which is the single most
/// common accessibility failure in an iOS app.
enum BudjTypography {
    /// The one line at the top of a screen.
    static let display = Font.largeTitle.weight(.semibold)
    /// A step's title.
    static let headline = Font.title2.weight(.semibold)
    /// A group's heading within a screen.
    static let title = Font.headline
    /// Running text.
    static let body = Font.body
    /// Supporting text under a field or an action.
    static let caption = Font.footnote
    /// The text on a control.
    static let label = Font.body.weight(.semibold)
    /// Small, tracked, uppercase — badges and eyebrows, and nowhere else.
    static let badge = Font.caption2.weight(.semibold)
}
