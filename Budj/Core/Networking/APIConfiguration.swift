//
//  APIConfiguration.swift
//  Budj
//

import Foundation

/// Where the app's server lives, fixed at build time.
///
/// The value comes from the `BUDJ_API_BASE_URL` build setting by way of
/// `Info.plist`, so a debug build can be pointed at a server running on this
/// machine without touching source, and a release build cannot be redirected at
/// runtime by anything at all.
nonisolated struct APIConfiguration {
    let baseURL: URL

    static let current = read(from: Bundle.main)

    static func read(from bundle: some InfoValues) -> APIConfiguration {
        let raw = bundle.stringValue(forInfoKey: "BudjAPIBaseURL")
        // A trailing slash here and a leading slash on every path would produce
        // `//api/...`, which the server does not route.
        let trimmed = raw.map { $0.hasSuffix("/") ? String($0.dropLast()) : $0 }
        guard let trimmed, let url = URL(string: trimmed), url.scheme != nil else {
            preconditionFailure("BUDJ_API_BASE_URL is missing or not a URL: \(raw ?? "nothing")")
        }
        return APIConfiguration(baseURL: url)
    }
}
