# System Prompt — PrivacyScreen iOS Library + Sample App

You are building an iOS project from scratch: a reusable Swift library called **PrivacyScreen** and a sample app called **VaultDemo** that demonstrates it. The project simulates Samsung S26-style privacy screen protection using software — ARKit face tracking + CoreMotion accelerometer sensor fusion — since iOS has no hardware-level pixel emission angle control.

## Project Structure

```
PrivacyScreen/
├── Package.swift                          # Swift Package (iOS 17+, platform .iOS(.v17))
├── Sources/
│   └── PrivacyScreen/
│       ├── Core/
│       │   ├── PrivacyManager.swift       # Central threat detection engine
│       │   ├── PowerThrottler.swift        # Battery-aware ARKit lifecycle manager
│       │   └── ThreatState.swift           # Threat model + aggregation logic
│       ├── Overlay/
│       │   ├── PrivacyShieldOverlay.swift  # Full-screen lock overlay at .locked
│       │   ├── PixelScatterEffect.swift    # Animated black pixel grid (Canvas-based)
│       │   └── PrivacySensitiveModifier.swift # .privacySensitive(level:) view modifier
│       └── Debug/
│           ├── PrivacyDebugOverlay.swift   # Real-time threat sensor readout
│           └── PowerDebugView.swift        # Power state + duty cycle readout
├── Tests/
│   └── PrivacyScreenTests/
│       └── ThreatStateTests.swift         # Unit tests for threat aggregation logic
└── Example/
    └── VaultDemo/                         # Xcode project (NOT part of the SPM package)
        ├── VaultDemoApp.swift
        ├── Views/
        │   ├── DashboardView.swift        # Main finance dashboard
        │   ├── AccountsView.swift         # Account list with balances
        │   ├── TransactionsView.swift     # Transaction feed
        │   ├── CardView.swift             # Credit/debit card display
        │   └── SettingsView.swift         # Privacy config + debug toggles
        ├── Models/
        │   ├── Account.swift
        │   ├── Transaction.swift
        │   └── Card.swift
        ├── Theme/
        │   └── VaultTheme.swift           # Colors, fonts, spacing constants
        └── Assets.xcassets
```

## Core Architecture

### ThreatState (pure value type — easily testable)

```
enum ThreatLevel: Comparable { case clear, cautious, threatened, locked }

struct ThreatState {
    var secondFaceDetected: Bool
    var primaryGazeDeviation: Float      // radians off-center
    var primaryFaceLost: Bool
    var deviceTiltAngle: Float           // degrees lateral roll
    var deviceTiltRate: Float            // °/s rotation magnitude

    var aggregatedThreat: ThreatLevel    // computed from scoring system
}
```

Scoring rules:
- `secondFaceDetected` → instant `.locked`
- `deviceTiltRate > 120°/s` → instant `.locked` (snatch detection)
- `primaryFaceLost` → +2
- `primaryGazeDeviation > 0.3 rad` → +1, `> 0.5 rad` → +2
- `abs(deviceTiltAngle) > 25°` → +1, `> 40°` → +2
- Score 0 = `.clear`, 1 = `.cautious`, 2 = `.threatened`, 3+ = `.locked`

### PrivacyManager (@MainActor, ObservableObject)

- Publishes `threatLevel: ThreatLevel` and `debugInfo`
- Owns an `ARSession` with delegate for face anchor processing
- Supports two modes: internal motion (standalone) or external motion (when PowerThrottler manages sensors)
- `startMonitoring(externalMotion: Bool = false)`
- ARSessionDelegate processes face anchors: sorts by distance (closest = primary user), extracts `lookAtPoint` for gaze deviation, counts faces
- Temporal smoothing: escalate within 1-2 frames, de-escalate only when ALL frames in window (8 frames ≈ 133ms) are lower. Use `withAnimation` on transitions.
- IMPORTANT: `nonisolated func session(_:didUpdate:)` must dispatch to `@MainActor` via `Task { @MainActor in ... }` for the face processing.

### PowerThrottler (@MainActor, ObservableObject)

State machine managing battery life:

```
DORMANT (~5mW)  → accel 5Hz, ARKit OFF
IDLE    (~30mW) → accel 15Hz, ARKit samples 0.5s every 3s (~17% duty cycle)
ACTIVE  (~180mW)→ accel 30Hz, ARKit continuous 60fps
ALERT   (~180mW)→ same as active, locked until threat clears + 5s cooldown
```

Transitions:
- DORMANT → ACTIVE: `userAcceleration magnitude > 0.15 m/s²` (phone picked up)
- ACTIVE → IDLE: still for 8s (`userAcceleration < 0.05 m/s²`)
- IDLE → DORMANT: still for 30s
- IDLE → ACTIVE: motion resumes
- Any → ALERT: `threatLevel >= .threatened`
- ALERT → ACTIVE: threat clears + 5s cooldown

Critical: iOS only allows ONE `CMMotionManager` per app. The throttler owns it and forwards motion data to PrivacyManager via `processMotionFromThrottler(_:)`. Two instances will crash.

The throttler attaches to PrivacyManager post-init: `throttler.attach(to: privacyManager, arSession: privacyManager.arSession)`.

Idle sampling: `resumeARKit()` → wait 0.5s → `pauseARKit()`, repeated every 3s. This catches approaching faces while cutting IR projector usage ~83%.

### PrivacySensitiveModifier (ViewModifier)

```swift
extension View {
    func privacySensitive(level: SensitivityLevel = .high) -> some View
}

enum SensitivityLevel {
    case low     // hidden at .locked only (merchant names)
    case medium  // hidden at .threatened (names, dates)
    case high    // hidden at .cautious (balances, card numbers, CVV)
}
```

