import SwiftUI
import AVFoundation

// The spare-room video poker machine — modeled on the Princess of Poker's machine.
// Nine games of `PokerSession.handsPerGame` hands each; play the max bet the whole way through
// and you reach game 10, where the machine's mini saucer takes over.
// Started as a shared copy with Clown Transformation Card Games; this copy now plays 20-hand games
// and games 5–9 are all Pick'em.
// every type is prefixed `PK` so nothing clashes with either app's own cards.

// MARK: - Cards

enum PKSuit: Int, CaseIterable, Hashable {
    case clubs, diamonds, hearts, spades

    var symbol: String { ["♣", "♦", "♥", "♠"][rawValue] }
    var isRed: Bool { self == .diamonds || self == .hearts }
}

struct PKCard: Identifiable, Hashable {
    /// 2…14 (ace high); 0 is the joker.
    let rank: Int
    let suit: PKSuit
    /// Tells the jokers apart in a deck with more than one (Five Joker Poker has five).
    var copy = 0

    var id: Int { rank == 0 ? 52 + copy : (rank - 2) * 4 + suit.rawValue }
    var isJoker: Bool { rank == 0 }

    static let joker = PKCard(rank: 0, suit: .spades)

    var rankText: String {
        switch rank {
        case 14: "A"
        case 13: "K"
        case 12: "Q"
        case 11: "J"
        case 0: "★"
        default: "\(rank)"
        }
    }
}

enum PKDeck {
    static func fresh(jokers: Int) -> [PKCard] {
        var cards = PKSuit.allCases.flatMap { s in (2...14).map { PKCard(rank: $0, suit: s) } }
        cards += (0..<jokers).map { PKCard(rank: 0, suit: .spades, copy: $0) }
        return cards
    }

    static func shuffled(jokers: Int) -> [PKCard] { fresh(jokers: jokers).shuffled() }
}

// MARK: - Hands and wild cards

/// Video poker results, weakest to strongest. Which ones pay depends on the game.
enum PKHand: Int, CaseIterable, Comparable {
    case nothing, lowPair, highPair, twoPair, trips, straight, flush, fullHouse, quads,
         straightFlush, fiveKind, wildRoyal, fourDeuces, fiveWilds, royal

    static func < (a: PKHand, b: PKHand) -> Bool { a.rawValue < b.rawValue }
}

enum PKRules {
    /// No wild cards; a pair pays from `minPair` (11 = jacks) up.
    case natural(minPair: Int)
    /// The joker is wild; a pair pays from `minPair` up.
    case joker(minPair: Int)
    case deuces
    case deucesJoker

    func isWild(_ c: PKCard) -> Bool {
        switch self {
        case .natural: false
        case .joker: c.isJoker
        case .deuces: c.rank == 2
        case .deucesJoker: c.isJoker || c.rank == 2
        }
    }

    var minPair: Int {
        switch self {
        case .natural(let m), .joker(let m): m
        default: 14   // deuces games: a pair of aces
        }
    }

    /// Ranks a 5-card hand under these wild-card rules.
    func evaluate(_ cards: [PKCard]) -> PKHand {
        let w = cards.filter(isWild).count
        let nat = cards.filter { !isWild($0) }
        let ranks = nat.map(\.rank)
        var counts: [Int: Int] = [:]
        for r in ranks { counts[r, default: 0] += 1 }
        let shape = counts.values.sorted(by: >)
        let maxCount = shape.first ?? 0
        let sameSuit = Set(nat.map(\.suit)).count <= 1
        let distinct = Set(ranks).count == ranks.count
        let deuces = cards.filter { $0.rank == 2 }.count

        func fits(_ highs: [Int]) -> Bool {
            guard distinct else { return false }
            return highs.contains { high in
                let low = high - 4
                return ranks.allSatisfy { r in (low...high).contains(r) || (r == 14 && low == 1) }
            }
        }
        let royalShape = fits([14])
        let straight = fits(Array(5...14))

        if w == 0 && sameSuit && royalShape { return .royal }
        if w == 5 { return .fiveWilds }
        switch self {
        case .deuces, .deucesJoker: if deuces == 4 { return .fourDeuces }
        // Four jokers (only Five Joker Poker has that many) rank where four deuces do.
        case .joker: if w == 4 { return .fourDeuces }
        default: break
        }
        if w > 0 && sameSuit && royalShape { return .wildRoyal }
        if w > 0 && maxCount + w >= 5 { return .fiveKind }
        if sameSuit && straight { return .straightFlush }
        if maxCount + w >= 4 { return .quads }
        if shape == [3, 2] || (w == 1 && shape == [2, 2]) { return .fullHouse }
        if sameSuit { return .flush }
        if straight { return .straight }
        if maxCount + w >= 3 { return .trips }
        if w == 0 && shape.starts(with: [2, 2]) { return .twoPair }
        if w == 0, let pair = counts.first(where: { $0.value == 2 })?.key, pair >= minPair { return .highPair }
        if w == 1, let top = ranks.max(), top >= minPair { return .highPair }
        return .nothing
    }
}

// MARK: - The nine games

