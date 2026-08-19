//
//  BiometricPersistenceTests.swift
//  BudjTests
//

import Foundation
import Testing
@testable import Budj

/// The three defects behind "Face ID isn't working as expected", each with the
/// assertion that would have caught it.
///
/// All three shared a shape: nothing failed, nothing was logged, and the app
/// went on claiming a protection it was not applying. None of them is reachable
/// by reading the code for a minute; each needed a test that outlives a launch.
@MainActor
struct BiometricPersistenceTests {

    // MARK: - The preference has to outlive the process

    /// The one that made Face ID stop working after the first relaunch.
    ///
    /// `requiresBiometry` used to start `false` on every launch, and every write
    /// consults it — so the first token refresh after relaunching rewrote the
    /// session *without* its access control. From then on the Keychain read
    /// raised no prompt, because there was nothing left to prompt for.
    @Test func aRelaunchKeepsTheSessionBehindBiometry() {
        let preference = InMemoryBiometricPreference()
        let persistence = InMemorySessionPersistence()

        let first = SessionStore(persistence: persistence, preference: preference)
        first.replace(with: .stub())
        first.setRequiresBiometry(true)
        #expect(persistence.storedRequiringBiometry)

        // A new process: a fresh store over the same storage.
        let second = SessionStore(persistence: persistence, preference: preference)
        #expect(second.requiresBiometry, "the preference did not survive the launch")

        // What a token refresh does, seconds after launch.
        second.replace(with: .stub(accessToken: "access-2"))

        #expect(
            persistence.storedRequiringBiometry,
            "a refresh silently rewrote the session without its access control"
        )
    }

    @Test func turningItOffAlsoSurvivesTheLaunch() {
        let preference = InMemoryBiometricPreference(requiresBiometry: true)
        let persistence = InMemorySessionPersistence()

        let store = SessionStore(persistence: persistence, preference: preference)
        store.replace(with: .stub())
        store.setRequiresBiometry(false)

        let relaunched = SessionStore(persistence: persistence, preference: preference)
        relaunched.replace(with: .stub(accessToken: "access-2"))

        #expect(relaunched.requiresBiometry == false)
        #expect(persistence.storedRequiringBiometry == false)
    }

    /// Signing out does not answer the question for the next person, but it does
    /// not un-answer it for this device either: the Keychain item is one item,
    /// and the opt-in step asks each new user regardless.
    @Test func signingOutLeavesTheDevicePreferenceStanding() {
        let preference = InMemoryBiometricPreference()
        let store = SessionStore(persistence: InMemorySessionPersistence(), preference: preference)
        store.replace(with: .stub())
        store.setRequiresBiometry(true)

        store.clear()

        #expect(preference.requiresBiometry)
    }

    // MARK: - A refused write is reported

    /// A screen that says Face ID is on over a session that is not behind it is
    /// worse than one that admits the write failed.
    @Test func aRefusedWriteIsReportedRatherThanSwallowed() {
        let persistence = InMemorySessionPersistence()
        persistence.failNextSave = true
        let store = SessionStore(
            persistence: persistence,
            preference: InMemoryBiometricPreference()
        )
        store.replace(with: .stub())
        persistence.failNextSave = true

        #expect(store.setRequiresBiometry(true) == false)
    }

    @Test func aSuccessfulWriteReportsSuccess() {
        let store = SessionStore(
            persistence: InMemorySessionPersistence(),
            preference: InMemoryBiometricPreference()
        )
        store.replace(with: .stub())

        #expect(store.setRequiresBiometry(true))
    }

    // MARK: - "Asked once" is per user for biometry

    /// The one that meant a second account on the same device was never offered
    /// Face ID at all: the record was keyed per install, so the first user's
    /// answer silently answered for everybody after them.
    @Test func asecondUserIsStillOfferedBiometrics() {
        let record = DefaultsStepRecord(defaults: isolatedDefaults())

        record.recordOffered(.biometrics, userID: "user-a")

        #expect(record.hasOffered(.biometrics, userID: "user-a"))
        #expect(
            record.hasOffered(.biometrics, userID: "user-b") == false,
            "a second account inherited the first one's answer"
        )
    }

    /// Push is the other way round on purpose. iOS will not re-prompt whoever is
    /// signed in, so asking per user would show a button that cannot work.
    @Test func pushIsAskedOncePerDeviceRatherThanPerUser() {
        let record = DefaultsStepRecord(defaults: isolatedDefaults())

        record.recordOffered(.push, userID: "user-a")

        #expect(record.hasOffered(.push, userID: "user-b"))
    }

    @Test func theRouterAsksEachUserAboutBiometrics() {
        let record = InMemoryStepRecord(offered: [.biometrics], userID: "user-a")
        let session = SessionStore(persistence: InMemorySessionPersistence())
        let model = OnboardingModel(
            api: BudjAPI(session: session),
            record: record,
            biometricsAvailable: true
        )

        model.seed(serverStep: .billing, userID: "user-a")
        #expect(model.step == .billing, "the first user was asked again")

        model.seed(serverStep: .billing, userID: "user-b")
        #expect(model.step == .biometrics, "the second user was never asked")
    }

    // MARK: - Helpers

    /// A defaults suite of this test's own, so the real one is neither read nor
    /// written and a second run agrees with the first.
    private func isolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "BiometricPersistenceTests.\(UUID().uuidString)")!
    }
}
