import Foundation

/// The just-for-fun card games, dealt and played trick by trick. The player's seat
/// makes every bid and plays every card; the other seats play by simple house rules.
enum Tricks {
    struct Rules {
        var seats: Int
        var trump: Int?
        /// Euchre and pepper: the jack of trump and the other jack of its colour are the top trumps.
        var bowers = false
        /// Pitch: you may trump even when you could follow suit.
        var trumpAnytime = false
        /// A suit nobody may lead until someone has played it (hearts in Hearts, spades in Spades).
        var breakSuit: Int?
        /// Euchre: the partner of someone going alone sits the hand out.
        var sitting: Int?
    }

    struct Played {
        let seat: Int
        let card: Card
    }

    struct Outcome {
        var points: [Int]
        var note: String
    }

    static let suitNames = ["Spades", "Hearts", "Diamonds", "Clubs"]
    static let suitSymbols = ["♠", "♥", "♦", "♣"]

    // MARK: Trick mechanics

    /// ♠↔♣, ♥↔♦
    static func sameColour(_ suit: Int) -> Int { [3, 2, 1, 0][suit] }

    /// The suit a card counts as: the left bower belongs to trump.
    static func suit(_ c: Card, _ r: Rules) -> Int {
        if r.bowers, let t = r.trump, c.rank == 11, c.suit == sameColour(t) { return t }
        return c.suit
    }

    /// How strong a card is in this trick: trump beats the led suit, anything else can't win.
    static func power(_ c: Card, led: Int, _ r: Rules) -> Int {
        let s = suit(c, r)
        if let t = r.trump, s == t {
            if r.bowers && c.rank == 11 { return c.suit == t ? 200 : 199 }
            return 100 + c.rank
        }
        return s == led ? c.rank : 0
    }

    static func winner(_ trick: [Played], _ r: Rules) -> Played {
        let led = suit(trick[0].card, r)
        return trick.max { power($0.card, led: led, r) < power($1.card, led: led, r) }!
    }

    static func legal(_ hand: [Card], trick: [Played], broken: Bool, _ r: Rules) -> [Card] {
        guard let first = trick.first else {
            if let b = r.breakSuit, !broken {
                let ok = hand.filter { suit($0, r) != b }
                if !ok.isEmpty { return ok }
            }
            return hand
        }
        let led = suit(first.card, r)
        let follow = hand.filter { suit($0, r) == led }
        if follow.isEmpty { return hand }
        if r.trumpAnytime, let t = r.trump { return hand.filter { suit($0, r) == led || suit($0, r) == t } }
        return follow
    }

    /// A computer player's card. `wants` is whether she's trying to take this trick.
    static func choose(_ legal: [Card], trick: [Played], wants: Bool, partner: Int?, dumpPoints: Bool, _ r: Rules) -> Card {
        func low(_ cards: [Card], led: Int) -> Card {
            cards.min { (power($0, led: led, r), $0.rank) < (power($1, led: led, r), $1.rank) }!
        }
        func high(_ cards: [Card], led: Int) -> Card {
            cards.max { (power($0, led: led, r), $0.rank) < (power($1, led: led, r), $1.rank) }!
        }
        guard let first = trick.first else {
            // Leading: cash an off-suit ace if hunting tricks, otherwise lead low.
            if wants, let ace = legal.filter({ $0.rank == 14 && suit($0, r) != r.trump }).first { return ace }
            return legal.min { $0.rank < $1.rank }!
        }
        let led = suit(first.card, r)
        let best = winner(trick, r)
        let bestPower = power(best.card, led: led, r)
        let beating = legal.filter { power($0, led: led, r) > bestPower }
        if wants {
            if let partner, best.seat == partner, trick.count == r.seats - 1 - (r.sitting == nil ? 0 : 1) { return low(legal, led: led) }
            return beating.isEmpty ? low(legal, led: led) : low(beating, led: led)
        }
        let losing = legal.filter { power($0, led: led, r) < bestPower }
        if !losing.isEmpty {
            // Hearts: when void, unload the queen of spades or the biggest heart.
            if dumpPoints && !legal.contains(where: { suit($0, r) == led }) {
                if let queen = losing.first(where: { $0.rank == 12 && $0.suit == 0 }) { return queen }
                if let heart = losing.filter({ $0.suit == 1 }).max(by: { $0.rank < $1.rank }) { return heart }
                return losing.max { $0.rank < $1.rank }!
            }
            return high(losing, led: led)
        }
        return high(legal, led: led)
    }

