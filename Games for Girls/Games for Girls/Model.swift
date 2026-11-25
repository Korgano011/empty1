import SwiftUI
import Observation

enum GameKind: String, CaseIterable, Codable, Identifiable {
    case backgammon, aceyDeucey, othello, callIt, obsession, starTrek, connect4, alleyCat, rummy500, ninetyNine, crazyEights, imOut
    var id: String { rawValue }

    var title: String {
        switch self {
        case .backgammon: "Backgammon"
        case .aceyDeucey: "Acey Deucey"
        case .othello: "Othello"
        case .callIt: "Call It"
        case .obsession: "Obsession"
        case .starTrek: "Star Trek Game"
        case .connect4: "Connect 4"
        case .alleyCat: "Alley Cat"
        case .rummy500: "500 Rummy"
        case .ninetyNine: "99"
        case .crazyEights: "Crazy Eights"
        case .imOut: "I'm Out"
        }
    }

    var blurb: String {
        switch self {
        case .backgammon: "Race all 15 checkers home and bear them off. Pink or green."
        case .aceyDeucey: "Backgammon where everyone starts off the board – roll 1-2 for a bonus!"
        case .othello: "Outflank and flip your opponent's discs."
        case .callIt: "Call your shot, roll the red & black dice. 2–5 players."
        case .obsession: "Slide your 10 rings up – or push theirs back down."
        case .starTrek: "Captain Janeway, Lt. Dax and Dr. Crusher race to complete missions."
        case .connect4: "Drop pink or green chips – four in a row wins."
        case .alleyCat: "Clubs, spades and the 🐱 5♦ Alley Cat. Win tricks by the difference – first to 44."
        case .rummy500: "Meld sets and runs, dig into the discard pile – first to 500. 2–4 players."
        case .ninetyNine: "3 players. Lay aside 3 cards as your secret bid, then take exactly that many tricks. First to 100."
        case .crazyEights: "Match suit or number – eights are wild! First to empty her hand wins. 2–5 players."
        case .imOut: "Suits don't count! Build the row up or down from its ends – can't play? Say \"I'm Out!\" First to play her last card wins. Pick 3–6 players."
        }
    }

    var icon: String {
        switch self {
        case .backgammon: "circle.grid.cross"
        case .aceyDeucey: "die.face.2"
        case .othello: "circle.lefthalf.filled"
        case .callIt: "die.face.5"
        case .obsession: "circle.circle"
        case .starTrek: "sparkles"
        case .connect4: "circle.grid.3x3.fill"
        case .alleyCat: "suit.club.fill"
        case .rummy500: "suit.spade.fill"
        case .ninetyNine: "suit.heart.fill"
        case .crazyEights: "suit.diamond.fill"
        case .imOut: "hand.raised.fill"
        }
    }

    var maxPlayers: Int {
        switch self {
        case .imOut: 6
        case .callIt, .crazyEights: 5
        case .rummy500: 4
        case .ninetyNine: 3
        default: 2
        }
    }
}

struct Seat: Identifiable {
    let id = UUID()
    var name: String
    var look: Look
    var human: Bool
}

struct GameOutcome {
    var winner: String
    var humanWon: Bool
}

enum Phase: Equatable { case title, cutscene, pickGame, invite, playing, results, shopping, chooseStyles }

struct SaveData: Codable {
    var day: Int
    var cash: Int
    var transformed: Int
    var cruises: Int
    var wins: Int
    var me: Int
    var firstDayDone: Bool
    var onShip: Bool? = nil
    var enhancements: [String]? = nil
    var pendingGifts: [String]? = nil
    var excursionDay: Int? = nil
    var ownedStyles: [String]? = nil
    var styleChoice: [String: String]? = nil
    var girlSavings: [Int]? = nil
    var spentToday: Int? = nil
    var girlBank: [Int]? = nil
    var bankTripDue: Bool? = nil
}

