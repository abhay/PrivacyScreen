import SwiftUI

// MARK: - PrivacyDebugOverlay

/// Real-time threat sensor readout displayed at the top-left of the screen.
///
/// Shows face count, gaze deviation, tilt angle/rate, and threat level
/// with a color-coded indicator.
public struct PrivacyDebugOverlay: View {
    @EnvironmentObject private var privacyManager: PrivacyManager

    public init() {}

    public var body: some View {
        let info = privacyManager.debugInfo

        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(privacyManager.threatLevel.color)
                    .frame(width: 8, height: 8)
                Text(privacyManager.threatLevel.rawValue.description)
                    .fontWeight(.semibold)
                Text("(\(info.rawThreatLevel.rawValue.description) raw)")
                    .foregroundStyle(.secondary)
            }

            Group {
                debugRow("Faces", "\(info.faceCount)")
                debugRow("Gaze", String(format: "%.2f rad", info.gazeDeviation))
                debugRow("Tilt", String(format: "%.1f\u{00B0}", info.tiltAngle))
                debugRow("Rate", String(format: "%.1f\u{00B0}/s", info.tiltRate))
                debugRow("Level", privacyManager.threatLevel.description)
            }
        }
        .font(.caption2.monospaced())
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 8)
        .padding(.top, 50)
        .allowsHitTesting(false)
    }

    private func debugRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            Text(value)
        }
    }
}

// MARK: - ThreatLevel + SwiftUI

extension ThreatLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .clear: "Clear"
        case .cautious: "Cautious"
        case .threatened: "Threatened"
        case .locked: "Locked"
        }
    }

    /// SwiftUI color for visual threat level indication.
    public var color: Color {
        switch self {
        case .clear: .green
        case .cautious: .yellow
        case .threatened: .orange
        case .locked: .red
        }
    }
}
