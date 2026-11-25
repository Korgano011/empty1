import SwiftUI

/// I'm Out – 3 to 6 players, one 52-card deck, suits ignored (A = 1 … K = 13).
/// Deal 10/9/8/7 cards for 3/4/5/6 players; the rest stay face down out of play.
/// Build a row by playing to its far left (equal or lower) or far right (equal or higher) end.
/// A new stack must have at least as many cards as the stack at that end; matching cards
/// can always be added onto an end stack. Can't (or won't) play? Say "I'm Out", take one card
/// from either end of the row and sit out the round. When one player is left, the row is
/// discarded and that player leads the next round. First to play their last card wins.
struct ImOutView: View {
    /// everyone available (you first); the player picks how many sit down
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    struct Stack: Identifiable {
        let id = UUID()
        var rank: Int
        var cards: [PCard]
    }

    @State private var hands: [[PCard]] = []
    @State private var row: [Stack] = []
    @State private var active: [Bool] = []
    @State private var turn = 0
    @State private var round = 1
    @State private var selected: Set<PCard> = []
    @State private var choosingTake = false
    @State private var over = false
    @State private var log: [String] = []
    @State private var started = false
    @State private var lastTaken: PCard?
    @State private var players: [Seat] = []

    private var n: Int { players.count }
    private var me: Int { 0 }
    private var myTurn: Bool { !over && turn == me && active.indices.contains(me) && active[me] }
    private var selRank: Int? { selected.first?.rank }

