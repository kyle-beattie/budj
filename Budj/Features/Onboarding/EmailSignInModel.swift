//
//  EmailSignInModel.swift
//  Budj
//

import Foundation
import Observation

/// The state behind the email and password screen.
///
/// It holds no SwiftUI types, so every rule it applies — what counts as a valid
/// address, which failure produces which message, what registering without a
/// session means — is testable without rendering anything.
@Observable
final class EmailSignInModel {
    enum Mode: Equatable {
        case signIn
        case register

        var other: Mode { self == .signIn ? .register : .signIn }
    }

    /// What finishing the screen produced, for the caller to route on.
    enum Outcome: Equatable {
        /// A session exists. Carry on into onboarding.
        case signedIn
        /// The account was created but needs its address confirmed first.
        case confirmationRequired
    }

    private(set) var mode: Mode = .signIn
    var email = ""
    var password = ""

    private(set) var emailError: String?
    private(set) var passwordError: String?
    /// A failure that belongs to the attempt rather than to one field.
    private(set) var formError: String?
    private(set) var isWorking = false
    private(set) var outcome: Outcome?

    /// The server's own minimum. Rejecting a shorter password here means one
    /// fewer round trip and a message under the right field.
    static let minimumPasswordLength = 8

    private let authenticator: Authenticator

    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }

    // MARK: - Editing

    func setMode(_ mode: Mode) {
        guard mode != self.mode else { return }
        self.mode = mode
        clearErrors()
    }

    func clearErrors() {
        emailError = nil
        passwordError = nil
        formError = nil
    }

    // MARK: - Submitting

    var canSubmit: Bool {
        !isWorking && !email.isEmpty && !password.isEmpty
    }

    func submit() async {
        guard !isWorking else { return }
        clearErrors()
        guard validate() else { return }

        isWorking = true
        defer { isWorking = false }

        do {
            switch mode {
            case .signIn:
                try await authenticator.signIn(email: trimmedEmail, password: password)
                outcome = .signedIn
            case .register:
                let registration = try await authenticator.register(
                    email: trimmedEmail,
                    password: password
                )
                outcome = registration.session == nil ? .confirmationRequired : .signedIn
            }
        } catch let error as APIError {
            describe(error)
        } catch {
            formError = "Something went wrong. Try again."
        }
    }

    // MARK: - Validation

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validate() -> Bool {
        // Deliberately loose: an address either reaches someone or it does not,
        // and a clever pattern rejects real addresses for a living.
        let address = trimmedEmail
        if address.isEmpty {
            emailError = "Enter your email address"
        } else if !address.contains("@") || address.hasPrefix("@") || address.hasSuffix("@") {
            emailError = "Enter a valid email address"
        }

        if password.isEmpty {
            passwordError = "Enter your password"
        } else if mode == .register, password.count < Self.minimumPasswordLength {
            passwordError = "Use at least \(Self.minimumPasswordLength) characters"
        }

        return emailError == nil && passwordError == nil
    }

    // MARK: - Failures

    private func describe(_ error: APIError) {
        switch error {
        case .unauthorized:
            // The server does not say which half was wrong, and it should not —
            // that would let someone find out which addresses have accounts.
            formError = "That email and password do not match an account."
        case .network:
            formError = "Can't reach Budj. Check your connection and try again."
        case let .server(status, code, message):
            formError = Self.message(forStatus: status, code: code, serverMessage: message)
        case .updateRequired, .buildBlocked, .subscriptionRequired, .planLimitExceeded:
            // Handled centrally — the app is already leaving this screen.
            formError = nil
        case .decoding:
            formError = "Something went wrong. Try again."
        }
    }

    private static func message(forStatus status: Int, code: String, serverMessage: String) -> String {
        // 409 is the one worth naming: registering an address that already has
        // an account is a thing the person can fix themselves by signing in.
        if status == 409 {
            return "That email address already has an account. Sign in instead."
        }
        if status == 429 {
            return "Too many attempts. Wait a moment and try again."
        }
        if (400..<500).contains(status), !serverMessage.isEmpty {
            return serverMessage
        }
        return "Something went wrong. Try again."
    }
}
