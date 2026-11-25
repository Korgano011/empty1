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


