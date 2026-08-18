//
//  Registration.swift
//  Budj
//

import Foundation

/// What creating an account produced.
///
/// The session is absent when the Supabase project requires the address to be
/// confirmed first, which is why `confirmationRequired` is published separately
/// rather than inferred from a missing session — an app that guesses shows
/// "something went wrong" to someone whose account was created perfectly.
nonisolated struct Registration: Decodable, Equatable, Sendable {
    let session: BudjSession?
    let confirmationRequired: Bool
}
