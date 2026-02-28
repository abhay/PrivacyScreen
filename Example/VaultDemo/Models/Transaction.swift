import Foundation

// MARK: - Transaction

struct Transaction: Identifiable {
    let id = UUID()
    let merchant: String
    let category: String
    let amount: Double
    let date: Date
    let icon: String
    let isCredit: Bool

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let formatted = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
        return isCredit ? "+\(formatted)" : "-\(formatted)"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Data

extension Transaction {
    static let samples: [Transaction] = {
        let calendar = Calendar.current
        let now = Date()

        return [
            Transaction(
                merchant: "Apple Inc.",
                category: "Technology",
                amount: 2499.00,
                date: calendar.date(byAdding: .hour, value: -3, to: now)!,
                icon: "laptopcomputer",
                isCredit: false
            ),
            Transaction(
                merchant: "Stripe Transfer",
                category: "Income",
                amount: 8450.00,
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                icon: "arrow.down.circle.fill",
                isCredit: true
            ),
            Transaction(
                merchant: "Whole Foods Market",
                category: "Groceries",
                amount: 127.43,
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                icon: "cart.fill",
                isCredit: false
            ),
            Transaction(
                merchant: "Tesla Supercharger",
                category: "Transportation",
                amount: 18.76,
                date: calendar.date(byAdding: .day, value: -2, to: now)!,
                icon: "bolt.fill",
                isCredit: false
            ),
            Transaction(
                merchant: "Netflix",
                category: "Entertainment",
                amount: 22.99,
                date: calendar.date(byAdding: .day, value: -3, to: now)!,
                icon: "play.rectangle.fill",
                isCredit: false
            ),
            Transaction(
                merchant: "Dividend Payment",
                category: "Investment",
                amount: 342.18,
                date: calendar.date(byAdding: .day, value: -4, to: now)!,
                icon: "chart.bar.fill",
                isCredit: true
            ),
            Transaction(
                merchant: "Blue Bottle Coffee",
                category: "Food & Drink",
                amount: 6.50,
                date: calendar.date(byAdding: .day, value: -4, to: now)!,
                icon: "cup.and.saucer.fill",
                isCredit: false
            ),
            Transaction(
                merchant: "Amazon Web Services",
                category: "Technology",
                amount: 847.23,
                date: calendar.date(byAdding: .day, value: -5, to: now)!,
                icon: "cloud.fill",
                isCredit: false
            )
        ]
    }()
}
