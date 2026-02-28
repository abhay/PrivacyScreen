import SwiftUI

// MARK: - SensitivityLevel

/// Controls when content becomes hidden based on the current threat level.
public enum SensitivityLevel: Sendable {
    /// Hidden at `.locked` only (e.g., merchant names).
    case low
    /// Hidden at `.threatened` and above (e.g., names, dates).
    case medium
    /// Hidden at `.cautious` and above (e.g., balances, card numbers, CVV).
    case high

    /// The threat level at which this sensitivity starts hiding content.
    var triggerLevel: ThreatLevel {
        switch self {
        case .low: .locked
        case .medium: .threatened
        case .high: .cautious
        }
    }
}

// MARK: - PrivacySensitiveModifier

/// View modifier that progressively blurs content based on threat level and sensitivity.
///
/// Apply using `.privacySensitive(level:)` on any view containing sensitive information.
struct PrivacySensitiveModifier: ViewModifier {
    let level: SensitivityLevel

    @EnvironmentObject private var privacyManager: PrivacyManager

    /// Blur radius based on how far above the trigger level the current threat is.
    private var blurRadius: CGFloat {
        guard privacyManager.isEnabled else { return 0 }
        let threat = privacyManager.threatLevel
        let trigger = level.triggerLevel

        guard threat >= trigger else { return 0 }

        // Progressive blur based on severity above trigger
        let severityAbove = threat.rawValue - trigger.rawValue
        switch severityAbove {
        case 0: return 8
        case 1: return 16
        default: return 24
        }
    }

    /// Whether to show the material overlay (at higher threat levels).
    private var showMaterialOverlay: Bool {
        guard privacyManager.isEnabled else { return false }
        let threat = privacyManager.threatLevel
        let trigger = level.triggerLevel
        guard threat >= trigger else { return false }
        return (threat.rawValue - trigger.rawValue) >= 1
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: blurRadius)
            .overlay {
                if showMaterialOverlay {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: privacyManager.threatLevel)
    }
}

// MARK: - View Extension

public extension View {
    /// Mark this view as containing privacy-sensitive content.
    ///
    /// Content will be progressively blurred based on the current threat level
    /// and the specified sensitivity level.
    ///
    /// - Parameter level: How sensitive the content is (determines when blurring begins).
    func privacySensitive(level: SensitivityLevel = .high) -> some View {
        modifier(PrivacySensitiveModifier(level: level))
    }
}
