import Foundation

struct PlayingCard: Hashable, Codable {
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
    private var cards: [PlayingCard]
    private let lowest: Int

    /// A shuffled deck; `lowest` drops the small cards (euchre and pepper use 9 and up).
    init(lowest: Int = 2) {
        self.lowest = lowest
        cards = Self.fresh(lowest)
    }

    private static func fresh(_ lowest: Int) -> [PlayingCard] {
        (lowest...14).flatMap { r in (0..<4).map { PlayingCard(rank: r, suit: $0) } }.shuffled()
    }

    /// Runs a fresh deck if this one is empty.
    mutating func draw() -> PlayingCard {
        if cards.isEmpty { cards = Self.fresh(lowest) }
        return cards.popLast()!
    }
    mutating func draw(_ n: Int) -> [PlayingCard] { (0..<n).map { _ in draw() } }
    mutating func drawIfAny() -> PlayingCard? { cards.popLast() }
}

/// Every way to choose `k` of `cards`.
func combos(_ cards: [PlayingCard], _ k: Int) -> [[PlayingCard]] {
    guard k > 0 else { return [[]] }
    guard cards.count >= k else { return [] }
    let first = cards[0], rest = Array(cards.dropFirst())
    return combos(rest, k - 1).map { [first] + $0 } + combos(rest, k)
}

/// Cards sorted the way you'd hold them: by suit, high to low.
func handSorted(_ cards: [PlayingCard]) -> [PlayingCard] {
    cards.sorted { $0.suit != $1.suit ? $0.suit < $1.suit : $0.rank > $1.rank }
}

// MARK: The table and the person playing

/// Cards as a game sees them: by seat (nil is the dealer or the middle of the table).
struct FeltGroup {
    var seat: Int?
    var cards: [PlayingCard]
    var splitAt: Int? = nil
    var label: String? = nil
    var hidden: Set<Int> = []
}

/// A decision for the person playing the daughter's seat.
struct PlayerPrompt {
    var title: String
    var options: [String] = []
    /// Cards in her hand she may tap to answer.
    var playable: Set<PlayingCard>? = nil
    /// Pick exactly this many of her cards, then confirm.
    var pick: Int? = nil
}

enum PlayerAnswer {
    case option(Int)
    case card(PlayingCard)
    case cards([PlayingCard])
}

/// What a game needs from the Director: whose seat is the player's, and ways to ask, show and wait.
struct TableHost {
    var human: Int?
    var ask: (PlayerPrompt, PlayerAnswer) async throws -> PlayerAnswer
    var show: ([FeltGroup]) -> Void
    /// The player's own cards, for the hand under the stage.
    var hand: ([PlayingCard]) -> Void
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
    func card(_ seat: Int, _ title: String, playable: [PlayingCard], auto: PlayingCard) async throws -> PlayingCard {
        guard seat == human else { return auto }
        if case .card(let c) = try await ask(PlayerPrompt(title: title, playable: Set(playable)), .card(auto)), playable.contains(c) { return c }
        return auto
    }
}
