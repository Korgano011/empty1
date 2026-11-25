import SwiftUI

/// A standard playing card. rank 1 = Ace … 13 = King; suit 0 ♣, 1 ♦, 2 ♥, 3 ♠.
struct PCard: Hashable, Identifiable {
    let rank: Int
    let suit: Int
    var id: Int { suit * 13 + rank }

    var isRed: Bool { suit == 1 || suit == 2 }
    var suitSymbol: String { ["♣", "♦", "♥", "♠"][suit] }
    var rankText: String {
        switch rank {
        case 1: "A"
        case 11: "J"
        case 12: "Q"
        case 13: "K"
        default: "\(rank)"
        }
    }
    var name: String { rankText + suitSymbol }
    /// The Alley Cat – the 5 of Diamonds.
    var isAlleyCat: Bool { rank == 5 && suit == 1 }

    static func fullDeck() -> [PCard] {
        (0..<4).flatMap { s in (1...13).map { PCard(rank: $0, suit: s) } }
    }
}

/// A drawn card face (or back when `card` is nil).
struct CardView: View {
    var card: PCard?
    var w: CGFloat = 48
    var selected = false
    var highlight = false
    var dim = false
    /// nil = the style in use (gameLook.cards)
    var style: CardStyle? = nil

    var body: some View {
        let h = w * 1.4
        let st = style ?? gameLook.cards
        let design: Font.Design = st.serif ? .serif : .rounded
        ZStack {
            if let card {
                RoundedRectangle(cornerRadius: w * 0.12).fill(st.face)
                let ink = card.isRed ? st.red : st.black
                VStack(spacing: 0) {
                    HStack {
                        VStack(spacing: -2) {
                            Text(card.rankText).font(.system(size: w * 0.3, weight: .bold, design: design))
                            Text(card.suitSymbol).font(.system(size: w * 0.24))
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(ink)
                .padding(w * 0.07)
                Text(card.isAlleyCat ? "🐱" : card.suitSymbol)
                    .font(.system(size: w * 0.42))
                    .foregroundStyle(ink)
                    .offset(x: w * 0.1, y: h * 0.12)
            } else {
                RoundedRectangle(cornerRadius: w * 0.12).fill(
                    LinearGradient(colors: [st.back1, st.back2], startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: w * 0.08).stroke(.white.opacity(0.7), lineWidth: 1.5).padding(w * 0.08)
                Text(st.emblem).font(.system(size: w * 0.35)).foregroundStyle(.white.opacity(0.85))
            }
            RoundedRectangle(cornerRadius: w * 0.12)
                .stroke(selected ? Palette.pink : highlight ? Color.yellow : Color.black.opacity(0.3), lineWidth: selected || highlight ? 3 : 1)
        }
        .frame(width: w, height: h)
        .shadow(color: .black.opacity(0.15), radius: 1.5, y: 1)
        .opacity(dim ? 0.45 : 1)
        .offset(y: selected ? -12 : 0)
    }
}

/// Name + score chip used by the card games.
struct PlayerChip: View {
    var seat: Seat
    var detail: String
    var active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Avatar(look: seat.look, size: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(seat.name).font(.caption.bold()).lineLimit(1)
                Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 10).fill(active ? Palette.pink.opacity(0.25) : Color.gray.opacity(0.1)))
    }
}
