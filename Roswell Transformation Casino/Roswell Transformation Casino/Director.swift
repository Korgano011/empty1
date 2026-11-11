import SwiftUI

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var mom: Person
    var ava: Person
    var rosie: Person

    var cast: [Person] { [mom, ava, rosie] }
    var customers: [Person] = []
    var everyone: [Person] { cast + [aunt, cousin].compactMap { $0 } + customers }
    /// Mom's sister and her little girl, visiting after every second night.
    var aunt: Person?
    var cousin: Person?

    var caption = "Tap Start to begin."
    var running = false
    var finished = false
    var muted = false { didSet { sound.muted = muted; poker?.voice.muted = muted; machineVoice.muted = muted } }
    /// The Roswell of Poker's own voice, heard even when nobody is playing it.
    @ObservationIgnored private let machineVoice = PokerVoice()

    /// Someone is playing the Roswell of Poker; its screen fills the window.
    var poker: PokerSession?
    /// The family has turned the backyard cottage into their own casino.
    var casinoBuilt = false
    /// A kid's bedroom across town (which one), while the game is downloaded to their computer.
    var kidRoom: Int?
    /// A column of light someone is beamed up or down in.
    var teleport: (x: Double, color: Color, t0: Date)?
    var boothClosed = false
    var signUntil = Date.distantPast
    var doorOpenUntil = Date.distantPast
    var boxes: [Double] = []
    var screen = "READY"
    var flashT0 = Date.distantPast
    var camFrom = Stage.full
    var camTo = Stage.full
    var camT0 = Date.distantPast
    var fadeT0 = Date.distantPast

    // The booth's current run
    /// Everyone under a beam right now, up to three.
    var beamPeople: [Person] = []
    var boothT0 = Date.distantPast
    /// How long this run's saucers take to fly out and back.
    var saucerFlight = BoothRun.lower
    var pressT0 = Date.distantPast

    // The casino
    var atCasino = false
    var choosingGame = false
    var gamesPlayed = 0
    var cash = CasinoGame.startCash
    /// Days at the casino so far, counting today: each has a day session and a night session.
    var nights = 0
    /// The session running now is the afternoon one, not the night one.
    var daytime = false
    /// What Mom has put in the bank on her morning errands.
    var bank = 0
    /// Everything the cousins have been paid: a quarter of the profit on each night they tag along.
    var cousinsPaid = 0
    /// Main Street, where Mom shops, buys groceries and goes to the bank.
    var inTown = false
    /// Across town after the family ends the night: tonight's guests reach their own front doors.
    var inNeighborhood = false
    /// Recruiting out front for a just-for-fun game: the house on the right of the street is the family's own.
    var outsideHome = false
    /// Night-time at home: the house goes dark and everyone sleeps.
    var lightsOut = false
    /// Groceries Mom bought between games this session.
    private var sessionGroceries = 0
    /// What the house made on the visit's first day, waiting to be split with the cousin after the second.
    @ObservationIgnored private var visitProfit = 0
    /// The aunt and cousin are sleeping over tonight, still aliens.
    var sleepover = false
    /// The aunt while she's off shopping on her own; she comes back to the house after the first trip.
    @ObservationIgnored private var awayAunt: Person?
    /// Who runs the casino table: Mom, or Ava while Mom is out shopping with the aunt.
    @ObservationIgnored private var hostOverride: Person?
    private var tableHost: Person { hostOverride ?? mom }
    /// The girls who help the host: both of them for Mom, just Rosie when Ava runs the table.
    private var helpers: [Person] { hostOverride == nil ? [ava, rosie] : cast.filter { $0 !== mom && $0 !== hostOverride } }
    /// Who deals, shown on the game picker.
    var hostName = "Mom"
    /// The game the girls ran on this visit morning, and what the house made on it.
    @ObservationIgnored private var girlsGame: (name: String, net: Int)?
    /// Tonight's guests, one household (a woman and any girls who came with her) per entry; they stay aliens until home.
    @ObservationIgnored private var nightHouseholds: [[Person]] = []
    /// Waiting for you to decide whether the family goes back for another night.
    var choosingNext = false
    /// Floating "+$" / "-$" over where the money changed hands.
    var cashPop: (text: String, t0: Date, x: Double)?
    var result: GameRecord?
    /// Cards lying on the table right now.
    var felt: [FeltCards] = []
    /// The scoreboard while a game is on; the table view seats one person per row.
    var board: TableBoard?
    /// Who sits in each scoreboard row.
    var tableSeats: [Person] = []
    /// The cards on the table, by game seat.
    var tableGroups: [FeltGroup] = []
    /// Your scoreboard row, if you're playing.
    var humanRow: Int?

    // You play the daughter who joins each table.
    /// Who you are at this table, if you're playing.
    var you: String?
    /// Your cards, shown under the stage.
    var myHand: [Card] = []
    /// What the table is waiting for you to decide.
    var prompt: PlayerPrompt?
    /// Let the computer make your plays.
    var autoPlay = false

    /// What the family has bought at Cosmic Customs and is using.
    var custom = Customization()
    /// Around the corner from the bank: the Cosmic Customs storefront.
    var inCustoms = false
    /// Mom is inside Cosmic Customs and the shop screen is open.
    var shopping = false
    @ObservationIgnored private var shopDone: CheckedContinuation<Void, Never>?

    /// The last saved night, if there is one: "Continue" picks the game up from there.
    var saved: SaveGame? = SaveGame.load()

    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var gamePick: CheckedContinuation<(game: CasinoGame, daughterHouse: Bool)?, Never>?
    @ObservationIgnored private var nextPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var auntVisits = 0
    @ObservationIgnored private var womenNames: [String] = []
    @ObservationIgnored private var kidNames: [String] = []
    @ObservationIgnored private var answerWait: CheckedContinuation<PlayerAnswer, Never>?
    /// What the computer would have played, used if you switch on auto-play or start over mid-question.
    @ObservationIgnored private var answerAuto: PlayerAnswer?
    @ObservationIgnored private var pokerDone: CheckedContinuation<Void, Never>?
    /// Credits left on the machine when the last player reached game 10.
    @ObservationIgnored private var leftoverCredits = 0

    init() {
        (mom, ava, rosie) = Self.makeFamily()
    }

    // MARK: Cosmic Customs

    /// What the shop can spend: the bank account, plus any cash above what Mom keeps on hand for the tables.
    var spendable: Int { max(0, bank) + max(0, cash - CasinoGame.startCash) }

    /// Tapping an item in the shop: puts on (or takes off) something already bought, or buys it and puts it on.
    /// Returns a line for the shop to show.
    func shopTap(_ item: ShopThing, for who: String?) -> String? {
        if custom.owns(item, for: who) {
            let wasOn = custom.isOn(item, for: who)
            custom.toggle(item, for: who)
            applyCustom()
            let now = custom.isOn(item, for: who)
            if wasOn == now { return "\(item.name) is already in use." }
            return now ? "\(who.map { "\($0) is" } ?? "The casino now has") \(who == nil ? item.name : "using \(item.name)")."
                       : "\(item.name) put away\(who.map { " for \($0)" } ?? "")."
        }
        guard spendable >= item.price else {
            return "Not enough money for \(item.name) — it's $\(item.price) and there's $\(spendable) to spend."
        }
        // The bank pays first, then any spare cash.
        let fromBank = min(max(0, bank), item.price)
        bank -= fromBank
        cash -= item.price - fromBank
        custom.markOwned(item, for: who)
        custom.spent += item.price
        if !custom.isOn(item, for: who) { custom.toggle(item, for: who) }
        applyCustom()
        sound.ching()
        return "Bought \(item.name) for $\(item.price)\(who.map { " — \($0) loves it!" } ?? "!")"
    }

    /// Puts everyone's bought looks on them and sets up the machine.
    func applyCustom() {
        for p in cast { p.look = custom.looks[p.id] ?? Look() }
        PokerHost.skin = custom.skin
        PokerHost.voiceStyle = custom.voice
    }

    /// The shop screen was closed: Mom walks out of the store, or (between days) the purchases are saved with the night.
    func closeShop() {
        if shopping {
            shopping = false
            shopDone?.resume()
            shopDone = nil
        } else if choosingNext && nights > 0 {
            saveProgress()
        }
    }

    private static func makeFamily() -> (Person, Person, Person) {
        let mom = Person("Mom", height: 152, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.40, g: 0.24, b: 0.12), style: .long,
                         shirt: RGB(r: 0.20, g: 0.60, b: 0.65), pants: RGB(r: 0.25, g: 0.30, b: 0.50), x: Stage.doorX)
        let ava = Person("Ava", height: 132, headScale: 0.13, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.92, g: 0.78, b: 0.42),
                         style: .ponytail, shirt: RGB(r: 0.95, g: 0.45, b: 0.40), pants: RGB(r: 0.30, g: 0.30, b: 0.45), kid: true, x: Stage.doorX)
        let rosie = Person("Rosie", height: 98, headScale: 0.16, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.55, g: 0.35, b: 0.18),
                           style: .pigtails, shirt: RGB(r: 0.98, g: 0.60, b: 0.75), pants: RGB(r: 0.95, g: 0.80, b: 0.30), kid: true, x: Stage.doorX)
        for p in [mom, ava, rosie] { p.visible = false }
        return (mom, ava, rosie)
    }

    /// The part of the stage on screen; eases from `camFrom` to `camTo` over 0.9s.
    func camera(at now: Date) -> CGRect {
        let t = min(max(now.timeIntervalSince(camT0) / 0.9, 0), 1)
        let e = t * t * (3 - 2 * t)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * e }
        return CGRect(x: mix(camFrom.minX, camTo.minX), y: mix(camFrom.minY, camTo.minY),
                      width: mix(camFrom.width, camTo.width), height: mix(camFrom.height, camTo.height))
    }

    /// What the Roswell of Poker's screen says.
    func screenText(_ now: Date) -> String {
        if let poker { return poker.ending == .qualified ? "GAME 10!" : "GAME \(poker.game.number)" }
        guard !beamPeople.isEmpty else { return screen }
        let (phase, u) = BoothRun.phase(now.timeIntervalSince(boothT0), flight: saucerFlight)
        switch phase {
        case .lowering: return "LAUNCH"
        case .charging: return "CHARGING"
        case .beaming:
            let left = max(0, 60 - Int(u * 60))
            return String(format: "0:%02d", left)
        case .sparkling: return "SPARKLE"
        case .cooling: return "COOLING"
        case .lifting: return "RETURN"
        case .done: return "DONE!"
        }
    }

    /// `resume`: carry on from the last saved night instead of starting a new game.
    func start(resume: Bool = false) {
        task?.cancel()
        gamePick?.resume(returning: nil)
        gamePick = nil
        nextPick?.resume(returning: false)
        nextPick = nil
        releasePrompt()
        poker?.shutDown()
        poker = nil
        pokerDone?.resume()
        pokerDone = nil
        leftoverCredits = 0
        casinoBuilt = false
        kidRoom = nil
        teleport = nil
        you = nil
        myHand = []
        prompt = nil
        humanRow = nil
        tableSeats = []
        tableGroups = []
        sound.prepare()
        sound.stopAll()
        (mom, ava, rosie) = Self.makeFamily()
        finished = false
        running = true
        boothClosed = false
        signUntil = .distantPast
        doorOpenUntil = .distantPast
        boxes = []
        screen = "READY"
        flashT0 = .distantPast
        camFrom = Stage.full
        camTo = Stage.full
        camT0 = .distantPast
        fadeT0 = .distantPast
        beamPeople = []
        boothT0 = .distantPast
        pressT0 = .distantPast
        atCasino = false
        choosingGame = false
        gamesPlayed = 0
        customers = []
        cash = CasinoGame.startCash
        nights = 0
        daytime = false
        bank = 0
        cousinsPaid = 0
        inTown = false
        inNeighborhood = false
        nightHouseholds = []
        choosingNext = false
        aunt = nil
        cousin = nil
        awayAunt = nil
        sleepover = false
        visitProfit = 0
        auntVisits = 0
        cashPop = nil
        result = nil
        felt = []
        board = nil
        womenNames = []
        kidNames = []
        shopDone?.resume()
        shopDone = nil
        shopping = false
        inCustoms = false
        custom = Customization()
        let save = resume ? SaveGame.load() : nil
        if let save { restore(save) }
        applyCustom()
        task = Task {
            do { try await story(resumed: save != nil) } catch {}
        }
    }

    /// The next game Mom runs, or nil to end the night. At a moneymaker table
    /// `daughterHouse` makes the daughter who joins the house, with Mom dealing.
    func choose(_ game: CasinoGame?, daughterHouse: Bool = false) {
        gamePick?.resume(returning: game.map { ($0, daughterHouse) })
        gamePick = nil
        choosingGame = false
    }

    /// After a night at the casino: go back tomorrow night, or call it a wrap.
    func chooseNext(_ again: Bool) {
        nextPick?.resume(returning: again)
        nextPick = nil
        choosingNext = false
    }

    /// Your answer to the current prompt.
    func answer(_ a: PlayerAnswer) {
        guard let wait = answerWait else { return }
        answerWait = nil
        answerAuto = nil
        prompt = nil
        wait.resume(returning: a)
    }

    /// Hands the question back to the computer (auto-play turned on, or the story restarting).
    func releasePrompt() {
        if let auto = answerAuto { answer(auto) }
    }

    /// Waits for you, unless auto-play is on.
    private func ask(_ p: PlayerPrompt, auto: PlayerAnswer) async throws -> PlayerAnswer {
        try Task.checkCancellation()
        if autoPlay { return auto }
        let a = await withCheckedContinuation { cont in
            answerWait = cont
            answerAuto = auto
            prompt = p
        }
        try Task.checkCancellation()
        return a
    }

    /// The bridge a game uses to ask you, lay cards on the felt and update the scoreboard.
    /// `seatX` places each seat's cards; the dealer's or middle cards go in the back row.
    private func host(human: Int?, seatX: [Double]) -> TableHost {
        TableHost(human: human,
                  ask: { [unowned self] p, auto in try await ask(p, auto: auto) },
                  show: { [unowned self] groups in
                      tableGroups = groups
                      felt = groups.map { g in
                          FeltCards(x: g.seat.map { seatX[$0] } ?? Stage.dealerX, back: g.seat == nil, cards: g.cards,
                                    hidden: g.hidden, splitAt: g.splitAt, label: g.label)
                      }
                  },
                  hand: { [unowned self] cards in if human != nil { myHand = cards } },
                  notes: { [unowned self] notes in
                      guard var b = board else { return }
                      // Row 0 is the house at a moneymaker table; fun-game rows line up with the seats.
                      let offset = b.game.isMoney ? 1 : 0
                      for (i, n) in notes.enumerated() where b.rows.indices.contains(i + offset) { b.rows[i + offset].note = n }
                      board = b
                  },
                  caption: { [unowned self] text in caption = text },
                  pause: { [unowned self] seconds in try await sleep(seconds) })
    }

    /// 0…1 black-out used when the scene changes.
    func fade(at now: Date) -> Double {
        let t = now.timeIntervalSince(fadeT0)
        guard t >= 0 && t < 1.2 else { return 0 }
        return t < 0.5 ? t / 0.5 : max(0, 1 - (t - 0.7) / 0.5)
    }

    // MARK: Story

    /// Puts the saved night back: money, counts, and any sleepover guests (still aliens).
    private func restore(_ save: SaveGame) {
        // A saved game is always past the first day, so the cottage casino is already open.
        casinoBuilt = true
        nights = save.nights
        cash = save.cash
        bank = save.bank
        cousinsPaid = save.cousinsPaid
        auntVisits = save.auntVisits
        visitProfit = save.visitProfit
        custom = save.custom ?? Customization()
        if let ac = save.auntColor.flatMap(AlienColor.init(rawValue:)), let cc = save.cousinColor.flatMap(AlienColor.init(rawValue:)) {
            let (a, c) = Self.makeVisitors(max(0, auntVisits - 1))
            for (p, color) in [(a, ac), (c, cc)] {
                p.alienColor = color
                p.alien = true
                p.changeFrom = 0
                p.changeTo = 1
                p.changeT0 = .distantPast
            }
            aunt = a
            cousin = c
            sleepover = true
        }
    }

    /// Saves tonight so the game can be continued from here.
    private func saveProgress() {
        let save = SaveGame(nights: nights, cash: cash, bank: bank, cousinsPaid: cousinsPaid, auntVisits: auntVisits,
                            visitProfit: visitProfit,
                            auntColor: sleepover ? aunt?.alienColor.rawValue : nil,
                            cousinColor: sleepover ? cousin?.alienColor.rawValue : nil, custom: custom)
        save.write()
        saved = save
    }

    /// Continuing a saved game: it's the saved night, lights out, everyone asleep (sleepover guests on the air mattresses).
    private func resumeNight() async throws {
        for (p, x) in zip(cast, Stage.roomX) {
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
            p.visible = true
        }
        if sleepover, let a = aunt, let c = cousin {
            for (p, x) in [(a, Stage.sleepoverX[0]), (c, Stage.sleepoverX[1])] {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.visible = true
            }
        }
        lightsOut = true
        (camFrom, camTo) = (Stage.full, Stage.full)
        caption = "Welcome back! End of day \(nights) — cash $\(cash), bank $\(bank)."
            + (sleepover ? " \(aunt?.id ?? "The aunt") and \(cousin?.id ?? "the cousin") are sleeping over." : "")
        try await sleep(2.4)
    }

    private func story(resumed: Bool = false) async throws {
        let (mom, ava, rosie) = (mom, ava, rosie)
        if !resumed {

            caption = "Mom and her two daughters just bought a new single-story house — with a little cottage in the backyard!"
            try await sleep(2.8)
            caption = "Moving day! Everyone carries a box to her room."
            doorOpenUntil = .now + 3.4
            for (p, x) in zip(cast, Stage.roomX) {
                p.carrying = true
                p.visible = true
                _ = beginWalk(p, to: x, speed: 125)
                try await sleep(0.8)
            }
            let arrive = cast.map { $0.moveT0.addingTimeInterval($0.moveDur) }.max() ?? .now
            try await sleep(max(arrive.timeIntervalSinceNow, 0) + 0.2)
            for p in cast {
                p.carrying = false
                boxes.append(p.x1 + (p === mom ? 28 : -25))
                p.facing = 0
            }
            try await say(rosie, "I LOVE my room!", 2)
            try await say(ava, "Mine's the biggest!", 2)
            caption = "Out back, across the yard, there's a little cottage nobody has looked inside yet."
            try await sleep(2.6)

            try await say(mom, "Girls, I'm going shopping. Be good while I'm gone!", 2.8)
            try await sayAll([ava, rosie], "Bye, Mom!", 1.6)
            caption = "Mom heads out to go shopping. The girls stay home."
            try await walk(mom, to: Stage.doorX, speed: 150)
            doorOpenUntil = .now + 1.2
            try await sleep(0.4)
            mom.visible = false
            try await sleep(1)

            try await say(rosie, "I'm bored… let's go look in the cottage!", 2.4)
            try await say(ava, "Okay!", 1.4)
            caption = "The girls head out the back door and across the yard to the cottage."
            try await walkAll([(rosie, Stage.watchX[0]), (ava, Stage.watchX[2])], speed: 150)
            for p in [ava, rosie] { p.facing = -1 }
            try await look(at: Stage.boothView)
            caption = "Inside the cottage stands a video poker machine, glowing green: THE ROSWELL OF POKER!"
            try await say(rosie, "Ooh! A video poker game!", 2.2)
            try await say(ava, "There's a sign on the side. Let's read it.", 2.2)
            signUntil = .now + 6
            try await sleep(6.2)
            try await say(ava, "Reach game ten for a surprise? I wonder what it is…", 2.6)
            try await say(rosie, "Can I play first? Pleeease?", 2)
            try await say(ava, "You're the youngest — go ahead. I'll watch!", 2.4)

            // Rosie plays all nine games. Game 10 is the machine's mini saucer.
            try await walk(rosie, to: Stage.playX)
            rosie.facing = -1
            try await walk(ava, to: Stage.seatX[2])
            ava.facing = -1
            try await playPoker(rosie)
            try await gameTen(rosie, watcher: (ava, "Rosie! What's happening to you?!"))
            try await say(rosie, "Whoa! I have a BIG \(rosie.alienColor.name) head!", 2.4)
            try await say(rosie, "I'm a ROSWELL ALIEN! Hee hee hee!", 2.2)
            try await snap(rosie)
            try await cashOutMachine(rosie)

            // The game isn't done: the machine sends a mini saucer out for Ava too.
            try await say(ava, "That is SO cool, Rosie!", 2.2)
            screen = "BONUS!"
            caption = "The Roswell of Poker isn't finished yet — its screen flashes BONUS!"
            sound.ding()
            try await say(rosie, "Ava… I think the machine wants YOU next!", 2.4)
            ava.mood = .shocked
            try await say(ava, "Me? But I didn't even play!", 2.2)
            ava.mood = .happy
            try await saucers([ava], at: [ava.x(at: .now)], firstTime: true)
            try await mirror(ava)
            try await say(ava, "Look at my huge eyes! They're amazing!", 2.6)
            try await snap(ava)

            caption = "The girls wait in the living room for Mom to come home."
            try await look(at: Stage.full)
            try await walkAll(zip([ava, rosie], Stage.couchX).map { ($0, $1) }, speed: 150)
            for p in [ava, rosie] { p.facing = 1 }
            try await sleep(1)
            caption = "A little while later…"
            try await sleep(1.6)

            // Mom comes home.
            doorOpenUntil = .now + 1.6
            (mom.x0, mom.x1, mom.moveDur) = (Stage.doorX, Stage.doorX, 0)
            mom.bags = true
            mom.visible = true
            try await sleep(0.3)
            try await walk(mom, to: 810)
            mom.facing = -1
            let livingRoom = Stage.shot(centerX: 765, height: 280)
            try await look(at: livingRoom)
            try await say(mom, "I'm home! I got snacks and—", 2.2)
            mom.mood = .shocked
            try await sleep(0.6)
            var colors: [String] = []
            for p in [ava, rosie] where !colors.contains(p.alienColor.name) { colors.append(p.alienColor.name) }
            try await say(mom, "GIRLS?! Why are you both \(Self.list(colors).uppercased())?!", 2.8)
            try await say(mom, "What happened?!", 1.8)
            try await say(rosie, "I played a video poker game in the cottage and made it to game ten!", 2.8)
            try await say(ava, "A mini saucer came out of the machine and changed Rosie — and then it came out again for me!", 3.2)
            mom.bags = false
            try await say(mom, "A mini saucer? Out of a poker machine? Girls, that's—", 2.4)
            try await say(rosie, "Mom… do you hear humming?", 2)

            // The saucer comes out of the cottage, across the yard and into the house for Mom.
            caption = "A mini saucer zooms out of the cottage, across the yard and into the house — straight for Mom!"
            try await say(ava, "It's coming for YOU, Mom!", 1.8)
            try await saucers([mom], at: [mom.x(at: .now)], firstTime: true, view: livingRoom, flight: BoothRun.longFlight)
            try await say(ava, "Go look in the bathroom mirror, Mom!", 2.2)
            try await bathroomMirror(mom, "AAAH! Is that really ME?!")
            try await say(mom, "Oh my… I LOVE it! I'm a real Roswell alien!", 2.6)
            try await say(rosie, "Now we're ALL aliens!", 2)
            try await say(ava, "Come out to the cottage, Mom — you have to see the machine!", 2.6)
            caption = "The girls lead Mom out to the cottage."
            try await look(at: Stage.full)
            try await walkAll([(rosie, Stage.watchX[0]), (ava, Stage.seatX[2]), (mom, Stage.mirrorStands[0])], speed: 150)
            mom.facing = -1
            try await look(at: Stage.boothView)
            for p in [ava, rosie] { p.facing = -1 }
            caption = "Mom reads the sign on the machine."
            signUntil = .now + 6
            try await sleep(6.2)
            try await say(mom, "The Roswell of Poker! Reach game ten for a surprise… so THAT'S what happened!", 3)
            try await snap(mom)

            // The three aliens make the cottage their own casino.
            try await look(at: Stage.boothView)
            try await say(ava, "Mom… what if we turned this cottage into our very own casino?", 2.8)
            try await say(mom, "A Roswell casino in our own backyard! Card tables, chips — moneymakers AND just-for-fun games!", 3.2)
            try await say(rosie, "And everybody who plays gets changed by the mini saucers first!", 2.6)
            try await say(mom, "Let's get to work, girls!", 2)
            caption = "The three Roswell aliens get to work…"
            fadeT0 = .now
            try await sleep(0.5)
            casinoBuilt = true
            sound.sparkle(true)
            try await sleep(1.2)
            sound.sparkle(false)
            sound.ding()
            caption = "Ta-da! The \(CasinoGame.casinoName) is open for business!"
            try await sayAll(cast, "Our own casino!", 2)

            caption = "The whole family heads back to the house."
            try await look(at: Stage.full)
            try await walkAll([(mom, 715), (ava, 745), (rosie, 775)])
            for p in cast { p.facing = 0 }
            try await look(at: Stage.shot(centerX: 745, height: 260))
            try await say(ava, "Three Roswell aliens!", 2)
            try await say(mom, "This is out of this world!", 2.2)
            try await say(rosie, "Playing the poker machine was a GOOD idea, right?", 2.6)
            caption = "The whole family has turned into Roswell aliens!"
            try await sleep(2.4)
        } else {
            try await resumeNight()
        }

        // Night after night at the casino. Every morning Mom buys groceries and goes to the bank;
        // after every second night her sister visits and they go shopping, and the cousin tags along to the casino.
        // A continued game starts at the saved night, right before the choice of another day.
        var atSavedNight = resumed
        while true {
            if !atSavedNight {
                nights += 1
                // An afternoon session (on day 1 the family is still an alien from the first change), home to rest, then the night session.
                // Each day: one game picked and played twice, Mom's shopping, change back, then bed.
                daytime = true
                if nights > 1 { try await alienAgain() }
                // On a visit day the (already alien) cousin tags along; the aunt gets back afterwards, is changed too,
                // and they sleep over as aliens. The next day they both tag along.
                try await casinoNight()
                try await bedtime()
                // Every night at lights-out is saved; "Continue" picks the game up from here.
                saveProgress()
            }
            atSavedNight = false
            let again = await withCheckedContinuation { cont in
                nextPick = cont
                choosingNext = true
            }
            try Task.checkCancellation()
            try await nextMorning(again: again)
            if !again { break }
        }
        caption = "That's a wrap! \(nights) \(nights == 1 ? "day and night" : "days and nights") at the casino — $\(bank) in the bank and $\(cash) on hand."
            + (cousinsPaid > 0 ? " The cousins were paid $\(cousinsPaid)." : "")
        finished = true
        running = false
    }

    /// Up to three line up beside the Roswell of Poker (or stand where `spots` says), and a mini saucer flies out of the machine
    /// over each of them; every beam runs together. Everyone is left standing where she was changed; `mirror` takes them to the mirror.
    /// `firstTime`: someone reaching game 10 who has no idea what's coming. `surprise`: guests who don't know either.
    /// `view`: where the camera waits while the saucers fly in (the cottage unless she's somewhere else, like the living room).
    /// `summon`: the family calls the saucers from wherever they are in the house; they fly over from the cottage and announce themselves.
    private func saucers(_ group: [Person], at spots: [Double]? = nil, firstTime: Bool = false, surprise: Bool = false, again: Bool = false,
                         summon: Bool = false, view: CGRect = Stage.boothView, flight: Double = BoothRun.lower) async throws {
        let spots = spots ?? Array(Stage.seatX.prefix(group.count))
        let names = Self.list(group.map(\.id))
        // Guests in for a surprise are shown where to stand by one of the family.
        if surprise, let host = cast.filter({ p in !group.contains { $0 === p } }).randomElement() {
            host.facing = -1
            try await say(host, "Stand right here by the machine, please.", 2)
        }
        if group.count > 1 || abs(group[0].x(at: .now) - spots[0]) > 1 {
            caption = group.count == 1 ? "\(names) stands beside the Roswell of Poker." : "\(names) line up beside the Roswell of Poker."
        }
        try await walkAll(zip(group, spots).filter { abs($0.0.x(at: .now) - $0.1) > 1 })
        for p in group { p.facing = 0 }
        try await look(at: view)

        // Each of them picks her own color — unless it's a surprise, when the machine picks.
        if surprise {
            caption = "The guests have no idea what this machine does…"
            for p in group { p.alienColor = p.look.color ?? AlienColor.basic.randomElement()! }
            try await say(group[0], group.count == 1 ? "Um… why am I standing by a poker machine?" : "Wait — why are we standing by a poker machine?", 2.4)
            try await say(rosie, "It's a surprise! Just stand still!", 2)
        } else if firstTime {
            for p in group { p.alienColor = p.look.color ?? AlienColor.basic.randomElement()! }
        } else {
            caption = group.count == 1 ? "\(names) picks a color." : "Everyone picks a color."
            for p in group {
                p.alienColor = p.look.color ?? AlienColor.basic.randomElement()!
                let c = p.alienColor.name
                try await say(p, ["I want \(c)!", "\(c.prefix(1).uppercased() + c.dropFirst()), please!", "Make me \(c)!", "Ooh — \(c) for me!"].randomElement()!, 1.8)
            }
        }

        if view == Stage.boothView {
            caption = "The hatch on top of the Roswell of Poker slides open…"
            sound.ding()
            try await sleep(0.8)
        }
        if summon {
            // Each of them calls for her own saucer, wherever she is.
            for p in group { try await say(p, ["Mini saucer!", "Mini saucer, please!", "Oh, mini saucer!"].randomElement()!, 1.6) }
            cut(to: Stage.full)
            caption = group.count == 1 ? "Whoosh! A mini saucer shoots out of the Roswell of Poker, across the yard and into the house!"
                                       : "Whoosh! Mini saucers shoot out of the Roswell of Poker, across the yard and into the house — one for each of them!"
        } else if again {
            // The family's been through this before.
            try await say(group.randomElement()!, "Here we go again.", 1.8)
        }

        let t0 = Date.now
        saucerFlight = flight
        beamPeople = group
        boothT0 = t0
        for p in group {
            p.alien = false
            (p.changeFrom, p.changeTo) = (0, 1)
            p.changeT0 = t0 + flight + BoothRun.charge * 0.5
            p.changeDur = BoothRun.charge * 0.5 + BoothRun.beam
        }
        sound.motor(true)
        caption = summon ? caption : view != Stage.boothView ? "Whirr… the mini saucer swoops in over \(names)'s head!"
            : group.count == 1 ? "Whirr… a mini saucer flies out of the machine and over \(names)'s head!"
                                   : "Whirr… a mini saucer flies out of the machine for each of them!"
        // A long flight (across the yard into the house) is watched from far enough back to see the whole trip.
        if flight > BoothRun.lower { cut(to: Stage.full) }
        try await sleep(flight)
        sound.motor(false)
        if summon {
            caption = (group.count == 1 ? "The mini saucer hovers" : "The mini saucers hover") + " overhead…"
            try await say(group.randomElement()!, "Here they come.", 2.0)
        }
        // Close in on the saucers: tall enough for the tallest, wide enough for everyone.
        let head = group.map { Pose($0, feet: CGPoint(x: $0.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head.y }.min()!
        let xs = group.map { $0.x(at: .now) }
        let span = xs.max()! - xs.min()! + 120
        let groupShot = Stage.focus(CGPoint(x: (xs.min()! + xs.max()!) / 2, y: head - 30),
                                    height: max(240, Stage.floorY - head + 120, span * Stage.H / Stage.W))
        cut(to: groupShot)
        caption = group.count == 1 ? "The saucer hums and starts to glow…" : "The saucers hum and start to glow…"
        sound.beam(true)
        blurt(group, ["Ooh, it's humming!", "Here it comes!", "I'm so nervous!", "It's glowing!", "Eeek! Here we go!"], for: BoothRun.charge)
        if firstTime, group.contains(where: { $0 === rosie }) { rosie.says = "What am I being turned into?" }
        try await sleep(BoothRun.charge)

        // A close-up of each of them as the beam changes her.
        // Nobody repeats a line; whoever is in the middle of a first or surprise change asks what's going on.
        let slice = BoothRun.beam / Double(group.count)
        var used: Set<String> = []
        for (i, p) in group.enumerated() {
            cut(to: closeUp(p))
            caption = "ZZZAP! \(p.id) is turning into a \(p.alienColor.name) Roswell alien — even her clothes disappear!"
            let middle = (firstTime || surprise) && i == group.count / 2
            try await react(p, for: slice, used: &used,
                            opening: middle ? (surprise ? (group.count == 1 ? "I'm being turned into a Roswell alien!" : "We're being turned into Roswell aliens.")
                                                        : (group.count == 1 ? "What's happening to me?!" : "What's happening?")) : nil)
        }
        cut(to: groupShot)
        sound.beam(false)
        sound.sparkle(true)
        caption = "Twinkle! Sparkles set the change in."
        blurt(group, ["It tickles!", "Sparkly!", "Hee hee hee!", "Ooh, twinkles!", "Wheee!"], for: BoothRun.sparkle)
        try await sleep(BoothRun.sparkle)
        sound.sparkle(false)
        sound.mist(true)
        caption = "Pssshh… the \(group.count == 1 ? "saucer cools" : "saucers cool") down with a puff of mist."
        try await sleep(BoothRun.cool)
        sound.mist(false)
        sound.motor(true)
        for p in group { p.alien = true }
        caption = group.count == 1 ? "The mini saucer zips back into the machine…" : "The mini saucers zip back into the machine…"
        if flight > BoothRun.lower {
            caption = group.count == 1 ? "The mini saucer flies back out of the house, across the yard and into the cottage…"
                                       : "The mini saucers fly back out of the house, across the yard and into the cottage…"
            cut(to: Stage.full)
        }
        try await sleep(flight)
        sound.motor(false)
        beamPeople = []
        for p in group { p.mood = .happy }
        screen = "DONE!"
        sound.ding()
        caption = "Ding! \(names) \(group.count == 1 ? "is a Roswell alien" : "are all Roswell aliens")!"
        try await sleep(1.2)
        screen = "READY"
        cut(to: view)
    }

    // MARK: The Roswell of Poker

    /// You play `p`'s nine games on the Roswell of Poker. In the cottage, running out of credits or not betting the max means
    /// inserting credits and starting over until she reaches game 10. On a kid's computer one try is all they get.
    /// Returns how the sitting ended; the credits left on the machine are kept in `leftoverCredits`.
    @discardableResult
    private func playPoker(_ p: Person, kid: Bool = false) async throws -> PokerSession.Ending {
        let session = PokerSession(player: p.id, kidComputer: kid, muted: muted)
        session.onSound = { [weak self] s in
            switch s {
            case .card: self?.sound.beep()
            case .coin: self?.sound.ching()
            case .chime: self?.sound.ding()
            }
        }
        session.onEnd = { [weak self] ending in
            guard ending == .qualified || kid else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(ending == .qualified ? 4.5 : 4))
                self?.finishPoker(session)
            }
        }
        caption = kid ? "\(p.id) is playing the Roswell of Poker on the computer. Bet the max every hand and reach game 10!"
                      : "\(p.id) is playing the Roswell of Poker. Bet the max every hand and reach game 10!"
        poker = session
        session.begin()
        await withCheckedContinuation { cont in pokerDone = cont }
        try Task.checkCancellation()
        leftoverCredits = session.credits
        return session.ending ?? .broke
    }

    private func finishPoker(_ session: PokerSession) {
        guard poker === session else { return }
        session.shutDown()
        poker = nil
        pokerDone?.resume()
        pokerDone = nil
    }

    /// Game 10 in the cottage: the hatch opens and a mini saucer flies out over the player, who's still standing at the machine.
    private func gameTen(_ p: Person, watcher: (Person, String)? = nil) async throws {
        screen = "GAME 10!"
        try await look(at: Stage.boothView)
        caption = "GAME 10! The Roswell of Poker starts to hum…"
        sound.ding()
        p.mood = .shocked
        try await say(p, "Game ten! What's going to happen?", 2)
        if let (w, line) = watcher { try await say(w, line, 2) }
        p.mood = .happy
        try await saucers([p], at: [p.x(at: .now)], firstTime: true)
        try await mirror(p)
    }

    /// Whatever credits are left on the machine after game 10 come out as cash for the house, a dollar a credit.
    private func cashOutMachine(_ p: Person) async throws {
        let credits = leftoverCredits
        leftoverCredits = 0
        guard credits > 0 else { return }
        screen = "CASH OUT"
        caption = "\(p.id) presses CASH OUT: the \(credits) credits left on the machine come out as $\(credits) for the house."
        sound.ching()
        cash += credits
        cashPop = ("+$\(credits) from the machine", .now, Stage.machine.midX + 60)
        try await say(p, p.isKid ? "$\(credits) left on the machine! That's for the house, Mom!" : "$\(credits) left on the machine — that goes to the house!", 2.6)
        try await sleep(0.6)
        screen = "READY"
    }

        /// Everyone in `group` says something at once, each her own line, without holding up the machine.
    private func blurt(_ group: [Person], _ lines: [String], for seconds: Double) {
        for (p, line) in zip(group, lines.shuffled()) {
            p.says = line
            p.saysUntil = .now + seconds - 0.2
        }
    }

    /// Her close-up under the beam: she reacts to whatever is changing right now — her skin early on,
    /// then her head, eyes and hair, and finally her clothes and hands. Fills `seconds`.
    /// Lines in `used` are skipped (and hers are added) so people beside her say different things;
    /// `opening` replaces her first line.
    private func react(_ p: Person, for seconds: Double, used: inout Set<String>, opening: String? = nil) async throws {
        let n = seconds >= 8 ? 3 : seconds >= 4.4 ? 2 : 1
        let each = seconds / Double(n) - 0.2
        let c = p.alienColor.name
        for k in 0..<n {
            if k == 0, let opening {
                p.mood = .shocked
                try await say(p, opening, each)
                continue
            }
            let level = p.alienLevel(at: .now + each / 2)
            let lines: [String]
            if level < 0.35 {
                lines = ["Whoa! My skin is turning \(c)!", "It tingles all over!", "Look at my arms — they're \(c)!",
                         p.isKid ? "Mommy, I'm going \(c)!" : "Oh my goodness — I'm going \(c)!"]
            } else if level < 0.7 {
                lines = ["My head is getting BIGGER!", "My eyes! They're getting HUGE!", "Where did my hair go?!",
                         "My ears are disappearing!", p.isKid ? "My head feels like a balloon!" : "My head is stretching like an egg!"]
            } else {
                lines = ["My clothes are vanishing!", "Only three fingers?!", "Ooh, I feel so light and skinny!",
                         p.isKid ? "I'm a real alien! Yay!" : "This is out of this world!"]
            }
            // Grown-ups are mostly shocked; kids mostly love it.
            p.mood = Double.random(in: 0...1) < (p.isKid ? 0.3 : 0.65) ? .shocked : .happy
            let line = lines.filter { !used.contains($0) }.randomElement() ?? lines.randomElement()!
            used.insert(line)
            try await say(p, line, each)
        }
    }

    /// Head to hips of someone under a mini saucer, with the saucer just in frame.
    private func closeUp(_ p: Person) -> CGRect {
        let x = p.x(at: .now)
        let pose = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: p.facing, now: .now)
        let top = pose.head.y - pose.hr * 2.6
        let bottom = pose.torso.maxY + pose.hr * 0.6
        return Stage.focus(CGPoint(x: x, y: (top + bottom) / 2), height: max(120, bottom - top))
    }

    /// At home: she hurries to the mirror over the bathroom sink, takes a look, and can't believe what she sees.
    private func bathroomMirror(_ p: Person, _ line: String) async throws {
        caption = "\(p.id) hurries to the bathroom mirror…"
        try await look(at: Stage.full)
        try await walk(p, to: Stage.bathStandX, speed: 150)
        p.facing = 0
        try await look(at: Stage.shot(centerX: 660, height: 230))
        caption = "\(p.id) takes a look in the mirror…"
        try await sleep(1.4)
        p.mood = .shocked
        caption = "SURPRISE! \(p.id) can't believe her eyes!"
        sound.ding()
        try await say(p, line, 2.6)
        try await sleep(0.8)
        p.mood = .happy
    }

    /// A walk to the mirror for a first look.
    private func mirror(_ p: Person) async throws {
        try await mirror([p])
    }

    /// Up to three walk to the wide mirror together and see themselves side by side.
    private func mirror(_ group: [Person]) async throws {
        caption = group.count == 1 ? "\(group[0].id) checks her new look in the mirror." : "They check their new look in the mirror."
        try await walkAll(zip(group, Stage.mirrorStands).map { ($0, $1) })
        for p in group { p.facing = -1 }
        let tallest = group.map(\.height).max() ?? 120
        try await look(at: Stage.shot(centerX: group.count == 1 ? 410 : 430, height: max(tallest, 120) + 120))
    }

    /// "Ava", "Ava and Rosie", "Mom, Ava and Rosie".
    private static func list(_ names: [String]) -> String {
        names.count <= 1 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + names.last!
    }

    /// Snap! A before-and-after photo for the album.
    private func snap(_ p: Person) async throws {
        caption = "Snap! \(p.id)'s before-and-after photo goes in the album."
        flashT0 = .now
        sound.shutter()
        album.add(AlbumEntry(date: .now, spec: PersonSpec(p)))
        try await sleep(1.4)
    }

    // MARK: The casino

    /// One session. Each game is picked at home, then the family heads out back to the cottage casino to play it twice.
    private func casinoNight() async throws {
        let (mom, ava, rosie) = (mom, ava, rosie)
        let day = daytime
        let session = day ? "day" : "night"
        // Money in the bank counts too: Mom makes deposits between games.
        let nightStart = cash + bank
        sessionGroceries = 0
        gamesPlayed = 0

        // Everyone gathers in the living room.
        try await look(at: Stage.full)
        try await walkAll(zip(cast, Stage.homeFamilyX).map { ($0, $1) } + (cousin.map { [($0, Stage.homeCousinX)] } ?? [])
                          + (aunt.map { [($0, Stage.homeAuntX)] } ?? []))
        for p in cast { p.facing = 0 }
        cousin?.facing = -1
        aunt?.facing = -1
        try await look(at: Stage.shot(centerX: 770, height: 280))
        if nights == 1 && day {
            caption = "The family has an idea…"
            try await say(ava, "Mom, let's open the cottage casino for real!", 2.4)
            try await say(mom, "Moneymakers AND just-for-fun games — all out in our cottage!", 2.8)
            try await say(rosie, "And everybody who plays stands by the Roswell of Poker, and the mini saucers come out!", 3)
            try await say(mom, "Every moneymaker buy-in is $\(CasinoGame.buyIn). We've got $\(CasinoGame.startCash) to cover the table.", 3)
        } else {
            caption = "\(day ? "Day" : "Night") \(nights) — game time!"
                + (aunt.map { a in " \(a.id) and \(cousin?.id ?? "her girl") tag along — together this time!" } ?? cousin.map { " \($0.id) tags along." } ?? "")
            try await sleep(2.4)
        }
        while true {
            try await look(at: Stage.full)
            caption = (gamesPlayed == 0 ? "Pick today's game" : "Pick the next game — or call it a \(session)")
                + ". Every game is played in the cottage casino out back."
            let pick = await withCheckedContinuation { cont in
                gamePick = cont
                choosingGame = true
            }
            try Task.checkCancellation()
            guard let pick else { break }
            result = nil
            // Every game picked is played twice, each time with a fresh set of guests.
            // On a visit day the kids already ran the first game this morning, so the afternoon game is played once.
            let rounds = girlsGame != nil ? 1 : 2
            try await toCasino(for: pick.game)
            for round in 1...rounds {
                if round == 2 {
                    caption = "Round two of \(pick.game.name) — time to find new players!"
                    try await say(mom, "That was fun! Let's play \(pick.game.name) again with some new faces.", 2.8)
                    result = nil
                }
                try await runTable(pick.game, daughterHouse: pick.game.isMoney && pick.daughterHouse)
                gamesPlayed += 1
                // In the hole after a game? The Roswell of Poker goes out to kids' computers right away.
                if cash < 0 { try await kidsRescue() }
            }
            try await backHome()
            // A day is one pick, played twice (once more on a visit day, after the kids' morning game).
            if gamesPlayed >= rounds {
                caption = (rounds == 1 ? "That's the second game of the day" : "That's two games of \(pick.game.name)") + " — that's it for the casino today!"
                try await sleep(2)
                break
            }
        }
        // Visit day: the aunt gets back to the house while everyone is still an alien.
        if awayAunt != nil {
            felt = []
            board = nil
            for p in cast { p.atTable = false }
            try await auntReturns()
        }
        // The end of the day: Mom runs to the store and the bank — never in between games.
        try await errands()
        // Still in the hole (nothing left in the bank): the game goes out to kids' computers.
        if cash < 0 { try await kidsRescue() }

        // Evening now: the guests go home under the stars and the family winds down.
        daytime = false
        caption = "That's a wrap for the \(session)!"
        felt = []
        board = nil
        mom.atTable = false
        try await look(at: Stage.shot(centerX: 770, height: 270))
        // Groceries bought between games are household spending, not a table loss.
        let profit = cash + bank - nightStart + sessionGroceries
        try await say(ava, "We ran \(gamesPlayed) \(gamesPlayed == 1 ? "game" : "games") and made a whole lot of Roswell aliens!", 3)
        if profit > 0 {
            try await say(mom, "And we're up $\(profit)! The house always wins.", 2.6)
        } else if profit == 0 {
            try await say(mom, "We broke even — but what a \(session)!", 2.4)
        } else {
            try await say(mom, "We're down $\(-profit)… but it sure was fun!", 2.6)
        }
        if sleepover {
            // The visitors stay over; the cousin is paid after tomorrow's trip together.
            visitProfit += profit
        } else if aunt != nil {
            try await payCousin(visitProfit + profit)
            visitProfit = 0
        }
        try await say(rosie, "Can we play again tomorrow?", 2)
        try await say(mom, "First thing in the morning! Time to wind down, girls.", 2.6)

        // The change only lasts until the session's over; it wears off now that they're home for good.
        for p in cast { p.facing = 0 }
        try await say(rosie, "Hey… I feel all tingly!", 2.2)
        caption = "The session's over — and the change wears off. The family turns human again, clothes and all!"
        try await changeBack(cast)
        try await say(ava, "We're human again!", 2)
        try await say(rosie, "And our clothes came back!", 2.2)
        if sleepover, let a = aunt, let c = cousin {
            a.facing = -1
            c.facing = -1
            caption = "\(a.id) and \(c.id) are staying the night — and staying Roswell aliens!"
            try await say(c, "Mommy, we're still aliens!", 2)
            try await say(a, "Looks like we're staying aliens all night, sweetie!", 2.6)
            try await say(mom, "Then you two are sleeping over. In the morning we'll all go on a trip together!", 3)
            try await say(c, "A sleepover? YAY!", 1.8)
        }
        try await say(mom, "What a day. Bedtime, girls!", 2.4)
        try await guestsGoHome()
        caption = "Every game is saved in the album."
    }

    /// After the family ends the night, every guest from tonight gets home still an alien and turns human at her own front door —
    /// up to four households to a street, each at her own house.
    private func guestsGoHome() async throws {
        let households = nightHouseholds.filter { $0.contains(where: \.alien) }
        nightHouseholds = []
        guard !households.isEmpty else { return }
        let family = cast + [cousin, aunt].compactMap { $0 }
        let homeX = family.map { $0.x(at: .now) }
        let batches = stride(from: 0, to: households.count, by: Stage.guestDoorX.count).map {
            Array(households[$0..<min($0 + Stage.guestDoorX.count, households.count)])
        }
        for (b, batch) in batches.enumerated() {
            fadeT0 = .now
            try await sleep(0.5)
            inNeighborhood = true
            for p in family { p.visible = false }
            // Each household walks in from the nearer side of the street to her own front door.
            var moves: [(Person, Double)] = []
            for (h, group) in batch.enumerated() {
                let door = Stage.guestDoorX[h], fromLeft = h < 2
                for (i, p) in group.enumerated() {
                    let start = fromLeft ? -50 - Double(i) * 28 : Stage.W + 50 + Double(i) * 28
                    p.says = nil
                    p.atTable = false
                    p.visible = true
                    (p.x0, p.x1, p.moveDur, p.facing) = (start, start, 0, fromLeft ? 1 : -1)
                    moves.append((p, door + (Double(i) - Double(group.count - 1) / 2) * 30))
                }
            }
            customers = batch.flatMap { $0 }
            (camFrom, camTo) = (Stage.full, Stage.full)
            try await sleep(0.8)
            caption = b == 0 ? "Meanwhile, across town, \(daytime ? "this afternoon's" : "tonight's") guests get home — still Roswell aliens…"
                             : "…and down the next street, more guests get home…"
            try await walkAll(moves, speed: 150)
            for p in customers { p.facing = 0 }
            try await sleep(0.4)
            let aliens = customers.filter(\.alien)
            caption = "Home at last — the change wears off at the front door. Human again, clothes and all!"
            try await changeBack(aliens)
            for group in batch.prefix(2) {
                guard let p = group.first(where: { !$0.isKid }) ?? group.first else { continue }
                let line = p.id.hasPrefix("Aunt ")
                    ? "Human again! What a \(daytime ? "day" : "night") — thanks, sis!"
                    : group.count > 1 && group.contains(where: \.isKid)
                        ? ["We're home, sweetie — and we're human again!", "Look, honey — our clothes came back!"].randomElement()!
                        : (daytime ? ["Home sweet home — and human again!", "My clothes are back, just in time for dinner!",
                                      "What an afternoon! I'll be back tonight!"]
                                   : ["Home sweet home — and human again!", "My clothes are back, just in time for bed!",
                                      "What a night! I'll be back tomorrow!"]).randomElement()!
                try await say(p, line, 2.4)
            }
            if let kid = batch.flatMap({ $0 }).first(where: \.isKid) {
                try await say(kid, ["I'm me again, Mommy!", daytime ? "Can we go back tonight?" : "Can we go back tomorrow?", "That was SO cool!"].randomElement()!, 2)
            }
            caption = daytime ? "See you later, everybody!" : "Good night, everybody!"
            for p in customers { p.facing = 0 }
            try await sleep(1.2)
            for p in customers { p.visible = false }
            sound.ding()
            try await sleep(0.8)
        }
        // Back to the family's house.
        fadeT0 = .now
        try await sleep(0.5)
        inNeighborhood = false
        customers = []
        for (p, x) in zip(family, homeX) {
            (p.x0, p.x1, p.moveDur) = (x, x, 0)
            p.visible = true
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
    }

    // MARK: Between nights

    /// Before every session but the very first: the family heads out to the cottage, and the mini saucers change them again.
    private func alienAgain() async throws {
        let (mom, ava, rosie) = (mom, ava, rosie)
        let when = daytime ? "today" : "tonight"
        caption = aunt != nil ? "The second half of day \(nights) — and \(aunt!.id) is coming along!" : "Good morning — day \(nights) of games!"
        try await look(at: Stage.full)
        // On a visit day the girls are still aliens from their own game this morning; only Mom needs the saucer.
        let changing = cast.filter { !$0.alien }
        guard !changing.isEmpty else { return }
        if changing.count == 1 && changing[0] === mom {
            try await say(mom, "My turn to be a Roswell alien again!", 2.4)
            try await sayAll([ava, rosie], "Yay, Mom!", 1.6)
        } else {
            try await say(mom, "Who's ready to be a Roswell alien again?", 2.4)
            try await sayAll([ava, rosie], "We are!", 1.6)
        }
        if let cousin {
            try await say(cousin, cousin.alien ? "Now it's YOUR turn! Can I watch?" : "Can I watch?", 2)
            try await say(mom, "Sure, sweetie — come see!", 2)
        }
        try await summonSaucers(changing)
        if let cousin { try await say(cousin, "Whoa! That's SO cool!", 2) }
        for p in changing {
            try await say(p, ["\(p.alienColor.name.prefix(1).uppercased() + p.alienColor.name.dropFirst()) \(when)!", "Alien again — I love it!",
                              "Look at my big \(p.alienColor.name) head!"].randomElement()!, 2)
        }
        try await say(rosie, "Let's go!", 1.6)
        try await walkAll(zip(cast, Stage.homeFamilyX).map { ($0, $1) }.filter { abs($0.0.x(at: .now) - $0.1) > 1 }, speed: 150)
        for p in cast { p.facing = 0 }
    }

    /// Spots around the house the family can be when they call for the saucers: bathroom, living room and the three bedrooms.
    private static let houseSpots: [(x: Double, room: String)] = [(640, "the bathroom"), (720, "the living room"), (800, "the living room"),
                                                                    (Stage.roomX[0], "Mom's room"), (Stage.roomX[1], "Ava's room"), (Stage.roomX[2], "Rosie's room")]

    /// The family scatter around the house and each says "Mini saucer!" — the saucers fly over from the cottage to wherever they are.
    private func summonSaucers(_ changing: [Person]) async throws {
        let picks = Self.houseSpots.shuffled().prefix(changing.count).sorted { $0.x < $1.x }
        let spots = picks.map(\.x)
        let where_ = zip(changing, picks).map { "\($0.id) in \($1.room)" }
        caption = changing.count == 1 ? "\(where_[0]) — no need to go out to the cottage." : "Everyone's somewhere in the house: " + Self.list(where_) + "."
        try await look(at: Stage.full)
        try await walkAll(zip(changing, spots).map { ($0, $1) }.filter { abs($0.0.x(at: .now) - $0.1) > 1 }, speed: 150)
        for p in changing { p.facing = 0 }
        try await saucers(changing, at: spots, summon: true, view: Stage.full, flight: BoothRun.longFlight)
    }

    /// The morning after a night at the casino. Mom always buys groceries and goes to the bank.
    /// After every second night (when the family is going back), her sister and niece visit first:
    /// Mom takes her sister shopping and the cousin tags along.
    private func nextMorning(again: Bool) async throws {
        let (mom, ava, rosie) = (mom, ava, rosie)
        let girls = [ava, rosie]
        nightHouseholds = []
        girlsGame = nil
        fadeT0 = .now
        try await sleep(0.5)
        lightsOut = false
        for (p, x) in zip(cast, [715.0, 745.0, 775.0]) {
            p.says = nil
            p.bags = false
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
        }
        // Sleepover guests get up off the air mattresses — still aliens.
        let stayed = sleepover ? [aunt, cousin].compactMap { $0 } : []
        sleepover = false
        for (p, x) in zip(stayed, [835.0, 858.0]) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1)
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "The next morning…"
        try await look(at: Stage.shot(centerX: 780, height: 270))
        if let a = aunt, let c = cousin, !stayed.isEmpty {
            let sister = a.id.replacingOccurrences(of: "Aunt ", with: "")
            caption = "\(a.id) and \(c.id) wake up — still Roswell aliens!"
            for p in cast { p.facing = 1 }
            try await say(mom, "Good morning, \(sister)! You two are still aliens!", 2.6)
            try await say(a, "We slept like a couple of Martians!", 2.4)
            if again {
                try await say(c, "Is it time for our trip together?", 2.2)
                try await say(mom, "It sure is! Everybody's coming along today.", 2.6)
                try await sayAll(girls, "Yay!", 1.4)
            } else {
                try await say(mom, "No games today, sis — what a run we had!", 2.6)
                try await say(a, "Then we'd better head home. The change will wear off when we get there!", 3)
                caption = "\(a.id) and \(c.id) head home, still aliens."
                doorOpenUntil = .now + 2.4
                try await walkAll([(a, Stage.doorX), (c, Stage.doorX)], speed: 120)
                a.visible = false
                c.visible = false
                aunt = nil
                cousin = nil
                visitProfit = 0
            }
            return
        }

        // After every odd night the aunt and cousin visit.
        if again && nights % 2 == 1 && aunt == nil {
            let (a, c) = Self.makeVisitors(auntVisits)
            auntVisits += 1
            caption = "Ding-dong! It's \(a.id), Mom's sister, with her little girl \(c.id)."
            doorOpenUntil = .now + 2.4
            aunt = a
            cousin = c
            try await walkAll([(a, 835), (c, 858)])
            a.facing = -1
            c.facing = -1
            for p in cast { p.facing = 1 }
            let sister = a.id.replacingOccurrences(of: "Aunt ", with: "")
            try await say(mom, "\(sister)! And little \(c.id)! What a nice surprise!", 2.6)
            try await sayAll(girls, "Hi, Aunt \(sister)! Hi, \(c.id)!", 2)
            try await say(a, "I need some new clothes. Come shopping with me?", 2.6)
            try await say(mom, "I'd love to! Groceries and the bank can wait till tonight.", 2.6)
            try await say(c, "Can I stay here and play with my cousins?", 2.2)
            try await say(a, "Of course, sweetie! Be good.", 1.8)
            try await say(mom, "Girls, look after \(c.id). We'll be back soon!", 2.4)
            try await sayAll(girls, "Bye!", 1.4)
            caption = "Mom and \(a.id) head out shopping. \(c.id) stays home with her cousins."
            doorOpenUntil = .now + 2.5
            try await walkAll([(mom, Stage.doorX), (a, Stage.doorX)], speed: 150)
            for p in [mom, a] { p.visible = false }
            try await sleep(0.8)
            try await cousinTransforms()
            try await girlsHostGame()
            c.visible = false
            try await townTrip(with: [a], errands: false)
        } else {
            // Mom already did the shopping and the bank after yesterday's games.
            for p in girls { p.facing = -1 }
            mom.facing = 1
            if again {
                try await say(mom, "Good morning, girls! Ready to play again?", 2.6)
                try await sayAll(girls, "Yes!", 1.4)
            } else {
                try await say(mom, "Good morning, girls! No games today. What a run we had!", 2.8)
            }
            return
        }

        // Home again.
        fadeT0 = .now
        try await sleep(0.5)
        inTown = false
        // The cousin stayed home with the girls.
        for p in girls + [cousin].compactMap({ $0 }) { p.visible = true }
        (mom.x0, mom.x1, mom.moveDur) = (Stage.doorX, Stage.doorX, 0)
        mom.visible = true
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Mom comes home from the boutique."
        doorOpenUntil = .now + 2
        try await walk(mom, to: 830)
        mom.facing = -1
        cousin?.facing = 1
        for p in girls { p.facing = 1 }
        try await look(at: Stage.shot(centerX: 780, height: 270))
        try await say(mom, "I'm home! Groceries and the bank can wait till the end of the day.", 2.8)
        mom.bags = false
        if let cousin, let aunt = awayAunt {
            let sister = aunt.id.replacingOccurrences(of: "Aunt ", with: "")
            try await look(at: Stage.shot(centerX: 770, height: 250))
            mom.mood = .shocked
            try await say(mom, "\(cousin.id)?! Is that YOU? And girls — you're aliens too!", 2.6)
            try await say(cousin, "The mini saucers turned me into a \(cousin.alienColor.name) Roswell alien, Auntie!", 2.8)
            try await say(rosie, "She picked the color herself!", 2)
            mom.mood = .happy
            try await say(mom, "Well, you look adorable! Your mom is going to be SO surprised.", 2.8)
            try await say(ava, "Don't tell her — let's surprise her!", 2.2)
            if let g = girlsGame {
                try await say(rosie, "And Mom — we ran a game of \(g.name) in the casino while you were gone! Ava was the dealer!", 3)
                try await say(ava, g.net > 0 ? "The house made $\(g.net)!" : g.net == 0 ? "We broke even!" : "We lost $\(-g.net)… but it was fun!", 2.4)
                try await say(mom, "My girls, running the casino all by themselves! I'm so proud of you!", 2.8)
            }
            _ = sister
            caption = "A little later…"
            try await sleep(1.6)
            // The second half of the day: the aunt gets back, is changed, and comes along with everyone.
            try await auntReturns()
            try await say(mom, "\(cousin.id), you help out again this afternoon, and you get a quarter of today's profit.", 2.8)
            try await say(cousin, "A whole quarter? Yay!", 2)
        } else if !again {
            try await say(mom, "No games today, girls. What a run we had!", 2.6)
        }
    }

    /// After the family changes back: lights out, everyone to her own room, and a night's sleep.
    private func bedtime() async throws {
        let girls = [ava, rosie]
        caption = "Bedtime! Everyone heads to her room."
        try await look(at: Stage.full)
        let guests = [aunt, cousin].compactMap { $0 }
        if sleepover, let a = aunt, let c = cousin {
            caption = "Bedtime! \(a.id) and \(c.id) get the air mattresses in the living room."
            try await walkAll(zip(cast, Stage.roomX).map { ($0, $1) } + [(a, Stage.sleepoverX[0]), (c, Stage.sleepoverX[1])], speed: 140)
            try await say(c, "Good night, cousins! Good night, Auntie!", 2.2)
        } else {
            for p in guests { p.visible = false }
            try await walkAll(zip(cast, Stage.roomX).map { ($0, $1) }, speed: 140)
        }
        for p in cast + guests { p.facing = 0 }
        try await sayAll(girls, "Good night, Mom!", 1.8)
        try await say(mom, "Sweet dreams, girls. More games in the morning!", 2.6)
        lightsOut = true
        caption = "Lights out… Zzz…"
        try await sleep(3.6)
        // The lights stay out until morning (`nextMorning`).
        for p in guests { p.visible = true }
    }

    /// After each pair of games: Mom pops out for groceries and a bank deposit while everyone waits at home.
    private func errands() async throws {
        let (mom, ava, rosie) = (mom, ava, rosie)
        let girls = [ava, rosie]
        try await look(at: Stage.full)
        for p in cast { p.atTable = false }
        try await walkAll(zip(cast, Stage.homeFamilyX).map { ($0, $1) })
        for p in girls { p.facing = 1 }
        try await say(mom, "Girls, I'm running out for groceries and to the bank. Be right back!", 2.8)
        if let a = aunt {
            try await say(mom, "Make yourselves at home, \(a.id.replacingOccurrences(of: "Aunt ", with: ""))!", 2.2)
        }
        try await sayAll(girls, "Bye, Mom!", 1.6)
        caption = "Mom heads out to do the shopping and make a bank deposit."
        doorOpenUntil = .now + 1.6
        try await walk(mom, to: Stage.doorX, speed: 150)
        mom.visible = false
        try await sleep(0.6)
        let visitors = [aunt, cousin].compactMap { $0 }
        for p in visitors { p.visible = false }
        try await townTrip(with: [])
        sessionGroceries += Self.groceries

        fadeT0 = .now
        try await sleep(0.5)
        inTown = false
        inCustoms = false
        for p in girls + visitors { p.visible = true }
        (mom.x0, mom.x1, mom.moveDur) = (Stage.doorX, Stage.doorX, 0)
        mom.visible = true
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Mom comes home with the groceries."
        doorOpenUntil = .now + 2
        try await walk(mom, to: Stage.homeFamilyX[0])
        mom.facing = 1
        for p in girls { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 780, height: 270))
        try await say(mom, "I'm back! Groceries are in, and the money's in the bank.", 2.8)
        mom.bags = false
        for p in cast { p.facing = 0 }
    }

    /// After the bank, Mom pops around the corner into Cosmic Customs and you shop for the family and the casino.
    private func visitCustoms() async throws {
        let mom = mom
        caption = "One more stop, just around the corner…"
        try await walk(mom, to: Stage.W + 40, speed: 170)
        fadeT0 = .now
        try await sleep(0.5)
        inCustoms = true
        (mom.x0, mom.x1, mom.moveDur, mom.facing) = (-40, -40, 0, 1)
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Cosmic Customs — alien looks, outfits, casino decor and Roswell of Poker upgrades."
        try await walk(mom, to: Stage.customsDoorX - 50)
        mom.facing = 0
        try await say(mom, ["Let's see what's new at Cosmic Customs!", "Just a quick peek inside…", "Ooh, new stuff in the window!"].randomElement()!, 2.2)
        doorOpenUntil = .now + 1.2
        try await walk(mom, to: Stage.customsDoorX, speed: 90)
        mom.visible = false
        let before = custom.spent
        if !autoPlay {
            caption = "You're shopping at Cosmic Customs with $\(spendable) to spend. Tap Done when you're finished."
            await withCheckedContinuation { cont in
                shopDone = cont
                shopping = true
            }
            try Task.checkCancellation()
        } else {
            caption = "Mom browses Cosmic Customs."
            try await sleep(2)
        }
        doorOpenUntil = .now + 1.2
        mom.visible = true
        mom.facing = 1
        let spent = custom.spent - before
        if spent > 0 {
            sound.ching()
            cashPop = ("-$\(spent) Cosmic Customs", .now, Stage.customsDoorX)
            caption = "Mom spends $\(spent) at Cosmic Customs."
            try await say(mom, ["The girls are going to love this!", "Wait till everyone sees the casino!", "Worth every penny!"].randomElement()!, 2.4)
        } else {
            caption = "Mom just window-shops today."
            try await say(mom, "Nothing today — maybe next time!", 2.2)
        }
    }

    /// Main Street: a stop at the boutique if the aunt came along, then groceries and the bank.
    private func townTrip(with companions: [Person], errands: Bool = true) async throws {
        let mom = mom
        let trip = [mom] + companions
        fadeT0 = .now
        try await sleep(0.5)
        inTown = true
        for p in cast where p !== mom { p.visible = false }
        for (i, p) in trip.enumerated() {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (-40 - Double(i) * 30, -40 - Double(i) * 30, 0, 1)
            p.visible = true
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Main Street."

        if let a = aunt, companions.contains(where: { $0 === a }) {
            caption = "First stop: Bella's Boutique."
            try await walkAll(trip.indices.map { (trip[$0], Stage.boutiqueDoorX - Double($0) * 26) })
            for p in trip { p.facing = 0 }
            try await say(a, "Ooh, look at that window!", 2)
            for p in trip { p.visible = false }
            caption = "Mom helps \(a.id) try on outfit after outfit…"
            try await sleep(3.4)
            for p in trip { p.visible = true }
            a.bags = true
            try await say(a, "I got three new outfits!", 2.2)
            try await say(mom, "You look so pretty, sis!", 2)
        }

        if errands {
            caption = "Next stop: the Fresh Market for groceries."
            try await walkAll(trip.indices.map { (trip[$0], Stage.storeDoorX - Double($0) * 26) })
            for p in trip { p.facing = 0 }
            for p in trip { p.visible = false }
            try await sleep(2.8)
            for p in trip { p.visible = true }
            mom.bags = true
            cash -= Self.groceries
            cashPop = ("-$\(Self.groceries) groceries", .now, Stage.storeDoorX)
            sound.ching()
            caption = "Mom buys $\(Self.groceries) worth of groceries."
            try await sleep(2.2)

            caption = "Last stop: First National Bank."
            try await walkAll(trip.indices.map { (trip[$0], Stage.bankDoorX - Double($0) * 26) })
            for p in trip { p.facing = 0 }
            mom.visible = false
            try await sleep(2.4)
            mom.visible = true
            // Mom keeps enough cash on hand to cover tonight's table and banks the rest — or takes some out if she's short.
            let extra = cash - CasinoGame.startCash
            if extra > 0 {
                bank += extra
                cash -= extra
                cashPop = ("+$\(extra) deposited", .now, Stage.bankDoorX)
                caption = "Mom deposits $\(extra). The bank account has $\(bank)."
                sound.ching()
                try await say(mom, "$\(extra) in the bank, and $\(cash) to run tonight's table!", 2.6)
            } else if extra < 0 && bank > 0 {
                let take = min(bank, -extra)
                bank -= take
                cash += take
                cashPop = ("-$\(take) withdrawn", .now, Stage.bankDoorX)
                caption = "Nothing to deposit today — Mom takes out $\(take) so the table has enough cash. The bank account has $\(bank)."
                try await say(mom, "A slow night — but there's still $\(bank) in the bank.", 2.6)
            } else {
                caption = "Nothing extra to deposit today. The bank account has $\(bank)."
                try await say(mom, "Nothing to deposit today. Maybe tomorrow!", 2.4)
            }
            if companions.isEmpty { try await visitCustoms() }
        }

        if let a = aunt, companions.contains(where: { $0 === a }) {
            let sister = a.id.replacingOccurrences(of: "Aunt ", with: "")
            try await say(a, "I'm not done shopping yet! I'll meet you back at the house in a little while.", 3)
            try await say(mom, "Take your time, \(sister) — we'll have a surprise for you.", 2.6)
            try await say(a, "A surprise? Ooh, I can't wait!", 2)
            caption = "\(a.id) keeps shopping. She'll be back at the house in a little while."
            try await walk(a, to: Stage.W + 60, speed: 150)
            a.visible = false
            a.bags = false
            awayAunt = a
            aunt = nil
        }
        try await sleep(0.6)
    }

    /// What Mom spends on groceries every morning.
    private static let groceries = 40

    private static let visitors: [(aunt: String, cousin: String, hair: RGB, style: HairStyle, shirt: RGB, cousinHair: RGB, cousinStyle: HairStyle)] = [
        ("Sharon", "Kayla", RGB(r: 0.40, g: 0.24, b: 0.12), .bob, RGB(r: 0.85, g: 0.30, b: 0.45), RGB(r: 0.45, g: 0.28, b: 0.14), .pigtails),
        ("Joanne", "Brooke", RGB(r: 0.92, g: 0.78, b: 0.42), .ponytail, RGB(r: 0.30, g: 0.55, b: 0.85), RGB(r: 0.92, g: 0.78, b: 0.42), .ponytail),
        ("Michelle", "Megan", RGB(r: 0.20, g: 0.12, b: 0.08), .curly, RGB(r: 0.95, g: 0.60, b: 0.20), RGB(r: 0.20, g: 0.12, b: 0.08), .curly),
        ("Patty", "Hannah", RGB(r: 0.75, g: 0.32, b: 0.14), .long, RGB(r: 0.35, g: 0.65, b: 0.45), RGB(r: 0.75, g: 0.32, b: 0.14), .bob),
    ]

    /// Mom's sister and her little girl, a different pair each visit.
    private static func makeVisitors(_ n: Int) -> (Person, Person) {
        let v = visitors[n % visitors.count]
        let skin = RGB(r: 0.96, g: 0.80, b: 0.68)
        let aunt = Person("Aunt \(v.aunt)", height: 154, skin: skin, hair: v.hair, style: v.style,
                          shirt: v.shirt, pants: RGB(r: 0.28, g: 0.28, b: 0.42), x: Stage.doorX)
        let cousin = Person(v.cousin, height: 108, headScale: 0.15, skin: skin, hair: v.cousinHair, style: v.cousinStyle,
                            shirt: RGB(r: 0.98, g: 0.70, b: 0.30), pants: RGB(r: 0.95, g: 0.55, b: 0.70), kid: true, x: Stage.doorX)
        return (aunt, cousin)
    }

    /// Visit mornings, while Mom and the aunt are out shopping: the girls show their cousin the machine, and she becomes an alien.
    private func cousinTransforms() async throws {
        guard let c = cousin else { return }
        let (ava, rosie) = (ava, rosie)
        caption = "With Mom and \(aunt?.id ?? "her aunt") out shopping, the girls have something to show their cousin…"
        for p in [ava, rosie] { p.facing = 1 }
        c.facing = -1
        try await look(at: Stage.shot(centerX: 800, height: 260))
        try await say(rosie, "\(c.id), want to see something REALLY cool?", 2.4)
        try await say(c, "Yes! What is it?", 1.6)
        try await say(ava, "There's a poker machine in our cottage casino with mini saucers that turn you into a Roswell alien!", 3)
        try await say(rosie, "It wears off later — and you get to pick your color!", 2.6)
        try await say(c, "No way! I want to try it!", 2)
        caption = "The girls lead \(c.id) out back to the cottage casino."
        try await look(at: Stage.full)
        try await walkAll([(rosie, Stage.watchX[0]), (ava, Stage.watchX[2]), (c, 400)], speed: 150)
        for p in [ava, rosie, c] { p.facing = -1 }
        try await look(at: Stage.boothView)
        try await say(rosie, "Stand right there — the mini saucer does the rest!", 2.4)
        try await saucers([c])
        try await mirror(c)
        try await say(c, "I'm a \(c.alienColor.name) alien! Look at my big eyes!", 2.6)
        try await sayAll([ava, rosie], "You look awesome!", 1.8)
        try await say(c, "Wait till Mommy sees me!", 2)
        try await snap(c)
        caption = "Everyone heads back to the living room to wait for Mom."
        try await look(at: Stage.full)
        try await walkAll([(c, 715), (ava, 745), (rosie, 775)], speed: 150)
        for p in [ava, rosie] { p.facing = 0 }
        c.facing = 0
    }

    /// Visit mornings, after the cousin's change and while Mom and the aunt are still shopping: Ava runs the cottage casino
    /// in Mom's place and Rosie (you) joins the table; the cousin watches. The girls change back when they come home.
    private func girlsHostGame() async throws {
        guard let c = cousin else { return }
        let (ava, rosie) = (ava, rosie)
        let girls = [ava, rosie]
        let start = cash + bank
        try await look(at: Stage.shot(centerX: 745, height: 260))
        caption = "Mom and \(aunt?.id ?? "her sister") are still out shopping…"
        try await say(rosie, "Mom's going to be gone a while… let's open up the casino ourselves!", 2.8)
        try await say(ava, "I'll run the table, just like Mom!", 2.2)
        try await say(c, "Can I watch? Please?", 1.8)
        try await sayAll(girls, "Of course!", 1.6)

        // The girls go under the mini saucers first — everybody in the casino is an alien.
        try await summonSaucers(girls)
        try await say(c, "Now we're ALL aliens!", 2)
        try await look(at: Stage.full)
        try await walkAll([(ava, Stage.homeFamilyX[1]), (rosie, Stage.homeFamilyX[2]), (c, Stage.homeCousinX)], speed: 150)
        for p in girls { p.facing = 0 }
        c.facing = -1

        hostOverride = ava
        hostName = ava.id
        defer {
            hostOverride = nil
            hostName = mom.id
        }
        try await look(at: Stage.full)
        caption = "Ava's running the casino! Pick the game she deals in the cottage."
        let pick = await withCheckedContinuation { cont in
            gamePick = cont
            choosingGame = true
        }
        try Task.checkCancellation()
        guard let pick else { return }
        result = nil
        try await toCasino(for: pick.game)
        try await runTable(pick.game, daughterHouse: pick.game.isMoney && pick.daughterHouse)
        try await backHome()
        let net = cash + bank - start
        girlsGame = (pick.game.name, net)
        // The cousin helped out, so the morning's take counts toward her quarter.
        visitProfit += net
        try await look(at: Stage.shot(centerX: 770, height: 270))
        try await say(ava, net > 0 ? "We made $\(net) for the house!" : net == 0 ? "We broke even!" : "We lost $\(-net)… oops!", 2.4)
        caption = "Back in the house — and the girls and \(c.id) all stay Roswell aliens, to surprise their moms!"
        try await say(rosie, "Let's stay aliens till Mom gets home!", 2.2)
        try await say(c, "Wait till Mommy sees me!", 2)
        for p in girls { p.facing = 0 }
    }

    /// Midday on a visit day the aunt comes back to the house, gets a shock — her daughter is an alien — and her daughter
    /// takes her to the Roswell of Poker for a mini saucer of her own. Then she tags along for the second half of the day.
    private func auntReturns() async throws {
        guard let a = awayAunt, let c = cousin else { return }
        let (mom, ava, rosie) = (mom, ava, rosie)
        let sister = a.id.replacingOccurrences(of: "Aunt ", with: "")
        _ = ava
        awayAunt = nil
        aunt = a
        try await look(at: Stage.full)
        try await walkAll(zip(cast, Stage.homeFamilyX).map { ($0, $1) } + [(c, Stage.homeCousinX)])
        for p in cast { p.facing = 1 }
        c.facing = 1
        (a.x0, a.x1, a.moveDur, a.facing) = (Stage.doorX, Stage.doorX, 0, -1)
        a.mood = .happy
        a.bags = true
        a.visible = true
        sound.ding()
        caption = "\(a.id) gets back to the house with her shopping bags…"
        doorOpenUntil = .now + 2.4
        try await walk(a, to: Stage.doorX + 40)
        a.facing = -1
        try await look(at: Stage.shot(centerX: 790, height: 300))
        try await say(a, "I'm back! I bought out half the mall—", 2.2)
        a.mood = .shocked
        caption = "SURPRISE! \(a.id) can't believe her eyes!"
        try await say(a, "AAAH! Who ARE you all?!", 2.2)
        try await say(c, "Mommy, it's ME — \(c.id)!", 2)
        try await say(a, "\(c.id)?! You're \(c.alienColor.name)! And your eyes are HUGE!", 2.8)
        try await say(mom, "Surprise, sis! It's the poker machine out in our cottage casino — it turns you into a Roswell alien!", 3)
        try await say(rosie, "We ran a game in the casino this morning — and \(c.id) helped!", 2.6)
        a.mood = .happy
        a.bags = false
        try await say(a, "Well… if you can't beat 'em, join 'em! Turn me into one too!", 2.8)
        try await say(c, "Yay! A mini saucer does it, Mommy!", 2.2)
        try await say(a, "A mini saucer? Where would I even find a mini saucer?", 2.6)
        // The machine out in the cottage hears her.
        caption = "A deep voice booms all the way from the cottage: “Did someone say mini saucer?”"
        machineVoice.speak("Did someone say mini saucer?", host: .roswell)
        try await sleep(3)
        a.mood = .shocked
        try await say(a, "Who said that?!", 1.8)
        try await say(rosie, "That's the Roswell of Poker! Here it comes, Aunt \(sister)!", 2.4)
        caption = "A mini saucer zooms out of the cottage, across the yard and into the house — straight for \(a.id)!"
        try await saucers([a], at: [a.x(at: .now)], firstTime: true, view: Stage.shot(centerX: 790, height: 300), flight: BoothRun.longFlight)
        try await say(c, "Go look in the bathroom mirror, Mommy!", 2.2)
        try await bathroomMirror(a, "AAAH! Is that really ME?! I'm \(a.alienColor.name)!")
        try await say(a, "Look at me — I'm a real Roswell alien!", 2.4)
        try await look(at: Stage.full)
        try await walkAll([(a, Stage.homeAuntX), (c, Stage.homeCousinX)], speed: 150)
        try await look(at: Stage.shot(centerX: 820, height: 280))
        try await say(c, "You look awesome, Mommy!", 2)
        try await say(mom, "And \(sister) — this afternoon you're both coming to the casino with us!", 2.8)
        try await snap(a)
        a.facing = -1
        c.facing = -1
    }

    /// At the end of the night the cousin who tagged along gets a quarter of the profit; then she and her mom go home,
    /// and the aunt stays an alien until she gets home.
    private func payCousin(_ profit: Int) async throws {
        guard let a = aunt, let c = cousin else { return }
        let mom = mom
        let share = max(0, profit / 4)
        if share > 0 {
            try await say(mom, "\(c.id), you helped out all day — here's your quarter of the profit: $\(share)!", 3)
            cash -= share
            cousinsPaid += share
            cashPop = ("-$\(share) to \(c.id)", .now, c.x(at: .now))
            sound.ching()
            try await say(c, "$\(share)! Thank you, Auntie!", 2.2)
        } else {
            try await say(mom, "No profit to share tonight, \(c.id) — sorry, sweetie!", 2.6)
            try await say(c, "That's okay! It was still fun!", 2)
        }
        caption = "\(a.id) and \(c.id) head for the front door."
        try await walkAll([(a, Stage.doorX + 30), (c, Stage.doorX + 52)], speed: 110)
        a.facing = -1
        c.facing = -1
        try await look(at: Stage.shot(centerX: 800, height: 300))
        caption = "\(a.id) heads home still a Roswell alien — the change will wear off when she gets there."
        try await say(a, "Thanks, sis! I'll turn back when I get home.", 2.4)
        try await say(c, "Bye, cousins!", 1.6)
        nightHouseholds.append([a, c])
        doorOpenUntil = .now + 2
        try await walkAll([(a, Stage.doorX), (c, Stage.doorX)], speed: 110)
        aunt = nil
        cousin = nil
        try await look(at: Stage.shot(centerX: 770, height: 270))
    }

    /// The change wears off on its own: everyone in `group` slowly turns human again, and their clothes come back.
    private func changeBack(_ group: [Person], over seconds: Double = 5) async throws {
        let t0 = Date.now
        for p in group {
            p.alien = false
            (p.changeFrom, p.changeTo) = (1, 0)
            p.changeT0 = t0
            p.changeDur = seconds
        }
        sound.sparkle(true)
        try await sleep(seconds)
        sound.sparkle(false)
        sound.ding()
        try await sleep(0.6)
    }

    /// One full game in the cottage casino: a daughter joins (you play her), Mom recruits players out front — some with their own
    /// daughters — everyone who's agreed is taken into the casino to stand by the Roswell of Poker, the mini saucers change them,
    /// they buy in (moneymakers only), and play. At a moneymaker table the daughter either plays or, with `daughterHouse`, banks while Mom deals.
    private func runTable(_ game: CasinoGame, daughterHouse: Bool) async throws {
        let mom = tableHost
        let girls = helpers
        let daughter = girls.randomElement()!
        let watchers = girls.filter { $0 !== daughter }
        let house = game.isMoney ? (daughterHouse ? daughter : mom) : nil
        let daughterPlays = !daughterHouse
        // Mom adds up to three people to a moneymaker table (the daughter doesn't count); fun tables fill their seats.
        let need = game.isMoney ? CasinoGame.maxPlayers : game.funSeats - 2
        let startCash = cash

        caption = daughterPlays ? "\(daughter.id) wants to play \(game.name) — and you're playing her!" : "\(daughter.id) is the house tonight — \(hostName) will deal."
        try await say(daughter, daughterPlays ? "\(hostName), can I play this one? Pleeease?" : "Can I be the house, \(hostName)?", 2.4)
        try await say(mom, daughterPlays ? "Sure, sweetie — take a seat! I'll find the rest." : "You're the house! I'll deal the cards.", 2.4)

        mom.atTable = false
        felt = []
        board = nil
        // Mom and the girls go out front and ask people strolling down the street.
        try await goOutside()

        // Each woman (and any daughter she brought) takes the next waiting spots by the booth.
        var players: [Person] = []
        // A girl who becomes an alien plays if there was a seat for her; otherwise she watches, alien and all.
        var kids: [(kid: Person, mother: Person, alien: Bool, plays: Bool)] = []
        var slot = [ObjectIdentifier: Int]()
        var asked = 0
        // At a moneymaker table a girl who joins her mom takes up a spot too: the two of them count as 2.
        var filled = 0
        // A moneymaker table stops at three joiners or six passers-by asked, whichever comes first;
        // if the first five all said no, the sixth says yes so there's a game. Fun tables keep asking until every seat is filled.
        while filled < need && !(game.isMoney && asked >= CasinoGame.maxAsked) {
            asked += 1
            let next = slot.count
            let mustSayYes = game.isMoney ? asked == CasinoGame.maxAsked && players.isEmpty : asked >= 10
            if let (p, kid, alien, plays) = try await askPasserby(game, slot: next, filled: filled, need: need, mustSayYes: mustSayYes) {
                players.append(p)
                // A girl who joins her mom takes a seat of her own, so the two of them count as 2.
                filled += 1 + (plays ? 1 : 0)
                slot[ObjectIdentifier(p)] = next
                if let kid {
                    kids.append((kid, p, alien, plays))
                    slot[ObjectIdentifier(kid)] = next + 1
                }
            }
        }
        customers = players + kids.map(\.kid)
        try await comeInside(slot: slot)
        // An empty moneymaker seat goes to one of the sisters who'd otherwise watch; she's already an alien, and plays with family money.
        var fillers: [Person] = []
        if filled < need {
            caption = "\(hostName) has asked \(asked) passers-by — time to play with \(filled == 1 ? "one guest" : "\(filled) guests")."
            try await say(mom, "That's enough asking — let's play!", 2.2)
            if game.isMoney {
                fillers = Array(watchers.shuffled().prefix(need - filled))
                for f in fillers {
                    try await say(f, "There's an empty seat — can I take it, \(hostName)?", 2.4)
                    try await say(mom, "Sure, \(f.id)! The house covers your buy-in.", 2.4)
                }
                if !fillers.isEmpty {
                    caption = "\(Self.list(fillers.map(\.id))) \(fillers.count == 1 ? "takes the empty seat" : "take the empty seats")."
                    filled += fillers.count
                }
            }
        }
        try await say(mom, players.count == 1 ? "Welcome to our cottage casino! One quick stop before we deal — right over by the poker machine."
                                              : "Welcome to our cottage casino, ladies! One quick stop before we deal — right over by the poker machine.", 3)

        // Everyone who's agreed stands by the machine, three at a time, and the mini saucers change them: each woman, then her daughter.
        caption = "Players are ready — first stop, the Roswell of Poker!"
        try await look(at: Stage.full)
        try await walkAll([(mom, Stage.boothSideX[0])] + zip(girls, Stage.boothSideX.dropFirst()).map { ($0, $1) })
        for p in cast { p.facing = -1 }
        var goingAlien = players.flatMap { p in [p] + kids.filter { $0.mother === p && $0.alien }.map(\.kid) }
        func transform(_ list: [Person], surprise: Bool = false) async throws {
            guard !list.isEmpty else { return }
            // Every guest is changed at the same time: one mini saucer each.
            caption = list.count == 1 ? "\(list[0].id) steps up to the machine."
                                      : "Everyone lines up beside the Roswell of Poker — a mini saucer for each of them, all at once!"
            try await saucers(list, at: Stage.machineSpots(list.count), surprise: surprise)
            // The mirror fits three at a time.
            for start in stride(from: 0, to: list.count, by: 3) {
                let group = Array(list[start..<min(start + 3, list.count)])
                try await mirror(group)
                if surprise {
                    // The surprise sinks in: wide eyes and dropped jaws, in the room and in the glass.
                    for p in group { p.mood = .shocked }
                    caption = group.count == 1 ? "\(group[0].id) can't believe her eyes!" : "They can't believe their eyes!"
                    var used: Set<String> = []
                    for p in group {
                        let lines = p.isKid ? ["Whoa! Mommy, look at me!", "Is that ME?!", "Eeek! My head is HUGE!"]
                                            : ["So THAT was the surprise?!", "I did NOT see that coming!", "Nobody told me I'd be an alien!",
                                               "Oh my gosh — is that really me?!", "Wh-what happened to my face?!"]
                        let line = lines.filter { !used.contains($0) }.randomElement() ?? lines[0]
                        used.insert(line)
                        try await say(p, line, 2.4)
                    }
                    try await sleep(0.6)
                    for p in group { p.mood = .happy }
                }
                for p in group {
                    try await say(p, p.isKid ? ["Look, Mommy! I'm an alien!", "My eyes are SO big!", "I look like Rosie!"].randomElement()!
                                             : ["Wow, I'm \(p.alienColor.name)! Deal me in!", "I look out of this world! Let's play!", "That was quick! Now let's play some cards!",
                                                "Alien and ready to win!"].randomElement()!, 2.4)
                }
                try await look(at: Stage.full)
                try await walkAll(group.map { ($0, Stage.waitX[slot[ObjectIdentifier($0)]!]) })
                for p in group { p.facing = 1 }
            }
        }
        try await transform(goingAlien, surprise: true)

        // A girl who said no gets a second chance once she's seen everyone else turned.
        // She plays if a spot is still open; otherwise she watches as an alien.
        var secondChance: [Person] = []
        for k in kids.indices where !kids[k].alien {
            let (kid, mother) = (kids[k].kid, kids[k].mother)
            caption = "\(kid.id) watched everyone turn into aliens…"
            try await look(at: Stage.full)
            rosie.facing = 1
            try await say(rosie, "\(kid.id), now that you've seen everybody change — want another chance to be a Roswell alien?", 3)
            if Double.random(in: 0...1) < 0.5 {
                try await say(kid, ["Okay — I changed my mind! Can I, Mommy?", "It looks fun! Yes please!", "I want to be green too!"].randomElement()!, 2.4)
                try await say(mother, "Go for it, sweetie!", 2)
                kids[k].alien = true
                if filled < need {
                    kids[k].plays = true
                    filled += 1
                }
                secondChance.append(kid)
            } else {
                try await say(kid, ["Still no thanks!", "Nope, I'll just watch.", "Maybe next time!"].randomElement()!, 2.2)
                try await say(mother, "That's fine, honey. You can watch with the girls.", 2.2)
            }
        }
        if !secondChance.isEmpty {
            try await transform(secondChance)
            goingAlien += secondChance
        }

        // To the table. Each girl who became an alien sits beside her mom and plays; the daughter takes a random seat.
        // Girls who stayed human watch with the sisters.
        caption = "Everyone takes a spot at the \(game.name) table."
        // Girls who became aliens without a seat watch too.
        let guests = players.flatMap { p in [p] + kids.filter { $0.mother === p && $0.plays }.map(\.kid) }
        var seated = guests
        for f in fillers { seated.insert(f, at: Int.random(in: 0...seated.count)) }
        if daughterPlays { seated.insert(daughter, at: Int.random(in: 0...seated.count)) }
        let family = { (p: Person) in p === daughter || fillers.contains { $0 === p } }
        let spots = Stage.spots(seated.count)
        let audience = watchers.filter { w in !fillers.contains { $0 === w } } + kids.filter { !$0.plays }.map(\.kid)
        var moves = [(mom, Stage.dealerX)] + zip(seated, spots).map { ($0, $1) }
            + zip(audience, Stage.girlsTableX).map { ($0, $1) }
        if !daughterPlays { moves.append((daughter, Stage.houseX)) }
        try await walkAll(moves)
        for p in seated + [mom] + (daughterPlays ? [] : [daughter]) {
            p.atTable = true
            p.facing = 0
        }
        for g in audience { g.facing = -1 }
        try await look(at: Stage.tableShot)
        you = daughterPlays ? daughter.id : nil
        if daughterPlays { caption = "You're \(daughter.id). Your cards show up under the table." }

        // Buy-ins. Moms pay for their girls; the daughter's comes out of the family's cash and her winnings go back in.
        let buyIns = guests.count * CasinoGame.buyIn
        var familyBuyIn = 0
        var setupFee = 0
        if game.isMoney {
            setupFee = CasinoGame.setupFee
            caption = "\(hostName) spends $\(setupFee) on fresh cards and chips for the \(game.name) table."
            cash -= setupFee
            cashPop = ("-$\(setupFee)", .now, Stage.dealerX)
            sound.ching()
            try await sleep(2)
            try await say(mom, "Buy-in is $\(CasinoGame.buyIn) each. Play till you double it — or run out!", 2.6)
            if !daughterPlays { try await say(daughter, "I'm the house! Place your bets, ladies!", 2.2) }
            // The daughter's chips come from the house, and whatever she finishes with goes back to it.
            let net = buyIns - ((daughterPlays ? 1 : 0) + fillers.count) * CasinoGame.buyIn
            cash += net
            cashPop = (net >= 0 ? "+$\(net)" : "-$\(-net)", .now, Stage.dealerX)
        } else {
            try await say(mom, "No buy-in, ladies — this one's just for fun! The winner gets bragging rights.", 2.8)
        }
        if game.isMoney {
            if let (kid, mother, _, _) = kids.first(where: \.plays) {
                try await say(mother, "And here's $\(CasinoGame.buyIn) for \(kid.id) — she's playing too!", 2.4)
            }
            sound.ching()
        }
        try await sleep(1.4)

        var finishes: [String]
        var cashOuts: [Int]
        var winners: [String] = []
        var hands = 0
        var familyCashOut = 0
        var daughterFinish: String
        let mySeat = seated.firstIndex { $0 === daughter }
        if game.isMoney, let house {
            (finishes, cashOuts, hands) = try await playMoney(game, seated, house: house, human: mySeat)
            // A daughter at the table plays with family money, so only the guests' chips leave the family.
            var paid = 0
            var guestCash: [Int] = []
            var daughterCash = 0
            for (p, c) in zip(seated, cashOuts) {
                if family(p) { familyCashOut += c } else { paid += c; guestCash.append(c) }
                if p === daughter { daughterCash = c }
            }
            daughterFinish = mySeat.map { finishes[$0] } ?? "was the house"
            for f in fillers {
                if let i = seated.firstIndex(where: { $0 === f }) { daughterFinish += " · \(f.id) filled a seat and \(finishes[i])" }
            }
            finishes = seated.indices.filter { !family(seated[$0]) }.map { finishes[$0] }
            cashOuts = guestCash
            familyBuyIn = ((daughterPlays ? 1 : 0) + fillers.count) * CasinoGame.buyIn
            try await say(house, "Time to cash out, ladies!", 2)
            cash += familyCashOut - paid
            cashPop = (familyCashOut - paid >= 0 ? "+$\(familyCashOut - paid)" : "-$\(paid - familyCashOut)", .now, Stage.dealerX)
            if daughterPlays && daughterCash > CasinoGame.buyIn {
                try await say(daughter, "I won $\(daughterCash - CasinoGame.buyIn) — it all goes to the house!", 2.4)
            }
            sound.ching()
            let net = buyIns - paid
            caption = net >= 0 ? "The house (\(house.id)) keeps $\(net) of the $\(buyIns) the guests bought in for."
                               : "The guests beat the house (\(house.id)) by $\(-net)!"
            try await sleep(2.4)
        } else {
            let table = [mom] + seated
            let scores: [Int]
            (scores, hands) = try await playFun(game, table, human: mySeat.map { $0 + 1 })
            let won = Tricks.winners(game, scores: scores, hands: hands) ?? [scores.indices.max { scores[$0] < scores[$1] }!]
            winners = won.map { table[$0].id }
            // Nothing to pay out: it's just for fun.
            let family = won.filter { $0 == 0 || table[$0] === daughter }
            let guestIdx = table.indices.filter { $0 > 0 && table[$0] !== daughter }
            cashOuts = guestIdx.map { _ in 0 }
            finishes = guestIdx.map { "\(scores[$0]) pts" + (won.contains($0) ? " · won!" : "") }
            daughterFinish = "\(scores[table.firstIndex { $0 === daughter }!]) pts"
            caption = "\(winners.joined(separator: " & ")) win\(won.count == 1 ? "s" : "") the game!"
            sound.ding()
            if !family.isEmpty {
                let star = table[family[0]]
                try await say(star, star === mom ? (won.count == 1 ? "\(hostName) wins! Ha!" : "We did it, partner!") : "I WON! I won, \(hostName)!", 2.2)
            } else {
                try await say(table[won[0]], ["Woo-hoo! I win!", "Ha! Pay up, ladies!", "Best game ever!"].randomElement()!, 2.2)
                try await say(mom, "Well played!", 1.8)
            }
            try await sleep(1)
        }
        you = nil
        myHand = []
        humanRow = nil

        // Thank-yous, then off they go, green, with their daughters.
        try await say(players.randomElement()!, ["Thanks for the game! I love being an alien!", "What a night! See you next time!",
                                                 "Alien and lucky — best casino ever!"].randomElement()!, 2.6)
        try await sayAll(girls, "Bye!", 1.4)
        // Everyone who became an alien and played, in seat order; girls note who brought them.
        var album = guests.indices.map { i -> TablePlayer in
            let p = guests[i]
            let mother = kids.first { $0.kid === p }?.mother
            return TablePlayer(spec: PersonSpec(p), buyIn: game.isMoney ? CasinoGame.buyIn : 0, cashOut: cashOuts[i],
                               finish: finishes[i] + (mother.map { " · came with \($0.id)" } ?? ""))
        }
        // Girls who became aliens but had no seat left watched the game.
        album += kids.filter { $0.alien && !$0.plays }.map {
            TablePlayer(spec: PersonSpec($0.kid), buyIn: 0, cashOut: 0, finish: "watched as an alien · came with \($0.mother.id)")
        }
        let record = GameRecord(date: .now, game: game, asked: asked, players: album,
                                hands: hands, winners: winners, momBuyIn: familyBuyIn, momCashOut: familyCashOut,
                                startCash: startCash, endCash: cash,
                                house: house?.id, daughter: daughter.id, daughterFinish: daughterFinish, setupFee: setupFee)
        self.album.add(record)
        result = record
        felt = []
        board = nil
        tableSeats = []
        tableGroups = []
        // The guests head for the exit still aliens; the change wears off once they get home after the family ends the night.
        caption = "The players head for the exit…"
        try await look(at: Stage.full)
        let leaving = players.flatMap { p in [p] + kids.filter { $0.mother === p }.map(\.kid) }
        for p in leaving { p.atTable = false }
        // The daughter rejoins her sisters.
        daughter.atTable = false
        _ = beginWalk(daughter, to: Stage.girlsTableX[2], speed: 110)
        for (i, f) in fillers.enumerated() {
            f.atTable = false
            _ = beginWalk(f, to: Stage.girlsTableX[i], speed: 110)
        }
        try await walkAll(leaving.indices.map { (leaving[$0], Stage.exitX[min($0, Stage.exitX.count - 1)]) }, speed: 110)
        daughter.facing = -1
        for p in leaving { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 1060, height: 380))
        caption = "Out the cottage door they go — still Roswell aliens! The change wears off when they get home."
        for p in goingAlien.prefix(2) {
            try await say(p, p.isKid ? ["I get to stay an alien all the way home!", "Wait till my friends see me!", "That was SO cool!"].randomElement()!
                                     : ["I'm going home a Roswell alien!", "Won't the neighbors be surprised!", "What a night! Same time next week?"].randomElement()!, 2.2)
        }
        nightHouseholds += players.map { p in [p] + kids.filter { $0.mother === p }.map(\.kid) }
        mom.atTable = false

        caption = "Off they go, aliens and happy!"
        for p in leaving { _ = beginWalk(p, to: 1320, speed: 110) }
        try await sleep((1320 - Stage.exitX.last!) / 110)
        customers = []
        caption = "The \(game.name) game is saved in the album."
    }

    /// Out the back door and across the yard to the cottage casino, where the game is played.
    private func toCasino(for game: CasinoGame) async throws {
        let mom = tableHost
        caption = "\(game.name) it is — out back to the \(CasinoGame.casinoName)!"
        try await say(mom, "Come on, girls — let's open up the casino!", 2.2)
        try await walkAll(([mom] + helpers).enumerated().map { ($1, Stage.backDoorX + Double($0) * 20) }
                          + [cousin, aunt].compactMap { $0 }.map { ($0, Stage.backDoorX + 60) }, speed: 150)
        fadeT0 = .now
        try await sleep(0.5)
        atCasino = true
        screen = "READY"
        for (p, x) in zip([mom] + helpers, [Stage.dealerX] + Stage.girlsTableX) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
        }
        if let cousin { (cousin.x0, cousin.x1, cousin.moveDur, cousin.facing) = (Stage.girlsTableX[8], Stage.girlsTableX[8], 0, -1) }
        if let aunt { (aunt.x0, aunt.x1, aunt.moveDur, aunt.facing) = (Stage.girlsTableX[7], Stage.girlsTableX[7], 0, -1) }
        mom.atTable = true
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "The \(CasinoGame.casinoName)! The Roswell of Poker glows in the corner, right next to \(hostName)'s card table."
        try await sleep(2.2)
    }

    /// After a pick's two games: the family closes up the cottage casino and heads back into the house.
    private func backHome() async throws {
        caption = "Time to close up the casino and head back to the house."
        try await sleep(1.4)
        fadeT0 = .now
        try await sleep(0.5)
        atCasino = false
        screen = "READY"
        felt = []
        board = nil
        for p in cast { p.atTable = false }
        for (p, x) in zip(cast, Stage.homeFamilyX) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
        }
        if let cousin { (cousin.x0, cousin.x1, cousin.moveDur, cousin.facing) = (Stage.homeCousinX, Stage.homeCousinX, 0, -1) }
        if let aunt { (aunt.x0, aunt.x1, aunt.moveDur, aunt.facing) = (Stage.homeAuntX, Stage.homeAuntX, 0, -1) }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Back in the house."
        try await sleep(1.4)
    }

    /// Mom and the girls step out front and ask people walking down the street. The aunt and cousin wait in the casino.
    private func goOutside() async throws {
        let mom = tableHost
        caption = "\(hostName) and the girls head out front to find players."
        try await say(mom, "Let's go find some players, girls!", 2)
        fadeT0 = .now
        try await sleep(0.5)
        inNeighborhood = true
        outsideHome = true
        for p in [aunt, cousin].compactMap({ $0 }) { p.visible = false }
        for p in cast { p.atTable = false }
        for (p, x) in zip([mom] + helpers, [Stage.askX] + Stage.girlsAskX) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Out on the sidewalk, \(hostName) waits for people to stroll by."
        try await look(at: Stage.shot(centerX: 1020, height: 300))
    }

    /// Everyone who said yes is taken out back into the cottage casino, and waits by the Roswell of Poker.
    private func comeInside(slot: [ObjectIdentifier: Int]) async throws {
        let mom = tableHost
        caption = "Everyone heads around back to the cottage casino."
        try await sleep(1.2)
        fadeT0 = .now
        try await sleep(0.5)
        inNeighborhood = false
        outsideHome = false
        doorOpenUntil = .distantPast
        // The aunt is still out shopping while the girls run the casino on their own.
        for p in [hostOverride == nil ? aunt : nil, cousin].compactMap({ $0 }) { p.visible = true }
        for (p, x) in zip([mom] + helpers, Stage.boothSideX) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1)
        }
        for p in customers {
            let x = slot[ObjectIdentifier(p)].map { Stage.waitX[$0] } ?? Stage.waitX[0]
            p.says = nil
            p.visible = true
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1)
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Inside the \(CasinoGame.casinoName)."
        try await sleep(1)
    }

    /// A woman strolls by, sometimes with her daughter, and Mom asks her to play.
    /// Returns her, the girl if she brought one, whether the girl wants to be an alien too, and whether she gets a seat.
    /// She's strolling down the street out front; if she says yes she goes in and around back to the cottage casino.
    private func askPasserby(_ game: CasinoGame, slot: Int, filled: Int, need: Int, mustSayYes: Bool) async throws -> (Person, Person?, Bool, Bool)? {
        let (mom, ava, rosie) = (tableHost, ava, rosie)
        let p = Person.customer(nextWomanName(), kid: false, x: 1300)
        let kid = Double.random(in: 0...1) < 0.35 ? Person.customer(nextKidName(), kid: true, x: 1335) : nil
        customers.append(p)
        if let kid { customers.append(kid) }
        let stroll = 85.0
        _ = beginWalk(p, to: -150, speed: stroll)
        if let kid { _ = beginWalk(kid, to: -115, speed: stroll) }
        try await sleep((1300 - Stage.stopX) / stroll)
        stop(p)
        if let kid { stop(kid) }
        mom.facing = 1

        if game.isMoney {
            try await say(mom, "Hi! Want to play \(game.name) at our cottage casino out back? Buy-in is $\(CasinoGame.buyIn)!", 2.8)
        } else {
            try await say(mom, "Hi! Want to play \(game.name) at our cottage casino out back? No buy-in — it's just for fun!", 2.8)
        }
        guard mustSayYes || Double.random(in: 0...1) < 0.55 else {
            try await say(p, ["No thanks, I'm not much for cards.", "Not tonight, sorry!", "Maybe another time.",
                              "I'm just out walking the dog, thanks!",
                              "I'm meeting friends, but thanks!"].randomElement()!, 2.4)
            caption = "\(p.id) keeps walking."
            _ = beginWalk(p, to: -150, speed: stroll)
            if let kid { _ = beginWalk(kid, to: -115, speed: stroll) }
            try await sleep(1.2)
            Task { [weak self] in
                try? await Task.sleep(for: .seconds((Stage.stopX + 150) / stroll))
                self?.customers.removeAll { $0 === p || $0 === kid }
            }
            return nil
        }
        try await say(p, ["Ooh, I love \(game.name)! Count me in!", "Sure, why not!", "Deal me in!",
                          "I haven't played \(game.name) in ages — I'm in!", "Sounds like fun! I'm in!"].randomElement()!, 2.6)
        var alien = false
        // A girl joining counts toward the table's limit, so she only gets a seat if there's room for two.
        // When the seats run out she can still be an alien — she just watches the game.
        let roomForHer = need - filled >= 2
        if let kid {
            // Her daughter tags along; Rosie asks if she'd like to be an alien too, and her mom decides with her.
            rosie.facing = 1
            try await say(rosie, roomForHer ? "Hi \(kid.id)! Want to come along and play too?"
                                            : "Hi \(kid.id)! The table's full — but you can come along and watch with us! Want to?", 2.8)
            if Double.random(in: 0...1) < 0.65 {
                try await say(kid, ["Yes! Can I, Mommy? Please?", "Ooh, yes! Me too!", "Yay! I want to come!"].randomElement()!, 2.4)
                try await say(p, "If you really want to, sweetie — sure!", 2.4)
                alien = true
            } else {
                try await say(kid, ["No thanks, I'm shy.", "Nope! I'll just watch.", "Maybe when I'm bigger."].randomElement()!, 2.4)
                try await say(p, "That's okay, honey. You can watch the game with the girls.", 2.6)
            }
        } else if Bool.random() {
            try await say(rosie, "Yay! You're going to love it!", 2.2)
        } else {
            try await say(ava, "Yay! This is going to be so much fun!", 2.2)
        }
        let plays = alien && roomForHer
        let left = need - filled - 1 - (plays ? 1 : 0)
        let who = plays ? "\(p.id) and \(kid!.id) join" : alien ? "\(p.id) joins, and \(kid!.id) will watch" : "\(p.id) joins"
        caption = left <= 0 ? "\(who) — that's a full table!" : "\(who)! \(left) more spot\(left == 1 ? "" : "s") to fill."
        do {
            // She goes in through the family's house and out back to the cottage casino to wait for the game.
            try await say(mom, kid == nil ? "Great! Go on in and straight out back to the cottage!" : "Great! Go on in, you two — straight out back to the cottage!", 2.4)
            let door = Stage.familyDoorX
            let walkers = [p] + (kid.map { [$0] } ?? [])
            doorOpenUntil = .now + 60
            for (i, w) in walkers.enumerated() { _ = beginWalk(w, to: door + Double(i) * 8, speed: 120) }
            try await sleep(abs(p.x(at: .now) - door) / 120 + 0.4)
            caption = "\(walkers.map(\.id).joined(separator: " and ")) \(walkers.count == 1 ? "goes" : "go") into the house."
            for w in walkers { w.visible = false }
            try await sleep(0.4)
            doorOpenUntil = .distantPast
            return (p, kid, alien, plays)
        }
    }

    /// Hands against the house; you make your own calls at `human`'s seat.
    /// Returns each player's final line, her cash-out and how many hands were dealt.
    private func playMoney(_ game: CasinoGame, _ players: [Person], house: Person, human: Int?) async throws -> ([String], [Int], Int) {
        var chips: [Int?] = players.map { _ in CasinoGame.buyIn }
        var rows = [BoardRow(id: house.id, value: "House", note: house === tableHost ? "\(hostName) deals and banks" : "\(hostName) deals")]
            + players.map { BoardRow(id: $0.id, value: "$\(CasinoGame.buyIn)", note: "") }
        tableSeats = [house] + players
        humanRow = human.map { $0 + 1 }
        tableGroups = []
        board = TableBoard(game: game, status: "Shuffling up…", rows: rows)
        try await sleep(1)
        let table = host(human: human, seatX: Stage.spots(players.count))

        // Everyone plays until she doubles her buy-in or loses it all, then sits back.
        // The game ends once every guest (everyone but the daughter) is done.
        let goal = CasinoGame.buyIn * CasinoGame.goal
        var done = players.map { _ in false }
        let guests = players.indices.filter { $0 != human }
        var dealt = 0
        while dealt < CasinoGame.handLimit && guests.contains(where: { !done[$0] }) {
            dealt += 1
            let hand = dealt
            board?.status = "Hand \(hand) · playing to $\(goal) or broke"
            caption = "Hand \(hand): \(hostName) deals \(game.name)."
            sound.deal()
            // Players who are finished sit the hand out.
            let live = chips.indices.map { done[$0] ? nil : chips[$0] }
            let r = try await MoneyTable.play(game, chips: live, host: table)
            table.show(r.felt)
            try await sleep(1.4)

            var best: (Person, Int)?
            for (i, seat) in r.seats.enumerated() {
                guard let seat else { continue }
                chips[i]! += seat.net
                rows[i + 1].value = "$\(chips[i]!)"
                rows[i + 1].note = seat.net == 0 ? seat.note : "\(seat.net > 0 ? "+" : "-")$\(abs(seat.net)) · \(seat.note)"
                if seat.net > (best?.1 ?? 0) { best = (players[i], seat.net) }
            }
            rows[0].note = r.dealerNote
            board?.rows = rows
            if let human, let mine = r.seats[human] {
                caption = "Hand \(hand): \(r.dealerNote). You \(mine.net > 0 ? "win $\(mine.net)" : mine.net < 0 ? "lose $\(-mine.net)" : "push") — \(mine.note)."
            } else {
                caption = "Hand \(hand): \(r.dealerNote)."
            }
            sound.ching()
            if let (p, won) = best, won >= 15 {
                try await say(p, ["Woo-hoo! +$\(won)!", "Look at that! Pay me!", "I'm on a roll!"].randomElement()!, 2)
            } else {
                try await sleep(2.2)
            }
            for i in chips.indices where !done[i] {
                if chips[i]! >= goal {
                    done[i] = true
                    rows[i + 1].note = "Doubled up! Cashes out $\(chips[i]!)"
                    rows[i + 1].out = true
                    board?.rows = rows
                    try await say(players[i], i == human ? "I doubled my money! I'm cashing out!" : ["I doubled my money! I'm done!", "That's $\(chips[i]!)! Cash me out!"].randomElement()!, 2.4)
                } else if chips[i]! <= 0 {
                    done[i] = true
                    rows[i + 1].note = "Lost it all"
                    rows[i + 1].out = true
                    board?.rows = rows
                    try await say(players[i], "I'm out of chips! Good game, everyone.", 2.2)
                }
            }
        }
        if guests.contains(where: { !done[$0] }) {
            caption = "It's getting late — \(hostName) closes the table after \(dealt) hands."
            try await sleep(2.4)
        } else {
            caption = "Every guest has doubled up or lost it all — the game's over!"
            try await sleep(2.4)
        }
        felt = []
        tableGroups = []
        board?.status = "Cashing out after \(dealt) hand\(dealt == 1 ? "" : "s")"
        let finals = chips.map { $0 ?? 0 }
        return (finals.map { "finished with $\($0)" }, finals, dealt)
    }

    /// Deals hand after hand, card by card, until someone reaches the target. You play `human`'s seat.
    /// Returns the final scores and how many hands were dealt.
    private func playFun(_ game: CasinoGame, _ table: [Person], human: Int?) async throws -> ([Int], Int) {
        let names = table.map(\.id)
        var scores = names.map { _ in 0 }
        func rows() -> [BoardRow] {
            names.indices.map { BoardRow(id: names[$0], value: "\(scores[$0])", note: "", team: game.isPartners ? $0 % 2 : nil) }
        }
        tableSeats = table
        humanRow = human
        tableGroups = []
        board = TableBoard(game: game, status: game == .hearts ? "Game ends at \(game.target) · low score wins"
                                              : game == .diamonds ? "\(game.target) rounds · most crystal points wins"
                                              : game == .fives ? "\(game.target) hands · closest to \(CasinoGame.fivesGoal) without going over" : "First to \(game.target)",
                           rows: rows(), pot: nil)
        if game.isPartners {
            caption = "Partners: \(names[0]) & \(names[2]) vs. \(names[1]) & \(names[3])."
            try await sleep(2.4)
        }
        let seats = host(human: human, seatX: [Stage.dealerX] + Stage.spotX)
        var hand = 0
        var dealer = Int.random(in: 0..<names.count)
        while Tricks.winners(game, scores: scores, hands: hand) == nil && hand < 30 {
            board?.status = "Hand \(hand + 1) · \(names[dealer]) deals · " + (game == .hearts ? "ends at \(game.target)" : game.byRounds ? "of \(game.target)" : "to \(game.target)")
            caption = "Hand \(hand + 1): \(names[dealer]) deals."
            sound.deal()
            let r = try await Tricks.hand(game, names: names, scores: scores, dealer: dealer, round: hand, host: seats)
            hand += 1
            for i in scores.indices { scores[i] += r.points[i] }
            var rs = rows()
            for i in rs.indices where r.points[i] != 0 { rs[i].note = r.points[i] > 0 ? "+\(r.points[i])" : "\(r.points[i])" }
            board?.rows = rs
            caption = "Hand \(hand): \(r.note)"
            try await sleep(3)
            dealer = (dealer + 1) % names.count
        }
        felt = []
        tableGroups = []
        return (scores, hand)
    }

    private func nextWomanName() -> String {
        if womenNames.isEmpty {
            womenNames = ["Angela", "Bonnie", "Brenda", "Carol", "Cheryl", "Denise", "Diane", "Donna", "Ellen", "Fran", "Gina", "Holly",
                          "Iris", "Joyce", "Karen", "Lena", "Linda", "Maria", "Nancy", "Olivia", "Paula", "Peggy", "Rachel", "Rita",
                          "Sandy", "Terri", "Tina", "Val", "Wendy", "Yolanda"].shuffled()
        }
        return womenNames.popLast()!
    }

    private func nextKidName() -> String {
        if kidNames.isEmpty {
            kidNames = ["Abby", "Bella", "Chloe", "Daisy", "Ellie", "Gracie", "Hailey", "Ivy", "Josie", "Katie", "Lily", "Maddie",
                        "Nora", "Piper", "Ruby", "Sophie", "Tessa", "Zoe"].shuffled()
        }
        return kidNames.popLast()!
    }

    // MARK: Kids to the rescue

    /// The house is in the hole and the bank is empty: Rosie sends the Roswell of Poker to kids' computers around town, and you
    /// play each kid's try. A kid who reaches game 10 is beamed to the cottage casino, where the mini saucers change her.
    /// The credits left on the kids' machines go to the house in dollars, and a quarter of each kid's goes home with her for her parents.
    /// Kids keep trying until the house's three quarters cover the hole (at least one kid per $100 short, three at most);
    /// then they play a just-for-fun game with the family, get beamed home to their moms, and go inside still Roswell aliens.
    private func kidsRescue() async throws {
        let deficit = -cash
        guard deficit > 0 else { return }
        let (mom, ava, rosie) = (mom, ava, rosie)
        let homeX = cast.map { $0.x(at: .now) }
        // It can happen right after a game in the cottage casino, or at home at the end of the day.
        let wasAtCasino = atCasino
        for p in cast { p.atTable = false }
        try await look(at: wasAtCasino ? Stage.shot(centerX: 470, height: 300) : Stage.shot(centerX: 760, height: 280))
        caption = "Uh-oh — the cash box is $\(deficit) in the hole!"
        mom.mood = .shocked
        try await say(mom, "We're $\(deficit) in the hole! What are we going to do?", 2.6)
        mom.mood = .happy
        try await say(rosie, "Mom! We can send the Roswell of Poker to some kids' computers!", 2.6)
        try await say(ava, "Any kid who makes it to game ten gets beamed to our casino — and the credits left on her machine go to the house!", 3.2)
        try await say(mom, "And a quarter of it goes home with her for her parents. Let's do it!", 2.6)
        caption = "Rosie sends the Roswell of Poker out to kids' computers all over town…"
        sound.ding()
        try await sleep(2)

        let needed = min(3, max(1, (deficit + 99) / 100))
        var rescuers: [(kid: Person, mother: Person, credits: Int)] = []
        var houseShare = 0
        var tries = 0
        while rescuers.count < 3 && (rescuers.count < needed || houseShare < deficit) {
            let kid = Person.customer(nextKidName(), kid: true, x: Stage.kidPlayX)
            // Across town: the kid's bedroom, with the game waiting on her computer.
            fadeT0 = .now
            try await sleep(0.5)
            kidRoom = tries
            tries += 1
            for p in cast { p.visible = false }
            for p in [aunt, cousin].compactMap({ $0 }) { p.visible = false }
            customers = [kid]
            (kid.x0, kid.x1, kid.moveDur, kid.facing) = (Stage.kidPlayX, Stage.kidPlayX, 0, -1)
            kid.visible = true
            (camFrom, camTo) = (Stage.full, Stage.full)
            try await sleep(0.8)
            caption = "Across town, \(kid.id)'s computer goes ping!"
            try await look(at: Stage.shot(centerX: Stage.kidDeskX + 20, height: 300))
            try await say(kid, ["Ooh! A new game just popped up — the Roswell of Poker!", "What's this? A video poker game with an alien on it!",
                                "Free credits? Okay, I'll play!"].randomElement()!, 2.6)
            let ending = try await playPoker(kid, kid: true)
            if ending == .qualified {
                let credits = leftoverCredits
                leftoverCredits = 0
                // She calls her mom in to see — and her mom watches her get beamed away.
                let mother = Person.customer(nextWomanName(), kid: false, x: 0)
                try await say(kid, "I made it to game ten! MOM! Come look!", 2.4)
                (mother.x0, mother.x1, mother.moveDur, mother.facing) = (Stage.W + 40, Stage.W + 40, 0, -1)
                mother.visible = true
                customers = [kid, mother]
                try await look(at: Stage.shot(centerX: Stage.kidPlayX + 70, height: 320))
                caption = "\(kid.id) calls her mom into her room…"
                try await say(mother, "Coming, sweetie!", 1.6)
                try await walk(mother, to: Stage.kidPlayX + 110, speed: 150)
                mother.facing = -1
                kid.facing = 1
                try await say(mother, "What is it, honey?", 1.8)
                try await say(kid, "Look — game ten on the Roswell of Poker! Wait… what's happening?!", 2.6)
                kid.mood = .shocked
                teleport = (Stage.kidPlayX, AlienColor.green.beam.color, .now)
                sound.beam(true)
                caption = "A green beam shines down through the ceiling — and carries \(kid.id) up and away, with \(credits) credits left on her machine!"
                try await sleep(0.5)
                kid.lift = (.now, true)
                try await sleep(0.5)
                mother.mood = .shocked
                try await sleep(Person.liftTime - 0.5)
                kid.visible = false
                kid.lift = nil
                try await sleep(0.4)
                sound.beam(false)
                teleport = nil
                kid.mood = .happy
                caption = "\(mother.id) can't believe her eyes!"
                try await say(mother, "\(kid.id)?! \(kid.id.uppercased())! Where did you GO?!", 2.4)
                try await say(mother, ["She was right here! A beam of light took my little girl!", "This can't be happening!"].randomElement()!, 2.4)
                mother.visible = false
                rescuers.append((kid, mother, credits))
                houseShare += credits - credits / 4
            } else {
                kid.mood = .shocked
                try await say(kid, ending == .broke ? "Aww, I ran out of credits!" : "Oh no — I didn't bet the max every hand!", 2.4)
                caption = "No game 10 for \(kid.id). The Roswell of Poker pops up on another kid's computer…"
                try await sleep(1.6)
            }
            customers = []
        }

        // The kids land in the cottage casino, and the mini saucers take it from there.
        let kids = rescuers.map(\.kid)
        fadeT0 = .now
        try await sleep(0.5)
        kidRoom = nil
        atCasino = true
        for (p, x) in zip(cast, Stage.boothSideX) {
            p.says = nil
            p.visible = true
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1)
        }
        for p in [aunt, cousin].compactMap({ $0 }) { p.visible = false }
        customers = kids
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Back in the \(CasinoGame.casinoName), the family waits…"
        try await look(at: Stage.shot(centerX: 300, height: 330))
        let landing = Stage.machineSpots(kids.count)
        for (i, k) in kids.enumerated() {
            let x = landing[i]
            (k.x0, k.x1, k.moveDur, k.facing) = (x, x, 0, 1)
            teleport = (x, AlienColor.green.beam.color, .now)
            sound.beam(true)
            caption = "ZAP! The beam carries \(k.id) down into the cottage casino, right next to the Roswell of Poker!"
            try await sleep(0.4)
            k.lift = (.now, false)
            k.visible = true
            try await sleep(Person.liftTime)
            k.lift = nil
            try await sleep(0.7)
            sound.beam(false)
            teleport = nil
            try await say(k, ["Whoa! Where am I?", "Is this… a casino?!", "How did I get here?"][i % 3], 2)
        }
        try await say(mom, kids.count == 1 ? "Welcome to the \(CasinoGame.casinoName)! You made it to game ten — so the mini saucer has a surprise for you!"
                                           : "Welcome to the \(CasinoGame.casinoName), girls! You made it to game ten — so the mini saucers have a surprise for you!", 3.2)
        try await saucers(kids, surprise: true)
        try await mirror(kids)
        var used: Set<String> = []
        for k in kids {
            let lines = ["I'm a Roswell alien!", "Look at my HUGE eyes!", "My head is SO big!", "I'm \(k.alienColor.name)!"]
            let line = lines.filter { !used.contains($0) }.randomElement() ?? lines[0]
            used.insert(line)
            try await say(k, line, 2)
            try await snap(k)
        }

        // Every credit left on the kids' machines is a dollar for the house; each kid takes a quarter of hers home.
        let total = rescuers.map(\.credits).reduce(0, +)
        cash += total
        cashPop = ("+$\(total) from the kids' machines", .now, Stage.boothSideX[0])
        sound.ching()
        caption = "The \(total) credits left on the kids' machines go to the house: +$\(total)."
        try await say(mom, "Thank you, girls! That gets us out of the hole!", 2.4)
        var shares: [Int] = []
        for r in rescuers {
            let share = r.credits / 4
            shares.append(share)
            cash -= share
        }
        let paid = shares.reduce(0, +)
        if paid > 0 {
            cashPop = ("-$\(paid) to take home", .now, Stage.boothSideX[0])
            sound.ching()
            caption = "A quarter of each kid's credits goes home with her for her parents: " + zip(kids, shares).map { "\($0.id) $\($1)" }.joined(separator: ", ") + "."
            try await say(mom, "And a quarter of what you each won goes home with you, for your mom and dad!", 2.8)
        }
        try await sleep(1.2)

        // A just-for-fun game with the family, for the kids who saved the day.
        let game = CasinoGame.funGames.filter { $0.funSeats >= kids.count + 1 }.randomElement()!
        let girls = [ava, rosie]
        let seatsLeft = game.funSeats - 1 - kids.count
        let joiners = Array(girls.shuffled().prefix(seatsLeft))
        var seated = kids
        for g in joiners { seated.insert(g, at: Int.random(in: 0...seated.count)) }
        let watching = girls.filter { g in !joiners.contains { $0 === g } }
        try await say(mom, "Now, before you go home — who wants to play some \(game.name)? Just for fun!", 2.6)
        try await sayAll(kids, "Yes!", 1.4)
        caption = "Everyone takes a spot at the \(game.name) table."
        try await walkAll([(mom, Stage.dealerX)] + zip(seated, Stage.spots(seated.count)).map { ($0, $1) }
                          + zip(watching, Stage.girlsTableX).map { ($0, $1) })
        for p in seated + [mom] {
            p.atTable = true
            p.facing = 0
        }
        for g in watching { g.facing = -1 }
        try await look(at: Stage.tableShot)
        let mine = seated.firstIndex { p in joiners.contains { $0 === p } }
        you = mine.map { seated[$0].id }
        if let mine { caption = "You're \(seated[mine].id). Your cards show up under the table." }
        try await sleep(1.2)
        let table = [mom] + seated
        let (scores, hands) = try await playFun(game, table, human: mine.map { $0 + 1 })
        let won = Tricks.winners(game, scores: scores, hands: hands) ?? [scores.indices.max { scores[$0] < scores[$1] }!]
        caption = "\(won.map { table[$0].id }.joined(separator: " & ")) win\(won.count == 1 ? "s" : "") the game!"
        sound.ding()
        try await say(table[won[0]], ["Woo-hoo! I win!", "That was SO much fun!", "Best game ever!"].randomElement()!, 2.2)
        you = nil
        myHand = []
        humanRow = nil
        felt = []
        board = nil
        tableSeats = []
        tableGroups = []
        for p in table { p.atTable = false }
        try await look(at: Stage.full)
        try await say(mom, "Time to go home, girls. Your moms will be wondering where you are!", 2.6)
        try await sayAll(kids, "Bye! Thank you!", 1.6)

        // Beamed home: each kid lands in front of her own house, where her mother is waiting at the door.
        fadeT0 = .now
        try await sleep(0.5)
        atCasino = false
        inNeighborhood = true
        for p in cast { p.visible = false }
        let mothers = rescuers.map(\.mother)
        for (i, m) in mothers.enumerated() {
            let door = Stage.guestDoorX[i]
            (m.x0, m.x1, m.moveDur, m.facing) = (door, door, 0, 1)
            m.mood = .shocked
            m.visible = true
        }
        for k in kids { k.visible = false }
        customers = mothers + kids
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Meanwhile, across town, the moms are looking everywhere for their girls…"
        try await say(mothers[0], "\(kids[0].id)! Where are you?!", 2)
        for (i, (k, m)) in zip(kids, mothers).enumerated() {
            let x = Stage.guestDoorX[i] + 60
            (k.x0, k.x1, k.moveDur, k.facing) = (x, x, 0, -1)
            teleport = (x, k.alienColor.beam.color, .now)
            sound.beam(true)
            caption = "ZAP! \(k.id) is beamed home to her mom — with $\(shares[i])!"
            try await sleep(1.3)
            k.visible = true
            try await sleep(1.6)
            sound.beam(false)
            teleport = nil
            try await say(m, "AAAH! Who are YOU?!", 1.8)
            try await say(k, "Mom, it's me, \(k.id)! I made it to game ten on the Roswell of Poker!", 2.8)
            if shares[i] > 0 {
                sound.ching()
                try await say(k, "And I brought home $\(shares[i]) for you and Dad!", 2.4)
            }
            m.mood = .happy
            try await say(m, shares[i] > 0 ? "$\(shares[i])?! Well… come inside, my little alien!" : "Well… come inside, my little alien!", 2.4)
        }
        // Every kid goes into her house with her mom — still a Roswell alien.
        caption = "In they go — every one of them still a Roswell alien!"
        for (i, (k, m)) in zip(kids, mothers).enumerated() {
            try await say(k, ["Can I stay an alien till bedtime?", "Wait till Dad sees me!", "I'm going to be green at dinner!"][i % 3], 2.2)
            let door = Stage.guestDoorX[i]
            try await walkAll([(k, door + 10), (m, door - 6)], speed: 110)
            k.facing = 0
            m.facing = 0
            try await sleep(0.3)
            k.visible = false
            m.visible = false
            sound.ding()
            try await sleep(0.5)
        }
        caption = "The kids are home safe with their moms — big heads, huge eyes and all."
        try await sleep(2)

        // Back with the family.
        fadeT0 = .now
        try await sleep(0.5)
        inNeighborhood = false
        atCasino = wasAtCasino
        customers = []
        for (p, x) in zip(cast, homeX) {
            p.visible = true
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
        }
        for p in [aunt, cousin].compactMap({ $0 }) { p.visible = true }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Kids to the rescue! The cash box is back to $\(cash)."
        try await say(mom, "Saved by the Roswell of Poker!", 2.2)
    }

    // MARK: Helpers

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }

    private func beginWalk(_ p: Person, to x: Double, speed: Double) -> Double {
        let now = Date.now
        let cur = p.x(at: now)
        p.x0 = cur
        p.x1 = x
        p.moveT0 = now
        p.moveDur = abs(x - cur) / speed
        if x != cur { p.facing = x > cur ? 1 : -1 }
        return p.moveDur
    }

    private func walk(_ p: Person, to x: Double, speed: Double = 130) async throws {
        try await sleep(beginWalk(p, to: x, speed: speed) + 0.1)
    }

    private func walkAll(_ moves: [(Person, Double)], speed: Double = 130) async throws {
        let longest = moves.map { beginWalk($0.0, to: $0.1, speed: speed) }.max() ?? 0
        try await sleep(longest + 0.1)
    }

    /// Halts someone mid-walk where they are.
    private func stop(_ p: Person) {
        let x = p.x(at: .now)
        (p.x0, p.x1, p.moveDur) = (x, x, 0)
    }

    private func say(_ p: Person, _ text: String, _ seconds: Double = 2.6) async throws {
        p.says = text
        p.saysUntil = .now + seconds
        try await sleep(seconds + 0.2)
    }

    /// Everyone in `people` says it at once.
    private func sayAll(_ people: [Person], _ text: String, _ seconds: Double) async throws {
        for p in people {
            p.says = text
            p.saysUntil = .now + seconds
        }
        try await sleep(seconds + 0.2)
    }

    /// Starts moving the camera without waiting for it.
    private func cut(to rect: CGRect) {
        camFrom = camera(at: .now)
        camTo = rect
        camT0 = .now
    }

    private func look(at rect: CGRect) async throws {
        cut(to: rect)
        try await sleep(0.9)
    }
}
