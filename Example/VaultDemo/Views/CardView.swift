import SwiftUI
import PrivacyScreen

// MARK: - CardView

struct CardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: VaultTheme.paddingLarge) {
                ForEach(Card.samples) { card in
                    creditCardView(card)
                }
            }
            .padding(.horizontal, VaultTheme.paddingMedium)
            .padding(.top, VaultTheme.paddingMedium)
            .padding(.bottom, 100)
        }
        .background(VaultTheme.background)
    }

    private func creditCardView(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: network logo and type
            HStack {
                Text(card.network.rawValue)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(card.type.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.15), in: Capsule())
            }

            Spacer()
                .frame(height: 40)

            // Card number
            Text(card.formattedNumber)
                .font(VaultTheme.cardNumber)
                .foregroundStyle(.white)
                .privacySensitive(level: .high)

            Spacer()
                .frame(height: 24)

            // Bottom row: cardholder, expiry, CVV
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CARDHOLDER")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(card.cardholderName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .privacySensitive(level: .medium)
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("EXPIRES")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(card.expiryDate)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .privacySensitive(level: .medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("CVV")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Text(card.cvv)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .privacySensitive(level: .high)
                }
            }
        }
        .padding(VaultTheme.paddingLarge)
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(
            card.network == .visa ? VaultTheme.cardGradientBlue : VaultTheme.cardGradientDark,
            in: RoundedRectangle(cornerRadius: VaultTheme.cornerRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VaultTheme.cornerRadius)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}
