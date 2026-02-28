import SwiftUI

// MARK: - VaultTheme

/// Design system constants for the VaultDemo app.
enum VaultTheme {

    // MARK: - Colors

    /// Primary background color (#0A0A0F).
    static let background = Color(red: 0.039, green: 0.039, blue: 0.059)

    /// Slightly elevated surface color.
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.12)

    /// Card/container background.
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.15)

    /// Subtle border color.
    static let border = Color.white.opacity(0.08)

    /// Primary accent color.
    static let accent = Color(red: 0.4, green: 0.5, blue: 1.0)

    /// Positive change / income color.
    static let positive = Color(red: 0.3, green: 0.85, blue: 0.5)

    /// Negative change / expense color.
    static let negative = Color(red: 1.0, green: 0.4, blue: 0.4)

    /// Muted text color.
    static let textMuted = Color.white.opacity(0.5)

    /// Secondary text color.
    static let textSecondary = Color.white.opacity(0.7)

    // MARK: - Card Gradients

    static let cardGradientBlue = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.3, blue: 0.8),
            Color(red: 0.4, green: 0.2, blue: 0.7),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradientDark = LinearGradient(
        colors: [
            Color(red: 0.15, green: 0.15, blue: 0.2),
            Color(red: 0.1, green: 0.1, blue: 0.15),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Spacing

    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12

    // MARK: - Fonts

    /// Large hero number font (SF Pro Rounded).
    static let heroNumber = Font.system(size: 42, weight: .bold, design: .rounded)

    /// Medium number font.
    static let mediumNumber = Font.system(size: 24, weight: .semibold, design: .rounded)

    /// Small number font.
    static let smallNumber = Font.system(size: 18, weight: .semibold, design: .rounded)

    /// Card number font (monospaced).
    static let cardNumber = Font.system(size: 20, weight: .medium, design: .monospaced)

    // MARK: - Helpers

    /// Format a dollar amount.
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    /// Format a percentage change.
    static func formatChange(_ amount: Double, total: Double) -> String {
        let pct = (amount / (total - amount)) * 100
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(formatCurrency(amount)) (\(String(format: "%.2f", pct))%)"
    }
}

// MARK: - View Extension

extension View {
    /// Apply a VaultTheme card style.
    func vaultCard() -> some View {
        padding(VaultTheme.paddingMedium)
            .background(VaultTheme.cardBackground, in: RoundedRectangle(cornerRadius: VaultTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: VaultTheme.cornerRadius)
                    .strokeBorder(VaultTheme.border, lineWidth: 1)
            )
    }
}