struct PKPayRow: Identifiable {
    let hand: PKHand
    let name: String
    /// Credits paid per credit bet.
    let pays: Int
    /// What 5 credits pays, when it isn't simply 5 × `pays`.
    var maxPays: Int? = nil

    var id: PKHand { hand }

    func payout(bet: Int) -> Int {
        if bet == 5, let maxPays { return maxPays }
        return pays * bet
    }
}

/// The Princess of Poker's line-up, with both Sneaky Queens games replaced by Deuces Joker Wild:
/// games 1–4 are Double Down Stud and the last five, 5–9, are Pick'em.
enum PKGame: Int, CaseIterable {
    case jacks, joker, deuces, deucesJoker, pickJacks, pickJoker, pickDeuces, pickDeucesJoker, pickFiveJoker

    enum Style { case doubleDown, pickEm, draw }

    var number: Int { rawValue + 1 }

    var title: String {
        switch self {
        case .jacks: "Double Down Stud"
        case .joker: "Joker Poker"
        case .deuces: "Deuces Wild"
        case .deucesJoker: "Deuces Joker Wild"
        case .pickJacks: "Pick'em Nines or Better"
        case .pickJoker: "Pick'em Joker Poker"
        case .pickDeuces: "Pick'em Deuces Wild"
        case .pickDeucesJoker: "Pick'em Deuces Joker Wild"
        case .pickFiveJoker: "Pick'em Five Joker Poker"
        }
    }

    /// How the host announces it: games 2–4 are Double Down Stud versions.
    var spokenTitle: String {
        style == .doubleDown && self != .jacks ? "Double Down Stud \(title)" : title
    }

    var style: Style {
        switch self {
        case .jacks, .joker, .deuces, .deucesJoker: .doubleDown
        default: .pickEm
        }
    }

    var rules: PKRules {
        switch self {
        case .jacks: .natural(minPair: 11)
        case .joker: .joker(minPair: 8)
        case .pickJacks: .natural(minPair: 9)
        case .pickFiveJoker: .joker(minPair: 13)
        case .pickJoker: .joker(minPair: 11)
        case .deuces, .pickDeuces: .deuces
        case .deucesJoker, .pickDeucesJoker: .deucesJoker
        }
    }

    /// Jokers in the deck: one in the joker games, five in Five Joker Poker.
    var jokers: Int {
        if self == .pickFiveJoker { return 5 }
        switch rules {
        case .joker, .deucesJoker: return 1
        default: return 0
        }
    }

    func isWild(_ c: PKCard) -> Bool { rules.isWild(c) }

    /// Double Down Jacks or Better also pays even money (a push) on a pair of 6s through 10s.
    func evaluate(_ cards: [PKCard]) -> PKHand {
        let h = rules.evaluate(cards)
        if h == .nothing, self == .jacks {
            let counts = Dictionary(grouping: cards, by: \.rank).mapValues(\.count)
            if counts.contains(where: { $0.value == 2 && (6...10).contains($0.key) }) { return .lowPair }
        }
        return h
    }

