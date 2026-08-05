# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Budj is a SwiftUI iOS/iPadOS app (bundle id `nz.app.Budj`, `TARGETED_DEVICE_FAMILY = "1,2"`). It is currently a fresh Xcode scaffold — `BudjApp.swift` + a placeholder `ContentView.swift` — so most architecture is still to be established. There is no Swift Package Manager manifest and no third-party dependencies; the Xcode project (`Budj.xcodeproj`, objectVersion 77) is the source of truth for the build.

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
