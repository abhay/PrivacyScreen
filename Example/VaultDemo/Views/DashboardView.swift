import SwiftUI
import PrivacyScreen

// MARK: - DashboardView

struct DashboardView: View {
    @EnvironmentObject private var privacyManager: PrivacyManager

    var body: some View {
        ScrollView {
            VStack(spacing: VaultTheme.paddingLarge) {
                heroBalanceSection
                quickActionsRow
                accountsSection
                recentActivitySection
            }
            .padding(.horizontal, VaultTheme.paddingMedium)
            .padding(.top, VaultTheme.paddingMedium)
            .padding(.bottom, 100)
        }
        .background(VaultTheme.background)
    }

    // MARK: - Hero Balance

    private var heroBalanceSection: some View {
        VStack(spacing: 8) {
            Text("Total Balance")
                .font(.subheadline)
                .foregroundStyle(VaultTheme.textMuted)

            Text(VaultTheme.formatCurrency(Account.totalBalance))
                .font(VaultTheme.heroNumber)
                .foregroundStyle(.white)
                .privacySensitive(level: .high)

            Text(VaultTheme.formatChange(Account.totalDailyChange, total: Account.totalBalance))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(VaultTheme.positive)
                .privacySensitive(level: .high)

            sparklineChart
                .frame(height: 60)
                .padding(.top, 8)
                .privacySensitive(level: .high)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VaultTheme.paddingLarge)
    }

    // MARK: - Sparkline Chart

    private var sparklineChart: some View {
        let dataPoints: [Double] = [
            168_200, 170_450, 169_800, 172_100, 171_500, 174_300,
            173_800, 176_900, 175_200, 178_400, 177_100, 180_300,
            179_500, 181_200, 182_800, 181_900, 183_400, 184_229
        ]

        let minVal = dataPoints.min() ?? 0
        let maxVal = dataPoints.max() ?? 1
        let range = maxVal - minVal

        return GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let stepX = width / CGFloat(dataPoints.count - 1)

            ZStack {
                // Gradient fill
                Path { path in
                    for (index, value) in dataPoints.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat((value - minVal) / range) * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [VaultTheme.positive.opacity(0.3), VaultTheme.positive.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    for (index, value) in dataPoints.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat((value - minVal) / range) * height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(VaultTheme.positive, lineWidth: 2)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 0) {
            quickAction(icon: "arrow.up.right", label: "Send")
            quickAction(icon: "arrow.down.left", label: "Request")
            quickAction(icon: "creditcard.fill", label: "Pay")
            quickAction(icon: "arrow.left.arrow.right", label: "Transfer")
        }
        .vaultCard()
    }

    private func quickAction(icon: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(VaultTheme.accent)
                .frame(width: 44, height: 44)
                .background(VaultTheme.accent.opacity(0.12), in: Circle())

            Text(label)
                .font(.caption)
                .foregroundStyle(VaultTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Accounts Section

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(Account.samples) { account in
                accountRow(account)
            }
        }
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(VaultTheme.accent)
                .frame(width: 40, height: 40)
                .background(VaultTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)

                Text(account.maskedNumber)
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)
                    .privacySensitive(level: .medium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(VaultTheme.formatCurrency(account.balance))
                    .font(VaultTheme.smallNumber)
                    .foregroundStyle(.white)
                    .privacySensitive(level: .high)

                Text("+\(VaultTheme.formatCurrency(account.dailyChange))")
                    .font(.caption)
                    .foregroundStyle(VaultTheme.positive)
                    .privacySensitive(level: .high)
            }
        }
        .vaultCard()
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("See All")
                    .font(.subheadline)
                    .foregroundStyle(VaultTheme.accent)
            }

            ForEach(Transaction.samples) { transaction in
                transactionRow(transaction)
            }
        }
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(transaction.isCredit ? VaultTheme.positive : VaultTheme.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    (transaction.isCredit ? VaultTheme.positive : Color.white).opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 8)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchant)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .privacySensitive(level: .low)

                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundStyle(VaultTheme.textMuted)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(transaction.isCredit ? VaultTheme.positive : .white)
                .privacySensitive(level: .high)
        }
        .padding(.vertical, 4)
    }
}
