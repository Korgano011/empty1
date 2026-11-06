import SwiftUI

enum CasinoGame: String, Codable, CaseIterable, Identifiable {
    case pitch, euchre, hearts, spades, knaves, pepper, ninetyNine, fourHundred, diamonds

    var id: Self { self }

    /// What each guest pays to be turned into an alien animal by the cottage machine before a home card game.
    static let transformFee = 10

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
        }
    }

    /// Seats at a just-for-fun table, Debbie included.
    var funSeats: Int { self == .knaves || self == .ninetyNine ? 3 : 4 }
    var isPartners: Bool { [.euchre, .spades, .pepper, .fourHundred].contains(self) }

    /// The score that ends a just-for-fun game.
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
        /// Diamonds goes by rounds, not points: one deal per player.
        case .diamonds: 4
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
}

/// What the family does next: a trip in the flying zoo, or a card game hosted at home.
enum Outing {
    case trip
    case cards(CasinoGame)
}

/// A card game at home goes in the album as an event with no venue setup fee.
extension EventRecord {
    var isCardGame: Bool { cardGame != nil || retiredGame != nil }
    var title: String { cardGame.map { "\($0.name) at Home" } ?? (retiredGame != nil ? "Card Game at Home" : venue.name) }
    var shortTitle: String { cardGame?.name ?? (retiredGame != nil ? "Card Game" : venue.shortName) }
    var icon: String { cardGame?.icon ?? (retiredGame != nil ? "suit.club.fill" : venue.icon) }
    var accent: Color { cardGame?.accent ?? (retiredGame != nil ? .gray : venue.accent) }
}

/// Before each outing: the flying zoo, or one of the Roswell casino's card games played at home.
struct OutingPicker: View {
    let cash: Int
    let pick: (Outing) -> Void
    var body: some View {
        VStack(spacing: 10) {
            Button {
                pick(.trip)
            } label: {
                Label("Flying Zoo Trip — pick a destination", systemImage: "airplane")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(cash < Venue.cheapestFee)
            Text("…or host a card game at the house: no travel, no setup fee. Every guest is turned into an alien animal in the cottage first — $\(CasinoGame.transformFee) a transformation.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            box("Card Games — Just for Fun", "Debbie and a daughter (you!) play too · the family turns into alien animals too · no buy-in", CasinoGame.allCases) { EmptyView() }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func box(_ title: String, _ subtitle: String, _ games: [CasinoGame], @ViewBuilder options: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(.headline, design: .rounded, weight: .heavy))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            options()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                ForEach(games) { game in
                    Button {
                        pick(.cards(game))
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: game.icon).font(.title3)
                            Text(game.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                            Text(game.blurb).font(.caption2).multilineTextAlignment(.center)
                            Text("\(game.funSeats) players\(game.isPartners ? " · partners" : "")").font(.caption2.bold())
                        }
                        .frame(maxWidth: .infinity, minHeight: 78)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(game.accent)
                }
            }
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// One card in your hand.
struct CardButton: View {
    enum State { case idle, playable, picked, dimmed }
    let card: PlayingCard
    let state: State
    var width = 34.0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CardFace(card: card, width: width)
                .overlay(RoundedRectangle(cornerRadius: width * 0.14)
                    .strokeBorder(state == .picked ? Color.green : Color.yellow, lineWidth: 3)
                    .opacity(state == .picked || state == .playable ? 1 : 0))
                .offset(y: state == .picked ? -10 : 0)
                .opacity(state == .dimmed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state == .dimmed || state == .idle)
    }
}
