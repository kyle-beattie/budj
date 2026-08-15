# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Budj is a New Zealand personal-finance app: it connects to your bank via open banking and runs **rules** — a trigger plus an action — that move money automatically. Instead of scheduling a transfer for the 1st of the month, you set a condition ("when salary lands", "when balance goes above $3,000") and an action ("move $200 to Savings"), and the rule fires the moment the condition is true.

It is a SwiftUI iOS/iPadOS app (bundle id `nz.app.Budj`, `TARGETED_DEVICE_FAMILY = "1,2"`). The Xcode project currently holds a fresh scaffold — `BudjApp.swift` + a placeholder `ContentView.swift` — so all of the above is designed but not yet built. There is no Swift Package Manager manifest and no third-party dependencies; the Xcode project (`Budj.xcodeproj`, objectVersion 77) is the source of truth for the build.

## Design prototype

A click-through prototype and design system live **outside this repo**, at `~/Documents/budj/Budj iOS App Design/` (not version-controlled with the app — treat it as read-only reference and re-check it rather than assuming it is unchanged):

- `Budj.dc.html` — the interactive iOS prototype. Its behaviour lives in a `<script type="text/x-dc">` block near the end of the file; extract that block to read the screen flow and domain model as plain JS.
- `_ds/budj-design-system-*/tokens/` — `colors.css`, `typography.css`, `spacing.css`, `effects.css`. These are the authoritative visual values.
- `_ds/budj-design-system-*/readme.md` — voice, visual foundations, and motion rules. Read this before making any design judgement call.
- `assets/lettermark.svg`, `assets/wordmark.svg` — placeholder brand marks created for the kit, not real brand assets.

### Domain model implied by the prototype

- **Account** — id, bank (ANZ / ASB / BNZ / Westpac / Kiwibank), name, balance.
- **Rule** — name, source account, trigger, formula, destination account, active flag. Triggers are one of `received` (money arrives), `threshold` (balance crosses an amount, above/below), or `recurring` (a recurring pattern such as "Salary" is detected).
- **Formula** — the action is an arithmetic expression over `x`, the amount received, with `min/max/round/ceil/floor/abs` available. Presets: fixed (`50`), percentage (`x * 0.15`), round-up (`ceil(x/5)*5 - x`), keep-back (`max(x - 50, 0)`), or custom. The builder shows a live preview against an example `x`.
- **PendingRun** — a rule match awaiting review. Runs are **not** automatic: a match raises a notification, and the user confirms (with the amount editable before sending) or dismisses it. Confirmed and dismissed runs both land in history.

Screens: splash → sign in (Apple/Google) → Face ID opt-in → connect banks, then a four-tab app — Home (primary balance, pending reviews, top rules, recent history), Rules (list + add/edit sheet), Accounts (list, add bank, remove), Settings (Face ID, push, alerts, log out).

### Translating the design system to SwiftUI

- Dark-only, true black (`#000`) app background with cool gray surfaces stepped up from it; a single bright green accent `#39FF88` used sparingly (CTAs, active states, positive amounts). No secondary brand hue.
- Full-radius system: buttons and pills fully rounded; cards and sheets 28–32pt. Never sharp or barely-rounded corners.
- "Liquid glass" is the signature surface — map it to iOS 26's native glass APIs rather than reimplementing the CSS blur stack. Reserve it for surfaces floating over content (tab bar, sheets, toasts, dashboard cards); use solid surfaces for dense lists (rule lists, transaction rows) where blur hurts legibility.
- Type: Space Grotesk for display/headlines, the system font for body/UI, JetBrains Mono for money amounts and account numbers. The two non-system faces are Google Fonts in the kit and would need bundling into the app target — confirm licensing and intent before adding them; until then, prefer the system font with `.monospacedDigit()` for amounts.
- Currency is always NZD with two decimals and thousands separators (`$2,184.30`). Use `Decimal` and `FormatStyle`, not `Double`, for money in real code — the prototype's `Double` balances are prototype convenience.
- Copy rules: sentence case everywhere, no emoji, no exclamation points, second person ("your rules"). Uppercase tracked text only for small badge/eyebrow labels.
- The kit substitutes an in-house icon set for SF Symbols because it couldn't bundle Apple's. In the app, use real SF Symbols.

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