    /// Plays out every card. Returns tricks taken and the cards won, per seat.
    static func playOut(_ hands: inout [[Card]], leader: Int, rules r: Rules, names: [String], host: TableHost,
                        wants: (Int) -> Bool, partner: (Int) -> Int?, dumpPoints: Bool = false, firstLead: Card? = nil,
                        slough: ((Int, [Card]) -> Card?)? = nil,
                        afterCard: (([Played]) async throws -> Void)? = nil,
                        afterTrick: (([Played], Played) async throws -> Void)? = nil,
                        header: String) async throws -> (tricks: [Int], won: [[Card]]) {
        var tricks = Array(repeating: 0, count: r.seats)
        var won = Array(repeating: [Card](), count: r.seats)
        var leader = leader
        var broken = false
        let rounds = hands[leader].count
        func show(_ trick: [Played]) {
            host.show([FeltGroup(seat: nil, cards: [], label: header)] + trick.map { FeltGroup(seat: $0.seat, cards: [$0.card]) })
        }
        func noteTricks() { host.notes(names.indices.map { $0 == r.sitting ? "Sitting out" : "\(tricks[$0]) trick\(tricks[$0] == 1 ? "" : "s")" }) }
        for round in 0..<rounds {
            var trick: [Played] = []
            for k in 0..<r.seats {
                let seat = (leader + k) % r.seats
                if seat == r.sitting { continue }
                var options = legal(hands[seat], trick: trick, broken: broken, r)
                if round == 0, trick.isEmpty, let firstLead, hands[seat].contains(firstLead) { options = [firstLead] }
                var auto = choose(options, trick: trick, wants: wants(seat), partner: partner(seat), dumpPoints: dumpPoints, r)
                if let slough, let first = trick.first, !options.contains(where: { suit($0, r) == suit(first.card, r) }),
                   let pick = slough(seat, options) { auto = pick }
                let title = trick.isEmpty ? "Your lead." : "Your play — \(names[trick[0].seat]) led \(suitNames[suit(trick[0].card, r)].lowercased())."
                let card = try await host.card(seat, title, playable: options, auto: auto)
                hands[seat].removeAll { $0 == card }
                if let b = r.breakSuit, suit(card, r) == b { broken = true }
                trick.append(Played(seat: seat, card: card))
                show(trick)
                if seat == host.human { host.hand(hands[seat]) }
                try await host.pause(seat == host.human ? 0.25 : 0.55)
                try await afterCard?(trick)
            }
            let w = winner(trick, r)
            tricks[w.seat] += 1
            won[w.seat] += trick.map(\.card)
            noteTricks()
            host.caption("\(names[w.seat]) takes the trick with the \(w.card.label).")
            try await host.pause(0.9)
            try await afterTrick?(trick, w)
            leader = w.seat
        }
        host.show([FeltGroup(seat: nil, cards: [], label: header)])
        return (tricks, won)
    }

    /// Rough tricks a hand should take with this trump.
    static func estimate(_ hand: [Card], trump: Int?, bowers: Bool = false) -> Int {
        var r = Rules(seats: 4, trump: trump, bowers: bowers)
        r.trump = trump
        var e = 0.0
        for s in 0..<4 {
            let cards = hand.filter { suit($0, r) == s }
            if s == trump {
                e += cards.reduce(0.0) { $0 + (power($1, led: s, r) >= 112 ? 1 : 0.5) }
                e += Double(max(0, cards.count - 3)) * 0.5
            } else {
                if cards.contains(where: { $0.rank == 14 }) { e += 1 }
                if cards.contains(where: { $0.rank == 13 }) && cards.count >= 2 { e += 0.5 }
            }
        }
        return Int(e)
    }

    /// The suit a hand is strongest in, and how many tricks it might take there.
    static func bestSuit(_ hand: [Card], bowers: Bool = false, excluding: Int? = nil) -> (suit: Int, tricks: Int) {
        (0..<4).filter { $0 != excluding }.map { ($0, estimate(hand, trump: $0, bowers: bowers)) }.max { $0.1 < $1.1 }!
    }

    private static func deal(_ n: Int, each: Int, lowest: Int = 2) -> (hands: [[Card]], rest: [Card]) {
        var deck = Deck(lowest: lowest)
        let hands = (0..<n).map { _ in handSorted(deck.draw(each)) }
        var rest: [Card] = []
        while let c = deck.drawIfAny() { rest.append(c) }
        return (hands, rest)
    }

    // MARK: One deal of each game

