//
//  SupabaseConfiguration.swift
//  Budj
//

import Foundation

/// Where Supabase lives, and the publishable key that identifies this project
/// to it.
///
/// The app talks to Supabase at exactly one endpoint — the id-token exchange in
/// `SupabaseIdentity` — so this is deliberately not a general client
/// configuration (D16). Everything else goes through the Budj server.
///
/// The anon key is a publishable identifier rather than a credential: it grants
/// nothing on its own and is designed to ship inside clients. No service-role
/// key ever goes near this app.
nonisolated struct SupabaseConfiguration {
    let baseURL: URL
    let anonKey: String

    static let current = read(from: Bundle.main)

    static func read(from bundle: some InfoValues) -> SupabaseConfiguration? {
        guard
            let rawURL = bundle.stringValue(forInfoKey: "BudjSupabaseURL"),
            let key = bundle.stringValue(forInfoKey: "BudjSupabaseAnonKey"),
            !key.isEmpty
        else { return nil }

        let trimmed = rawURL.hasSuffix("/") ? String(rawURL.dropLast()) : rawURL
        guard let url = URL(string: trimmed), url.scheme != nil else { return nil }

        return SupabaseConfiguration(baseURL: url, anonKey: key)
    }
}