@Observable
final class AppModel {
    var phase: Phase = .title
    var day = 1
    var cash = 0
    var earnedToday = 0
    var transformed = 3
    var cruises = 0
    var wins = 0
    /// which girl the user plays as (0 Ellie, 1 Christina, 2 Deirdre)
    var me = 0
    var firstDayDone = false
    /// The girls spent last night aboard the ship (wake up in their cabins).
    var onShip = false

    /// Ship upgrades bought on shore excursions (and cleared through customs).
    var enhancements: Set<String> = []
    /// Gifts for Mom, waiting for the next night at home.
    var pendingGifts: [String] = []
    /// The day of the last shore excursion (one per day).
    var excursionDay = 0
    var port: Port?
    /// Game styles bought (checkers, chips, cards) and which one each game uses.
    var ownedStyleNames: Set<String> = []
    var styleChoice: [String: String] = [:]
    /// Game styles that just came home from an excursion – the girls pick which ones to use.
    var newStyles: [String] = []
    /// Each girl's own savings from her fair share of the profits.
    var girlSavings = [0, 0, 0]
    /// What each girl has deposited in her own account at Boardwalk Bank.
    var girlBank = [0, 0, 0]
    /// After every cruise night, Mom takes the girls to the bank the next morning.
    var bankTripDue = false
    /// Money spent shopping today (comes off today's profit).
    var spentToday = 0
    var cart: [ShopItem] = []

    private var upgrades: [ShopItem] { Shop.allShipItems.filter { enhancements.contains($0.name) } }
    var acceptBonus: Double { upgrades.reduce(0) { $0 + $1.accept } }
    var tipPerPassenger: Int { upgrades.reduce(0) { $0 + $1.tip } }
    var winBonus: Int { 25 + upgrades.reduce(0) { $0 + $1.winBonus } }
    var canExcursion: Bool { firstDayDone && excursionDay != day }

    var game: GameKind?
    var passengers: [Passenger] = []
    var fee = 20
    var lastOutcome: GameOutcome?
    var lastCruiseEarned = 0

    var shots: [Shot] = []
    var sceneContext = SceneContext()
    var cutsceneID = 0
    private var afterCutscene: (() -> Void)?

    static let saveKey = "gamesForGirlsSave"

    var hasSave: Bool { UserDefaults.standard.data(forKey: Self.saveKey) != nil }

    // MARK: flow

    func newGame() {
        day = 1; cash = 0; earnedToday = 0; transformed = 3; cruises = 0; wins = 0; firstDayDone = false; onShip = false
        enhancements = []; pendingGifts = []; excursionDay = 0
        ownedStyleNames = []; styleChoice = [:]; girlSavings = [0, 0, 0]; spentToday = 0
        girlBank = [0, 0, 0]; bankTripDue = false
        applyLooks()
        passengers = []
        play(Story.prologue()) { self.phase = .pickGame }
    }

    func continueGame() {
        guard load() else { newGame(); return }
        earnedToday = 0
        if firstDayDone { startDay() } else { newGame() }
    }

    func startDay() {
        passengers = []
        var shots = onShip ? Story.shipMorning(day: day) : Story.morning(day: day, game: "")
        if bankTripDue {
            bankTripDue = false
            if let deposits = makeDeposits() {
                shots += Story.bankTrip(fromShip: onShip, deposits: deposits, pocket: girlSavings, bank: girlBank)
            }
            save()
        }
        play(shots) { self.phase = .pickGame }
    }

    /// Each girl deposits half of her savings (rounded up) and keeps the rest as spending money.
    /// Returns nil when nobody has anything to deposit.
    private func makeDeposits() -> [Int]? {
        let deposits = girlSavings.map { ($0 + 1) / 2 }
        guard deposits.contains(where: { $0 > 0 }) else { return nil }
        for i in 0..<3 {
            girlSavings[i] -= deposits[i]
            girlBank[i] += deposits[i]
        }
        return deposits
    }

    func choose(_ kind: GameKind) {
        game = kind
        if firstDayDone {
            passengers = []
            phase = .invite
        } else {
            phase = .playing
        }
    }

