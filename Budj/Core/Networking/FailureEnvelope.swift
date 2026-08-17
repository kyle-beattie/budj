//
//  FailureEnvelope.swift
//  Budj
//

import Foundation

/// The shape every failing response arrives in: `{ "error": { code, message,
/// details? } }`.
///
/// A failure that does not match this is a decoding failure, not a success —
/// the one reading that must never be silently forgiving.
nonisolated struct FailureEnvelope: Decodable {
    let error: Failure

    struct Failure: Decodable {
        let code: String
        let message: String

        /// `details` is untyped in the contract and only `PLAN_LIMIT_EXCEEDED`
        /// currently carries a shape the app reads. A payload that does not
        /// match leaves this `nil` rather than failing the whole envelope: the
        /// code and message are what the app acts on.
        let planLimit: PlanLimit?

        private enum CodingKeys: String, CodingKey {
            case code, message, details
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            code = try container.decode(String.self, forKey: .code)
            message = try container.decode(String.self, forKey: .message)
            planLimit = try? container.decodeIfPresent(PlanLimit.self, forKey: .details)
        }
    }
}
