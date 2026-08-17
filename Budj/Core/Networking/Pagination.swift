//
//  Pagination.swift
//  Budj
//

import Foundation

/// A paginated collection's `meta`.
nonisolated struct Pagination: Decodable, Equatable, Sendable {
    let total: Int
    let limit: Int
    let offset: Int
}
