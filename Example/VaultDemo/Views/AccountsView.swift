import PrivacyScreen
import SwiftUI

// MARK: - AccountsView

struct AccountsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: VaultTheme.paddingMedium) {
                ForEach(Account.samples) { account in
                    accountCard(account)
                }
            }
            .padding(.horizontal, VaultTheme.paddingMedium)
            .padding(.top, VaultTheme.paddingMedium)
            .padding(.bottom, 100)
        }
        .background(VaultTheme.background)
    }

    private func accountCard(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: VaultTheme.paddingMedium) {
            HStack {
                Image(systemName: account.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(VaultTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        VaultTheme.accent.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: VaultTheme.cornerRadiusSmall)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(account.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(VaultTheme.textMuted)
                }

                Spacer()
            }

            Divider()
                .overlay(VaultTheme.border)

            HStack {
                VStack(alignment: .leading, spacing: VaultTheme.grid(1)) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundStyle(VaultTheme.textMuted)

                    Text(VaultTheme.formatCurrency(account.balance))
                        .font(VaultTheme.mediumNumber)
                        .foregroundStyle(.white)
                        .privacySensitive(level: .high)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: VaultTheme.grid(1)) {
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(VaultTheme.textMuted)

                    Text("+\(VaultTheme.formatCurrency(account.dailyChange))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VaultTheme.positive)
                        .privacySensitive(level: .high)
                }
            }

            HStack {
                Text("Account")
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)

                Spacer()

                Text(account.accountNumber)
                    .font(.caption.monospaced())
                    .foregroundStyle(VaultTheme.textSecondary)
                    .privacySensitive(level: .high)
            }
        }
        .vaultCard()
    }
}
