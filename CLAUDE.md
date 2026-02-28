# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PrivacyScreen** is a Swift Package library (iOS 17+) that simulates hardware-level privacy screen protection using ARKit face tracking + CoreMotion accelerometer sensor fusion. **VaultDemo** is a sample finance app demonstrating the library.

## Build & Test Commands

```bash
# Build the library (iOS-only frameworks — must target iOS SDK)
swift build --sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -Xswiftc "-target" -Xswiftc "arm64-apple-ios17.0-simulator"

# Run unit tests via xcodebuild (swift test alone won't resolve iOS frameworks)
xcodebuild test -scheme PrivacyScreen \
  -destination 'platform=iOS Simulator,name=iPhone 16' -quiet

# Run a single test
xcodebuild test -scheme PrivacyScreen \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing PrivacyScreenTests/ThreatStateTests/testName

# Build VaultDemo for simulator
xcodebuild build -project Example/VaultDemo/VaultDemo.xcodeproj \
  -scheme VaultDemo -destination 'platform=iOS Simulator,name=iPhone 16' -quiet

# Install and launch on simulator
xcrun simctl install booted path/to/VaultDemo.app
xcrun simctl launch booted com.vaultdemo.app

# Lint & format
swiftlint lint Sources/ Tests/ Example/
swiftformat --lint Sources/ Tests/ Example/

# Auto-fix lint/format issues
swiftformat Sources/ Tests/ Example/
swiftlint lint --fix Sources/ Tests/ Example/

# Run pre-commit hooks manually
lefthook run pre-commit
```

ARFaceTrackingConfiguration requires a physical device with TrueDepth camera (iPhone X+). The app runs on simulator but falls back to accelerometer-only mode (face detection disabled, tilt still works). Use Settings > "Simulate Threat" to test the full privacy overlay on simulator.

## Architecture

### Two-component system

1. **PrivacyScreen library** (`Sources/PrivacyScreen/`) — SPM package with Core, Overlay, and Debug modules
2. **VaultDemo app** (`Example/VaultDemo/`) — separate Xcode project, NOT part of the SPM package; adds the local package as a dependency

### Core data flow

```
ARKit face anchors + CMMotionManager data
    → ThreatState (pure value type, scoring logic)
    → PrivacyManager (publishes threatLevel)
    → PrivacySensitiveModifier (blurs views based on sensitivity level)
    → PrivacyShieldOverlay (full lockdown at .locked)
```

### ThreatState scoring (pure value type — 29 tests using Swift Testing)

- `secondFaceDetected` → instant `.locked`
- `deviceTiltRate > 120°/s` → instant `.locked` (snatch detection)
- `primaryFaceLost` → +2 score
- `primaryGazeDeviation > 0.3 rad` → +1, `> 0.5 rad` → +2
- `abs(deviceTiltAngle) > 25°` → +1, `> 40°` → +2
- Score: 0=`.clear`, 1=`.cautious`, 2=`.threatened`, 3+=`.locked`

### PowerThrottler state machine

```
DORMANT (5mW)  → accel 5Hz, ARKit OFF
IDLE    (30mW) → accel 15Hz, ARKit samples 0.5s every 3s (~17% duty)
ACTIVE  (180mW)→ accel 30Hz, ARKit continuous 60fps
ALERT   (180mW)→ same as active, locked until threat clears + 5s cooldown
```

### SensitivityLevel mapping

- `.high` — hidden at `.cautious` (balances, card numbers, CVV)
- `.medium` — hidden at `.threatened` (names, dates)
- `.low` — hidden at `.locked` only (merchant names)

## Critical Constraints

- **Single CMMotionManager per app** — iOS enforces this. PowerThrottler owns it and forwards data to PrivacyManager via `processMotionFromThrottler(_:)`. Creating two instances will crash.
- **@MainActor isolation** — PrivacyManager and PowerThrottler are `@MainActor`. ARSessionDelegate methods must be `nonisolated` and dispatch to main actor via `Task { @MainActor in ... }`.
- **Throttler attaches post-init**: `throttler.attach(to: privacyManager, arSession: privacyManager.arSession)` — cannot be done in initializers.
- **Temporal smoothing** — Threat escalation is immediate (1-2 frames), but de-escalation requires ALL frames in an 8-frame window (~133ms) to be lower.
- **PrivacyShieldOverlay** must use `.allowsHitTesting(false)` so touch events pass through.

## Code Style

- `// MARK: -` section headers generously
- `///` doc comments on all public API
- Computed properties for derived state (no stored + manual sync)
- `withAnimation` blocks, not implicit `.animation()` modifiers
- `@Published` only for state that views directly observe
- Private by default; expose only what the API surface requires
- Config structs with sensible defaults for tunable parameters

## VaultDemo Design

Premium dark-themed finance app (Mercury/Revolut-inspired). Base color `#0A0A0F`, SF Pro Rounded for large numbers, SF Symbols throughout. All data is hardcoded — no networking, persistence, or real data. The purpose is demonstrating the privacy library on realistic-looking financial UI.

Key wiring: both `PrivacyManager` and `PowerThrottler` are injected as `@EnvironmentObject` from `VaultDemoApp`. Views use `VaultTheme` constants and the `.vaultCard()` modifier for consistent styling. Tests use Swift Testing (`@Test`, `#expect`, `@Suite`) not XCTest.

## Scope Boundaries

No networking, API calls, persistence, onboarding, auth, localization, haptics, or UI tests. Only ThreatState gets unit tests.