    var paytable: [PKPayRow] {
        switch self {
        case .jacks:
            [PKPayRow(hand: .royal, name: "Royal Flush", pays: 2000),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 200),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 50),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 12),
             PKPayRow(hand: .flush, name: "Flush", pays: 9),
             PKPayRow(hand: .straight, name: "Straight", pays: 8),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 4),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 3),
             PKPayRow(hand: .highPair, name: "Jacks or Better", pays: 2),
             PKPayRow(hand: .lowPair, name: "6s through 10s", pays: 1)]
        case .joker:
            [PKPayRow(hand: .royal, name: "Natural Royal", pays: 2000),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 400),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 200),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 100),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 30),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 12),
             PKPayRow(hand: .flush, name: "Flush", pays: 8),
             PKPayRow(hand: .straight, name: "Straight", pays: 6),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 4),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 3),
             PKPayRow(hand: .highPair, name: "8s or Better", pays: 1)]
        case .deuces:
            [PKPayRow(hand: .royal, name: "Natural Royal", pays: 2000),
             PKPayRow(hand: .fourDeuces, name: "4 Deuces", pays: 400),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 100),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 40),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 25),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 8),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 6),
             PKPayRow(hand: .flush, name: "Flush", pays: 4),
             PKPayRow(hand: .straight, name: "Straight", pays: 4),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 2),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 1),
             PKPayRow(hand: .highPair, name: "Pair of Aces", pays: 1)]
        case .deucesJoker:
            // Double Down Stud version: no draws, so it pays more than the draw game.
            [PKPayRow(hand: .fiveWilds, name: "4 Deuces + Joker", pays: 2000),
             PKPayRow(hand: .royal, name: "Natural Royal", pays: 1000, maxPays: 6000),
             PKPayRow(hand: .fourDeuces, name: "4 Deuces", pays: 200),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 50),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 20),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 15),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 5),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 4),
             PKPayRow(hand: .flush, name: "Flush", pays: 3),
             PKPayRow(hand: .straight, name: "Straight", pays: 3),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 2),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 1),
             PKPayRow(hand: .highPair, name: "Pair of Aces", pays: 1)]
        case .pickJacks:
            [PKPayRow(hand: .royal, name: "Royal Flush", pays: 1000, maxPays: 6000),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 200),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 100),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 18),
             PKPayRow(hand: .flush, name: "Flush", pays: 15),
             PKPayRow(hand: .straight, name: "Straight", pays: 11),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 5),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 3),
             PKPayRow(hand: .highPair, name: "9s or Better", pays: 2)]
        case .pickJoker:
            [PKPayRow(hand: .royal, name: "Natural Royal", pays: 1000, maxPays: 6000),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 200, maxPays: 2000),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 200),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 100),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 50),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 10),
             PKPayRow(hand: .flush, name: "Flush", pays: 7),
             PKPayRow(hand: .straight, name: "Straight", pays: 5),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 4),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 3),
             PKPayRow(hand: .highPair, name: "Jacks or Better", pays: 2)]
        case .pickDeuces:
            [PKPayRow(hand: .royal, name: "Natural Royal", pays: 1000, maxPays: 6000),
             PKPayRow(hand: .fourDeuces, name: "4 Deuces", pays: 500),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 50),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 20),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 15),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 10),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 7),
             PKPayRow(hand: .flush, name: "Flush", pays: 5),
             PKPayRow(hand: .straight, name: "Straight", pays: 4),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 3),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 2),
             PKPayRow(hand: .highPair, name: "Pair of Aces", pays: 1)]
        case .pickDeucesJoker:
            [PKPayRow(hand: .fiveWilds, name: "4 Deuces + Joker", pays: 5000),
             PKPayRow(hand: .royal, name: "Natural Royal", pays: 1000, maxPays: 5000),
             PKPayRow(hand: .fourDeuces, name: "4 Deuces", pays: 100),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 20),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 15),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 10),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 4),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 4),
             PKPayRow(hand: .flush, name: "Flush", pays: 4),
             PKPayRow(hand: .straight, name: "Straight", pays: 3),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 2),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 1),
             PKPayRow(hand: .highPair, name: "Pair of Aces", pays: 1)]
        case .pickFiveJoker:
            // Five wild jokers in a 57-card deck: big wild hands come often, so the small ones pay less.
            [PKPayRow(hand: .fiveWilds, name: "5 Jokers", pays: 2000, maxPays: 10000),
             PKPayRow(hand: .royal, name: "Natural Royal", pays: 1000, maxPays: 6000),
             PKPayRow(hand: .fourDeuces, name: "4 Jokers", pays: 400),
             PKPayRow(hand: .wildRoyal, name: "Wild Royal", pays: 50),
             PKPayRow(hand: .fiveKind, name: "5 of a Kind", pays: 25),
             PKPayRow(hand: .straightFlush, name: "Straight Flush", pays: 15),
             PKPayRow(hand: .quads, name: "4 of a Kind", pays: 8),
             PKPayRow(hand: .fullHouse, name: "Full House", pays: 6),
             PKPayRow(hand: .flush, name: "Flush", pays: 5),
             PKPayRow(hand: .straight, name: "Straight", pays: 4),
             PKPayRow(hand: .trips, name: "3 of a Kind", pays: 2),
             PKPayRow(hand: .twoPair, name: "Two Pair", pays: 2),
             PKPayRow(hand: .highPair, name: "Kings or Better", pays: 1)]
        }
    }

    func row(for hand: PKHand) -> PKPayRow? { paytable.first { $0.hand == hand } }

    /// Credits back on a hand at `bet`.
    func payout(_ cards: [PKCard], bet: Int) -> Int { row(for: evaluate(cards))?.payout(bet: bet) ?? 0 }
}

// MARK: - Who runs the machine

enum PokerHost {
    case animals, clowns

    var title: String { self == .animals ? "THE ANIMALS OF POKER" : "THE CLOWNS OF POKER" }
    var name: String { self == .animals ? "the Animals of Poker" : "the Clowns of Poker" }
    var hello: String { self == .animals ? "Roar!" : "Honk honk!" }
    var pet: String { self == .animals ? "cub" : "sweetie" }
    var cheers: [String] {
        self == .animals ? ["Roar! Nice hand, cub!", "Now that's a wild one!", "The whole jungle is cheering!"]
                         : ["Honk honk! Nice hand!", "Ha-ha! Look at you go!", "That's no joke — what a hand!"]
    }
    var screenTop: Color { self == .animals ? Color(red: 0.05, green: 0.22, blue: 0.08) : Color(red: 0.25, green: 0.03, blue: 0.22) }
    var screenBottom: Color { self == .animals ? Color(red: 0.01, green: 0.07, blue: 0.02) : Color(red: 0.07, green: 0.0, blue: 0.08) }
    var accent: Color { self == .animals ? Color(red: 1, green: 0.72, blue: 0.2) : Color(red: 1, green: 0.4, blue: 0.75) }
    var backTop: Color { self == .animals ? Color(red: 0.2, green: 0.45, blue: 0.15) : Color(red: 0.75, green: 0.1, blue: 0.5) }
    var backBottom: Color { self == .animals ? Color(red: 0.08, green: 0.25, blue: 0.08) : Color(red: 0.4, green: 0.05, blue: 0.4) }
    var backMark: String { self == .animals ? "🐾" : "🤡" }
}

