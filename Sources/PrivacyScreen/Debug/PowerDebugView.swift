import SwiftUI

// MARK: - PowerDebugView

/// Power state and duty cycle readout displayed at the top-right of the screen.
///
/// Shows power state, ARKit mode, duty cycle percentage, motion frequency,
/// acceleration magnitude, time since motion, and estimated power consumption.
public struct PowerDebugView: View {
    @EnvironmentObject private var powerThrottler: PowerThrottler

    public init() {}

    private var stateColor: Color {
        switch powerThrottler.powerState {
        case .dormant: return .gray
        case .idle: return .blue
        case .active: return .green
        case .alert: return .red
        }
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                Text(powerThrottler.powerState.rawValue.uppercased())
                    .fontWeight(.semibold)
                Circle()
                    .fill(stateColor)
                    .frame(width: 8, height: 8)
            }

            Group {
                debugRow("ARKit", powerThrottler.arKitMode)
                debugRow("Duty", String(format: "%.0f%%", powerThrottler.dutyCycle))
                debugRow("Hz", String(format: "%.0f", powerThrottler.powerState.motionHz))
                debugRow("Accel", String(format: "%.3f", powerThrottler.accelerationMagnitude))
                debugRow("Still", formatDuration(powerThrottler.timeSinceMotion))
                debugRow("Power", "\(powerThrottler.powerState.estimatedPowerMW) mW")
            }
        }
        .font(.caption2.monospaced())
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.trailing, 8)
        .padding(.top, 50)
        .allowsHitTesting(false)
    }

    private func debugRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        if interval < 1 { return "0s" }
        if interval < 60 { return String(format: "%.0fs", interval) }
        return String(format: "%.0fm", interval / 60)
    }
}
