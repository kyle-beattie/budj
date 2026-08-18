//
//  BudjRadius.swift
//  Budj
//

import CoreGraphics

/// The corner radii, and the whole list of them.
///
/// The system is full-radius: buttons and pills are fully rounded, cards and
/// sheets are generously rounded. Nothing in the app is square, and nothing is
/// barely-rounded — a 4pt corner reads as an accident.
enum BudjRadius {
    /// 12 — small controls and inline chips.
    static let small: CGFloat = 12
    /// 20 — text fields and list rows.
    static let medium: CGFloat = 20
    /// 28 — cards.
    static let large: CGFloat = 28
    /// 32 — sheets and full-width panels.
    static let extraLarge: CGFloat = 32
}