/// Plays the host's lines out loud.
@MainActor final class PokerVoice {
    private let synth = AVSpeechSynthesizer()
    var muted = false

    /// The Animals of Poker talk in a man's voice. Many voices don't report a gender, so this goes by name:
    /// the best-quality US man available (Evan, Nathan, Tom, Aaron, Alex, then Reed, Eddy…), Daniel or Arthur
    /// from the UK, any voice flagged male, and Fred only as a last resort.
    private static let maleVoice: AVSpeechSynthesisVoice? = {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
        let names = ["Evan", "Nathan", "Tom", "Aaron", "Alex", "Reed", "Eddy", "Rocko", "Daniel", "Arthur", "Gordon", "Ralph"]
        for name in names {
            let matches = english.filter { $0.name == name }
            if let v = matches.max(by: { a, b in
                (a.quality.rawValue, a.language == "en-US" ? 1 : 0) < (b.quality.rawValue, b.language == "en-US" ? 1 : 0)
            }) { return v }
        }
        return english.first { $0.gender == .male && $0.name != "Fred" }
            ?? english.first { $0.gender == .male }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }()

    func speak(_ text: String, host: PokerHost) {
        guard !muted else { return }
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = host == .animals ? Self.maleVoice : AVSpeechSynthesisVoice(language: "en-US")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * (host == .animals ? 0.95 : 1.05)
        u.pitchMultiplier = host == .animals ? 0.8 : 1.5
        synth.speak(u)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }
}

enum PokerSound { case card, coin, chime }

// MARK: - One sitting at the machine

@MainActor @Observable final class PokerSession {
    enum Phase { case intro, ready, doubling, picking, holding, result, over }
    enum Ending { case broke, notMaxBet, qualified }

    static let startCredits = 200
    /// Every game on the spare-room machine is 20 hands.
    static let handsPerGame = 20

    let player: String
    let host: PokerHost
    var credits = startCredits
    var game = PKGame.jacks
    var handsPlayed = 0
    var bet = 5
    var doubled = false
    var maxBetThroughout = true
    var phase = Phase.intro
    var hand: [PKCard] = []
    var held: Set<Int> = []
    var piles: [[PKCard]] = []
    var pickedPile: Int?
    var result = PKHand.nothing
    var won = 0
    var ending: Ending?
    var line = ""
    var talkingUntil = Date.distantPast
    /// Plays every hand for you at the max bet.
    var autoPlay = false { didSet { if autoPlay { scheduleAuto() } } }

    @ObservationIgnored private var deck: [PKCard] = []
    @ObservationIgnored private var introTask: Task<Void, Never>?
    @ObservationIgnored private var autoTask: Task<Void, Never>?
    @ObservationIgnored let voice = PokerVoice()
    @ObservationIgnored var onSound: ((PokerSound) -> Void)?
    /// Called when the sitting ends; the Director takes over at game 10.
    @ObservationIgnored var onEnd: ((Ending) -> Void)?

    init(player: String, host: PokerHost, muted: Bool) {
        self.player = player
        self.host = host
        voice.muted = muted
    }

    var talking: Bool { Date.now < talkingUntil }
    var totalBet: Int { bet * (doubled ? 2 : 1) }

    func say(_ text: String) {
        line = text
        talkingUntil = .now + Double(text.count) * 0.065 + 0.5
        voice.speak(text, host: host)
    }

    func begin() { announce(first: true) }

    /// Stops talking and playing (the story was restarted).
    func shutDown() {
        introTask?.cancel()
        autoTask?.cancel()
        voice.stop()
        onEnd = nil
    }

    private static let numberWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

