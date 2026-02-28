import PrivacyScreen
import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var privacyManager: PrivacyManager
    @EnvironmentObject private var powerThrottler: PowerThrottler

    @State private var tiltSensitivity: Double = 25
    @State private var gazeSensitivity: Double = 0.3

    var body: some View {
        ScrollView {
            VStack(spacing: VaultTheme.paddingMedium) {
                privacyToggles
                sensitivityControls
                infoSection
                simulateSection
            }
            .padding(.horizontal, VaultTheme.paddingMedium)
            .padding(.top, VaultTheme.paddingMedium)
            .padding(.bottom, 100)
        }
        .background(VaultTheme.background)
    }

    // MARK: - Privacy Toggles

    private var privacyToggles: some View {
        VStack(spacing: 0) {
            settingsToggle(
                icon: "shield.checkered",
                title: "Privacy Protection",
                subtitle: "Monitor for visual threats",
                isOn: $privacyManager.isEnabled
            )

            Divider().overlay(VaultTheme.border)

            settingsToggle(
                icon: "ladybug.fill",
                title: "Debug Overlays",
                subtitle: "Show sensor readouts",
                isOn: $privacyManager.showDebugOverlay
            )
        }
        .vaultCard()
    }

    private func settingsToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: VaultTheme.grid(3)) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(VaultTheme.accent)
                .frame(width: 36, height: 36)
                .background(VaultTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: VaultTheme.grid(2)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(VaultTheme.accent)
        }
        .padding(.vertical, VaultTheme.grid(2))
    }

    // MARK: - Sensitivity Controls

    private var sensitivityControls: some View {
        VStack(spacing: VaultTheme.paddingMedium) {
            VStack(alignment: .leading, spacing: VaultTheme.grid(2)) {
                HStack {
                    Text("Tilt Sensitivity")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(Int(tiltSensitivity))\u{00B0}")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(VaultTheme.textSecondary)
                }

                Slider(value: $tiltSensitivity, in: 10 ... 50, step: 5)
                    .tint(VaultTheme.accent)
                    .onChange(of: tiltSensitivity) { _, newValue in
                        privacyManager.config.tiltThresholdLow = Float(newValue)
                        privacyManager.config.tiltThresholdHigh = Float(newValue + 15)
                    }

                Text("Lower values trigger protection sooner when the device is tilted")
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)
            }

            Divider().overlay(VaultTheme.border)

            VStack(alignment: .leading, spacing: VaultTheme.grid(2)) {
                HStack {
                    Text("Gaze Sensitivity")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(String(format: "%.1f rad", gazeSensitivity))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(VaultTheme.textSecondary)
                }

                Slider(value: $gazeSensitivity, in: 0.1 ... 0.6, step: 0.05)
                    .tint(VaultTheme.accent)
                    .onChange(of: gazeSensitivity) { _, newValue in
                        privacyManager.config.gazeThresholdLow = Float(newValue)
                        privacyManager.config.gazeThresholdHigh = Float(newValue + 0.2)
                    }

                Text("Lower values trigger protection sooner when gaze drifts away")
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)
            }
        }
        .vaultCard()
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: VaultTheme.grid(3)) {
            Label("How It Works", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VaultTheme.accent)

            VStack(alignment: .leading, spacing: 10) {
                infoRow(
                    icon: "faceid",
                    text: "Detects if someone else is looking at your screen using the TrueDepth camera"
                )
                infoRow(
                    icon: "gyroscope",
                    text: "Monitors device tilt angle to detect shoulder surfing positions"
                )
                infoRow(
                    icon: "hand.raised.fingers.spread.fill",
                    text: "Detects rapid device movement that may indicate a snatch attempt"
                )
                infoRow(
                    icon: "eye.slash.fill",
                    text: "Progressively blurs sensitive content based on threat severity"
                )
                infoRow(
                    icon: "battery.75percent",
                    text: "Intelligent power management reduces battery impact by up to 95%"
                )
            }
        }
        .vaultCard()
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(VaultTheme.textSecondary)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(VaultTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Simulate Section

    private var simulateSection: some View {
        Button {
            privacyManager.simulateThreat(duration: 3.0)
        } label: {

            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 18))
                Text("Simulate Threat")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.red.opacity(0.8), .orange.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: VaultTheme.cornerRadiusSmall)
            )
        }
        .buttonStyle(VaultButtonStyle())
    }
}
