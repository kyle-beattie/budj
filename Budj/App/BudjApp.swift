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

        _authenticator = State(initialValue: Authenticator(api: api, session: session, identity: identity))
        _app = State(initialValue: app)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(app)
                .environment(authenticator)
                .onOpenURL { url in
                    // Deep-link handling lands here; the bank authorisation
                    // callback (task 12.2) is the first thing that will need it.
                    print("App opened via URL: \(url)")
                }
        }
    }
}