    func setSail() {
        guard let game, !passengers.isEmpty else { return }
        let fees = passengers.count * (fee + tipPerPassenger)
        cash += fees
        earnedToday += fees
        lastCruiseEarned = fees
        sceneContext.passengers = passengers
        Sound.shared.play(.coin)
        play(Story.boarding(passengers, game: game.title)) {
            for i in self.passengers.indices { self.passengers[i].changed = true }
            self.transformed += self.passengers.count
            self.sceneContext.passengers = self.passengers
            self.phase = .playing
            self.save()
        }
    }

    func seats() -> [Seat] {
        guard let game else { return [] }
        let girls = (0..<3).map { Seat(name: girlNames[$0], look: Cast.kids[$0], human: $0 == me) }
        var list = [girls[me]]
        if firstDayDone {
            list += passengers.map { Seat(name: $0.girlName, look: $0.look, human: false) }
        }
        list += girls.enumerated().filter { $0.offset != me }.map(\.element)
        return Array(list.prefix(game.maxPlayers))
    }

    func finish(_ o: GameOutcome) {
        lastOutcome = o
        if firstDayDone {
            cruises += 1
            if o.humanWon {
                wins += 1
                cash += winBonus; earnedToday += winBonus; lastCruiseEarned += winBonus
            }
        } else if o.humanWon {
            wins += 1
        }
        Sound.shared.play(o.humanWon ? .win : .lose)
        phase = .results
        save()
    }

    func afterResults() {
        if !firstDayDone {
            firstDayDone = true
            play(Story.afterFirstGame()) {
                self.day = 2
                self.earnedToday = 0
                self.onShip = false
                self.save()
                self.startDay()
            }
        } else {
            passengers = []
            phase = .pickGame
        }
    }

    func endDay(onShip ship: Bool = false) {
        let earned = earnedToday
        let (profit, share) = payShares()
        let shots = ship ? Story.nightOnShip(earned: earned, cash: cash, profit: profit, share: share, savings: girlSavings)
                         : Story.endOfDay(day: day, earned: earned, cash: cash, gifts: pendingGifts, profit: profit, share: share, savings: girlSavings)
        if !ship { pendingGifts = [] }
        play(shots) {
            self.day += 1
            self.earnedToday = 0
            self.spentToday = 0
            self.onShip = ship
            self.bankTripDue = true
            self.save()
            self.startDay()
        }
    }

    // MARK: shore excursions

    func startExcursion(_ p: Port) {
        port = p
        cart = []
        excursionDay = day
        passengers = []
        save()
        play(Story.excursionOut(p)) { self.phase = .shopping }
    }

    func buy(_ item: ShopItem) {
        guard cash >= item.price, !cart.contains(item) else { return }
        cash -= item.price
        spentToday += item.price
        cart.append(item)
        Sound.shared.play(.coin)
    }

    func returnItem(_ item: ShopItem) {
        guard let i = cart.firstIndex(of: item) else { return }
        cart.remove(at: i)
        cash += item.price
        spentToday -= item.price
        Sound.shared.play(.click)
    }

    func leavePort() {
        guard let port else { return }
        let bag = cart
        for item in bag where item.seized == nil {
            switch item.kind {
            case .ship: enhancements.insert(item.name)
            case .gift: pendingGifts.append(item.name)
            case .game:
                ownedStyleNames.insert(item.name)
            }
        }
        newStyles = bag.filter { $0.seized == nil && $0.isStyle }.map(\.name)
        cart = []
        applyLooks()
        save()
        play(Story.excursionBack(port, cart: bag)) {
            // New chips or cards made it through customs: choose which ones to play with.
            self.phase = self.newStyles.isEmpty ? .pickGame : .chooseStyles
        }
    }

    // MARK: game styles

    func owns(_ item: ShopItem) -> Bool {
        switch item.kind {
        case .ship: enhancements.contains(item.name)
        case .game: ownedStyleNames.contains(item.name)
        case .gift: false
        }
    }

