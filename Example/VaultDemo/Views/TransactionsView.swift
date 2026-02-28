import SwiftUI
import PrivacyScreen

// MARK: - TransactionsView

struct TransactionsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Transaction.samples) { transaction in
                    transactionRow(transaction)
                    if transaction.id != Transaction.samples.last?.id {
                        Divider()
                            .overlay(VaultTheme.border)
                            .padding(.leading, 60)
                    }
                }
            }
            .vaultCard()
            .padding(.horizontal, VaultTheme.paddingMedium)
            .padding(.top, VaultTheme.paddingMedium)
            .padding(.bottom, 100)
        }
        .background(VaultTheme.background)
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(transaction.isCredit ? VaultTheme.positive : VaultTheme.textSecondary)
                .frame(width: 40, height: 40)
                .background(
                    (transaction.isCredit ? VaultTheme.positive : Color.white).opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 10)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.merchant)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .privacySensitive(level: .low)

                Text(transaction.category)
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)

                Text(transaction.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(VaultTheme.textMuted)
                    .privacySensitive(level: .medium)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(transaction.isCredit ? VaultTheme.positive : .white)
                .privacySensitive(level: .high)
        }
        .padding(.vertical, 12)
    }
}
