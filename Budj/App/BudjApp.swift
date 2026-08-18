//
//  BudjApp.swift
//  Budj
//
//  Created by Kyle Beattie on 05/08/2026.
//

import SwiftUI

@main
struct BudjApp: App {
    /// Built once, here, and handed down. Nothing else constructs an API client
    /// or a session store, so there is only ever one of each and they cannot
    /// disagree about who is signed in.
    @State private var session: SessionStore
    @State private var api: BudjAPI
    @State private var authenticator: Authenticator
    @State private var app: AppModel
    @State private var confirmation: EmailConfirmationModel

    init() {
        let session = SessionStore()
        let api = BudjAPI(session: session)
        let app = AppModel(
            session: session,
            gate: LaunchGateModel(api: api, session: session),
            onboarding: OnboardingModel(api: api)
        )
        api.interruptionHandler = app

        _session = State(initialValue: session)
        _api = State(initialValue: api)
        // Provider sign-in is offered only when the build carries a Supabase
        // address and key. Without them the button would be a control that
        // cannot work, so it is not shown at all.
        let identity = SupabaseConfiguration.current.map { SupabaseIdentity(configuration: $0) }

        let authenticator = Authenticator(api: api, session: session, identity: identity)
        _authenticator = State(initialValue: authenticator)
        _app = State(initialValue: app)
        // App-scoped, not screen-scoped: the address-confirmation link comes
        // back minutes later and possibly to a cold start, so whatever holds its
        // state has to outlive the screen that started it (D17).
        _confirmation = State(initialValue: EmailConfirmationModel(authenticator: authenticator))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(app)
                .environment(authenticator)
                .environment(confirmation)
                .onOpenURL { url in
                    // Each handler answers whether the URL was one of its own,
                    // so adding the bank authorisation callback (task 12.2) is
                    // another line here rather than a rewrite of this one.
                    guard !confirmation.open(url) else { return }
                    print("App opened via an unhandled URL: \(url)")
                }
        }
    }
}
