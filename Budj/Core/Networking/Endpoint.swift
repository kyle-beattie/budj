//
//  Endpoint.swift
//  Budj
//

import Foundation

/// One request, described rather than constructed.
///
/// An `Endpoint` carries no headers and knows nothing about authorisation or
/// the build number — `BudjAPI` applies both, so there is no per-call
/// opportunity to omit either.
nonisolated struct Endpoint {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    let method: Method
    let path: String
    let query: [URLQueryItem]

    /// Whether the request carries the user's bearer token. Sign-in and
    /// registration are the only routes that do not.
    let requiresAuthorization: Bool

    /// Deferred so that the client owns the encoder, rather than each call site
    /// configuring one and eventually configuring one differently.
    let encodeBody: ((JSONEncoder) throws -> Data)?

    static func get(
        _ path: String,
        query: [URLQueryItem] = [],
        requiresAuthorization: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: .get,
            path: path,
            query: query,
            requiresAuthorization: requiresAuthorization,
            encodeBody: nil
        )
    }

    static func post(
        _ path: String,
        requiresAuthorization: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: .post,
            path: path,
            query: [],
            requiresAuthorization: requiresAuthorization,
            encodeBody: nil
        )
    }

    static func post(
        _ path: String,
        body: some Encodable,
        requiresAuthorization: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: .post,
            path: path,
            query: [],
            requiresAuthorization: requiresAuthorization,
            encodeBody: { try $0.encode(body) }
        )
    }

    static func patch(
        _ path: String,
        body: some Encodable,
        requiresAuthorization: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: .patch,
            path: path,
            query: [],
            requiresAuthorization: requiresAuthorization,
            encodeBody: { try $0.encode(body) }
        )
    }

    static func delete(
        _ path: String,
        requiresAuthorization: Bool = true
    ) -> Endpoint {
        Endpoint(
            method: .delete,
            path: path,
            query: [],
            requiresAuthorization: requiresAuthorization,
            encodeBody: nil
        )
    }
}
