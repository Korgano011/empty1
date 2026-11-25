import SwiftUI

/// 500 Rummy – 2 to 4 players. Draw from the stock or take any card from the discard pile
/// (plus every card on top of it) as long as you meld that card right away. Meld sets and runs,
/// lay off on anyone's melds, then discard. Melded cards score for you; cards left in hand count
/// against you. Ace = 15 (1 in A-2-3), 10/J/Q/K = 10, 2–9 = 5. First to 500 wins.
struct Meld: Identifiable {
    let id = UUID()
    var cards: [PCard]
    var owners: [Int]
}

enum Rummy {
    static let target = 500

    static func handValue(_ c: PCard) -> Int { c.rank == 1 ? 15 : c.rank >= 10 ? 10 : 5 }

    static func isSet(_ cs: [PCard]) -> Bool { cs.count >= 3 && Set(cs.map(\.rank)).count == 1 }

    /// The run in order (ace low or high), or nil if not a run.
    static func runOrder(_ cs: [PCard]) -> [PCard]? {
        guard cs.count >= 3, Set(cs.map(\.suit)).count == 1 else { return nil }
        for aceHigh in [false, true] {
            let r = cs.map { $0.rank == 1 && aceHigh ? 14 : $0.rank }.sorted()
            if Set(r).count == r.count, r.last! - r.first! == r.count - 1 {
                return cs.sorted { ($0.rank == 1 && aceHigh ? 14 : $0.rank) < ($1.rank == 1 && aceHigh ? 14 : $1.rank) }
            }
        }
        return nil
    }

    static func isValid(_ cs: [PCard]) -> Bool { isSet(cs) || runOrder(cs) != nil }

    static func arranged(_ cs: [PCard]) -> [PCard] {
        if let run = runOrder(cs) { return run }
        return cs.sorted { $0.suit < $1.suit }
    }

    /// Points of each card inside a meld (ace counts 1 in a low run).
    static func meldValue(_ c: PCard, in cs: [PCard]) -> Int {
        if c.rank == 1, let run = runOrder(cs), run.first == c { return 1 }
        return handValue(c)
    }

    static func credited(_ p: Int, _ melds: [Meld]) -> Int {
        melds.reduce(0) { sum, m in
            sum + zip(m.cards, m.owners).filter { $0.1 == p }.reduce(0) { $0 + meldValue($1.0, in: m.cards) }
        }
    }

    static func layoffIndex(_ c: PCard, _ melds: [Meld]) -> Int? {
        melds.firstIndex { isValid($0.cards + [c]) }
    }

    /// A meld containing `c` that can be made from `c` plus cards in `pool`.
    static func meldWith(_ c: PCard, _ pool: [PCard]) -> [PCard]? {
        let same = pool.filter { $0.rank == c.rank && $0 != c }
        var best: [PCard]? = same.count >= 2 ? [c] + same.prefix(3) : nil
        if let run = runWith(c, pool), run.count > (best?.count ?? 0) { best = run }
        return best
    }

    /// The longest run through `c` made from same-suit cards in `pool`.
    static func runWith(_ c: PCard, _ pool: [PCard]) -> [PCard]? {
        let suited = pool.filter { $0.suit == c.suit && $0 != c }
        var best: [PCard]? = nil
        for aceHigh in [false, true] {
            func v(_ x: PCard) -> Int { x.rank == 1 && aceHigh ? 14 : x.rank }
            var byV: [Int: PCard] = [:]
            for x in suited { byV[v(x)] = x }
            var run = [c]
            var lo = v(c) - 1, hi = v(c) + 1
            while let x = byV[lo] { run.insert(x, at: 0); lo -= 1 }
            while let x = byV[hi] { run.append(x); hi += 1 }
            if run.count >= 3, run.count > (best?.count ?? 0) { best = run }
        }
        return best
    }

    static func canUse(_ c: PCard, pool: [PCard], table: [Meld]) -> Bool {
        layoffIndex(c, table) != nil || meldWith(c, pool) != nil
    }

