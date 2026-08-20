//
//  UnreachableView.swift
//  Budj
//

import SwiftUI

/// Shown when there is a session but the server could not be asked where this
/// person is.
///
/// This is the outcome that gets skipped, because it needs a signed-in user and
/// a server that is down at the same time — a combination nobody reproduces by
/// hand. Without it the app either guesses a step or hangs on the launch mark,
/// and guessing shows a paywall to somebody who has already paid.
///
/// It says the app could not reach Budj rather than that anything is wrong with
/// the user's account, because at this point the app does not know that it is.
struct UnreachableView: View {
    @Environment(AppModel.self) private var app

    @State private var isRetrying = false

    var body: some View {
        StepScaffold(
            title: "Can't reach Budj",
            subtitle: "Your connection or our server is having a moment. Nothing is wrong with your account."
        ) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(BudjColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BudjSpacing.section)
                .accessibilityHidden(true)
        } actions: {
            Button("Try again") { retry() }
                .buttonStyle(.budjPrimary(isLoading: isRetrying))
                .disabled(isRetrying)
        }
    }

    private func retry() {
        guard !isRetrying else { return }
        isRetrying = true
        Task {
            await app.start()
            isRetrying = false
        }
    }
}

//#Preview {
//    UnreachableView()
//        .environment(AppModel.preview())
//}
