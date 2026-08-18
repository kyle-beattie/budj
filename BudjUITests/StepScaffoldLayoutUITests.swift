//
//  StepScaffoldLayoutUITests.swift
//  BudjUITests
//

import XCTest

/// The account-creation form stays usable with the keyboard up at the largest
/// accessibility type size.
///
/// **This is a smoke test, not a regression guard for the layout fix it was
/// written alongside.** The scaffold used to clip its form to zero height when
/// the action buttons and the keyboard together left the scroll view no room;
/// that was demonstrated in landscape, measured at 0pt before the fix and 406pt
/// after. The app is portrait-only now, and in portrait the failure does not
/// reproduce on any simulator available here — restoring the old layout leaves
/// this test passing. It is kept for what it does cover, which is task 5.2's
/// territory: the form still exists and is reachable at accessibility sizes.
final class StepScaffoldLayoutUITests: XCTestCase {

    func testTheFormSurvivesTheKeyboardAtTheLargestTypeSize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()

        let create = app.buttons["Create an account"]
        XCTAssertTrue(create.waitForExistence(timeout: 10), "No welcome screen")
        create.tap()

        let email = app.textFields.firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5), "No email field")
        email.tap()
        Thread.sleep(forTimeInterval: 2)

        let height = app.scrollViews.firstMatch.frame.height
        XCTAssertGreaterThan(
            height, 100,
            "The scaffold's scroll view collapsed to \(height) with the keyboard up"
        )
        XCTAssertTrue(
            app.textFields.firstMatch.exists,
            "The form is not in the hierarchy at the largest type size"
        )
    }
}
