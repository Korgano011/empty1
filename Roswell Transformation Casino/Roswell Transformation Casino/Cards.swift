import Foundation

struct Card: Hashable, Codable {
    /// 2…14, ace high.
    let rank: Int
    /// 0 ♠, 1 ♥, 2 ♦, 3 ♣
    let suit: Int

    var isRed: Bool { suit == 1 || suit == 2 }
    var rankText: String {
        // The Diamonds deck is numbered 1–15; those cards are stored as 101…115.
        if rank > 100 { return "\(rank - 100)" }
        return switch rank {
        case 14: "A"
        case 13: "K"
        case 12: "Q"
        case 11: "J"
        case 10: "10"
        default: "\(rank)"
        }
    }
    var suitText: String { ["♠", "♥", "♦", "♣"][suit] }
    var label: String { rankText + suitText }
}

struct Deck {
    private var cards: [Card]
    private let lowest: Int

    /// A shuffled deck; `lowest` drops the small cards (euchre and pepper use 9 and up).
    init(lowest: Int = 2) {
        self.lowest = lowest
        cards = Self.fresh(lowest)
    }

    private static func fresh(_ lowest: Int) -> [Card] {
        (lowest...14).flatMap { r in (0..<4).map { Card(rank: r, suit: $0) } }.shuffled()
    }

    /// A full table can run one deck dry (Pai Gow deals 7 each); the dealer opens a fresh one.
    mutating func draw() -> Card {
        if cards.isEmpty { cards = Self.fresh(lowest) }
        return cards.popLast()!
    }
    mutating func draw(_ n: Int) -> [Card] { (0..<n).map { _ in draw() } }
    mutating func drawIfAny() -> Card? { cards.popLast() }
}

// MARK: Poker hands

/// Scores compare lexicographically: category first, then the ranks that break ties.
typealias HandScore = [Int]

func beats(_ a: HandScore, _ b: HandScore) -> Bool {
    for (x, y) in zip(a, b) where x != y { return x > y }
    return a.count > b.count
}

func compare(_ a: HandScore, _ b: HandScore) -> Int {
    beats(a, b) ? 1 : beats(b, a) ? -1 : 0
}

/// Ranks grouped by how many of each, biggest group (then highest rank) first.
private func groups(_ cards: [Card]) -> [(rank: Int, count: Int)] {
    Dictionary(grouping: cards.map(\.rank), by: { $0 }).map { ($0.key, $0.value.count) }
        .sorted { $0.count != $1.count ? $0.count > $1.count : $0.rank > $1.rank }
}

/// The straight's top card, or nil. Ace can play low (A-2-3…).
private func straightHigh(_ cards: [Card]) -> Int? {
    let ranks = Set(cards.map(\.rank))
    guard ranks.count == cards.count else { return nil }
    let sorted = ranks.sorted()
    if sorted.last! - sorted.first! == cards.count - 1 { return sorted.last! }
    if ranks.contains(14), sorted.dropLast() == Array(2...cards.count) { return cards.count }
    return nil
}

private func isFlush(_ cards: [Card]) -> Bool { Set(cards.map(\.suit)).count == 1 }

enum Poker5: Int {
    case high, pair, twoPair, trips, straight, flush, fullHouse, quads, straightFlush

    var name: String {
        ["High card", "Pair", "Two pair", "Three of a kind", "Straight", "Flush", "Full house", "Four of a kind", "Straight flush"][rawValue]
    }
}

/// A 5-card poker hand.
func score5(_ cards: [Card]) -> HandScore {
    let g = groups(cards)
    let flush = isFlush(cards)
    let straight = straightHigh(cards)
    let kickers = g.map(\.rank)
    let cat: Poker5
    switch (g[0].count, g.count > 1 ? g[1].count : 0) {
    case (4, _): cat = .quads
    case (3, 2): cat = .fullHouse
    case (3, _): cat = .trips
    case (2, 2): cat = .twoPair
    case (2, _): cat = .pair
    default:
        if let s = straight { return [(flush ? Poker5.straightFlush : .straight).rawValue, s] }
        cat = flush ? .flush : .high
    }
    return [cat.rawValue] + kickers
}

func combos(_ cards: [Card], _ k: Int) -> [[Card]] {
    guard k > 0 else { return [[]] }
    guard cards.count >= k else { return [] }
    let first = cards[0], rest = Array(cards.dropFirst())
    return combos(rest, k - 1).map { [first] + $0 } + combos(rest, k)
}

/// The best five of however many cards, and which five.
func best5(_ cards: [Card]) -> (score: HandScore, cards: [Card]) {
    combos(cards, 5).map { (score5($0), $0) }.max { beats($1.0, $0.0) }!
}

/// Three Card Poker ranks a straight above a flush: SF, trips, straight, flush, pair, high.
func score3(_ cards: [Card]) -> HandScore {
    let g = groups(cards)
    if g[0].count == 3 { return [4, g[0].rank] }
    if g[0].count == 2 { return [1] + g.map(\.rank) }
    let flush = isFlush(cards)
    if let s = straightHigh(cards) { return [flush ? 5 : 3, s] }
    return [flush ? 2 : 0] + g.map(\.rank)
}

let threeCardNames = ["High card", "Pair", "Flush", "Straight", "Three of a kind", "Straight flush"]

