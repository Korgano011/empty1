import SwiftUI

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var mom: Person
    var olivia: Person
    var grace: Person
    var christina: Person

    var cast: [Person] { [mom, olivia, grace, christina] }
    /// The saucer's Roswell aliens; the last one is their leader.
    var crew: [Person] = []
    var customers: [Person] = []
    var everyone: [Person] { cast + [sitter, aunt, cousin, mailman, ex, bartender].compactMap { $0 } + officers + crew + customers }
    /// Who is home running the business: the whole family, the two girls left with the babysitter,
    /// or whoever is riding along while an aunt is visiting.
    var team: [Person] { visitCrew?.team ?? sitter.map { stayers + [$0] } ?? cast }
    /// The girls who stayed home, oldest first.
    private var stayers: [Person] { [olivia, grace, christina].filter { $0 !== traveler } }
    /// Each bed and who sleeps in it; the babysitter takes Mom's.
    var beds: [(Person, Double)] {
        var b = Array(zip(cast, Stage.bedX))
        if let sitter { b.append((sitter, Stage.bedX[0])) }
        return b
    }
    private var leader: Person { crew[crew.count - 1] }

    var caption = "Tap Start to begin."
    var running = false
    var finished = false
    var muted = false { didSet { sound.muted = muted } }

    var place = Place.house
    var boxes: [Double] = []
    var doorOpenUntil = Date.distantPast
    /// The glowing green button the aliens leave in the spare room.
    var buttonShown = false
    var buttonPressT0 = Date.distantPast

    // The flying saucer
    var saucerShown = false
    var saucerLanded = false
    /// Stars streak past the portholes.
    var shipFlying = false
    var beamOn = false
    var beamT0 = Date.distantPast
    private var saucerFrom = CGPoint.zero
    private var saucerTo = CGPoint.zero
    private var saucerT0 = Date.distantPast
    private var saucerDur = 0.0

    // The transformation deck
    var strapped: Set<String> = []
    var strapT0 = Date.distantPast
    var consolePressT0 = Date.distantPast
    var screen = "READY"
    /// The big mirror the aliens lower in front of the chairs, and when it goes back up.
    var mirrorT0 = Date.distantFuture
    var mirrorUpT0 = Date.distantPast
    /// The family member waiting for the player to pick her colour.
    var choosingColor: Person?

    var card: Card?
    var cardUntil = Date.distantPast
    var clockT0 = Date.distantPast
    var clockDur = 1.0
    var clockLabel = ""
    var clockSpan = 60
    var flashT0 = Date.distantPast
    var camFrom = Stage.full
    var camTo = Stage.full
    var camT0 = Date.distantPast
    var fadeT0 = Date.distantPast
    /// Night at the house: the sky goes dark and the moon comes out.
    var night = false
    /// Who is tucked into her bed at home.
    var sleeping: Set<String> = []

    // Trips to venues
    var venue: Venue?
    var choosingVenue = false
    var choosingNext = false
    var cash = Venue.startCash
    /// Floating "+$" / "-$" over where the money changed hands.
    var cashPop: (text: String, t0: Date, x: Double)?
    var result: EventRecord?
    var trips = 0
    /// Each time they do it again the pairs trade jobs: Mom and Christina stand outside, Olivia and Grace work the machine.
    var swapped = false
    var totalProfit = 0
    var totalTransformed = 0
    /// What Mom has put in the bank; setup fees come out of `cash` only.
    var bank = 0
    /// The teenage babysitter, while Mom is away on vacation.
    var sitter: Person?
    /// The daughter who goes on vacation with Mom.
    var traveler: Person?
    var choosingRest = false
    /// Everything the babysitters have been paid: one third of the profit on each of their trips.
    var sitterPaid = 0
    static let vacationCost = 150
    private static let sitterNames = ["Marcie", "Wanda", "Donna", "Gloria", "Lynda", "Laurie"]
    /// Nights the babysitter has stayed; Mom comes home the morning after the second.
    @ObservationIgnored private var vacations = 0
    /// Times this babysitter has been through the machine, and what she has earned.
    @ObservationIgnored private var sitterRides = 0
    @ObservationIgnored private var sitterStint = 0
    /// Rotates the babysitter-mode jobs each trip.
    @ObservationIgnored private var sitterRotation = 0
    /// Mom's sister and her little girl, visiting the morning after every even night.
    var aunt: Person?
    /// The mailman, delivering the letter from Mom's husband.
    var mailman: Person?
    /// Mom has had her talk with the girls about the divorce.
    private var divorceTalked = false
    // Rusty's Tavern, the night Mom's ex-husband gets cut off.
    var ex: Person?
    var bartender: Person?
    var officers: [Person] = []
    /// When he starts tearing the place up, and when the police lights show up outside.
    var rampageT0 = Date.distantFuture
    var policeT0 = Date.distantFuture
    private var barNightDone = false
    /// The divorce papers have come and Mom has signed them.
    private var papersSigned = false
    /// When Mom's pen touches the signature line on the divorce papers.
    var signT0 = Date.distantFuture
    var cousin: Person?
    /// While they visit: who rides, their jobs at the venue, who announces the profit, and the newcomer being shown around.
    var visitCrew: (team: [Person], greeter: Person, cashier: Person, host: Person, presser: Person, boss: Person, guest: Person)?
    /// Everything the aunts and cousins have been paid: a quarter of the profit on each of their trips.
    var visitorsPaid = 0
    @ObservationIgnored private var nights = 0
    @ObservationIgnored private var auntVisits = 0

    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var venuePick: CheckedContinuation<Venue, Never>?
    @ObservationIgnored private var colorPick: CheckedContinuation<AlienColor, Never>?
    @ObservationIgnored private var nextPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var restPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var served: [PersonSpec] = []
    @ObservationIgnored private var asked = 0
    @ObservationIgnored private var earned = 0
    @ObservationIgnored private var adultNames: [String] = []
    private static let menNames = ["Carlos", "Eddie", "Hank", "Jamal", "Steve", "Victor", "Kenji", "Luis"]
    private static let womenNames = ["Gina", "Iris", "Paula", "Nadia", "Leilani", "Carmen", "Dawn", "Lesley"]
    @ObservationIgnored private var momNames: [String] = []
    @ObservationIgnored private var kidNames: [String] = []

    init() {
        (mom, olivia, grace, christina) = Self.makeFamily()
    }

    /// Outside at a venue: the first greets, the second takes the money.
    private var outsidePair: (Person, Person) {
        if let v = visitCrew { return (v.greeter, v.cashier) }
        if sitter != nil { return (sitterRoles[0], sitterRoles[1]) }
        return swapped ? (mom, christina) : (olivia, grace)
    }
    /// Inside the saucer: the first works the controls, the second pushes the button.
    /// With the babysitter there are only three of them, so one works the machine alone.
    private var insidePair: (Person, Person) {
        if let v = visitCrew { return (v.host, v.presser) }
        if sitter != nil { return (sitterRoles[2], sitterRoles[2]) }
        return swapped ? (olivia, grace) : (mom, christina)
    }
    /// Babysitter mode: the older sister and the babysitter start outside; the jobs rotate each trip.
    private var sitterRoles: [Person] {
        let r = [stayers[0], sitter!, stayers[1]]
        return (0..<3).map { r[($0 + sitterRotation) % 3] }
    }

    /// Where each person's bedroom is; the babysitter uses Mom's.
    private func roomX(_ p: Person) -> Double {
        p === sitter ? Stage.roomX[0] : Stage.roomX[cast.firstIndex { $0 === p } ?? 0]
    }

    /// A teenage babysitter; each name has her own look.
    private static func makeSitter(_ name: String) -> Person {
        let i = sitterNames.firstIndex(of: name) ?? 0
        let skins = [RGB(r: 0.98, g: 0.84, b: 0.72), RGB(r: 0.86, g: 0.66, b: 0.50), RGB(r: 0.99, g: 0.86, b: 0.76),
                     RGB(r: 0.62, g: 0.42, b: 0.30), RGB(r: 0.96, g: 0.80, b: 0.68), RGB(r: 0.90, g: 0.72, b: 0.56)]
        let hairs = [RGB(r: 0.45, g: 0.28, b: 0.14), RGB(r: 0.12, g: 0.10, b: 0.08), RGB(r: 0.95, g: 0.82, b: 0.45),
                     RGB(r: 0.08, g: 0.06, b: 0.05), RGB(r: 0.72, g: 0.30, b: 0.12), RGB(r: 0.88, g: 0.72, b: 0.40)]
        let styles: [HairStyle] = [.ponytail, .curly, .long, .bob, .long, .ponytail]
        let shirts = [RGB(r: 0.90, g: 0.30, b: 0.45), RGB(r: 0.20, g: 0.65, b: 0.55), RGB(r: 0.95, g: 0.60, b: 0.20),
                      RGB(r: 0.45, g: 0.35, b: 0.80), RGB(r: 0.25, g: 0.50, b: 0.90), RGB(r: 0.98, g: 0.45, b: 0.65)]
        return Person(name, height: 146, headScale: 0.125, skin: skins[i], hair: hairs[i], style: styles[i],
                      shirt: shirts[i], pants: RGB(r: 0.25, g: 0.35, b: 0.60), x: Stage.doorX)
    }

    private static func makeFamily() -> (Person, Person, Person, Person) {
        let skin = RGB(r: 0.96, g: 0.80, b: 0.68)
        let mom = Person("Mom", height: 152, skin: skin, hair: RGB(r: 0.20, g: 0.12, b: 0.08), style: .bun,
                         shirt: RGB(r: 0.95, g: 0.55, b: 0.15), pants: RGB(r: 0.25, g: 0.30, b: 0.50), x: Stage.doorX)
        let olivia = Person("Olivia", height: 132, headScale: 0.13, skin: skin, hair: RGB(r: 0.45, g: 0.28, b: 0.14),
                            style: .long, shirt: RGB(r: 0.25, g: 0.55, b: 0.85), pants: RGB(r: 0.30, g: 0.30, b: 0.45), kid: true, x: Stage.doorX)
        let grace = Person("Grace", height: 116, headScale: 0.145, skin: skin, hair: RGB(r: 0.92, g: 0.78, b: 0.42),
                           style: .long, shirt: RGB(r: 0.60, g: 0.40, b: 0.80), pants: RGB(r: 0.30, g: 0.70, b: 0.40), kid: true, x: Stage.doorX)
        let christina = Person("Christina", height: 98, headScale: 0.16, skin: skin, hair: RGB(r: 0.75, g: 0.32, b: 0.14),
                          style: .pigtails, shirt: RGB(r: 0.98, g: 0.85, b: 0.25), pants: RGB(r: 0.95, g: 0.50, b: 0.70), kid: true, x: Stage.doorX)
        for p in [mom, olivia, grace, christina] { p.visible = false }
        return (mom, olivia, grace, christina)
    }

    private static func makeCrew() -> [Person] {
        zip(["Zib", "Norb", "Quix", "Plib", "Zorp"], [-60.0, -110, -160, 1260, 1310]).map { name, x in
            let p = Person.alienCrew(name, x: x)
            p.visible = false
            return p
        }
    }

    /// The part of the stage on screen; eases from `camFrom` to `camTo` over 0.9s.
    func camera(at now: Date) -> CGRect {
        let t = min(max(now.timeIntervalSince(camT0) / 0.9, 0), 1)
        let e = t * t * (3 - 2 * t)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * e }
        return CGRect(x: mix(camFrom.minX, camTo.minX), y: mix(camFrom.minY, camTo.minY),
                      width: mix(camFrom.width, camTo.width), height: mix(camFrom.height, camTo.height))
    }

    /// The middle of the saucer's disc, bobbing gently while it hovers.
    func saucer(at now: Date) -> CGPoint? {
        guard saucerShown else { return nil }
        let t = min(max(now.timeIntervalSince(saucerT0) / max(saucerDur, 0.001), 0), 1)
        let e = t * t * (3 - 2 * t)
        let bob = saucerLanded ? 0 : sin(now.timeIntervalSinceReferenceDate * 2) * 3
        return CGPoint(x: saucerFrom.x + (saucerTo.x - saucerFrom.x) * e, y: saucerFrom.y + (saucerTo.y - saucerFrom.y) * e + bob)
    }

    /// What the console's screen says.
    func screenText(_ now: Date) -> String {
        if let p = everyone.first(where: { $0.seated && $0.isTingling(at: now) }) {
            if now < p.changeT0 { return "TINGLE\nPHASE" }
            let left = Int((1 - p.progress(at: now)) * 300)
            return String(format: "TRANSFORMING\n%d:%02d", left / 60, left % 60)
        }
        return screen
    }

    func start() {
        task?.cancel()
        venuePick?.resume(returning: .lasVegas)
        venuePick = nil
        colorPick?.resume(returning: .green)
        colorPick = nil
        nextPick?.resume(returning: false)
        nextPick = nil
        restPick?.resume(returning: false)
        restPick = nil
        choosingRest = false
        sitter = nil
        traveler = nil
        sitterPaid = 0
        vacations = 0
        sitterRides = 0
        sitterStint = 0
        sitterRotation = 0
        aunt = nil
        mailman = nil
        divorceTalked = false
        papersSigned = false
        signT0 = .distantFuture
        ex = nil
        bartender = nil
        officers = []
        rampageT0 = .distantFuture
        policeT0 = .distantFuture
        barNightDone = false
        cousin = nil
        visitCrew = nil
        visitorsPaid = 0
        nights = 0
        auntVisits = 0
        sound.prepare()
        sound.stopAll()
        (mom, olivia, grace, christina) = Self.makeFamily()
        crew = Self.makeCrew()
        customers = []
        finished = false
        running = true
        place = .house
        boxes = []
        doorOpenUntil = .distantPast
        buttonShown = false
        buttonPressT0 = .distantPast
        saucerShown = false
        saucerLanded = false
        shipFlying = false
        beamOn = false
        strapped = []
        mirrorT0 = .distantFuture
        consolePressT0 = .distantPast
        screen = "READY"
        choosingColor = nil
        card = nil
        clockT0 = .distantPast
        flashT0 = .distantPast
        camFrom = Stage.full
        camTo = Stage.full
        camT0 = .distantPast
        fadeT0 = .distantPast
        venue = nil
        choosingVenue = false
        choosingNext = false
        cash = Venue.startCash
        cashPop = nil
        result = nil
        trips = 0
        swapped = false
        totalProfit = 0
        totalTransformed = 0
        bank = 0
        night = false
        sleeping = []
        task = Task {
            do { try await story() } catch {}
        }
    }

    func choose(_ venue: Venue) {
        venuePick?.resume(returning: venue)
        venuePick = nil
        choosingVenue = false
    }

    func choose(_ color: AlienColor) {
        colorPick?.resume(returning: color)
        colorPick = nil
        choosingColor = nil
    }

    func chooseRest(vacation: Bool) {
        restPick?.resume(returning: vacation)
        restPick = nil
        choosingRest = false
    }

    func chooseNext(again: Bool) {
        nextPick?.resume(returning: again)
        nextPick = nil
        choosingNext = false
    }

    /// 0…1 black-out used when the scene changes.
    func fade(at now: Date) -> Double {
        let t = now.timeIntervalSince(fadeT0)
        guard t >= 0 && t < 1.2 else { return 0 }
        return t < 0.5 ? t / 0.5 : max(0, 1 - (t - 0.7) / 0.5)
    }

    /// How far the mirror has come down, 0 (up in the ceiling) … 1 (in front of the family).
    func mirror(at now: Date) -> Double {
        let down = min(max(now.timeIntervalSince(mirrorT0) / 1.2, 0), 1)
        let up = min(max(now.timeIntervalSince(mirrorUpT0) / 1.0, 0), 1)
        let u = mirrorUpT0 > mirrorT0 ? down * (1 - up) : down
        return u * u * (3 - 2 * u)
    }

    // MARK: Story

    private func story() async throws {
        let (mom, olivia, grace, christina) = (mom, olivia, grace, christina)

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
        try await say(christina, "I LOVE my room!", 2)
        try await say(olivia, "Mine has a big window!", 2)
        try await say(grace, "Mine is purple!", 1.8)
        caption = "After moving in, all the rooms are taken — except one spare room at the back of the house."
        try await sleep(2.8)
        try await letterFromHusband()

        try await say(christina, "I'm going to go look in the spare room!", 2.4)
        caption = "Christina, who is five, wanders into the empty spare room and peeks out the back door."
        try await walk(christina, to: Stage.spareX[3], speed: 150)
        christina.facing = -1
        try await look(at: Stage.yardView)

        // A flying saucer comes down into the backyard.
        caption = "Something is coming down out of the sky…"
        saucerShown = true
        saucerLanded = false
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: -120), over: 0)
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: Stage.floorY - Stage.hoverLift), over: 3.5)
        sound.hum(true)
        try await sleep(3.6)
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: Stage.floorY - Stage.landedLift), over: 1.8)
        try await sleep(1.3)
        saucerLanded = true
        try await sleep(0.7)
        sound.hum(false)
        christina.mood = .shocked
        caption = "A flying saucer lands in the backyard!"
        try await say(christina, "A FLYING SAUCER! MOMMY! COME QUICK!", 2.6)

        caption = "Everyone comes running to the spare room."
        try await look(at: Stage.full)
        try await walkAll([(mom, Stage.spareX[0]), (olivia, Stage.spareX[1]), (grace, Stage.spareX[2])], speed: 170)
        for p in [mom, olivia, grace] { p.facing = -1 }
        try await look(at: Stage.yardView)
        mom.mood = .shocked
        try await say(mom, "Is that… a real flying saucer?!", 2.4)
        try await say(olivia, "It landed right in our backyard!", 2.2)
        try await say(grace, "Let's go check it out!", 2)
        mom.mood = .happy
        christina.mood = .happy

        caption = "The family goes outside to check it out."
        try await walkAll([(mom, 395), (olivia, 368), (grace, 342), (christina, 318)], speed: 130)
        try await say(christina, "It's so shiny!", 1.8)
        try await say(mom, "Stay close, girls. Let's take a closer look.", 2.4)
        caption = "They tiptoe closer…"
        try await walkAll(zip([mom, olivia, grace, christina], Stage.yardLine.reversed()).map { ($0, $1) }, speed: 55)
        for p in cast { p.facing = -1 }

        // The beam
        caption = "Suddenly the saucer lifts off its legs — and a beam switches on!"
        saucerLanded = false
        sound.hum(true)
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: Stage.floorY - Stage.hoverLift), over: 1.4)
        try await sleep(1.5)
        for p in cast { p.mood = .shocked }
        shout(cast, "AAAAH!", 2)
        caption = "The beam pulls them up inside the flying saucer!"
        try await beamUp(cast)
        for p in cast { p.mood = .happy }

        // Inside the saucer
        try await sceneChange {
            self.place = .ship
            self.saucerShown = false
            self.sound.hum(false)
            self.seat(self.cast, chairs: [0, 1, 2, 3])
            self.show(self.cast)
            self.cutNow(Stage.chairsView)
        }
        // Mom is the first to realize where they've landed.
        mom.mood = .smiling
        caption = "Mom blinks and looks around in wonder…"
        let momHead = Pose(mom, feet: CGPoint(x: mom.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head
        try await look(at: Stage.focus(CGPoint(x: momHead.x, y: momHead.y + 20), height: 220))
        try await say(mom, "Whoa! We floated right up here!", 2.4)
        try await say(mom, "We're inside a real flying saucer! How exciting!", 2.6)
        mom.mood = .happy
        // Pull back so all four are seen getting strapped in at once.
        try await look(at: Stage.chairsView)
        caption = "Suddenly, glowing straps snap across all four of them at once!"
        try await strap(cast)
        for p in cast { p.mood = .smiling }
        try await say(mom, "Ooh! Glowing seatbelts!", 2.2)
        caption = "They're buckled into four comfy chairs, like the start of a theme park ride!"
        try await say(mom, "It's just like a ride at an amusement park!", 2.4)
        try await say(christina, "I wonder where we're going!", 2)
        try await say(olivia, "This is so exciting, Mommy!", 2)
        for p in cast { p.mood = .happy }

        caption = "Then they're surrounded by Roswell aliens!"
        try await look(at: Stage.full)
        for p in crew { p.visible = true }
        try await walkAll(zip(crew, Stage.crewX).map { ($0, $1) }, speed: 120)
        for p in crew { p.facing = 0 }
        for p in cast { p.mood = .smiling }
        try await say(grace, "ALIENS! Real Roswell aliens! So cool!", 2.4)
        try await walk(leader, to: Stage.consoleX - 40, speed: 100)
        leader.facing = 0
        try await say(leader, "Welcome aboard, Earthlings. We come in peace.", 2.6)
        try await say(leader, "We heard about your husband filing for a divorce.", 2.8)
        try await say(mom, "You know about that?", 2)
        try await say(leader, "Today is your lucky day.", 2.2)
        for p in cast { p.mood = .happy }
        try await say(mom, "Our lucky day? Well… we could sure use one!", 2.6)
        try await say(christina, "Yay! Lucky day!", 1.8)
        try await say(leader, "Sit back and relax. You are going to love this.", 2.6)

        caption = "One of them pushes a glowing green button, and the machine tied to the chairs comes on…"
        try await runMachine(cast.map { ($0, AlienColor.green) }, presser: leader, change: Machine.change,
                             tingleLine: (grace, "Hee hee! It tickles!"), legsStartLine: (christina, "Ooh! My feet feel all fizzy!"),
                             legsLine: (olivia, "Cool! My legs are turning green!"),
                             bodyLine: (mom, "My arms and chest are turning green — this is amazing!"),
                             facesLine: "It's coming up to our faces!",
                             growingLines: ["Our heads are growing…", "…and growing!"], linesBy: mom)
        try await look(at: Stage.chairsView)
        caption = "The process takes five minutes. Now they're Roswell aliens from toe to face!"
        try await sleep(1.6)

        try await look(at: Stage.full)
        caption = "The transformation is complete."
        try await say(leader, "The transformation is complete. Look in the mirror, Earthlings.", 3.2)
        caption = "The aliens lower a big mirror in front of the family…"
        try await showMirror(cast, caption: "…and the family sees themselves for the first time!", calm: cast)
        for p in cast { p.mood = .smiling }
        try await look(at: Stage.chairsView)
        try await say(mom, "Wow… look at us, girls!", 2.2)
        try await say(mom, "We have been turned into Roswell Aliens!", 2.8)
        try await say(olivia, "We look so cool!", 1.8)
        for p in cast { p.mood = .happy }

        // One by one, they reach up and feel their new heads.
        caption = "The straps on their arms pop open, and one by one they feel their new heads…"
        strapped = []
        sound.clunk()
        try await sleep(1.2)
        for (p, line) in [(mom, "My head is so big… and so smooth!"), (olivia, "It's shaped like a giant egg!"),
                          (grace, "All my hair is gone — it's so smooth!"), (christina, "It feels like a big balloon! I love it!")] {
            let head = Pose(p, feet: CGPoint(x: p.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head
            try await look(at: Stage.focus(CGPoint(x: head.x, y: head.y + 12), height: 150))
            caption = "\(p.id) feels her new head…"
            p.feelHead = true
            try await sleep(0.8)
            try await say(p, line, 2.4)
            p.feelHead = false
            try await sleep(0.3)
        }
        for p in cast { p.mood = .happy }

        try await look(at: Stage.full)
        try await say(leader, "We are actually your friends.", 2.4)
        try await say(leader, "We transformed you so you can make some money.", 2.8)
        try await say(leader, "We will take you to a place of your choosing to get other people to try this.", 3.4)
        caption = "The aliens explain the deal…"
        card = .deal
        cardUntil = .now + 15
        try await sleep(15.2)
        try await say(leader, "Press one of these buttons, and this flying saucer will take you there.", 3.2)
        try await say(leader, "The only catch is you will have to pay for the setup.", 2.8)
        try await say(mom, "We have $\(Venue.startCash) saved. I guess we're in business!", 2.8)
        try await say(christina, "We're ALIENS! Cool!", 2)
        try await snap(cast)
        unstrap(cast)

        var first = true
        while true {
            try await tripToVenue()
            try await comeHome(first: first)
            if trips % 2 == 0 { try await restUntilMorning() }
            if cash < Venue.cheapestFee {
                try await say(sitter == nil ? mom : stayers[0], "We only have $\(cash) left — not enough for another setup fee.", 2.8)
            }
            first = false
            let again = await withCheckedContinuation { cont in
                nextPick = cont
                choosingNext = true
                caption = "Press the green button to do it again, or end the game?"
            }
            try Task.checkCancellation()
            guard again else { break }
            try await doItAgain()
        }

        caption = "Game over! \(trips) \(trips == 1 ? "trip" : "trips") in the flying saucer, \(totalTransformed) customers transformed, "
            + "\(totalProfit >= 0 ? "$\(totalProfit) profit" : "$\(-totalProfit) lost"). Family cash: $\(cash), savings in the bank: $\(bank)."
            + (sitterPaid > 0 ? " Babysitters were paid $\(sitterPaid)." : "")
            + (visitorsPaid > 0 ? " Aunts and cousins were paid $\(visitorsPaid)." : "")
        try await say(christina, "That was out of this world!", 2.6)
        finished = true
        running = false
    }

    private func reaction(_ color: AlienColor) -> String {
        switch color {
        case .green: "I'm a little green alien!"
        case .darkGreen: "Dark green, like a forest on Mars!"
        case .purple: "Purple! My favorite color from space!"
        case .pink: "A PINK alien! So cute!"
        case .orange: "Orange alien! Like a pumpkin from space!"
        case .lavender: "Lavender! Like a sunset on Mars!"
        case .lightBlue: "Light blue — out of this world!"
        case .brightRed: "Bright red! Like a fire truck from outer space!"
        case .emerald: "Emerald! Like a jewel from outer space!"
        case .lightGreen: "Light green, like a baby alien!"
        }
    }

    // MARK: The machine

    /// Presses the glowing green button: a tingle, then the change climbs from the legs to the face.
    private func runMachine(_ riders: [(Person, AlienColor)], presser: Person, change: Double,
                            tingleLine: (Person, String)? = nil, tingleShout: String? = nil, legsStartLine: (Person, String)? = nil, legsLine: (Person, String)? = nil,
                            bodyLine: (Person, String)? = nil, facesLine: String? = nil,
                            faceWarning: String? = nil, faceComing: String? = nil, faceLine: (Person, String)? = nil,
                            growingLines: [String] = [], linesBy: Person? = nil, focus: Person? = nil) async throws {
        presser.facing = presser.x(at: .now) < Stage.consoleX ? 1 : -1
        presser.reachTo = Stage.greenButton
        try await sleep(0.7)
        consolePressT0 = .now
        sound.beep()
        try await sleep(0.4)
        presser.reachTo = nil

        let t0 = Date.now + 0.2
        for (p, color) in riders {
            p.alien = color
            p.tingleT0 = t0
            p.changeT0 = t0 + Machine.tingle
            p.changeDur = change
            p.fade(to: 1, over: 0)
            p.shineT0 = .distantPast
        }
        let people = riders.map(\.0)
        // The camera follows `focus` alone if given, otherwise frames everyone in the chairs.
        let shown = focus.map { [$0] } ?? people
        let xs = shown.map { $0.x(at: .now) }
        let cx = (xs.min()! + xs.max()!) / 2
        let h = max(170, (xs.max()! - xs.min()! + 180) / 2)
        let names = shown.count == 4 ? "They" : shown.map(\.id).joined(separator: " and ")
        sound.tingle()
        caption = "\(names) first \(shown.count == 1 ? "feels" : "feel") a tingling sensation…"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 100), height: max(h, 230)))
        if let (p, s) = tingleLine { mention(p, s, 1.8) }
        if let tingleShout {
            // Once the tingle has sunk in, everyone speaks up together.
            try await sleep(1.6)
            shout(people, tingleShout, 2.6)
            try await sleep(Machine.tingle - 1.4)
        } else {
            try await sleep(0.2 + Machine.tingle)
        }

        sound.zap(true)
        clockT0 = .now
        clockDur = change
        clockLabel = "Five minutes later…"
        clockSpan = 300
        caption = "…then \(shown.count == 1 ? "\(names)'s legs start" : "their legs start") to transform!"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 45), height: h))
        if let (p, s) = legsStartLine { mention(p, s, 2.2) }
        if let (p, s) = legsLine {
            try await sleep(change * 0.08)
            mention(p, s, 2.4)
            try await sleep(change * 0.13)
        } else {
            try await sleep(change * 0.21)
        }
        caption = "It works its way up \(shown.count == 1 ? "the body" : "their bodies")…"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 105), height: h))
        if let (p, s) = bodyLine { mention(p, s, 1.8) }
        if let facesLine, let first = people.first {
            // The family speaks up the instant their faces start to change.
            let faceStart = first.changeT0 + change * 0.42
            try await sleep(max(0, faceStart.timeIntervalSinceNow))
            // `linesBy` says it alone; otherwise they all say it together.
            shout(linesBy.map { [$0] } ?? people, facesLine, 3)
            try await sleep(max(0, (faceStart + change * 0.02).timeIntervalSinceNow))
        } else if let (fp, s) = faceLine {
            // Close in on her face the moment it starts to change.
            // With `faceWarning`, she sees it coming just before it reaches her face.
            let faceStart = fp.changeT0 + change * 0.42
            let closeUp = faceStart - (faceWarning == nil ? 0 : 2.6)
            try await sleep(max(0, closeUp.timeIntervalSinceNow))
            let head = Pose(fp, feet: CGPoint(x: fp.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head
            cut(to: Stage.focus(CGPoint(x: head.x, y: head.y + 10), height: 150))
            if let faceWarning {
                caption = "The change reaches \(fp.id)'s neck…"
                mention(fp, faceWarning, 2.4)
                try await sleep(max(0, faceStart.timeIntervalSinceNow))
            }
            caption = "\(fp.id)'s face starts to change…"
            if let faceComing {
                // As it starts on her face she sees it's really happening, then screams.
                mention(fp, faceComing, 2)
                try await sleep(2.1)
            } else {
                try await sleep(faceWarning == nil ? 1.6 : 0.6)
            }
            mention(fp, s, 3.2)
            try await sleep(1.6)
        } else {
            try await sleep(change * 0.23)
        }
        let top = shown.map { Pose($0, feet: CGPoint(x: $0.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head.y }.min()!
        caption = "…all the way up to \(shown.count == 1 ? "the face" : "their faces")!"
        cut(to: Stage.focus(CGPoint(x: cx, y: top + 12), height: h))
        try await sleep(change * 0.2)
        // The head slowly swells from a round human head into a big Roswell egg.
        caption = shown.count == 1 ? "\(names)'s head is turning into a big Roswell alien head…"
                                    : "Their heads are turning into big Roswell alien heads…"
        cut(to: Stage.focus(CGPoint(x: cx, y: top), height: max(140, h * 0.8)))
        if growingLines.isEmpty {
            try await sleep(change * 0.36 + 0.3)
        } else {
            // They call out each stage of it as their heads swell.
            let span = change * 0.36 + 0.3
            let gap = min(4.2, span / Double(growingLines.count + 1))
            for line in growingLines {
                shout(linesBy.map { [$0] } ?? people, line, gap - 0.4)
                try await sleep(gap)
            }
            try await sleep(span - gap * Double(growingLines.count))
        }
        sound.zap(false)
        sound.chime()
        screen = "COMPLETE"
        for p in people { p.shineT0 = .now }
        try await sleep(1.2)
        screen = "READY"
    }

    /// Lowers the big mirror in front of the chairs so `people` can see what they've turned into, then raises it.
    /// `calm` (newcomers who are loving it) aren't shocked by what they see.
    private func showMirror(_ people: [Person], caption seen: String, seconds: Double = 4, calm: [Person] = []) async throws {
        sound.clunk()
        mirrorT0 = .now
        mirrorUpT0 = .distantPast
        try await sleep(1.6)
        let moods = people.map(\.mood)
        for p in people where p !== sitter && !calm.contains(where: { $0 === p }) { p.mood = .shocked }
        sound.shimmer()
        caption = seen
        try await sleep(seconds)
        mirrorUpT0 = .now
        try await sleep(1.1)
        for (p, m) in zip(people, moods) { p.mood = m }
    }

    private func seat(_ people: [Person], chairs: [Int]) {
        for (p, i) in zip(people, chairs) {
            p.seated = true
            p.facing = 0
            p.place(height: 0)
            (p.x0, p.x1, p.moveDur) = (Stage.chairX[i], Stage.chairX[i], 0)
        }
    }

    private func strap(_ people: [Person]) async throws {
        try await sleep(0.5)
        for p in people { strapped.insert(p.id) }
        strapT0 = .now
        sound.clunk()
        try await sleep(0.8)
    }

    private func unstrap(_ people: [Person]) {
        for p in people {
            strapped.remove(p.id)
            p.seated = false
        }
    }

    /// Snap! Before-and-after photos for the album.
    private func snap(_ people: [Person]) async throws {
        caption = "Snap! Before-and-after photos go in the album."
        flashT0 = .now
        sound.shutter()
        for p in people {
            if let color = p.alien { album.add(AlbumEntry(date: .now, spec: PersonSpec(p, color: color))) }
        }
        try await sleep(1.4)
    }

    // MARK: The flying saucer

    private func moveSaucer(to point: CGPoint, over seconds: Double) {
        saucerFrom = seconds == 0 ? point : saucer(at: .now) ?? point
        saucerTo = point
        saucerT0 = .now
        saucerDur = seconds
    }

    /// The beam lifts everyone up into the hatch.
    private func beamUp(_ people: [Person]) async throws {
        beamOn = true
        beamT0 = .now
        sound.beam(true)
        try await sleep(0.5)
        for (i, p) in people.enumerated() {
            p.facing = 0
            stop(p)
            p.float(to: Stage.beamRise, over: 2.4 + Double(i) * 0.15)
        }
        try await sleep(2.6 + Double(people.count) * 0.15)
        for p in people {
            p.visible = false
            p.place(height: 0)
        }
        beamOn = false
        sound.beam(false)
        try await sleep(0.3)
    }

    /// The beam sets people down on the ground at `xs`.
    private func beamDown(_ people: [Person], at xs: [Double]) async throws {
        beamOn = true
        beamT0 = .now
        sound.beam(true)
        try await sleep(0.5)
        for (i, (p, x)) in zip(people, xs).enumerated() {
            p.facing = 0
            p.seated = false
            (p.x0, p.x1, p.moveDur) = (x, x, 0)
            p.place(height: Stage.beamRise)
            p.visible = true
            p.float(to: 0, over: 2.2 + Double(i) * 0.15)
        }
        try await sleep(2.4 + Double(people.count) * 0.15)
        beamOn = false
        sound.beam(false)
        try await sleep(0.3)
    }

    /// Only these people are on stage.
    private func show(_ people: [Person]) {
        for p in everyone { p.visible = people.contains { $0 === p } }
    }

    // MARK: Trips

    private func tripToVenue() async throws {
        let (greeter, cashier) = outsidePair
        let (host, presser) = insidePair
        try await look(at: Stage.full)
        caption = "Press a button to pick where the flying saucer goes. Setup has to be paid for — they have $\(cash)."
        let venue = await withCheckedContinuation { cont in
            venuePick = cont
            choosingVenue = true
        }
        try Task.checkCancellation()

        caption = "Whoosh! The flying saucer zooms off to \(venue.theName)!"
        shipFlying = true
        sound.hum(true)
        try await sleep(2.6)

        try await sceneChange {
            self.shipFlying = false
            self.place = .venue
            self.venue = venue
            self.unstrap(self.team)
            self.show([])
            self.customers = []
            self.saucerShown = true
            self.saucerLanded = false
            self.moveSaucer(to: CGPoint(x: Stage.venueSaucerX, y: -120), over: 0)
            self.cutNow(Stage.full)
        }
        served = []
        asked = 0
        earned = 0
        adultNames = (Self.menNames + Self.womenNames).shuffled()
        momNames = ["Brenda", "Denise", "Lena", "Rita", "Tanya", "Monica", "Sara", "Wendy", "Stacy", "Sherry", "Michelle"].shuffled()
        kidNames = ["Amy", "Ben", "Cora", "Danny", "Ella", "Finn", "Gwen", "Hannah", "Jade", "Max", "Noah", "Kai",
                    "Dierdre", "Mary", "Sue", "Dawn", "Heidi"].shuffled()
        let startCash = cash

        moveSaucer(to: CGPoint(x: Stage.venueSaucerX, y: Stage.floorY - Stage.hoverLift), over: 2.4)
        caption = "The flying saucer comes down at \(venue.theName)!"
        try await sleep(2.6)
        sound.hum(false)
        caption = "Setting up at \(venue.theName) costs $\(venue.fee)."
        cash -= venue.fee
        cashPop = ("-$\(venue.fee)", .now, Stage.cashX)
        try await sleep(2)

        caption = host === presser ? "\(greeter.id) and \(cashier.id) stand outside, while \(host.id) works the machine."
                                   : "\(greeter.id) and \(cashier.id) stand outside, while \(host.id) and \(presser.id) work the machine."
        try await beamDown([greeter, cashier], at: Stage.beamSpot)
        try await walkAll([(greeter, Stage.greetX[0]), (cashier, Stage.greetX[1])])
        (greeter.facing, cashier.facing) = (1, 1)
        try await say(greeter, "Get transformed into a Roswell alien! Only $\(venue.price), kids $\(venue.kidPrice)!", 3)
        try await say(cashier, "Pick your color: green, pink, orange, lavender, or light blue!", 3)
        try await say(greeter, "And it wears off in eight hours!", 2.2)

        for n in 1...venue.groups {
            caption = "Visitor \(n) of \(venue.groups) comes strolling by."
            try await serveGroup(venue)
        }

        caption = "That's a wrap at \(venue.theName)!"
        (greeter.facing, cashier.facing) = (0, 0)
        try await look(at: Stage.shot(centerX: 670, height: 260))
        let people = "\(served.count) \(served.count == 1 ? "person" : "people")"
        try await say(greeter, "We transformed \(people) today!", 2.4)
        try await say(cashier, "Time to go home!", 1.8)
        let record = EventRecord(date: .now, venue: venue, asked: asked, customers: served, fee: venue.fee, earned: earned,
                                 startCash: startCash, endCash: cash)
        album.add(record)
        result = record
        trips += 1
        totalProfit += record.profit
        totalTransformed += served.count
    }

    /// Visitors stroll across from the right: a grown-up on their own, or a kid out with their mother.
    /// Anyone who pays steps into the beam and gets transformed in the chairs inside.
    private func serveGroup(_ venue: Venue) async throws {
        let (greeter, cashier) = outsidePair
        try await look(at: Stage.full)
        // Groups are at most three: a grown-up alone, or a mother with one or two kids.
        let withKid = Double.random(in: 0...1) < venue.kidChance
        let kidCount = withKid ? (Double.random(in: 0...1) < 0.4 ? 2 : 1) : 0
        let kids = (0..<kidCount).map { i in Person.customer(kidNames.popLast() ?? "Kiddo", kid: true, x: 1300 + Double(i) * 70) }
        let first = kids.first
            ?? adultNames.popLast().map { Person.customer($0, kid: false, female: Self.womenNames.contains($0), x: 1300) }
            ?? Person.customer("Guest", kid: false, female: false, x: 1300)
        let mother = withKid ? Person.customer(momNames.popLast() ?? "Mrs. Smith", kid: false, x: 1335) : nil
        let group = (kids.isEmpty ? [first] : kids) + (mother.map { [$0] } ?? [])
        customers = group
        asked += group.count

        let stroll = 85.0
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((1300 - Stage.stopX[0]) / stroll)
        for p in group { stop(p) }
        for p in group { p.facing = -1 }
        (greeter.facing, cashier.facing) = (1, 1)

        try await say(greeter, "Hi! Want to be turned into a Roswell alien?", 2.4)
        let firstYes = Double.random(in: 0...1) < (withKid ? venue.kidYes : venue.adultYes)
        if withKid {
            try await say(first, firstYes ? ["Yes! Can I? Please?", "An ALIEN? Cool!", "In a flying saucer? YES!"].randomElement()!
                                           : ["No way, that's too spooky!", "Nope! I'm scared of aliens!", "Maybe when I'm bigger."].randomElement()!, 2.2)
        } else {
            try await say(first, firstYes ? ["Sure, why not!", "Beam me up!", "I've always wanted to be an alien!"].randomElement()!
                                           : ["No thanks!", "Not today!", "Uh… I'll pass."].randomElement()!, 2.2)
        }
        var buyers = firstYes ? [first] : []
        if kids.count > 1 {
            let second = kids[1]
            try await say(greeter, "How about you?", 1.6)
            // A little brother or sister usually wants whatever the first kid gets.
            let secondYes = Double.random(in: 0...1) < (firstYes ? 0.85 : venue.kidYes * 0.5)
            try await say(second, secondYes ? (firstYes ? ["Me too! Me too!", "I want to be an alien too!"].randomElement()!
                                                        : ["Well, I'm not scared! I'll do it!", "I will! Beam me up!"].randomElement()!)
                                            : ["No thanks, I'll watch.", "Nuh-uh, too spooky!"].randomElement()!, 2.2)
            if secondYes { buyers.append(second) }
        }
        let kidsIn = !buyers.isEmpty
        let sweetie = buyers.count > 1 ? "kids" : "sweetie"
        if let mother {
            try await say(cashier, "Would you like to be transformed too?", 2.2)
            let momYes = Double.random(in: 0...1) < (kidsIn ? venue.momYes : venue.momYes * 0.5)
            if momYes {
                try await say(mother, kidsIn ? "Why not? Let's be aliens together!" : "Ha! Sure — I'll do it!", 2.4)
                buyers.append(mother)
            } else {
                try await say(mother, kidsIn ? "Oh no, I'll just watch. Go ahead, \(sweetie)!" : "No thanks, we're off to have fun!", 2.4)
            }
        }

        guard !buyers.isEmpty else {
            caption = group.count == 1 ? "\(first.id) keeps walking." : "They keep walking."
            for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
            try await sleep((Stage.stopX[1] + 150) / stroll)
            customers = []
            return
        }

        try await transformRound(buyers, group: group, payer: mother ?? first, venue: venue)

        // Anyone who said no has now seen it done — they get a second chance.
        let holdouts = group.filter { $0.alien == nil }
        if !holdouts.isEmpty {
            for p in holdouts { p.facing = -1 }
            greeter.facing = 1
            caption = "\(greeter.id) offers \(ListFormatter.localizedString(byJoining: holdouts.map(\.id))) a second chance."
            try await say(greeter, holdouts.count == 1 ? "Now that you've seen it up close — want a second chance?"
                                                      : "Now that you've seen it up close — anyone want a second chance?", 2.6)
            var second: [Person] = []
            for p in holdouts {
                let isMother = p === mother
                if isMother, let kid = kids.first(where: { $0.alien != nil }) {
                    try await say(kid, "Come on, Mom! Do it! Do it!", 2)
                }
                let yes = Double.random(in: 0...1) < (isMother ? 0.7 : p.isKid ? 0.7 : 0.55)
                let line = switch (yes, p.isKid) {
                case (true, true): ["Okay! I'm not scared anymore!", "It looks so fun! Me too!", "I changed my mind! Beam me up!"].randomElement()!
                case (true, false): ["Oh, why not — I'll do it too!", "You talked me into it!", "Okay, now I want to be an alien too!"].randomElement()!
                case (false, true): ["Still too spooky for me!", "Nope, I'll just watch."].randomElement()!
                case (false, false): ["No, I'm happy watching.", "Still no thanks — but it looks great!"].randomElement()!
                }
                try await say(p, line, 2.2)
                if yes { second.append(p) }
            }
            if second.isEmpty {
                caption = "Maybe next time!"
                try await sleep(1.4)
            } else {
                try await transformRound(second, group: group, payer: mother ?? first, venue: venue)
            }
        }

        caption = group.allSatisfy({ $0.alien != nil }) ? "Off they go, transformed into Roswell aliens!"
                                                         : "Off they go — some aliens, some not!"
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((Stage.waitX[1] + 150) / stroll)
        customers = []
    }

    /// One trip through the saucer for `buyers`: they pay the cashier, get beamed up and transformed, and come back down
    /// to the rest of `group`, who wait off to the side.
    private func transformRound(_ buyers: [Person], group: [Person], payer: Person, venue: Venue) async throws {
        let (greeter, cashier) = outsidePair
        let (host, presser) = insidePair
        // Pay at the table.
        let amount = buyers.reduce(0) { $0 + ($1.isKid ? venue.kidPrice : venue.price) }
        try await say(cashier, "That'll be $\(amount), please! It wears off in eight hours.", 2.8)
        caption = "\(payer.id) pays $\(amount)."
        payer.says = ["Here you go!", "Here's $\(amount)!", "Worth every penny!"].randomElement()!
        payer.saysUntil = .now + 1.6
        cash += amount
        earned += amount
        cashPop = ("+$\(amount)", .now, Stage.cashX)
        sound.pay()
        try await sleep(1.8)

        caption = "\(ListFormatter.localizedString(byJoining: buyers.map(\.id))) \(buyers.count == 1 ? "steps" : "step") under the flying saucer."
        var moves = zip(buyers, Stage.beamSpot).map { ($0, $1) }
        let others = group.filter { p in !buyers.contains { $0 === p } }
        for (p, x) in zip(others, Stage.waitX.reversed()) { moves.append((p, x)) }
        try await walkAll(moves)
        for p in group where !buyers.contains(where: { $0 === p }) { p.facing = -1 }
        try await beamUp(buyers)

        // Inside: one works the controls, the other pushes the button.
        let deckView = buyers.count == 3 ? CGRect(x: 300, y: 120, width: 820, height: 410) : CGRect(x: 440, y: 190, width: 680, height: 340)
        try await sceneChange {
            self.place = .ship
            self.seat(buyers, chairs: buyers.count == 3 ? [1, 2, 3] : Array([2, 3].prefix(buyers.count)))
            (host.x0, host.x1, host.moveDur, host.facing) = (Stage.controlX[0], Stage.controlX[0], 0, -1)
            (presser.x0, presser.x1, presser.moveDur, presser.facing) = (Stage.controlX[1], Stage.controlX[1], 0, -1)
            self.show([host, presser] + buyers)
            self.cutNow(deckView)
        }
        try await strap(buyers)
        try await say(host, buyers.count == 1 ? "Welcome aboard! Which color alien do you want to be?"
                                             : "Welcome aboard! Which colors do you want to be?", 2.6)
        var riders: [(Person, AlienColor)] = []
        for p in buyers {
            let color = AlienColor.allCases.randomElement()!
            try await say(p, ["\(color.name), please!", "I want to be \(color.name.lowercased())!", "\(color.name)! Definitely \(color.name.lowercased())!"].randomElement()!, 2)
            riders.append((p, color))
        }
        try await say(presser, "Hold still! I'm pushing the glowing green button!", 2.2)
        try await runMachine(riders, presser: presser, change: Machine.customerChange,
                             tingleLine: (buyers[0], "Ooh, that tingles!"))
        try await look(at: deckView)
        try await say(host, buyers.count == 1 ? "All done! Take a look in the mirror!" : "All done! Take a look in the mirror, everybody!", 2.4)
        caption = "\(host.id) lowers the big mirror in front of the chairs…"
        try await showMirror(buyers, caption: buyers.count == 1 ? "\(buyers[0].id) sees a Roswell alien looking back!"
                                                                 : "They see Roswell aliens looking back!", seconds: 3)
        for (p, color) in riders {
            try await say(p, p.isKid ? ["I'm a \(color.name.lowercased()) alien!", "Look at my big eyes!", "Best day EVER!"].randomElement()!
                                     : ["Wow! Look at me!", "I'm a real Roswell alien!", "That was out of this world!"].randomElement()!, 2.2)
            served.append(PersonSpec(p, color: color))
        }
        try await say(host, "You'll change back in eight hours. Enjoy!", 2.4)
        unstrap(buyers)

        // Back outside
        try await sceneChange {
            self.place = .venue
            self.show([greeter, cashier] + others)
            self.cutNow(Stage.full)
        }
        try await beamDown(buyers, at: Array(Stage.beamSpot.prefix(buyers.count)))
        // Someone still human cheers them on; if everyone waiting is already an alien, one of them welcomes the newcomers.
        if let watcher = others.first(where: { $0.alien == nil }) ?? others.first {
            watcher.facing = -1
            try await say(watcher, watcher.alien == nil ? "Look at you! You're an ALIEN!" : "Yay! Now we're aliens together!", 2.2)
        }
        try await say(buyers.last!, ["Thank you! We love it!", "Best thing at the whole \(venue.shortName)!", "Wait till my friends see this!"].randomElement()!, 2.4)
        try await say(greeter, "Remember — it wears off in eight hours!", 2.2)

    }

    /// The saucer takes them home: the transformation fades 50%, then one minute later it's gone.
    /// `gather` sends everyone to the green button afterwards.
    private func comeHome(first: Bool, gather: Bool = true) async throws {
        let (mom, olivia, grace, christina) = (mom, olivia, grace, christina)
        let team = team
        try await look(at: Stage.full)
        let (greeter, cashier) = outsidePair
        caption = "\(greeter.id) and \(cashier.id) beam back up, and the flying saucer takes \(sitter == nil ? "the family" : "them") home."
        try await walkAll([(greeter, Stage.beamSpot[0]), (cashier, Stage.beamSpot[1])])
        try await beamUp([greeter, cashier])
        sound.hum(true)
        moveSaucer(to: CGPoint(x: Stage.venueSaucerX, y: -150), over: 1.6)
        try await sleep(1.4)

        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.customers = []
            self.show([])
            self.moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: -120), over: 0)
            self.cutNow(Stage.full)
        }
        caption = "Home again!"
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: Stage.floorY - Stage.hoverLift), over: 2.4)
        try await sleep(2.5)
        try await look(at: Stage.yardView)
        let spots = Array(Stage.yardLine.reversed().prefix(team.count))
        try await beamDown(team + [leader], at: spots + [300])
        leader.facing = -1
        try await say(leader, "Thank you, Earthlings. Now that you are home, your transformation will wear off.", 3.4)
        try await say(leader, "Farewell!", 1.4)
        try await beamUp([leader])
        caption = "The flying saucer zooms away…"
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX + 500, y: -200), over: 2.2)
        try await sleep(2.3)
        saucerShown = false
        sound.hum(false)
        for p in team { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 200, height: 240))

        for p in team { p.fade(to: 0.5, over: 2.5) }
        sound.shimmer()
        caption = "…and the transformation fades 50 percent!"
        try await sleep(2.8)
        if let v = visitCrew {
            try await say(v.boss, "\(v.guest.id), you're only half an alien now!", 2.4)
            try await say(v.cashier === v.boss ? v.host : v.cashier, "One more minute and we'll be back to normal.", 2.4)
        } else if let sitter {
            try await say(stayers[1], "\(sitter.id), you're only half an alien now!", 2.4)
            try await say(stayers[0], "One more minute and we'll be back to normal.", 2.4)
        } else {
            try await say(christina, "Mommy, you're only half an alien now!", 2.4)
            try await say(olivia, "One more minute and we'll be back to normal.", 2.4)
        }

        clockT0 = .now
        clockDur = 6
        clockLabel = "One minute later…"
        clockSpan = 60
        caption = "One minute later… (sped up!)"
        try await sleep(clockDur - 1.5)
        for p in team { p.fade(to: 0, over: 1.5) }
        sound.shimmer()
        try await sleep(1.8)
        caption = "Everyone is back to normal!"
        try await say(visitCrew?.guest ?? (sitter == nil ? grace : stayers[1]), "We're human again!", 2)

        let profit = result?.profit ?? 0
        let earned = result?.earned ?? 0
        let boss = visitCrew?.boss ?? sitter ?? mom
        try await say(visitCrew?.host ?? (sitter == nil ? olivia : stayers[0]), "We took in $\(earned) today!", 2.2)
        if profit > 0 {
            try await say(boss, "That's $\(profit) profit after the setup fee!", 2.6)
        } else if profit == 0 {
            try await say(boss, "We broke even on the setup fee.", 2.4)
        } else {
            try await say(boss, "We lost $\(-profit) on the setup… but it sure was fun!", 2.8)
        }
        if let sitter {
            // The babysitter gets one third of the profit.
            if profit > 0 {
                let cut = profit / 3
                cash -= cut
                sitterPaid += cut
                sitterStint += cut
                sound.pay()
                caption = "\(sitter.id) gets her one third of the profit: $\(cut)."
                try await say(sitter, "And my third comes to $\(cut). Thanks, girls!", 2.6)
            } else {
                caption = "No profit this time, so there's no third for \(sitter.id)."
                try await sleep(2.2)
            }
        }

        guard gather else { return }
        if first {
            caption = "After they turn back, they notice something glowing in the spare room…"
            buttonShown = true
            try await look(at: Stage.full)
            try await say(christina, "Look! Something is glowing in the spare room!", 2.4)
            try await walkAll([(mom, Stage.spareX[0]), (olivia, Stage.spareX[1]), (grace, Stage.spareX[2]), (christina, Stage.buttonX - 22)], speed: 140)
            (mom.facing, olivia.facing, grace.facing, christina.facing) = (1, 1, -1, 1)
            try await look(at: Stage.shot(centerX: 500, height: 230))
            caption = "A glowing green button — with a message attached!"
            try await say(grace, "There's a note on it!", 1.8)
            card = .note
            cardUntil = .now + 9
            try await sleep(9.2)
            try await say(mom, "So we can do it again and make more money!", 2.6)
            try await say(olivia, "And this time we get to pick our colors!", 2.4)
        } else {
            caption = "The glowing green button is still waiting in the spare room."
            try await look(at: Stage.full)
            try await gatherAtButton()
        }
    }

    /// Everyone at home heads to the glowing green button in the spare room.
    private func gatherAtButton() async throws {
        if let sitter {
            let (older, younger) = (stayers[0], stayers[1])
            try await walkAll([(sitter, Stage.spareX[0]), (older, Stage.spareX[2]), (younger, Stage.buttonX - 22)], speed: 140)
            (sitter.facing, older.facing, younger.facing) = (1, -1, 1)
        } else {
            try await walkAll([(mom, Stage.spareX[0]), (olivia, Stage.spareX[1]), (grace, Stage.spareX[2]), (christina, Stage.buttonX - 22)], speed: 140)
            (mom.facing, olivia.facing, grace.facing, christina.facing) = (1, 1, -1, 1)
        }
        try await look(at: Stage.shot(centerX: 500, height: 230))
    }

    /// After every second trip. With the whole family home, they choose: two of them take a vacation
    /// (and a babysitter comes to help the other two), or the money goes in the bank.
    /// With the babysitter, the older sister does the shopping and the banking; Mom comes home the following morning
    /// and the babysitter goes home.
    /// The morning after every even night, an aunt drops off her little girl; they each get a first ride, and then
    /// it's another night.
    private func restUntilMorning() async throws {
        nights += 1
        let auntDay = nights % 2 == 0
        if auntDay {
            if sitter == nil {
                try await nightOut(shopper: mom, vacation: false)
            } else {
                try await nightOut(shopper: stayers[0], vacation: false)
                try await vacationOver(gather: false)
            }
            try await auntVisit()
            try await restUntilMorning()
            return
        }
        if sitter == nil {
            let vacation = await withCheckedContinuation { cont in
                restPick = cont
                choosingRest = true
                caption = "Two trips done! Take a mini vacation for two, or put the money in the bank?"
            }
            try Task.checkCancellation()
            if vacation {
                try await planVacation()
                try await nightOut(shopper: mom, vacation: true)
                try await babysitterArrives()
            } else {
                try await nightOut(shopper: mom, vacation: false)
                try await goodMorning(shopper: mom)
            }
        } else {
            // After the babysitter's two trips the older sister shops and banks, the babysitter stays over,
            // and Mom and the traveler come home the following morning.
            try await nightOut(shopper: stayers[0], vacation: false)
            try await vacationOver()
        }
    }

    /// Mom announces the vacation and pays for it; she'll take one of the girls.
    private func planVacation() async throws {
        let (mom, christina, grace, olivia) = (mom, christina, grace, olivia)
        let traveler = [christina, grace, olivia][vacations % 3]
        self.traveler = traveler
        try await look(at: Stage.shot(centerX: 520, height: 260))
        try await say(mom, "That's two trips! We've worked so hard — it's time for a mini vacation!", 3)
        try await say(mom, "\(traveler.id) and I are going on a mini vacation.", 2.6)
        traveler.mood = .shocked
        try await say(traveler, "Yay! A mini vacation!", 1.8)
        traveler.mood = .happy
        try await say(mom, "The mini vacation costs $\(Self.vacationCost), and whatever's left goes in the bank.", 3)
        cash -= Self.vacationCost
        sound.pay()
        caption = "Mom pays $\(Self.vacationCost) for the mini vacation. Cash left: $\(cash)."
        try await sleep(2.2)
        try await say(stayers[1], "But who's going to watch us?", 2.2)
        try await say(mom, "I'm hiring a babysitter. She'll be here first thing in the morning.", 3)
    }

    /// One of them goes out to buy food and make a deposit at the bank while the others rest; it's dark when she gets home,
    /// and the next morning everyone is up.
    private func nightOut(shopper: Person, vacation: Bool) async throws {
        let others = team.filter { $0 !== shopper }
        try await look(at: Stage.shot(centerX: 520, height: 260))
        if shopper === mom {
            try await say(mom, vacation ? "Now I'm going to buy some food and put the rest of our money in the bank."
                                        : "That's two trips! I'm going to buy some food and put our money in the bank.", 3)
            try await say(mom, vacation ? "While I'm gone, get some rest. The babysitter comes in the morning."
                                        : "While I'm gone, get some rest. We'll go again in the morning.", 3)
            try await say(christina, "Okay, Mommy!", 1.6)
            shout([olivia, grace], "Bye, Mom!", 1.6)
        } else {
            try await say(shopper, "That's two trips! I'm going to buy some food and put our money in the bank.", 3)
            if let sitter { try await say(sitter, "Okay, \(shopper.id) — be careful! We'll get some rest.", 2.6) }
            shout(others.filter { $0 !== sitter }, "Bye!", 1.6)
        }
        try await sleep(1.8)

        try await look(at: Stage.full)
        caption = "\(shopper.id) heads out the front door, and the others go to their rooms to rest."
        let shopperWalk = beginWalk(shopper, to: Stage.doorX, speed: 140)
        try await walkAll(others.map { ($0, roomX($0)) }, speed: 120)
        try await sleep(max(0, shopperWalk - 1))
        doorOpenUntil = .now + 1.2
        try await sleep(0.5)
        shopper.visible = false
        caption = "Everyone else climbs into bed for a rest."
        for p in others {
            p.visible = false
            sleeping.insert(p.id)
        }
        try await sleep(2.4)

        // In town: the grocery store, then the bank.
        try await sceneChange {
            self.place = .town
            self.show([shopper])
            (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
        }
        caption = "First stop: the grocery store."
        try await walk(shopper, to: Stage.storeDoorX, speed: 140)
        shopper.visible = false
        let food = min(Self.groceryBill, cash)
        caption = "\(shopper.id) buys $\(food) of groceries."
        try await sleep(1.6)
        cash -= food
        cashPop = ("-$\(food)", .now, Stage.storeDoorX)
        try await sleep(1.4)
        shopper.carrying = true
        shopper.groceries = true
        shopper.visible = true
        shopper.facing = 0
        try await say(shopper, "Dinner and breakfast — done!", 2.2)

        caption = "Next stop: the bank."
        try await walk(shopper, to: Stage.bankDoorX, speed: 140)
        shopper.visible = false
        // Keep enough for the next setup fee; the rest goes in the bank.
        let deposit = max(0, (cash - Self.keepForSetup) / 10 * 10)
        try await sleep(1.4)
        if deposit > 0 {
            cash -= deposit
            bank += deposit
            cashPop = ("Deposited $\(deposit)", .now, Stage.bankDoorX)
            sound.pay()
            caption = "\(shopper.id) deposits $\(deposit) in the bank. Savings: $\(bank)."
        } else {
            caption = "\(shopper.id) keeps what she has for the next setup fee."
        }
        try await sleep(2.2)
        shopper.visible = true
        shopper.facing = 0
        try await say(shopper, deposit > 0 ? "Our savings are growing!" : "Nothing extra to deposit today — we need it for the setup fee.", 2.6)
        try await walk(shopper, to: Stage.W + 60, speed: 150)

        // Home after dark.
        try await sceneChange {
            self.place = .house
            self.night = true
            (shopper.x0, shopper.x1, shopper.moveDur, shopper.facing) = (Stage.doorX, Stage.doorX, 0, -1)
            self.cutNow(Stage.full)
        }
        caption = "It's dark by the time \(shopper.id) gets home."
        doorOpenUntil = .now + 1.2
        try await walk(shopper, to: 760, speed: 110)
        shopper.carrying = false
        shopper.groceries = false
        shopper.facing = 1
        try await say(shopper, shopper === mom ? "Sleep tight, girls. Big day tomorrow." : "I'm home! The groceries are in.", 2.4)
        if shopper === mom && divorceTalked && !papersSigned { try await signDivorcePapers() }
        caption = "Now it's \(shopper.id)'s turn to get some rest."
        try await walk(shopper, to: roomX(shopper), speed: 110)
        shopper.facing = 0
        try await say(shopper, "What a day! Time for me to get some rest too.", 2.6)
        shopper.visible = false
        sleeping.insert(shopper.id)
        try await look(at: Stage.shot(centerX: shopper === mom ? 640 : roomX(shopper) - 40, height: 260))
        caption = "\(shopper.id) climbs into bed and gets some rest too."
        try await sleep(3)
        try await look(at: Stage.full)
        caption = "It's nighttime outside, and everyone gets a good night's sleep."
        try await sleep(4)
        if shopper === mom && !barNightDone { try await barFight() }

        try await sceneChange {
            self.night = false
            self.sleeping = []
            self.show(self.team)
            for p in self.team {
                (p.x0, p.x1, p.moveDur, p.facing) = (self.roomX(p), self.roomX(p), 0, 0)
            }
            self.cutNow(Stage.full)
        }
        caption = "The next morning…"
        sound.chime()
        try await sleep(1.2)
    }

    /// The first night Mom comes home with the groceries, while everyone sleeps: across town her ex-husband is refused service
    /// at Rusty's Tavern, goes mad and wrecks the place, and the police come and arrest him.
    private func barFight() async throws {
        barNightDone = true
        let man = { (name: String, height: Double, skin: RGB, hair: RGB, shirt: RGB, pants: RGB) in
            Person(name, height: height, skin: skin, hair: hair, style: .short, shirt: shirt, pants: pants, shorts: false, female: false, x: Stage.barDoorX)
        }
        let navy = RGB(r: 0.12, g: 0.18, b: 0.38)
        let rick = man("Rick", 180, RGB(r: 0.92, g: 0.74, b: 0.60), RGB(r: 0.30, g: 0.20, b: 0.12), RGB(r: 0.70, g: 0.16, b: 0.14), RGB(r: 0.20, g: 0.26, b: 0.45))
        let joe = man("Joe", 170, RGB(r: 0.78, g: 0.58, b: 0.44), RGB(r: 0.10, g: 0.08, b: 0.06), RGB(r: 0.96, g: 0.96, b: 0.94), RGB(r: 0.12, g: 0.12, b: 0.14))
        let cops = [man("Officer Brooks", 178, RGB(r: 0.62, g: 0.44, b: 0.32), RGB(r: 0.08, g: 0.06, b: 0.05), navy, navy),
                    man("Officer Diaz", 174, RGB(r: 0.86, g: 0.68, b: 0.54), RGB(r: 0.22, g: 0.14, b: 0.08), navy, navy)]
        try await sceneChange {
            self.place = .bar
            self.ex = rick
            self.bartender = joe
            self.officers = cops
            self.rampageT0 = .distantFuture
            self.policeT0 = .distantFuture
            self.show([rick, joe])
            (joe.x0, joe.x1, joe.moveDur, joe.facing) = (Stage.bartenderX, Stage.bartenderX, 0, -1)
            self.cutNow(Stage.full)
        }
        caption = "Meanwhile, across town, Mom's ex-husband Rick walks into Rusty's Tavern…"
        try await walk(rick, to: 790, speed: 110)
        rick.facing = 1
        try await look(at: Stage.shot(centerX: 840, height: 260))
        try await say(rick, "Gimme a beer. Make it a big one.", 2.4)
        try await say(joe, "Sorry, Rick. I can't serve you.", 2.2)
        rick.mood = .shocked
        try await say(rick, "What do you mean, you can't serve me?!", 2.4)
        try await say(joe, "You've been too combative in here one too many times. You're cut off.", 3.2)
        rick.mood = .angry
        try await say(rick, "CUT OFF?! Nobody cuts ME off!", 2.4)

        // The rampage: stools, tables, chairs, the sign, then every bottle on the back bar.
        caption = "Rick goes mad and starts tearing up the place!"
        try await look(at: Stage.full)
        rampageT0 = .now
        joe.mood = .shocked
        mention(rick, "AAAAARGH!", 2.2)
        for (at, _) in [(0.3, 0), (0.7, 0)] { Task { try? await self.sleep(at); self.sound.crash() } }
        try await sleep(0.9)
        try await walk(rick, to: 450, speed: 160)          // flips the near table at 2.1s
        sound.crash()
        mention(joe, "Hey! Knock it off!", 2)
        try await walk(rick, to: 250, speed: 160)          // and the far one, then the chairs
        sound.crash()
        try await sleep(0.3)
        sound.crash()
        mention(rick, "Nobody tells me no!", 2.2)
        try await sleep(1.2)
        try await walk(rick, to: 700, speed: 160)          // then the stools and the bottles
        let bottlesAt = rampageT0 + BarWreck.bottlesFrom
        try await sleep(max(0, bottlesAt.timeIntervalSinceNow))
        rick.reachTo = CGPoint(x: 760, y: 230)
        for _ in 0..<3 {
            sound.crash()
            try await sleep(0.75)
        }
        rick.reachTo = nil
        try await sleep(max(0, (rampageT0 + BarWreck.bottlesTo).timeIntervalSinceNow))
        try await say(joe, "That's it — I'm calling the police!", 2.4)

        // The police
        caption = "Sirens wail outside — the police are here!"
        sound.siren(true)
        policeT0 = .now + 0.8
        try await sleep(2.6)
        for c in cops { c.visible = true }
        doorOpenUntil = .now + 1.6
        try await walkAll([(cops[0], 630), (cops[1], 770)], speed: 150)
        cops[0].facing = 1
        cops[1].facing = -1
        sound.siren(false)
        try await look(at: Stage.shot(centerX: 700, height: 260))
        try await say(cops[0], "Police! Freeze! Put your hands behind your back!", 2.6)
        try await say(rick, "This guy won't even serve me a drink!", 2.4)
        try await say(cops[1], "Rick, you're under arrest for destroying this bar.", 2.8)
        rick.cuffed = true
        sound.clunk()
        caption = "The police slap the handcuffs on Rick…"
        rick.mood = .shocked
        try await say(rick, "You can't do this to me!", 2)
        try await say(cops[0], "Tell it to the judge.", 2)
        caption = "…and haul him off to jail."
        rick.mood = .angry
        try await look(at: Stage.full)
        try await walkAll([(cops[0], Stage.barDoorX - 30), (rick, Stage.barDoorX), (cops[1], Stage.barDoorX + 30)], speed: 110)
        doorOpenUntil = .now + 1.2
        try await sleep(0.4)
        for p in [rick] + cops { p.visible = false }
        joe.mood = .happy
        try await say(joe, "And don't come back!", 2)
        policeT0 = .distantFuture

        // Back home, they sleep right through it.
        try await sceneChange {
            self.place = .house
            self.show([])
            self.ex = nil
            self.bartender = nil
            self.officers = []
            self.rampageT0 = .distantFuture
            self.cutNow(Stage.full)
        }
        caption = "Back home, Mom and the girls sleep right through it."
        try await sleep(2.4)
    }

    /// Moving day: before Christina wanders off to the spare room, the mailman brings Mom a letter from her husband.
    private func letterFromHusband() async throws {
        let mom = mom
        let m = Person("Mailman", height: 172, skin: RGB(r: 0.80, g: 0.62, b: 0.48), hair: RGB(r: 0.25, g: 0.18, b: 0.12), style: .short,
                       shirt: RGB(r: 0.45, g: 0.60, b: 0.80), pants: RGB(r: 0.15, g: 0.20, b: 0.38), female: false, x: Stage.doorX)
        mailman = m
        caption = "Ding-dong! The mailman is at the front door."
        sound.chime()
        m.visible = true
        doorOpenUntil = .now + 1.6
        _ = beginWalk(mom, to: 740, speed: 120)
        try await walk(m, to: 790, speed: 90)
        m.facing = -1
        mom.facing = 1
        try await look(at: Stage.shot(centerX: 765, height: 240))
        try await say(m, "Good morning, ma'am. I have a letter for you.", 2.4)
        try await say(mom, "Thank you!", 1.6)
        try await say(m, "Welcome to the neighborhood!", 2)
        caption = "The mailman heads off on his route."
        try await walk(m, to: Stage.doorX, speed: 110)
        doorOpenUntil = .now + 1.2
        try await sleep(0.5)
        m.visible = false
        mailman = nil

        mom.facing = 0
        try await say(mom, "It's from my husband…", 2)
        caption = "Mom opens the letter and reads it."
        card = .letter
        cardUntil = .now + 17
        try await sleep(17)
        mom.mood = .shocked
        try await say(mom, "A divorce…", 2)
        try await say(mom, "What are we going to do to make money?", 2.6)
        try await say(mom, "I can't think about this right now. Today is moving day.", 2.8)
        mom.mood = .happy
        try await walk(mom, to: Stage.roomX[0], speed: 100)
        mom.facing = 0
        try await look(at: Stage.full)
    }

    /// The next time Mom comes home from shopping after telling the girls, the divorce papers are waiting, and she signs them.
    private func signDivorcePapers() async throws {
        papersSigned = true
        let mom = mom
        try await look(at: Stage.shot(centerX: 760, height: 240))
        caption = "A big envelope came in the mail while Mom was out…"
        mom.facing = 0
        try await sleep(1.6)
        try await say(mom, "The divorce papers. Just like he said.", 2.4)
        try await say(mom, "I told the girls I'd sign them to make it easy on ourselves.", 3)
        caption = "Mom signs the divorce papers."
        card = .papers
        signT0 = .now + 2.2
        cardUntil = .now + 7.5
        try await sleep(7.6)
        card = nil
        try await say(mom, "There. It's signed. I'll mail them back in the morning.", 2.8)
        try await say(mom, "Time to move on.", 2)
    }

    /// The first morning Mom is home after the first night, she tells the girls she is letting their father go.
    private func divorceTalk() async throws {
        divorceTalked = true
        let (mom, olivia, grace, christina) = (mom, olivia, grace, christina)
        try await look(at: Stage.shot(centerX: 690, height: 240))
        try await say(mom, "Girls, come here. There's something I need to tell you.", 2.6)
        try await walkAll([(christina, 640), (grace, 672), (olivia, 704), (mom, 745)], speed: 130)
        for p in [christina, grace, olivia] { p.facing = 1 }
        mom.facing = -1
        try await say(mom, "Your father was too combative in the first place.", 2.8)
        try await say(mom, "I think it's time to let him go, and move on.", 2.6)
        try await say(mom, "When the papers come, I will sign them to make it easy on ourselves.", 3.4)
        try await say(olivia, "We understand, Mom.", 2)
        try await say(grace, "We'll be okay — we have each other!", 2.2)
        try await say(christina, "We love you, Mommy!", 2)
        try await say(mom, "I love you too, girls. Now — let's go make some money!", 2.8)
        shout([olivia, grace, christina], "Yay!", 1.6)
        try await sleep(1.8)
    }

    /// An ordinary morning: rested, fed, and ready to go again.
    private func goodMorning(shopper: Person) async throws {
        let youngest = team.filter { $0 !== sitter }.last!
        try await say(youngest, "Good morning! I feel so rested!", 2.2)
        try await say(shopper, "Good morning! The groceries are in, and \(bank > 0 ? "we have $\(bank) in the bank" : "the bills are paid").", 3)
        if shopper === mom && !divorceTalked {
            try await divorceTalk()
        } else if let eager = team.first(where: { $0 !== shopper && $0 !== youngest }) {
            try await say(eager, "Let's go again!", 1.8)
        }
        try await gatherAtButton()
    }

    /// The morning Mom leaves: the babysitter arrives, Mom introduces her, and Mom and the traveler head off.
    private func babysitterArrives() async throws {
        guard let traveler else { return }
        let mom = mom
        let kids = stayers
        let name = Self.sitterNames[vacations % Self.sitterNames.count]
        vacations += 1
        let s = Self.makeSitter(name)
        try await say(mom, "Good morning, girls! The babysitter will be here any minute.", 2.8)
        try await walkAll([(traveler, 640), (kids[1], 675), (kids[0], 705), (mom, 745)], speed: 140)
        for p in [traveler, kids[1], kids[0], mom] { p.facing = 1 }

        caption = "Ding-dong! The babysitter is at the front door."
        sound.chime()
        sitter = s
        sitterRides = 0
        sitterStint = 0
        sitterRotation = 0
        s.visible = true
        (s.x0, s.x1, s.moveDur) = (Stage.doorX, Stage.doorX, 0)
        doorOpenUntil = .now + 1.6
        try await walk(s, to: 785, speed: 100)
        s.facing = -1
        try await look(at: Stage.shot(centerX: 715, height: 240))
        try await say(mom, "Girls, this is \(name). She'll be babysitting while \(traveler.id) and I are on our mini vacation.", 3.4)
        try await say(s, "Hi, girls! It's so nice to meet you!", 2.4)
        shout(kids, "Hi, \(name)!", 1.8)
        try await sleep(2)
        try await say(mom, "\(kids[0].id), \(kids[1].id) — show her how we make money.", 2.8)
        try await say(kids[0], "We will, Mom!", 1.8)
        try await say(s, "How do you girls make money?", 2.2)
        try await say(kids[1], "You'll see!", 1.6)
        try await say(mom, "\(name), you'll get one third of all the profit.", 2.8)
        try await say(s, "One third? Deal!", 1.8)
        try await say(mom, "We'll be back the morning after your day with the babysitter. Be good, girls!", 2.6)
        try await say(traveler, "Bye! We'll bring you souvenirs!", 2.2)
        shout(kids + [s], "Have fun!", 1.8)

        caption = "Mom and \(traveler.id) grab their suitcases and leave for their mini vacation."
        for p in [mom, traveler] { p.carrying = true }
        try await look(at: Stage.full)
        try await walkAll([(mom, Stage.doorX), (traveler, Stage.doorX)], speed: 120)
        doorOpenUntil = .now + 1.2
        try await sleep(0.5)
        for p in [mom, traveler] {
            p.visible = false
            p.carrying = false
        }
        s.facing = 0
        try await say(s, "Okay, girls — show me how you make money!", 2.6)
        try await say(kids[0], "Follow us to the spare room!", 2)
        try await gatherAtButton()
    }

    /// The morning after the babysitter's second night, Mom and the traveler come home and the babysitter goes home.
    private func vacationOver(gather: Bool = true) async throws {
        guard let sitter, let traveler else { return }
        let mom = mom
        let kids = stayers
        try await say(kids[1], "Good morning! Mom and \(traveler.id) come home today!", 2.4)
        try await walkAll([(sitter, 680), (kids[1], 715), (kids[0], 745)], speed: 140)
        for p in [sitter, kids[1], kids[0]] { p.facing = 1 }
        caption = "Mom and \(traveler.id) come home from their mini vacation!"
        for p in [mom, traveler] {
            p.carrying = true
            p.visible = true
            (p.x0, p.x1, p.moveDur) = (Stage.doorX, Stage.doorX, 0)
        }
        doorOpenUntil = .now + 1.6
        try await walkAll([(traveler, 778), (mom, 800)], speed: 90)
        for p in [mom, traveler] {
            p.carrying = false
            p.facing = -1
        }
        try await look(at: Stage.shot(centerX: 740, height: 240))
        try await say(mom, "We're home!", 1.8)
        shout(kids, "MOM! \(traveler.id)!", 1.8)
        try await sleep(2)
        try await say(traveler, "We had the best time! We brought you souvenirs!", 2.8)
        try await say(mom, "Did you show \(sitter.id) how we make money?", 2.6)
        try await say(kids[0], "We sure did! She was a \((sitter.alien ?? .green).name.lowercased()) Roswell alien!", 2.8)
        try await say(sitter, "Best babysitting job ever! My third of the profit came to $\(sitterStint)!", 3.2)
        try await say(mom, "Thank you, \(sitter.id)! Come back any time.", 2.4)
        try await say(sitter, "Bye, girls!", 1.6)
        caption = "\(sitter.id) heads home."
        try await walk(sitter, to: Stage.doorX, speed: 130)
        doorOpenUntil = .now + 1.2
        try await sleep(0.5)
        sitter.visible = false
        self.sitter = nil
        self.traveler = nil
        if !divorceTalked { try await divorceTalk() }
        guard gather else { return }
        try await say(mom, "Now — who wants to go again?", 2.2)
        try await look(at: Stage.full)
        try await gatherAtButton()
    }

    // MARK: The aunt's visit

    private static func makeVisitors(_ v: AuntVisit) -> (Person, Person) {
        let aunt = Person("Aunt \(v.aunt)", height: 154, skin: v.auntSkin, hair: v.auntHair, style: v.auntStyle,
                          shirt: v.auntShirt, pants: RGB(r: 0.28, g: 0.28, b: 0.42), x: Stage.doorX)
        let cousin = Person(v.cousin, height: v.cousinHeight, headScale: v.cousinHeadScale, skin: v.auntSkin, hair: v.cousinHair,
                            style: v.cousinStyle, shirt: v.cousinShirt, pants: RGB(r: 0.95, g: 0.55, b: 0.70), kid: true, x: Stage.doorX)
        return (aunt, cousin)
    }

    /// Mom's sister drops off her little girl so the two of them can go clothes shopping. Mom quietly tells the girls to
    /// take their cousin on a trip for a quarter of the profit; the cousin finds the button and the girls explain it.
    /// When the sisters get home the cousin shows off her money, her suspicious mother is shown the button, and she rides
    /// along with Mom and two of the girls — and she and her daughter get a quarter of that profit too.
    private func auntVisit() async throws {
        let (mom, olivia, grace, christina) = (mom, olivia, grace, christina)
        let v = AuntVisit.all[auntVisits % AuntVisit.all.count]
        auntVisits += 1
        let (a, c) = Self.makeVisitors(v)
        let auntName = "Aunt \(v.aunt)"
        aunt = a
        cousin = c

        // Ding-dong
        try await look(at: Stage.full)
        try await walkAll([(christina, 640), (grace, 675), (olivia, 705), (mom, 745)], speed: 140)
        for p in cast { p.facing = 1 }
        caption = "Ding-dong! It's \(auntName), Mom's sister, with her little girl \(c.id), who is \(v.age)."
        sound.chime()
        for p in [a, c] {
            (p.x0, p.x1, p.moveDur) = (Stage.doorX, Stage.doorX, 0)
            p.visible = true
        }
        doorOpenUntil = .now + 1.8
        try await walkAll([(c, 772), (a, 798)], speed: 100)
        for p in [a, c] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 720, height: 240))
        try await say(mom, "\(v.aunt)! And little \(c.id)! What a nice surprise!", 2.6)
        try await say(a, v.hello, 3.2)
        if auntVisits == 1 && barNightDone {
            // The first aunt brings the news about Rick.
            try await say(a, "But first — did you hear what happened to Rick?", 2.6)
            try await say(mom, "No… what happened?", 1.8)
            try await say(a, "He went to Rusty's Tavern, and they refused to serve him.", 2.8)
            try await say(a, "He went mad and started tearing up the whole place!", 2.8)
            for p in cast { p.mood = .shocked }
            try await say(a, "The police came and arrested him.", 2.4)
            try await say(mom, "Oh my goodness!", 1.8)
            try await say(a, "And he was sentenced to 20 years in prison.", 2.8)
            caption = "Rick was sentenced to 20 years in prison."
            try await say(olivia, "Twenty years?!", 1.8)
            for p in cast { p.mood = .happy }
            try await say(mom, "He was always too combative. I'm glad we let him go and moved on.", 3.2)
            try await say(grace, "We're safe now, Mom.", 2)
            try await say(christina, "And we have each other!", 2)
        }
        try await say(a, "Could the girls watch \(c.id) while we're out?", 2.4)
        try await say(mom, "Sure! I could use some new clothes myself.", 2.4)
        try await say(c, "Hi, cousins!", 1.6)
        shout([olivia, grace, christina], "Hi, \(c.id)!", 1.8)
        try await sleep(2)
        caption = "While \(auntName) looks for her car keys, Mom pulls the girls aside and whispers…"
        try await walkAll([(mom, 690)], speed: 90)
        mom.facing = -1
        try await say(mom, "Take \(c.id) on a trip, and give her a quarter of the profits.", 3)
        try await say(olivia, "We will, Mom!", 1.8)
        mom.facing = 1
        try await say(a, "Be good for your cousins, \(c.id)! We'll be back this afternoon.", 2.8)
        try await say(c, "Bye, Mommy!", 1.6)
        caption = "Mom and \(auntName) head out to go clothes shopping."
        try await walkAll([(mom, Stage.doorX), (a, Stage.doorX)], speed: 120)
        doorOpenUntil = .now + 1.2
        try await sleep(0.5)
        for p in [mom, a] { p.visible = false }

        // The cousin finds the button
        try await look(at: Stage.full)
        caption = "\(c.id) wanders off and finds the spare room…"
        try await walk(c, to: Stage.buttonX - 26, speed: 110)
        c.facing = 1
        try await look(at: Stage.shot(centerX: 500, height: 230))
        try await say(c, v.curious, 2.6)
        caption = "Her cousins come over to explain."
        try await walkAll([(olivia, Stage.spareX[0]), (christina, Stage.spareX[1] - 4), (grace, Stage.spareX[2])], speed: 150)
        (olivia.facing, christina.facing, grace.facing) = (1, 1, -1)
        try await say(olivia, "That's our secret, \(c.id). This is how we make money!", 2.8)
        try await say(grace, "We press the glowing green button, and a flying saucer comes to pick us up.", 3)
        try await say(christina, "Then real Roswell aliens turn us into aliens — any color we want!", 2.8)
        try await say(olivia, "We fly to fun places, and people pay us to turn them into aliens too.", 3)
        try await say(grace, "And it wears off in eight hours. That's how we make money!", 2.6)
        try await say(olivia, "Want to come on a trip with us? You get a quarter of the profit!", 2.8)
        c.mood = .smiling
        try await say(c, v.accept, 2.4)
        c.mood = .happy

        // The cousin's first ride: she asks the customers, Olivia takes the money, Grace and Christina work the machine.
        visitCrew = (team: [olivia, grace, christina, c], greeter: c, cashier: olivia, host: grace, presser: christina,
                     boss: olivia, guest: c)
        try await visitRide(newcomer: c, pusher: c, welcome: olivia, lines: v.cousinRide)
        try await say(olivia, "\(c.id) asks the customers, I take the money, and Grace and Christina work the machine.", 3.2)
        try await tripToVenue()
        try await comeHome(first: false, gather: false)
        let profit = result?.profit ?? 0
        let stash = max(0, profit / 4)
        if stash > 0 {
            caption = "\(c.id) gets a quarter of the profit: $\(stash)."
            try await say(olivia, "And a quarter of the profit is yours, \(c.id) — $\(stash)!", 2.6)
            cash -= stash
            visitorsPaid += stash
            cashPop = ("-$\(stash) to \(c.id)", .now, c.x(at: .now))
            sound.pay()
            c.mood = .smiling
            try await say(c, "$\(stash)! I'm going to give it all to my mommy!", 2.6)
            c.mood = .happy
        } else {
            try await say(olivia, "No profit to share this time, \(c.id) — sorry!", 2.4)
            try await say(c, "That's okay! Being an alien was the best part!", 2.4)
        }

        // That afternoon the shoppers come home.
        visitCrew = nil
        try await look(at: Stage.full)
        caption = "Everyone heads back inside."
        try await walkAll([(christina, 640), (c, 670), (grace, 700), (olivia, 730)], speed: 150)
        for p in [christina, c, grace, olivia] { p.facing = 1 }
        caption = "That afternoon, Mom and \(auntName) come home with bags of new clothes."
        for p in [mom, a] {
            (p.x0, p.x1, p.moveDur) = (Stage.doorX, Stage.doorX, 0)
            p.carrying = true
            p.groceries = true
            p.visible = true
        }
        doorOpenUntil = .now + 1.8
        try await walkAll([(a, 772), (mom, 798)], speed: 100)
        for p in [mom, a] {
            p.carrying = false
            p.groceries = false
            p.facing = -1
        }
        try await look(at: Stage.shot(centerX: 720, height: 240))
        try await say(a, v.back, 2.4)
        if stash > 0 {
            c.mood = .smiling
            try await say(c, v.showMoney, 2.8)
            cashPop = ("$\(stash) for Mommy", .now, c.x(at: .now))
            try await say(c, "$\(stash)! All for you!", 2)
            c.mood = .happy
            a.mood = .shocked
            for line in v.suspicious { try await say(a, line, 2.8) }
            try await say(mom, "Why don't you let \(c.id) show you?", 2.2)
        }
        // With no money to show, the aunt simply comes along to see what the girls have been up to.
        try await say(c, "Come see, Mommy! It's in the spare room!", 2.4)

        // The cousin shows her mother the button.
        try await look(at: Stage.full)
        caption = "\(c.id) leads her mother to the spare room."
        try await walkAll([(c, Stage.buttonX - 26), (a, Stage.spareX[2]), (mom, Stage.spareX[2] + 40),
                           (olivia, Stage.spareX[0]), (grace, 600), (christina, 630)], speed: 140)
        (c.facing, a.facing, olivia.facing) = (1, -1, 1)
        for p in [mom, grace, christina] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 240))
        try await say(c, "This glowing green button, Mommy! Press it, and a flying saucer comes!", 3)
        try await say(a, v.scoff, 2.6)
        try await say(mom, "Come on a trip with us, \(v.aunt), and see for yourself. Two of the girls will come too.", 3.2)
        let sisters = [olivia, grace, christina].shuffled()
        let (s1, s2, stayer) = (sisters[0], sisters[1], sisters[2])
        try await say(stayer, "I'll stay here and watch \(c.id)!", 2.2)
        a.mood = .happy
        try await say(a, v.auntAccept, 2.6)

        // The aunt's first ride, with Mom and two of the girls.
        visitCrew = (team: [mom, a, s1, s2], greeter: a, cashier: mom, host: s1, presser: s2, boss: mom, guest: a)
        try await say(c, "Can I press it for you, Mommy?", 2)
        try await visitRide(newcomer: a, pusher: c, welcome: mom, lines: v.auntRide)
        try await say(mom, "\(v.aunt) asks the customers, I take the money, and \(s1.id) and \(s2.id) work the machine.", 3.2)
        try await tripToVenue()
        try await comeHome(first: false, gather: false)
        let auntShare = max(0, (result?.profit ?? 0) / 4)

        // The two who stayed home come out to meet them.
        for (p, x) in [(stayer, 330.0), (c, 300)] {
            (p.x0, p.x1, p.moveDur, p.facing) = (Stage.spareX[1], Stage.spareX[1], 0, -1)
            p.visible = true
            _ = beginWalk(p, to: x, speed: 140)
        }
        try await sleep(1.4)
        c.facing = -1
        if auntShare > 0 {
            caption = "\(auntName) and \(c.id) get a quarter of the profit: $\(auntShare)."
            try await say(mom, "\(v.aunt), you and \(c.id) get a quarter of the profit — $\(auntShare)!", 3)
            cash -= auntShare
            visitorsPaid += auntShare
            cashPop = ("-$\(auntShare) to \(v.aunt) & \(c.id)", .now, a.x(at: .now))
            sound.pay()
            try await say(a, v.thanks, 2.8)
        } else {
            try await say(mom, "No profit to share this time, \(v.aunt) — sorry!", 2.6)
            try await say(a, "Don't be! I wouldn't have missed it for the world.", 2.6)
        }

        // Goodbyes
        try await look(at: Stage.full)
        caption = "Everyone walks \(auntName) and \(c.id) to the front door."
        try await walkAll([(c, 772), (a, 798), (christina, 640), (grace, 675), (olivia, 705), (mom, 745)], speed: 150)
        for p in cast { p.facing = 1 }
        for p in [a, c] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 720, height: 240))
        try await say(a, v.auntBye, 3)
        try await say(c, v.cousinBye, 2.6)
        shout([olivia, grace, christina], "Bye, \(c.id)! Bye, \(auntName)!", 2)
        try await sleep(1.6)
        caption = "\(auntName) and \(c.id) head home."
        try await walkAll([(a, Stage.doorX), (c, Stage.doorX)], speed: 120)
        doorOpenUntil = .now + 1.2
        try await sleep(0.5)
        aunt = nil
        cousin = nil
        visitCrew = nil
    }

    /// A newcomer's first ride: `pusher` presses the green button, the saucer comes back, and everyone on the `team`
    /// rides — the newcomer loving every second of it.
    private func visitRide(newcomer n: Person, pusher: Person, welcome: Person, lines: RideLines) async throws {
        let team = team
        caption = "\(pusher.id) presses the glowing green button…"
        try await walk(pusher, to: Stage.buttonX - 26)
        pusher.facing = 1
        pusher.reachTo = CGPoint(x: Stage.buttonX, y: Stage.floorY - 75)
        try await sleep(0.6)
        buttonPressT0 = .now
        sound.beep()
        try await sleep(0.5)
        pusher.reachTo = nil

        caption = "…and the flying saucer comes to the house!"
        try await look(at: Stage.full)
        saucerShown = true
        saucerLanded = false
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX - 400, y: -150), over: 0)
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: Stage.floorY - Stage.hoverLift), over: 3)
        sound.hum(true)
        try await sleep(3.1)
        n.mood = .smiling
        try await say(n, lines.spotSaucer, 2.6)
        n.mood = .happy
        caption = "Everyone hurries out to the backyard."
        try await walkAll(zip(team, Stage.yardLine.reversed()).map { ($0, $1) }, speed: 150)
        try await look(at: Stage.yardView)
        try await beamDown([leader], at: [320])
        leader.facing = -1
        try await say(leader, "A new Earthling. Welcome.", 2)
        try await say(welcome, "Don't worry, \(n.id) — they're our friends!", 2.2)
        try await say(leader, "Please line up and stand still.", 2.4)
        for p in team { p.facing = 0 }
        try await sleep(0.6)
        caption = "The beam pulls them all up — \(n.id) too!"
        mention(n, "Wheee!", 2)
        try await beamUp(team + [leader])

        try await sceneChange {
            self.place = .ship
            self.saucerShown = false
            self.sound.hum(false)
            self.seat(team, chairs: Array(0..<team.count))
            for (p, x) in zip(self.crew, Stage.crewX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
            }
            (self.leader.x0, self.leader.x1) = (Stage.consoleX - 40, Stage.consoleX - 40)
            self.show(team + self.crew)
            self.cutNow(Stage.full)
        }
        try await strap(team)
        caption = "Strapped into the chairs, surrounded by Roswell aliens."
        try await look(at: Stage.chairsView)
        try await say(n, lines.inShip, 3)
        try await say(leader, "Choose your colors, Earthlings.", 2.2)

        // The newcomer picks first.
        var colors: [ObjectIdentifier: AlienColor] = [:]
        for p in [n] + team.filter({ $0 !== n }) {
            try await look(at: Stage.focus(CGPoint(x: p.x(at: .now), y: Stage.floorY - 90), height: 230))
            caption = "What color Roswell alien does \(p.id) want to be?"
            let color = await withCheckedContinuation { cont in
                colorPick = cont
                choosingColor = p
            }
            try Task.checkCancellation()
            try await say(p, "I want to be \(color.name.lowercased())!", 1.8)
            colors[ObjectIdentifier(p)] = color
        }
        let riders = team.map { ($0, colors[ObjectIdentifier($0)] ?? .green) }
        try await look(at: Stage.full)
        try await say(leader, "Hold still, Earthlings.", 2)
        caption = "The alien pushes the glowing green button…"
        try await runMachine(riders, presser: leader, change: Machine.change,
                             tingleLine: (n, lines.tingle), legsStartLine: (n, lines.legs), bodyLine: (n, lines.body),
                             faceWarning: lines.faceWarning, faceComing: lines.faceComing,
                             faceLine: (n, lines.faceLine), focus: n)
        try await look(at: Stage.full)
        try await say(leader, "Look in the mirror, Earthlings.", 2.2)
        caption = "The aliens lower the big mirror in front of them…"
        try await showMirror(team, caption: "…and \(n.id) sees herself as a Roswell alien for the first time!", calm: [n])
        try await look(at: Stage.chairsView)
        n.mood = .smiling
        try await say(n, lines.mirror, 2.8)
        n.mood = .happy

        // Her straps pop open and she feels her new head, then rocks it from side to side.
        caption = "The straps on \(n.id)'s arms pop open…"
        strapped.remove(n.id)
        sound.clunk()
        try await sleep(1.0)
        let head = Pose(n, feet: CGPoint(x: n.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head
        try await look(at: Stage.focus(CGPoint(x: head.x, y: head.y + 12), height: 150))
        caption = "\(n.id) feels her new head…"
        n.feelHead = true
        try await sleep(0.8)
        try await say(n, lines.headFeel, 2.8)
        n.feelHead = false
        try await sleep(0.3)
        caption = "\(n.id) happily rocks her big new head from side to side…"
        n.rockT0 = .now
        n.rockDur = 3.6
        try await sleep(3.8)
        try await look(at: Stage.chairsView)
        for p in team where p !== n {
            try await say(p, reaction(colors[ObjectIdentifier(p)] ?? .green), 2.2)
        }
        try await say(welcome, "Welcome to the family business, \(n.id)!", 2.4)
        // Before the photo goes in the album, one of the sisters gets her to smile.
        try await look(at: Stage.focus(CGPoint(x: n.x(at: .now), y: Stage.floorY - 90), height: 230))
        let sister = team.filter { p in [olivia, grace, christina].contains { $0 === p } }.randomElement() ?? olivia
        try await say(sister, "Smile!", 1.4)
        n.mood = .smiling
        caption = "\(n.id) gives a big smile for the album…"
        try await sleep(1.2)
        try await snap(team)
        n.mood = .happy
        unstrap(team)
    }

    private static let groceryBill = 35
    private static let keepForSetup = 200

    /// Press the green button: the saucer comes back, and everyone picks her own colour.
    /// The babysitter's first time, the girls show her how it works and she gets green.
    private func doItAgain() async throws {
        let (mom, olivia, grace, christina) = (mom, olivia, grace, christina)
        let team = team
        let lead = sitter ?? mom
        let firstRide = sitter != nil && sitterRides == 0
        let sl = SitterRide.lines(for: sitter?.id ?? "")
        let pusher: Person
        if let sitter, firstRide {
            let (older, younger) = (stayers[0], stayers[1])
            try await say(older, "\(sitter.id), watch this! This is how we make money.", 2.8)
            try await say(older, "We press the glowing green button, and a flying saucer comes to get us.", 3)
            try await say(sitter, "A flying saucer? You girls are pulling my leg!", 2.6)
            pusher = younger
            try await say(younger, "I'll press it!", 1.6)
        } else {
            try await say(lead, "Let's do it again!", 1.8)
            if sitter != nil { sitterRotation += 1 } else { swapped.toggle() }
            try await say(lead, "Who wants to do the honors?", 2.2)
            pusher = team.randomElement()!
            try await say(pusher, pusher === lead ? "You know what? I'll do it myself!"
                                                  : ["Me! Me! I'll do it!", "I will!", "Ooh, let me!"].randomElement()!, 1.8)
        }
        caption = "\(pusher.id) presses the glowing green button…"
        try await walk(pusher, to: Stage.buttonX - 26)
        pusher.facing = 1
        pusher.reachTo = CGPoint(x: Stage.buttonX, y: Stage.floorY - 75)
        try await sleep(0.6)
        buttonPressT0 = .now
        sound.beep()
        try await sleep(0.5)
        pusher.reachTo = nil

        caption = "…and the flying saucer returns to the house!"
        try await look(at: Stage.full)
        saucerShown = true
        saucerLanded = false
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX - 400, y: -150), over: 0)
        moveSaucer(to: CGPoint(x: Stage.yardSaucerX, y: Stage.floorY - Stage.hoverLift), over: 3)
        sound.hum(true)
        try await sleep(3.1)
        try await say(sitter == nil ? christina : stayers[1], "It's back! Come on!", 1.8)
        caption = "Everyone hurries out to the backyard."
        try await walkAll(zip(team, Stage.yardLine.reversed()).map { ($0, $1) }, speed: 150)
        try await look(at: Stage.yardView)
        try await beamDown([leader], at: [320])
        leader.facing = -1
        if let sitter, firstRide {
            try await say(leader, "A new Earthling. Welcome.", 2)
            try await say(sitter, sl.seeAlien, 2.4)
            try await say(stayers[0], "Don't worry — they're our friends!", 2.2)
        }
        try await say(leader, "Please line up and stand still.", 2.4)
        for p in team { p.facing = 0 }
        try await sleep(0.6)
        caption = "The beam pulls them in again!"
        try await beamUp(team + [leader])

        try await sceneChange {
            self.place = .ship
            self.saucerShown = false
            self.sound.hum(false)
            self.seat(team, chairs: Array(0..<team.count))
            for (p, x) in zip(self.crew, Stage.crewX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
            }
            (self.leader.x0, self.leader.x1) = (Stage.consoleX - 40, Stage.consoleX - 40)
            self.show(team + self.crew)
            self.cutNow(Stage.full)
        }
        try await strap(team)
        caption = "Strapped into the chairs again, surrounded by Roswell aliens."
        try await say(leader, firstRide ? "Girls, choose your colors. The new Earthling will be green." : "This time, you choose your color.", 2.6)

        // Youngest first; the babysitter is green her first time.
        var colors: [ObjectIdentifier: AlienColor] = [:]
        let pickers: [Person]
        if let sitter {
            pickers = [stayers[1], stayers[0]] + (firstRide ? [] : [sitter])
            if firstRide { colors[ObjectIdentifier(sitter)] = .green }
        } else {
            pickers = [christina, grace, olivia, mom]
        }
        for p in pickers {
            try await look(at: Stage.focus(CGPoint(x: p.x(at: .now), y: Stage.floorY - 90), height: 230))
            caption = "What color Roswell alien does \(p.id) want to be?"
            let color = await withCheckedContinuation { cont in
                colorPick = cont
                choosingColor = p
            }
            try Task.checkCancellation()
            try await say(p, "I want to be \(color.name.lowercased())!", 1.8)
            colors[ObjectIdentifier(p)] = color
        }
        let riders = team.map { ($0, colors[ObjectIdentifier($0)] ?? .green) }
        try await look(at: Stage.full)
        if let sitter, firstRide {
            try await say(sitter, sl.ride.inShip, 3)
            try await say(stayers[0], "You're going to love it!", 2)
        }
        try await say(leader, "You ready?", 2)
        shout(team, "Give us 10 seconds to take a few breaths.", 3)
        try await sleep(3.2)
        caption = "They take a few deep breaths… in… and out…"
        try await sleep(6.8)
        shout(team, "Alright lets do it!", 2)
        try await sleep(2.2)
        caption = "The alien pushes the glowing green button…"
        if let sitter, firstRide {
            try await runMachine(riders, presser: leader, change: Machine.change,
                                 tingleLine: (sitter, sl.ride.tingle),
                                 legsStartLine: (sitter, sl.ride.legs),
                                 bodyLine: (sitter, sl.ride.body),
                                 faceWarning: sl.ride.faceWarning, faceComing: sl.ride.faceComing,
                                 faceLine: (sitter, sl.ride.faceLine), focus: sitter)
        } else {
            let (legs, body) = sitter == nil ? (olivia, grace) : (stayers[0], stayers[1])
            try await runMachine(riders, presser: leader, change: Machine.change,
                                 tingleShout: "This really tickles.",
                                 legsLine: (legs, "My legs are going \((colors[ObjectIdentifier(legs)] ?? .green).name.lowercased())!"),
                                 bodyLine: (body, "My arms and chest are turning \((colors[ObjectIdentifier(body)] ?? .green).name.lowercased())!"),
                                 facesLine: "Now our faces")
        }
        try await look(at: Stage.full)
        try await say(leader, "Look in the mirror, Earthlings.", 2.2)
        caption = "The aliens lower the big mirror in front of them…"
        try await showMirror(team, caption: firstRide ? "…and \(sitter!.id) sees herself as a Roswell alien for the first time!"
                                                      : "…and they see their new colors for the first time!")
        try await look(at: Stage.chairsView)
        if let sitter, firstRide {
            sitter.mood = .smiling
            try await say(sitter, sl.ride.mirror, 2.8)
            sitter.mood = .happy
            // Her straps pop open and she reaches up to feel her new head.
            caption = "The straps on \(sitter.id)'s arms pop open…"
            strapped.remove(sitter.id)
            sound.clunk()
            try await sleep(1.0)
            let head = Pose(sitter, feet: CGPoint(x: sitter.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head
            try await look(at: Stage.focus(CGPoint(x: head.x, y: head.y + 12), height: 150))
            caption = "\(sitter.id) feels her new head…"
            sitter.feelHead = true
            try await sleep(0.8)
            try await say(sitter, sl.ride.headFeel, 2.8)
            sitter.feelHead = false
            try await sleep(0.3)
            // She rocks her big new head from side to side a few times.
            caption = "\(sitter.id) rocks her big new head from side to side…"
            sitter.rockT0 = .now
            sitter.rockDur = 3.6
            try await sleep(3.8)
            try await look(at: Stage.chairsView)
            for p in [stayers[1], stayers[0]] {
                try await say(p, reaction(colors[ObjectIdentifier(p)] ?? .green), 2.2)
            }
            try await say(sitter, sl.bestJob, 2.6)
            try await say(stayers[0], "Told you! Now let's go make some money!", 2.4)
        } else {
            for p in pickers {
                try await say(p, reaction(colors[ObjectIdentifier(p)] ?? .green), 2.2)
            }
            try await say(sitter == nil ? grace : stayers[1], "Look at us! A rainbow of aliens!", 2.2)
        }
        if let sitter {
            // Before the photo goes in the album, a sister gets the babysitter to smile.
            try await look(at: Stage.focus(CGPoint(x: sitter.x(at: .now), y: Stage.floorY - 90), height: 230))
            try await say(stayers.randomElement()!, "Smile!", 1.4)
            sitter.mood = .smiling
            caption = "\(sitter.id) gives a big smile for the album…"
            try await sleep(1.2)
        }
        try await snap(team)
        sitter?.mood = .happy
        unstrap(team)
        if sitter != nil { sitterRides += 1 }
    }

    // MARK: Helpers

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }

    /// Fades to black, changes the scene, and fades back in.
    private func sceneChange(_ change: () -> Void) async throws {
        fadeT0 = .now
        try await sleep(0.5)
        change()
        try await sleep(0.8)
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
        mention(p, text, seconds)
        try await sleep(seconds + 0.2)
    }

    /// Says something without waiting for it.
    private func mention(_ p: Person, _ text: String, _ seconds: Double) {
        p.says = text
        p.saysUntil = .now + seconds
    }

    /// Everyone in `people` says it at once, without waiting.
    private func shout(_ people: [Person], _ text: String, _ seconds: Double) {
        for p in people { mention(p, text, seconds) }
    }

    /// Jumps the camera straight to `rect`.
    private func cutNow(_ rect: CGRect) {
        (camFrom, camTo) = (rect, rect)
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
