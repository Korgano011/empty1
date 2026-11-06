import SwiftUI

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var mom: Person
    var ava: Person
    var mia: Person
    var rosie: Person

    var cast: [Person] { [mom, ava, mia, rosie] }
    var customers: [Person] = []
    var everyone: [Person] { cast + [aunt, cousin].compactMap { $0 } + customers }
    /// Mom's sister and her little girl, visiting after every second night.
    var aunt: Person?
    var cousin: Person?

    var caption = "Tap Start to begin."
    var running = false
    var finished = false
    var muted = false { didSet { sound.muted = muted } }

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

    init() {
        (mom, ava, mia, rosie) = Self.makeFamily()
    }

    private static func makeFamily() -> (Person, Person, Person, Person) {
        let mom = Person("Mom", height: 152, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.40, g: 0.24, b: 0.12), style: .long,
                         shirt: RGB(r: 0.20, g: 0.60, b: 0.65), pants: RGB(r: 0.25, g: 0.30, b: 0.50), x: Stage.doorX)
        let ava = Person("Ava", height: 132, headScale: 0.13, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.92, g: 0.78, b: 0.42),
                         style: .ponytail, shirt: RGB(r: 0.95, g: 0.45, b: 0.40), pants: RGB(r: 0.30, g: 0.30, b: 0.45), kid: true, x: Stage.doorX)
        let mia = Person("Mia", height: 116, headScale: 0.145, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.75, g: 0.32, b: 0.14),
                         style: .curly, shirt: RGB(r: 0.60, g: 0.40, b: 0.80), pants: RGB(r: 0.25, g: 0.45, b: 0.70), kid: true, x: Stage.doorX)
        let rosie = Person("Rosie", height: 98, headScale: 0.16, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.55, g: 0.35, b: 0.18),
                           style: .pigtails, shirt: RGB(r: 0.98, g: 0.60, b: 0.75), pants: RGB(r: 0.95, g: 0.80, b: 0.30), kid: true, x: Stage.doorX)
        for p in [mom, ava, mia, rosie] { p.visible = false }
        return (mom, ava, mia, rosie)
    }

    /// The part of the stage on screen; eases from `camFrom` to `camTo` over 0.9s.
    func camera(at now: Date) -> CGRect {
        let t = min(max(now.timeIntervalSince(camT0) / 0.9, 0), 1)
        let e = t * t * (3 - 2 * t)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * e }
        return CGRect(x: mix(camFrom.minX, camTo.minX), y: mix(camFrom.minY, camTo.minY),
                      width: mix(camFrom.width, camTo.width), height: mix(camFrom.height, camTo.height))
    }

    /// What the booth's little screen says.
    func screenText(_ now: Date) -> String {
        guard !beamPeople.isEmpty else { return screen }
        let (phase, u) = BoothRun.phase(now.timeIntervalSince(boothT0))
        switch phase {
        case .lowering: return "LOWERING"
        case .charging: return "CHARGING"
        case .beaming:
            let left = max(0, 60 - Int(u * 60))
            return String(format: "0:%02d", left)
        case .sparkling: return "SPARKLE"
        case .cooling: return "COOLING"
        case .lifting, .done: return "DONE!"
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
        you = nil
        myHand = []
        prompt = nil
        humanRow = nil
        tableSeats = []
        tableGroups = []
        sound.prepare()
        sound.stopAll()
        (mom, ava, mia, rosie) = Self.makeFamily()
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
        let save = resume ? SaveGame.load() : nil
        if let save { restore(save) }
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
        nights = save.nights
        cash = save.cash
        bank = save.bank
        cousinsPaid = save.cousinsPaid
        auntVisits = save.auntVisits
        visitProfit = save.visitProfit
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
                            cousinColor: sleepover ? cousin?.alienColor.rawValue : nil)
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
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        if !resumed {

            caption = "Mom and her three daughters just bought a new single-story house!"
            try await sleep(2.5)
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
            try await say(mia, "Mine is purple!", 1.8)
            caption = "All the rooms are taken — except one, at the far end of the house."
            try await sleep(2.6)

            try await say(mom, "Girls, I'm going shopping. Be good while I'm gone!", 2.8)
            try await sayAll([ava, mia, rosie], "Bye, Mom!", 1.6)
            caption = "Mom heads out to go shopping. The girls stay home."
            try await walk(mom, to: Stage.doorX, speed: 150)
            doorOpenUntil = .now + 1.2
            try await sleep(0.4)
            mom.visible = false
            try await sleep(1)

            try await say(rosie, "I'm bored… let's go exploring!", 2.4)
            try await sayAll([ava, mia], "Okay!", 1.4)
            caption = "The three girls wander down the hall."
            try await walkAll([(rosie, Stage.watchX[0]), (ava, Stage.watchX[1]), (mia, Stage.watchX[2])], speed: 150)
            for p in [ava, mia, rosie] { p.facing = -1 }
            try await look(at: Stage.boothView)
            caption = "In the empty room, the girls find a strange machine with three chairs and a glowing green button!"
            try await say(rosie, "Ooh! A glowing button!", 2.4)
            try await say(mia, "I wonder what it does…", 2.2)
            try await say(ava, "It has THREE chairs — one for each of us!", 2.6)
            try await sayAll([ava, mia, rosie], "Let's try it!", 1.8)

            try await booth([ava, mia, rosie], firstTime: true)
            try await mirror([ava, mia, rosie])
            try await say(ava, "Look at my huge eyes! They're amazing!", 2.6)
            try await snap(ava)
            try await say(mia, "Look at me! I'm \(mia.alienColor.name)!", 2.4)
            try await snap(mia)
            try await say(rosie, "Whoa! I have a BIG \(rosie.alienColor.name) head!", 2.4)
            try await say(rosie, "We're ROSWELL ALIENS! Hee hee hee!", 2.2)
            try await snap(rosie)

            caption = "The girls wait in the living room for Mom to come home."
            try await look(at: Stage.full)
            try await walkAll(zip([ava, mia, rosie], Stage.couchX).map { ($0, $1) }, speed: 150)
            for p in [ava, mia, rosie] { p.facing = 1 }
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
            try await look(at: Stage.shot(centerX: 765, height: 280))
            try await say(mom, "I'm home! I got snacks and—", 2.2)
            mom.mood = .shocked
            try await sleep(0.6)
            var colors: [String] = []
            for p in [ava, mia, rosie] where !colors.contains(p.alienColor.name) { colors.append(p.alienColor.name) }
            try await say(mom, "GIRLS?! Why are you all \(Self.list(colors).uppercased())?!", 2.8)
            try await say(mom, "What happened?!", 1.8)
            try await say(rosie, "We pressed a glowing button! Come see!", 2.6)
            mom.mood = .happy
            mom.bags = false

            caption = "The girls lead Mom to the empty room."
            try await look(at: Stage.full)
            try await walkAll([(rosie, Stage.watchX[0] - 25), (mom, Stage.watchX[0]), (ava, Stage.watchX[1]), (mia, Stage.watchX[2])], speed: 150)
            for p in cast { p.facing = -1 }
            try await look(at: Stage.boothView)
            caption = "Mom reads the sign on the booth."
            signUntil = .now + 6
            try await sleep(6.2)
            try await say(mom, "A one-minute Roswell transformation machine? So THAT'S what happened!", 3)
            try await say(ava, "Mom… being a Roswell alien is SO cool!", 3)
            try await say(mia, "And you get to pick your own color!", 2.6)
            try await say(mom, "Well… it does look like fun.", 2.6)
            try await sayAll([ava, mia, rosie], "Be a Roswell alien too, Mom!", 2.4)
            try await say(mom, "Ha! Okay, okay — here goes nothing!", 2.6)

            try await booth([mom])
            try await mirror(mom)
            try await say(mom, "Oh my… I LOVE it! I'm a real Roswell alien!", 2.6)
            try await say(rosie, "Now we're ALL aliens!", 2)
            try await snap(mom)

            caption = "The whole family heads to the living room."
            try await look(at: Stage.full)
            try await walkAll([(mom, 715), (ava, 745), (mia, 775), (rosie, 800)])
            for p in cast { p.facing = 0 }
            try await look(at: Stage.shot(centerX: 758, height: 260))
            try await say(mia, "Four Roswell aliens!", 2)
            try await say(mom, "This is out of this world!", 2.2)
            try await say(rosie, "The glowing button was a GOOD idea, right?", 2.6)
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

    /// Up to three sit down at once, the one nearest the button presses it, and every beam runs together.
    /// Everyone is left standing at her chair; `mirror` takes each to the mirror.
    /// `firstTime`: the girls' very first change, all three together, before they know what the machine does.
    private func booth(_ group: [Person], presser chosen: Person? = nil, firstTime: Bool = false, surprise: Bool = false, fourth: Person? = nil, again: Bool = false) async throws {
        // Fill from the right so somebody is always next to the button.
        let seats = Array(Stage.seatX.suffix(group.count))
        let names = Self.list(group.map(\.id))
        // Guests in for a surprise are shown in by one of the family.
        if surprise, let host = cast.filter({ p in !group.contains { $0 === p } }).randomElement() {
            host.facing = -1
            try await say(host, "Step in, please.", 1.8)
        }
        caption = group.count == 1 ? "\(names) sits down in the chair." : "\(names) each sit down in a chair."
        try await walkAll(zip(group, seats).filter { abs($0.0.x(at: .now) - $0.1) > 1 })
        for p in group {
            p.seated = true
            p.facing = 1
        }
        boothClosed = true
        try await look(at: Stage.boothView)

        // Each of them picks her own color — unless it's a surprise, when the family picks for them.
        if surprise {
            caption = "The guests have no idea what this machine does…"
            for p in group { p.alienColor = AlienColor.allCases.randomElement()! }
            try await say(group[0], group.count == 1 ? "Um… what does this chair do?" : "Wait — what IS this thing?", 2.2)
            try await say(rosie, "It's a surprise! Just sit tight!", 2)
        }
        caption = surprise ? caption : group.count == 1 ? "\(names) picks a color." : "Everyone picks a color."
        for p in group where !surprise {
            p.alienColor = AlienColor.allCases.randomElement()!
            let c = p.alienColor.name
            try await say(p, ["I want \(c)!", "\(c.prefix(1).uppercased() + c.dropFirst()), please!", "Make me \(c)!", "Ooh — \(c) for me!"].randomElement()!, 1.8)
        }

        // At the casino one of the family works the machine; at home the sitter nearest the button presses it.
        let presser: Person
        var presserHome: Double?
        if atCasino || chosen != nil {
            presser = chosen ?? cast.filter { p in !group.contains { $0 === p } }.randomElement()!
            presserHome = presser.x(at: .now)
            caption = "\(presser.id) runs the machine for them."
            try await walk(presser, to: Stage.buttonStand)
            presser.facing = -1
            try await say(presser, group.count == 1 ? "\(group[0].alienColor.name.prefix(1).uppercased() + group[0].alienColor.name.dropFirst()) it is! Here we go!"
                                                   : "Colors are set! Here we go!", 1.8)
        } else {
            presser = group.last!
        }
        caption = "\(presser.id) presses the glowing button…"
        presser.reachTo = Stage.button
        try await sleep(0.7)
        pressT0 = .now
        sound.beep()
        try await sleep(0.4)
        presser.reachTo = nil
        // The 4th person, who had to wait for the second run, is off now.
        if again {
            // The family's been through this before.
            try await say(group.randomElement()!, "Here we go again.", 1.8)
        } else if let fourth {
            try await say(fourth, "Here I go.", 1.6)
        } else if presser === mom && group.contains(where: { $0 === mom }) {
            // Mom pressing her own button.
            try await say(mom, "Here I go.", 1.6)
        }

        let t0 = Date.now
        beamPeople = group
        boothT0 = t0
        for p in group {
            p.alien = false
            (p.changeFrom, p.changeTo) = (0, 1)
            p.changeT0 = t0 + BoothRun.lower + BoothRun.charge * 0.5
            p.changeDur = BoothRun.charge * 0.5 + BoothRun.beam
        }
        sound.motor(true)
        caption = group.count == 1 ? "Whirr… a little silver saucer lowers over \(names)'s head!" : "Whirr… a little silver saucer lowers over each head!"
        try await sleep(BoothRun.lower)
        sound.motor(false)
        // Close in on the saucers: tall enough for the tallest sitter, wide enough for every chair in use.
        let head = group.map { Pose($0, feet: CGPoint(x: seats[0], y: Stage.floorY), facing: 1, now: .now).head.y }.min()!
        let top = Stage.booth.minY
        let span = seats.last! - seats.first! + 120
        let groupShot = Stage.focus(CGPoint(x: (seats.first! + seats.last!) / 2 + 20, y: (head + top) / 2 + 12),
                                    height: max(220, head - top + 90, span * Stage.H / Stage.W))
        cut(to: groupShot)
        caption = group.count == 1 ? "The saucer hums and starts to glow…" : "The saucers hum and start to glow…"
        sound.beam(true)
        blurt(group, ["Ooh, it's humming!", "Here it comes!", "I'm so nervous!", "It's glowing!", "Eeek! Here we go!"], for: BoothRun.charge)
        if firstTime, group.contains(where: { $0 === rosie }) { rosie.says = "What am I being turned into?" }
        try await sleep(BoothRun.charge)

        // A close-up of each of them as the beam changes her.
        // Nobody repeats a line; on the girls' first change, whoever is in the middle asks what's going on.
        let slice = BoothRun.beam / Double(group.count)
        var used: Set<String> = []
        for (i, (p, seat)) in zip(group, seats).enumerated() {
            cut(to: closeUp(p, seat: seat))
            caption = "ZZZAP! \(p.id) is turning into a \(p.alienColor.name) Roswell alien — even her clothes disappear!"
            // Halfway through a guests' surprise change, whoever is in the middle realizes what's going on.
            let middle = (firstTime && group.count > 1 || surprise) && i == group.count / 2
            try await react(p, for: slice, used: &used,
                            opening: middle ? (surprise ? "We're being turned into Roswell aliens." : "What's happening?") : nil)
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
        caption = group.count == 1 ? "The saucer lifts…" : "The saucers lift…"
        try await sleep(BoothRun.lift)
        sound.motor(false)
        beamPeople = []
        for p in group { p.mood = .happy }
        screen = "DONE!"
        sound.ding()
        caption = "Ding! \(names) \(group.count == 1 ? "is a Roswell alien" : "are all Roswell aliens")!"
        try await sleep(1.2)

        for p in group { p.seated = false }
        boothClosed = false
        screen = "READY"
        cut(to: Stage.boothView)
        if let presserHome {
            try await walk(presser, to: presserHome)
            presser.facing = -1
        }
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

    /// Head to hips of someone sitting in the machine, with her saucer just in frame.
    private func closeUp(_ p: Person, seat: Double) -> CGRect {
        let pose = Pose(p, feet: CGPoint(x: seat, y: Stage.floorY), facing: 1, now: .now)
        let top = pose.head.y - pose.hr * 2.6
        let bottom = pose.torso.maxY + pose.hr * 0.6
        return Stage.focus(CGPoint(x: seat + pose.hr * 0.5, y: (top + bottom) / 2), height: max(120, bottom - top))
    }

    /// A walk to the mirror for a first look.
    private func mirror(_ p: Person) async throws {
        try await mirror([p])
    }

    /// Up to three walk to the wide mirror together and see themselves side by side.
    private func mirror(_ group: [Person]) async throws {
        try await walkAll(zip(group, Stage.mirrorStands).map { ($0, $1) })
        for p in group { p.facing = -1 }
        let tallest = group.map(\.height).max() ?? 120
        try await look(at: Stage.shot(centerX: group.count == 1 ? 410 : 430, height: max(tallest, 120) + 120))
    }

    /// "Ava", "Ava and Mia", "Ava, Mia and Rosie".
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

    /// One session — the afternoon one while `daytime`, otherwise the night one. Each game is picked at home:
    /// moneymakers take the family and the machine to the casino and back; just-for-fun games are played right at home.
    private func casinoNight() async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        let day = daytime
        let session = day ? "day" : "night"
        // Money in the bank counts too: Mom makes deposits between games.
        let nightStart = cash + bank
        sessionGroceries = 0
        gamesPlayed = 0
        nightHouseholds = []

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
            try await say(ava, "Mom, what if we took the machine to the casino?", 2.6)
            try await say(mom, "Ooh! I could run a card table — and everyone who plays becomes a Roswell alien first!", 3)
            try await say(rosie, "And they get to pick their own colors — we'll press the button for them!", 2.4)
            try await say(mom, "Moneymaker games at the casino, and just-for-fun games right here at home!", 3)
            try await say(mom, "Every buy-in is $\(CasinoGame.buyIn). We've got $\(CasinoGame.startCash) to cover the table.", 3)
        } else {
            caption = "\(day ? "Day" : "Night") \(nights) — game time!"
                + (aunt.map { a in " \(a.id) and \(cousin?.id ?? "her girl") tag along — together this time!" } ?? cousin.map { " \($0.id) tags along." } ?? "")
            try await sleep(2.4)
        }
        while true {
            try await look(at: Stage.full)
            caption = (gamesPlayed == 0 ? "Pick today's game" : "Pick the next game — or call it a \(session)")
                + ". Moneymakers are at the casino; just-for-fun games are at home."
            let pick = await withCheckedContinuation { cont in
                gamePick = cont
                choosingGame = true
            }
            try Task.checkCancellation()
            guard let pick else { break }
            result = nil
            // Every game picked is played twice, each time with a fresh set of guests.
            if pick.game.isMoney { try await toCasino(for: pick.game) }
            for round in 1...2 {
                if round == 2 {
                    caption = "Round two of \(pick.game.name) — time to find new players!"
                    try await say(mom, "That was fun! Let's play \(pick.game.name) again with some new faces.", 2.8)
                    result = nil
                }
                try await runTable(pick.game, daughterHouse: pick.game.isMoney && pick.daughterHouse)
                if !pick.game.isMoney {
                    try await walkAll(zip(cast, Stage.homeFamilyX).map { ($0, $1) })
                    for p in cast { p.facing = 0 }
                }
                gamesPlayed += 1
            }
            if pick.game.isMoney { try await backHome() }
            // Home after the second game: Mom runs to the store and the bank.
            try await errands()
            // A day is one pick, played twice.
            if gamesPlayed >= 2 {
                caption = "That's two games of \(pick.game.name) — and Mom's done shopping. That's it for today!"
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
        try await say(mia, "And our clothes came back!", 2.2)
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

    /// Before every session but the very first: the family turns alien again at home before the machine goes to the casino.
    private func alienAgain() async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        let when = daytime ? "today" : "tonight"
        caption = "Good morning — day \(nights) of games!"
        try await look(at: Stage.full)
        try await say(mom, "Who's ready to be a Roswell alien again?", 2.4)
        try await sayAll([ava, mia, rosie], "We are!", 1.6)
        if let cousin {
            try await say(cousin, cousin.alien ? "Now it's YOUR turn! Can I watch?" : "Can I watch?", 2)
            try await say(mom, "Sure, sweetie — come see!", 2)
        }
        caption = "Everyone heads to the Roswell transformation machine."
        try await walkAll([(rosie, Stage.watchX[0] - 25), (mom, Stage.watchX[0]), (ava, Stage.watchX[1]), (mia, Stage.watchX[2])]
                          + (cousin.map { [($0, 455.0)] } ?? []) + (aunt.map { [($0, 485.0)] } ?? []), speed: 150)
        for p in cast { p.facing = -1 }
        cousin?.facing = -1
        aunt?.facing = -1
        try await look(at: Stage.boothView)
        try await booth([mom, ava, mia], again: true)
        for p in [ava, mia, mom] {
            try await say(p, ["\(p.alienColor.name.prefix(1).uppercased() + p.alienColor.name.dropFirst()) \(when)!", "Alien again — I love it!",
                              "Look at my big \(p.alienColor.name) head!"].randomElement()!, 2)
        }
        try await walkAll([(mom, Stage.watchX[0]), (ava, Stage.watchX[1]), (mia, Stage.watchX[2])])
        for p in [mom, ava, mia] { p.facing = -1 }
        try await say(rosie, "My turn!", 1.6)
        if let cousin {
            try await say(cousin, "Can I push the button for you, Rosie?", 2.2)
            try await booth([rosie], presser: cousin, fourth: rosie)
            try await say(cousin, "Whoa! That's SO cool!", 2)
        } else {
            try await booth([rosie], fourth: rosie)
        }
        try await say(rosie, "I'm \(rosie.alienColor.name) \(when)! Let's go!", 2.2)
    }

    /// The morning after a night at the casino. Mom always buys groceries and goes to the bank.
    /// After every second night (when the family is going back), her sister and niece visit first:
    /// Mom takes her sister shopping and the cousin tags along.
    private func nextMorning(again: Bool) async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        let girls = [ava, mia, rosie]
        fadeT0 = .now
        try await sleep(0.5)
        lightsOut = false
        for (p, x) in zip(cast, [715.0, 745.0, 775.0, 800.0]) {
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
            try await say(mom, "I'd love to! I have groceries and the bank to do anyway.", 2.6)
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
            c.visible = false
            try await townTrip(with: [a])
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
        caption = "Mom comes home with the groceries."
        doorOpenUntil = .now + 2
        try await walk(mom, to: 830)
        mom.facing = -1
        cousin?.facing = 1
        for p in girls { p.facing = 1 }
        try await look(at: Stage.shot(centerX: 780, height: 270))
        try await say(mom, "I'm home! The groceries are in, and the money's in the bank.", 2.8)
        mom.bags = false
        if let cousin, let aunt = awayAunt {
            let sister = aunt.id.replacingOccurrences(of: "Aunt ", with: "")
            try await look(at: Stage.shot(centerX: 770, height: 250))
            mom.mood = .shocked
            try await say(mom, "\(cousin.id)?! Is that YOU?", 2.2)
            try await say(cousin, "The girls turned me into a \(cousin.alienColor.name) Roswell alien, Auntie!", 2.8)
            try await say(rosie, "She picked the color herself!", 2)
            mom.mood = .happy
            try await say(mom, "Well, you look adorable! Your mom is going to be SO surprised.", 2.8)
            try await say(ava, "Don't tell her — let's surprise her!", 2.2)
            caption = "\(aunt.id) is still out shopping — she'll come back to the house after the casino trip."
            try await sleep(2.6)
            try await say(mom, "Aunt \(sister) kept shopping, so \(cousin.id) comes along with us on today's trip!", 3)
            try await say(mom, "\(cousin.id), you help out, and you get a quarter of the profit when your visit's over.", 2.8)
            try await say(cousin, "A whole quarter? Yay!", 2)
        } else if !again {
            try await say(mom, "No games today, girls. What a run we had!", 2.6)
        }
    }

    /// After the family changes back: lights out, everyone to her own room, and a night's sleep.
    private func bedtime() async throws {
        let girls = [ava, mia, rosie]
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
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        let girls = [ava, mia, rosie]
        try await look(at: Stage.full)
        for p in cast { p.atTable = false }
        try await walkAll(zip(cast, Stage.homeFamilyX).map { ($0, $1) })
        for p in girls { p.facing = 1 }
        try await say(mom, "Girls, I'm running out for groceries and to the bank. Be right back!", 2.8)
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

    /// Main Street: a stop at the boutique if the aunt came along, then groceries and the bank.
    private func townTrip(with companions: [Person]) async throws {
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

        if let a = aunt, companions.contains(where: { $0 === a }) {
            let sister = a.id.replacingOccurrences(of: "Aunt ", with: "")
            try await say(a, "I'm not done shopping yet! \(cousin.map { "Can \($0.id) go along with you all to the casino today?" } ?? "")", 3)
            try await say(mom, "Of course! Come back to the house after our trip, \(sister) — we'll have a surprise for you.", 3)
            try await say(a, "A surprise? Ooh, I can't wait!", 2)
            caption = "\(a.id) keeps shopping. She'll come back to the house after today's casino trip."
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
    /// What everyone pays for a trip through the Roswell transformation machine.
    static let transformFee = 10

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
        let (ava, mia, rosie) = (ava, mia, rosie)
        caption = "With Mom and \(aunt?.id ?? "her aunt") out shopping, the girls have something to show their cousin…"
        for p in [ava, mia, rosie] { p.facing = 1 }
        c.facing = -1
        try await look(at: Stage.shot(centerX: 800, height: 260))
        try await say(rosie, "\(c.id), want to see something REALLY cool?", 2.4)
        try await say(c, "Yes! What is it?", 1.6)
        try await say(ava, "There's a machine in the spare room that turns you into a Roswell alien!", 3)
        try await say(mia, "It wears off later — and you get to pick your color!", 2.6)
        try await say(c, "No way! I want to try it!", 2)
        caption = "The girls lead \(c.id) down the hall to the Roswell transformation machine."
        try await look(at: Stage.full)
        try await walkAll([(rosie, Stage.watchX[0]), (ava, Stage.watchX[1]), (mia, Stage.watchX[2]), (c, 455)], speed: 150)
        for p in [ava, mia, rosie, c] { p.facing = -1 }
        try await look(at: Stage.boothView)
        try await say(rosie, "Hop in the chair — I'll push the button for you!", 2.4)
        try await booth([c], presser: rosie)
        try await mirror(c)
        try await say(c, "I'm a \(c.alienColor.name) alien! Look at my big eyes!", 2.6)
        try await sayAll([ava, mia, rosie], "You look awesome!", 1.8)
        try await say(c, "Wait till Mommy sees me!", 2)
        try await snap(c)
        caption = "Everyone heads back to the living room to wait for Mom."
        try await look(at: Stage.full)
        try await walkAll([(c, 715), (ava, 745), (mia, 775), (rosie, 800)], speed: 150)
        for p in [ava, mia, rosie] { p.facing = 0 }
        c.facing = 0
    }

    /// After the first trip of a visit day the aunt comes back to the house, gets a shock — her daughter and her sister's family
    /// are all aliens — and goes through the home machine herself; her daughter presses the button. Then she tags along on trip two.
    private func auntReturns() async throws {
        guard let a = awayAunt, let c = cousin else { return }
        let (mom, ava, rosie) = (mom, ava, rosie)
        let sister = a.id.replacingOccurrences(of: "Aunt ", with: "")
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
        try await say(mom, "Surprise, sis! It's the machine in the spare room. We're all Roswell aliens!", 3)
        try await say(rosie, "We just got back from the casino — and \(c.id) helped!", 2.6)
        a.mood = .happy
        a.bags = false
        try await say(a, "Well… if you can't beat 'em, join 'em! Turn me into one too!", 2.8)
        try await say(c, "Yay! Can I push the button for Mommy?", 2.2)
        try await say(mom, "Go ahead, sweetie. And \(sister) — sleep over tonight, and we'll all go on a trip together in the morning!", 3.2)
        caption = "\(c.id) takes her mom down the hall to the Roswell transformation machine."
        try await look(at: Stage.full)
        try await booth([a], presser: c)
        try await mirror(a)
        try await say(a, "Look at me — I'm \(a.alienColor.name)! I'm a real Roswell alien!", 2.6)
        try await say(c, "You look awesome, Mommy!", 2)
        try await say(ava, "Tomorrow you're coming to the casino with us!", 2.4)
        try await snap(a)
        // The transformation fee — she pays for her girl's change too.
        let fee = Self.transformFee * 2
        cash += fee
        cashPop = ("+$\(fee) transformation", .now, a.x(at: .now))
        sound.ching()
        caption = "\(a.id) pays the $\(Self.transformFee) transformation fee — for herself and for \(c.id)."
        try await say(mom, "That'll be $\(Self.transformFee) for the transformation, sis — house rules!", 2.6)
        try await say(a, "Here's $\(fee) — ten for me and ten for \(c.id). Worth every penny!", 2.8)
        sleepover = true
        try await look(at: Stage.full)
        try await walkAll([(a, Stage.homeAuntX), (c, Stage.homeCousinX)])
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
            try await say(mom, "\(c.id), you tagged along both days — here's your quarter of the profit: $\(share)!", 3)
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

    /// One full game: a daughter joins (you play her), Mom recruits players — some with their own
    /// daughters — everyone who's agreed becomes a Roswell alien, they buy in, and play.
    /// At a moneymaker table the daughter either plays or, with `daughterHouse`, banks while Mom deals.
    private func runTable(_ game: CasinoGame, daughterHouse: Bool) async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        let girls = [ava, mia, rosie]
        let daughter = girls.randomElement()!
        let watchers = girls.filter { $0 !== daughter }
        let house = game.isMoney ? (daughterHouse ? daughter : mom) : nil
        let daughterPlays = !daughterHouse
        // Mom adds up to three people to a moneymaker table (the daughter doesn't count); fun tables fill their seats.
        let need = game.isMoney ? CasinoGame.maxPlayers : game.funSeats - 2
        let startCash = cash

        caption = daughterPlays ? "\(daughter.id) wants to play \(game.name) — and you're playing her!" : "\(daughter.id) is the house tonight — Mom will deal."
        try await say(daughter, daughterPlays ? "Mom, can I play this one? Pleeease?" : "Can I be the house, Mom?", 2.4)
        try await say(mom, daughterPlays ? "Sure, sweetie — take a seat! I'll find the rest." : "You're the house! I'll deal the cards.", 2.4)

        mom.atTable = false
        felt = []
        board = nil
        if game.isMoney {
            // Mom heads out on the floor; the girls tag along.
            caption = "Mom goes looking for players. The girls tag along."
            try await walkAll([(mom, Stage.askX)] + zip(girls, Stage.girlsAskX).map { ($0, $1) })
            mom.facing = 1
            for g in girls { g.facing = 1 }
            try await look(at: Stage.shot(centerX: 1020, height: 300))
        } else {
            // Just-for-fun games are played at home: Mom and the girls go out front and ask around the neighborhood.
            try await goOutside()
        }

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
            if let (p, kid, alien, plays) = try await askPasserby(game, slot: next, filled: filled, need: need, mustSayYes: mustSayYes,
                                                                  outside: !game.isMoney) {
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
        if !game.isMoney { try await comeInside(slot: slot) }
        // An empty moneymaker seat goes to one of the sisters who'd otherwise watch; she's already an alien, and plays with family money.
        var fillers: [Person] = []
        if filled < need {
            caption = "Mom has asked \(asked) passers-by — time to play with \(filled == 1 ? "one guest" : "\(filled) guests")."
            try await say(mom, "That's enough asking — let's play!", 2.2)
            if game.isMoney {
                fillers = Array(watchers.shuffled().prefix(need - filled))
                for f in fillers {
                    try await say(f, "There's an empty seat — can I take it, Mom?", 2.4)
                    try await say(mom, "Sure, \(f.id)! The house covers your buy-in.", 2.4)
                }
                if !fillers.isEmpty {
                    caption = "\(Self.list(fillers.map(\.id))) \(fillers.count == 1 ? "takes the empty seat" : "take the empty seats")."
                    filled += fillers.count
                }
            }
        }
        try await say(mom, players.count == 1 ? "That's our player! Follow me — one quick stop before we deal." : "That's everybody! Follow me, ladies — one quick stop before we deal.", 2.6)

        // Everyone who's agreed becomes an alien, three chairs at a time: each woman, then her daughter.
        caption = game.isMoney ? "Players are ready — first stop, the Roswell transformation machine!"
                               : "Players are ready — first stop, the Roswell transformation machine in the empty room!"
        try await look(at: Stage.full)
        try await walkAll([(mom, Stage.boothSideX[0])] + zip(girls, Stage.boothSideX.dropFirst()).map { ($0, $1) })
        for p in cast { p.facing = -1 }
        var goingAlien = players.flatMap { p in [p] + kids.filter { $0.mother === p && $0.alien }.map(\.kid) }
        func transform(_ list: [Person], surprise: Bool = false) async throws {
            for start in stride(from: 0, to: list.count, by: 3) {
                let group = Array(list[start..<min(start + 3, list.count)])
                caption = group.count == 1 ? "\(group[0].id) heads into the booth." : "The machine takes three at a time — in they go!"
                try await booth(group, surprise: surprise, fourth: start == 3 ? group[0] : nil)
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
                // $10 a head for the transformation; moms pay for their girls.
                let fee = group.count * Self.transformFee
                cash += fee
                cashPop = ("+$\(fee) transformation", .now, Stage.mirrorStands[1])
                sound.ching()
                caption = "Mom collects the $\(Self.transformFee) transformation fee\(group.count > 1 ? " — $\(fee) for the group" : "")."
                try await say(mom, group.count == 1 ? "That'll be $\(Self.transformFee) for the transformation!" : "That's $\(Self.transformFee) each for the transformation!", 2.4)
                let payers = group.filter { !$0.isKid }.isEmpty
                    ? group.compactMap { k in kids.first { $0.kid === k }?.mother }
                    : group.filter { !$0.isKid }
                if let payer = payers.first {
                    try await say(payer, group.count == 1 && payer !== group[0] ? "Here's $\(Self.transformFee) for \(group[0].id)." :
                                    ["Worth every penny!", "Here you go — what a ride!", "Best ten bucks I ever spent!"].randomElement()!, 2.2)
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
        let spots = game.isMoney ? Stage.spots(seated.count) : Array(Stage.homeSpotX.prefix(seated.count))
        let audience = watchers.filter { w in !fillers.contains { $0 === w } } + kids.filter { !$0.plays }.map(\.kid)
        let dealerSpot = game.isMoney ? Stage.dealerX : Stage.homeDealerX
        var moves = [(mom, dealerSpot)] + zip(seated, spots).map { ($0, $1) }
            + zip(audience, game.isMoney ? Stage.girlsTableX : Stage.homeAudienceX).map { ($0, $1) }
        if !daughterPlays { moves.append((daughter, Stage.houseX)) }
        try await walkAll(moves)
        for p in seated + [mom] + (daughterPlays ? [] : [daughter]) {
            p.atTable = true
            p.facing = 0
        }
        for g in audience { g.facing = -1 }
        try await look(at: game.isMoney ? Stage.tableShot : Stage.shot(centerX: 790, height: 290))
        you = daughterPlays ? daughter.id : nil
        if daughterPlays { caption = "You're \(daughter.id). Your cards show up under the table." }

        // Buy-ins. Moms pay for their girls; the daughter's comes out of the family's cash and her winnings go back in.
        let buyIns = guests.count * CasinoGame.buyIn
        var familyBuyIn = 0
        var setupFee = 0
        if game.isMoney {
            setupFee = CasinoGame.setupFee
            caption = "Mom pays the casino $\(setupFee) to set up the \(game.name) table."
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
                try await say(star, star === mom ? (won.count == 1 ? "Mom wins! Ha!" : "We did it, partner!") : "I WON! I won, Mom!", 2.2)
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
        if !game.isMoney {
            try await leaveHome(players: players, kids: kids.map { ($0.kid, $0.mother) }, goingAlien: goingAlien, daughter: daughter)
            mom.atTable = false
            caption = "The \(game.name) game is saved in the album."
            return
        }
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
        caption = "Out they go — still Roswell aliens! The change wears off when they get home."
        for p in goingAlien.prefix(2) {
            try await say(p, p.isKid ? ["I get to stay an alien all the way home!", "Wait till my friends see me!", "That was SO cool!"].randomElement()!
                                     : ["I'm going home a Roswell alien!", "Won't the neighbors be surprised!", "What a night! Same time next week?"].randomElement()!, 2.2)
        }
        nightHouseholds += players.map { p in [p] + kids.filter { $0.mother === p }.map(\.kid) }

        caption = "Off they go, aliens and happy!"
        for p in leaving { _ = beginWalk(p, to: 1320, speed: 110) }
        try await sleep((1320 - Stage.exitX.last!) / 110)
        customers = []
        caption = "The \(game.name) game is saved in the album."
    }

    /// A moneymaker game: the family takes the machine to the casino, right beside Mom's card table.
    private func toCasino(for game: CasinoGame) async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        caption = "\(game.name) is a moneymaker — off to the \(CasinoGame.casinoName) with the machine!"
        try await say(mom, "Load up the machine, girls — we're going to the casino!", 2.4)
        fadeT0 = .now
        try await sleep(0.5)
        atCasino = true
        boothClosed = false
        screen = "READY"
        for (p, x) in zip([mom, ava, mia, rosie], [Stage.dealerX] + Stage.girlsTableX) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
        }
        if let cousin { (cousin.x0, cousin.x1, cousin.moveDur, cousin.facing) = (Stage.girlsTableX[8], Stage.girlsTableX[8], 0, -1) }
        if let aunt { (aunt.x0, aunt.x1, aunt.moveDur, aunt.facing) = (Stage.girlsTableX[7], Stage.girlsTableX[7], 0, -1) }
        mom.atTable = true
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "The \(CasinoGame.casinoName)! The Roswell transformation machine sits right next to Mom's card table."
        try await sleep(2.2)
    }

    /// After a moneymaker game: the family brings the machine home again.
    private func backHome() async throws {
        caption = "Time to take the machine home."
        try await sleep(1.4)
        fadeT0 = .now
        try await sleep(0.5)
        atCasino = false
        boothClosed = false
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
        caption = "Back home with the machine."
        try await sleep(1.4)
    }

    /// A just-for-fun game: Mom and the girls step outside and ask people walking down the street.
    /// The aunt and cousin wait inside.
    private func goOutside() async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        caption = "Mom and the girls head outside to ask around the neighborhood."
        try await say(mom, "Let's go find some players, girls!", 2)
        try await walkAll([(mom, Stage.doorX), (ava, Stage.doorX), (mia, Stage.doorX), (rosie, Stage.doorX)], speed: 150)
        fadeT0 = .now
        try await sleep(0.5)
        inNeighborhood = true
        outsideHome = true
        for p in [aunt, cousin].compactMap({ $0 }) { p.visible = false }
        for (p, x) in zip([mom, ava, mia, rosie], [Stage.askX] + Stage.girlsAskX) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
        caption = "Out on the sidewalk, Mom waits for people to stroll by."
        try await look(at: Stage.shot(centerX: 1020, height: 300))
    }

    /// Everyone who said yes follows the family back inside and lines up by the machine.
    private func comeInside(slot: [ObjectIdentifier: Int]) async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        caption = "Everyone heads inside."
        try await sleep(1.2)
        fadeT0 = .now
        try await sleep(0.5)
        inNeighborhood = false
        outsideHome = false
        doorOpenUntil = .distantPast
        for p in [aunt, cousin].compactMap({ $0 }) { p.visible = true }
        for (p, x) in zip([mom, ava, mia, rosie], [Stage.doorX - 25, 760.0, 735.0, 710.0]) {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1)
        }
        for p in customers {
            let x = slot[ObjectIdentifier(p)].map { Stage.waitX[$0] } ?? Stage.waitX[0]
            p.says = nil
            p.visible = true
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)
    }

    /// After a game at home: the guests go out the front door, still aliens.
    private func leaveHome(players: [Person], kids: [(kid: Person, mother: Person)], goingAlien: [Person], daughter: Person) async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        caption = "The players head for the front door…"
        try await look(at: Stage.full)
        let leaving = players.flatMap { p in [p] + kids.filter { $0.mother === p }.map(\.kid) }
        for p in leaving + [daughter, mom] { p.atTable = false }
        try await walkAll(leaving.indices.map { (leaving[$0], Stage.doorX + 20 + Double($0) * 22) }, speed: 110)
        for p in leaving { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 800, height: 300))
        caption = "Out they go — still Roswell aliens! The change wears off when they get home."
        for p in goingAlien.prefix(2) {
            try await say(p, p.isKid ? ["I get to stay an alien all the way home!", "Wait till my friends see me!", "That was SO cool!"].randomElement()!
                                     : ["I'm going home a Roswell alien!", "Thanks for having us over!", "Won't the neighbors be surprised!"].randomElement()!, 2.2)
        }
        nightHouseholds += players.map { p in [p] + kids.filter { $0.mother === p }.map(\.kid) }
        doorOpenUntil = .now + 2.4
        try await walkAll(leaving.map { ($0, Stage.doorX) }, speed: 110)
        for p in leaving { p.visible = false }
        customers = []
        try await sayAll([ava, mia, rosie], "Bye!", 1.4)
    }

    /// A woman strolls by, sometimes with her daughter, and Mom asks her to play.
    /// Returns her, the girl if she brought one, whether the girl wants to be an alien too, and whether she gets a seat.
    /// `outside`: a just-for-fun game — she's strolling down the street outside the house, and there's no buy-in.
    private func askPasserby(_ game: CasinoGame, slot: Int, filled: Int, need: Int, mustSayYes: Bool,
                             outside: Bool = false) async throws -> (Person, Person?, Bool, Bool)? {
        let (mom, ava, rosie) = (mom, ava, rosie)
        if womenNames.isEmpty {
            womenNames = ["Angela", "Bonnie", "Brenda", "Carol", "Cheryl", "Denise", "Diane", "Donna", "Ellen", "Fran", "Gina", "Holly",
                          "Iris", "Joyce", "Karen", "Lena", "Linda", "Maria", "Nancy", "Olivia", "Paula", "Peggy", "Rachel", "Rita",
                          "Sandy", "Terri", "Tina", "Val", "Wendy", "Yolanda"].shuffled()
        }
        if kidNames.isEmpty {
            kidNames = ["Abby", "Bella", "Chloe", "Daisy", "Ellie", "Gracie", "Hailey", "Ivy", "Josie", "Katie", "Lily", "Maddie",
                        "Nora", "Piper", "Ruby", "Sophie", "Tessa", "Zoe"].shuffled()
        }
        let p = Person.customer(womenNames.popLast()!, kid: false, x: 1300)
        let kid = Double.random(in: 0...1) < 0.35 ? Person.customer(kidNames.popLast()!, kid: true, x: 1335) : nil
        customers.append(p)
        if let kid { customers.append(kid) }
        let stroll = 85.0
        _ = beginWalk(p, to: -150, speed: stroll)
        if let kid { _ = beginWalk(kid, to: -115, speed: stroll) }
        try await sleep((1300 - Stage.stopX) / stroll)
        stop(p)
        if let kid { stop(kid) }
        mom.facing = 1

        if outside {
            try await say(mom, "Hi! Want to come over and play \(game.name) with us? No buy-in — it's just for fun!", 2.8)
        } else {
            try await say(mom, "Hi! Want to play \(game.name) with us? Buy-in is $\(CasinoGame.buyIn)!", 2.8)
        }
        guard mustSayYes || Double.random(in: 0...1) < 0.55 else {
            try await say(p, ["No thanks, I'm not much for cards.", "Not tonight, sorry!", "Maybe another time.",
                              outside ? "I'm just out walking the dog, thanks!" : "I'm headed to the slots, thanks!",
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
        if outside {
            // A just-for-fun guest goes straight into the family's house to wait for the game.
            try await say(mom, kid == nil ? "Great! Go on in — make yourself at home!" : "Great! Go on in, you two — make yourselves at home!", 2.4)
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
        let from = p.x(at: .now)
        _ = beginWalk(p, to: Stage.waitX[slot], speed: 140)
        if let kid { _ = beginWalk(kid, to: Stage.waitX[slot + 1], speed: 140) }
        try await sleep((from - Stage.waitX[slot]) / 140 + 0.1)
        p.facing = 1
        kid?.facing = 1
        return (p, kid, alien, plays)
    }

    /// Hands against the house; you make your own calls at `human`'s seat.
    /// Returns each player's final line, her cash-out and how many hands were dealt.
    private func playMoney(_ game: CasinoGame, _ players: [Person], house: Person, human: Int?) async throws -> ([String], [Int], Int) {
        var chips: [Int?] = players.map { _ in CasinoGame.buyIn }
        var rows = [BoardRow(id: house.id, value: "House", note: house === mom ? "Mom deals and banks" : "Mom deals")]
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
            caption = "Hand \(hand): Mom deals \(game.name)."
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
            caption = "It's getting late — Mom closes the table after \(dealt) hands."
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
                                              : game == .diamonds ? "\(game.target) rounds · most crystal points wins" : "First to \(game.target)",
                           rows: rows(), pot: nil)
        if game.isPartners {
            caption = "Partners: \(names[0]) & \(names[2]) vs. \(names[1]) & \(names[3])."
            try await sleep(2.4)
        }
        let seats = host(human: human, seatX: [Stage.dealerX] + Stage.spotX)
        var hand = 0
        var dealer = Int.random(in: 0..<names.count)
        while Tricks.winners(game, scores: scores, hands: hand) == nil && hand < 30 {
            board?.status = "Hand \(hand + 1) · \(names[dealer]) deals · " + (game == .hearts ? "ends at \(game.target)" : game == .diamonds ? "of \(game.target)" : "to \(game.target)")
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