    /// One deal. `round` counts deals from 0; `dealer` is the seat dealing.
    static func hand(_ game: CasinoGame, names: [String], scores: [Int], dealer: Int, round: Int, host: TableHost) async throws -> Outcome {
        let n = names.count
        let partner: (Int) -> Int? = game.isPartners ? { ($0 + 2) % 4 } : { _ in nil }
        let me = host.human
        host.notes(names.map { _ in "" })
        func showMine(_ hands: [[Card]]) { if let me { host.hand(handSorted(hands[me])) } }

        switch game {
        case .hearts:
            var (hands, _) = deal(4, each: 13)
            showMine(hands)
            let two = Card(rank: 2, suit: 3)
            let leader = hands.firstIndex { $0.contains(two) }!
            let r = Rules(seats: 4, trump: nil, breakSuit: 1)
            let (_, won) = try await playOut(&hands, leader: leader, rules: r, names: names, host: host, wants: { _ in false },
                                             partner: { _ in nil }, dumpPoints: true, firstLead: two, header: "No trump · 2♣ leads")
            var pts = won.map { cards in cards.filter { $0.suit == 1 }.count + (cards.contains(Card(rank: 12, suit: 0)) ? 13 : 0) }
            if let shooter = pts.firstIndex(of: 26) {
                pts = pts.indices.map { $0 == shooter ? 0 : 26 }
                return Outcome(points: pts, note: "\(names[shooter]) shoots the moon! Everyone else takes 26.")
            }
            let queen = won.firstIndex { $0.contains(Card(rank: 12, suit: 0)) }!
            return Outcome(points: pts, note: "\(names[queen]) gets stuck with the Q♠!")

        case .spades:
            // A team down by 100 or more may call double nil — before looking at the cards.
            var blind: Int?
            for team in 0..<2 where blind == nil && scores[1 - team] - scores[team] >= 100 {
                if let me, me % 2 == team {
                    host.hand([])
                    let pick = try await host.option(me, "Your team is behind by \(scores[1 - team] - scores[team]). Call DOUBLE NIL without looking at your cards? +200 if you take no tricks, −200 if you take even one.",
                                                     ["Call double nil", "Look at my cards"], auto: 1)
                    if pick == 0 { blind = me }
                }
                if blind == nil, Double.random(in: 0...1) < 0.35 {
                    let caller = [team, team + 2].filter { $0 != me }.randomElement()!
                    blind = caller
                }
            }
            if let blind { host.caption("\(names[blind]) calls DOUBLE NIL without looking at her cards!") }
            var (hands, _) = deal(4, each: 13)
            showMine(hands)
            var bids = Array(repeating: 0, count: 4)
            var nil1 = Array(repeating: false, count: 4)
            for k in 1...4 {
                let seat = (dealer + k) % 4
                if seat == blind { continue }
                let est = estimate(hands[seat], trump: 0)
                let auto = est == 0 && !hands[seat].contains(where: { $0.suit == 0 && $0.rank >= 11 }) ? 0 : max(1, est)
                let pick = try await host.option(seat, "Spades: your bid? (Nil: +100 if you take no tricks, −100 if you take any.)",
                                                 ["Nil"] + (1...9).map(String.init), auto: auto)
                if pick == 0 { nil1[seat] = true } else { bids[seat] = pick }
                host.notes(names.indices.map { $0 == blind ? "Double nil" : nil1[$0] ? "Nil" : bids[$0] > 0 ? "Bid \(bids[$0])" : "" })
                try await host.pause(0.4)
            }
            let r = Rules(seats: 4, trump: 0, breakSuit: 0)
            let (tricks, _) = try await playOut(&hands, leader: (dealer + 1) % 4, rules: r, names: names, host: host,
                                                wants: { $0 != blind && !nil1[$0] }, partner: partner, header: "Spades are trump")
            var pts = [0, 0, 0, 0]
            var notes: [String] = []
            for team in 0..<2 {
                let seats = [team, team + 2]
                let bidders = seats.filter { $0 != blind && !nil1[$0] }
                let bid = bidders.reduce(0) { $0 + bids[$1] }, took = bidders.reduce(0) { $0 + tricks[$1] }
                var score = bid == 0 ? 0 : took >= bid ? bid * 10 + (took - bid) : -bid * 10
                var line = "\(names[team]) & \(names[team + 2]) bid \(bid), took \(took)"
                for s in seats where s == blind || nil1[s] {
                    let value = s == blind ? 200 : 100
                    score += tricks[s] == 0 ? value : -value
                    line += " · \(names[s])'s \(s == blind ? "double nil" : "nil") \(tricks[s] == 0 ? "makes it! +\(value)" : "fails, −\(value)")"
                }
                pts[team] = score
                pts[team + 2] = score
                notes.append(line)
            }
            return Outcome(points: pts, note: notes.joined(separator: " · "))

        case .euchre:
            var (hands, kitty) = deal(4, each: 5, lowest: 9)
            showMine(hands)
            let up = kitty[0]
            host.show([FeltGroup(seat: nil, cards: [up], label: "Turned up")])
            var trump: Int?
            var maker = 0
            // Round one: order up the turned card.
            for k in 1...4 where trump == nil {
                let seat = (dealer + k) % 4
                let strength = estimate(hands[seat] + (seat == dealer ? [up] : []), trump: up.suit, bowers: true)
                let pick = try await host.option(seat, "Euchre: order up the \(up.label) as trump? \(seat == dealer ? "You'd pick it up." : "\(names[dealer]) picks it up.")",
                                                 ["Order it up", "Pass"], auto: strength >= 3 ? 0 : 1)
                if pick == 0 { (trump, maker) = (up.suit, seat) }
                host.caption(pick == 0 ? "\(names[seat]) orders it up!" : "\(names[seat]) passes.")
                try await host.pause(0.5)
            }
            if let t = trump {
                // The dealer takes the card and throws one away.
                let r = Rules(seats: 4, trump: t, bowers: true)
                hands[dealer].append(up)
                let keep = hands[dealer]
                let auto = keep.min { (power($0, led: -1, r), $0.rank) < (power($1, led: -1, r), $1.rank) }!
                if dealer == me { host.hand(handSorted(keep)) }
                let out = try await host.card(dealer, "You pick up the \(up.label). Tap a card to throw away.", playable: keep, auto: auto)
                hands[dealer].removeAll { $0 == out }
                showMine(hands)
            } else {
                // Round two: name any other suit. The dealer is stuck if everyone passes.
                for k in 1...4 where trump == nil {
                    let seat = (dealer + k) % 4
                    let suits = (0..<4).filter { $0 != up.suit }
                    let best = bestSuit(hands[seat], bowers: true, excluding: up.suit)
                    let stuck = seat == dealer
                    let options = suits.map { suitNames[$0] } + (stuck ? [] : ["Pass"])
                    let auto = best.tricks >= 3 || stuck ? suits.firstIndex(of: best.suit)! : suits.count
                    let pick = try await host.option(seat, stuck ? "Euchre: everyone passed — you're stuck. Name trump." : "Euchre: name trump, or pass?",
                                                     options, auto: auto)
                    if pick < suits.count { (trump, maker) = (suits[pick], seat) }
                    host.caption(pick < suits.count ? "\(names[seat]) calls \(suitNames[suits[pick]].lowercased())!" : "\(names[seat]) passes.")
                    try await host.pause(0.5)
                }
            }
            let t = trump!
            let alone = try await host.option(maker, "Go alone? Take all 5 tricks by yourself for 4 points.",
                                              ["Play with my partner", "Go alone"], auto: estimate(hands[maker], trump: t, bowers: true) >= 5 ? 1 : 0) == 1
            let r = Rules(seats: 4, trump: t, bowers: true, sitting: alone ? (maker + 2) % 4 : nil)
            var leader = (dealer + 1) % 4
            if leader == r.sitting { leader = (leader + 1) % 4 }
            let (tricks, _) = try await playOut(&hands, leader: leader, rules: r, names: names, host: host, wants: { _ in true },
                                                partner: { alone ? nil : partner($0) }, header: "\(suitSymbols[t]) trump · \(names[maker]) made it")
            let team = maker % 2
            let took = tricks[team] + tricks[team + 2]
            var pts = [0, 0, 0, 0]
            let note: String
            if took >= 3 {
                let p = took == 5 ? (alone ? 4 : 2) : 1
                pts[team] = p
                pts[team + 2] = p
                note = "\(names[team]) & \(names[team + 2]) take \(took)\(took == 5 ? (alone ? " — alone! +4" : " — a march! +2") : " · +1")"
            } else {
                pts[1 - team] = 2
                pts[3 - team] = 2
                note = "\(names[team]) & \(names[team + 2]) get euchred! +2 to \(names[1 - team]) & \(names[3 - team])"
            }
            return Outcome(points: pts, note: note)

        case .pitch:
            var (hands, _) = deal(4, each: 6)
            showMine(hands)
            let dealt = hands
            var high = 0, bidder = dealer
            for k in 1...4 {
                let seat = (dealer + k) % 4
                let stuck = seat == dealer && high == 0
                let bids = high >= 4 ? [] : Array(max(2, high + 1)...4)
                let est = pitchStrength(hands[seat])
                let options = (stuck ? [] : ["Pass"]) + bids.map { "Bid \($0)" }
                let auto = stuck ? 0 : est >= bids.first ?? 9 ? 1 : 0
                guard !bids.isEmpty else { continue }
                let pick = try await host.option(seat, stuck ? "Pitch: everyone passed — you're stuck with 2." : "Pitch: bid on High, Low, Jack and Game?",
                                                 options, auto: auto)
                let bid = stuck ? bids[pick] : pick == 0 ? 0 : bids[pick - 1]
                if bid > high { (high, bidder) = (bid, seat) }
                host.caption(bid > 0 ? "\(names[seat]) bids \(bid)." : "\(names[seat]) passes.")
                host.notes(names.indices.map { $0 == bidder && high > 0 ? "Bid \(high)" : "" })
                try await host.pause(0.5)
            }
            // The bidder's first card names trump.
            let best = bestPitchSuit(hands[bidder])
            let auto = hands[bidder].filter { $0.suit == best }.max { $0.rank < $1.rank }!
            let lead = try await host.card(bidder, "You won the bid! Lead a card — its suit becomes trump.", playable: hands[bidder], auto: auto)
            let t = lead.suit
            host.caption("\(names[bidder]) leads the \(lead.label) — \(suitNames[t].lowercased()) are trump!")
            let r = Rules(seats: 4, trump: t, trumpAnytime: true)
            let (_, won) = try await playOut(&hands, leader: bidder, rules: r, names: names, host: host, wants: { _ in true },
                                             partner: partner, firstLead: lead, header: "\(suitSymbols[t]) trump · \(names[bidder]) bid \(high)")
            // No partners: every player scores for herself.
            // High and Low go to whoever was dealt them; Jack to whoever wins it; Game to the most card points (a tie scores nobody).
            var pts = [0, 0, 0, 0]
            var got: [String] = []
            let trumps = dealt.enumerated().flatMap { s, cards in cards.filter { $0.suit == t }.map { (s, $0) } }
            if let hi = trumps.max(by: { $0.1.rank < $1.1.rank }) { pts[hi.0] += 1; got.append("High: \(names[hi.0])") }
            if let lo = trumps.min(by: { $0.1.rank < $1.1.rank }) { pts[lo.0] += 1; got.append("Low: \(names[lo.0])") }
            if let j = won.firstIndex(where: { $0.contains(Card(rank: 11, suit: t)) }) { pts[j] += 1; got.append("Jack: \(names[j])") }
            let gamePts = won.map { $0.reduce(0) { $0 + pitchGamePoints($1) } }
            if let top = gamePts.max(), gamePts.filter({ $0 == top }).count == 1, let w = gamePts.firstIndex(of: top) {
                pts[w] += 1
                got.append("Game: \(names[w])")
            }
            let set = pts[bidder] < high
            if set { pts[bidder] = -high }
            return Outcome(points: pts, note: got.joined(separator: " · ") + (set ? " · \(names[bidder]) is set back \(high)!" : ""))

        case .knaves:
            var (hands, rest) = deal(3, each: 17)
            showMine(hands)
            let t = rest[0].suit
            host.caption("The \(rest[0].label) is turned — \(suitNames[t].lowercased()) are trump.")
            try await host.pause(1)
            let r = Rules(seats: 3, trump: t)
            let (tricks, won) = try await playOut(&hands, leader: (dealer + 1) % 3, rules: r, names: names, host: host, wants: { _ in true },
                                                  partner: { _ in nil }, header: "\(suitSymbols[t]) trump · jacks cost points")
            var pts = tricks
            var jacks: [String] = []
            for (penalty, suit) in [(4, 1), (3, 2), (2, 3), (1, 0)] {
                if let who = won.firstIndex(where: { $0.contains(Card(rank: 11, suit: suit)) }) {
                    pts[who] -= penalty
                    jacks.append("\(names[who]) takes the J\(suitSymbols[suit]) (−\(penalty))")
                }
            }
            return Outcome(points: pts, note: jacks.joined(separator: " · "))

        case .pepper:
            var (hands, _) = deal(4, each: 6, lowest: 9)
            showMine(hands)
            var high = 0, bidder = dealer
            for k in 1...4 {
                let seat = (dealer + k) % 4
                let stuck = seat == dealer && high == 0
                let bids = high >= 6 ? [] : Array(max(3, high + 1)...6)
                guard !bids.isEmpty else { continue }
                let est = bestSuit(hands[seat], bowers: true).tricks + 1
                let options = (stuck ? [] : ["Pass"]) + bids.map { $0 == 6 ? "Pepper (all 6)" : "Bid \($0)" }
                let auto = stuck ? 0 : est >= bids[0] ? 1 : 0
                let pick = try await host.option(seat, stuck ? "Pepper: everyone passed — you're stuck with 3." : "Pepper: how many of the 6 tricks will your team take?",
                                                 options, auto: auto)
                let bid = stuck ? bids[pick] : pick == 0 ? 0 : bids[pick - 1]
                if bid > high { (high, bidder) = (bid, seat) }
                host.caption(bid > 0 ? "\(names[seat]) bids \(bid == 6 ? "pepper" : "\(bid)")." : "\(names[seat]) passes.")
                host.notes(names.indices.map { $0 == bidder && high > 0 ? "Bid \(high)" : "" })
                try await host.pause(0.5)
            }
            let auto = bestSuit(hands[bidder], bowers: true).suit
            let t = try await host.option(bidder, "You won the bid at \(high). Name trump.", suitNames, auto: auto)
            host.caption("\(names[bidder]) calls \(suitNames[t].lowercased())!")
            let r = Rules(seats: 4, trump: t, bowers: true)
            let (tricks, _) = try await playOut(&hands, leader: bidder, rules: r, names: names, host: host, wants: { _ in true },
                                                partner: partner, header: "\(suitSymbols[t]) trump · \(names[bidder]) bid \(high == 6 ? "pepper" : "\(high)")")
            let bt = bidder % 2
            let took = tricks[bt] + tricks[bt + 2]
            var team = [0, 0]
            team[bt] = took >= high ? (high == 6 ? 12 : took) : (high == 6 ? -12 : -high)
            team[1 - bt] = 6 - took
            return Outcome(points: [team[0], team[1], team[0], team[1]],
                           note: "\(names[bt]) & \(names[bt + 2]) bid \(high == 6 ? "pepper" : "\(high)"), take \(took)\(took >= high ? "" : " — peppered!")")

        case .ninetyNine:
            var (hands, _) = deal(3, each: 12, lowest: 6)
            showMine(hands)
            // Trump rotates each deal.
            let t = [3, 1, 0, 2][round % 4]
            host.caption("\(suitNames[t]) are trump this deal.")
            // Each player sets aside 3 cards; their suits spell the bid (♣3 ♥2 ♠1 ♦0).
            let value = [1, 2, 0, 3]
            var bids = [0, 0, 0]
            for seat in 0..<3 {
                let auto = ninetyNineDiscard(hands[seat], trump: t, value: value)
                var discard = auto
                if seat == me {
                    let answer = try await host.ask(PlayerPrompt(title: "99: tap 3 cards to set aside. Their suits are your bid — ♣ = 3, ♥ = 2, ♠ = 1, ♦ = 0. \(suitNames[t]) are trump.",
                                                                 options: ["Pick for me"], pick: 3), .cards(auto))
                    if case .cards(let c) = answer, c.count == 3 { discard = c }
                }
                hands[seat].removeAll { discard.contains($0) }
                bids[seat] = discard.reduce(0) { $0 + value[$1.suit] }
            }
            showMine(hands)
            host.notes(bids.map { "Bid \($0)" })
            let r = Rules(seats: 3, trump: t)
            let (tricks, _) = try await playOut(&hands, leader: (dealer + 1) % 3, rules: r, names: names, host: host, wants: { _ in true },
                                                partner: { _ in nil }, header: "\(suitSymbols[t]) trump · bids \(bids.map(String.init).joined(separator: "/"))")
            let exact = (0..<3).map { tricks[$0] == bids[$0] }
            let bonus = [0, 30, 20, 10][exact.filter { $0 }.count]
            let hit = (0..<3).filter { exact[$0] }.map { names[$0] }
            return Outcome(points: (0..<3).map { tricks[$0] + (exact[$0] ? bonus : 0) },
                           note: hit.isEmpty ? "Nobody hits her bid." : "\(hit.joined(separator: " and ")) \(hit.count == 1 ? "hits her bid" : "hit their bids")! +\(bonus)")

        case .fourHundred:
            // Hearts are always trump. If the bids add up to less than 11, it's a redeal.
            var deal400 = deal(4, each: 13).hands
            var bids = [0, 0, 0, 0]
            while true {
                showMine(deal400)
                for k in 1...4 {
                    let seat = (dealer + k) % 4
                    let auto = max(2, estimate(deal400[seat], trump: 1)) - 2
                    let pick = try await host.option(seat, "400: how many tricks will you take? (Hearts are trump. Bids of 7+ score double.)",
                                                     (2...9).map(String.init), auto: auto)
                    bids[seat] = pick + 2
                    host.notes(bids.map { $0 > 0 ? "Bid \($0)" : "" })
                    try await host.pause(0.4)
                }
                if bids.reduce(0, +) >= 11 { break }
                host.caption("The bids only add up to \(bids.reduce(0, +)) — that's a redeal!")
                try await host.pause(1.4)
                bids = [0, 0, 0, 0]
                deal400 = deal(4, each: 13).hands
            }
            var hands = deal400
            let r = Rules(seats: 4, trump: 1)
            let (tricks, _) = try await playOut(&hands, leader: (dealer + 1) % 4, rules: r, names: names, host: host, wants: { _ in true },
                                                partner: partner, header: "♥ trump · bids \(bids.map(String.init).joined(separator: "/"))")
            let pts = (0..<4).map { i -> Int in
                let v = bids[i] >= 7 ? bids[i] * 2 : bids[i]
                return tricks[i] >= bids[i] ? v : -v
            }
            let set = (0..<4).filter { pts[$0] < 0 }.map { names[$0] }
            return Outcome(points: pts, note: set.isEmpty ? "Everybody makes her bid!" : "\(set.joined(separator: " and ")) \(set.count == 1 ? "is" : "are") set!")

        case .diamonds:
            return try await diamonds(names: names, dealer: dealer, round: round, host: host)

        default:
            return Outcome(points: names.map { _ in 0 }, note: "")
        }
    }

