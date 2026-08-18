//
//  BiometricKind.swift
//  Budj
//

import Foundation

/// Which biometric this device offers, for the one purpose the app has: naming
/// it in the opt-in copy.
///
/// The names are Apple's proper nouns and are the only capitalised words the
/// voice rules permit here — "unlock with Face ID", never "unlock with face id"
/// and never a generic "biometrics".
nonisolated enum BiometricKind: Equatable {
    case faceID
    case touchID
    case opticID

    var name: String {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        }
    }
}