    static func dealSize(_ players: Int) -> Int {
        switch players { case 3: 10; case 4: 9; case 5: 8; default: 7 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if hands.isEmpty {
                    playerPicker
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(0..<n, id: \.self) { p in
                                PlayerChip(seat: players[p],
                                           detail: active[p] ? "\(hands[p].count) cards" : "I'm Out · \(hands[p].count)",
                                           active: turn == p && !over)
                                    .opacity(active[p] || over ? 1 : 0.5)
                            }
                        }
                    }
                    Text("Round \(round)").font(.caption.bold()).foregroundStyle(.secondary)
                    rowView
                    Text(prompt).font(.subheadline.bold()).foregroundStyle(Palette.pink).multilineTextAlignment(.center)
                    if choosingTake { takePicker }
                    handView
                    if !choosingTake { buttons }
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(log.suffix(4).enumerated()), id: \.offset) { _, l in
                            Text(l).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Suits don't count – A is 1, J 11, Q 12, K 13. Play to the far LEFT end (same or lower) or far RIGHT end (same or higher). A new stack needs at least as many cards as the end stack. Can't play? Say I'm Out and take a card from an end. First to play their last card wins!")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    private var playerPicker: some View {
        VStack(spacing: 14) {
            Text("How many players?").font(.title2.bold()).foregroundStyle(Palette.pink)
            HStack(spacing: 12) {
                ForEach(3...6, id: \.self) { k in
                    Button { start(with: k) } label: {
                        VStack(spacing: 2) {
                            Text("\(k)").font(.title.bold())
                            Text("\(Self.dealSize(k)) cards").font(.caption2)
                        }
                        .frame(width: 54, height: 60)
                    }
                    .buttonStyle(.borderedProminent).tint(Palette.pink)
                }
            }
            Text("Extra seats are filled by girls from the ship's lounge.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }

    private func start(with count: Int) {
        guard !started else { return }
        started = true
        var list = Array(seats.prefix(count))
        var used = Set(list.map(\.name))
        while list.count < count {
            let g = Passenger.random()
            guard !used.contains(g.girlName) else { continue }
            used.insert(g.girlName)
            list.append(Seat(name: g.girlName, look: g.look, human: false))
        }
        players = list
        Sound.shared.play(.click)
        deal()
    }

    // MARK: views

    private var rowView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    if row.isEmpty {
                        Text(over ? "" : "The row is empty – \(players[turn].name) starts a new row.")
                            .font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
                            .frame(height: 96)
                    }
                    ForEach(Array(row.enumerated()), id: \.element.id) { i, s in
                        VStack(spacing: 2) {
                            Text(i == 0 && row.count > 1 ? "LEFT" : i == row.count - 1 && row.count > 1 ? "RIGHT" : row.count == 1 ? "BOTH ENDS" : " ")
                                .font(.system(size: 9, weight: .heavy)).foregroundStyle(.yellow)
                            ZStack(alignment: .top) {
                                ForEach(Array(s.cards.enumerated()), id: \.offset) { j, c in
                                    CardView(card: c, w: 40).offset(y: CGFloat(j) * 14)
                                }
                            }
                            .frame(height: 56 + CGFloat(max(0, s.cards.count - 1)) * 14, alignment: .top)
                            Text("×\(s.cards.count)").font(.caption2.bold()).foregroundStyle(.white)
                        }
                        .opacity(i == 0 || i == row.count - 1 ? 1 : 0.6)
                        .id(s.id)
                    }
                }
                .padding(.horizontal, 6)
            }
            .onChange(of: row.count) {
                if let last = row.last { withAnimation { proxy.scrollTo(last.id) } }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(red: 0.1, green: 0.45, blue: 0.3)))
    }

    private var handView: some View {
        let mine = hands[me].sorted { ($0.rank, $0.suit) < ($1.rank, $1.suit) }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -10) {
                ForEach(mine) { c in
                    Button { tap(c) } label: {
                        if active[me] || over {
                            CardView(card: c, w: 48, selected: selected.contains(c), highlight: c == lastTaken,
                                     dim: myTurn && !rankPlayable(c.rank))
                        } else {
                            CardView(card: nil, w: 48)   // hand set face down while out
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!myTurn || choosingTake)
                }
            }
            .padding(.top, 14).padding(.horizontal, 4)
        }
    }

    @ViewBuilder private var buttons: some View {
        if myTurn {
            HStack {
                if row.isEmpty {
                    Button("Start the Row") { humanPlay(left: true) }.disabled(selected.isEmpty)
                } else {
                    Button("◀︎ Play Left") { humanPlay(left: true) }.disabled(!canPlay(left: true))
                    Button("Play Right ▶︎") { humanPlay(left: false) }.disabled(!canPlay(left: false))
                }
            }
            .buttonStyle(.borderedProminent).tint(Palette.pink)
            if !row.isEmpty {
                Button("I'm Out!") { selected = []; choosingTake = true }
                    .buttonStyle(.bordered).tint(.orange)
            }
        }
    }

    private var takePicker: some View {
        VStack(spacing: 6) {
            Text("Take one card from an end of the row:").font(.caption)
            HStack {
                if let l = row.first {
                    Button("Take a \(rankName(l.rank)) from the left") { declareOut(me, takeLeft: true) }
                }
                if row.count > 1, let r = row.last {
                    Button("Take a \(rankName(r.rank)) from the right") { declareOut(me, takeLeft: false) }
                }
            }
            .buttonStyle(.borderedProminent).tint(.orange)
            Button("Never mind") { choosingTake = false }.font(.caption)
        }
    }

    private var prompt: String {
        if over { return "Game over!" }
        if choosingTake { return "I'm Out! Pick your card." }
        if !active[me] { return "You're out this round – \(players[turn].name) is playing…" }
        if turn == me {
            if row.isEmpty { return "You lead! Pick one or more cards of the same number." }
            if selected.isEmpty { return "Your turn – tap cards of one number, then play left or right." }
            return "\(selected.count) × \(rankName(selRank!)) selected."
        }
        return "\(players[turn].name) is thinking…"
    }

    private func rankName(_ r: Int) -> String {
        switch r { case 1: "Ace"; case 11: "Jack"; case 12: "Queen"; case 13: "King"; default: "\(r)" }
    }

    // MARK: rules

    /// Can `count` cards of `rank` go on the left (or right) end?
    private func legal(rank: Int, count: Int, left: Bool) -> Bool {
        guard count > 0 else { return false }
        guard let end = left ? row.first : row.last else { return true }
        if rank == end.rank { return true }                       // add onto the end stack
        let beyond = left ? rank < end.rank : rank > end.rank
        return beyond && count >= end.cards.count                  // new stack, at least as tall
    }

    private func rankPlayable(_ r: Int) -> Bool {
        let have = hands[me].filter { $0.rank == r }.count
        return row.isEmpty || legal(rank: r, count: have, left: true) || legal(rank: r, count: have, left: false)
    }

    private func canPlay(left: Bool) -> Bool {
        guard let r = selRank else { return false }
        return legal(rank: r, count: selected.count, left: left)
    }

    // MARK: flow

    private func deal() {
        var deck = PCard.fullDeck().shuffled()
        let size = Self.dealSize(n)
        hands = (0..<n).map { _ in let h = Array(deck.prefix(size)); deck.removeFirst(size); return h }
        active = Array(repeating: true, count: n)
        turn = Int.random(in: 0..<n)
        log.append("\(size) cards each, \(deck.count) left face down. \(players[turn].name) leads.")
        Sound.shared.play(.flip)
        startTurn()
    }

    private func tap(_ c: PCard) {
        guard myTurn else { return }
        if selected.contains(c) {
            selected.remove(c)
        } else {
            if let r = selRank, r != c.rank { selected = [] }
            selected.insert(c)
        }
        Sound.shared.play(.click)
    }

    private func startTurn() {
        lastTaken = turn == me ? lastTaken : nil
        if !players[turn].human {
            let p = turn
            later(active[me] ? 1.0 : 0.6) { aiTurn(p) }
        }
    }

    private func nextActive(after p: Int) -> Int {
        var q = p
        repeat { q = (q + 1) % n } while !active[q]
        return q
    }

    private func humanPlay(left: Bool) {
        guard myTurn, let r = selRank, legal(rank: r, count: selected.count, left: left) else { return }
        let cards = Array(selected)
        selected = []
        lastTaken = nil
        play(me, cards, left: left)
    }

    private func play(_ p: Int, _ cards: [PCard], left: Bool) {
        let r = cards[0].rank
        hands[p].removeAll { cards.contains($0) }
        let where_: String
        if row.isEmpty {
            row = [Stack(rank: r, cards: cards)]
            where_ = "to start the row"
        } else if left {
            if row[0].rank == r { row[0].cards += cards } else { row.insert(Stack(rank: r, cards: cards), at: 0) }
            where_ = "on the left"
        } else {
            if row[row.count - 1].rank == r { row[row.count - 1].cards += cards } else { row.append(Stack(rank: r, cards: cards)) }
            where_ = "on the right"
        }
        let what = cards.count == 1 ? "a \(rankName(r))" : "\(cards.count) \(rankName(r))s"
        log.append("\(players[p].name) plays \(what) \(where_).")
        Sound.shared.play(.flip)
        if hands[p].isEmpty {
            over = true
            log.append("\(players[p].name) played her last card and wins!")
            Sound.shared.play(.sparkle)
            later(1.8) { onFinish(GameOutcome(winner: players[p].name, humanWon: players[p].human)) }
            return
        }
        turn = nextActive(after: p)
        startTurn()
    }

    private func declareOut(_ p: Int, takeLeft: Bool) {
        choosingTake = false
        guard !row.isEmpty else { return }
        let i = takeLeft ? 0 : row.count - 1
        let c = row[i].cards.removeLast()
        if row[i].cards.isEmpty { row.remove(at: i) }
        hands[p].append(c)
        if p == me { lastTaken = c }
        active[p] = false
        log.append("\(players[p].name): \"I'm Out!\" – takes a \(rankName(c.rank)).")
        Sound.shared.play(.chip)
        let left = (0..<n).filter { active[$0] }
        if left.count <= 1 {
            let leader = left.first ?? p
            later(1.2) { newRound(leader: leader) }
            return
        }
        turn = nextActive(after: p)
        startTurn()
    }

    private func newRound(leader: Int) {
        guard !over else { return }
        let cleared = row.reduce(0) { $0 + $1.cards.count }
        row = []
        active = Array(repeating: true, count: n)
        round += 1
        turn = leader
        log.append("Round over – \(cleared) cards discarded. \(players[leader].name) leads round \(round).")
        Sound.shared.play(.flip)
        if round > 150 {
            // safety net – fewest cards wins
            over = true
            let w = (0..<n).min { hands[$0].count < hands[$1].count }!
            log.append("Time's up! \(players[w].name) has the fewest cards and wins.")
            later(1.8) { onFinish(GameOutcome(winner: players[w].name, humanWon: players[w].human)) }
            return
        }
        startTurn()
    }

    // MARK: AI

    private func aiTurn(_ p: Int) {
        guard !over, turn == p, active[p] else { return }
        let hand = hands[p]
        let groups = Dictionary(grouping: hand, by: \.rank)

        if row.isEmpty {
            // lead with the biggest group, preferring middle numbers so both ends stay open
            let best = groups.max { a, b in
                (a.value.count * 10 - abs(a.key - 7)) < (b.value.count * 10 - abs(b.key - 7))
            }!
            play(p, best.value, left: true)
            return
        }

        var bestPlay: (cards: [PCard], left: Bool, score: Int)?
        for (r, cards) in groups {
            for left in [true, false] {
                guard legal(rank: r, count: cards.count, left: left) else { continue }
                guard let end = left ? row.first : row.last else { continue }
                // play the fewest cards that are legal unless dumping them all is close to winning
                let need = r == end.rank ? 1 : end.cards.count
                let useAll = hand.count - cards.count <= 2 || cards.count - need <= 1
                let use = useAll ? cards : Array(cards.prefix(need))
                let gap = abs(r - end.rank)
                var score = use.count * 12 - gap * 2
                if hand.count == use.count { score += 1000 }           // winning play
                if r == 1 || r == 13 { score += 3 }                      // seal an end
                if bestPlay == nil || score > bestPlay!.score { bestPlay = (use, left, score) }
            }
        }
        if let b = bestPlay {
            play(p, b.cards, left: b.left)
            return
        }
        // I'm Out – take the end card that best matches what's in hand (or an extreme card)
        let lRank = row.first!.rank, rRank = row.last!.rank
        func value(_ r: Int) -> Int { (groups[r]?.count ?? 0) * 10 + abs(r - 7) }
        declareOut(p, takeLeft: row.count == 1 || value(lRank) >= value(rRank))
    }
}
