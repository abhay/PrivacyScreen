import PrivacyScreen
import SwiftUI

// MARK: - DemoCaption

struct DemoCaption: Equatable {
    let title: String
    let subtitle: String

    static let empty = DemoCaption(title: "", subtitle: "")

    var isEmpty: Bool {
        title.isEmpty && subtitle.isEmpty
    }
}

// MARK: - DemoRunner

/// Drives a scripted demo sequence that walks through all threat levels with captions.
///
/// Triggered via the `-demo` launch argument for hands-free simulator video recording.
@MainActor
final class DemoRunner: ObservableObject {

    // MARK: - Published State

    @Published private(set) var caption: DemoCaption = .empty
    @Published private(set) var isRunning: Bool = false

    /// When false, captions are suppressed (used for screenshot capture).
    var showCaptions: Bool = true

    // MARK: - Demo Script

    private struct Step {
        let delay: Duration
        let level: ThreatLevel?
        let title: String
        let subtitle: String
    }

    private let script: [Step] = [
        Step(
            delay: .seconds(0),
            level: nil,
            title: "PrivacyScreen Demo",
            subtitle: "Simulated threat detection"
        ),
        Step(
            delay: .seconds(2),
            level: .clear,
            title: "All Clear",
            subtitle: "No threats — all data visible"
        ),
        Step(
            delay: .seconds(5),
            level: .cautious,
            title: "Possible Onlooker",
            subtitle: "High-sensitivity content blurs (balances, card numbers)"
        ),
        Step(
            delay: .seconds(5),
            level: .threatened,
            title: "Shoulder Surfer",
            subtitle: "Names and dates also hidden"
        ),
        Step(
            delay: .seconds(5),
            level: .locked,
            title: "Second Face Detected",
            subtitle: "Full privacy shield activated"
        ),
        Step(
            delay: .seconds(5),
            level: .threatened,
            title: "De-escalating",
            subtitle: "Shield lifts, partial blur remains"
        ),
        Step(
            delay: .seconds(4),
            level: .cautious,
            title: "Cooling Down",
            subtitle: "Only high-sensitivity content still blurred"
        ),
        Step(
            delay: .seconds(4),
            level: .clear,
            title: "Threat Resolved",
            subtitle: "All data visible again"
        ),
    ]

    // MARK: - Run

    private var task: Task<Void, Never>?

    func start(privacyManager: PrivacyManager) {
        guard !isRunning else { return }
        isRunning = true

        task = Task { [script] in
            for step in script {
                if step.delay > .zero {
                    try? await Task.sleep(for: step.delay)
                }
                guard !Task.isCancelled else { break }

                if self.showCaptions {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.caption = DemoCaption(title: step.title, subtitle: step.subtitle)
                    }
                }
                if let level = step.level {
                    privacyManager.simulateThreatLevel(level)
                }
            }

            // Hold final state briefly then mark done
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                self.caption = .empty
            }
            self.isRunning = false
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }
}
