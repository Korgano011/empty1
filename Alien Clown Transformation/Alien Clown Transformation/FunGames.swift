import SwiftUI

/// The just-for-fun card games played on a day at sea — the same games the Roswell Cottage Casino deals for fun.
/// Nobody bets: it's just for fun, and the winner gets bragging rights.
enum CasinoGame: String, Codable, CaseIterable, Identifiable {
    case pitch, euchre, hearts, spades, knaves, pepper, ninetyNine, fourHundred, diamonds, allFours, fives

    var id: Self { self }

    static let funGames: [CasinoGame] = allCases
    /// Fives: the total every player is aiming for without going over.
    static let fivesGoal = 25

    /// Every game on the ship is just for fun.
    var isMoney: Bool { false }

    var name: String {
        switch self {
        case .pitch: "Pitch"
        case .euchre: "Euchre"
        case .hearts: "Hearts"
        case .spades: "Spades"
        case .knaves: "Knaves"
        case .pepper: "Pepper"
        case .ninetyNine: "99"
        case .fourHundred: "400"
        case .diamonds: "Diamonds"
        case .allFours: "All Fours"
        case .fives: "Fives"
        }
    }

    var icon: String {
        switch self {
        case .pitch: "baseball.fill"
        case .euchre: "person.2.fill"
        case .hearts: "suit.heart.fill"
        case .spades: "suit.spade.fill"
        case .knaves: "person.3.fill"
        case .pepper: "flame.fill"
        case .ninetyNine: "number.square.fill"
        case .fourHundred: "number.circle.fill"
        case .diamonds: "diamond.fill"
        case .allFours: "4.circle.fill"
        case .fives: "5.circle.fill"
        }
    }

    var blurb: String {
        switch self {
        case .pitch: "No partners · High, Low, Jack, Game · to \(target)"
        case .euchre: "Partners, bowers · to \(target)"
        case .hearts: "Dodge the Q♠ · ends at \(target)"
        case .spades: "Blind double nil · to \(target)"
        case .knaves: "Avoid the jacks · to \(target)"
        case .pepper: "Bid or get peppered · to \(target)"
        case .ninetyNine: "Hit your bid exactly · to \(target)"
        case .fourHundred: "Partners · one to \(target)"
        case .diamonds: "Collect crystals · \(target) rounds"
        case .allFours: "Partners · High, Low, Jack, Game · to \(target)"
        case .fives: "Hit exactly \(Self.fivesGoal) in \(target) hands · Magenta 5s"
        }
    }

    /// Seats at the table.
    var funSeats: Int { self == .knaves || self == .ninetyNine ? 3 : 4 }
    var isPartners: Bool { [.euchre, .spades, .pepper, .fourHundred, .allFours].contains(self) }
    /// Games that end after a set number of deals instead of at a score.
    var byRounds: Bool { self == .diamonds || self == .fives }

    /// The score that ends the game.
    var target: Int {
        switch self {
        case .pitch: 11
        case .euchre: 10
        case .hearts: 100
        case .spades: 300
        case .knaves: 20
        case .pepper: 30
        case .ninetyNine: 100
        case .fourHundred: 41
        // Diamonds goes by rounds, not points: one deal per player.
        case .diamonds: 4
        case .allFours: 11
        // Fives goes by hands too: four deals, closest to 25 without going over.
        case .fives: 4
        }
    }

    var accent: Color { Color(red: 0.20, green: 0.55, blue: 0.85) }
}

/// One line on the scoreboard: a player and her score.
struct BoardRow: Identifiable {
    let id: String
    var value: String
    var note: String
    /// Partner games: 0 or 1.
    var team: Int?
    var out = false
}

struct TableBoard {
    let game: CasinoGame
    var status: String
    var rows: [BoardRow]
    var pot: Int?
}

/// What the player picks for the next part of a cruise day.
enum DayPlan {
    case port(Venue)
    case sea(CasinoGame)
    case end
    /// Everyone spends the night aboard; next morning the ship calls at two more ports, then takes them all back.
    case overnight
}
