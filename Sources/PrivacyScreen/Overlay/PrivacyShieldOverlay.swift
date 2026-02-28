import SwiftUI

// MARK: - PrivacyShieldOverlay

/// Full-screen overlay displayed when threat level reaches `.locked`.
///
/// Layers:
/// 1. Ultra-thin material blur
/// 2. Animated pixel scatter effect
/// 3. Lock icon and status text
///
/// Touch events pass through via `.allowsHitTesting(false)`.
public struct PrivacyShieldOverlay: View {
    @EnvironmentObject private var privacyManager: PrivacyManager

    private var isActive: Bool {
        privacyManager.isEnabled && privacyManager.threatLevel == .locked
    }

    public init() {}

    public var body: some View {
        ZStack {
            if isActive {
                // Layer 1: Material blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Layer 2: Pixel scatter animation
                PixelScatterEffect()
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Layer 3: Lock icon and text
                VStack(spacing: 16) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Privacy Mode Active")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .allowsHitTesting(false)
    }
}
