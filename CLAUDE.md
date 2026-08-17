# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Budj is a New Zealand personal-finance app: it connects to your bank via open banking and runs **rules** — a trigger plus an action — that move money automatically. Instead of scheduling a transfer for the 1st of the month, you set a condition ("when salary lands", "when balance goes above $3,000") and an action ("move $200 to Savings"), and the rule fires the moment the condition is true.

It is a SwiftUI iOS/iPadOS app (bundle id `nz.app.Budj`, `TARGETED_DEVICE_FAMILY = "1,2"`). The Xcode project currently holds a fresh scaffold — `BudjApp.swift` + a placeholder `ContentView.swift` — so all of the above is designed but not yet built. There is no Swift Package Manager manifest and no third-party dependencies; the Xcode project (`Budj.xcodeproj`, objectVersion 77) is the source of truth for the build.

## Specs

Product behaviour is specified in the **`budj-specs` OpenSpec store**, a standalone repo at `/Users/kylebeattie/Sites/budj-specs` shared between this app and `budj-server`. Read it before designing anything; it is the source of truth for the domain model, the flows, and the API contract.

```bash
openspec list --store budj-specs
openspec show <change> --store budj-specs
```

The iOS app's own change is `add-ios-onboarding` — launch, sign-in, subscription, bank connection, and the component architecture everything else is built on. `add-onboarding`, `add-rule-triggers`, `add-rule-allocation` and `add-account-deletion` specify the server the app talks to.

An earlier click-through prototype and a generated design kit are **out of date and must not be cited as authority** — they predate the specs and contradict them (most visibly on the rule model, which is now an ordered step list rather than a formula over `x`, and on colour).

## Design

- Colour comes from the **asset catalogue** and nowhere else. Every colour is a named set with both light and dark appearances defined; the app supports both.
- Full-radius system: buttons and pills fully rounded; cards and sheets 28–32pt. Never sharp or barely-rounded corners.
- Spacing is a 4pt scale, referenced by name. Nothing uses a value off the scale.
- "Liquid glass" is the signature surface — use iOS 26's native glass APIs. Reserve it for surfaces floating over content (tab bar, sheets, toasts, the primary action); use solid surfaces for dense lists (rule lists, transaction rows) where blur hurts legibility.
- Motion: one standard curve, one springier curve for toggles and sheet presentation. Durations 120ms (press), 200ms (default), 340ms (sheets and transitions). Always animate a named value, never implicitly.
- Type is the system font, with `.monospacedDigit()` for amounts and account numbers. No custom faces are bundled.
- Icons are real SF Symbols.
- Currency is always NZD with two decimals and thousands separators (`$2,184.30`). Use `Decimal` and `FormatStyle`, never `Double`, for money.
- Copy rules: sentence case everywhere, no emoji, no exclamation points, second person ("your rules"). Uppercase tracked text only for small badge/eyebrow labels.

## Commands

The only scheme is `Budj`; it covers all three targets (`Budj`, `BudjTests`, `BudjUITests`).

```bash
# Build
xcodebuild build -scheme Budj -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# All tests (unit + UI)
xcodebuild test -scheme Budj -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Unit tests only
xcodebuild test -scheme Budj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BudjTests

# A single test — Swift Testing uses the function name, XCTest uses Class/method
xcodebuild test -scheme Budj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BudjTests/BudjTests/example
xcodebuild test -scheme Budj -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BudjUITests/BudjUITests/testExample
```

`IPHONEOS_DEPLOYMENT_TARGET` is 26.5, so the destination must be an iOS 26.x simulator. iPhone 15/16 devices on this machine only have iOS 17.4/18.2 runtimes and will fail to launch — use iPhone 17 / 17 Pro / 17e / iPhone Air, or an iPad Pro 13-inch (M5).

## Conventions

- **Default actor isolation is `MainActor`** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`). Unannotated types are already main-actor-isolated; annotate explicitly only to move work *off* the main actor (`nonisolated`, `@concurrent`, actors).
- **Unit tests use Swift Testing** (`import Testing`, `@Test`, `#expect`). UI tests use XCTest/XCUIApplication, since XCUITest has no Swift Testing equivalent.
- Adding a file to the repo does not add it to the build. New sources must be registered in `Budj.xcodeproj/project.pbxproj` (add via Xcode, or edit the pbxproj carefully and verify with a build).

## SwiftUI guidance

The `swiftui-pro` skill is installed for this project (`.claude/settings.json`, vendored under `.agents/skills/swiftui-pro/`). Invoke it when writing or reviewing SwiftUI code. Its house rules, which apply to all work here:

- Target iOS 26 APIs and modern Swift concurrency; avoid UIKit unless asked.
- Do not introduce third-party frameworks without asking first.
- One type per file; organise folders by app feature.