    private func announce(first: Bool = false) {
        phase = .intro
        hand = []
        held = []
        piles = []
        pickedPile = nil
        doubled = false
        let n = Self.numberWords[game.number]
        say(first ? "\(host.hello) Welcome, \(player). We are \(host.name). Welcome to game \(n): \(game.spokenTitle). Let's begin."
                  : "Game \(n) is \(game.spokenTitle). Let's begin.")
        let pause = (first ? 6.5 : 3.5) + (game.style == .doubleDown ? 1 : 0)
        introTask?.cancel()
        introTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(pause))
            guard let self, !Task.isCancelled, self.phase == .intro else { return }
            self.phase = .ready
            self.scheduleAuto()
        }
    }

    var betweenHands: Bool { phase == .ready || phase == .result || phase == .intro }
    var canDeal: Bool { betweenHands && credits > 0 && ending == nil }
    var canDouble: Bool { phase == .doubling && credits >= bet }

    func betOne() {
        guard betweenHands, ending == nil else { return }
        bet = bet >= min(5, credits) ? 1 : bet + 1
        onSound?(.card)
    }

    func betMax() {
        guard betweenHands, ending == nil else { return }
        bet = min(5, credits)
        deal()
    }

    func deal() {
        guard canDeal else { return }
        introTask?.cancel()
        bet = min(bet, credits)
        credits -= bet
        if bet < 5 { maxBetThroughout = false }
        deck = PKDeck.shuffled(jokers: game.jokers)
        won = 0
        result = .nothing
        pickedPile = nil
        doubled = false
        held = []
        onSound?(.card)
        hand = Array(deck.prefix(5))
        switch game.style {
        case .pickEm:
            hand = Array(deck.prefix(2))
            piles = [Array(deck[2..<5]), Array(deck[5..<8])]
            deck.removeFirst(8)
            phase = .picking
        case .doubleDown:
            // Four cards face up; the fifth waits face down until you double down or stand.
            deck.removeFirst(5)
            phase = .doubling
        case .draw:
            deck.removeFirst(5)
            phase = .holding
        }
        scheduleAuto()
    }

    func doubleDown() {
        guard canDouble else { return }
        credits -= bet
        doubled = true
        onSound?(.coin)
        settle()
    }

    func stand() {
        guard phase == .doubling else { return }
        onSound?(.card)
        settle()
    }

    func pick(_ pile: Int) {
        guard phase == .picking else { return }
        pickedPile = pile
        hand += piles[pile]
        onSound?(.card)
        settle()
    }

    func toggleHold(_ i: Int) {
        guard phase == .holding, hand.indices.contains(i) else { return }
        if held.contains(i) { held.remove(i) } else { held.insert(i) }
        onSound?(.card)
    }

    func draw() {
        guard phase == .holding else { return }
        for i in hand.indices where !held.contains(i) { hand[i] = deck.removeFirst() }
        onSound?(.card)
        settle()
    }

    private func settle() {
        result = game.evaluate(hand)
        won = game.row(for: result)?.payout(bet: totalBet) ?? 0
        credits += won
        handsPlayed += 1
        phase = .result
        if won > 0 { onSound?(.coin) }
        if result >= .fullHouse, won > 0 {
            onSound?(.chime)
            say(host.cheers.randomElement()!)
        }

        if credits <= 0 {
            end(.broke)
        } else if handsPlayed >= Self.handsPerGame {
            if game == PKGame.allCases.last {
                end(maxBetThroughout ? .qualified : .notMaxBet)
            } else {
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(1.6))
                    guard let self, self.phase == .result, self.ending == nil else { return }
                    self.game = PKGame(rawValue: self.game.rawValue + 1)!
                    self.handsPlayed = 0
                    self.announce()
                }
            }
        } else {
            scheduleAuto()
        }
    }

    /// Insert credits: start again at game 1 with a fresh 200 credits.
    func restart() {
        ending = nil
        credits = Self.startCredits
        game = .jacks
        handsPlayed = 0
        bet = 5
        maxBetThroughout = true
        won = 0
        announce(first: true)
    }

    private func end(_ e: Ending) {
        introTask?.cancel()
        autoTask?.cancel()
        ending = e
        phase = .over
        switch e {
        case .broke: say("You are good, \(host.pet), but not good enough. Insert credits and try again.")
        case .notMaxBet: say("You did not play the max bet of 5 the whole way through, so you do not qualify for game 10. Insert credits and try again.")
        case .qualified: say("You are very, very good, \(player)! You have made it to game 10. Let's begin.")
        }
        onEnd?(e)
    }

    var resultText: String {
        guard phase == .result || (phase == .over && !hand.isEmpty) else { return "" }
        guard won > 0, let row = game.row(for: result) else { return "No win" }
        return "\(row.name)! Win \(won)" + (doubled ? " (doubled down)" : "")
    }

    // MARK: Auto play

    private func scheduleAuto() {
        guard autoPlay, ending == nil else { return }
        autoTask?.cancel()
        autoTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            guard let self, !Task.isCancelled, self.autoPlay else { return }
            self.autoStep()
        }
    }

    private func autoStep() {
        switch phase {
        case .ready, .result:
            bet = 5
            betMax()
        case .doubling:
            // Double whenever the average fifth card pays back more than the bet.
            let seen = Array(hand.prefix(4))
            let rest = PKDeck.fresh(jokers: game.jokers).filter { !seen.contains($0) }
            let avg = Double(rest.map { game.payout(seen + [$0], bet: 1) }.reduce(0, +)) / Double(rest.count)
            if avg > 1, canDouble { doubleDown() } else { stand() }
        case .picking:
            // Only the top card of each pile shows: favour a wild, then a pair with your cards, then the higher card.
            func score(_ pile: [PKCard]) -> Int {
                let top = pile[0]
                if game.isWild(top) { return 100 }
                if hand.contains(where: { $0.rank == top.rank }) { return 50 + top.rank }
                return top.rank
            }
            pick(score(piles[0]) >= score(piles[1]) ? 0 : 1)
        case .holding:
            held = Set(autoHolds())
            draw()
        default:
            break
        }
    }

    /// A simple Deuces Joker Wild hold: keep a made straight or better, else the wilds plus any pairs,
    /// else four to a flush, else just the wilds.
    private func autoHolds() -> [Int] {
        let all = Array(hand.indices)
        if game.evaluate(hand) >= .straight { return all }
        let wild = all.filter { game.isWild(hand[$0]) }
        let nat = all.filter { !game.isWild(hand[$0]) }
        let counts = Dictionary(grouping: nat, by: { hand[$0].rank })
        let paired = counts.values.filter { $0.count >= 2 }.flatMap { $0 }
        if !paired.isEmpty { return wild + paired }
        let bySuit = Dictionary(grouping: nat, by: { hand[$0].suit })
        if let flush = bySuit.values.first(where: { $0.count + wild.count >= 4 }) { return wild + flush }
        return wild
    }
}