Implementation: progressive gaussian blur (8/16/24 radius) + `.ultraThinMaterial` overlay at higher threat levels. Animate with `.easeInOut(duration: 0.2)`.

### PrivacyShieldOverlay

Full-screen overlay at `.locked` level. Layers:
1. `.ultraThinMaterial` full bleed
2. `PixelScatterEffect` — Canvas drawing thousands of black rects in a pseudorandom checkerboard with shimmer animation (use `TimelineView(.animation(minimumInterval: 1/30))`)
3. `eye.slash.fill` SF Symbol + "Privacy Mode Active" text

Must set `.allowsHitTesting(false)` so touch events pass through.

### Debug Overlays

Two overlays, shown when `privacyManager.showDebugOverlay == true`:
- **PrivacyDebugOverlay** (top-left): face count, gaze deviation (rad), tilt angle (°), tilt rate (°/s), threat level with color-coded indicator
- **PowerDebugView** (top-right): power state, ARKit mode (OFF/SAMPLING/ON), duty cycle %, motion Hz, acceleration, time since motion, estimated power (mW)

Both use `.ultraThinMaterial` backgrounds, monospaced caption2 font.

## VaultDemo Sample App

### Design Direction

Build a **premium, dark-themed finance app** inspired by Mercury, Revolut, and the iOS Stocks app. This is for a demo — it should look production-quality. Dark backgrounds (#0A0A0F base), subtle material cards, SF Pro Rounded for large numbers, SF Pro for body text. Use SF Symbols throughout.

The app does NOT need networking, persistence, or real data. All data is hardcoded. The point is demonstrating the privacy library on realistic-looking financial UI.

### Views

**DashboardView** (main tab):
- Large hero balance: "$184,229.47" with daily change "+$2,847.33 (1.57%)" in green
- Inline sparkline chart (use a simple SwiftUI Path or Chart framework)
- Quick action row: Send, Request, Pay, Transfer (SF Symbol icons in tinted circles)
- "Accounts" section with 3 cards (Checking, Savings, Investment) showing masked account numbers and balances
- "Recent Activity" section with 6-8 transactions

Apply `.privacySensitive()` to:
- `.high`: all dollar amounts, card numbers, CVV, full account numbers
- `.medium`: cardholder name, expiry date, partial account numbers (••••4281)
- `.low`: merchant/payee names

**CardView**:
- Realistic credit card with gradient background (blue→purple or dark metal)
- Card number, cardholder, expiry, CVV — all tagged with appropriate sensitivity
- Use `RoundedRectangle(cornerRadius: 16)` with a `LinearGradient`

**SettingsView**:
- Toggle: Privacy Mode enabled/disabled
- Toggle: Show Debug Overlays
- Stepper or slider: Tilt sensitivity threshold
- Stepper or slider: Gaze sensitivity threshold
- Info section explaining how the privacy system works
- Button: "Simulate Threat" (for testing without a second person — manually sets threat to .locked for 3s)

### App Entry Point

```swift
@main
struct VaultDemoApp: App {
    @StateObject private var privacyManager = PrivacyManager()
    @StateObject private var powerThrottler = PowerThrottler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(privacyManager)
                .environmentObject(powerThrottler)
                .onAppear {
                    privacyManager.startMonitoring(externalMotion: true)
                    powerThrottler.attach(to: privacyManager, arSession: privacyManager.arSession)
                    powerThrottler.start()
                }
        }
    }
}
```

## Technical Requirements

- **Deployment target**: iOS 17.0+
- **Swift**: 5.9+
- **Package type**: Swift Package Manager library. The Example/VaultDemo app is a separate Xcode project that adds the local package as a dependency.
- **Frameworks**: ARKit, CoreMotion, SwiftUI, Combine. No third-party dependencies.
- **Device-only**: ARFaceTrackingConfiguration requires TrueDepth camera (iPhone X+). Add runtime check and graceful fallback (accelerometer-only mode on unsupported devices or simulator — face detection disabled, tilt still works).
- **Info.plist**: `NSCameraUsageDescription` = "Used for privacy protection — detecting if someone else can see your screen."
- **Concurrency**: PrivacyManager and PowerThrottler are `@MainActor`. ARSessionDelegate methods are `nonisolated` and must dispatch to main actor. CMMotionManager callbacks come on `.main` queue.
- **Single CMMotionManager**: iOS enforces one per app. PowerThrottler owns it. PrivacyManager receives forwarded data.

## Testing

Write unit tests for `ThreatState` aggregation since it's a pure value type:
- Test each signal independently (second face → locked, high tilt rate → locked, etc.)
- Test score accumulation (face lost + moderate tilt = threatened)
- Test edge cases (all signals zero = clear, all signals max = locked)

## Code Style

- Use `// MARK: -` section headers generously
- Document all public API with `///` doc comments
- Keep computed properties for derived state (no stored + manual sync)
- Prefer `withAnimation` blocks over implicit `.animation()` modifiers
- Use `@Published` only for state that views directly observe
- Private by default; expose only what the API surface requires
- Config structs with sensible defaults for all tunable parameters

## What NOT To Build

- No networking, no API calls, no persistence
- No onboarding flow or auth
- No App Store metadata or launch screen customization
- No unit tests for UI (just ThreatState logic tests)
- No localization
- No haptics (mentioned as future extension but skip for now)

## First Steps

1. Create the Swift Package with the directory structure above
2. Build `ThreatState.swift` first — it's pure logic, testable, no dependencies
3. Build `PrivacyManager.swift` consuming ThreatState
4. Build `PowerThrottler.swift` with the state machine
5. Build the view modifiers and overlays
6. Create the VaultDemo app with hardcoded data
7. Wire everything together in the app entry point
8. Write ThreatState unit tests
9. Test on a physical device with the debug overlays enabled