    // MARK: Diamonds

    /// A player's diamond crystals: the vault is safe (2 points each), the showroom can be robbed (1 point each).
    struct Crystals {
        var vault = 0
        var showroom = 0
        var points: Int { vault * 2 + showroom }
    }

    /// Crystals carry over from round to round; the first round of a game clears them.
    static var crystals: [Crystals] = []

    /// One round of Diamonds: 60 cards numbered 1–15, 10 each, no trump. Every card played off-suit
    /// and every trick won triggers its suit's action; after 10 tricks, suit majorities and zero-trick bonuses.
    private static func diamonds(names: [String], dealer: Int, round: Int, host: TableHost) async throws -> Outcome {
        if round == 0 { crystals = names.map { _ in Crystals() } }
        let before = crystals.map(\.points)
        let deck = (1...15).flatMap { n in (0..<4).map { Card(rank: 100 + n, suit: $0) } }.shuffled()
        var hands = (0..<4).map { s in handSorted(Array(deck[s * 10..<s * 10 + 10])) }
        if let me = host.human { host.hand(hands[me]) }
        var taken = [0, 0, 0, 0]

        func noteCrystals() {
            host.notes(names.indices.map { "Vault \(crystals[$0].vault) · Show \(crystals[$0].showroom) · \(taken[$0]) tr" })
        }
        func action(_ suit: Int, _ seat: Int, _ why: String) async throws {
            let who = names[seat]
            let line: String
            switch suit {
            case 2:
                crystals[seat].vault += 1
                line = "\(who) \(why): ♦ a diamond goes straight into her vault."
            case 1:
                crystals[seat].showroom += 1
                line = "\(who) \(why): ♥ a diamond for her showroom."
            case 0:
                if crystals[seat].showroom > 0 {
                    crystals[seat].showroom -= 1
                    crystals[seat].vault += 1
                    line = "\(who) \(why): ♠ she locks a showroom diamond in her vault."
                } else {
                    line = "\(who) \(why): ♠ but her showroom is empty."
                }
            default:
                let targets = names.indices.filter { $0 != seat && crystals[$0].showroom > 0 }
                if targets.isEmpty {
                    line = "\(who) \(why): ♣ but nobody has a showroom diamond to steal."
                } else {
                    let richest = targets.indices.max { crystals[targets[$0]].points < crystals[targets[$1]].points }!
                    let pick = try await host.option(seat, "♣ Clubs: steal a diamond from whose showroom?",
                                                     targets.map { "\(names[$0]) (\(crystals[$0].showroom))" }, auto: richest)
                    let victim = targets[pick]
                    crystals[victim].showroom -= 1
                    crystals[seat].showroom += 1
                    line = "\(who) \(why): ♣ she steals a diamond from \(names[victim])'s showroom!"
                }
            }
            noteCrystals()
            host.caption(line)
            try await host.pause(1.1)
        }

        noteCrystals()
        let r = Rules(seats: 4, trump: nil)
        let (_, won) = try await playOut(&hands, leader: (dealer + 1) % 4, rules: r, names: names, host: host, wants: { _ in true },
                                         partner: { _ in nil },
                                         slough: { seat, cards in diamondsSlough(cards, seat: seat) },
                                         afterCard: { trick in
                                             // Can't follow suit: the card's own suit action, right away.
                                             if let last = trick.last, trick.count > 1, last.card.suit != trick[0].card.suit {
                                                 try await action(last.card.suit, last.seat, "can't follow")
                                             }
                                         },
                                         afterTrick: { trick, w in
                                             taken[w.seat] += 1
                                             try await action(trick[0].card.suit, w.seat, "wins the trick")
                                         },
                                         header: "No trump · every suit has an action")
        // Round majorities: most cards taken in a suit (no ties) earns that suit's action.
        var majorities: [String] = []
        for s in [2, 1, 0, 3] {
            let counts = won.map { $0.filter { $0.suit == s }.count }
            let top = counts.max()!
            guard top > 0, counts.filter({ $0 == top }).count == 1 else { continue }
            let seat = counts.firstIndex(of: top)!
            majorities.append("\(suitSymbols[s]) \(names[seat])")
            try await action(s, seat, "has the most \(suitNames[s].lowercased())")
        }
        // Zero tricks: two diamond actions.
        let shutOut = names.indices.filter { taken[$0] == 0 }
        for seat in shutOut {
            try await action(2, seat, "took no tricks")
            try await action(2, seat, "took no tricks")
        }
        let points = names.indices.map { crystals[$0].points - before[$0] }
        var note = "Majorities: " + (majorities.isEmpty ? "none" : majorities.joined(separator: ", "))
        if !shutOut.isEmpty { note += " · \(shutOut.map { names[$0] }.joined(separator: " & ")) took no tricks: 2 vault diamonds" }
        return Outcome(points: points, note: note)
    }