// MARK: - Views

struct PKCardView: View {
    let card: PKCard?
    var faceUp = true
    var held = false
    var wild = false
    var host = PokerHost.animals
    var width: CGFloat = 64

    private var height: CGFloat { width * 1.42 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.1)
                .fill(faceUp && card != nil ? Color.white : Color.clear)
            if let card, faceUp {
                face(card)
            } else if card != nil {
                RoundedRectangle(cornerRadius: width * 0.1)
                    .fill(LinearGradient(colors: [host.backTop, host.backBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay {
                        RoundedRectangle(cornerRadius: width * 0.07)
                            .strokeBorder(host.accent.opacity(0.8), lineWidth: 1.5)
                            .padding(width * 0.07)
                    }
                    .overlay { Text(host.backMark).font(.system(size: width * 0.4)) }
            } else {
                RoundedRectangle(cornerRadius: width * 0.1)
                    .strokeBorder(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .frame(width: width, height: height)
        .overlay {
            if wild && faceUp && card != nil {
                RoundedRectangle(cornerRadius: width * 0.1).strokeBorder(Color.yellow, lineWidth: 3)
            }
        }
        .overlay(alignment: .bottom) {
            if wild && faceUp, let card, card.rank == 2 {
                Text("WILD")
                    .font(.system(size: width * 0.2, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .background(Color.yellow, in: Capsule())
                    .padding(.bottom, width * 0.08)
            }
        }
        .overlay(alignment: .top) {
            if held {
                Text("HELD")
                    .font(.system(size: width * 0.2, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .background(Color.yellow, in: Capsule())
                    .offset(y: -width * 0.16)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
    }

    @ViewBuilder private func face(_ card: PKCard) -> some View {
        let color: Color = card.isJoker ? .purple : (card.suit.isRed ? .red : .black)
        if card.isJoker {
            VStack(spacing: 2) {
                Text("★").font(.system(size: width * 0.42))
                Text("JOKER").font(.system(size: width * 0.17, weight: .black, design: .rounded))
            }
            .foregroundStyle(color)
        } else {
            ZStack {
                VStack {
                    HStack {
                        VStack(spacing: -2) {
                            Text(card.rankText).font(.system(size: width * 0.28, weight: .bold, design: .rounded))
                            Text(card.suit.symbol).font(.system(size: width * 0.2))
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(width * 0.06)
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.5))
                    .offset(y: width * 0.12)
            }
            .foregroundStyle(color)
        }
    }
}

/// The host on the machine's screen: a lion for the Animals of Poker, a clown for the Clowns of Poker.
struct PokerHostFace: View {
    let host: PokerHost
    var talking = false

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let t = Date.now.timeIntervalSinceReferenceDate
            let open = talking ? (0.5 + 0.5 * sin(t * 18)) : 0
            func oval(_ x: Double, _ y: Double, _ rw: Double, _ rh: Double) -> Path {
                Path(ellipseIn: CGRect(x: w * (x - rw / 2), y: h * (y - rh / 2), width: w * rw, height: h * rh))
            }
            switch host {
            case .animals:
                let mane = Color(red: 0.75, green: 0.38, blue: 0.10), fur = Color(red: 0.95, green: 0.72, blue: 0.35)
                for k in 0..<14 {
                    let a = Double(k) / 14 * 2 * .pi
                    ctx.fill(oval(0.5 + cos(a) * 0.3, 0.52 + sin(a) * 0.3, 0.3, 0.3), with: .color(mane))
                }
                ctx.fill(oval(0.5, 0.52, 0.66, 0.66), with: .color(mane))
                for x in [0.3, 0.7] {
                    ctx.fill(oval(x, 0.26, 0.16, 0.16), with: .color(fur))
                    ctx.fill(oval(x, 0.26, 0.08, 0.08), with: .color(Color(red: 0.8, green: 0.5, blue: 0.4)))
                }
                ctx.fill(oval(0.5, 0.54, 0.5, 0.52), with: .color(fur))
                ctx.fill(oval(0.5, 0.68, 0.3, 0.2), with: .color(Color(red: 1, green: 0.9, blue: 0.75)))
                for x in [0.4, 0.6] {
                    ctx.fill(oval(x, 0.47, 0.09, 0.1), with: .color(Color(red: 0.95, green: 0.8, blue: 0.2)))
                    ctx.fill(oval(x, 0.47, 0.025, 0.08), with: .color(.black))
                }
                var nose = Path()
                nose.move(to: CGPoint(x: w * 0.44, y: h * 0.58))
                nose.addLine(to: CGPoint(x: w * 0.56, y: h * 0.58))
                nose.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))
                nose.closeSubpath()
                ctx.fill(nose, with: .color(Color(red: 0.35, green: 0.18, blue: 0.12)))
                ctx.fill(oval(0.5, 0.72, 0.14, 0.02 + 0.08 * open), with: .color(Color(red: 0.45, green: 0.1, blue: 0.1)))
            case .clowns:
                let hair = [Color.red, .orange, .yellow, .green, .blue, .purple]
                for (k, c) in hair.enumerated() {
                    let x = 0.14 + Double(k % 3) * 0.06, y = 0.3 + Double(k / 3) * 0.14
                    ctx.fill(oval(x, y, 0.2, 0.2), with: .color(c))
                    ctx.fill(oval(1 - x, y, 0.2, 0.2), with: .color(c))
                }
                ctx.fill(oval(0.5, 0.52, 0.56, 0.62), with: .color(.white))
                for x in [0.39, 0.61] {
                    ctx.fill(oval(x, 0.44, 0.1, 0.14), with: .color(Color(red: 0.3, green: 0.5, blue: 1)))
                    ctx.fill(oval(x, 0.45, 0.04, 0.06), with: .color(.black))
                }
                ctx.fill(oval(0.5, 0.57, 0.14, 0.14), with: .color(.red))
                var smile = Path()
                smile.move(to: CGPoint(x: w * 0.3, y: h * 0.66))
                smile.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.66), control: CGPoint(x: w * 0.5, y: h * (0.84 + 0.06 * open)))
                smile.addQuadCurve(to: CGPoint(x: w * 0.3, y: h * 0.66), control: CGPoint(x: w * 0.5, y: h * 0.76))
                ctx.fill(smile, with: .color(.red))
                var hat = Path()
                hat.move(to: CGPoint(x: w * 0.38, y: h * 0.24))
                hat.addLine(to: CGPoint(x: w * 0.5, y: h * 0.02))
                hat.addLine(to: CGPoint(x: w * 0.62, y: h * 0.24))
                hat.closeSubpath()
                ctx.fill(hat, with: .color(Color(red: 1, green: 0.4, blue: 0.75)))
                ctx.fill(oval(0.5, 0.03, 0.07, 0.07), with: .color(.yellow))
            }
        }
    }
}

/// The machine's screen: the host up top, the paytable, the cards and the buttons.
struct PokerMachineView: View {
    @Bindable var session: PokerSession

    var body: some View {
        GeometryReader { geo in
            let cardW = min(92, (geo.size.width - 48) / 5.6)
            ScrollView {
                VStack(spacing: 10) {
                    hostScreen
                    header
                    paytable
                    cards(cardW)
                    Text(session.resultText)
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(session.won > 0 ? Color.yellow : .white.opacity(0.7))
                        .frame(minHeight: 28)
                    meters
                    controls
                }
                .padding(14)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .background(LinearGradient(colors: [session.host.screenTop, session.host.screenBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .overlay {
            if session.phase == .over, session.ending != .qualified { tryAgainOverlay }
        }
    }

    private var hostScreen: some View {
        HStack(alignment: .center, spacing: 12) {
            TimelineView(.periodic(from: .now, by: 0.08)) { _ in
                PokerHostFace(host: session.host, talking: session.talking)
            }
            .frame(width: 96, height: 96)
            .background(Circle().fill(session.host.accent.opacity(0.25)))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(session.host.accent, lineWidth: 3))
            VStack(alignment: .leading, spacing: 4) {
                Text(session.host.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(session.host.accent)
                Text(session.line.isEmpty ? "…" : session.line)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var header: some View {
        HStack {
            Text("GAME \(session.game.number) OF 10")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(session.host.accent)
            Text(session.game.title.uppercased())
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer()
            Text("\(session.player) · Hand \(min(session.handsPlayed + ([.doubling, .picking, .holding].contains(session.phase) ? 1 : 0), PokerSession.handsPerGame)) / \(PokerSession.handsPerGame)")
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var paytable: some View {
        let shownBet = max(1, session.phase == .result ? session.totalBet : session.bet)
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 2) {
            ForEach(session.game.paytable) { row in
                let hit = session.phase == .result && session.result == row.hand && session.won > 0
                HStack {
                    Text(row.name).lineLimit(1).minimumScaleFactor(0.7)
                    Spacer()
                    Text("\(row.payout(bet: shownBet))").monospacedDigit()
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(hit ? .black : .yellow)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(hit ? Color.yellow : Color.clear, in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(8)
        .background(Color(red: 0.05, green: 0.05, blue: 0.4), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .bottomTrailing) {
            let tip: String? = switch session.game.style {
            case .doubleDown: "Double down before the 5th card"
            case .draw: "Tap cards to hold, then draw"
            case .pickEm: nil
            }
            if let tip {
                Text(tip)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(session.host.accent, in: Capsule())
                    .offset(y: 10)
            }
        }
    }

    @ViewBuilder private func cards(_ w: CGFloat) -> some View {
        if session.game.style == .pickEm {
            pickEmCards(w)
        } else {
            HStack(spacing: w * 0.12) {
                ForEach(0..<5, id: \.self) { i in
                    let card = session.hand[pk: i]
                    let up = card != nil && !(i == 4 && session.phase == .doubling)
                    Button {
                        session.toggleHold(i)
                    } label: {
                        PKCardView(card: card ?? PKCard(rank: 14, suit: .spades), faceUp: up,
                                   held: session.phase == .holding && session.held.contains(i),
                                   wild: up && (card.map(session.game.isWild) ?? false), host: session.host, width: w)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
            .frame(minHeight: w * 1.42 + 18)
        }
    }

    private func pickEmCards(_ w: CGFloat) -> some View {
        let small = w * 0.9
        return HStack(alignment: .top, spacing: small * 0.3) {
            VStack(spacing: 4) {
                Text("YOUR CARDS").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 4) {
                    ForEach(0..<2, id: \.self) { i in
                        let card = session.hand[pk: i]
                        PKCardView(card: card ?? .joker, faceUp: card != nil, wild: card.map(session.game.isWild) ?? false,
                                   host: session.host, width: small)
                    }
                }
            }
            // Once a pile is picked, only that pile stays on screen.
            ForEach((0..<2).filter { session.pickedPile == nil || session.pickedPile == $0 }, id: \.self) { p in
                let pile = session.piles[pk: p] ?? []
                let revealed = session.phase == .result || session.phase == .over
                let chosen = session.pickedPile == p
                Button {
                    session.pick(p)
                } label: {
                    VStack(spacing: 4) {
                        Text(session.phase == .picking ? "PICK \(p == 0 ? "A" : "B")" : (chosen ? "PICKED" : "PILE \(p == 0 ? "A" : "B")"))
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(chosen ? .yellow : .white.opacity(0.7))
                        if pile.isEmpty {
                            PKCardView(card: nil, host: session.host, width: small)
                        } else if revealed {
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { k in
                                    PKCardView(card: pile[k], wild: session.game.isWild(pile[k]), host: session.host, width: small)
                                }
                            }
                        } else {
                            ZStack(alignment: .top) {
                                ForEach((0..<3).reversed(), id: \.self) { k in
                                    PKCardView(card: pile[k], faceUp: k == 0, wild: k == 0 && session.game.isWild(pile[k]),
                                               host: session.host, width: small)
                                        .offset(y: Double(2 - k) * small * 0.16)
                                }
                            }
                            .padding(.bottom, small * 0.32)
                        }
                    }
                    .padding(4)
                    .background(chosen ? Color.yellow.opacity(0.2) : (session.phase == .picking ? Color.white.opacity(0.08) : .clear),
                                in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var meters: some View {
        HStack {
            meter("CREDITS", "\(session.credits)")
            meter("BET", "\(session.bet)")
            meter("WIN", "\(session.won)")
            VStack(spacing: 2) {
                Image(systemName: session.maxBetThroughout ? "crown.fill" : "xmark.circle.fill")
                    .foregroundStyle(session.maxBetThroughout ? .yellow : .gray)
                Text(session.maxBetThroughout ? "Max bet streak" : "Game 10 lost")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func meter(_ title: String, _ value: String) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(.red)
            Text(value).font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(.yellow)
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                switch session.phase {
                case .doubling:
                    machineButton("DOUBLE DOWN", .red, enabled: session.canDouble && !session.autoPlay) { session.doubleDown() }
                    machineButton("5TH CARD", .green, enabled: !session.autoPlay) { session.stand() }
                case .picking:
                    machineButton("BET ONE", .blue, enabled: false) {}
                    machineButton("BET MAX", .red, enabled: false) {}
                    machineButton("PICK A PILE", .green, enabled: false) {}
                case .holding:
                    machineButton("TAP CARDS TO HOLD", .blue, enabled: false) {}
                    machineButton("DRAW", .green, enabled: !session.autoPlay) { session.draw() }
                default:
                    let free = session.betweenHands && session.ending == nil && !session.autoPlay
                    machineButton("BET ONE", .blue, enabled: free) { session.betOne() }
                    machineButton("BET MAX", .red, enabled: free && session.credits > 0) { session.betMax() }
                    machineButton("DEAL", .green, enabled: session.canDeal && !session.autoPlay) { session.deal() }
                }
            }
            Toggle(isOn: $session.autoPlay) {
                Label("Auto Play (max bet)", systemImage: "play.circle.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }
            .tint(session.host.accent)
            .frame(maxWidth: 320)
            .disabled(session.ending != nil)
        }
    }

    private func machineButton(_ title: String, _ color: Color, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 10))
                .opacity(enabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var tryAgainOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 16) {
                TimelineView(.periodic(from: .now, by: 0.08)) { _ in
                    PokerHostFace(host: session.host, talking: session.talking)
                }
                .frame(width: 160, height: 160)
                .background(Circle().fill(session.host.accent.opacity(0.3)))
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(session.host.accent, lineWidth: 4))
                Text(session.line)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("\(session.player) needs to reach game 10.")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.yellow)
                Button("Insert Credits") { session.restart() }
                    .buttonStyle(.borderedProminent)
                    .tint(session.host.accent)
                    .font(.system(.headline, design: .rounded))
            }
            .padding(24)
            .frame(maxWidth: 520)
        }
    }
}

extension Array {
    fileprivate subscript(pk i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
