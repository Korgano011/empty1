import SwiftUI

/// Crazy Eights – 2 to 5 players. Match the top card's suit or rank; eights are wild and
/// name a new suit. Can't play? Draw until you can (or pass when the stock is gone).
/// First to get rid of all their cards wins.
struct CrazyEightsView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    @State private var hands: [[PCard]] = []
    @State private var stock: [PCard] = []
    @State private var pile: [PCard] = []
    @State private var suit = 0          // suit to match (an eight may have changed it)
    @State private var turn = 0
    @State private var choosingSuit: PCard?
    @State private var over = false
    @State private var lastDrawn: PCard?
    @State private var log: [String] = []
    @State private var started = false
    @State private var passes = 0

    private var n: Int { seats.count }
    private var me: Int { 0 }
    private var top: PCard? { pile.last }
    private var myTurn: Bool { !over && turn == me && choosingSuit == nil }
    private let suitNames = ["♣ Clubs", "♦ Diamonds", "♥ Hearts", "♠ Spades"]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if !hands.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(0..<n, id: \.self) { p in
                                PlayerChip(seat: seats[p], detail: "\(hands[p].count) cards", active: turn == p && !over)
                            }
                        }
                    }
                    table
                    Text(prompt).font(.subheadline.bold()).foregroundStyle(Palette.pink).multilineTextAlignment(.center)
                    if let eight = choosingSuit { suitPicker(eight) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -10) {
                            ForEach(hands[me].sorted { ($0.suit, $0.rank) < ($1.suit, $1.rank) }) { c in
                                Button { humanPlay(c) } label: {
                                    CardView(card: c, w: 48, highlight: c == lastDrawn, dim: myTurn && !playable(c))
                                }
                                .buttonStyle(.plain)
                                .disabled(!myTurn)
                            }
                        }
                        .padding(.top, 8).padding(.horizontal, 4)
                    }
                    HStack {
                        Button("Draw a Card") { humanDraw() }
                            .disabled(!myTurn || stock.isEmpty)
                        if myTurn && stock.isEmpty && !hands[me].contains(where: playable) {
                            Button("Pass") { pass(me) }
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(Palette.pink)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(log.suffix(4).enumerated()), id: \.offset) { _, l in
                            Text(l).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Match the suit or the number. Eights are wild – play one any time and pick the new suit. First to run out of cards wins!")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .onAppear {
            guard !started else { return }
            started = true
            deal()
        }
    }

    private var table: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                if stock.isEmpty {
                    RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4])).frame(width: 56, height: 78)
                } else {
                    CardView(card: nil, w: 56)
                }
                Text("Stock \(stock.count)").font(.caption2).foregroundStyle(.white)
            }
            VStack(spacing: 4) {
                if let top { CardView(card: top, w: 64) }
                Text("Play on \(suitNames[suit])").font(.caption2.bold()).foregroundStyle(.white)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.1, green: 0.45, blue: 0.3)))
    }

    private func suitPicker(_ eight: PCard) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { s in
                Button(suitNames[s]) { finishEight(me, eight, suit: s) }
                    .buttonStyle(.bordered)
                    .tint(s == 1 || s == 2 ? .red : .primary)
            }
        }
    }

    private var prompt: String {
        if over { return "Game over!" }
        if choosingSuit != nil { return "Crazy eight! Pick the new suit:" }
        if turn == me { return "Your turn – play a matching card or an eight, or draw." }
        return "\(seats[turn].name) is thinking…"
    }

    // MARK: flow

    private func deal() {
        var deck = PCard.fullDeck().shuffled()
        let size = n == 2 ? 7 : 5
        hands = (0..<n).map { _ in let h = Array(deck.prefix(size)); deck.removeFirst(size); return h }
        // the starter can't be an eight
        let i = deck.firstIndex { $0.rank != 8 }!
        pile = [deck.remove(at: i)]
        suit = pile[0].suit
        stock = deck
        turn = Int.random(in: 0..<n)
        log.append("\(seats[turn].name) goes first.")
        Sound.shared.play(.flip)
        startTurn()
    }

    private func playable(_ c: PCard) -> Bool {
        guard let top else { return true }
        return c.rank == 8 || c.suit == suit || c.rank == top.rank
    }

    private func startTurn() {
        lastDrawn = nil
        if !seats[turn].human {
            let p = turn
            later(1.0) { aiTurn(p) }
        }
    }

    private func advance() {
        turn = (turn + 1) % n
        startTurn()
    }

    private func humanPlay(_ c: PCard) {
        guard myTurn, playable(c) else { return }
        if c.rank == 8 {
            hands[me].removeAll { $0 == c }
            pile.append(c)
            Sound.shared.play(.flip)
            if hands[me].isEmpty { finishEight(me, c, suit: c.suit); return }
            choosingSuit = c
        } else {
            place(me, c)
        }
    }

    private func humanDraw() {
        guard myTurn, !stock.isEmpty else { return }
        let c = stock.removeLast()
        hands[me].append(c)
        lastDrawn = c
        Sound.shared.play(.flip)
    }

    private func place(_ p: Int, _ c: PCard) {
        hands[p].removeAll { $0 == c }
        pile.append(c)
        suit = c.suit
        log.append("\(seats[p].name) plays \(c.name).")
        Sound.shared.play(.flip)
        afterPlay(p)
    }

    private func finishEight(_ p: Int, _ c: PCard, suit s: Int) {
        choosingSuit = nil
        suit = s
        log.append("\(seats[p].name) plays a crazy \(c.name) – the suit is now \(suitNames[s])!")
        Sound.shared.play(.sparkle)
        afterPlay(p)
    }

    private func pass(_ p: Int) {
        log.append("\(seats[p].name) can't play and passes.")
        passes += 1
        if passes >= n {
            // blocked: nobody can play and the stock is gone – fewest cards wins
            over = true
            let w = (0..<n).min { hands[$0].count < hands[$1].count }!
            log.append("Nobody can play! \(seats[w].name) has the fewest cards and wins.")
            later(1.8) { onFinish(GameOutcome(winner: seats[w].name, humanWon: seats[w].human)) }
            return
        }
        advance()
    }

    private func afterPlay(_ p: Int) {
        passes = 0
        if hands[p].isEmpty {
            over = true
            log.append("\(seats[p].name) is out of cards and wins!")
            later(1.8) { onFinish(GameOutcome(winner: seats[p].name, humanWon: seats[p].human)) }
            return
        }
        if hands[p].count == 1 { log.append("\(seats[p].name): \"Last card!\"") }
        advance()
    }

    // MARK: AI

    private func aiTurn(_ p: Int) {
        guard !over, turn == p else { return }
        let options = hands[p].filter(playable)
        let plain = options.filter { $0.rank != 8 }
        func count(_ s: Int) -> Int { hands[p].filter { $0.suit == s && $0.rank != 8 }.count }
        if let c = plain.max(by: { count($0.suit) < count($1.suit) }) {
            place(p, c)
        } else if let eight = options.first {
            hands[p].removeAll { $0 == eight }
            pile.append(eight)
            let best = (0..<4).max { count($0) < count($1) }!
            finishEight(p, eight, suit: hands[p].isEmpty ? eight.suit : best)
        } else if !stock.isEmpty {
            hands[p].append(stock.removeLast())
            Sound.shared.play(.flip)
            later(0.5) { aiTurn(p) }
        } else {
            pass(p)
        }
    }
}