    /// Off-suit, a computer player throws the suit whose action helps her most, giving up her lowest card of it.
    private static func diamondsSlough(_ cards: [Card], seat: Int) -> Card? {
        let robbable = crystals.indices.contains { $0 != seat && crystals[$0].showroom > 0 }
        let worth = [crystals[seat].showroom > 0 ? 3 : 0, 2, 4, robbable ? 3 : 0]
        let best = cards.max { (worth[$0.suit], -$0.rank) < (worth[$1.suit], -$1.rank) }
        return best
    }

    // MARK: Helpers for the computer players

    private static func pitchGamePoints(_ c: Card) -> Int {
        switch c.rank {
        case 10: 10
        case 14: 4
        case 13: 3
        case 12: 2
        case 11: 1
        default: 0
        }
    }

    private static func bestPitchSuit(_ hand: [Card]) -> Int {
        (0..<4).max { a, b in
            let ca = hand.filter { $0.suit == a }, cb = hand.filter { $0.suit == b }
            return (ca.count, ca.map(\.rank).max() ?? 0) < (cb.count, cb.map(\.rank).max() ?? 0)
        }!
    }

    /// Points a pitch hand expects to make in its best suit.
    private static func pitchStrength(_ hand: [Card]) -> Int {
        let s = bestPitchSuit(hand)
        let cards = hand.filter { $0.suit == s }
        var e = 0
        if cards.contains(where: { $0.rank == 14 }) { e += 1 }
        if cards.contains(where: { $0.rank <= 3 }) { e += 1 }
        if cards.contains(where: { $0.rank == 11 }) { e += 1 }
        if cards.count >= 3 { e += 1 }
        return e
    }

