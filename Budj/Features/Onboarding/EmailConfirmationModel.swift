//
//  EmailConfirmationModel.swift
//  Budj
//

import Foundation
import Observation

/// The state behind the address-confirmation sheet (D17).
///
/// It is app-scoped rather than owned by the sign-in screen on purpose: the
/// person leaves for their mail app and comes back minutes later, possibly to a
/// cold start. Whatever presents the sheet has to still exist then, and the
/// sign-in screen does not.
@Observable
final class EmailConfirmationModel {
    /// The four things the sheet can be saying. `nil` is the fifth: no sheet.
    enum Phase: Equatable {
        /// Registered, and waiting on the link.
        case waiting(email: String)
        /// The link arrived and its session is being exchanged.
        case exchanging
        /// Confirmed and signed in. The session is already stored.
        case confirmed
        /// The link cannot be used, or the exchange was refused.
        case refused(String)
    }

    private(set) var phase: Phase?

    var isPresented: Bool { phase != nil }

    /// Whether the session behind the sheet exists, so dismissing it — by the
    /// button or by a swipe — moves the app on rather than stranding a signed-in
    /// person on the sign-in screen.
    var didConfirm: Bool { phase == .confirmed }

    private let authenticator: Authenticator
    private var exchange: Task<Void, Never>?

    init(authenticator: Authenticator) {
        self.authenticator = authenticator
    }

    // MARK: - Opening

    /// Called when registration succeeded without a session.
    func awaitConfirmation(of email: String) {
        exchange?.cancel()
        exchange = nil
        phase = .waiting(email: email)
    }

    /// Handles an incoming URL, and reports whether it was one of ours.
    ///
    /// Every URL the app is opened with comes through here; the ones that are
    /// not confirmation links are left for whoever else is listening, which for
    /// now is nobody and later is the bank callback.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let link = EmailConfirmationLink.parse(url) else { return false }

        switch link {
        case let .granted(refreshToken):
            begin(refreshToken: refreshToken)
        case let .refused(code, message):
            phase = .refused(Self.message(forCode: code, description: message))
        }
        return true
    }

    // MARK: - Exchanging

    private func begin(refreshToken: String) {
        exchange?.cancel()
        phase = .exchanging
        exchange = Task { [weak self] in
            guard let self else { return }
            do {
                try await authenticator.completeEmailConfirmation(refreshToken: refreshToken)
                guard !Task.isCancelled else { return }
                phase = .confirmed
            } catch is CancellationError {
                return
            } catch let error as APIError {
                guard !Task.isCancelled else { return }
                phase = .refused(Self.message(for: error))
            } catch {
                guard !Task.isCancelled else { return }
                phase = .refused("Something went wrong. Sign in with your email address and password.")
            }
            exchange = nil
        }
    }

    // MARK: - Closing

    /// Closes the sheet. Whether that also moves the app on is the caller's to
    /// decide from `didConfirm`, because the sheet does not route.
    func dismiss() {
        exchange?.cancel()
        exchange = nil
        phase = nil
    }

    // MARK: - Copy

    /// Every refusal ends in the same place — sign in, or start again — so the
    /// message says which of those to do rather than naming Supabase's code.
    private static func message(forCode code: String?, description: String?) -> String {
        switch code {
        case "otp_expired":
            return "That link has expired. Create your account again to get a new one."
        case "access_denied", "email_link_invalid":
            return "That link has already been used. Sign in with your email address and password."
        default:
            let advice = "Sign in with your email address and password."
            guard let description, !description.isEmpty else {
                return "That link cannot be used. \(advice)"
            }
            return "\(description). \(advice)"
        }
    }

    private static func message(for error: APIError) -> String {
        switch error {
        case .network:
            "Can't reach Budj. Check your connection and open the link again."
        case .unauthorized:
            "That link has already been used. Sign in with your email address and password."
        default:
            "Something went wrong. Sign in with your email address and password."
        }
    }
}

#if DEBUG
extension EmailConfirmationModel {
    /// A model parked in one phase, for previews. It is wired to an
    /// authenticator that has no server to talk to, which is fine: a preview
    /// never leaves the phase it was given.
    static func preview(_ phase: Phase) -> EmailConfirmationModel {
        let session = SessionStore()
        let model = EmailConfirmationModel(
            authenticator: Authenticator(api: BudjAPI(session: session), session: session)
        )
        model.phase = phase
        return model
    }
}
#endif