    /// Greedily find melds in a hand; tries runs-first and sets-first and keeps the bigger total.
    static func findMelds(_ hand: [PCard]) -> [[PCard]] {
        func greedy(runsFirst: Bool) -> [[PCard]] {
            var rest = hand
            var out: [[PCard]] = []
            for pass in 0..<2 {
                let runs = (pass == 0) == runsFirst
                while true {
                    var best: [PCard]? = nil
                    for c in rest {
                        let m: [PCard]?
                        if runs {
                            m = runWith(c, rest)
                        } else {
                            let same = rest.filter { $0.rank == c.rank }
                            m = same.count >= 3 ? same : nil
                        }
                        if let m, m.count > (best?.count ?? 0) { best = m }
                    }
                    guard let b = best else { break }
                    out.append(b)
                    rest.removeAll { b.contains($0) }
                }
            }
            return out
        }
        let a = greedy(runsFirst: true), b = greedy(runsFirst: false)
        func total(_ ms: [[PCard]]) -> Int { ms.joined().reduce(0) { $0 + handValue($1) } }
        return total(a) >= total(b) ? a : b
    }
}

struct Rummy500View: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    enum Step { case draw, play, ai, handOver, gameOver }

    @State private var hands: [[PCard]] = []
    @State private var stock: [PCard] = []
    @State private var discard: [PCard] = []
    @State private var melds: [Meld] = []
    @State private var scores: [Int] = []
    @State private var dealer = 0
    @State private var turn = 0
    @State private var step: Step = .draw
    @State private var selected: Set<PCard> = []
    @State private var mustMeld: PCard?
    @State private var lastDrawn: Set<PCard> = []
    @State private var message = ""
    @State private var log: [String] = []
    @State private var summary: [String] = []
    @State private var started = false

    private var n: Int { seats.count }
    private var me: Int { 0 }
    private var myHand: [PCard] { hands.isEmpty ? [] : hands[me].sorted { ($0.suit, $0.rank) < ($1.suit, $1.rank) } }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if !hands.isEmpty {
                    opponents
                    tableView
                    pileRow
                    Text(message).font(.subheadline.bold()).foregroundStyle(Palette.pink).multilineTextAlignment(.center)
                    handView
                    controls
                    if step == .handOver || step == .gameOver { summaryView }
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(log.suffix(4).enumerated()), id: \.offset) { _, l in
                            Text(l).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Ace 15 (1 in A-2-3) • 10/J/Q/K 10 • 2–9 5. Melds score for you, cards left in hand count against you. First to \(Rummy.target).")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .onAppear {
            guard !started else { return }
            started = true
            scores = Array(repeating: 0, count: n)
            dealer = Int.random(in: 0..<n)
            deal()
        }
    }

    // MARK: views

    private var opponents: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<n, id: \.self) { p in
                    PlayerChip(seat: seats[p],
                               detail: "\(scores[p]) pts\(p == me ? "" : " • \(hands[p].count) cards")",
                               active: turn == p && step != .handOver && step != .gameOver)
                }
            }
        }
    }

    private var tableView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(melds.isEmpty ? "No melds yet" : "Melds on the table").font(.caption.bold()).foregroundStyle(.white.opacity(0.85))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8, alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(melds) { m in
                    HStack(spacing: -16) {
                        ForEach(Array(zip(m.cards, m.owners).enumerated()), id: \.offset) { _, co in
                            CardView(card: co.0, w: 32)
                                .overlay(alignment: .bottom) {
                                    Circle().fill(ownerColor(co.1)).frame(width: 7, height: 7).offset(y: 5)
                                }
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.1, green: 0.45, blue: 0.3)))
    }

    private func ownerColor(_ p: Int) -> Color { [Palette.pink, Palette.green, .purple, .orange][p % 4] }

    private var pileRow: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 3) {
                Button { humanDrawStock() } label: {
                    if stock.isEmpty {
                        RoundedRectangle(cornerRadius: 5).stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4])).frame(width: 44, height: 62)
                    } else {
                        CardView(card: nil, w: 44)
                    }
                }
                .buttonStyle(.plain)
                .disabled(step != .draw || stock.isEmpty)
                Text("Stock \(stock.count)").font(.caption2)
            }
            VStack(alignment: .leading, spacing: 3) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -14) {
                            ForEach(Array(discard.enumerated()), id: \.element.id) { i, c in
                                Button { humanTakeDiscard(i) } label: { CardView(card: c, w: 40) }
                                    .buttonStyle(.plain)
                                    .disabled(step != .draw)
                                    .id(c.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: discard.count) { if let l = discard.last { proxy.scrollTo(l.id, anchor: .trailing) } }
                }
                Text("Discard pile – tap a card to take it and everything on top of it").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var handView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -12) {
                ForEach(myHand) { c in
                    Button { toggle(c) } label: {
                        CardView(card: c, w: 48, selected: selected.contains(c), highlight: lastDrawn.contains(c) || c == mustMeld)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 16).padding(.horizontal, 4).padding(.bottom, 4)
        }
    }

    @ViewBuilder private var controls: some View {
        if step == .draw && seats[turn].human && stock.isEmpty {
            Button("Stock is empty – End the Hand") { endHand(reason: "The stock ran out.") }
                .buttonStyle(.bordered)
        }
        if step == .play {
            let sel = Array(selected)
            HStack(spacing: 8) {
                Button("Meld") { humanMeld(sel) }
                    .disabled(!Rummy.isValid(sel))
                Button("Lay Off") { humanLayoff(sel) }
                    .disabled(sel.isEmpty)
                Button("Discard") { humanDiscard(sel[0]) }
                    .disabled(sel.count != 1 || mustMeldPending)
            }
            .buttonStyle(.borderedProminent).tint(Palette.pink)
        }
    }

    private var summaryView: some View {
        VStack(spacing: 6) {
            Text(step == .gameOver ? "Game Over" : "Hand Over").font(.headline)
            ForEach(summary, id: \.self) { Text($0).font(.caption) }
            if step == .handOver {
                Button { dealer = (dealer + 1) % n; deal() } label: { Label("Next Hand", systemImage: "arrow.right").frame(maxWidth: 220) }
                    .buttonStyle(.borderedProminent).tint(Palette.pink)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.pink.opacity(0.12)))
    }

    private var mustMeldPending: Bool {
        if let m = mustMeld { return hands[me].contains(m) }
        return false
    }

    // MARK: flow

    private func deal() {
        var deck = PCard.fullDeck().shuffled()
        let size = n == 2 ? 13 : 7
        hands = (0..<n).map { _ in let h = Array(deck.prefix(size)); deck.removeFirst(size); return h }
        discard = [deck.removeLast()]
        stock = deck
        melds = []
        selected = []; mustMeld = nil; lastDrawn = []
        summary = []
        turn = (dealer + 1) % n
        log.append("\(seats[dealer].name) deals \(size) cards each.")
        Sound.shared.play(.flip)
        startTurn()
    }

    private func startTurn() {
        mustMeld = nil
        selected = []
        if seats[turn].human {
            step = .draw
            message = stock.isEmpty ? "The stock is empty – take from the discard pile or end the hand." : "Your turn – draw from the stock or take from the discard pile."
        } else {
            step = .ai
            message = "\(seats[turn].name) is playing…"
            later(1.0) { aiDraw() }
        }
    }

    private func nextTurn() {
        if hands[turn].isEmpty { endHand(reason: "\(seats[turn].name) went out!"); return }
        turn = (turn + 1) % n
        startTurn()
    }

    private func take(_ p: Int, from i: Int) -> PCard {
        let c = discard[i]
        let taken = Array(discard[i...])
        discard.removeSubrange(i...)
        hands[p] += taken
        if p == me { lastDrawn = Set(taken) }
        log.append("\(seats[p].name) takes \(taken.count == 1 ? c.name : "\(taken.count) cards from \(c.name) up") from the discard pile.")
        Sound.shared.play(.flip)
        return c
    }

    private func toggle(_ c: PCard) {
        guard step == .play else { return }
        if selected.contains(c) { selected.remove(c) } else { selected.insert(c) }
        Sound.shared.play(.click)
    }

    private func humanDrawStock() {
        guard step == .draw, seats[turn].human, !stock.isEmpty else { return }
        let c = stock.removeLast()
        hands[me].append(c)
        lastDrawn = [c]
        Sound.shared.play(.flip)
        step = .play
        message = "Meld or lay off if you can, then discard one card."
    }

    private func humanTakeDiscard(_ i: Int) {
        guard step == .draw, seats[turn].human, i < discard.count else { return }
        let c = discard[i]
        let deep = i < discard.count - 1
        if deep {
            let pool = hands[me] + discard[i...].filter { $0 != c }
            guard Rummy.canUse(c, pool: pool, table: melds) else {
                message = "You can only take \(c.name) if you can meld it right away."
                Sound.shared.play(.lose)
                return
            }
        }
        _ = take(me, from: i)
        mustMeld = deep ? c : nil
        step = .play
        message = deep ? "You must meld or lay off \(c.name) this turn." : "Meld or lay off if you can, then discard one card."
    }

    private func humanMeld(_ sel: [PCard]) {
        guard Rummy.isValid(sel) else { return }
        melds.append(Meld(cards: Rummy.arranged(sel), owners: Array(repeating: me, count: sel.count)))
        hands[me].removeAll { sel.contains($0) }
        selected = []
        Sound.shared.play(.sparkle)
        log.append("\(seats[me].name) melds \(sel.map(\.name).joined(separator: " ")).")
        afterHumanPlay()
    }

    private func humanLayoff(_ sel: [PCard]) {
        var trial = melds
        var left = sel
        var progress = true
        while !left.isEmpty && progress {
            progress = false
            for c in left {
                if let k = Rummy.layoffIndex(c, trial) {
                    let cs = trial[k].cards + [c]
                    let os = trial[k].owners + [me]
                    let order = Rummy.arranged(cs)
                    trial[k].cards = order
                    trial[k].owners = order.map { x in os[cs.firstIndex(of: x)!] }
                    left.removeAll { $0 == c }
                    progress = true
                }
            }
        }
        guard left.isEmpty else {
            message = "\(left.map(\.name).joined(separator: ", ")) won't fit on any meld."
            Sound.shared.play(.lose)
            return
        }
        melds = trial
        hands[me].removeAll { sel.contains($0) }
        selected = []
        Sound.shared.play(.sparkle)
        log.append("\(seats[me].name) lays off \(sel.map(\.name).joined(separator: " ")).")
        afterHumanPlay()
    }

    private func afterHumanPlay() {
        if hands[me].isEmpty { endHand(reason: "\(seats[me].name) went out!"); return }
        message = mustMeldPending ? "You still need to meld \(mustMeld!.name)." : "Meld more, or discard one card to end your turn."
    }

    private func humanDiscard(_ c: PCard) {
        guard step == .play, !mustMeldPending else { return }
        hands[me].removeAll { $0 == c }
        discard.append(c)
        selected = []; lastDrawn = []
        Sound.shared.play(.chip)
        nextTurn()
    }

    private func endHand(reason: String) {
        var lines = [reason]
        for p in 0..<n {
            let plus = Rummy.credited(p, melds)
            let minus = hands[p].reduce(0) { $0 + Rummy.handValue($1) }
            scores[p] += plus - minus
            lines.append("\(seats[p].name): +\(plus) melded, −\(minus) in hand → \(scores[p])")
        }
        summary = lines
        log.append(reason)
        message = ""
        let top = scores.max()!
        if top >= Rummy.target && scores.filter({ $0 == top }).count == 1 {
            step = .gameOver
            let w = scores.firstIndex(of: top)!
            summary.append("\(seats[w].name) wins with \(top)!")
            later(2.5) { onFinish(GameOutcome(winner: seats[w].name, humanWon: seats[w].human)) }
        } else {
            step = .handOver
        }
    }

    // MARK: AI

    private func aiDraw() {
        guard step == .ai else { return }
        let p = turn
        // look up to 4 cards deep in the discard pile for something we can use
        var choice: Int? = nil
        for i in stride(from: discard.count - 1, through: max(0, discard.count - 4), by: -1) {
            let c = discard[i]
            let pool = hands[p] + discard[i...].filter { $0 != c }
            if Rummy.canUse(c, pool: pool, table: melds) { choice = i; break }
        }
        if let i = choice {
            let deep = i < discard.count - 1
            let c = take(p, from: i)
            mustMeld = deep ? c : nil
            aiMustMeld = c
        } else if !stock.isEmpty {
            hands[p].append(stock.removeLast())
            log.append("\(seats[p].name) draws from the stock.")
            Sound.shared.play(.flip)
            aiMustMeld = nil
        } else {
            endHand(reason: "The stock ran out.")
            return
        }
        later(0.9) { aiMelds() }
    }

    @State private var aiMustMeld: PCard?

    private func aiMelds() {
        guard step == .ai else { return }
        let p = turn
        var did: [String] = []
        // first use the card taken from the discard pile
        if let c = aiMustMeld, hands[p].contains(c) {
            if let k = Rummy.layoffIndex(c, melds) {
                layoff(p, c, k); did.append(c.name)
            } else if let m = Rummy.meldWith(c, hands[p]) {
                meld(p, m); did.append(m.map(\.name).joined(separator: " "))
            }
        }
        for m in Rummy.findMelds(hands[p]) {
            meld(p, m); did.append(m.map(\.name).joined(separator: " "))
        }
        var progress = true
        while progress {
            progress = false
            for c in hands[p] {
                if let k = Rummy.layoffIndex(c, melds) { layoff(p, c, k); did.append(c.name); progress = true; break }
            }
        }
        if !did.isEmpty {
            log.append("\(seats[p].name) melds \(did.joined(separator: ", ")).")
            Sound.shared.play(.sparkle)
        }
        if hands[p].isEmpty { endHand(reason: "\(seats[p].name) went out!"); return }
        later(did.isEmpty ? 0.5 : 1.0) { aiDiscard() }
    }

    private func meld(_ p: Int, _ m: [PCard]) {
        melds.append(Meld(cards: Rummy.arranged(m), owners: Array(repeating: p, count: m.count)))
        hands[p].removeAll { m.contains($0) }
    }

    private func layoff(_ p: Int, _ c: PCard, _ k: Int) {
        let cs = melds[k].cards + [c]
        let os = melds[k].owners + [p]
        let order = Rummy.arranged(cs)
        melds[k].cards = order
        melds[k].owners = order.map { x in os[cs.firstIndex(of: x)!] }
        hands[p].removeAll { $0 == c }
    }

    private func aiDiscard() {
        guard step == .ai else { return }
        let p = turn
        let hand = hands[p]
        func useful(_ c: PCard) -> Double {
            var u = 0.0
            for x in hand where x != c {
                if x.rank == c.rank { u += 2 }
                if x.suit == c.suit && abs(x.rank - c.rank) == 1 { u += 1.5 }
                if x.suit == c.suit && abs(x.rank - c.rank) == 2 { u += 0.7 }
            }
            return u
        }
        let c = hand.min { a, b in
            let ua = useful(a), ub = useful(b)
            return ua != ub ? ua < ub : Rummy.handValue(a) > Rummy.handValue(b)
        }!
        hands[p].removeAll { $0 == c }
        discard.append(c)
        log.append("\(seats[p].name) discards \(c.name).")
        Sound.shared.play(.chip)
        later(0.6) { nextTurn() }
    }
}
