//
//  BudjSpacing.swift
//  Budj
//

import CoreGraphics

/// The 4pt scale, named rather than numeric.
///
/// Nothing in the app uses a spacing value that is not on this list. A number
/// typed into a `padding` is a value nobody chose and nobody can change
/// consistently later.
enum BudjSpacing {
    /// 4 — between a label and the thing it labels.
    static let hair: CGFloat = 4
    /// 8 — inside a control.
    static let tight: CGFloat = 8
    /// 12 — between rows of a list.
    static let snug: CGFloat = 12
    /// 16 — the default gap, and the screen's side margin on compact widths.
    static let regular: CGFloat = 16
    /// 24 — between groups within a section.
    static let loose: CGFloat = 24
    /// 32 — between sections.
    static let section: CGFloat = 32
    /// 48 — above a screen's first element, below its last.
    static let screen: CGFloat = 48
}
