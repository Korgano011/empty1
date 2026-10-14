import SwiftUI

struct RGB: Codable {
    var r, g, b: Double

    static let fair = RGB(r: 0.99, g: 0.87, b: 0.77)

    var color: Color { Color(red: r, green: g, blue: b) }

    func mix(_ other: RGB, _ t: Double) -> RGB {
        let t = min(max(t, 0), 1)
        return RGB(r: r + (other.r - r) * t, g: g + (other.g - g) * t, b: b + (other.b - b) * t)
    }
}

enum TanLevel: String, CaseIterable, Identifiable, Codable {
    case glow, medium, dark, ultradark

    var id: Self { self }

    var title: String {
        switch self {
        case .glow: "Glow"
        case .medium: "Medium"
        case .dark: "Dark"
        case .ultradark: "Ultradark"
        }
    }

    var skin: RGB {
        switch self {
        case .glow: RGB(r: 0.95, g: 0.77, b: 0.62)
        case .medium: RGB(r: 0.86, g: 0.63, b: 0.45)
        case .dark: RGB(r: 0.70, g: 0.47, b: 0.30)
        case .ultradark: RGB(r: 0.52, g: 0.33, b: 0.20)
        }
    }

    var reaction: String {
        switch self {
        case .glow: "Ooh, a pretty golden glow!"
        case .medium: "I look like I spent all summer at the beach!"
        case .dark: "Whoa, I'm really bronzed!"
        case .ultradark: "WOW! I'm super dark!"
        }
    }
}

enum Outfit { case clothes, swim }

enum HairStyle: String, Codable { case long, ponytail, pigtails }

final class Person: Identifiable {
    let id: String
    let height: Double
    let headScale: Double
    let hair: RGB
    let style: HairStyle
    let shirt: RGB
    let bottoms: RGB
    let swim: RGB
    let onePiece: Bool

    var visible = true
    var x0: Double
    var x1: Double
    var moveT0 = Date.distantPast
    var moveDur = 0.0
    var facing = 1.0

    var outfit = Outfit.clothes
    var poofT0 = Date.distantPast

    var skin0 = RGB.fair
    var skin1 = RGB.fair
    var tanT0 = Date.distantPast
    var tanDur = 0.0
    var level: TanLevel?

    /// How her face looks: smiling, angry (the boss), sad with tears, or scared.
    enum Mood { case normal, angry, sad, scared }
    var mood = Mood.normal

    /// A man (the salon boss): short hair, trousers and a tie.
    var isMan = false
    /// Gia's grey maintenance uniform, worn over her clothes.
    var uniform: RGB?
    /// Carrying a mop.
    var mop = false
    /// Holding a phone to her (or his) ear.
    var onPhone = false

    var says: String?
    var saysUntil = Date.distantPast
    var carrying = false
    var scrubUntil = Date.distantPast

    init(_ id: String, height: Double, headScale: Double, hair: RGB, style: HairStyle,
         shirt: RGB, bottoms: RGB, swim: RGB, onePiece: Bool = false, x: Double) {
        self.id = id
        self.height = height
        self.headScale = headScale
        self.hair = hair
        self.style = style
        self.shirt = shirt
        self.bottoms = bottoms
        self.swim = swim
        self.onePiece = onePiece
        x0 = x
        x1 = x
    }

    func x(at now: Date) -> Double {
        let t = now.timeIntervalSince(moveT0)
        if t >= moveDur { return x1 }
        if t <= 0 { return x0 }
        return x0 + (x1 - x0) * t / moveDur
    }

    func isWalking(at now: Date) -> Bool {
        let t = now.timeIntervalSince(moveT0)
        return t > 0 && t < moveDur
    }

    /// The booth tans from the bottom up: legs first, then the body and arms, then the face.
    enum Part { case legs, body, head }

    func skin(at now: Date, part: Part = .head) -> RGB {
        guard tanDur > 0 else { return skin1 }
        let u = now.timeIntervalSince(tanT0) / tanDur
        let (a, b): (Double, Double) = switch part {
        case .legs: (0, Spray.bodyStart + 0.05)
        case .body: (Spray.bodyStart, Spray.faceStart + 0.05)
        case .head: (Spray.faceStart, 1)
        }
        return skin0.mix(skin1, min(max((u - a) / (b - a), 0), 1))
    }
}

/// One spray-tan session: five minutes, sped up.
enum Spray {
    /// Real seconds for the family's five minutes, and a quicker one for customers.
    static let family = 30.0
    static let customer = 18.0
    /// Where in the session the mist moves up from the legs to the body, and from the body to the face.
    static let bodyStart = 0.3
    static let faceStart = 0.65
}

enum Venue: String, CaseIterable, Identifiable, Codable {
    case stateFair, boardwalk, park, californiaCoast, tahiti, longBeachIsland, capeCod, keansburg

    var id: Self { self }

    var name: String {
        switch self {
        case .stateFair: "State Fair"
        case .boardwalk: "Boardwalk"
        case .park: "Amusement Park"
        case .californiaCoast: "California Coast"
        case .tahiti: "Tahiti"
        case .longBeachIsland: "Long Beach Island"
        case .capeCod: "Cape Cod"
        case .keansburg: "Keansburg"
        }
    }

    var blurb: String {
        switch self {
        case .stateFair: "Cheap spot, friendly crowd"
        case .boardwalk: "Beach crowd loves a tan"
        case .park: "Big crowds, pricey spot"
        case .californiaCoast: "Surfers by the sea cliffs"
        case .tahiti: "Island paradise, top prices"
        case .longBeachIsland: "Jersey Shore families"
        case .capeCod: "Summer cottages and sailboats"
        case .keansburg: "Bayshore rides and water slides"
        }
    }

    var icon: String {
        switch self {
        case .stateFair: "party.popper"
        case .boardwalk: "beach.umbrella"
        case .park: "sparkles"
        case .californiaCoast: "sun.horizon.fill"
        case .tahiti: "water.waves"
        case .longBeachIsland: "light.beacon.max.fill"
        case .capeCod: "sailboat.fill"
        case .keansburg: "figure.water.fitness"
        }
    }

    /// What it costs to set up the booth there.
    var fee: Int {
        switch self {
        case .stateFair: 40
        case .boardwalk: 60
        case .park: 90
        case .californiaCoast: 80
        case .tahiti: 120
        case .longBeachIsland: 50
        case .capeCod: 70
        case .keansburg: 45
        }
    }
    /// Price of one spray tan.
    var price: Int {
        switch self {
        case .stateFair: 12
        case .boardwalk: 15
        case .park: 20
        case .californiaCoast: 18
        case .tahiti: 25
        case .longBeachIsland: 14
        case .capeCod: 16
        case .keansburg: 13
        }
    }
    var groups: Int {
        switch self {
        case .stateFair, .boardwalk, .californiaCoast, .longBeachIsland, .capeCod, .keansburg: 6
        case .park, .tahiti: 7
        }
    }
    var adultYes: Double {
        switch self {
        case .park: 0.5
        case .californiaCoast, .tahiti: 0.65
        default: 0.6
        }
    }
    var kidYes: Double {
        switch self {
        case .stateFair, .longBeachIsland, .keansburg: 0.8
        default: 0.75
        }
    }

    static let startCash = 200
}

struct DemoResult {
    let venue: Venue
    let tans: Int
    let startCash: Int
    let endCash: Int
    /// What a cousin, aunt or babysitter was paid out of the profit.
    var share = 0
    var earned: Int { tans * venue.price }
    var profit: Int { earned - venue.fee }
}

/// People are the same person only if they're the same object.
extension Person: Equatable {
    static func == (a: Person, b: Person) -> Bool { a === b }
}

extension Person {
    private static let hairs = [RGB(r: 0.20, g: 0.12, b: 0.08), RGB(r: 0.45, g: 0.28, b: 0.14), RGB(r: 0.92, g: 0.78, b: 0.42),
                                RGB(r: 0.75, g: 0.32, b: 0.14), RGB(r: 0.10, g: 0.10, b: 0.10), RGB(r: 0.60, g: 0.45, b: 0.30)]
    private static let colors = [RGB(r: 0.90, g: 0.30, b: 0.30), RGB(r: 0.25, g: 0.55, b: 0.85), RGB(r: 0.30, g: 0.70, b: 0.40),
                                 RGB(r: 0.95, g: 0.75, b: 0.20), RGB(r: 0.60, g: 0.40, b: 0.80), RGB(r: 0.95, g: 0.50, b: 0.70),
                                 RGB(r: 0.20, g: 0.65, b: 0.65), RGB(r: 0.95, g: 0.55, b: 0.15), RGB(r: 0.35, g: 0.35, b: 0.45)]

    /// A random fair-goer, an adult or a kid.
    static func customer(_ name: String, kid: Bool, x: Double) -> Person {
        Person(name, height: kid ? .random(in: 88...118) : .random(in: 136...154),
               headScale: kid ? 0.155 : 0.12,
               hair: hairs.randomElement()!,
               style: [HairStyle.long, .ponytail, .pigtails].randomElement()!,
               shirt: colors.randomElement()!, bottoms: colors.randomElement()!, swim: colors.randomElement()!,
               onePiece: kid, x: x)
    }
}

/// Where the story is before it moves home.
enum Place { case salon, convention }

/// Thrown when the player chooses End Game.
struct EndGame: Error {}

