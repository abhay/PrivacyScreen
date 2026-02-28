import Foundation

// MARK: - CardTheme

/// Visual theme for a payment card. SwiftUI rendering extensions live in VaultTheme.swift.
enum CardTheme {
    case blue
    case slate
}

// MARK: - Card

struct Card: Identifiable {
    let id = UUID()
    let cardNumber: String
    let cardholderName: String
    let expiryDate: String
    let cvv: String
    let type: CardType
    let network: CardNetwork
    let theme: CardTheme

    enum CardType: String {
        case credit = "Credit"
        case debit = "Debit"
    }

    enum CardNetwork: String {
        case visa = "Visa"
        case mastercard = "Mastercard"
    }

    var maskedNumber: String {
        let last4 = String(cardNumber.suffix(4))
        return "•••• •••• •••• \(last4)"
    }

    var formattedNumber: String {
        var result = ""
        for (index, char) in cardNumber.filter(\.isNumber).enumerated() {
            if index > 0, index % 4 == 0 { result += " " }
            result.append(char)
        }
        return result
    }
}

// MARK: - Sample Data

extension Card {
    static let samples: [Card] = [
        Card(
            cardNumber: "4829173650284019",
            cardholderName: "ABHAY KUMAR",
            expiryDate: "09/28",
            cvv: "847",
            type: .credit,
            network: .visa,
            theme: .blue
        ),
        Card(
            cardNumber: "5291048273619405",
            cardholderName: "ABHAY KUMAR",
            expiryDate: "03/27",
            cvv: "312",
            type: .debit,
            network: .mastercard,
            theme: .slate
        ),
    ]
}
