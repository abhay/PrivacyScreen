import Foundation

// MARK: - Account

struct Account: Identifiable {
    let id = UUID()
    let name: String
    let type: AccountType
    let accountNumber: String
    let maskedNumber: String
    let balance: Double
    let dailyChange: Double
    let icon: String

    enum AccountType: String {
        case checking = "Checking"
        case savings = "Savings"
        case investment = "Investment"
    }
}

// MARK: - Sample Data

extension Account {
    static let samples: [Account] = [
        Account(
            name: "Primary Checking",
            type: .checking,
            accountNumber: "4821 7293 0048 4281",
            maskedNumber: "••••4281",
            balance: 42_847.33,
            dailyChange: 1_247.50,
            icon: "building.columns.fill"
        ),
        Account(
            name: "High-Yield Savings",
            type: .savings,
            accountNumber: "7382 0194 5528 9103",
            maskedNumber: "••••9103",
            balance: 89_412.67,
            dailyChange: 412.83,
            icon: "banknote.fill"
        ),
        Account(
            name: "Growth Portfolio",
            type: .investment,
            accountNumber: "9201 4837 2910 6547",
            maskedNumber: "••••6547",
            balance: 51_969.47,
            dailyChange: 1_187.00,
            icon: "chart.line.uptrend.xyaxis"
        )
    ]

    static var totalBalance: Double {
        samples.reduce(0) { $0 + $1.balance }
    }

    static var totalDailyChange: Double {
        samples.reduce(0) { $0 + $1.dailyChange }
    }
}
