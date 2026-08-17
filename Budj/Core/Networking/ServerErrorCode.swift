//
//  ServerErrorCode.swift
//  Budj
//

import Foundation

/// The error codes the contract publishes, spelled exactly as the server sends
/// them.
///
/// Case is part of the identifier: a code compared case-insensitively would
/// match something the server never said. Anything not listed here is not
/// invented by the app — it degrades to a general server failure.
nonisolated enum ServerErrorCode: String {
    case unauthorized = "UNAUTHORIZED"
    case subscriptionRequired = "SUBSCRIPTION_REQUIRED"
    case planLimitExceeded = "PLAN_LIMIT_EXCEEDED"
    case clientUpdateRequired = "CLIENT_UPDATE_REQUIRED"
    case clientBuildBlocked = "CLIENT_BUILD_BLOCKED"
}

/// The header the server reads the build number from, spelled as the contract
/// spells it.
nonisolated enum ClientBuildHeader {
    static let name = "x-client-build"
}