    func ownedStyles(_ slot: StyleSlot) -> [String] {
        let classic = slot == .cards ? CardStyle.classic.name : PieceStyle.classic.name
        let owned = Port.allCases.flatMap { Shop.items($0) }.filter { $0.kind == .game(slot) && ownedStyleNames.contains($0.name) }.map(\.name)
        return [classic] + (slot == .cards ? [] : PieceStyle.gems) + owned
    }

    /// The slots (backgammon, Connect 4, cards) that got something new on this excursion.
    var newStyleSlots: [StyleSlot] {
        StyleSlot.allCases.filter { slot in newStyles.contains { Shop.item(named: $0)?.kind == .game(slot) } }
    }

    func finishChoosingStyles() {
        newStyles = []
        phase = .pickGame
    }

    func selectedStyle(_ slot: StyleSlot) -> String {
        styleChoice[slot.rawValue] ?? (slot == .cards ? CardStyle.classic.name : PieceStyle.classic.name)
    }

    func selectStyle(_ slot: StyleSlot, _ name: String) {
        styleChoice[slot.rawValue] = name
        applyLooks()
        Sound.shared.play(.chip)
        save()
    }

    /// Push the saved choices to the globals the drawing code reads (ship upgrades, game styles).
    func applyLooks() {
        shipExtras = enhancements
        gameLook = GameLook(backgammon: .named(selectedStyle(.backgammon)),
                            connect4: .named(selectedStyle(.connect4)),
                            cards: .named(selectedStyle(.cards)))
    }

    // MARK: profit sharing

    /// Today's profit is split four ways – the ship's business and each of the three girls get an
    /// equal share. The girls' shares go into their own savings; the rest stays in the bank.
    private func payShares() -> (profit: Int, share: Int) {
        let profit = earnedToday - spentToday
        guard profit > 0 else { return (profit, 0) }
        let share = profit / 4
        for i in 0..<3 { girlSavings[i] += share }
        cash -= share * 3
        return (profit, share)
    }

    func quitToTitle() {
        Sound.shared.stopSpeaking()
        save()
        phase = .title
    }

    func play(_ s: [Shot], then: @escaping () -> Void) {
        shots = s
        afterCutscene = then
        cutsceneID += 1
        phase = .cutscene
    }

    func cutsceneDone() {
        let f = afterCutscene
        afterCutscene = nil
        f?()
    }

    // MARK: save

    func save() {
        let d = SaveData(day: day, cash: cash, transformed: transformed, cruises: cruises, wins: wins, me: me, firstDayDone: firstDayDone, onShip: onShip,
                         enhancements: Array(enhancements), pendingGifts: pendingGifts, excursionDay: excursionDay,
                         ownedStyles: Array(ownedStyleNames), styleChoice: styleChoice, girlSavings: girlSavings, spentToday: spentToday,
                         girlBank: girlBank, bankTripDue: bankTripDue)
        if let data = try? JSONEncoder().encode(d) { UserDefaults.standard.set(data, forKey: Self.saveKey) }
    }

    @discardableResult
    func load() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let d = try? JSONDecoder().decode(SaveData.self, from: data) else { return false }
        day = d.day; cash = d.cash; transformed = d.transformed; cruises = d.cruises; wins = d.wins; me = d.me; firstDayDone = d.firstDayDone; onShip = d.onShip ?? false
        enhancements = Set(d.enhancements ?? []); pendingGifts = d.pendingGifts ?? []; excursionDay = d.excursionDay ?? 0
        ownedStyleNames = Set(d.ownedStyles ?? []); styleChoice = d.styleChoice ?? [:]; girlSavings = d.girlSavings ?? [0, 0, 0]; spentToday = d.spentToday ?? 0
        girlBank = d.girlBank ?? [0, 0, 0]; bankTripDue = d.bankTripDue ?? false
        applyLooks()
        return true
    }
}
