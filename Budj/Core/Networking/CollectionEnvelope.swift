//
//  CollectionEnvelope.swift
//  Budj
//

import Foundation

/// The shape every collection arrives in: the items under `data`, and — where
/// the endpoint paginates — its metadata under `meta`.
///
/// Decoding the metadata alongside the items is what lets a caller tell a full
/// page from the last one without counting what it received.
nonisolated struct CollectionEnvelope<Element: Decodable>: Decodable {
    let data: [Element]
    let meta: Pagination?
}