/// Crazy 4 Poker's best four of five: quads, SF, trips, flush, straight, two pair, pair, high.
func best4(_ cards: [Card]) -> HandScore {
    combos(cards, 4).map { hand -> HandScore in
        let g = groups(hand)
        let ranks = g.map(\.rank)
        switch (g[0].count, g.count > 1 ? g[1].count : 0) {
        case (4, _): return [7] + ranks
        case (3, _): return [5] + ranks
        case (2, 2): return [2] + ranks
        case (2, _): return [1] + ranks
        default:
            let flush = isFlush(hand)
            if let s = straightHigh(hand) { return [flush ? 6 : 3, s] }
            return [flush ? 4 : 0] + ranks
        }
    }.max { beats($1, $0) }!
}

let fourCardNames = ["High card", "Pair", "Two pair", "Straight", "Flush", "Three of a kind", "Straight flush", "Four of a kind"]


/// Cards sorted the way you'd hold them: by suit, high to low.
func handSorted(_ cards: [Card]) -> [Card] {
    cards.sorted { $0.suit != $1.suit ? $0.suit < $1.suit : $0.rank > $1.rank }
}

// MARK: The table and the person playing

/// One group of cards lying on the felt.
struct FeltCards {
    var x: Double
    /// The back row is the dealer's side; the front row sits in front of each player.
    var back = false
    var cards: [Card]
    /// Indices of cards lying face down.
    var hidden: Set<Int> = []
    /// Cards before this index are spaced apart from the rest (pai gow's 5 + 2).
    var splitAt: Int?
    var label: String?
}

/// Cards as a game sees them: by seat (nil is the dealer or the middle of the table).
struct FeltGroup {
    var seat: Int?
    var cards: [Card]
    var splitAt: Int? = nil
    var label: String? = nil
    var hidden: Set<Int> = []
}

/// A decision for the person playing the daughter's seat.
struct PlayerPrompt {
    var title: String
    var options: [String] = []
    /// Cards in her hand she may tap to answer.
    var playable: Set<Card>? = nil
    /// Pick exactly this many of her cards, then confirm.
    var pick: Int? = nil
}

enum PlayerAnswer {
    case option(Int)
    case card(Card)
    case cards([Card])
}

/// What a game needs from the Director: whose seat is the player's, and ways to ask, show and wait.
struct TableHost {
    var human: Int?
    var ask: (PlayerPrompt, PlayerAnswer) async throws -> PlayerAnswer
    var show: ([FeltGroup]) -> Void
    /// The player's own cards, for the hand under the stage.
    var hand: ([Card]) -> Void
    /// A note beside each seat on the scoreboard (bids, tricks taken).
    var notes: ([String]) -> Void
    var caption: (String) -> Void
    var pause: (Double) async throws -> Void

    /// The player picks a button; everyone else gets `auto`.
    func option(_ seat: Int, _ title: String, _ options: [String], auto: Int) async throws -> Int {
        guard seat == human else { return auto }
        if case .option(let i) = try await ask(PlayerPrompt(title: title, options: options), .option(auto)) { return i }
        return auto
    }

    /// The player taps one of `playable`; everyone else gets `auto`.
    func card(_ seat: Int, _ title: String, playable: [Card], auto: Card) async throws -> Card {
        guard seat == human else { return auto }
        if case .card(let c) = try await ask(PlayerPrompt(title: title, playable: Set(playable)), .card(auto)), playable.contains(c) { return c }
        return auto
    }
}

/// What happened to one player in one hand.
struct SeatResult {
    var net: Int
    var note: String
}

struct HandResult {
    var felt: [FeltGroup]
    var seats: [SeatResult?]
    var dealerNote: String
}

// MARK: The casino games, played for real

enum MoneyTable {
    /// Plays one hand. `chips[i]` is player i's stack, or nil if she's busted out.
    static func play(_ game: CasinoGame, chips: [Int?], host: TableHost) async throws -> HandResult {
        var stakes = chips.map { stake(game, $0) }
        // The player sets her own bet.
        if let h = host.human, let c = chips[h], let usual = stakes[h] {
            let choices = [5, 10, 25].filter { $0 <= c }
            if choices.count > 1 {
                let i = try await host.option(h, "\(game.name): pick your bet\(betWord(game)). You have $\(c).",
                                              choices.map { "$\($0)" }, auto: choices.firstIndex(of: usual) ?? 0)
                stakes[h] = choices[i]
            }
        }
        switch game {
        case .blackjack: return try await blackjack(chips, stakes, host)
        case .threeCard: return try await threeCard(chips, stakes, host)
        case .letItRide: return try await letItRide(chips, stakes, host)
        case .mississippiStud: return try await mississippi(chips, stakes, host)
        case .crazy4: return try await crazy4(chips, stakes, host)
        case .caribbeanStud: return try await caribbean(chips, stakes, host)
        case .paiGow: return try await paiGow(stakes, host)
        case .baccarat: return try await baccarat(stakes, host)
        case .texasHoldem, .omaha: return try await holdem(game, chips, stakes, host)
        default: return HandResult(felt: [], seats: chips.map { _ in nil }, dealerNote: "")
        }
    }

    private static func betWord(_ game: CasinoGame) -> String {
        switch game {
        case .letItRide: " (each of 3 bets)"
        case .mississippiStud, .threeCard, .crazy4, .caribbeanStud: " (the ante)"
        case .texasHoldem, .omaha: " (the ante, plus a matching blind)"
        default: ""
        }
    }

    static func unit(_ game: CasinoGame) -> Int {
        switch game {
        case .letItRide, .mississippiStud, .crazy4, .caribbeanStud, .texasHoldem, .omaha: 5
        default: 10
        }
    }

