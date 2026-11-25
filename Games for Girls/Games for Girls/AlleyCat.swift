import SwiftUI

/// Alley Cat – two-player trick game with the 13 Clubs, 13 Spades and the 5♦ (the Alley Cat).
/// Higher rank wins the trick (Club beats Spade on a tie; the Alley Cat beats the other 5s).
/// A trick scores the difference between its two cards for the winner. A trick holding the
/// Alley Cat is scored as negative points, its winner draws and the loser leads.
/// Otherwise the loser draws and the winner leads. First to 44 wins.
struct AlleyCatView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    static let target = 44

    @State private var hands: [[PCard]] = [[], []]
    @State private var stock: [PCard] = []
    @State private var scores = [0, 0]
    @State private var handPts = [0, 0]
    @State private var dealer = 1
    @State private var leader = 0
    @State private var lead: PCard?
    @State private var reply: PCard?
    @State private var resolving = false
    @State private var handOver = false
    @State private var gameOver = false
    @State private var log: [String] = []
    @State private var started = false

    private var turn: Int { lead == nil ? leader : 1 - leader }
    private var myTurn: Bool { !resolving && !handOver && seats[turn].human && !hands[turn].isEmpty }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    PlayerChip(seat: seats[1], detail: "\(scores[1]) pts • \(hands[1].count) cards", active: turn == 1 && !handOver)
                    Spacer()
                    Text("First to \(Self.target)").font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: -30) {
                    ForEach(0..<hands[1].count, id: \.self) { _ in CardView(card: nil, w: 40) }
                }
                .frame(height: 60)

                table

                HStack {
                    PlayerChip(seat: seats[0], detail: "\(scores[0]) pts • this hand \(handPts[0])", active: turn == 0 && !handOver)
                    Spacer()
                }
                Text(prompt).font(.subheadline.bold()).foregroundStyle(Palette.pink)
                HStack(spacing: 6) {
                    ForEach(sorted(hands[0])) { c in
                        Button { humanPlay(c) } label: { CardView(card: c, w: 48, dim: !myTurn) }
                            .buttonStyle(.plain)
                            .disabled(!myTurn)
                    }
                }
                .frame(minHeight: 80)

                if handOver && !gameOver {
                    Button { nextHand() } label: { Label("Next Hand", systemImage: "arrow.right").frame(maxWidth: 220) }
                        .buttonStyle(.borderedProminent).tint(Palette.pink)
                }
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.suffix(5).enumerated()), id: \.offset) { _, l in
                        Text(l).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Card values: A=1 … K=13. A trick is worth the difference between its two cards. The 🐱 5♦ Alley Cat makes a trick count against whoever takes it.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding()
        }
        .onAppear {
            guard !started else { return }
            started = true
            dealer = Int.random(in: 0...1)
            deal()
        }
    }

    private var table: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                if stock.isEmpty {
                    RoundedRectangle(cornerRadius: 6).stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4])).frame(width: 52, height: 73)
                } else {
                    CardView(card: nil, w: 52)
                }
                Text("Draw pile \(stock.count)").font(.caption2)
            }
            HStack(spacing: 10) {
                trickSlot(lead, who: lead == nil ? nil : leader)
                trickSlot(reply, who: reply == nil ? nil : 1 - leader)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.1, green: 0.45, blue: 0.3)))
    }

    private func trickSlot(_ c: PCard?, who: Int?) -> some View {
        VStack(spacing: 4) {
            if let c {
                CardView(card: c, w: 60)
            } else {
                RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4])).frame(width: 60, height: 84)
            }
            Text(who.map { seats[$0].name } ?? " ").font(.caption2.bold()).foregroundStyle(.white)
        }
    }

    private var prompt: String {
        if gameOver { return "Game over!" }
        if handOver { return "Hand over." }
        if resolving { return " " }
        if seats[turn].human { return lead == nil ? "Your lead – play any card." : "Play any card to answer \(lead!.name)." }
        return "\(seats[turn].name) is thinking…"
    }

    private func sorted(_ h: [PCard]) -> [PCard] {
        h.sorted { ($0.suit, $0.rank) < ($1.suit, $1.rank) }
    }

    // MARK: flow

    private func deal() {
        var deck = (1...13).map { PCard(rank: $0, suit: 0) } + (1...13).map { PCard(rank: $0, suit: 3) } + [PCard(rank: 5, suit: 1)]
        deck.shuffle()
        hands = [Array(deck[0..<6]), Array(deck[6..<12])]
        stock = Array(deck[12...])
        handPts = [0, 0]
        lead = nil; reply = nil
        handOver = false
        leader = 1 - dealer
        log.append("\(seats[dealer].name) deals. \(seats[leader].name) leads.")
        Sound.shared.play(.flip)
        nextTurn()
    }

    private func nextHand() {
        dealer = 1 - dealer
        deal()
    }

    private func nextTurn() {
        if hands[0].isEmpty || hands[1].isEmpty { endHand(); return }
        let p = turn
        if !seats[p].human {
            later(1.0) { aiPlay(p) }
        }
    }

    private func humanPlay(_ c: PCard) {
        guard myTurn else { return }
        play(turn, c)
    }

    private func play(_ p: Int, _ c: PCard) {
        hands[p].removeAll { $0 == c }
        Sound.shared.play(.flip)
        if lead == nil {
            lead = c
            nextTurn()
        } else {
            reply = c
            resolve()
        }
    }

    /// Does card a (played second) beat card b (led)?
    static func beats(_ a: PCard, _ b: PCard) -> Bool {
        if a.rank != b.rank { return a.rank > b.rank }
        if a.isAlleyCat { return true }
        if b.isAlleyCat { return false }
        return a.suit == 0   // Club beats Spade
    }

    /// (winner is the follower?, points to the winner)
    static func outcome(lead: PCard, reply: PCard) -> (followerWins: Bool, pts: Int, cat: Bool) {
        let cat = lead.isAlleyCat || reply.isAlleyCat
        let v = abs(lead.rank - reply.rank)
        return (beats(reply, lead), cat ? -v : v, cat)
    }

    private func resolve() {
        guard let l = lead, let r = reply else { return }
        resolving = true
        let o = Self.outcome(lead: l, reply: r)
        let w = o.followerWins ? 1 - leader : leader
        let loser = 1 - w
        scores[w] += o.pts
        handPts[w] += o.pts
        if o.cat {
            log.append("🐱 Alley Cat! \(seats[w].name) takes \(l.name) & \(r.name) for \(o.pts) points.")
            Sound.shared.play(.lose)
        } else {
            log.append("\(seats[w].name) takes \(l.name) & \(r.name) for \(o.pts) point\(o.pts == 1 ? "" : "s").")
            Sound.shared.play(.chip)
        }
        let drawer = o.cat ? w : loser
        let nextLeader = o.cat ? loser : w
        later(1.6) {
            if !stock.isEmpty { hands[drawer].append(stock.removeLast()) }
            lead = nil; reply = nil
            leader = nextLeader
            resolving = false
            nextTurn()
        }
    }

    private func endHand() {
        handOver = true
        log.append("Hand over: \(seats[0].name) \(handPts[0]), \(seats[1].name) \(handPts[1]). Score \(scores[0])–\(scores[1]).")
        if max(scores[0], scores[1]) >= Self.target && scores[0] != scores[1] {
            gameOver = true
            let w = scores[0] > scores[1] ? 0 : 1
            log.append("\(seats[w].name) wins with \(scores[w])!")
            later(2.0) { onFinish(GameOutcome(winner: seats[w].name, humanWon: seats[w].human)) }
        }
    }

    // MARK: AI

    private func aiPlay(_ p: Int) {
        guard !handOver, turn == p, !hands[p].isEmpty else { return }
        let hand = hands[p]
        let choice: PCard
        if let l = lead {
            // pick the answer that's best for us right now; keep high cards on ties
            choice = hand.max { a, b in
                let ga = gain(p, l, a), gb = gain(p, l, b)
                return ga != gb ? ga < gb : a.rank > b.rank
            }!
        } else {
            // lead the highest card (hard to beat); hold the Alley Cat back
            let plain = hand.filter { !$0.isAlleyCat }
            choice = plain.max { ($0.rank, $0.suit == 0 ? 1 : 0) < ($1.rank, $1.suit == 0 ? 1 : 0) } ?? hand[0]
        }
        play(p, choice)
    }

    private func gain(_ p: Int, _ l: PCard, _ c: PCard) -> Int {
        let o = Self.outcome(lead: l, reply: c)
        return o.followerWins ? o.pts : -o.pts
    }
}
