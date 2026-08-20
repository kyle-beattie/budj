//
//  PushOptInView.swift
//  Budj
//

import SwiftUI
import UserNotifications

/// The push step: the last thing before the app itself.
///
/// Client-only, so unlike billing and bank there is no server answer to wait
/// for and nothing here is mocked. Asking iOS for authorisation is real.
/// Registering for remote notifications and forwarding the APNs token to the
/// server is task 13.2–13.3 and is not.
///
/// Skipping is a `secondary` button rather than a text link, deliberately: a
/// declined permission must not be a second-class answer, and notifications are
/// advisory — nothing about them holds anyone back (D12).
struct PushOptInView: View {
    /// Called for both answers. The router only records that the offer was made;
    /// which way it was answered is this screen's business and nothing else's.
    var onAnswered: () -> Void

    @State private var isRequesting = false

    var body: some View {
        StepScaffold(
            title: "Get notified",
            subtitle: "Budj tells you what it set aside and when, so money moving is never a surprise. You can change this later in Settings."
        ) {
            EmptyView()
        } actions: {
            Button("Turn on notifications") { request() }
                .buttonStyle(BudjButtonStyle(variant: .primary, isLoading: isRequesting))
                .disabled(isRequesting)

            Button("Not now") { onAnswered() }
                .buttonStyle(.budjSecondary)
                .disabled(isRequesting)
        }
    }

    private func request() {
        guard !isRequesting else { return }
        isRequesting = true
        Task {
            // The answer is not read: granted and denied are the same fact to
            // the router, and iOS will not ask twice either way.
            _ = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isRequesting = false
            onAnswered()
        }
    }
}

#Preview {
    PushOptInView {}
}
