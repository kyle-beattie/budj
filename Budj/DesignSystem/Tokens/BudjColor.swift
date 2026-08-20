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
  static let mint = Color.mint
  static let blue = Color.blue

  static let bankNoteFiveLight = Color("BankNotes/Five/Light")
  static let bankNoteFiveMed = Color("BankNotes/Five/Med")
  static let bankNoteFiveDark = Color("BankNotes/Five/Dark")

  static let bankNoteTenLight = Color("BankNotes/Ten/Light")
  static let bankNoteTenMed = Color("BankNotes/Ten/Med")
  static let bankNoteTenDark = Color("BankNotes/Ten/Dark")

  static let bankNoteTwentyLight = Color("BankNotes/Twenty/Light")
  static let bankNoteTwentyMed = Color("BankNotes/Twenty/Med")
  static let bankNoteTwentyDark = Color("BankNotes/Twenty/Dark")

  static let bankNoteFiftyLight = Color("BankNotes/Fifty/Light")
  static let bankNoteFiftyMed = Color("BankNotes/Fifty/Med")
  static let bankNoteFiftyDark = Color("BankNotes/Fifty/Dark")

  static let bankNoteHundredLight = Color("BankNotes/Hundred/Light")
  static let bankNoteHundredMed = Color("BankNotes/Hundred/Med")
  static let bankNoteHundredDark = Color("BankNotes/Hundred/Dark")
}
