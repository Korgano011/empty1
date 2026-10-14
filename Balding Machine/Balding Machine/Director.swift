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
    var everyone: [Person] { cast + customers }

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
    var domePerson: Person?
    var boothT0 = Date.distantPast
    var pressT0 = Date.distantPast

    // Public appearance
    var venue: Venue?
    var choosingVenue = false
    var cash = Venue.startCash
    /// Donations collected for St. Baldrick's (never part of the family's cash).
    var raised = 0
    /// Floating "+$" / "-$" over where the money changed hands.
    var cashPop: (text: String, t0: Date, x: Double)?
    var result: EventRecord?
    /// Where the booth sits: the empty room, or the middle of the venue.
    var boothDX: Double { venue == nil ? 0 : Stage.venueShift }

    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var venuePick: CheckedContinuation<Venue, Never>?
    @ObservationIgnored private var served: [PersonSpec] = []
    @ObservationIgnored private var asked = 0
    @ObservationIgnored private var earned = 0
    @ObservationIgnored private var adultNames: [String] = []
    @ObservationIgnored private var kidNames: [String] = []

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
        guard domePerson != nil else { return screen }
        let (phase, u) = BoothRun.phase(now.timeIntervalSince(boothT0))
        switch phase {
        case .lowering: return "LOWERING"
        case .filling: return "CREAM IN"
        case .soaking:
            let left = max(0, 60 - Int(u * 60))
            return String(format: "0:%02d", left)
        case .rinsing: return "RINSING"
        case .drying: return "DRYING"
        case .lifting, .done: return "DONE!"
        }
    }

    func start() {
        task?.cancel()
        venuePick?.resume(returning: .carnival)
        venuePick = nil
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
        domePerson = nil
        boothT0 = .distantPast
        pressT0 = .distantPast
        venue = nil
        choosingVenue = false
        customers = []
        served = []
        asked = 0
        earned = 0
        cash = Venue.startCash
        raised = 0
        cashPop = nil
        result = nil
        adultNames = ["Brenda", "Carlos", "Denise", "Eddie", "Gina", "Hank", "Iris", "Jamal", "Lena", "Paula", "Rita", "Steve"].shuffled()
        kidNames = ["Amy", "Ben", "Cora", "Danny", "Emma", "Finn", "Gwen", "Hannah", "Jade", "Max"].shuffled()
        task = Task {
            do { try await story() } catch {}
        }
    }

    func choose(_ venue: Venue) {
        venuePick?.resume(returning: venue)
        venuePick = nil
        choosingVenue = false
    }

    /// 0…1 black-out used when the scene changes.
    func fade(at now: Date) -> Double {
        let t = now.timeIntervalSince(fadeT0)
        guard t >= 0 && t < 1.2 else { return 0 }
        return t < 0.5 ? t / 0.5 : max(0, 1 - (t - 0.7) / 0.5)
    }

    // MARK: Story

    private func story() async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)

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

        try await say(rosie, "I'm bored… I'm going exploring!", 2.4)
        caption = "Rosie, who is five, wanders down the hall."
        try await walk(rosie, to: 300, speed: 150)
        rosie.facing = -1
        try await look(at: Stage.boothView)
        caption = "In the empty room, Rosie finds a booth with a chair and a glowing button!"
        try await say(rosie, "Ooh! A glowing button!", 2.4)
        try await say(rosie, "I wonder what it does…", 2.2)

        try await booth(rosie)
        try await say(rosie, "Whoa! My head is SO smooth!", 2.4)
        try await say(rosie, "I'm BALD! Hee hee hee!", 2.2)
        try await snap(rosie)

        caption = "Rosie waits in the living room for Mom to come home."
        try await look(at: Stage.full)
        try await walk(rosie, to: Stage.couchX[0], speed: 150)
        rosie.facing = 1
        try await sleep(1)
        caption = "A little while later…"
        try await sleep(1.6)

        // Mom comes home.
        doorOpenUntil = .now + 1.6
        (mom.x0, mom.x1, mom.moveDur) = (Stage.doorX, Stage.doorX, 0)
        mom.bags = true
        mom.visible = true
        try await sleep(0.3)
        try await walk(mom, to: 770)
        mom.facing = -1
        try await look(at: Stage.shot(centerX: 760, height: 280))
        try await say(mom, "I'm home! I got snacks and—", 2.2)
        mom.mood = .shocked
        try await sleep(0.6)
        try await say(mom, "ROSIE?! Where is your HAIR?!", 2.6)
        caption = "Ava and Mia hear Mom and come running."
        try await look(at: Stage.full)
        try await walkAll([(ava, 815), (mia, 842)], speed: 170)
        (ava.facing, mia.facing) = (-1, -1)
        try await look(at: Stage.shot(centerX: 775, height: 280))
        try await say(ava, "Whoa! Rosie is BALD!", 2)
        try await say(mia, "What happened?!", 1.8)
        try await say(mom, "Rosie, how did this happen?", 2.2)
        try await say(rosie, "I pressed a glowing button! Come see!", 2.6)
        mom.mood = .happy
        mom.bags = false

        caption = "Rosie leads everyone to the empty room."
        try await look(at: Stage.full)
        try await walkAll([(rosie, Stage.watchX[0] - 25), (mom, Stage.watchX[0]), (ava, Stage.watchX[1]), (mia, Stage.watchX[2])], speed: 150)
        for p in cast { p.facing = -1 }
        try await look(at: Stage.boothView)
        caption = "Mom reads the sign on the booth."
        signUntil = .now + 6
        try await sleep(6.2)
        try await say(mom, "A one-minute hair removal booth? So THAT'S what happened!", 3)
        try await say(ava, "Mom… think how much we spend on shampoo and haircuts!", 3)
        try await say(mia, "And conditioner! And hair ties! And the salon!", 2.6)
        try await say(mom, "You're right. We ARE spending too much money on our hair.", 3)
        try await say(ava, "I'll go next!", 1.8)

        try await booth(ava)
        try await say(ava, "It's so smooth! And no more brushing!", 2.6)
        try await say(rosie, "Now you're bald like me!", 2.2)
        try await snap(ava)
        try await walk(ava, to: Stage.watchX[1])
        ava.facing = -1

        try await say(mia, "My turn! My turn!", 1.8)
        try await booth(mia)
        try await say(mia, "Bye-bye, curls! Hello, bald!", 2.4)
        try await say(mom, "You look adorable!", 2)
        try await snap(mia)
        try await walk(mia, to: Stage.watchX[2])

        caption = "Three bald sisters turn to Mom…"
        for p in [ava, mia, rosie] { p.facing = 1 }
        mom.facing = -1
        try await look(at: Stage.shot(centerX: 305, height: 230))
        try await sayAll([ava, mia, rosie], "Bald your head, Mom!", 2.6)
        try await say(mom, "Ha! Okay, okay — here goes nothing!", 2.4)

        try await booth(mom)
        try await say(mom, "Oh my… I LOVE it! It's so smooth!", 2.6)
        try await say(rosie, "Mommy's bald too!", 2)
        try await snap(mom)

        caption = "The whole family heads to the living room."
        try await look(at: Stage.full)
        try await walkAll([(mom, 715), (ava, 745), (mia, 775), (rosie, 800)])
        for p in cast { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 758, height: 260))
        try await say(mia, "Four bald heads!", 2)
        try await say(mom, "And no more shampoo bills!", 2.2)
        try await say(rosie, "The glowing button was a GOOD idea, right?", 2.6)
        caption = "The whole family is bald — and saving money on hair!"
        try await sleep(2.4)

        try await publicAppearance()
        finished = true
        running = false
    }

    /// Sit, press the button, cream, rinse, then walk to the mirror for a look.
    private func booth(_ p: Person) async throws {
        let dx = boothDX
        caption = "\(p.id) sits down in the chair."
        if abs(p.x(at: .now) - Stage.seatX - dx) > 1 { try await walk(p, to: Stage.seatX + dx) }
        p.seated = true
        p.facing = 1
        boothClosed = true
        try await look(at: Stage.boothView.offsetBy(dx: dx, dy: 0))
        if venue != nil {
            rosie.facing = 1
            try await say(rosie, p.isKid ? "Press the glowing button!" : "Now press the glowing button!", 1.8)
        }

        caption = "\(p.id) presses the glowing button…"
        p.reachTo = CGPoint(x: Stage.button.x + dx, y: Stage.button.y)
        try await sleep(0.7)
        pressT0 = .now
        sound.beep()
        try await sleep(0.4)
        p.reachTo = nil

        let t0 = Date.now
        domePerson = p
        boothT0 = t0
        p.hairFadeT0 = t0 + BoothRun.lower + BoothRun.fill * 0.5
        p.hairFadeDur = BoothRun.fill * 0.5 + BoothRun.soak
        sound.motor(true)
        caption = "Whirr… a plastic dome comes down over \(p.id)'s head!"
        try await sleep(BoothRun.lower)
        sound.motor(false)
        let head = Pose(p, feet: CGPoint(x: Stage.seatX + dx, y: Stage.floorY), facing: 1, now: .now).head
        let top = Stage.booth.minY
        cut(to: Stage.focus(CGPoint(x: Stage.seatX + dx + 20, y: (head.y + top) / 2 + 12), height: max(220, head.y - top + 90)))
        caption = "The dome fills up with hair removal cream!"
        sound.gloop(true)
        try await sleep(BoothRun.fill)
        caption = "The cream works for one minute… (the clock is sped up!)"
        try await sleep(BoothRun.soak)
        sound.gloop(false)
        sound.rinse(true)
        caption = "Whoosh! A warm rinse washes the cream — and the hair — away."
        try await sleep(BoothRun.rinse)
        sound.rinse(false)
        sound.dryer(true)
        caption = "Fwoosh! Warm air blows \(p.id)'s head dry."
        try await sleep(BoothRun.dry)
        sound.dryer(false)
        sound.motor(true)
        p.bald = true
        caption = "The dome lifts…"
        try await sleep(BoothRun.lift)
        sound.motor(false)
        domePerson = nil
        screen = "DONE!"
        sound.ding()
        caption = "Ding! \(p.id) has a smooth bald head!"
        try await sleep(1.2)

        p.seated = false
        boothClosed = false
        cut(to: Stage.boothView.offsetBy(dx: dx, dy: 0))
        try await walk(p, to: Stage.mirrorStand + dx)
        p.facing = -1
        screen = "READY"
        try await look(at: Stage.shot(centerX: 385 + dx, height: max(p.height, 120) + 110))
    }

    /// Snap! A before-and-after photo for the album.
    private func snap(_ p: Person) async throws {
        caption = "Snap! \(p.id)'s before-and-after photo goes in the album."
        flashT0 = .now
        sound.shutter()
        album.add(AlbumEntry(date: .now, spec: PersonSpec(p)))
        try await sleep(1.4)
    }

    // MARK: Public appearance

    private func publicAppearance() async throws {
        let (mom, ava, mia, rosie) = (mom, ava, mia, rosie)
        caption = "The family has an idea…"
        try await say(ava, "Mom, other families must spend a fortune on hair too!", 2.8)
        try await say(mia, "Let's give the booth a public appearance!", 2.6)
        try await say(rosie, "Everybody can press the glowing button!", 2.4)
        try await say(mom, "We'll have to pay for the setup. We've saved $\(Venue.startCash)!", 2.8)

        try await look(at: Stage.full)
        caption = "Pick where the family takes the booth for its public appearance."
        let venue = await withCheckedContinuation { cont in
            venuePick = cont
            choosingVenue = true
        }
        try Task.checkCancellation()

        // Scene change: pack up the booth and head out.
        fadeT0 = .now
        try await sleep(0.5)
        self.venue = venue
        boothClosed = false
        screen = "READY"
        for (p, x) in [(rosie, Stage.hostX), (ava, Stage.greetX[0]), (mia, Stage.greetX[1]), (mom, Stage.momX)] {
            p.says = nil
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
        }
        (camFrom, camTo) = (Stage.full, Stage.full)
        try await sleep(0.8)

        caption = "They set up the booth at the \(venue.name). Setup fee: $\(venue.fee)."
        cash -= venue.fee
        cashPop = ("-$\(venue.fee)", .now, Stage.cashX)
        try await sleep(2)
        if venue.isCharity {
            try await say(mom, "Free shaves today! Donations go to St. Baldrick's to help kids with cancer!", 3.4)
        } else {
            try await say(mom, "Bald in one minute! Only $\(venue.price), kids just $\(venue.kidPrice)!", 3)
        }
        for n in 1...venue.groups {
            caption = "Visitor \(n) of \(venue.groups) comes strolling by."
            try await serveGroup(venue)
        }

        caption = "That's a wrap at the \(venue.name)!"
        try await walkAll([(mom, 900), (ava, 930), (mia, 958), (rosie, 985)])
        for p in cast { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 942, height: 250))
        let people = "\(served.count) \(served.count == 1 ? "person" : "people")"
        let profit = earned - venue.fee
        if venue.isCharity {
            try await say(ava, "We made \(people) bald and raised $\(raised) for St. Baldrick's!", 3)
            try await say(mom, "Best $\(venue.fee) we ever spent.", 2.4)
            try await say(rosie, "Can we come back next year?", 2)
        } else {
            try await say(ava, "We made \(people) bald and took in $\(earned)!", 2.8)
            if profit > 0 {
                try await say(mom, "That's $\(profit) profit after the $\(venue.fee) setup fee!", 2.8)
                try await say(mia, "Let's do this again!", 2)
            } else if profit == 0 {
                try await say(mom, "We broke even. Not bad for our first time!", 2.6)
            } else {
                try await say(mom, "We lost $\(-profit) on the setup fee… but it sure was fun!", 2.8)
            }
        }
        let record = EventRecord(date: .now, venue: venue, asked: asked, customers: served, fee: venue.fee, earned: earned,
                                 raised: raised, startCash: Venue.startCash, endCash: cash)
        album.add(record)
        result = record
        caption = "The \(venue.name) is saved in the album: \(served.count) went bald out of \(asked) asked."
    }

    /// Visitors stroll across from the right; Ava and Mia stop them and ask.
    /// Anyone who says no just keeps walking.
    private func serveGroup(_ venue: Venue) async throws {
        let (mom, ava, mia) = (mom, ava, mia)
        let adult = Person.customer(adultNames.popLast() ?? "Guest", kid: false, x: 1300)
        let kid = Double.random(in: 0...1) < venue.kidChance ? Person.customer(kidNames.popLast() ?? "Kiddo", kid: true, x: 1335) : nil
        let group = [adult] + (kid.map { [$0] } ?? [])
        customers = group
        asked += group.count

        let stroll = 80.0
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((1300 - Stage.stopX[0]) / stroll)
        for p in group { stop(p) }
        (ava.facing, mia.facing) = (1, 1)

        let noLines = ["No thanks!", "I like my hair, thanks!", "Maybe another time.", "Not today!"]
        try await say(ava, "Hi there! Want to be bald?", 2.2)
        let adultYes = Double.random(in: 0...1) < venue.adultYes
        try await say(adult, adultYes
            ? (venue.isCharity ? ["For the kids? Absolutely!", "I'm in — let's raise some money!", "Yes! I'll brave the shave!"]
                               : ["Sure, why not!", "In one minute? Let's do it!", "I've always wondered what I'd look like!"]).randomElement()!
            : noLines.randomElement()!, 2.2)

        var buyers = adultYes ? [adult] : []
        if let kid {
            try await say(mia, "Would you like to be bald too?", 2.2)
            if Double.random(in: 0...1) < venue.kidYes {
                try await say(kid, ["Yes! Can I? Please?", "Yeah! Like you!", "Ooh, I want to be bald!"].randomElement()!, 2)
                try await say(adult, adultYes ? "Let's do it together!" : "Okay, just you then, sweetie.", 2.2)
                buyers.append(kid)
            } else {
                try await say(kid, ["No way, I like my braids!", "Nope! I'm getting cotton candy!", "Maybe when I'm bigger."].randomElement()!, 2.2)
            }
        }

        guard !buyers.isEmpty else {
            caption = "\(adult.id) keeps walking."
            for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
            try await sleep((Stage.stopX[0] + 150) / stroll)
            customers = []
            return
        }

        // Pay Mom at the table — or drop a donation in the jar.
        mom.facing = 1
        if venue.isCharity {
            let amount = buyers.reduce(0) { $0 + ($1.isKid ? Int.random(in: 2...5) * 5 : Int.random(in: 4...12) * 5) }
            try await say(adult, "Here's $\(amount) for St. Baldrick's!", 2.2)
            raised += amount
            cashPop = ("♥ $\(amount)", .now, Stage.cashX)
            sound.ching()
            try await say(mom, "Thank you so much!", 1.8)
        } else {
            let amount = buyers.reduce(0) { $0 + ($1.isKid ? venue.kidPrice : venue.price) }
            try await say(mom, "That'll be $\(amount), please!", 2)
            cash += amount
            earned += amount
            cashPop = ("+$\(amount)", .now, Stage.cashX)
            sound.ching()
            try await sleep(1.2)
        }

        // First customer heads for the chair; everyone else waits by the mirror.
        caption = "\(buyers[0].id) heads over to the booth."
        let wait = Dictionary(uniqueKeysWithValues: zip(group.map(\.id), Stage.waitX))
        var moves = [(buyers[0], Stage.seatX + boothDX)]
        for p in group where p !== buyers[0] { moves.append((p, wait[p.id]!)) }
        try await walkAll(moves)
        for p in group where !p.seated { p.facing = -1 }

        for p in buyers {
            try await booth(p)
            try await say(p, p.isKid ? ["I'm SHINY!", "Look at my head!", "Best day EVER!"].randomElement()!
                                     : ["Wow! I look fantastic!", "So smooth! I love it!", "That was quick!"].randomElement()!, 2.4)
            served.append(PersonSpec(p))
            try await look(at: Stage.full)
            try await walk(p, to: wait[p.id]!)
            p.facing = -1
        }
        try await say(adult, venue.isCharity ? "Thank you! Proud to be bald for a good cause!"
                                             : ["Thank you! We love it!", "Best thing at the whole \(venue.name)!", "Wait till my friends see this!"].randomElement()!, 2.6)

        caption = "Off they go, bald and happy!"
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((Stage.waitX[1] + 150) / stroll)
        customers = []
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
