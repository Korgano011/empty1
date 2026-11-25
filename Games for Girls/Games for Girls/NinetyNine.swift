import SwiftUI

/// Ninety-Nine (David Parlett) – 3 players, 36 cards (6 up to A), 12 each.
/// Everyone secretly lays aside 3 cards as their bid: ♣ = 3, ♥ = 2, ♠ = 1, ♦ = 0 tricks.
/// The other 9 cards are played as tricks (follow suit). 1 point per trick; making your bid
/// exactly earns 30 if you're the only one, 20 if two make it, 10 if all three do.
/// First deal is no trump; afterwards trumps are ♣/♥/♠/♦ when 3/2/1/0 players made their bids.
/// Game is 100.
struct NinetyNineView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    static let target = 100
    static func bidValue(_ c: PCard) -> Int { [3, 0, 2, 1][c.suit] }   // ♣ ♦ ♥ ♠
    static func power(_ c: PCard) -> Int { c.rank == 1 ? 14 : c.rank }

    enum Step { case bidding, playing, handOver, gameOver }

    @State private var hands: [[PCard]] = [[], [], []]
    @State private var bidCards: [[PCard]] = [[], [], []]
    @State private var tricks = [0, 0, 0]
    @State private var scores = [0, 0, 0]
    @State private var trump: Int? = nil
    @State private var dealer = 0
    @State private var turn = 0
    @State private var trick: [(Int, PCard)] = []
    @State private var step: Step = .bidding
    @State private var selected: Set<PCard> = []
    @State private var resolving = false
    @State private var log: [String] = []
    @State private var summary: [String] = []
    @State private var started = false

    private var me: Int { 0 }
    private var bid: [Int] { bidCards.map { $0.reduce(0) { $0 + Self.bidValue($1) } } }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    ForEach(0..<3, id: \.self) { p in
                        PlayerChip(seat: seats[p], detail: detail(p), active: step == .playing && turn == p)
                    }
                }
                Text("Trumps: \(trumpName)  •  First to \(Self.target)").font(.caption.bold())
                trickArea
                Text(prompt).font(.subheadline.bold()).foregroundStyle(Palette.pink).multilineTextAlignment(.center)
                if step == .bidding { bidPreview }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -10) {
                        ForEach(sorted(hands[me])) { c in
                            Button { tap(c) } label: {
                                CardView(card: c, w: 46, selected: selected.contains(c), dim: step == .playing && !legal(c, for: me))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 16).padding(.horizontal, 4)
                }
                if step == .handOver || step == .gameOver { summaryView }
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.suffix(4).enumerated()), id: \.offset) { _, l in
                        Text(l).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Bid cards: ♣ = 3, ♥ = 2, ♠ = 1, ♦ = 0 tricks. Take exactly your bid! 1 point per trick, plus 30 if you're the only one to make it, 20 if two do, 10 if all three do.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding()
        }
        .onAppear {
            guard !started else { return }
            started = true
            dealer = Int.random(in: 0..<3)
            deal()
        }
    }

    private var trumpName: String { trump.map { ["♣ Clubs", "♦ Diamonds", "♥ Hearts", "♠ Spades"][$0] } ?? "No trump" }

    private func detail(_ p: Int) -> String {
        // "won/bid" – opponents' bids stay secret until the hand is over
        if step == .bidding { return "\(scores[p]) pts" }
        let b = p == me || step != .playing ? "\(bid[p])" : "?"
        return "\(scores[p]) pts • \(tricks[p])/\(b)"
    }

    private var trickArea: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { k in
                VStack(spacing: 4) {
                    if k < trick.count {
                        CardView(card: trick[k].1, w: 56)
                        Text(seats[trick[k].0].name).font(.caption2.bold()).foregroundStyle(.white).lineLimit(1)
                    } else {
                        RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4])).frame(width: 56, height: 78)
                        Text(" ").font(.caption2)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.1, green: 0.45, blue: 0.3)))
    }

    private var bidPreview: some View {
        let v = selected.reduce(0) { $0 + Self.bidValue($1) }
        return HStack {
            Text(selected.count == 3 ? "Bid \(v) trick\(v == 1 ? "" : "s")" : "Pick \(3 - selected.count) more").font(.headline)
            Button("Lay Aside as My Bid") { humanBid() }
                .buttonStyle(.borderedProminent).tint(Palette.pink)
                .disabled(selected.count != 3)
        }
    }

    private var summaryView: some View {
        VStack(spacing: 6) {
            Text(step == .gameOver ? "Game Over" : "Hand Over").font(.headline)
            ForEach(summary, id: \.self) { Text($0).font(.caption) }
            if step == .handOver {
                Button { dealer = (dealer + 1) % 3; deal() } label: { Label("Next Hand", systemImage: "arrow.right").frame(maxWidth: 220) }
                    .buttonStyle(.borderedProminent).tint(Palette.pink)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.pink.opacity(0.12)))
    }

    private var prompt: String {
        switch step {
        case .bidding: return "Choose 3 cards to lay aside face down – their suits are your secret bid."
        case .handOver, .gameOver: return " "
        case .playing:
            if resolving { return " " }
            if turn == me { return trick.isEmpty ? "Your lead. You bid \(bid[me]), you've won \(tricks[me])." : "Your play – follow suit if you can." }
            return "\(seats[turn].name) is thinking…"
        }
    }

    private func sorted(_ h: [PCard]) -> [PCard] {
        h.sorted { ($0.suit, Self.power($0)) < ($1.suit, Self.power($1)) }
    }

    // MARK: flow

    private func deal() {
        var deck = (0..<4).flatMap { s in ([1] + Array(6...13)).map { PCard(rank: $0, suit: s) } }.shuffled()
        hands = (0..<3).map { _ in let h = Array(deck.prefix(12)); deck.removeFirst(12); return h }
        bidCards = [[], [], []]
        tricks = [0, 0, 0]
        trick = []
        selected = []
        summary = []
        step = .bidding
        log.append("\(seats[dealer].name) deals. Trumps: \(trumpName).")
        Sound.shared.play(.flip)
        for p in 0..<3 where !seats[p].human {
            let b = aiChooseBid(hands[p])
            bidCards[p] = b
            hands[p].removeAll { b.contains($0) }
        }
    }

    private func tap(_ c: PCard) {
        switch step {
        case .bidding:
            if selected.contains(c) { selected.remove(c) } else if selected.count < 3 { selected.insert(c) }
            Sound.shared.play(.click)
        case .playing:
            guard turn == me, !resolving, legal(c, for: me) else { return }
            play(me, c)
        default: break
        }
    }

    private func humanBid() {
        guard selected.count == 3 else { return }
        bidCards[me] = Array(selected)
        hands[me].removeAll { selected.contains($0) }
        selected = []
        log.append("You lay aside a bid of \(bid[me]). Everyone has bid secretly.")
        Sound.shared.play(.chip)
        step = .playing
        turn = (dealer + 1) % 3
        nextTurn()
    }

    private func legal(_ c: PCard, for p: Int) -> Bool {
        guard let led = trick.first?.1 else { return true }
        return c.suit == led.suit || !hands[p].contains { $0.suit == led.suit }
    }

    private func nextTurn() {
        if !seats[turn].human {
            let p = turn
            later(0.9) { aiPlay(p) }
        }
    }

    private func play(_ p: Int, _ c: PCard) {
        hands[p].removeAll { $0 == c }
        trick.append((p, c))
        Sound.shared.play(.flip)
        if trick.count == 3 {
            resolve()
        } else {
            turn = (turn + 1) % 3
            nextTurn()
        }
    }

    private func winnerOf(_ t: [(Int, PCard)]) -> Int {
        let led = t[0].1.suit
        let best = t.max { a, b in key(a.1, led) < key(b.1, led) }!
        return best.0
    }

    private func key(_ c: PCard, _ led: Int) -> Int {
        if let trump, c.suit == trump { return 200 + Self.power(c) }
        return c.suit == led ? 100 + Self.power(c) : 0
    }

    private func resolve() {
        resolving = true
        let w = winnerOf(trick)
        tricks[w] += 1
        log.append("\(seats[w].name) wins the trick with \(trick.first { $0.0 == w }!.1.name).")
        Sound.shared.play(.chip)
        later(1.4) {
            trick = []
            resolving = false
            if hands.allSatisfy({ $0.isEmpty }) { endHand(); return }
            turn = w
            nextTurn()
        }
    }

    private func endHand() {
        let made = (0..<3).filter { tricks[$0] == bid[$0] }
        let bonus = [0, 30, 20, 10][made.count]
        var lines: [String] = []
        for p in 0..<3 {
            let ok = made.contains(p)
            scores[p] += tricks[p] + (ok ? bonus : 0)
            let shown = ok ? " (bid cards: \(bidCards[p].map(\.name).joined(separator: " ")))" : ""
            lines.append("\(seats[p].name): bid \(bid[p]), took \(tricks[p]) \(ok ? "✅ +\(bonus)" : "❌")\(shown) → \(scores[p])")
        }
        trump = [1, 3, 2, 0][made.count]   // 0 made → ♦, 1 → ♠, 2 → ♥, 3 → ♣
        lines.append("Next hand's trumps: \(trumpName)")
        summary = lines
        Sound.shared.play(made.contains(me) ? .win : .lose)
        let top = scores.max()!
        if top >= Self.target && scores.filter({ $0 == top }).count == 1 {
            step = .gameOver
            let w = scores.firstIndex(of: top)!
            summary.removeLast()
            summary.append("\(seats[w].name) wins with \(top)!")
            later(2.5) { onFinish(GameOutcome(winner: seats[w].name, humanWon: seats[w].human)) }
        } else {
            step = .handOver
        }
    }

    // MARK: AI

    /// Rough number of tricks a 9-card hand should take.
    private func estimate(_ h: [PCard]) -> Double {
        var e = 0.0
        for s in 0..<4 {
            let suit = h.filter { $0.suit == s }.map { Self.power($0) }.sorted(by: >)
            let isTrump = trump == s
            for (i, r) in suit.enumerated() {
                if isTrump {
                    e += r == 14 ? 1 : r == 13 ? 0.9 : r == 12 ? 0.75 : r >= 10 ? 0.55 : 0.4
                } else {
                    let base: Double = r == 14 ? 0.9 : r == 13 ? 0.6 : r == 12 ? 0.3 : r == 11 ? 0.12 : 0.03
                    e += i < 3 ? base : base * 0.5
                    if trump == nil && i >= 4 { e += 0.35 }   // long suit at no trump
                }
            }
            if trump != nil && !isTrump && suit.count <= 1 { e += Double(h.filter { $0.suit == trump }.count) * 0.12 }
        }
        return e
    }

    private func aiChooseBid(_ hand: [PCard]) -> [PCard] {
        var best: [PCard] = Array(hand.prefix(3))
        var bestErr = Double.infinity
        let n = hand.count
        for i in 0..<n { for j in (i + 1)..<n { for k in (j + 1)..<n {
            let b = [hand[i], hand[j], hand[k]]
            let rest = hand.filter { !b.contains($0) }
            let v = Double(b.reduce(0) { $0 + Self.bidValue($1) })
            let err = abs(estimate(rest) - v) + Double.random(in: 0..<0.05)
            if err < bestErr { bestErr = err; best = b }
        } } }
        return best
    }

    private func aiPlay(_ p: Int) {
        guard step == .playing, turn == p, !resolving else { return }
        let options = hands[p].filter { legal($0, for: p) }
        let wantWin = tricks[p] < bid[p]
        func wins(_ c: PCard) -> Bool {
            guard !trick.isEmpty else { return false }
            return winnerOf(trick + [(p, c)]) == p
        }
        func strength(_ c: PCard) -> Int { (trump == c.suit ? 100 : 0) + Self.power(c) }
        var choice: PCard
        if trick.isEmpty {
            // lead: strong card when we still need tricks, weak card when we're done
            choice = wantWin ? options.max { strength($0) < strength($1) }! : options.min { strength($0) < strength($1) }!
        } else {
            let winners = options.filter(wins), losers = options.filter { !wins($0) }
            if wantWin, let c = winners.min(by: { strength($0) < strength($1) }) {
                choice = c
            } else if !wantWin, let c = losers.max(by: { strength($0) < strength($1) }) {
                choice = c
            } else {
                choice = options.min { strength($0) < strength($1) }!
            }
        }
        play(p, choice)
    }
}