/// Who works a trip: the cashier at the table, a greeter for grown-ups and one for kids, and anyone else along.
/// A `newcomer` gets her own spray tan first; a `payee` gets 1/`fraction` of the trip's profit.
struct Team {
    var cashier: Person
    var adultGreeter: Person
    var kidGreeter: Person
    var helpers: [Person] = []
    var newcomer: Person? = nil
    var payee: (person: Person, fraction: Int)? = nil
    var members: [Person] { [cashier, adultGreeter, kidGreeter] + helpers }
}

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var mom: Person
    var maddie: Person
    var chloe: Person
    var lily: Person

    var cast: [Person] { [mom, maddie, chloe, lily] }
    var customers: [Person] = []
    /// An aunt and cousin visiting, or the babysitter.
    var visitors: [Person] = []
    var everyone: [Person] { cast + visitors + customers }

    // Days and nights
    var inTown = false
    /// Gia's tanning salon or the spray tan convention, before the story moves home.
    var place: Place?
    var salonClosed = false
    /// The health department's notice says the salon is shut for good, not just for two days.
    var salonPermanent = false
    /// With Gia gone, nobody fixes the salon booths.
    var salonBroken = false
    /// The boss's messages are waiting on Gia's answering machine.
    var machineBlinking = false
    var flyerUntil = Date.distantPast
    /// The booth isn't in the empty room until Gia brings it home.
    var boothHidden = false
    /// A sheet over the booth until the morning after Gia brings it home.
    var boothCovered = false
    var night = false
    /// Who is asleep, and where their Zs float.
    var sleepers: [(id: String, x: Double)] = []
    var bank = 0
    var trips = 0
    var nights = 0
    var totalTans = 0
    var paidOut = 0
    var choosingNext = false
    var nextPrompt = ""
    var choosingVacation = false
    @ObservationIgnored private var nextPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var vacationPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var auntVisits = 0
    @ObservationIgnored private var sitterVisits = 0
    @ObservationIgnored private var shopperTurn = 0

    var caption = "Tap Start to begin."
    var choosingFor: Person?
    var running = false
    var finished = false

    var sprayT0 = Date.distantPast
    var sprayDur = 0.0
    /// The warm-air drying cycle that follows the spray.
    var dryT0 = Date.distantPast
    var dryDur = 0.0
    /// The five-minute clock shown while the booth sprays.
    var clockT0 = Date.distantPast
    var clockDur = 1.0
    var boothClosed = false
    var signUntil = Date.distantPast
    var doorOpenUntil = Date.distantPast
    var bagsX: Double?
    var camFrom = Stage.full
    var camTo = Stage.full
    var camT0 = Date.distantPast
    var fadeT0 = Date.distantPast

    // Public demonstration
    var venue: Venue?
    var choosingVenue = false
    var cash = Venue.startCash
    var cashPop: (text: String, t0: Date)?
    var result: DemoResult?
    var muted = false { didSet { sound.muted = muted } }
    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()

    init() {
        (mom, maddie, chloe, lily) = Self.makeFamily()
    }

    private static func makeFamily() -> (Person, Person, Person, Person) {
        let mom = Person("Gia", height: 150, headScale: 0.12, hair: RGB(r: 0.40, g: 0.24, b: 0.12), style: .long,
                         shirt: RGB(r: 0.30, g: 0.50, b: 0.80), bottoms: RGB(r: 0.25, g: 0.30, b: 0.45),
                         swim: RGB(r: 0.85, g: 0.15, b: 0.30), x: 640)
        let maddie = Person("Maddie", height: 128, headScale: 0.13, hair: RGB(r: 0.95, g: 0.80, b: 0.40), style: .ponytail,
                            shirt: RGB(r: 0.55, g: 0.35, b: 0.75), bottoms: RGB(r: 0.30, g: 0.35, b: 0.60),
                            swim: RGB(r: 0.10, g: 0.70, b: 0.70), x: 600)
        let chloe = Person("Chloe", height: 112, headScale: 0.145, hair: RGB(r: 0.80, g: 0.35, b: 0.15), style: .pigtails,
                           shirt: RGB(r: 0.30, g: 0.70, b: 0.40), bottoms: RGB(r: 0.95, g: 0.60, b: 0.20),
                           swim: RGB(r: 0.98, g: 0.55, b: 0.10), x: 680)
        let lily = Person("Lily", height: 92, headScale: 0.165, hair: RGB(r: 0.50, g: 0.30, b: 0.15), style: .pigtails,
                          shirt: RGB(r: 1.0, g: 0.60, b: 0.75), bottoms: RGB(r: 0.60, g: 0.40, b: 0.85),
                          swim: RGB(r: 1.0, g: 0.40, b: 0.70), onePiece: true, x: 715)
        return (mom, maddie, chloe, lily)
    }

    /// The part of the stage on screen; eases from `camFrom` to `camTo` over 0.9s.
    func camera(at now: Date) -> CGRect {
        let t = min(max(now.timeIntervalSince(camT0) / 0.9, 0), 1)
        let e = t * t * (3 - 2 * t)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * e }
        return CGRect(x: mix(camFrom.minX, camTo.minX), y: mix(camFrom.minY, camTo.minY),
                      width: mix(camFrom.width, camTo.width), height: mix(camFrom.height, camTo.height))
    }

    private var task: Task<Void, Never>?
    private var pick: CheckedContinuation<TanLevel, Never>?
    private var venuePick: CheckedContinuation<Venue, Never>?
    private var tansSold = 0
    private var served: [PersonSpec] = []
    /// Names for the grown-ups and kids who stroll by; the lists reshuffle when they run out.
    private static let momNames = ["Brenda", "Tina", "Carla", "Denise", "Grace", "Heather", "Joy", "Kim", "Paula", "Rita",
                                   "Angela", "Becky", "Cindy", "Diane", "Erin", "Felicia", "Gina", "Holly", "Irene", "Jackie",
                                   "Laura", "Megan", "Nancy", "Renee", "Sandra", "Theresa", "Valerie", "Wanda", "Yvonne", "Lorraine"]
    private static let childNames = ["Amy", "Bella", "Cora", "Daisy", "Emma", "Fiona", "Gwen", "Hannah", "Ivy", "Jade",
                                     "Abby", "Brianna", "Claire", "Delilah", "Eden", "Faith", "Gabby", "Hazel", "Isla", "Josie",
                                     "Katie", "Leah", "Molly", "Nora", "Paige", "Quinn", "Rosie", "Sadie", "Tessa", "Willow"]
    private var adultNames: [String] = []
    private var kidNames: [String] = []

    func start() {
        task?.cancel()
        pick?.resume(returning: .glow)
        pick = nil
        venuePick?.resume(returning: .stateFair)
        venuePick = nil
        nextPick?.resume(returning: false)
        nextPick = nil
        vacationPick?.resume(returning: false)
        vacationPick = nil
        choosingNext = false
        choosingVacation = false
        visitors = []
        inTown = false
        place = nil
        salonClosed = false
        salonPermanent = false
        salonBroken = false
        machineBlinking = false
        flyerUntil = .distantPast
        boothHidden = false
        boothCovered = false
        night = false
        sleepers = []
        bank = 0
        trips = 0
        nights = 0
        totalTans = 0
        paidOut = 0
        auntVisits = 0
        sitterVisits = 0
        shopperTurn = 0
        sound.prepare()
        sound.spray(false)
        sound.dryer(false)
        (mom, maddie, chloe, lily) = Self.makeFamily()
        choosingFor = nil
        finished = false
        running = true
        sprayT0 = .distantPast
        dryT0 = .distantPast
        boothClosed = false
        signUntil = .distantPast
        doorOpenUntil = .distantPast
        bagsX = nil
        camFrom = Stage.full
        camTo = Stage.full
        camT0 = .distantPast
        fadeT0 = .distantPast
        customers = []
        venue = nil
        choosingVenue = false
        cash = Venue.startCash
        cashPop = nil
        result = nil
        tansSold = 0
        served = []
        adultNames = []
        kidNames = []
        task = Task {
            do { try await story() } catch {}
        }
    }

    func choose(_ level: TanLevel) {
        pick?.resume(returning: level)
        pick = nil
        choosingFor = nil
    }

    /// Between trips: keep going, or end the game.
    func chooseNext(again: Bool) {
        nextPick?.resume(returning: again)
        nextPick = nil
        choosingNext = false
    }

    func chooseVacation(_ go: Bool) {
        vacationPick?.resume(returning: go)
        vacationPick = nil
        choosingVacation = false
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

    // MARK: Gia's last days at the salon

    /// Gia's story before the booth: the new boss takes her off spray tanning and puts her on maintenance and won't let her
    /// go to the spray tan convention, so she walks out without telling him and goes anyway. The salon falls apart without her.
    private func salonPrologue() async throws {
        let gia = mom
        for g in [maddie, chloe, lily] { g.visible = false }
        let boss = Person("Boss", height: 164, headScale: 0.11, hair: RGB(r: 0.22, g: 0.18, b: 0.14), style: .long,
                          shirt: RGB(r: 0.95, g: 0.95, b: 0.97), bottoms: RGB(r: 0.22, g: 0.24, b: 0.32),
                          swim: RGB(r: 0.70, g: 0.10, b: 0.12), x: 1010)
        boss.isMan = true
        boss.facing = -1
        visitors = [boss]
        place = .salon
        cut(to: Stage.full)
        (gia.x0, gia.x1, gia.facing) = (Stage.salonGiaX, Stage.salonGiaX, 1)

        caption = "Meet Gia. She works at Sunny Glow Tanning — the best spray tanner in town."
        try await sleep(3.2)
        caption = "But Sunny Glow has a new boss…"
        try await walk(boss, to: Stage.salonGiaX + 110, speed: 90)
        try await say(boss, "Gia, you're done spray tanning. From now on, you're our maintenance person.", 3.6)
        try await say(gia, "Maintenance? But spray tanning is what I'm good at!", 3)
        try await say(boss, "Mops, buckets and light bulbs. Starting today.", 2.8)
        caption = "Gia trades her salon smock for a maintenance uniform."
        gia.poofT0 = .now
        try await sleep(0.35)
        gia.uniform = Self.maintenanceGray
        gia.mop = true
        try await sleep(0.6)
        try await walk(boss, to: Stage.salonDeskX, speed: 90)
        boss.facing = -1

        caption = "Day after day, Gia mops the floors and scrubs out the booths."
        try await walk(gia, to: 300, speed: 55)
        try await walk(gia, to: Stage.salonGiaX, speed: 55)
        try await say(gia, "This isn't what I signed up for…", 2.6)

        caption = "One morning, a flyer comes in the mail."
        flyerUntil = .now + 5
        try await sleep(5)
        try await say(gia, "A spray tan convention is coming to town!", 2.8)
        try await walk(gia, to: Stage.salonDeskX - 110, speed: 110)
        try await say(gia, "Can I have Saturday off to go to the spray tan convention?", 3.2)
        boss.mood = .angry
        try await say(boss, "Absolutely not. You're maintenance now. Those booths won't clean themselves.", 3.6)
        try await say(gia, "But—", 1.2)
        try await say(boss, "The answer is no!", 2)
        try await walk(gia, to: Stage.salonGiaX, speed: 110)
        gia.facing = 1
        caption = "Gia has had enough."
        try await say(gia, "That's it. I'm done with this place — and I'm not even going to tell him.", 3.6)
        caption = "Without a word to her boss, Gia leans her mop against the wall and walks out. She never comes back."
        gia.mop = false
        try await sleep(0.6)
        try await walk(gia, to: -60, speed: 90)
        try await sleep(0.8)

        // The convention — with cut-aways to the salon after each customer.
        try await toConvention(gia)
        caption = "The Spray Tan Convention! Gia jumps in at the live demo booth."
        try await say(gia, "Who wants a spray tan? Step right up!", 2.8)
        if adultNames.isEmpty { adultNames = Self.momNames.shuffled() }
        let asks = ["Ooh, can I try?", "Is it really just five minutes?", "I've always wanted a spray tan!"]
        let thanks = ["Thank you, Gia — you're a natural!", "Wow! You really know your stuff!", "Best spray tan at the whole convention!"]
        for k in 0..<3 {
            if k > 0 {
                try await toConvention(gia)
                caption = ["", "Back at the convention, Gia's next customer is waiting.", "At the convention, there's still a line for Gia's booth."][k]
                try await sleep(2)
            }
            let guest = Person.customer(adultNames.removeLast(), kid: false, x: 1290)
            customers = [guest]
            try await walk(guest, to: Stage.conventionGuestX, speed: 120)
            guest.facing = -1
            try await say(guest, asks[k], 2.4)
            try await say(gia, "Step right in!", 1.8)
            try await boothTurn(guest, level: TanLevel.allCases.randomElement()!)
            try await poof(guest, .clothes)
            try await say(guest, thanks[k], 2.6)
            try await walk(guest, to: 1300, speed: 140)
            customers = []
            switch k {
            case 0: try await bossCalls(boss)
            case 1: try await brokenBooths(boss)
            default: try await bossTellsWife(boss)
            }
        }
        try await toConvention(gia)
        caption = "The crowd loves Gia's spray tans!"
        try await say(gia, "I'd forgotten how much I love this.", 2.6)
        try await say(gia, "I know what I'll do — I'll build a spray tan booth of my own. And I'll surprise my girls!", 4)

        // Home — and the boss comes to the door.
        try await changeScene {
            self.place = nil
            self.visitors = []
            self.boothHidden = true
            self.machineBlinking = true
            gia.visible = false
            for g in [self.maddie, self.chloe, self.lily] { g.visible = true }
            (gia.x0, gia.x1, gia.facing) = (Stage.doorX, Stage.doorX, -1)
        }
        try await homeFromConvention(boss)
    }

    /// Switches (back) to the convention floor, with Gia at the demo booth.
    private func toConvention(_ gia: Person) async throws {
        try await changeScene {
            self.place = .convention
            self.visitors = []
            self.customers = []
            self.boothHidden = false
            gia.visible = true
            gia.uniform = nil
            gia.mop = false
            (gia.x0, gia.x1, gia.facing) = (Stage.conventionGiaX, Stage.conventionGiaX, 1)
        }
    }

    /// Switches to the salon, with Gia away at the convention.
    private func toSalon(_ boss: Person, _ others: [Person] = [], bossAt x: Double = Stage.salonDeskX) async throws {
        try await changeScene {
            self.place = .salon
            self.customers = []
            self.visitors = [boss] + others
            self.mom.visible = false
            (boss.x0, boss.x1, boss.facing) = (x, x, -1)
        }
    }

    /// After her first customer: the boss calls Gia and gets her answering machine.
    private func bossCalls(_ boss: Person) async throws {
        try await toSalon(boss)
        caption = "Meanwhile, back at Sunny Glow, Gia hasn't shown up for work."
        try await say(boss, "Where is Gia? These floors won't mop themselves!", 3)
        caption = "He picks up the phone and calls her. Ring… ring…"
        boss.onPhone = true
        try await sleep(2.4)
        caption = "\"Hi, you've reached Gia. Please leave a message after the beep.\"  Beep!"
        sound.ding()
        try await sleep(3.2)
        try await say(boss, "Gia, it's your boss. You're late. Where are you? Call me back right away!", 4)
        boss.onPhone = false
        try await changeScene {
            self.place = nil
            self.visitors = []
            self.boothHidden = true
            self.machineBlinking = true
            for p in self.cast { p.visible = false }
        }
        caption = "Gia and her three daughters just moved into their new one-story house. Every room is taken — except one."
        try await sleep(3.5)
        caption = "Nobody's home. On the end table, the answering machine blinks with the boss's message."
        try await look(at: Stage.shot(centerX: 728, height: 160))
        try await sleep(3)
        try await look(at: Stage.full)
    }

    /// After her second customer: a customer comes into the salon, and with Gia gone the booths don't work.
    private func brokenBooths(_ boss: Person) async throws {
        if adultNames.isEmpty { adultNames = Self.momNames.shuffled() }
        let client = Person.customer(adultNames.removeLast(), kid: false, x: 1290)
        try await toSalon(boss, [client])
        caption = "Back at Sunny Glow, a customer walks in."
        try await walk(client, to: Stage.salonDeskX - 110, speed: 110)
        client.facing = 1
        try await say(client, "Hi! I'd like a spray tan, please.", 2.4)
        try await say(boss, "Right this way. Booth 1.", 2.2)
        try await walkAll([(client, 140), (boss, 260)])
        client.facing = -1
        boss.facing = -1
        caption = "She steps into Booth 1 and presses START…"
        try await sleep(1.4)
        sound.spray(true)
        try await sleep(0.4)
        sound.spray(false)
        caption = "Pssst… sputter… cough. Nothing comes out."
        try await sleep(2)
        try await say(client, "It's not working!", 2)
        try await say(boss, "Try Booth 2.", 1.8)
        try await walk(client, to: 247, speed: 90)
        boss.facing = 1
        caption = "Booth 2 sputters too."
        sound.spray(true)
        try await sleep(0.3)
        sound.spray(false)
        try await sleep(1.4)
        salonBroken = true
        sound.ding()
        caption = "Neither booth works. Gia was the one who kept them running — and she's at the convention."
        try await sleep(3)
        try await say(client, "Neither booth works! I'm taking my business somewhere else.", 3.2)
        boss.mood = .angry
        try await say(boss, "Gia was supposed to keep these booths fixed. Where is she?!", 3.2)
        try await walk(client, to: 1300, speed: 140)
    }

    /// After her third customer: the boss talks to his wife about Gia.
    private func bossTellsWife(_ boss: Person) async throws {
        let wife = Person.customer("Wife", kid: false, x: 1290)
        try await toSalon(boss, [wife], bossAt: Stage.salonGiaX + 150)
        caption = "That evening, the boss's wife stops by the salon."
        try await walk(wife, to: Stage.salonGiaX + 260, speed: 110)
        wife.facing = -1
        boss.facing = 1
        try await look(at: Stage.shot(centerX: Stage.salonGiaX + 205, height: 280))
        try await say(boss, "Gia hasn't shown up, she won't return my calls, and the booths are broken.", 3.8)
        try await say(boss, "When I see her, I'm going to give her the scolding of her life!", 3.4)
        try await say(wife, "Scolding her is not going to do you any good.", 2.8)
        try await say(wife, "If she just stops coming and doesn't return your phone calls, the only maintenance she is performing is bye bye.", 5)
        try await say(boss, "…", 1.4)
        try await look(at: Stage.full)
        try await walk(wife, to: 1300, speed: 120)
    }

    /// Gia gets home from the convention. Her boss shows up and scolds her, but it gets him nowhere — and when he
    /// goes back to the salon, the health department has shut it down for good. That night Gia builds her own
    /// spray tan booth in the empty room, under a sheet — a surprise for the girls in the morning.
    private func homeFromConvention(_ boss: Person) async throws {
        let (gia, maddie, chloe, lily) = (mom, maddie, chloe, lily)
        caption = "Gia comes home from the convention, all smiles."
        doorOpenUntil = .now + 1
        try await sleep(0.4)
        gia.visible = true
        try await walk(gia, to: 760, speed: 80)
        gia.facing = -1
        for g in [maddie, chloe, lily] { g.facing = 1 }
        try await look(at: Stage.shot(centerX: 690, height: 260))
        try await say(lily, "Mommy, you're home!", 2)
        try await say(maddie, "How was the convention?", 2.2)
        try await say(gia, "Wonderful! I spray tanned people all day. It felt so good to do what I love.", 3.6)
        try await say(chloe, "Mom, the answering machine is blinking.", 2.6)
        try await say(gia, "I know who that is. I'm not calling him back.", 2.8)

        // The boss comes to the door.
        caption = "Knock, knock, knock!"
        try await walkAll([(maddie, 590), (chloe, 625), (lily, 655), (gia, 715)])
        gia.facing = 1
        for g in [maddie, chloe, lily] { g.facing = 1 }
        boss.mood = .angry
        (boss.x0, boss.x1, boss.facing) = (Stage.doorX, Stage.doorX, -1)
        visitors = [boss]
        doorOpenUntil = .now + 1.2
        try await sleep(0.3)
        try await walk(boss, to: 800, speed: 80)
        boss.facing = -1
        caption = "It's Gia's boss — and he's furious."
        try await look(at: Stage.shot(centerX: 730, height: 250))
        try await say(boss, "Gia! You walked out on me without a word! You didn't show up, and you didn't return one single call!", 4.4)
        try await say(boss, "The booths broke down, customers walked out, and the whole salon is falling apart!", 4)
        try await say(boss, "Of all the irresponsible, ungrateful— you are the worst employee I have ever had!", 4)
        caption = "He scolds and scolds… but it gets him nowhere."
        try await say(gia, "Are you finished?", 2)
        try await say(gia, "You took me off spray tanning and handed me a mop. I don't work for you anymore.", 3.8)
        try await say(boss, "You— you can't just—", 2.2)
        try await say(gia, "I already did. Goodbye.", 2.2)
        try await look(at: Stage.full)
        caption = "The boss storms out."
        try await walk(boss, to: Stage.doorX, speed: 120)
        doorOpenUntil = .now + 0.8
        visitors = []
        try await sleep(0.8)

        // Back at the salon.
        try await changeScene {
            self.place = .salon
            self.salonClosed = true
            self.salonPermanent = true
            self.visitors = [boss]
            for p in self.cast { p.visible = false }
            (boss.x0, boss.x1, boss.facing) = (-40, -40, 1)
        }
        caption = "The boss drives back to Sunny Glow…"
        try await walk(boss, to: 760, speed: 100)
        boss.facing = 1
        caption = "…and finds a notice on the wall. The health department has shut the salon down — permanently."
        try await look(at: Stage.shot(centerX: 920, height: 300))
        try await sleep(1.8)
        boss.mood = .sad
        try await say(boss, "Permanently?! No… no, no, no!", 2.8)
        try await sleep(1)

        // Home again: the girls hear the news, then Gia builds her booth.
        try await changeScene {
            self.place = nil
            self.salonClosed = false
            self.salonPermanent = false
            self.salonBroken = false
            self.visitors = []
            self.machineBlinking = false
            for p in self.cast { p.visible = true }
            (gia.x0, gia.x1, gia.facing) = (715, 715, -1)
            for g in [maddie, chloe, lily] { g.facing = 1 }
        }
        try await look(at: Stage.shot(centerX: 660, height: 260))
        try await say(maddie, "Mom, did you really quit your job?", 2.6)
        try await say(gia, "I sure did. I'm done mopping floors for him.", 2.8)
        try await say(chloe, "Good! You're the best spray tanner ever!", 2.6)
        try await say(gia, "And I have a big idea… but it's a surprise.", 2.8)
        try await say(lily, "A surprise? What is it?", 2.2)
        try await say(gia, "You'll see in the morning!", 2.2)
        try await look(at: Stage.full)

        caption = "It's late, so Gia sends the girls to bed…"
        try await say(gia, "Time for bed, girls!", 2)
        try await walkAll([(maddie, bedX(maddie)), (chloe, bedX(chloe)), (lily, bedX(lily))])
        for g in [maddie, chloe, lily] {
            g.visible = false
            sleepers.append((g.id, bedX(g)))
        }
        caption = "…then she gets to work in the empty room, building a spray tan booth of her own."
        try await walk(gia, to: 200)
        gia.facing = -1
        for (k, step) in ["She bolts the frame together…", "…fits the panels and the spray nozzles…", "…wires up the warm-air dryer…"].enumerated() {
            caption = step
            gia.poofT0 = .now
            sound.ding()
            if k == 1 {
                try await sleep(0.35)
                boothHidden = false
            }
            try await sleep(2.2)
        }
        boothHidden = false
        caption = "…and covers it with a sheet — a surprise for the girls in the morning."
        gia.poofT0 = .now
        try await sleep(0.35)
        boothCovered = true
        try await sleep(1.2)
        try await say(gia, "My girls are going to love this in the morning!", 2.8)
        try await walk(gia, to: bedX(gia))
        gia.visible = false
        sleepers.append((gia.id, bedX(gia)))
        night = true
        caption = "Everyone gets a good night's sleep."
        try await sleep(3.5)

        // The next morning
        fadeT0 = .now
        try await sleep(0.55)
        night = false
        sleepers = []
        for (p, x) in [(gia, 640.0), (maddie, 600), (chloe, 680), (lily, 715)] {
            (p.x0, p.x1, p.facing) = (x, x, 1)
            p.visible = true
        }
        try await sleep(0.75)
        caption = "The next morning…"
        try await sleep(2)
    }

    private static let maintenanceGray = RGB(r: 0.45, g: 0.50, b: 0.55)

    /// Fades to black, changes the scene while it's dark, and fades back in.
    private func changeScene(_ change: () -> Void) async throws {
        fadeT0 = .now
        try await sleep(0.55)
        change()
        cut(to: Stage.full)
        camFrom = Stage.full
        try await sleep(0.75)
    }

    // MARK: Story

    private func story() async throws {
        let (mom, maddie, chloe, lily) = (mom, maddie, chloe, lily)

        try await salonPrologue()

        // Gia shows the girls her surprise — and goes first.
        try await say(mom, "Girls, come with me. I have a surprise for you!", 2.8)
        caption = "Gia leads the girls to the empty room."
        try await walkAll([(mom, 175), (lily, 300), (maddie, 340), (chloe, 375)])
        mom.facing = 1
        for g in [lily, maddie, chloe] { g.facing = -1 }
        try await look(at: Stage.shot(centerX: 230, height: 270))
        try await say(chloe, "What's under the sheet?", 2.2)
        caption = "Gia pulls the cover off!"
        try await sleep(0.8)
        boothCovered = false
        sound.ding()
        try await sleep(0.6)
        try await say(maddie, "A spray tan booth!", 2)
        try await say(lily, "Wow!", 1.4)
        try await say(mom, "I built it myself last night! I'll go first and show you how it works.", 3.6)
        caption = "Gia shows the girls the instructions."
        signUntil = .now + 5
        try await sleep(5)
        try await look(at: Stage.full)
        try await boothTurn(mom)
        try await walk(mom, to: 410)
        mom.facing = -1
        try await say(mom, "See? Nothing to it! Who's next?", 2.4)

        for (girl, ask) in [(maddie, "Me! Me!"), (chloe, "My turn!")] {
            let spot = girl.x1
            try await say(girl, ask, 1.6)
            try await boothTurn(girl)
            try await walk(girl, to: spot)
            girl.facing = -1
        }

        // The youngest is scared at first.
        try await look(at: Stage.shot(centerX: 330, height: 250))
        lily.facing = 1
        try await say(mom, "Your turn.", 1.8)
        lily.mood = .scared
        caption = "Lily isn't so sure…"
        try await say(lily, "I'm scared, Mommy… what if it hurts?", 2.8)
        try await say(mom, "It doesn't hurt one bit, sweetie. It feels like a warm, misty rain.", 3.2)
        lily.facing = -1
        try await say(maddie, "It just tickles a little! You'll love it!", 2.6)
        try await say(chloe, "Come on, Lily — we'll be right here the whole time!", 2.8)
        lily.facing = 1
        try await say(mom, "And look how pretty your sisters' tans came out!", 2.8)
        lily.mood = .normal
        try await say(lily, "Okay… I'll try it!", 2.2)
        try await look(at: Stage.full)
        try await boothTurn(lily)
        try await say(lily, "That wasn't scary at all! I love my tan!", 3)
        try await say(mom, "I'm so proud of you, Lily!", 2.4)

        caption = "Everyone gathers around."
        try await walkAll([(mom, 250), (lily, 285), (chloe, 320), (maddie, 355)])
        for p in cast { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 302, height: 245))
        try await say(mom, "Look at us — now we all match!", 2.6)
        let summary = cast.compactMap { p in p.level.map { "\(p.id): \($0.title)" } }
        caption = "The whole family got spray tans!  " + summary.joined(separator: " · ")
        try await sleep(3)

        try await demonstration()
        do {
            try await business()
        } catch is EndGame {}
        try await look(at: Stage.full)
        caption = "Game over! \(trips) \(trips == 1 ? "trip" : "trips"), \(totalTans) spray tans sold, \(nights) \(nights == 1 ? "night" : "nights"). "
            + "Cash on hand: $\(cash), savings in the bank: $\(bank)." + (paidOut > 0 ? " Cousins, aunts and babysitters were paid $\(paidOut)." : "")
        finished = true
        running = false
    }

    // MARK: Public demonstration

    private func demonstration() async throws {
        let (mom, maddie, chloe, lily) = (mom, maddie, chloe, lily)
        caption = "Maddie has an idea…"
        try await say(maddie, "Let's do a public demonstration of the booth!", 3)
        try await say(chloe, "People would pay for a spray tan like ours!", 3)
        try await say(mom, "I quit my job at the salon — this could be our new business!", 3)
        try await say(mom, "We'd have to pay to set up the booth. We have $\(Venue.startCash) saved.", 3.4)
        try await say(lily, "Let's pick a place!", 2)
    }

    /// Visitors stroll across from the right; the girls stop them and ask.
    /// Anyone who says no just keeps walking.
    private func serveGroup(_ venue: Venue, _ team: Team) async throws {
        // The cashier takes the money; one greeter asks the grown-up, the other asks the kids.
        let (mom, maddie, chloe) = (team.cashier, team.adultGreeter, team.kidGreeter)
        if adultNames.isEmpty { adultNames = Self.momNames.shuffled() }
        if kidNames.isEmpty { kidNames = Self.childNames.shuffled() }
        // Groups of up to three: a grown-up on her own, or a mom with one or two kids.
        let roll = Double.random(in: 0...1)
        let kidCount = roll < 0.4 ? 0 : (roll < 0.75 ? 1 : 2)
        let adult = Person.customer(adultNames.removeLast(), kid: false, x: 1290)
        let kids = (0..<kidCount).map { i -> Person in
            if kidNames.isEmpty { kidNames = Self.childNames.shuffled() }
            return Person.customer(kidNames.removeLast(), kid: true, x: 1335 + Double(i) * 40)
        }
        let group = [adult] + kids
        customers = group

        // Stroll in; the greeters stop them next to the booth.
        let stroll = 80.0
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((1290 - 990) / stroll)
        for p in group { stop(p) }

        let noLines = ["No thanks!", "Maybe another time.", "Not today, thanks."]
        let kidNoLines = ["No way, it looks cold!", "I'd rather get cotton candy!", "Nope, I'm scared!", "Hmm… no thank you."]
        try await say(maddie, "Excuse me! Would you like a spray tan? Only $\(venue.price)!", 2.8)
        let adultYes = Double.random(in: 0...1) < venue.adultYes
        try await say(adult, adultYes
            ? ["Ooh, yes please!", "Sure, why not?", "I've always wanted to try one!"].randomElement()!
            : noLines.randomElement()!, 2.2)

        var buyers = adultYes ? [adult] : []
        for (i, kid) in kids.enumerated() {
            try await say(chloe, i == 0 ? (kids.count == 1 ? "How about you? Do you want to get spray tanned too?" : "How about you two? Want a spray tan?")
                                        : "And you, \(kid.id)?", 2.6)
            if Double.random(in: 0...1) < venue.kidYes {
                try await say(kid, ["Yes! Can I, Mom? Please?", "Me too! Me too!", "Yes please!"].randomElement()!, 2.2)
                buyers.append(kid)
            } else {
                try await say(kid, kidNoLines.randomElement()!, 2.2)
            }
        }
        if kids.contains(where: { buyers.contains($0) }) {
            try await say(adult, adultYes ? "Sure, sweetie! We'll all do it." : "Okay, go ahead, sweetie.", 2.2)
        }

        // In a group, anyone who said no gets a second chance right away if nobody said yes.
        if buyers.isEmpty && group.count >= 2 {
            caption = "\(maddie.id) and \(chloe.id) give them a second chance…"
            try await say(maddie, "Are you sure? It only takes five minutes, and you'll look like you just got back from the beach!", 3.4)
            buyers = try await secondChance(group, venue: venue)
        }

        guard !buyers.isEmpty else {
            caption = "\(adult.id) keeps walking."
            for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
            try await sleep((990 + 150) / stroll)
            customers = []
            return
        }

        // Pay at the cash table, then take turns in the booth.
        caption = "\(adult.id) heads to the cash table."
        try await walkAll(group.enumerated().map { ($1, Stage.cashX + 50 + Double($0) * 35) })
        for p in group { p.facing = -1 }
        try await payAndTan(buyers, payer: adult, cashier: mom, venue: venue)

        // Anyone in the group who still said no gets a second chance once they see the others' tans.
        let holdouts = group.filter { !buyers.contains($0) }
        if group.count >= 2 && !holdouts.isEmpty {
            caption = "Seeing the new tans, \(holdouts.map(\.id).joined(separator: " and ")) \(holdouts.count == 1 ? "gets" : "get") a second chance…"
            for p in holdouts { p.facing = 1 }
            mom.facing = 1
            try await say(mom, holdouts.count == 1 ? "\(holdouts[0].id), now that you've seen how great it looks — want one too?"
                                                 : "Now that you've seen how great it looks — want one too?", 3)
            let more = try await secondChance(holdouts, venue: venue, sawIt: true)
            if !more.isEmpty {
                try await payAndTan(more, payer: adult, cashier: mom, venue: venue)
                buyers += more
            }
        }
        try await say(adult, ["Thank you! We love it!", "Worth every penny!", "Wait till my friends see this!"].randomElement()!, 2.4)

        caption = "Off they go, nice and tan!"
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((Stage.cashX + 160 + 150) / stroll)
        customers = []
    }

    /// Each of `people` thinks again. Kids are easier to win over; seeing someone else's tan helps.
    private func secondChance(_ people: [Person], venue: Venue, sawIt: Bool = false) async throws -> [Person] {
        var yes: [Person] = []
        for p in people {
            let kid = p.headScale > 0.14
            let odds = (kid ? 0.65 : 0.5) + (sawIt ? 0.15 : 0)
            if Double.random(in: 0...1) < odds {
                try await say(p, kid ? ["Okay, I'll try it!", "Well… okay, yes!", "I changed my mind — yes please!"].randomElement()!
                                     : ["You know what? Why not!", "Oh, go on then — I'll do it!", "Alright, you talked me into it!"].randomElement()!, 2.4)
                yes.append(p)
            } else {
                try await say(p, kid ? "No thanks, really!" : "Still no, but thank you!", 2)
            }
        }
        return yes
    }

    /// The payer hands over the money for everyone in `buyers`, and they take turns in the booth.
    private func payAndTan(_ buyers: [Person], payer: Person, cashier: Person, venue: Venue) async throws {
        cashier.facing = 1
        let amount = buyers.count * venue.price
        try await say(cashier, "That'll be $\(amount), please!", 2)
        cash += amount
        tansSold += buyers.count
        cashPop = ("+$\(amount)", .now)
        sound.ching()
        try await sleep(1.2)
        for p in buyers {
            let spot = p.x1
            try await boothTurn(p, level: TanLevel.allCases.randomElement()!)
            served.append(PersonSpec(p, family: false))
            try await poof(p, .clothes)
            try await walk(p, to: spot)
            p.facing = -1
        }
    }

    /// Where the booth sits: the house's empty room, or the middle of the venue.
    private var boothShift: Double { venue == nil && place != .convention ? 0 : Stage.venueShift }

    /// What each of the family says as the spray reaches her legs, her tummy and arms, and her face.
    private static let sprayLines: [String: (legs: String, body: String, face: String)] = [
        "Lily": ("Ooh, it tickles my toes!", "It feels like a warm, misty rain!", "My face too! Hee hee — I love it!"),
        "Maddie": ("My legs are turning so golden!", "This feels amazing!", "Here comes my face — best day ever!"),
        "Chloe": ("Wow, look at my legs!", "Now my tummy and arms — so cool!", "My face is getting tanned! I'm going to look awesome!"),
        "Gia": ("Ooh, that feels nice on my legs!", "It's just like a day at the spa!", "Even my face! I feel so pretty!"),
    ]

    /// Customers' own happy lines as the spray climbs: legs, tummy and arms, face. Grown-ups and kids each have their own.
    private static let adultLines: (legs: [String], body: [String], face: [String]) = (
        ["Oh, that's lovely and warm!", "My legs look like I just got back from Hawaii!", "Ooh, this is so relaxing!",
         "Look at that glow already!", "My legs haven't looked this good in years!", "Mmm, it smells like coconut!",
         "This is the best money I've spent all day!", "So smooth and even!"],
        ["It's like a mini vacation!", "My arms are going golden!", "I could stand here all day!",
         "Wait till my friends see this!", "Now that's a beach-ready tan!", "This beats lying in the sun for hours!",
         "I feel like a movie star!", "So much better than a sunburn!"],
        ["Even my face! I'm glowing!", "My face is getting that sun-kissed look!", "My face is getting tanned!",
         "Here comes my face — I love it!", "Now my face is turning tan!", "My face and cheeks are going all golden!",
         "Here goes my face!", "Now its doing my face!"])
    private static let kidLines: (legs: [String], body: [String], face: [String]) = (
        ["Hee hee! It tickles!", "My legs are turning gold!", "Ooh, it's like a warm cloud!", "Wheee! This is fun!",
         "Look, Mom! My legs!", "It feels like bubbles!"],
        ["My tummy too! Hee hee!", "Now my arms are getting tan!", "This is the coolest thing ever!", "I'm a golden kid!",
         "It's like a misty rain!", "Best day EVER!"],
        ["My face! My face! Hee hee!", "Mom look my face is getting tanned!", "Now its doing my face!",
         "Here comes my pretty face!", "Here comes a nice tan face!", "Now for a nice tan face!"])
    /// More to say while the mist covers their face: the family's own pair, and dealt decks for everyone else.
    private static let familyFaceMore: [String: [String]] = [
        "Lily": ["Eyes closed tight… hee hee, it tickles my nose!", "My cheeks are getting all golden, Mommy!"],
        "Maddie": ["Mmm, my cheeks feel so warm and tingly.", "Holding my breath… I'm going to look like a movie star!"],
        "Chloe": ["Eyes shut! It's like a cool breeze on my face!", "I bet my nose is super tan now!"],
        "Gia": ["Ahh… it's like a little facial at the spa.", "My cheeks and forehead feel so smooth and warm!"],
    ]
    private static let adultFaceMore = [
        "Eyes closed… mmm, it's like a cool mist on my cheeks.", "My cheeks feel all warm and tingly!",
        "Holding my breath… there goes my nose!", "Ooh, now my forehead and chin!", "It smells like coconut and sunshine!",
        "Don't forget my neck — ooh, there it goes!", "I can feel it on my eyelids — so soft!",
        "My face is going to match my legs perfectly!", "No more pale winter face for me!", "It's like a facial and a vacation in one!",
    ]
    private static let kidFaceMore = [
        "Hee hee! It's tickling my nose!", "I'm keeping my eyes shut tight!", "My cheeks feel all tingly!",
        "Pfff! I'm holding my breath!", "It's like a bubble bath for my face!", "Am I tan yet? Am I tan yet?",
        "My ears are getting tan too!", "It feels like a sneeze is coming… nope!",
    ]
    /// What the rest of the family calls out while someone's face is being sprayed (only those standing by the booth).
    private func faceWatchers(_ p: Person) -> [(Person, String)] {
        let lines: [(Person, String)]
        switch p.id {
        case "Maddie": lines = [(mom, "Keep your eyes closed, sweetie — you're doing great!"),
                                (lily, "Maddie, your face is getting all golden!")]
        case "Chloe": lines = [(maddie, "Hold your breath, Chloe! Here comes your nose!"),
                               (mom, "Oh, Chloe, your cheeks look so pretty!")]
        case "Gia": lines = [(lily, "Mommy, your face is turning all golden!"),
                             (chloe, "Keep your eyes closed, Mom! You look amazing!"),
                             (maddie, "Wow, Mom, you look like a movie star!")]
        case "Lily": lines = [(mom, "You're doing so great, sweetie! Keep those eyes closed!"),
                              (chloe, "See, Lily? Nothing to be scared of!")]
        default: lines = []
        }
        return lines.filter { $0.0.visible && $0.0 !== p }
    }

    @ObservationIgnored private var adultFaceDeck = [String]()
    @ObservationIgnored private var kidFaceDeck = [String]()

    /// Extra face-stage lines: two for the family (30s spray), one for customers and visitors.
    private func faceMoreLines(_ p: Person, family: Bool) -> [String] {
        if family, let mine = Self.familyFaceMore[p.id] { return mine }
        let kid = p.headScale > 0.14
        if kid {
            if kidFaceDeck.isEmpty { kidFaceDeck = Self.kidFaceMore.shuffled() }
            return [kidFaceDeck.removeLast()]
        }
        if adultFaceDeck.isEmpty { adultFaceDeck = Self.adultFaceMore.shuffled() }
        return [adultFaceDeck.removeLast()]
    }

    @ObservationIgnored private var adultDeck = (legs: [String](), body: [String](), face: [String]())
    @ObservationIgnored private var kidDeck = (legs: [String](), body: [String](), face: [String]())

    @ObservationIgnored private var mirrorDeck = [String]()
    @ObservationIgnored private var kidMirrorDeck = [String]()

    /// A customer's first look in the mirror, dealt so it changes from customer to customer.
    private func nextMirrorLine(kid: Bool, level: TanLevel) -> String {
        let adults = ["Look at me! I'm gorgeous!", "That's the best tan I've ever had!", "I can't stop smiling!",
                      "My friends are going to be so jealous!", "Wow — \(level.title.lowercased()) suits me perfectly!",
                      "I look like I just stepped off a cruise ship!", "Five minutes well spent!", "I feel fabulous!"]
        let kids = ["I'm so tan! Woo-hoo!", "Look how golden I am!", "I look like a beach kid!", "That was AWESOME!",
                    "Mom, look at me!", "I want to stay this color forever!"]
        if kid {
            if kidMirrorDeck.isEmpty { kidMirrorDeck = kids.shuffled() }
            return kidMirrorDeck.removeLast()
        }
        if mirrorDeck.isEmpty { mirrorDeck = adults.shuffled() }
        return mirrorDeck.removeLast()
    }

    /// The next customer's three lines, dealt from shuffled decks so no two customers in a row say the same thing.
    private func nextCustomerLines(kid: Bool) -> (legs: String, body: String, face: String) {
        func deal(_ deck: inout [String], _ pool: [String]) -> String {
            if deck.isEmpty { deck = pool.shuffled() }
            return deck.removeLast()
        }
        let pool = kid ? Self.kidLines : Self.adultLines
        if kid {
            return (deal(&kidDeck.legs, pool.legs), deal(&kidDeck.body, pool.body), deal(&kidDeck.face, pool.face))
        }
        return (deal(&adultDeck.legs, pool.legs), deal(&adultDeck.body, pool.body), deal(&adultDeck.face, pool.face))
    }

    /// With `level` the person picks it themselves; otherwise the player does.
    private func boothTurn(_ p: Person, level chosen: TanLevel? = nil) async throws {
        let dx = boothShift
        caption = "\(p.id) changes into a bikini."
        try await poof(p, .swim)
        caption = "\(p.id) steps into the booth."
        try await walk(p, to: Stage.boothX + dx)
        p.facing = 0
        boothClosed = true
        try await look(at: Stage.boothView.offsetBy(dx: dx, dy: 0))
        let level: TanLevel
        if let chosen {
            caption = "\(p.id) picks a tan level…"
            try await sleep(1.4)
            caption = "\(p.id) presses \(chosen.title)!"
            try await sleep(1.2)
            level = chosen
        } else {
            caption = "\(p.id) is in the booth. Press a button to pick the tan level!"
            level = await withCheckedContinuation { cont in
                pick = cont
                choosingFor = p
            }
            try Task.checkCancellation()
        }

        // Five minutes, sped up: the mist starts at the feet and works its way up to the face.
        let family = cast.contains { $0 === p }
        let watchers = family ? faceWatchers(p) : []
        let faceMore = faceMoreLines(p, family: family)
        // Stretch the family's session if the face stage has more talking than fits (it's still "five minutes").
        let faceTalk = 3.0 + Double(faceMore.count) * 2.8 + Double(watchers.count) * 2.6
        let dur = family ? max(Spray.family, (faceTalk + 1.4) / (1 - Spray.faceStart)) : Spray.customer
        let visitor = Self.visitorLines[p.id]
        let lines = family ? Self.sprayLines[p.id]
            : visitor.map { (legs: $0.legs, body: $0.body, face: $0.face) } ?? nextCustomerLines(kid: p.headScale > 0.14)
        caption = "Pssshhh! The jets start spraying \(p.id)'s legs (\(level.title))."
        let now = Date.now
        sprayT0 = now
        sprayDur = dur
        clockT0 = now
        clockDur = dur
        p.skin0 = p.skin(at: now)
        p.skin1 = level.skin
        p.tanT0 = now
        p.tanDur = dur
        p.level = level
        sound.spray(true)
        if let lines { try await sleep(1.2); try await say(p, lines.legs, 2.6) }
        try await sleep(max(0, (now + dur * Spray.bodyStart).timeIntervalSinceNow))
        caption = "The mist moves up to \(p.id)'s tummy and arms…"
        if let lines { try await sleep(0.6); try await say(p, lines.body, 2.6) }
        // Close in on her face the moment the jets reach it.
        try await sleep(max(0, (now + dur * Spray.faceStart).timeIntervalSinceNow))
        caption = "Now the jets spray \(p.id)'s face…"
        let head = Stage.headY(of: p)
        try await look(at: Stage.focus(CGPoint(x: Stage.boothX + dx, y: head + 6), height: max(110, p.height * 0.62)))
        if let lines {
            try await say(p, lines.face, family ? 2.8 : 2.4)
            caption = "Eyes closed, \(p.id) holds still while the mist covers cheeks, nose and forehead…"
            let more = faceMore
            for i in 0..<max(more.count, watchers.count) {
                if i < watchers.count {
                    let (w, line) = watchers[i]
                    caption = "\(w.id) calls out to \(p.id) from outside the booth."
                    try await say(w, line, 2.4)
                }
                if i < more.count {
                    if i == more.count - 1 && more.count > 1 { caption = "The last of the mist settles on \(p.id)'s face…" }
                    try await say(p, more[i], family ? 2.6 : 2.4)
                }
            }
        }
        try await sleep(max(0, (now + dur).timeIntervalSinceNow))
        sound.spray(false)
        try await look(at: Stage.boothView.offsetBy(dx: dx, dy: 0))
        caption = "Whirr! Warm air dries \(p.id)'s tan."
        dryT0 = .now
        dryDur = 2.5
        sound.dryer(true)
        try await sleep(2.5)
        sound.dryer(false)
        sound.ding()
        try await sleep(0.3)
        boothClosed = false
        try await sleep(0.6)

        caption = "\(p.id) looks in the mirror."
        cut(to: Stage.shot(centerX: 215 + dx, height: p.height + 95))
        try await walk(p, to: Stage.mirrorStand + dx)
        p.facing = -1
        try await sleep(0.5)
        try await say(p, family ? level.reaction : visitor?.mirror ?? nextMirrorLine(kid: p.headScale > 0.14, level: level), 2.8)
        try await look(at: Stage.full)
    }

    // MARK: Trips, nights and visitors

    /// Groceries cost this much; and this much cash stays on hand for the next setup fee, the rest goes in the bank.
    private static let groceryBill = 30
    private static let keepForSetup = 120
    private static let vacationCost = 150
    private static let cheapestFee = Venue.allCases.map(\.fee).min()!

    /// The family's own trip: Mom at the cash table, Maddie and Chloe greeting, Lily helping.
    private var familyTeam: Team { Team(cashier: mom, adultGreeter: maddie, kidGreeter: chloe, helpers: [lily]) }

    /// Two trips a day, then someone shops and banks and everyone rests. After odd nights an aunt and cousin come over;
    /// from the second night on, after even nights there's the chance of a mini vacation with a babysitter.
    private func business() async throws {
        var firstDay = true
        while true {
            if nights % 2 == 1 {
                // After odd nights: an aunt and cousin come over (two trips).
                try await auntVisit()
            } else if nights >= 2, try await askVacation() {
                // The babysitter's two trips, the older sister's shopping night, and Mom home the next morning.
                try await babysitterDays()
                try await afterMorning()
                continue
            } else {
                if !firstDay { try await askNext("A new day! Ready for the first trip?") }
                firstDay = false
                try await trip(familyTeam)
                try await askNext("Ready for the day's second trip?")
                try await trip(familyTeam)
            }
            try await nightRest(shopper: nextShopper())
            try await afterMorning()
        }
    }

    /// Anything that happens the morning after a night: after the seventh, the family's tans wear off.
    private func afterMorning() async throws {
        if nights == 7 { try await tansFade() }
    }

    /// Takes turns: Mom, Maddie and Chloe (Lily is too little to go to the store on her own).
    private func nextShopper() -> Person {
        defer { shopperTurn += 1 }
        return [mom, maddie, chloe][shopperTurn % 3]
    }

    private func askNext(_ prompt: String) async throws {
        if cash < Self.cheapestFee {
            if bank > 0 {
                let take = min(bank, Self.keepForSetup)
                bank -= take
                cash += take
                caption = "They take $\(take) out of the bank for the next setup fee."
                try await sleep(2.4)
            } else {
                caption = "They're out of money for another setup fee."
                try await sleep(2.4)
                throw EndGame()
            }
        }
        nextPrompt = prompt
        let again = await withCheckedContinuation { cont in
            nextPick = cont
            choosingNext = true
            caption = "Keep going, or end the game?"
        }
        try Task.checkCancellation()
        guard again else { throw EndGame() }
    }

    private func askVacation() async throws -> Bool {
        guard cash + bank >= Self.vacationCost + Self.cheapestFee else { return false }
        try await look(at: Stage.shot(centerX: 680, height: 250))
        try await say(mom, "Girls, I could use a little getaway. A one-night mini vacation is $\(Self.vacationCost).", 3.2)
        let go = await withCheckedContinuation { cont in
            vacationPick = cont
            choosingVacation = true
            caption = "Should Gia take one of the girls on a one-night mini vacation? She'll hire a babysitter."
        }
        try Task.checkCancellation()
        return go
    }

    /// One trip to a venue the player picks. The team goes; everyone else stays home.
    private func trip(_ team: Team) async throws {
        let startCash = cash
        let home = everyone.filter { $0.visible && !team.members.contains($0) }
        tansSold = 0
        served = []
        result = nil
        try await look(at: Stage.full)
        caption = "Where should they set up the booth? They have $\(cash)."
        let venue = await withCheckedContinuation { cont in
            venuePick = cont
            choosingVenue = true
        }
        try Task.checkCancellation()

        // Pack up the booth and head out.
        fadeT0 = .now
        try await sleep(0.5)
        self.venue = venue
        bagsX = nil
        night = false
        for p in everyone { p.visible = team.members.contains(p) }
        var spots = [(team.cashier, Stage.cashX), (team.adultGreeter, 850.0), (team.kidGreeter, 890.0)]
        for (i, p) in team.helpers.enumerated() { spots.append((p, 350 - Double(i) * 38)) }
        for (p, x) in spots {
            p.outfit = .clothes
            p.carrying = false
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
        }
        try await sleep(0.8)

        caption = "They set up the booth at the \(venue.name). Setup fee: $\(venue.fee)."
        cash -= venue.fee
        cashPop = ("-$\(venue.fee)", .now)
        try await sleep(2)
        if let n = team.newcomer {
            let spot = n.x1
            caption = "First, \(n.id) gets a spray tan of her own!"
            try await say(team.cashier, "\(n.id), you go first!", 2)
            try await boothTurn(n)
            try await poof(n, .clothes)
            try await walk(n, to: spot)
            n.facing = 1
        }
        try await say(team.cashier, "Step right up! Spray tans, only $\(venue.price)!", 2.8)

        for k in 1...venue.groups {
            caption = "Visitor \(k) of \(venue.groups) comes strolling by."
            try await serveGroup(venue, team)
        }

        var result = DemoResult(venue: venue, tans: tansSold, startCash: startCash, endCash: cash)
        caption = "Closing time at the \(venue.name)! \(tansSold) spray tans sold."
        try await walkAll(team.members.enumerated().map { ($1, 800 + Double($0) * 35) })
        for p in team.members { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 850, height: 245))
        let talker = team.cashier
        if result.profit > 0 {
            try await say(talker, "We made $\(result.profit) profit!", 2.6)
        } else if result.profit == 0 {
            try await say(talker, "We broke even. Still a fun day!", 2.6)
        } else {
            try await say(talker, "We lost $\(-result.profit)… but it sure was fun!", 2.8)
        }
        if let (payee, fraction) = team.payee {
            let share = max(0, result.profit) / fraction
            let part = fraction == 4 ? "one quarter" : "one third"
            if share > 0 {
                cash -= share
                paidOut += share
                result.share = share
                cashPop = ("-$\(share) to \(payee.id)", .now)
                sound.ching()
                try await say(talker, "\(payee.id), here's your \(part) of the profit: $\(share)!", 3)
                try await say(payee, payee.headScale > 0.14 ? "Wow! $\(share), all for me? Thank you!" : "$\(share)! Thank you — that was a blast!", 2.6)
            } else {
                try await say(payee, "No profit this time, but I had so much fun!", 2.6)
            }
        }
        totalTans += tansSold
        trips += 1
        self.result = result
        album.add(EventRecord(date: .now, venue: venue, tans: result.tans, startCash: startCash, endCash: cash,
                              family: team.members.map { PersonSpec($0, family: cast.contains($0)) }, customers: served))
        caption = "Trip over at the \(venue.name). Time to head home."
        try await sleep(1.6)

        // Home again: the team in the living room, and whoever stayed home is still there.
        fadeT0 = .now
        try await sleep(0.5)
        self.venue = nil
        customers = []
        for (i, p) in team.members.enumerated() {
            p.visible = true
            (p.x0, p.x1, p.moveDur, p.facing) = (600 + Double(i) * 35, 600 + Double(i) * 35, 0, 1)
        }
        for p in home { p.visible = true }
        cut(to: Stage.full)
        camFrom = Stage.full
        try await sleep(0.8)
    }

    /// One of them goes to buy groceries and make a deposit; everyone else goes to bed, and so does she when she gets back.
    private func nightRest(shopper: Person, sitterStays: Person? = nil) async throws {
        let home = everyone.filter { $0.visible && !customers.contains($0) }
        let others = home.filter { $0 !== shopper }
        try await look(at: Stage.shot(centerX: 680, height: 250))
        caption = "That's two trips! Time for groceries, the bank, and some rest."
        try await say(shopper, "I'll go buy groceries and put our money in the bank.", 2.8)
        try await say(others.first { $0 !== sitterStays } ?? shopper, "Okay! We'll get some rest.", 2)
        try await look(at: Stage.full)

        // Everyone else heads to bed.
        caption = "\(shopper.id) heads out, and everyone else goes to bed."
        _ = beginWalk(shopper, to: Stage.doorX, speed: 140)
        try await walkAll(others.map { ($0, bedX($0)) })
        doorOpenUntil = .now + 1
        shopper.visible = false
        for p in others {
            p.visible = false
            sleepers.append((p.id, bedX(p)))
        }
        try await sleep(1)

        // Town: the grocery store, then the bank.
        fadeT0 = .now
        try await sleep(0.5)
        inTown = true
        shopper.visible = true
        shopper.outfit = .clothes
        (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
        try await sleep(0.8)
        caption = "First stop: the grocery store."
        try await walk(shopper, to: Stage.storeDoorX, speed: 140)
        shopper.visible = false
        let food = min(Self.groceryBill, cash)
        cash -= food
        cashPop = ("-$\(food) groceries", .now)
        caption = "\(shopper.id) buys $\(food) of groceries."
        try await sleep(1.8)
        shopper.visible = true
        shopper.carrying = true
        shopper.facing = 1
        try await say(shopper, "Dinner and breakfast — done!", 2)
        caption = "Next stop: the bank."
        try await walk(shopper, to: Stage.bankDoorX, speed: 140)
        shopper.visible = false
        let deposit = max(0, (cash - Self.keepForSetup) / 10 * 10)
        try await sleep(1.2)
        if deposit > 0 {
            cash -= deposit
            bank += deposit
            cashPop = ("Deposited $\(deposit)", .now)
            sound.ching()
            caption = "\(shopper.id) deposits $\(deposit). Savings in the bank: $\(bank)."
        } else {
            caption = "\(shopper.id) keeps what's left for the next setup fee."
        }
        try await sleep(2)
        shopper.visible = true
        shopper.facing = 1
        try await say(shopper, deposit > 0 ? "Our savings keep growing!" : "Nothing extra to deposit today.", 2.2)
        try await walk(shopper, to: Stage.W + 60, speed: 150)

        // Home in the dark.
        fadeT0 = .now
        try await sleep(0.5)
        inTown = false
        night = true
        (shopper.x0, shopper.x1, shopper.moveDur, shopper.facing) = (Stage.doorX, Stage.doorX, 0, -1)
        try await sleep(0.8)
        caption = "It's dark by the time \(shopper.id) gets home."
        doorOpenUntil = .now + 1
        try await walk(shopper, to: 720, speed: 110)
        shopper.carrying = false
        try await say(shopper, "Groceries are put away. Good night, everyone!", 2.4)
        try await walk(shopper, to: bedX(shopper), speed: 120)
        shopper.visible = false
        sleepers.append((shopper.id, bedX(shopper)))
        caption = "Everyone gets a good night's rest."
        try await sleep(3.5)
        nights += 1

        // The next morning
        fadeT0 = .now
        try await sleep(0.5)
        night = false
        sleepers = []
        for (i, p) in home.enumerated() {
            p.visible = true
            p.outfit = .clothes
            (p.x0, p.x1, p.moveDur, p.facing) = (600 + Double(i) * 35, 600 + Double(i) * 35, 0, 1)
        }
        try await sleep(0.8)
        caption = "The next morning…  (Night \(nights))"
        sound.ding()
        try await sleep(1.4)
        try await say(home.last ?? shopper, ["Good morning! I feel so rested!", "Rise and shine — let's make some money!",
                                             "What a great sleep!"].randomElement()!, 2.2)
    }

    /// Where each of them sleeps: Mom in her room, the girls in the bunk bed, a babysitter on the couch.
    private func bedX(_ p: Person) -> Double {
        if p === mom { return 1110 }
        if cast.contains(p) { return 880 + Double([maddie, chloe, lily].firstIndex(of: p) ?? 0) * 30 }
        return 640
    }

    /// After a week, the family's spray tans wear off.
    private func tansFade() async throws {
        try await look(at: Stage.shot(centerX: 670, height: 250))
        caption = "It's been a whole week… the family's spray tans slowly fade away."
        let now = Date.now
        for p in cast {
            p.skin0 = p.skin1
            p.skin1 = .fair
            p.tanT0 = now
            p.tanDur = 6
            p.level = nil
        }
        try await sleep(6.2)
        try await say(mom, "Our tans are gone! What a wonderful week it was.", 2.8)
        try await say(lily, "Can we get tanned again someday?", 2.2)
        try await say(mom, "Anytime, sweetie — we have our very own booth!", 2.6)
    }

    // MARK: Aunts and cousins

    private struct Aunt {
        let name, cousin: String
        let age: Int
        let hair, kidHair: RGB
        let style, kidStyle: HairStyle
        let shirt, kidShirt, swim, kidSwim: RGB
        let hello: String
    }

    private static let aunts: [Aunt] = [
        Aunt(name: "Karen", cousin: "Mia", age: 3, hair: RGB(r: 0.30, g: 0.18, b: 0.10), kidHair: RGB(r: 0.35, g: 0.20, b: 0.10),
             style: .long, kidStyle: .pigtails, shirt: RGB(r: 0.85, g: 0.30, b: 0.45), kidShirt: RGB(r: 1.0, g: 0.80, b: 0.30),
             swim: RGB(r: 0.20, g: 0.50, b: 0.85), kidSwim: RGB(r: 1.0, g: 0.45, b: 0.65), hello: "Good morning! Mia couldn't wait to see her cousins!"),
        Aunt(name: "Rachel", cousin: "Ava", age: 4, hair: RGB(r: 0.92, g: 0.78, b: 0.42), kidHair: RGB(r: 0.95, g: 0.82, b: 0.45),
             style: .ponytail, kidStyle: .pigtails, shirt: RGB(r: 0.30, g: 0.65, b: 0.55), kidShirt: RGB(r: 0.60, g: 0.40, b: 0.85),
             swim: RGB(r: 0.95, g: 0.55, b: 0.15), kidSwim: RGB(r: 0.30, g: 0.75, b: 0.90), hello: "Hi, sis! Ava has been asking about you all week!"),
        Aunt(name: "Monica", cousin: "Zoe", age: 5, hair: RGB(r: 0.10, g: 0.08, b: 0.06), kidHair: RGB(r: 0.12, g: 0.09, b: 0.07),
             style: .long, kidStyle: .ponytail, shirt: RGB(r: 0.55, g: 0.35, b: 0.75), kidShirt: RGB(r: 0.95, g: 0.50, b: 0.70),
             swim: RGB(r: 0.10, g: 0.65, b: 0.55), kidSwim: RGB(r: 0.98, g: 0.75, b: 0.20), hello: "Surprise! Zoe and I brought you some cookies!"),
        Aunt(name: "Tracy", cousin: "Ella", age: 6, hair: RGB(r: 0.72, g: 0.32, b: 0.14), kidHair: RGB(r: 0.78, g: 0.36, b: 0.16),
             style: .ponytail, kidStyle: .long, shirt: RGB(r: 0.95, g: 0.70, b: 0.20), kidShirt: RGB(r: 0.30, g: 0.70, b: 0.45),
             swim: RGB(r: 0.80, g: 0.20, b: 0.30), kidSwim: RGB(r: 0.55, g: 0.40, b: 0.90), hello: "Hello, everybody! Ella wore her favorite shirt for you!"),
        Aunt(name: "Wendy", cousin: "Ruby", age: 7, hair: RGB(r: 0.45, g: 0.28, b: 0.14), kidHair: RGB(r: 0.50, g: 0.30, b: 0.15),
             style: .long, kidStyle: .long, shirt: RGB(r: 0.25, g: 0.45, b: 0.85), kidShirt: RGB(r: 0.98, g: 0.45, b: 0.35),
             swim: RGB(r: 1.0, g: 0.40, b: 0.70), kidSwim: RGB(r: 0.20, g: 0.80, b: 0.60), hello: "Good morning! Ruby says she's old enough to help now!"),
    ]

    /// After odd nights: an aunt takes Mom clothes shopping and leaves her daughter, who goes on a trip with the girls;
    /// then the aunt goes on a trip of her own with Mom and two of the girls.
    private func auntVisit() async throws {
        let (mom, maddie, chloe, lily) = (mom, maddie, chloe, lily)
        let v = Self.aunts[auntVisits % Self.aunts.count]
        auntVisits += 1
        let aunt = Person("Aunt \(v.name)", height: 150, headScale: 0.12, hair: v.hair, style: v.style,
                          shirt: v.shirt, bottoms: RGB(r: 0.25, g: 0.28, b: 0.42), swim: v.swim, x: Stage.doorX)
        let cousin = Person(v.cousin, height: 82 + Double(v.age - 3) * 8, headScale: 0.17 - Double(v.age - 3) * 0.004, hair: v.kidHair,
                            style: v.kidStyle, shirt: v.kidShirt, bottoms: RGB(r: 0.95, g: 0.55, b: 0.70), swim: v.kidSwim, onePiece: true, x: Stage.doorX)
        visitors = [aunt, cousin]

        try await look(at: Stage.full)
        try await walkAll([(lily, 600), (chloe, 635), (maddie, 670), (mom, 705)])
        for p in cast { p.facing = 1 }
        caption = "Ding-dong! It's Aunt \(v.name), Gia's sister, with her little girl \(v.cousin), who is \(v.age)."
        sound.ding()
        doorOpenUntil = .now + 1.4
        try await walkAll([(cousin, 745), (aunt, 770)])
        for p in visitors { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 700, height: 240))
        try await say(aunt, v.hello, 3)
        try await say(mom, "\(v.name)! \(v.cousin)! Come in, come in!", 2.4)
        try await say(cousin, "Hi, cousins!", 1.8)
        if cast.contains(where: { $0.level != nil }) {
            // They can't help noticing everyone's tan.
            try await say(aunt, "Wait a minute… why are you all so tan?", 2.4)
            try await say(cousin, "Did you go to the beach without us?", 2.2)
            try await say(mom, "Ha! You'll find out soon enough.", 2.2)
        }
        try await say(aunt, "Want to go clothes shopping with me today? Maybe the girls could watch \(v.cousin)?", 3.4)
        try await say(mom, "I'd love to! The girls will take great care of her.", 2.6)

        caption = "Before they go, Gia has a quick word with the girls…"
        try await say(mom, "Take \(v.cousin) on a tanning trip, and give her one quarter of the profits.", 3.2)
        try await say(maddie, "You got it, Mom!", 1.8)
        try await say(aunt, "Have fun, \(v.cousin)! We'll be back this afternoon.", 2.6)
        try await say(cousin, "Bye, Mommy!", 1.6)
        caption = "Gia and Aunt \(v.name) head out to go clothes shopping."
        try await walkAll([(mom, Stage.doorX), (aunt, Stage.doorX)])
        doorOpenUntil = .now + 1
        for p in [mom, aunt] { p.visible = false }
        try await say(cousin, "What's a tanning trip?", 2)
        try await say(chloe, "Come on — we'll show you our secret!", 2.2)

        // The girls show their cousin the booth in the empty room, and she tries it.
        caption = "The girls take \(v.cousin) to the empty room and show her the booth."
        try await walkAll([(cousin, 300), (lily, 335), (chloe, 370), (maddie, 405)])
        for p in [cousin, lily, chloe, maddie] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 260, height: 250))
        try await say(maddie, "This is our spray tan booth! That's how we all got so tan.", 2.8)
        try await say(cousin, "Wow! Can I try it? Please?", 2)
        try await say(lily, "Put on your swimsuit and step inside!", 2.2)
        try await boothTurn(cousin)
        try await poof(cousin, .clothes)
        try await walk(cousin, to: 300)
        cousin.facing = 1
        try await say(chloe, "Now let's go sell spray tans — you get one quarter of the profits!", 2.8)
        try await say(cousin, "Yay! Let's go!", 1.6)

        try await askNext("Take \(v.cousin) on her first tanning trip?")
        try await trip(Team(cashier: maddie, adultGreeter: chloe, kidGreeter: cousin, helpers: [lily], payee: (cousin, 4)))
        let cousinShare = result?.share ?? 0

        // The grown-ups come home from shopping.
        try await walkAll([(lily, 600), (chloe, 635), (maddie, 660), (cousin, 700)])
        for p in [lily, chloe, maddie, cousin] { p.facing = 1 }
        caption = "Gia and Aunt \(v.name) come home with bags of new clothes."
        for p in [mom, aunt] {
            p.visible = true
            p.carrying = true
            (p.x0, p.x1, p.moveDur) = (Stage.doorX, Stage.doorX, 0)
        }
        doorOpenUntil = .now + 1.4
        try await walkAll([(aunt, 740), (mom, 765)])
        for p in [mom, aunt] {
            p.facing = -1
            p.carrying = false
        }
        try await look(at: Stage.shot(centerX: 700, height: 240))
        try await say(mom, "We're home! We found the cutest outfits!", 2.4)
        cousin.facing = 1
        try await say(aunt, "\(v.cousin)?! Look at you — how did you get so tan?", 2.6)
        if cousinShare > 0 {
            try await say(cousin, "The girls showed me a magic booth! And look, Mommy — I made $\(cousinShare)!", 3.2)
            try await say(aunt, "$\(cousinShare)?! A magic booth? You have to show me!", 2.6)
        } else {
            try await say(cousin, "The girls showed me a magic booth! Then I helped sell spray tans!", 3)
            try await say(aunt, "A magic booth? You have to show me!", 2.2)
        }

        // The cousin shows her mother the booth, and the aunt tries it too.
        caption = "\(v.cousin) shows her mother the booth in the empty room."
        try await walkAll([(cousin, 300), (aunt, 340), (mom, 380), (maddie, 415), (chloe, 445), (lily, 470)])
        for p in [cousin, aunt, mom, maddie, chloe, lily] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 270, height: 250))
        try await say(cousin, "This is it, Mommy! You put on a swimsuit and press a button!", 2.8)
        try await say(aunt, "Well, I have to try this!", 2)
        try await boothTurn(aunt)
        try await poof(aunt, .clothes)
        try await walk(aunt, to: 340)
        aunt.facing = 1
        try await say(aunt, "I want to go on a trip too! You, me, and two of the girls!", 3)
        try await say(mom, "Great idea! You'll get one quarter of the profits.", 2.6)
        let stay: Person = [maddie, chloe, lily].randomElement()!
        let goers: [Person] = [maddie, chloe, lily].filter { $0 !== stay }
        try await say(stay, "I'll stay here and play with \(v.cousin)!", 2.4)
        try await say(cousin, "Yay!", 1.4)

        try await askNext("Go on a trip with Aunt \(v.name)?")
        try await trip(Team(cashier: mom, adultGreeter: goers[0], kidGreeter: goers[1], helpers: [aunt], payee: (aunt, 4)))

        // Goodbyes
        try await look(at: Stage.shot(centerX: 680, height: 250))
        try await say(aunt, "That was the most fun I've had in ages! Thank you!", 2.8)
        try await say(cousin, "Bye, everybody! Can we come back soon?", 2.4)
        try await say(mom, "Anytime! We love you both!", 2.2)
        caption = "Aunt \(v.name) and \(v.cousin) head home, nice and tan."
        try await walkAll([(cousin, Stage.doorX), (aunt, Stage.doorX)])
        doorOpenUntil = .now + 1
        try await sleep(0.4)
        visitors = []
    }

    // MARK: Mini vacation and the babysitter

    private struct Sitter {
        let name: String
        let hair: RGB
        let style: HairStyle
        let shirt, swim: RGB
        let hello: String
    }

    private static let sitters: [Sitter] = [
        Sitter(name: "Brooke", hair: RGB(r: 0.92, g: 0.78, b: 0.42), style: .ponytail, shirt: RGB(r: 0.95, g: 0.45, b: 0.60),
               swim: RGB(r: 0.20, g: 0.70, b: 0.85), hello: "Hi! I'm Brooke. I'm so excited to hang out with you!"),
        Sitter(name: "Kayla", hair: RGB(r: 0.10, g: 0.08, b: 0.06), style: .long, shirt: RGB(r: 0.40, g: 0.60, b: 0.90),
               swim: RGB(r: 0.95, g: 0.30, b: 0.40), hello: "Hey, girls! I'm Kayla. This is going to be a blast!"),
        Sitter(name: "Jenna", hair: RGB(r: 0.72, g: 0.32, b: 0.14), style: .ponytail, shirt: RGB(r: 0.35, g: 0.70, b: 0.45),
               swim: RGB(r: 0.98, g: 0.70, b: 0.20), hello: "Hi there! I'm Jenna. I've heard you girls are super fun!"),
        Sitter(name: "Taylor", hair: RGB(r: 0.45, g: 0.28, b: 0.14), style: .long, shirt: RGB(r: 0.98, g: 0.75, b: 0.25),
               swim: RGB(r: 0.60, g: 0.35, b: 0.85), hello: "Hello! I'm Taylor. I brought snacks!"),
        Sitter(name: "Sierra", hair: RGB(r: 0.30, g: 0.18, b: 0.10), style: .pigtails, shirt: RGB(r: 0.60, g: 0.40, b: 0.85),
               swim: RGB(r: 1.0, g: 0.45, b: 0.70), hello: "Hi, everyone! I'm Sierra. Ready for an awesome day?"),
    ]

    /// Mom takes one of the girls on a one-night mini vacation and hires a babysitter, who takes the other two on two trips
    /// for a third of the profits. Then the older one shops and banks, and Mom comes home the next morning.
    private func babysitterDays() async throws {
        let mom = mom
        let traveler: Person = [lily, chloe, maddie][sitterVisits % 3]
        let stayers: [Person] = [maddie, chloe, lily].filter { $0 !== traveler }
        let s = Self.sitters[sitterVisits % Self.sitters.count]
        sitterVisits += 1

        try await say(mom, "\(traveler.id) and I are going on a mini vacation!", 2.6)
        try await say(traveler, "Yay! A mini vacation!", 1.8)
        if cash < Self.vacationCost {
            let take = Self.vacationCost - cash
            bank -= take
            cash += take
        }
        cash -= Self.vacationCost
        cashPop = ("-$\(Self.vacationCost) mini vacation", .now)
        sound.ching()
        try await say(mom, "I've hired a babysitter. She'll be here any minute!", 2.6)

        let sitter = Person(s.name, height: 146, headScale: 0.125, hair: s.hair, style: s.style,
                            shirt: s.shirt, bottoms: RGB(r: 0.25, g: 0.30, b: 0.50), swim: s.swim, x: Stage.doorX)
        visitors = [sitter]
        caption = "Ding-dong! The babysitter is here."
        sound.ding()
        doorOpenUntil = .now + 1.4
        try await walk(sitter, to: 770)
        sitter.facing = -1
        try await look(at: Stage.shot(centerX: 700, height: 240))
        try await say(sitter, s.hello, 2.8)
        try await say(mom, "Girls, this is \(s.name). \(stayers[0].id), \(stayers[1].id) — go on a trip with \(s.name), and give her one third of the profits.", 4)
        try await say(stayers[0], "We will, Mom!", 1.8)
        try await say(sitter, "A spray tan business? That sounds amazing!", 2.4)
        try await say(mom, "We'll be back tomorrow morning. Have fun!", 2.4)
        try await say(traveler, "Bye! We'll bring you souvenirs!", 2)
        caption = "Gia and \(traveler.id) leave for their mini vacation."
        for p in [mom, traveler] { p.carrying = true }
        try await walkAll([(mom, Stage.doorX), (traveler, Stage.doorX)])
        doorOpenUntil = .now + 1
        for p in [mom, traveler] {
            p.visible = false
            p.carrying = false
        }

        // The girls show the babysitter the booth at home, and she tries it before their first trip.
        try await say(sitter, "So, how do you girls make money?", 2.2)
        try await say(stayers[1], "Come see our secret!", 1.8)
        caption = "The girls take \(s.name) to the empty room and show her the booth."
        try await walkAll([(sitter, 300), (stayers[1], 345), (stayers[0], 385)])
        for p in [sitter, stayers[1], stayers[0]] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 260, height: 250))
        try await say(stayers[0], "It's a spray tan booth! People pay us to use it.", 2.6)
        try await say(sitter, "No way! Can I try it?", 2)
        try await say(stayers[1], "Sure! Put on your bikini and step inside!", 2.2)
        try await boothTurn(sitter)
        try await poof(sitter, .clothes)
        try await walk(sitter, to: 300)
        sitter.facing = 1
        try await say(sitter, "Okay, now I get it! Let's go sell some spray tans!", 2.6)

        let team = Team(cashier: stayers[0], adultGreeter: sitter, kidGreeter: stayers[1], payee: (sitter, 3))
        try await askNext("Go on a trip with \(s.name)?")
        try await trip(team)
        try await askNext("One more trip with \(s.name)?")
        try await trip(team)

        // The older sister shops and banks; the babysitter sleeps over on the couch.
        try await nightRest(shopper: stayers[0], sitterStays: sitter)

        // Mom and the traveler come home.
        caption = "Gia and \(traveler.id) come home from their mini vacation!"
        for p in [mom, traveler] {
            p.visible = true
            p.carrying = true
            (p.x0, p.x1, p.moveDur) = (Stage.doorX, Stage.doorX, 0)
        }
        doorOpenUntil = .now + 1.4
        try await walkAll([(traveler, 745), (mom, 770)])
        for p in [mom, traveler] {
            p.facing = -1
            p.carrying = false
        }
        try await look(at: Stage.shot(centerX: 700, height: 240))
        try await say(mom, "We're home! Did you have fun with \(s.name)?", 2.4)
        try await say(stayers[1], "The best! She got a spray tan, too!", 2.2)
        try await say(sitter, "Best babysitting job ever! Thank you so much!", 2.6)
        try await say(mom, "Thank you, \(s.name)! Come back anytime.", 2.2)
        caption = "\(s.name) heads home."
        try await walk(sitter, to: Stage.doorX)
        doorOpenUntil = .now + 1
        visitors = []
    }

    /// Each aunt, cousin and babysitter has her own happy lines as she gets tanned: legs, tummy and arms, face, and the mirror.
    private static let visitorLines: [String: (legs: String, body: String, face: String, mirror: String)] = [
        "Aunt Karen": ("Oh my, that's warm and lovely!", "I feel like I'm on a cruise!", "My face too? I love this!", "Look at me! I look ten years younger!"),
        "Aunt Rachel": ("Ooh, it tickles a little!", "This is better than a day at the spa!", "Here comes my face — how fun!", "Wow! I'm absolutely glowing!"),
        "Aunt Monica": ("My legs look fantastic already!", "So warm and relaxing!", "Even my face! This is wonderful!", "I can't believe how good this looks!"),
        "Aunt Tracy": ("Now this is my kind of fun!", "I feel like a movie star!", "My face is getting so golden!", "Gorgeous! I need one of these booths!"),
        "Aunt Wendy": ("Ahh, that feels so nice!", "It's like a warm summer breeze!", "Ooh, my face! I love it!", "I look like I just got back from Hawaii!"),
        "Mia": ("Hee hee! My toes!", "It's like warm bubbles!", "My face! Hee hee hee!", "I'm a golden girl!"),
        "Ava": ("Ooh! It's tickly!", "My tummy is getting tan!", "My nose too! So funny!", "Look, I'm so tan!"),
        "Zoe": ("Wow, my legs!", "It's like a misty rain!", "My face is getting tan! Yay!", "I look like a beach girl!"),
        "Ella": ("This is so cool!", "My arms are turning gold!", "Here comes my face — I love it!", "I'm the tannest kid ever!"),
        "Ruby": ("Ooh, it feels warm!", "I feel like a grown-up!", "My face! This is awesome!", "I look amazing! Thank you!"),
        "Brooke": ("Oh, this is so fun!", "Wait till my friends see this!", "My face too! Best job ever!", "Wow, I look like a surfer girl!"),
        "Kayla": ("My legs look amazing!", "This is way better than the beach!", "Here comes my face — love it!", "I'm totally glowing!"),
        "Jenna": ("Ooh, warm and misty!", "I could stay in here all day!", "Even my face! So cool!", "This is the best tan I've ever had!"),
        "Taylor": ("Ha! It tickles!", "My arms are going golden!", "My face is getting tanned! Yay!", "I look like a movie star!"),
        "Sierra": ("This feels amazing!", "So relaxing!", "My face! I love it!", "I'm so golden! Thank you!"),
    ]

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

    private func walkAll(_ moves: [(Person, Double)]) async throws {
        let longest = moves.map { beginWalk($0.0, to: $0.1, speed: 130) }.max() ?? 0
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

    private func poof(_ p: Person, _ outfit: Outfit) async throws {
        p.poofT0 = .now
        try await sleep(0.35)
        p.outfit = outfit
        try await sleep(0.5)
    }
}