    /// Her bet this hand: the usual unit, or whatever she has left. Nil once she's out of chips.
    /// Raises she can't cover are taken off her choices, so she can play right down to $0.
    static func stake(_ game: CasinoGame, _ chips: Int?) -> Int? {
        guard let chips, chips > 0 else { return nil }
        return min(unit(game), chips)
    }

    // MARK: Blackjack

    private static func bjValue(_ cards: [Card]) -> (total: Int, soft: Bool) {
        var total = cards.reduce(0) { $0 + ($1.rank == 14 ? 11 : min($1.rank, 10)) }
        var aces = cards.filter { $0.rank == 14 }.count
        while total > 21 && aces > 0 { total -= 10; aces -= 1 }
        return (total, aces > 0)
    }

    private static func bjLabel(_ cards: [Card]) -> String {
        let (t, soft) = bjValue(cards)
        return t == 21 && cards.count == 2 ? "BJ" : t > 21 ? "Bust" : soft && t < 21 ? "Soft \(t)" : "\(t)"
    }

    /// 0 hit, 1 stand, 2 double — basic strategy, simplified.
    private static func bjAuto(_ h: [Card], up: Int, canDouble: Bool) -> Int {
        let (t, soft) = bjValue(h)
        if canDouble && !soft && (t == 10 || t == 11) && up < 10 { return 2 }
        let stand = (t >= 17 && !(soft && t == 17)) || (!soft && t >= 12 && up <= 6) || (soft && t >= 18)
        return stand ? 1 : 0
    }