    /// The three cards whose suits spell the bid closest to what the other nine should take.
    private static func ninetyNineDiscard(_ hand: [Card], trump: Int, value: [Int]) -> [Card] {
        combos(hand, 3).min { a, b in
            func cost(_ d: [Card]) -> Int {
                let keep = hand.filter { !d.contains($0) }
                let bid = d.reduce(0) { $0 + value[$1.suit] }
                return abs(estimate(keep, trump: trump) - bid) * 100 + d.reduce(0) { $0 + $1.rank }
            }
            return cost(a) < cost(b)
        }!
    }

    // MARK: Who's won

    /// Who's won, if anyone: the seats (a team counts as both partners).
    static func winners(_ game: CasinoGame, scores: [Int], hands: Int) -> [Int]? {
        switch game {
        case .diamonds:
            // Diamonds ends after one round per player; the most crystal points wins.
            guard hands >= game.target, let high = scores.max() else { return nil }
            return scores.indices.filter { scores[$0] == high }
        case .hearts:
            guard scores.contains(where: { $0 >= game.target }) else { return nil }
            let low = scores.min()!
            return scores.indices.filter { scores[$0] == low }
        case .spades:
            // First team to 300 wins; a team that sinks to -200 loses on the spot.
            if scores[0] <= -200 || scores[1] <= -200 { return scores[0] > scores[1] ? [0, 2] : [1, 3] }
            guard let high = scores.max(), high >= game.target else { return nil }
            return scores.indices.filter { scores[$0] == high }
        case .fourHundred:
            // A team wins once one partner reaches 41 and the other is above zero.
            for t in 0..<2 where max(scores[t], scores[t + 2]) >= game.target && min(scores[t], scores[t + 2]) > 0 {
                return [t, t + 2]
            }
            return nil
        default:
            guard let high = scores.max(), high >= game.target else { return nil }
            return scores.indices.filter { scores[$0] == high }
        }
    }
}
