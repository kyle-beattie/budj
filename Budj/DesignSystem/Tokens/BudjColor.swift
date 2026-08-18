//
//  BudjColor.swift
//  Budj
//

import SwiftUI

/// Every colour the app uses, named for what it is for rather than what it looks
/// like.
///
/// Each one resolves an asset catalogue set with both appearances defined, so a
/// colour has exactly one definition and light mode is impossible to forget.
/// Nothing outside this file names a colour.
enum BudjColor {
    /// The page behind everything.
    static let background = Color.background

    /// A panel sitting on the background — cards, grouped rows.
    static let surface = Color.surface

    /// A surface sitting on a surface — a field inside a card.
    static let raised = Color.raised

    static let textPrimary = Color.textPrimary
    static let textSecondary = Color.textSecondary
    static let textTertiary = Color.textTertiary

    /// The one colour that means "this is the thing to press".
    static let accent = Color.accent

    /// Text and symbols drawn on `accent`. Dark in both appearances, because
    /// the accent is amber in both — a label that flips with the appearance is
    /// unreadable in one of them.
    static let onAccent = Color.onAccent

    /// Something went wrong, or something is about to be destroyed.
    static let danger = Color.danger

    /// Worth reading before continuing, but nothing is broken.
    static let warning = Color.warning

    /// A hairline between things that are the same weight.
    static let borderSubtle = Color.borderSubtle

    /// A border that is doing real work — a focused field, a selected row.
    static let borderStrong = Color.borderStrong
}