    private static func blackjack(_ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        var hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(2) }
        var dealer = deck.draw(2)
        var bets = stakes.map { $0 ?? 0 }
        let up = dealer[0].rank == 14 ? 11 : min(dealer[0].rank, 10)
        let dealerBJ = bjValue(dealer).total == 21
        func felt(reveal: Bool) -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: dealer, label: reveal ? bjLabel(dealer) : "Shows \(dealer[0].rankText)", hidden: reveal ? [] : [1])]
                + hands.indices.compactMap { i in hands[i].map { FeltGroup(seat: i, cards: $0, label: bjLabel($0)) } }
        }
        host.show(felt(reveal: false))
        if let h = host.human, let mine = hands[h] { host.hand(mine) }
        try await host.pause(0.8)

        if !dealerBJ {
            for i in hands.indices {
                guard var h = hands[i] else { continue }
                while bjValue(h).total < 21 {
                    let canDouble = h.count == 2 && chips[i]! >= bets[i] * 2
                    let options = ["Hit", "Stand"] + (canDouble ? ["Double ($\(bets[i] * 2))"] : [])
                    let pick = try await host.option(i, "Blackjack: you have \(bjLabel(h)). Mom shows \(dealer[0].label).", options,
                                                     auto: bjAuto(h, up: up, canDouble: canDouble))
                    if pick == 1 { break }
                    h.append(deck.draw())
                    hands[i] = h
                    if i == host.human {
                        host.show(felt(reveal: false))
                        host.hand(h)
                    }
                    if pick == 2 { bets[i] *= 2; break }
                }
                hands[i] = h
            }
            if hands.contains(where: { $0.map { bjValue($0).total <= 21 } ?? false }) {
                while bjValue(dealer).total < 17 { dealer.append(deck.draw()) }
            }
        }

        let d = bjValue(dealer).total
        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i] else { seats.append(nil); continue }
            let t = bjValue(h).total
            let natural = t == 21 && h.count == 2
            let bet = bets[i]
            let net: Int, note: String
            if natural && !dealerBJ { (net, note) = (bet * 3 / 2, "Blackjack!") }
            else if natural { (net, note) = (0, "Blackjack push") }
            else if dealerBJ { (net, note) = (-bet, "Dealer blackjack") }
            else if t > 21 { (net, note) = (-bet, "Bust") }
            else if d > 21 || t > d { (net, note) = (bet, d > 21 ? "Dealer busts" : "\(t) beats \(d)") }
            else if t == d { (net, note) = (0, "Push at \(t)") }
            else { (net, note) = (-bet, "\(t) loses to \(d)") }
            seats.append(SeatResult(net: net, note: (bet > stakes[i]! ? "Doubled · " : "") + note))
        }
        return HandResult(felt: felt(reveal: true), seats: seats,
                          dealerNote: dealerBJ ? "Dealer has blackjack" : d > 21 ? "Dealer busts with \(d)" : "Dealer stands on \(d)")
    }

    // MARK: Three Card Poker

    private static func threeCard(_ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        let dealer = deck.draw(3)
        let hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(3) }
        let ds = score3(dealer)
        let qualifies = ds[0] > 0 || !beats([0, 12, 0, 0], ds)
        func felt(reveal: Bool) -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: dealer, label: reveal ? threeCardNames[ds[0]] : nil, hidden: reveal ? [] : [0, 1, 2])]
                + hands.indices.compactMap { i in hands[i].map { FeltGroup(seat: i, cards: $0, label: threeCardNames[score3($0)[0]]) } }
        }
        host.show(felt(reveal: false))
        if let h = host.human, let mine = hands[h] { host.hand(mine) }
        try await host.pause(0.8)

        var plays = hands.map { _ in false }
        for i in hands.indices {
            guard let h = hands[i], let a = stakes[i] else { continue }
            let s = score3(h)
            // Short of the play bet, she has to fold.
            guard chips[i]! >= 2 * a else { continue }
            let auto = s[0] > 0 || !beats([0, 12, 6, 4], s) ? 0 : 1
            plays[i] = try await host.option(i, "Three Card Poker: you have \(threeCardNames[s[0]].lowercased()). Play for $\(a) more, or fold?",
                                             ["Play", "Fold"], auto: auto) == 0
        }

        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i], let a = stakes[i] else { seats.append(nil); continue }
            let s = score3(h)
            guard plays[i] else { seats.append(SeatResult(net: -a, note: "Folds")); continue }
            let bonus = [5: 5, 4: 4, 3: 1][s[0]] ?? 0
            var net: Int, note: String
            if !qualifies { (net, note) = (a, "Dealer doesn't qualify") }
            else {
                switch compare(s, ds) {
                case 1: (net, note) = (2 * a, "\(threeCardNames[s[0]]) wins")
                case 0: (net, note) = (0, "Ties the dealer")
                default: (net, note) = (-2 * a, "Loses to \(threeCardNames[ds[0]].lowercased())")
                }
            }
            if bonus > 0 { net += bonus * a; note += " + ante bonus" }
            seats.append(SeatResult(net: net, note: note))
        }
        return HandResult(felt: felt(reveal: true), seats: seats,
                          dealerNote: qualifies ? "Dealer has \(threeCardNames[ds[0]].lowercased())" : "Dealer doesn't qualify")
    }

    // MARK: Let It Ride

    private static func letItRide(_ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        let hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(3) }
        let board = deck.draw(2)
        var shown = 0
        func felt(_ labels: Bool) -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: board, label: "Community", hidden: Set(shown..<2))]
                + hands.indices.compactMap { i in hands[i].map { FeltGroup(seat: i, cards: $0, label: labels ? liName(score5($0 + board)) : nil) } }
        }
        host.show(felt(false))
        if let h = host.human, let mine = hands[h] { host.hand(mine) }
        try await host.pause(0.8)

        var bets = hands.map { _ in 1 }
        // Two chances to pull a bet back: after your three cards, and after the first community card.
        for round in 0..<2 {
            for i in hands.indices {
                // Bets she can't cover are pulled back for her.
                guard let h = hands[i], let u = stakes[i], bets[i] < min(3, chips[i]! / u) else { continue }
                let seen = h + board.prefix(round)
                let g = groups(seen)
                let suits = Dictionary(grouping: seen, by: { $0.suit }).values.map(\.count).max() ?? 0
                let ride = round == 0
                    ? g[0].count == 3 || (g[0].count == 2 && g[0].rank >= 10) || (isFlush(h) && straightHigh(h) != nil)
                    : g[0].count >= 3 || (g[0].count == 2 && (g[0].rank >= 10 || g[1].count == 2)) || suits == 4
                let pick = try await host.option(i, "Let It Ride: bet \(round + 1) of 3 ($\(u)). Pull it back, or let it ride?",
                                                 ["Pull it back", "Let it ride"], auto: ride ? 1 : 0)
                if pick == 1 { bets[i] += 1 }
            }
            shown += 1
            host.show(felt(false))
            try await host.pause(0.8)
        }

        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i], let u = stakes[i] else { seats.append(nil); continue }
            let s = score5(h + board)
            let cat = Poker5(rawValue: s[0])!
            let pays: Int = switch cat {
            case .straightFlush: s[1] == 14 ? 1000 : 200
            case .quads: 50
            case .fullHouse: 11
            case .flush: 8
            case .straight: 5
            case .trips: 3
            case .twoPair: 2
            case .pair: s[1] >= 10 ? 1 : -1
            case .high: -1
            }
            seats.append(SeatResult(net: pays * bets[i] * u, note: "\(bets[i]) bet\(bets[i] == 1 ? "" : "s") ride · " +
                                    (pays > 0 ? "\(cat.name) pays \(pays) to 1" : "No pair of 10s")))
        }
        return HandResult(felt: felt(true), seats: seats, dealerNote: "Community cards: \(board.map(\.label).joined(separator: " "))")
    }

    private static func liName(_ s: HandScore) -> String {
        s[0] == Poker5.pair.rawValue && s[1] < 10 ? "Small pair" : Poker5(rawValue: s[0])!.name
    }

    // MARK: Mississippi Stud

    private static func studPoints(_ cards: [Card]) -> Int {
        cards.reduce(0) { $0 + ($1.rank >= 11 ? 2 : $1.rank >= 6 ? 1 : 0) }
    }

    private static func mississippi(_ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        let hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(2) }
        let board = deck.draw(3)
        var shown = 0
        var wagered = stakes.map { $0 ?? 0 }
        var folded = hands.map { _ in false }
        func felt() -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: board, label: "Community", hidden: Set(shown..<3))]
                + hands.indices.compactMap { i in hands[i].map { FeltGroup(seat: i, cards: $0, label: folded[i] ? "Folded" : "$\(wagered[i]) in") } }
        }
        host.show(felt())
        if let h = host.human, let mine = hands[h] { host.hand(mine) }
        try await host.pause(0.8)

        // Third, fourth and fifth street: fold, or bet 1x, 2x or 3x the ante.
        for street in 0..<3 {
            for i in hands.indices {
                guard let h = hands[i], let u = stakes[i], !folded[i] else { continue }
                let seen = h + board.prefix(street)
                let g = groups(seen)
                let made = g[0].count >= 2 && (g[0].rank >= 6 || g[0].count >= 3 || g.count > 1 && g[1].count == 2)
                let room = (chips[i]! - wagered[i]) / u
                let sizes = (1...3).filter { $0 <= room }
                let auto = made ? sizes.count : studPoints(seen) >= 2 + street ? min(1, sizes.count) : 0
                let pick = try await host.option(i, "Mississippi Stud, street \(street + 3): you've bet $\(wagered[i]). Fold or raise?",
                                                 ["Fold"] + sizes.map { "Bet $\($0 * u)" }, auto: auto)
                if pick == 0 { folded[i] = true } else { wagered[i] += sizes[pick - 1] * u }
            }
            shown += 1
            host.show(felt())
            try await host.pause(0.8)
        }

        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i] else { seats.append(nil); continue }
            if folded[i] { seats.append(SeatResult(net: -wagered[i], note: "Folds")); continue }
            let s = score5(h + board)
            let cat = Poker5(rawValue: s[0])!
            let pays: Int = switch cat {
            case .straightFlush: s[1] == 14 ? 500 : 100
            case .quads: 40
            case .fullHouse: 10
            case .flush: 6
            case .straight: 4
            case .trips: 3
            case .twoPair: 2
            case .pair: s[1] >= 11 ? 1 : s[1] >= 6 ? 0 : -1
            case .high: -1
            }
            seats.append(SeatResult(net: pays * wagered[i], note: "Bets $\(wagered[i]) · " +
                                    (pays > 0 ? "\(cat.name) pays \(pays) to 1" : pays == 0 ? "Small pair pushes" : "No pair of jacks")))
        }
        var result = felt()
        for k in result.indices where result[k].seat != nil {
            let i = result[k].seat!
            if !folded[i] {
                let s = score5(hands[i]! + board)
                result[k].label = s[0] == 1 ? "Pair of \(Card(rank: s[1], suit: 0).rankText)s" : Poker5(rawValue: s[0])!.name
            }
        }
        return HandResult(felt: result, seats: seats, dealerNote: "Board: \(board.map(\.label).joined(separator: " "))")
    }

    // MARK: Crazy 4 Poker

    private static func crazy4(_ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        let dealer = deck.draw(5)
        let hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(5) }
        let ds = best4(dealer)
        let qualifies = ds[0] > 0 || ds[1] >= 13
        func felt(reveal: Bool) -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: dealer, label: reveal ? fourCardNames[ds[0]] : nil, hidden: reveal ? [] : Set(0..<5))]
                + hands.indices.compactMap { i in hands[i].map { FeltGroup(seat: i, cards: $0, label: fourCardNames[best4($0)[0]]) } }
        }
        host.show(felt(reveal: false))
        if let h = host.human, let mine = hands[h] { host.hand(mine) }
        try await host.pause(0.8)

        // Ante + Super Bonus (if she can cover it); play 1x, or 3x with a pair of aces or better; or fold.
        let bonuses = stakes.indices.map { i in stakes[i].map { chips[i]! >= 2 * $0 ? $0 : 0 } ?? 0 }
        var plays = hands.map { _ in 0 }
        for i in hands.indices {
            guard let h = hands[i], let a = stakes[i] else { continue }
            let s = best4(h)
            let room = chips[i]! - a - bonuses[i]
            let big = s[0] >= 2 || (s[0] == 1 && s[1] == 14)
            let affordable = ([a] + (big ? [3 * a] : [])).filter { $0 <= room }
            let wants = s[0] > 0 || !beats([0, 13, 12, 8, 4], s)
            let pick = try await host.option(i, "Crazy 4 Poker: your best four is \(fourCardNames[s[0]].lowercased()).",
                                             ["Fold"] + affordable.map { "Play $\($0)" }, auto: wants ? affordable.count : 0)
            plays[i] = pick == 0 ? 0 : affordable[pick - 1]
        }

        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i], let a = stakes[i] else { seats.append(nil); continue }
            let s = best4(h)
            let play = plays[i], bonus = bonuses[i]
            guard play > 0 else { seats.append(SeatResult(net: -a - bonus, note: "Folds")); continue }
            let superPays: Int = switch s[0] {
            case 7: s[1] == 14 ? 200 : 30
            case 6: 15
            case 5: 2
            case 4, 3: 1
            default: 0
            }
            var net = 0
            var note: String
            switch compare(s, ds) {
            case 1:
                net = play + (qualifies ? a : 0) + superPays * bonus
                note = "\(fourCardNames[s[0]]) wins" + (qualifies ? "" : " · ante pushes")
            case 0:
                net = superPays * bonus
                note = "Ties the dealer"
            default:
                net = -play - (qualifies ? a : 0) + (superPays > 0 ? superPays * bonus : -bonus)
                note = "Loses to \(fourCardNames[ds[0]].lowercased())"
            }
            if superPays > 0 && bonus > 0 { note += " · Super Bonus" }
            seats.append(SeatResult(net: net, note: note))
        }
        return HandResult(felt: felt(reveal: true), seats: seats,
                          dealerNote: qualifies ? "Dealer has \(fourCardNames[ds[0]].lowercased())" : "Dealer doesn't qualify")
    }

    // MARK: Caribbean Stud

    private static func caribbean(_ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        let dealer = deck.draw(5)
        let hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(5) }
        let ds = score5(dealer)
        // The dealer needs ace-king or better.
        let qualifies = ds[0] > 0 || (ds[1] == 14 && ds[2] == 13)
        let dealerName = Poker5(rawValue: ds[0])!.name
        func felt(reveal: Bool) -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: dealer, label: reveal ? (qualifies ? dealerName : "No A-K") : "Shows \(dealer[0].label)",
                       hidden: reveal ? [] : Set(1..<5))]
                + hands.indices.compactMap { i in hands[i].map { FeltGroup(seat: i, cards: $0, label: Poker5(rawValue: score5($0)[0])!.name) } }
        }
        host.show(felt(reveal: false))
        if let h = host.human, let mine = hands[h] { host.hand(mine) }
        try await host.pause(0.8)

        var raised = hands.map { _ in false }
        for i in hands.indices {
            // Short of the raise, she has to fold.
            guard let h = hands[i], let a = stakes[i], chips[i]! >= 3 * a else { continue }
            let s = score5(h)
            let auto = s[0] > 0 || (s[1] == 14 && s[2] == 13) ? 0 : 1
            raised[i] = try await host.option(i, "Caribbean Stud: you have \(Poker5(rawValue: s[0])!.name.lowercased()). Mom shows \(dealer[0].label).",
                                              ["Raise $\(2 * a)", "Fold"], auto: auto) == 0
        }

        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i], let a = stakes[i] else { seats.append(nil); continue }
            guard raised[i] else { seats.append(SeatResult(net: -a, note: "Folds")); continue }
            let s = score5(h)
            let cat = Poker5(rawValue: s[0])!
            let raise = 2 * a
            let pays: Int = switch cat {
            case .straightFlush: s[1] == 14 ? 100 : 50
            case .quads: 20
            case .fullHouse: 7
            case .flush: 5
            case .straight: 4
            case .trips: 3
            case .twoPair: 2
            default: 1
            }
            if !qualifies {
                seats.append(SeatResult(net: a, note: "Raises · dealer doesn't qualify, ante pays"))
                continue
            }
            switch compare(s, ds) {
            case 1: seats.append(SeatResult(net: a + raise * pays, note: "Raises · \(cat.name) pays \(pays) to 1"))
            case 0: seats.append(SeatResult(net: 0, note: "Raises · ties the dealer"))
            default: seats.append(SeatResult(net: -a - raise, note: "Raises · loses to \(dealerName.lowercased())"))
            }
        }
        return HandResult(felt: felt(reveal: true), seats: seats, dealerNote: qualifies ? "Dealer has \(dealerName.lowercased())" : "Dealer doesn't qualify")
    }

    // MARK: Pai Gow Poker

    private static func score2(_ cards: [Card]) -> HandScore {
        let r = cards.map(\.rank).sorted(by: >)
        return r[0] == r[1] ? [1, r[0]] : [0] + r
    }

    /// The house way: keep the strongest high hand, then the best low hand that still leaves the high hand on top.
    private static func setPaiGow(_ seven: [Card]) -> (high: [Card], low: [Card]) {
        var best: (high: [Card], low: [Card], key: HandScore)?
        for low in combos(seven, 2) {
            let high = seven.filter { !low.contains($0) }
            let hs = score5(high), ls = score2(low)
            guard compare(hs, ls) >= 0 else { continue }
            let key = [hs[0]] + ls
            if best == nil || beats(key, best!.key) { best = (high, low, key) }
        }
        return (best!.high, best!.low)
    }

    private static func paiGow(_ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        var deck = Deck()
        let dealer = setPaiGow(deck.draw(7))
        var sets: [(high: [Card], low: [Card])?] = stakes.map { $0 == nil ? nil : setPaiGow(deck.draw(7)) }
        func felt(reveal: Bool) -> [FeltGroup] {
            [FeltGroup(seat: nil, cards: dealer.high + dealer.low, splitAt: 5,
                       label: reveal ? Poker5(rawValue: score5(dealer.high)[0])!.name : nil, hidden: reveal ? [] : Set(0..<7))]
                + sets.indices.compactMap { i in sets[i].map { FeltGroup(seat: i, cards: $0.high + $0.low, splitAt: 5,
                                                                         label: Poker5(rawValue: score5($0.high)[0])!.name) } }
        }
        // The player sets her own hand: tap the two cards for the low hand.
        if let h = host.human, let mine = sets[h] {
            let seven = handSorted(mine.high + mine.low)
            host.hand(seven)
            var title = "Pai Gow: tap the 2 cards for your low hand. Your 5-card hand has to beat it."
            while true {
                let answer = try await host.ask(PlayerPrompt(title: title, options: ["Use the house way"], pick: 2), .option(0))
                guard case .cards(let low) = answer, low.count == 2 else { break }
                let high = seven.filter { !low.contains($0) }
                if compare(score5(high), score2(low)) >= 0 {
                    sets[h] = (high, low)
                    break
                }
                title = "Your 2-card hand can't beat your 5-card hand. Pick 2 again."
            }
        }
        host.show(felt(reveal: false))
        try await host.pause(1)

        let dh = score5(dealer.high), dl = score2(dealer.low)
        var seats: [SeatResult?] = []
        for i in sets.indices {
            guard let me = sets[i], let bet = stakes[i] else { seats.append(nil); continue }
            // Copies go to the dealer.
            let wins = (beats(score5(me.high), dh) ? 1 : 0) + (beats(score2(me.low), dl) ? 1 : 0)
            switch wins {
            case 2: seats.append(SeatResult(net: bet - max(1, (bet * 5 + 99) / 100), note: "Wins both hands (5% commission)"))
            case 1: seats.append(SeatResult(net: 0, note: "Splits · push"))
            default: seats.append(SeatResult(net: -bet, note: "Dealer wins both"))
            }
        }
        return HandResult(felt: felt(reveal: true), seats: seats,
                          dealerNote: "Dealer sets \(Poker5(rawValue: dh[0])!.name.lowercased()) over \(dealer.low.map(\.label).joined(separator: " "))")
    }

    // MARK: Baccarat

    private static func bacValue(_ cards: [Card]) -> Int {
        cards.reduce(0) { $0 + ($1.rank == 14 ? 1 : $1.rank >= 10 ? 0 : $1.rank) } % 10
    }

    private static func baccarat(_ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        let sides = ["Player", "Banker", "Tie"]
        var bets: [String?] = []
        for i in stakes.indices {
            guard stakes[i] != nil else { bets.append(nil); continue }
            let roll = Double.random(in: 0...1)
            let auto = roll < 0.47 ? 0 : roll < 0.94 ? 1 : 2
            bets.append(sides[try await host.option(i, "Baccarat: bet $\(stakes[i]!) on Player, Banker (pays 19 to 20) or Tie (pays 8 to 1)?",
                                                     sides, auto: auto)])
        }

        var deck = Deck()
        var player = deck.draw(2), banker = deck.draw(2)
        let natural = bacValue(player) >= 8 || bacValue(banker) >= 8
        if !natural {
            var third: Card?
            if bacValue(player) <= 5 {
                let c = deck.draw()
                player.append(c)
                third = c
            }
            let b = bacValue(banker)
            let draws: Bool
            if let third {
                let t = third.rank == 14 ? 1 : third.rank >= 10 ? 0 : third.rank
                draws = switch b {
                case 0...2: true
                case 3: t != 8
                case 4: (2...7).contains(t)
                case 5: (4...7).contains(t)
                case 6: t == 6 || t == 7
                default: false
                }
            } else {
                draws = b <= 5
            }
            if draws { banker.append(deck.draw()) }
        }
        let p = bacValue(player), b = bacValue(banker)
        let winner = p > b ? "Player" : b > p ? "Banker" : "Tie"
        var felt = [FeltGroup(seat: nil, cards: player + banker, splitAt: player.count, label: "Player \(p) · Banker \(b)")]
        var seats: [SeatResult?] = []
        for i in stakes.indices {
            guard let bet = stakes[i], let side = bets[i] else { seats.append(nil); continue }
            felt.append(FeltGroup(seat: i, cards: [], label: "On \(side)"))
            let net: Int
            if side == "Tie" { net = winner == "Tie" ? bet * 8 : -bet }
            else if winner == "Tie" { net = 0 }
            else if side == winner { net = side == "Banker" ? bet * 95 / 100 : bet }
            else { net = -bet }
            seats.append(SeatResult(net: net, note: "Bets \(side) · \(winner == "Tie" ? "Tie" : "\(winner) wins")"))
        }
        return HandResult(felt: felt, seats: seats, dealerNote: winner == "Tie" ? "Tie at \(p)" : "\(winner) wins, \(max(p, b)) to \(min(p, b))")
    }

    // MARK: Texas and Omaha Hold'em (played against the house, Ultimate Hold'em style)

    /// Her best five: any five of hole + board in Texas; exactly two hole cards and three from the board in Omaha.
    static func holdemBest(_ game: CasinoGame, hole: [Card], board: [Card]) -> HandScore {
        guard game == .omaha else { return best5(hole + board).score }
        return combos(hole, 2).flatMap { h in combos(board, 3).map { score5(h + $0) } }.max { beats($1, $0) }!
    }

    /// What a hand is called, e.g. "Pair of Ks".
    private static func handName(_ s: HandScore) -> String {
        s[0] == Poker5.pair.rawValue ? "Pair of \(Card(rank: s[1], suit: 0).rankText)s" : Poker5(rawValue: s[0])!.name
    }

    /// Ante and blind go out together; she may raise 4x or 3x before the flop, 2x after it, or 1x (or fold) on the river.
    /// The dealer opens with a pair or better; otherwise the ante pushes. The blind only pays on a straight or better.
    private static func holdem(_ game: CasinoGame, _ chips: [Int?], _ stakes: [Int?], _ host: TableHost) async throws -> HandResult {
        let holeCount = game == .omaha ? 4 : 2
        var deck = Deck()
        let hands: [[Card]?] = stakes.map { $0 == nil ? nil : deck.draw(holeCount) }
        let dealer = deck.draw(holeCount)
        let board = deck.draw(5)
        // A blind she can't cover is skipped, so she can play down to her last chips.
        let blinds = stakes.indices.map { i in stakes[i].map { chips[i]! >= 2 * $0 ? $0 : 0 } ?? 0 }
        var play = hands.map { _ in 0 }
        var folded = hands.map { _ in false }
        var shown = 0
        func felt(reveal: Bool) -> [FeltGroup] {
            let ds = holdemBest(game, hole: dealer, board: board)
            return [FeltGroup(seat: nil, cards: dealer, label: reveal ? "Dealer · \(handName(ds))" : "Dealer", hidden: reveal ? [] : Set(dealer.indices)),
                    FeltGroup(seat: nil, cards: board, label: "Board", hidden: Set(shown..<5))]
                + hands.indices.compactMap { i in hands[i].map { h in
                    FeltGroup(seat: i, cards: h, label: folded[i] ? "Folded" : reveal ? handName(holdemBest(game, hole: h, board: board))
                                                                                       : play[i] > 0 ? "Raised $\(play[i])" : nil) } }
        }
        host.show(felt(reveal: false))
        if let h = host.human, let mine = hands[h] { host.hand(handSorted(mine)) }
        try await host.pause(0.8)

        // Three decision points: before the flop, after the flop, and after the river.
        for (street, cards) in [(0, 0), (1, 3), (2, 5)] {
            if shown != cards {
                shown = cards
                host.show(felt(reveal: false))
                try await host.pause(0.8)
            }
            for i in hands.indices {
                guard let h = hands[i], let a = stakes[i], !folded[i], play[i] == 0 else { continue }
                let room = chips[i]! - a - blinds[i]
                let seen = Array(board.prefix(cards))
                let ranks = h.map(\.rank).sorted(by: >)
                let pairInHole = Set(ranks).count < ranks.count
                let made = cards == 0 ? [0] : holdemBest(game, hole: h, board: seen)
                let usesHole = made[0] >= Poker5.twoPair.rawValue || (made[0] == 1 && h.contains { $0.rank == made[1] })
                switch street {
                case 0:
                    let sizes = [4, 3].filter { $0 * a <= room }
                    guard !sizes.isEmpty else { continue }
                    let suited = Set(h.map(\.suit)).count < h.count
                    let strong = game == .omaha ? pairInHole && ranks.contains { $0 >= 9 } || ranks[0] == 14 && ranks[1] >= 12
                                                : pairInHole && ranks[0] >= 3 || ranks[0] == 14 || ranks[0] == 13 && (ranks[1] >= 10 || suited && ranks[1] >= 5)
                                                    || ranks[0] == 12 && (ranks[1] >= 10 || suited && ranks[1] >= 8) || ranks[0] == 11 && ranks[1] == 10
                    let pick = try await host.option(i, "\(game.name): your hole cards are \(h.map(\.label).joined(separator: " ")). Check, or raise before the flop?",
                                                     ["Check"] + sizes.map { "Raise $\($0 * a)" }, auto: strong ? 1 : 0)
                    if pick > 0 { play[i] = sizes[pick - 1] * a }
                case 1:
                    guard 2 * a <= room else { continue }
                    let good = made[0] >= Poker5.twoPair.rawValue || (made[0] == 1 && usesHole && (made[1] >= 3 || game == .omaha && made[1] >= 8))
                    let pick = try await host.option(i, "\(game.name) flop: you have \(handName(made).lowercased()). Check, or raise $\(2 * a)?",
                                                     ["Check", "Raise $\(2 * a)"], auto: good ? 1 : 0)
                    if pick == 1 { play[i] = 2 * a }
                default:
                    // Short of the 1x bet, she checks it down and plays for her ante and blind.
                    guard a <= room else { continue }
                    let good = (made[0] >= 1 && usesHole) || made[0] >= Poker5.straight.rawValue || ranks[0] >= (game == .omaha ? 14 : 12)
                    let pick = try await host.option(i, "\(game.name) river: you have \(handName(made).lowercased()). Bet $\(a), or fold?",
                                                     ["Fold", "Bet $\(a)"], auto: good ? 1 : 0)
                    if pick == 1 { play[i] = a } else { folded[i] = true }
                }
            }
            host.show(felt(reveal: false))
        }

        let ds = holdemBest(game, hole: dealer, board: board)
        let qualifies = ds[0] >= Poker5.pair.rawValue
        var seats: [SeatResult?] = []
        for i in hands.indices {
            guard let h = hands[i], let a = stakes[i] else { seats.append(nil); continue }
            let blind = blinds[i]
            if folded[i] { seats.append(SeatResult(net: -a - blind, note: "Folds")); continue }
            let s = holdemBest(game, hole: h, board: board)
            let cat = Poker5(rawValue: s[0])!
            // Omaha makes big hands far more often, so its blind pays less, and only from a flush up.
            let blindPays: Double = switch (game == .omaha, cat) {
            case (true, .straightFlush): s[1] == 14 ? 200 : 30
            case (true, .quads): 8
            case (true, .fullHouse): 2
            case (true, .flush): 1
            case (true, _): 0
            case (false, .straightFlush): s[1] == 14 ? 500 : 50
            case (false, .quads): 10
            case (false, .fullHouse): 3
            case (false, .flush): 1.5
            case (false, .straight): 1
            case (false, _): 0
            }
            let raised = play[i] > 0 ? "Plays $\(play[i]) · " : "Checks it down · "
            switch compare(s, ds) {
            case 1:
                let net = play[i] + (qualifies ? a : 0) + Int(Double(blind) * blindPays)
                seats.append(SeatResult(net: net, note: raised + "\(handName(s)) wins" + (qualifies ? "" : " · ante pushes") + (blindPays > 0 && blind > 0 ? " · blind pays" : "")))
            case 0:
                seats.append(SeatResult(net: 0, note: raised + "ties the dealer"))
            default:
                seats.append(SeatResult(net: -play[i] - (qualifies ? a : 0) - blind, note: raised + "loses to \(handName(ds).lowercased())"))
            }
        }
        return HandResult(felt: felt(reveal: true), seats: seats,
                          dealerNote: qualifies ? "Dealer has \(handName(ds).lowercased())" : "Dealer has \(handName(ds).lowercased()) · no pair, ante pushes")
    }
}
