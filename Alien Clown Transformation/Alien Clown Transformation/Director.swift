import SwiftUI

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var deidre: Person
    var kelly: Person
    var jen: Person

    var cast: [Person] { [deidre, kelly, jen] }
    /// The repo man, Deidre's boyfriend, his new girlfriend, and her mean boss at Funland.
    var extras: [Person] = []
    /// The cruise ship's alien clowns; the last one is their ringmaster.
    var crew: [Person] = []
    var customers: [Person] = []
    /// Deidre's sister and her little girl (the aunts take turns), who visit the morning after every odd night.
    var family: [Person] = []
    /// Who is on this trip: greeter, cashier, machinist, then anyone else along for the ride.
    var team: [Person] = []
    /// A visitor counted in the meters (none at the moment).
    var guest: Person?
    /// Passers-by who came aboard for today's cruise; each goes home to the port she boarded at.
    var passengers: [Person] = []
    var everyone: [Person] { cast + family + extras + crew + customers + passengers }
    /// The top-right meters: Mom and the girls, plus any visitors once they have been clowns.
    var hudPeople: [Person] { cast + (family + (guest.map { [$0] } ?? [])).filter { $0.clown != nil } }
    private var leader: Person { crew[crew.count - 1] }

    var caption = "Tap Start to begin."
    var running = false
    var finished = false
    var muted = false {
        didSet {
            sound.muted = muted
            poker?.voice.muted = muted
            if muted { poker?.voice.stop() }
        }
    }

    var place = Place.house
    /// The glowing pink button the alien clowns leave in the living room.
    var buttonShown = false
    var buttonPressT0 = Date.distantPast

    // The driveway: Deidre's car and the repo man's tow truck
    var carShown = false
    var carHooked = false
    var truckShown = false
    private var truckFrom = Stage.truckX
    private var truckTo = Stage.truckX
    private var truckT0 = Date.distantPast
    private var truckDur = 0.0

    // Funland's parking lot: the zamboni Deidre drives (she sits on it while `zamboniRider`).
    var zamboniShown = false
    var zamboniRider: Person?
    private var zamboniParkedX = Stage.zamboniStartX
    /// The coworkers' three maintenance zambonis, and the repo men's flatbed that hauls them away.
    var fleet: [ParkZamboni] = []
    var flatbedShown = false
    private var flatbedFrom = -700.0
    private var flatbedTo = -700.0
    private var flatbedT0 = Date.distantPast
    private var flatbedDur = 0.0
    /// A scuffle between the boss and the repo man: where, and when the last punch landed.
    var scuffle: (x: Double, t0: Date)?
    static let loadDur = 1.6
    /// Deidre's old coworkers who lose their Funland jobs and join the S.S. Big Top's crew; they're on deck from then on.
    var recruits: [Person] = []
    /// The afternoon of the first cruise: the bank closes Funland and switches off its lights.
    var parkLightsOut = false
    var funlandClosed = false
    /// What the repo men have started winching onto their flatbed the afternoon Funland goes under, and when.
    /// Once the flatbed has driven off, those things are gone from the park for good.
    var parkHaul: [ParkRide: Date] = [:]
    static let rideLoadDur = 2.4
    /// The flatbed coming back with nothing on it (for Mr. Grimsby's motorcycle), so the rides don't reappear on its bed.
    var flatbedEmpty = false
    /// Mr. Grimsby's motorcycle, parked by the park office until the repo guy rides off on it.
    var motorcycleShown = true
    var motorcycleRider: Person?

    // The Clowns of Poker machine in the spare room
    var pokerShown = false
    var pokerAppearT0 = Date.distantPast
    /// What the cabinet's little screen says when it isn't showing cards.
    var pokerScreen = ""
    /// The sitting being played on the machine, shown full screen while `pokerPlaying`.
    var poker: PokerSession?
    var pokerPlaying = false

    // The cruise ship (the code still calls it the tent: it plays the same part)
    var tentShown = false
    /// Under way: the sea streaks past the ship's portholes.
    var tentFlying = false
    /// The gangway, run out from the ship's deck down to the yard or the quay, and when it started moving.
    var gangwayOut = false
    var gangwayT0 = Date.distantPast
    private var tentFrom = CGPoint.zero
    private var tentTo = CGPoint.zero
    private var tentT0 = Date.distantPast
    private var tentDur = 0.0

    // The transformation chairs
    var strapped: Set<String> = []
    var strapT0 = Date.distantPast
    var consolePressT0 = Date.distantPast
    var screen = "READY"
    /// The big mirror the clowns lower in front of the chairs, and when it goes back up.
    var mirrorT0 = Date.distantFuture
    var mirrorUpT0 = Date.distantPast
    /// Whoever is waiting for the player to pick her type of clown.
    var choosingKind: Person?
    /// The chairs are folded away so the passengers can stand on deck (for the mini saucers, or a card game).
    var chairsStowed = false
    /// Everyone with a mini saucer over her head right now, when the run started, and how long the flight out takes.
    var saucerPeople: [Person] = []
    var saucerT0 = Date.distantPast
    var saucerFlight = SaucerRun.lower
    /// Where the mini saucers fly from when it isn't the machine on deck (the ship, out behind a house).
    var miniTentFrom: CGPoint?
    /// The ship's pink beam that sets a passenger down ashore, and when it switched on or off.
    var beamOn = false
    var beamT0 = Date.distantPast
    /// The kid whose computer the Clowns of Poker downloaded itself onto (their room is labelled with it).
    var rescueKidName = ""
    @ObservationIgnored private var rescues = 0

    // A just-for-fun card game on a day at sea
    /// The scoreboard while a game is on; the table view seats one person per row.
    var board: TableBoard?
    /// Who sits in each scoreboard row.
    var tableSeats: [Person] = []
    /// The cards on the table, by game seat.
    var tableGroups: [FeltGroup] = []
    /// Your scoreboard row, if you're playing.
    var humanRow: Int?
    /// Who you are at the table.
    var you: String?
    /// Your cards, shown under the table.
    var myHand: [Card] = []
    /// What the table is waiting for you to decide.
    var prompt: PlayerPrompt?
    /// Let the computer make your plays.
    var autoPlay = false

    var card: InfoCard?
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
    /// The cabins for a night aboard: a door plate and whoever sleeps in its bunk beds (lower bunk first).
    var cabins: [(label: String, guests: [Person])] = []

    // Trips to venues
    var venue: Venue?
    /// The player is planning the next part of the cruise day: a port, a day at sea, or the end of the day.
    var choosingDay = false
    /// Ports and days at sea so far today.
    var stopsToday = 0
    /// The morning after a night aboard: which of the two port stops the player is picking (1 or 2), else nil.
    var morningStop: Int?
    /// Fares taken in and docking fees paid today.
    var dayEarned = 0
    var dayFees = 0
    var dayProfit: Int { dayEarned - dayFees }
    var choosingNext = false
    var cash = Venue.startCash
    /// Floating "+$" / "-$" over where the money changed hands.
    var cashPop: (text: String, t0: Date, x: Double)?
    var result: EventRecord?
    var trips = 0
    /// The jobs rotate each time they do it again, so everyone gets a turn working the machine.
    var rotation = 0
    /// How many times an aunt and cousin have come over.
    var familyVisits = 0
    /// How many times Brad has dropped Amber off before a business trip.
    var bradVisits = 0
    var totalProfit = 0
    var totalTransformed = 0
    /// How many people the ship can carry on a cruise, besides the family.
    static let baseCapacity = 20
    /// Upgrades bought for the S.S. Big Top at the ship-supply shop; they stay on the ship for good.
    var upgrades: Set<ShipUpgrade> = []
    /// How many passengers fit aboard — more once the extra deck chairs are fitted.
    var capacity: Int { Self.baseCapacity + (upgrades.contains(.deckChairs) ? ShipUpgrade.extraSeats : 0) }
    /// What has gone into the bank; setup fees come out of `cash` only.
    var bank = 0
    /// What they have bought out of their savings and parked in the driveway.
    var vehicles: Set<Vehicle> = []
    /// The one being brought home from the dealer right now, and whoever is riding it.
    var arriving: Vehicle?
    var rider: Person?
    private var arriveT0 = Date.distantPast
    /// Whoever is in the ship-supply shop waiting for the player to pick an upgrade.
    var choosingUpgrade: Person?
    var choosingVehicle = false

    /// The game saved at the end of a day, if there is one ("Continue" on the start screen).
    var saved: SaveGame? = SaveGame.load()
    /// The end-of-day prompt has just been saved (the Save button shows a check mark).
    var savedToday = false
    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var dayPick: CheckedContinuation<DayPlan, Never>?
    @ObservationIgnored private var answerWait: CheckedContinuation<PlayerAnswer, Never>?
    @ObservationIgnored private var answerAuto: PlayerAnswer?
    /// The port each passenger came aboard at.
    @ObservationIgnored private var boardedAt: [ObjectIdentifier: Venue] = [:]
    /// Nights slept at home so far.
    @ObservationIgnored private(set) var nights = 0
    @ObservationIgnored private var kindPick: CheckedContinuation<ClownKind, Never>?
    @ObservationIgnored private var nextPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var upgradePick: CheckedContinuation<ShipUpgrade?, Never>?
    @ObservationIgnored private var vehiclePick: CheckedContinuation<Vehicle?, Never>?
    @ObservationIgnored private var pokerDone: CheckedContinuation<Void, Never>?
    @ObservationIgnored private var served: [PersonSpec] = []
    @ObservationIgnored private var asked = 0
    @ObservationIgnored private var earned = 0
    @ObservationIgnored private var adultNames: [String] = []
    private static let menNames = ["Carlos", "Eddie", "Hank", "Jamal", "Steve", "Victor", "Kenji", "Luis"]
    private static let womenNames = ["Gina", "Iris", "Paula", "Nadia", "Leilani", "Carmen", "Stacy", "Irene", "Lori", "Dawn"]
    @ObservationIgnored private var momNames: [String] = []
    @ObservationIgnored private var kidNames: [String] = []

    init() {
        (deidre, kelly, jen) = Self.makeCast()
        team = [deidre, kelly, jen]
    }

    /// Two go outside — the first asks passers-by, the second takes the money — and one stays in to work the machine.
    private var roles: (greeter: Person, cashier: Person, machinist: Person) { (team[0], team[1], team[2]) }

    private static func makeCast() -> (Person, Person, Person) {
        let deidre = Person("Deidre", height: 160, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.07, g: 0.07, b: 0.09), style: .waist,
                            shirt: RGB(r: 0.20, g: 0.55, b: 0.60), pants: RGB(r: 0.22, g: 0.24, b: 0.34), shorts: false, x: -40)
        // Her two daughters: Kelly, the older one, and Jen, the youngest.
        let kelly = Person("Kelly", height: 130, headScale: 0.145, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.10, g: 0.10, b: 0.10), style: .curly,
                           shirt: RGB(r: 0.98, g: 0.80, b: 0.25), pants: RGB(r: 0.30, g: 0.42, b: 0.68), kid: true, x: Stage.livingX[1])
        let jen = Person("Jen", height: 110, headScale: 0.155, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.07, g: 0.07, b: 0.09), style: .ponytail,
                         shirt: RGB(r: 0.60, g: 0.40, b: 0.80), pants: RGB(r: 0.55, g: 0.75, b: 0.95), kid: true, x: Stage.livingX[2])
        for p in [deidre, kelly, jen] { p.visible = false }
        return (deidre, kelly, jen)
    }

    private static func makeExtras() -> [Person] {
        let repo = Person("Repo Man", height: 172, skin: RGB(r: 0.85, g: 0.65, b: 0.50), hair: RGB(r: 0.20, g: 0.12, b: 0.08), style: .short,
                          shirt: RGB(r: 0.30, g: 0.34, b: 0.42), pants: RGB(r: 0.20, g: 0.22, b: 0.28), shorts: false, female: false, x: 335)
        let brad = Person("Brad", height: 170, skin: RGB(r: 0.96, g: 0.80, b: 0.68), hair: RGB(r: 0.45, g: 0.28, b: 0.14), style: .short,
                          shirt: RGB(r: 0.30, g: 0.62, b: 0.40), pants: RGB(r: 0.72, g: 0.62, b: 0.45), shorts: false, female: false, x: Stage.boyfriendX)
        let amber = Person("Amber", height: 158, skin: RGB(r: 0.99, g: 0.86, b: 0.76), hair: RGB(r: 0.92, g: 0.78, b: 0.42), style: .long,
                           shirt: RGB(r: 0.90, g: 0.25, b: 0.35), pants: RGB(r: 0.95, g: 0.95, b: 0.95), x: -40)
        // Mr. Grimsby, Funland's park manager: a mean boss who keeps her on the maintenance zamboni.
        let boss = Person("Mr. Grimsby", height: 176, skin: RGB(r: 0.92, g: 0.74, b: 0.62), hair: RGB(r: 0.40, g: 0.40, b: 0.42), style: .short,
                          shirt: RGB(r: 0.55, g: 0.12, b: 0.16), pants: RGB(r: 0.18, g: 0.18, b: 0.22), shorts: false, female: false, x: Stage.parkOfficeX)
        // Deidre's coworkers at Funland, in their red park shirts, and the health inspector who shuts the park.
        let funRed = RGB(r: 0.85, g: 0.15, b: 0.35)
        let rita = Person("Rita", height: 158, skin: RGB(r: 0.93, g: 0.76, b: 0.62), hair: RGB(r: 0.55, g: 0.25, b: 0.10), style: .ponytail,
                          shirt: funRed, pants: RGB(r: 0.20, g: 0.25, b: 0.40), shorts: false, x: 640)
        let sam = Person("Sam", height: 172, skin: RGB(r: 0.55, g: 0.38, b: 0.26), hair: RGB(r: 0.08, g: 0.06, b: 0.05), style: .short,
                         shirt: funRed, pants: RGB(r: 0.72, g: 0.62, b: 0.45), shorts: false, female: false, x: -60)
        let tammy = Person("Tammy", height: 154, skin: RGB(r: 0.99, g: 0.86, b: 0.76), hair: RGB(r: 0.95, g: 0.82, b: 0.45), style: .curly,
                           shirt: funRed, pants: RGB(r: 0.20, g: 0.25, b: 0.40), shorts: false, x: 1260)
        // The two Shore Savings Bank representatives who come to shut Funland down for missed loan payments.
        let banker = Person("Bank Rep", height: 176, skin: RGB(r: 0.80, g: 0.62, b: 0.48), hair: RGB(r: 0.25, g: 0.18, b: 0.12), style: .short,
                            shirt: RGB(r: 0.16, g: 0.20, b: 0.30), pants: RGB(r: 0.16, g: 0.20, b: 0.30), shorts: false, female: false, x: -60)
        let bankManager = Person("Bank Manager", height: 164, skin: RGB(r: 0.95, g: 0.80, b: 0.68), hair: RGB(r: 0.30, g: 0.18, b: 0.10), style: .bun,
                                 shirt: RGB(r: 0.32, g: 0.30, b: 0.36), pants: RGB(r: 0.32, g: 0.30, b: 0.36), shorts: false, x: -110)
        // The repo man's partner, who comes along to Funland to take the zambonis.
        let repo2 = Person("Repo Guy", height: 180, skin: RGB(r: 0.70, g: 0.52, b: 0.40), hair: RGB(r: 0.10, g: 0.08, b: 0.06), style: .short,
                           shirt: RGB(r: 0.30, g: 0.34, b: 0.42), pants: RGB(r: 0.20, g: 0.22, b: 0.28), shorts: false, female: false, x: -60)
        let all = [repo, brad, amber, boss, rita, sam, tammy, banker, repo2, bankManager]
        for p in all { p.visible = false }
        return all
    }

    /// What a visiting mother says on her first ride, start to finish — each mom loves it in her own way.
    struct MomLines {
        var spotTent, beamUp, inTent, whatsNext, straps, tingle, legs, body, face, faceShout, headFeel, secret, bestDay: String
    }

    static func momLines(_ mom: String, kid: String) -> MomLines {
        switch mom {
        case "Carol": MomLines(
            spotTent: "Well, I'll be! A cruise ship pulling up to the yard!",
            beamUp: "Up, up and awaaay!",
            inTent: "Oh my stars, look at all these clowns! Hello there!",
            whatsNext: "\(kid), sweetheart, I haven't been this excited since the county fair!",
            straps: "Buckled in, just like a roller coaster. I love roller coasters!",
            tingle: "Hee hee! It's like a hundred little feathers!",
            legs: "My legs! Look at those big floppy shoes!",
            body: "A jumpsuit and a big ruffle collar — so stylish!",
            face: "Ooh, I can feel my head and face transforming",
            faceShout: "Yahoooooooo!",
            headFeel: "My goodness, my head is as round as a beach ball — how marvelous!",
            secret: "So THAT'S your secret! Count me in — honk honk!",
            bestDay: "Best day of my life, and I've been to Dollywood!")
        case "Rosa": MomLines(
            spotTent: "¡Ay, qué bonito! A cruise ship right beside the house!",
            beamUp: "¡Wepa! Here I gooo!",
            inTent: "¡Mira! Clowns everywhere! Hola, everybody!",
            whatsNext: "\(kid), mija, your abuela will never believe this!",
            straps: "Seat belts? Good — I want to stay for the whole show!",
            tingle: "Oh, that's a happy little tingle!",
            legs: "Look at my legs — I feel like dancing salsa!",
            body: "My whole body is turning clown! ¡Fantástico!",
            face: "Ooh, now my face… I can feel it smiling…",
            faceShout: "¡Olé-é-é-éééé!",
            headFeel: "¡Ay! My head is so big and soft — like a piñata!",
            secret: "So THAT'S your secret! ¡Vámonos! Let's go make some money!",
            bestDay: "¡Qué día! The most fun I've had since my wedding!")
        default: MomLines(
            spotTent: "Oh, how fun! A cruise ship full of clowns!",
            beamUp: "Wheee!",
            inTent: "A real circus on a cruise ship! Hello, everyone!",
            whatsNext: "\(kid), this is wonderful! What happens next?",
            straps: "Ooh, seat belts! This must be quite a ride!",
            tingle: "Ooh, this really tickles!",
            legs: "Ooh, my legs are changing!",
            body: "I'm turning into an alien clown! How fun!",
            face: "Here comes my face…",
            faceShout: "Wheeeeeeeeee!",
            headFeel: "My head feels so big and round — I love it!",
            secret: "So THAT'S your secret! Honk honk! Let's go make some money!",
            bestDay: "The most fun I've had in years!")
        }
    }

    /// One of Deidre's sisters and her little girl (`daughter` just picks which family: Kelly/Jen/Deidre → Linda/Carol/Rosa).
    private static func makeFamily(age: Int, for daughter: String) -> [Person] {
        let looks: (mom: String, kid: String, skin: RGB, momHair: RGB, momStyle: HairStyle, kidHair: RGB, kidStyle: HairStyle,
                    momShirt: RGB, kidShirt: RGB) = switch daughter {
        case "Jen": ("Carol", "Emma", RGB(r: 0.96, g: 0.80, b: 0.68), RGB(r: 0.72, g: 0.36, b: 0.16), .bob,
                     RGB(r: 0.80, g: 0.45, b: 0.20), .ponytail, RGB(r: 0.30, g: 0.60, b: 0.45), RGB(r: 1.0, g: 0.85, b: 0.30))
        case "Deidre": ("Rosa", "Mia", RGB(r: 0.80, g: 0.60, b: 0.45), RGB(r: 0.08, g: 0.06, b: 0.06), .long,
                        RGB(r: 0.08, g: 0.06, b: 0.06), .pigtails, RGB(r: 0.55, g: 0.30, b: 0.70), RGB(r: 0.45, g: 0.80, b: 0.90))
        default: ("Linda", "Sophie", RGB(r: 0.85, g: 0.65, b: 0.50), RGB(r: 0.22, g: 0.16, b: 0.12), .bun,
                  RGB(r: 0.10, g: 0.10, b: 0.10), .pigtails, RGB(r: 0.85, g: 0.40, b: 0.55), RGB(r: 1.0, g: 0.62, b: 0.76))
        }
        let mom = Person(looks.mom, height: 158, skin: looks.skin, hair: looks.momHair, style: looks.momStyle,
                         shirt: looks.momShirt, pants: RGB(r: 0.30, g: 0.30, b: 0.42), shorts: false, x: -60)
        let sophie = Person(looks.kid, height: 96 + Double(age - 4) * 8, headScale: 0.16, skin: looks.skin, hair: looks.kidHair,
                            style: looks.kidStyle, shirt: looks.kidShirt, pants: RGB(r: 0.55, g: 0.75, b: 0.95), kid: true, x: -60)
        for p in [mom, sophie] { p.visible = false }
        return [mom, sophie]
    }

    /// Where the clowns wait, off stage, before they close in around the chairs.
    private static let wingsX = [-60.0, -110, -160, 1260, 1310]

    private static func makeCrew() -> [Person] {
        let clowns: [(String, ClownKind, Double)] = [("Bonko", .bigTop, 168), ("Zazzle", .dotty, 150), ("Pip", .jester, 138),
                                                     ("Wobble", .cottonCandy, 176), ("Fizzbo", .starburst, 160)]
        return zip(clowns, wingsX).map { clown, x in
            let p = Person.alienClown(clown.0, kind: clown.1, height: clown.2, x: x)
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

    /// The middle of the ship's keel line, bobbing gently while it hovers or floats.
    func tent(at now: Date) -> CGPoint? {
        guard tentShown else { return nil }
        let t = min(max(now.timeIntervalSince(tentT0) / max(tentDur, 0.001), 0), 1)
        let e = t * t * (3 - 2 * t)
        let bob = sin(now.timeIntervalSinceReferenceDate * 2) * 3
        return CGPoint(x: tentFrom.x + (tentTo.x - tentFrom.x) * e, y: tentFrom.y + (tentTo.y - tentFrom.y) * e + bob)
    }

    /// The zamboni: under its driver while she rides it, otherwise parked where it stopped.
    func zamboni(at now: Date) -> Double? {
        guard zamboniShown else { return nil }
        return zamboniRider?.x(at: now) ?? zamboniParkedX
    }

    /// The repo men's flatbed (its bed's left end), easing to a stop on the way in and speeding up on the way out.
    func flatbed(at now: Date) -> Double? {
        guard flatbedShown else { return nil }
        let t = min(max(now.timeIntervalSince(flatbedT0) / max(flatbedDur, 0.001), 0), 1)
        let e = flatbedFrom >= Stage.flatbedX - 1 ? t * t : t * (2 - t)
        return flatbedFrom + (flatbedTo - flatbedFrom) * e
    }

    private func driveFlatbed(to x: Double, seconds: Double) {
        flatbedFrom = flatbed(at: .now) ?? flatbedFrom
        flatbedTo = x
        flatbedT0 = .now
        flatbedDur = seconds
    }

    /// Where each of the coworkers' zambonis is (driver's seat x) and how far off the ground: under its driver,
    /// parked, being winched up onto the flatbed, or riding away on it.
    func fleetSpots(at now: Date) -> [(x: Double, lift: Double)] {
        let bed = flatbed(at: now)
        return fleet.map { z in
            let ground = z.rider?.x(at: now) ?? z.parkedX
            guard let slot = z.slot, let bed else { return (ground, 0) }
            let t = min(max(now.timeIntervalSince(z.loadT0) / Self.loadDur, 0), 1)
            let e = t * t * (3 - 2 * t)
            return (ground + (bed + slot - ground) * e, Stage.flatbedDeck * e)
        }
    }

    /// Mr. Grimsby's motorcycle: parked by the office, or under the repo guy as he rides off on it.
    func motorcycle(at now: Date) -> Double? {
        guard motorcycleShown else { return nil }
        return motorcycleRider?.x(at: now) ?? Stage.motorcycleX
    }

    /// Where the tow truck is, pulling away slowly at first.
    func truck(at now: Date) -> Double? {
        guard truckShown else { return nil }
        let t = min(max(now.timeIntervalSince(truckT0) / max(truckDur, 0.001), 0), 1)
        return truckFrom + (truckTo - truckFrom) * t * t
    }

    /// Deidre's car: parked in the driveway, or hanging off the back of the tow truck.
    func car(at now: Date) -> (x: Double, hooked: Bool)? {
        guard carShown else { return nil }
        guard carHooked, let truck = truck(at: now) else { return (Stage.carX, false) }
        return (truck + Stage.carX - Stage.truckX, true)
    }

    /// Where one of their own vehicles is: parked in the driveway, or rolling in from the street.
    func parked(_ vehicle: Vehicle, at now: Date) -> Double? {
        guard vehicles.contains(vehicle) else { return nil }
        let spot = vehicle == .car ? Stage.carX : Stage.scooterX
        guard arriving == vehicle else { return spot }
        let t = min(max(now.timeIntervalSince(arriveT0) / Self.arriveDur, 0), 1)
        return -160 + (spot + 160) * (1 - (1 - t) * (1 - t))
    }

    private static let arriveDur = 2.6

    /// What is left to spend on ship upgrades once the cheapest setup fee is set aside.
    var spendingMoney: Int { cash - Venue.cheapestFee }

    /// What the console's screen says.
    func screenText(_ now: Date) -> String {
        if let p = everyone.first(where: { $0.visible && !$0.crew && $0.isTingling(at: now) }) {
            if now < p.changeT0 { return "TINGLE\nPHASE" }
            let left = Int((1 - p.progress(at: now)) * 300)
            return String(format: "TRANSFORMING\n%d:%02d", left / 60, left % 60)
        }
        return screen
    }

    /// `resume`: carry on from the morning after the saved day instead of starting a new game.
    func start(resume: Bool = false) {
        task?.cancel()
        dayPick?.resume(returning: .end)
        dayPick = nil
        releasePrompt()
        answerWait = nil
        answerAuto = nil
        kindPick?.resume(returning: .moonbeam)
        kindPick = nil
        nextPick?.resume(returning: false)
        nextPick = nil
        upgradePick?.resume(returning: nil)
        upgradePick = nil
        vehiclePick?.resume(returning: nil)
        vehiclePick = nil
        pokerDone?.resume()
        pokerDone = nil
        poker?.shutDown()
        poker = nil
        pokerPlaying = false
        pokerShown = false
        pokerScreen = ""
        zamboniShown = false
        zamboniRider = nil
        zamboniParkedX = Stage.zamboniStartX
        fleet = []
        flatbedShown = false
        scuffle = nil
        recruits = []
        parkLightsOut = false
        funlandClosed = false
        parkHaul = [:]
        flatbedEmpty = false
        motorcycleShown = true
        motorcycleRider = nil
        sound.prepare()
        sound.stopAll()
        (deidre, kelly, jen) = Self.makeCast()
        team = [deidre, kelly, jen]
        family = []
        guest = nil
        bradVisits = 0
        extras = Self.makeExtras()
        crew = Self.makeCrew()
        customers = []
        finished = false
        running = true
        place = .house
        buttonShown = false
        buttonPressT0 = .distantPast
        carShown = false
        carHooked = false
        truckShown = false
        tentShown = false
        tentFlying = false
        gangwayOut = false
        gangwayT0 = .distantPast
        chairsStowed = false
        saucerPeople = []
        miniTentFrom = nil
        beamOn = false
        beamT0 = .distantPast
        rescueKidName = ""
        rescues = 0
        board = nil
        tableSeats = []
        tableGroups = []
        humanRow = nil
        you = nil
        myHand = []
        prompt = nil
        passengers = []
        boardedAt = [:]
        nights = 0
        stopsToday = 0
        dayEarned = 0
        dayFees = 0
        strapped = []
        mirrorT0 = .distantFuture
        consolePressT0 = .distantPast
        screen = "READY"
        choosingKind = nil
        card = nil
        clockT0 = .distantPast
        flashT0 = .distantPast
        camFrom = Stage.full
        camTo = Stage.full
        camT0 = .distantPast
        fadeT0 = .distantPast
        venue = nil
        choosingDay = false
        morningStop = nil
        choosingNext = false
        cash = Venue.startCash
        cashPop = nil
        result = nil
        trips = 0
        rotation = 0
        familyVisits = 0
        totalProfit = 0
        totalTransformed = 0
        bank = 0
        vehicles = []
        arriving = nil
        rider = nil
        choosingUpgrade = nil
        choosingVehicle = false
        night = false
        sleeping = []
        savedToday = false
        let save = resume ? SaveGame.load() : nil
        if let save { restore(save) }
        task = Task {
            do { try await story(resume: save) } catch {}
        }
    }

    /// Puts back everything the saved game remembers.
    private func restore(_ save: SaveGame) {
        nights = save.nights
        trips = save.trips
        rotation = save.rotation
        team = (0..<3).map { cast[(rotation + $0) % 3] }
        familyVisits = save.familyVisits
        rescues = save.rescues
        cash = save.cash
        bank = save.bank
        totalProfit = save.totalProfit
        totalTransformed = save.totalTransformed
        vehicles = Set(save.vehicles.compactMap(Vehicle.init(rawValue:)))
        upgrades = Set((save.upgrades ?? []).compactMap(ShipUpgrade.init(rawValue:)))
        if let kinds = save.recruitKinds, kinds.count == 3 {
            recruits = [extras[4], extras[5], extras[6]]
            for (p, raw) in zip(recruits, kinds) {
                p.clown = raw.flatMap(ClownKind.init(rawValue:))
                p.changeT0 = p.clown == nil ? .distantFuture : .distantPast
            }
        }
    }

    /// Saves the game as it stands at the end of a day.
    func saveGame() {
        guard choosingNext else { return }
        let save = SaveGame(nights: nights, trips: trips, rotation: rotation, familyVisits: familyVisits, rescues: rescues,
                            cash: cash, bank: bank, totalProfit: totalProfit, totalTransformed: totalTransformed,
                            vehicles: vehicles.map(\.rawValue).sorted(),
                            upgrades: upgrades.map(\.rawValue).sorted(),
                            recruitKinds: recruits.count == 3 ? recruits.map { $0.clown?.rawValue } : nil)
        save.write()
        saved = save
        savedToday = true
    }

    func choose(_ plan: DayPlan) {
        dayPick?.resume(returning: plan)
        dayPick = nil
        choosingDay = false
    }

    /// Your answer to the card table's current question.
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

    /// Waits for you at the card table, unless auto-play is on.
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

    /// The bridge a card game uses to ask you, lay cards on the table and update the scoreboard.
    private func tableHost(human: Int?) -> TableHost {
        TableHost(human: human,
                  ask: { [unowned self] p, auto in try await ask(p, auto: auto) },
                  show: { [unowned self] groups in tableGroups = groups },
                  hand: { [unowned self] cards in if human != nil { myHand = cards } },
                  notes: { [unowned self] notes in
                      guard var b = board else { return }
                      for (i, n) in notes.enumerated() where b.rows.indices.contains(i) { b.rows[i].note = n }
                      board = b
                  },
                  caption: { [unowned self] text in caption = text },
                  pause: { [unowned self] seconds in try await sleep(seconds) })
    }

    /// The gangway's two ends — up at the ship's deck rail and down on the ground — and how far out it is (0…1).
    func gangway(at now: Date) -> (top: CGPoint, foot: CGPoint, out: Double)? {
        guard let ship = tent(at: now) else { return nil }
        let t = min(max(now.timeIntervalSince(gangwayT0) / Self.gangwayDur, 0), 1)
        let u = gangwayOut ? t : 1 - t
        guard u > 0 else { return nil }
        return (CGPoint(x: ship.x + Stage.gangwayTopDX, y: ship.y - 34), CGPoint(x: ship.x + Stage.gangwayFootDX, y: Stage.floorY), u * u * (3 - 2 * u))
    }

    private static let gangwayDur = 1.3

    /// The pink beam's two ends, the same as the gangway's, and how strong it is (0…1).
    func shipBeam(at now: Date) -> (top: CGPoint, foot: CGPoint, strength: Double)? {
        guard let ship = tent(at: now) else { return nil }
        let t = min(max(now.timeIntervalSince(beamT0) / 0.6, 0), 1)
        let u = beamOn ? t : 1 - t
        guard u > 0 else { return nil }
        return (CGPoint(x: ship.x + Stage.gangwayTopDX, y: ship.y - 34), CGPoint(x: ship.x + Stage.gangwayFootDX, y: Stage.floorY), u)
    }

    func choose(_ kind: ClownKind) {
        kindPick?.resume(returning: kind)
        kindPick = nil
        choosingKind = nil
    }

    func chooseNext(again: Bool) {
        nextPick?.resume(returning: again)
        nextPick = nil
        choosingNext = false
    }

    /// `nil` means she is done shopping.
    func choose(_ upgrade: ShipUpgrade?) {
        upgradePick?.resume(returning: upgrade)
        upgradePick = nil
    }

    /// Called by the machine when Jen's sitting ends: game 10 hands the story back.
    private func finishPoker() {
        pokerPlaying = false
        pokerDone?.resume()
        pokerDone = nil
    }

    /// `nil` means not today.
    func choose(_ vehicle: Vehicle?) {
        vehiclePick?.resume(returning: vehicle)
        vehiclePick = nil
        choosingVehicle = false
    }

    /// 0…1 black-out used when the scene changes.
    func fade(at now: Date) -> Double {
        let t = now.timeIntervalSince(fadeT0)
        guard t >= 0 && t < 1.2 else { return 0 }
        return t < 0.5 ? t / 0.5 : max(0, 1 - (t - 0.7) / 0.5)
    }

    /// How far the mirror has come down, 0 (up in the rigging) … 1 (in front of the chairs).
    func mirror(at now: Date) -> Double {
        let down = min(max(now.timeIntervalSince(mirrorT0) / 1.2, 0), 1)
        let up = min(max(now.timeIntervalSince(mirrorUpT0) / 1.0, 0), 1)
        let u = mirrorUpT0 > mirrorT0 ? down * (1 - up) : down
        return u * u * (3 - 2 * u)
    }

    // MARK: Story

    private func story(resume: SaveGame? = nil) async throws {
        let (deidre, kelly, jen) = (deidre, kelly, jen)
        let (repoMan, brad, amber, boss) = (extras[0], extras[1], extras[2], extras[3])

        if let resume {
            // Continuing a saved game: the next morning at home, gathered round the pink button.
            place = .house
            pokerShown = true
            pokerAppearT0 = .distantPast
            buttonShown = true
            wakeUp()
            for (p, x) in zip(cast, Stage.buttonSpots) { (p.x0, p.x1, p.moveDur) = (x, x, 0) }
            (deidre.facing, kelly.facing, jen.facing) = (1, -1, -1)
            fadeT0 = .now
            cutNow(Stage.shot(centerX: 520, height: 250))
            caption = "Welcome back! The morning after day \(resume.nights)."
            try await sleep(1.6)
            try await say(deidre, "Good morning, girls! Ready for another day on the cruise ship?", 2.8)
            try await dayLoop(first: false, skipFirstDay: true)
            return
        }

        try await zamboniWalkOff(boss: boss)
        try await worstDayEver(repoMan: repoMan, brad: brad, amber: amber)
        try await pokerMorning()
        try await shipAlongside()

        // Aboard the ship
        try await sceneChange {
            self.place = .bigTop
            self.tentShown = false
            self.tentFlying = false
            self.seat(self.cast, chairs: [0, 1, 2])
            for (p, x) in zip(self.crew, Self.wingsX) {
                (p.x0, p.x1, p.moveDur) = (x, x, 0)
                p.place(height: 0)
            }
            self.show(self.cast)
            self.cutNow(Stage.chairsView)
        }
        caption = "…and the clowns take them to their setup on board, still docked at the house."
        try await sleep(2.2)
        try await strap(cast)
        caption = "They are strapped into chairs…"
        try await say(kelly, "Ooh, seat belts! This must be some ride!", 2.4)
        try await say(jen, "A circus on a cruise ship! How cool is this?", 2.6)

        caption = "…and are surrounded by the alien clowns!"
        try await look(at: Stage.full)
        for p in crew { p.visible = true }
        sound.honk()
        try await walkAll(zip(crew, Stage.crewX).map { ($0, $1) }, speed: 120)
        for p in crew { p.facing = 0 }
        try await look(at: Stage.chairsView)
        try await say(kelly, "Hi, everybody! Love the outfits!", 2.2)
        try await say(deidre, "Well, hello! Whatever you have in mind, I'm ready for a fresh start.", 3)
        try await say(deidre, "Yesterday I walked out on my job, lost my car, and lost my boyfriend!", 3.2)
        try await say(deidre, "So things can only go up from here!", 2.4)
        try await look(at: Stage.full)
        try await walk(leader, to: Stage.consoleX - 45, speed: 100)
        leader.facing = -1
        try await say(leader, "We know. We are here to help you with that.", 3)
        try await say(jen, "See, Mommy? Your luck is already changing!", 2.6)

        caption = "The alien clown goes to press a glowing pink button…"
        try await say(leader, "Just relax and enjoy it.", 2)
        try await say(deidre, "Here we go, girls!", 1.8)
        try await runMachine([(deidre, .moonbeam), (kelly, .dotty), (jen, .cottonCandy)], presser: leader, change: Machine.change,
                             tingleLine: (kelly, "Ooh, this tickles! I love it!"), legsStartLine: (jen, "My legs are changing — how fun!"),
                             bodyLine: (kelly, "Look at our sparkly new suits!"),
                             faceShouts: (deidre, [("Here come our faces…", 15), ("They're growing…", 15),
                                                   ("…and growing…", 16), ("…and growing!", 17), ("Wheeeeeeeeee!", 18)]),
                             beamOnShout: 4, faceSpeakers: [[deidre], [kelly], [jen], [deidre], [deidre, kelly, jen]])
        try await look(at: Stage.chairsView)
        caption = "The transformation takes five minutes. Now they're alien clowns from their feet to their faces!"
        try await sleep(1.8)

        try await look(at: Stage.full)
        try await say(leader, "The transformation is complete. Have a look!", 2.8)
        caption = "The alien clowns lower a big mirror in front of the chairs…"
        try await showMirror(cast, caption: "…and Deidre and the girls see themselves for the first time!", calm: cast)
        for p in cast { p.mood = .beaming }
        try await look(at: Stage.chairsView)
        shout(cast, "Wow!", 1.8)
        try await sleep(2)
        try await say(deidre, "Would you look at us? We're alien clowns!", 2.6)
        try await say(kelly, "I've never looked so cheerful in my life!", 2.4)
        try await say(jen, "Game 10 is the best prize ever!", 2.2)
        for p in cast { p.mood = .happy }

        try await look(at: Stage.full)
        try await say(leader, "We said we are here to help you.", 2.6)
        try await say(leader, "Here is the deal: our cruise ship has pre-selected ports.", 3.2)
        caption = "The alien clowns explain the deal…"
        card = .deal
        cardUntil = .now + 18
        try await sleep(18.2)
        try await say(leader, "The only catch is you have to pay the docking fee at every port.", 3)
        try await say(leader, "Two of you go down the gangway and invite passers-by on a cruise. One of you stays aboard to work the machine.", 4)
        try await say(leader, "Everyone who comes aboard gets transformed. At the end of the day, we drop them all off where they came from.", 4)
        try await say(deidre, "I have $\(Venue.startCash) left from my last paycheck. Girls, we're in business!", 3)
        try await say(kelly, "Way better than driving a zamboni, Mom!", 2.2)
        try await say(deidre, "A new job already — this is turning into a great day!", 2.8)
        try await snap(cast)
        unstrap(cast)
        try await homeInvites()
        try await dayLoop(first: true, skipFirstDay: false)
    }

    /// Day after day aboard the cruise ship until the player ends the game. Once each day is complete the player can
    /// do it again, save the game, start over, or end it. `skipFirstDay` starts at that prompt (a continued game).
    private func dayLoop(first startFirst: Bool, skipFirstDay: Bool) async throws {
        let deidre = deidre
        var first = startFirst
        var skip = skipFirstDay
        // Set when the morning's setup already played the whole cruise (Brad's business-trip days): go straight to evening.
        var sailed = false
        while true {
            if !skip {
                if !sailed {
                    try await cruiseDay(keepAboard: first)
                    try await comeHome(first: first)
                }
                // After the first trip, Deidre's old coworkers at Funland get game 10 on a phone.
                if first { try await funlandRecruits() }
                try await restUntilMorning()
                // …and the morning after the first night, they hear Funland is out of business.
                if first { try await funlandNews() }
                // After every odd night an aunt and cousin come over.
                if nights % 2 == 1 && cash >= Venue.cheapestFee { try await morningVisit() }
                if cash < Venue.cheapestFee {
                    try await say(deidre, "We only have $\(cash) on hand — not enough for another setup fee.", 2.8)
                    // The Clowns of Poker downloads itself onto a kid's computer to save the day.
                    try await kidRescue()
                }
                first = false
            }
            skip = false
            savedToday = false
            let again = await withCheckedContinuation { cont in
                nextPick = cont
                choosingNext = true
                // Every night ends with the game saved, so it can always be continued from the next day.
                saveGame()
                caption = "Day \(nights) is complete, and your progress is saved! Continue from day \(nights + 1), start over, or end the game?"
            }
            try Task.checkCancellation()
            guard again else { break }
            sailed = try await doItAgain()
        }

        caption = "Game over! \(trips) \(trips == 1 ? "port" : "ports") visited aboard the cruise ship, \(totalTransformed) passengers transformed, "
            + "\(totalProfit >= 0 ? "$\(totalProfit) profit" : "$\(-totalProfit) lost"). Cash on hand: $\(cash), savings in the bank: $\(bank)."
            + (vehicles.isEmpty ? "" : " In the driveway: \(ListFormatter.localizedString(byJoining: Vehicle.allCases.filter(vehicles.contains).map { "a \($0.name.lowercased())" })), bought and paid for.")
        try await say(deidre, vehicles.contains(.car) ? "A new job, and a car nobody can repossess. Best thing that ever happened to us!"
                                                      : "Best thing that ever happened to us!", 3)
        finished = true
        running = false
    }

    /// The opening: at Funland the mean boss keeps Deidre on the maintenance zamboni. After an hour of going through the
    /// motions she stops the zamboni halfway across the lot, climbs off, and walks off the job for good.
    private func zamboniWalkOff(boss: Person) async throws {
        let deidre = deidre
        place = .park
        show([deidre, boss])
        zamboniShown = true
        zamboniRider = nil
        zamboniParkedX = Stage.zamboniStartX
        (deidre.x0, deidre.x1, deidre.moveDur, deidre.facing) = (Stage.parkOfficeX + 70, Stage.parkOfficeX + 70, 0, -1)
        (boss.x0, boss.x1, boss.moveDur, boss.facing) = (Stage.parkOfficeX, Stage.parkOfficeX, 0, 1)
        deidre.mood = .glum
        cutNow(Stage.full)
        caption = "Deidre works at Funland Amusement Park, down by the boardwalk."
        try await sleep(2.6)

        try await look(at: Stage.shot(centerX: Stage.parkOfficeX + 35, height: 300))
        try await say(boss, "Deidre! You're on the maintenance zamboni again today.", 2.8)
        try await say(deidre, "Again, Mr. Grimsby? That's every single day this month.", 2.8)
        try await say(boss, "Did I ask for your opinion? Scrub the whole lot, and do it right this time.", 3)
        try await say(boss, "And don't you dare put a scratch on it. That machine is worth more than you are.", 3.2)
        try await say(deidre, "Yes, Mr. Grimsby.", 1.8)
        caption = "Mr. Grimsby goes back into his office and slams the door."
        boss.visible = false
        sound.clunk()
        try await sleep(1.8)
        caption = "Her boss is so mean to her that Deidre has stopped feeling much of anything. She just goes through the motions."
        try await sleep(3.4)

        // Onto the zamboni, and round and round the lot for an hour.
        try await look(at: Stage.full)
        try await walk(deidre, to: Stage.zamboniStartX, speed: 70)
        deidre.facing = 1
        deidre.seated = true
        zamboniRider = deidre
        sound.hum(true)
        caption = "Back and forth across the parking lot she goes, a million miles away…"
        let first = beginWalk(deidre, to: 470, speed: 40)
        mention(deidre, "Scrub… turn… scrub… turn…", 2.4)
        try await sleep(first + 0.2)
        try await sceneChange {
            (deidre.x0, deidre.x1, deidre.moveDur, deidre.facing) = (Stage.zamboniStartX, Stage.zamboniStartX, 0, 1)
        }
        caption = "One hour later… still scrubbing the same lot."
        let lap = beginWalk(deidre, to: 470, speed: 40)
        mention(deidre, "Five years of this, and never once a thank-you.", 2.6)
        try await sleep(lap + 0.2)

        // Halfway across the lot, she's had enough.
        caption = "Halfway across the lot, Deidre suddenly stops the zamboni."
        let half = beginWalk(deidre, to: Stage.zamboniEndX, speed: 40)
        try await sleep(half * 0.6)
        stop(deidre)
        sound.hum(false)
        sound.clunk()
        try await look(at: Stage.shot(centerX: deidre.x(at: .now) + 30, height: 300))
        try await sleep(1.2)
        try await say(deidre, "What am I doing? Five years of scrubbing the same lot for a man who never says thank you.", 3.6)
        deidre.mood = .shocked
        try await say(deidre, "No more. I'm done!", 2)
        // She climbs down and leaves the zamboni right where it stopped.
        let parkedAt = deidre.x(at: .now)
        zamboniParkedX = parkedAt
        zamboniRider = nil
        deidre.seated = false
        (deidre.x0, deidre.x1, deidre.moveDur) = (parkedAt - 95, parkedAt - 95, 0)
        deidre.facing = -1
        deidre.mood = .happy
        caption = "Deidre climbs off the zamboni and leaves it sitting in the middle of the lot."
        try await sleep(1.8)

        // Grimsby spots her from his office.
        try await look(at: Stage.full)
        (boss.x0, boss.x1, boss.moveDur, boss.facing) = (Stage.parkOfficeX, Stage.parkOfficeX, 0, 1)
        boss.mood = .shocked
        boss.visible = true
        sound.clunk()
        try await say(boss, "DEIDRE! Why is that zamboni just sitting there?!", 2.6)
        _ = beginWalk(deidre, to: Stage.parkOfficeX + 110, speed: 100)
        try await walk(boss, to: Stage.parkOfficeX + 40, speed: 120)
        try await sleep(max(0, deidre.x(at: .now) - (Stage.parkOfficeX + 110)) / 100 + 0.2)
        boss.facing = 1
        deidre.facing = -1
        try await look(at: Stage.shot(centerX: Stage.parkOfficeX + 75, height: 300))
        try await say(boss, "Get back on that zamboni and finish the lot!", 2.6)
        try await say(deidre, "Well you are always giving me the short end of the stick.", 3)
        try await say(boss, "Get back to work, or you'll be scrubbing double shifts all summer!", 3)
        deidre.mood = .glum
        try await say(deidre, "No, Mr. Grimsby. Scrub your own lot. I'm walking off this job, and I'm not coming back!", 3.6)
        try await say(boss, "You can't just walk off the job!", 2.4)
        try await say(deidre, "Watch me.", 1.8)
        caption = "Deidre abandons her job right in the middle of her shift."
        deidre.carrying = true
        try await say(deidre, "Five years at Funland… and it all fits in one box.", 2.8)
        try await look(at: Stage.full)
        _ = beginWalk(deidre, to: -60, speed: 100)
        try await sleep(1.4)
        mention(boss, "DEIDRE! Get back here!", 2.2)
        try await sleep(2.6)
        mention(boss, "Who's going to finish the lot?!", 2.2)
        try await walk(deidre, to: -60, speed: 100)
        boss.mood = .happy
        zamboniShown = false
    }

    /// Laid off, repossessed and dumped, all before bedtime.
    private func worstDayEver(repoMan: Person, brad: Person, amber: Person) async throws {
        let (deidre, kelly, jen) = (deidre, kelly, jen)
        try await sceneChange {
            self.place = .house
            self.show([kelly, jen, brad, repoMan, deidre])
            self.carShown = true
            self.truckShown = true
            self.truckFrom = Stage.truckX
            self.truckTo = Stage.truckX
            self.truckDur = 0
            for p in [kelly, jen, brad, repoMan] { p.facing = -1 }
            (deidre.x0, deidre.x1, deidre.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.yardView)
        }
        caption = "Deidre walks home along the shore with her box. She has just walked off her job at Funland."
        try await walk(deidre, to: 120, speed: 60)
        caption = "When she arrives home, she sees a tow truck about to repo her car."
        deidre.mood = .shocked
        try await walk(deidre, to: 385, speed: 150)
        deidre.facing = -1
        repoMan.facing = 1
        try await say(deidre, "What do you think you're doing?", 2.6)
        try await say(repoMan, "I have an order to repossess.", 2.6)
        try await say(deidre, "Why?", 1.6)
        try await say(repoMan, "You didn't pay the payments.", 2.6)
        try await say(deidre, "Anything I can do?", 2.2)
        try await say(repoMan, "There's nothing you can do.", 2.6)

        caption = "Her car is taken away."
        try await walk(repoMan, to: Stage.truckX - 20, speed: 140)
        repoMan.visible = false
        carHooked = true
        sound.clunk()
        try await sleep(0.8)
        sound.hum(true)
        truckTo = -420
        truckT0 = .now
        truckDur = 3.4
        try await sleep(3.5)
        sound.hum(false)
        truckShown = false
        carShown = false
        try await say(deidre, "First my job, and now my car…", 2.4)
        deidre.mood = .happy

        caption = "When she enters the house she sees her two daughters, Kelly and Jen — and her boyfriend."
        deidre.carrying = false
        try await look(at: Stage.shot(centerX: 520, height: 300))
        try await walk(deidre, to: Stage.livingX[0], speed: 110)
        deidre.facing = 1
        try await say(brad, "Deidre, you hardly spend any time with me.", 2.8)
        try await say(brad, "You left me hanging at the 4th of July picnic until 4 in the morning…", 3.4)
        try await say(brad, "…and you are not returning my phone calls.", 2.8)
        try await say(deidre, "I have had my hands full.", 2.4)
        try await say(brad, "I like you, but I want to be with someone with more availability. Goodbye!", 3.4)
        deidre.mood = .shocked

        caption = "The boyfriend leaves…"
        try await look(at: Stage.yardView)
        amber.visible = true
        _ = beginWalk(amber, to: 270, speed: 120)
        try await walk(brad, to: 320, speed: 120)
        brad.facing = -1
        try await say(amber, "There you are, Brad!", 1.8)
        caption = "…and starts walking with his new girlfriend."
        _ = beginWalk(deidre, to: 445, speed: 90)
        try await walkAll([(brad, -90), (amber, -140)], speed: 80)
        brad.visible = false
        amber.visible = false
        deidre.facing = -1
        try await say(deidre, "So he dumps me for her.", 2.8)
        deidre.mood = .happy

        try await look(at: Stage.full)
        try await walk(deidre, to: Stage.livingX[0] + 30, speed: 90)
        deidre.facing = 1
        try await say(kelly, "Oh, Mom. What a rotten day.", 2.4)
        try await say(jen, "Let's all get some rest, Mommy. Things will be better in the morning.", 3)
        caption = "After this bad day, Deidre and her girls decide to get some rest and think it over in the morning."
        try await goToBed()

        // While they sleep, something turns up in the spare room.
        caption = "During the night, something appears in the spare room…"
        try await look(at: Stage.shot(centerX: Stage.pokerX - 30, height: 300))
        pokerShown = true
        pokerAppearT0 = .now
        sound.shimmer()
        try await sleep(3.6)
        try await sceneChange { self.wakeUp() }
        caption = "The next morning…"
        sound.chime()
        try await sleep(2)
    }

    /// The next morning Mom goes grocery shopping. While she's out, Jen (the youngest) finds the Clowns of Poker machine
    /// in the spare room and plays it — and once she makes it to game 10, the machine waits for Mom to get home.
    private func pokerMorning() async throws {
        let (deidre, kelly, jen) = (deidre, kelly, jen)
        try await say(deidre, "Good morning, girls. We're out of just about everything — I'm going to the grocery store.", 3.2)
        try await say(kelly, "Okay, Mom. We'll be fine.", 1.8)
        try await say(jen, "Bye, Mommy!", 1.4)
        caption = "Deidre heads out to the grocery store."
        try await walk(deidre, to: -60, speed: 170)
        deidre.visible = false

        caption = "Meanwhile, Jen wanders into the spare room…"
        try await walk(jen, to: Stage.pokerPlayerX, speed: 120)
        jen.facing = 1
        try await look(at: Stage.shot(centerX: Stage.pokerX - 50, height: 280))
        jen.mood = .shocked
        try await say(jen, "Kelly! KELLY! Come look!", 2)
        try await walk(kelly, to: Stage.pokerPlayerX - 42, speed: 150)
        kelly.facing = 1
        kelly.mood = .shocked
        try await say(kelly, "A poker machine? That wasn't there last night!", 2.6)
        jen.mood = .happy
        kelly.mood = .happy
        try await say(jen, "\"The Clowns of Poker\"! Can I play it? Please?", 2.6)
        try await say(kelly, "Go ahead. I'll watch.", 1.8)

        caption = "Jen plays the Clowns of Poker. Play the max bet all the way through to make it to game 10!"
        let session = PokerSession(player: jen.id, muted: muted)
        session.onSound = { [weak self] s in
            switch s {
            case .card: self?.sound.shutter()
            case .coin: self?.sound.pay()
            case .chime: self?.sound.chime()
            }
        }
        // Running out or missing the max bet just shows Insert Credits on the machine; game 10 hands the story back.
        session.onEnd = { [weak self, weak session] ending in
            guard ending == .qualified else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(7))
                guard let self, let session, self.poker === session else { return }
                self.finishPoker()
            }
        }
        poker = session
        pokerPlaying = true
        session.begin()
        await withCheckedContinuation { cont in pokerDone = cont }
        try Task.checkCancellation()

        pokerScreen = "GAME 10\nWAITING\nFOR MOM"
        try await look(at: Stage.shot(centerX: Stage.pokerX - 50, height: 280))
        jen.mood = .beaming
        try await say(jen, "I made it to game 10!", 2)
        jen.mood = .happy
        // Whatever credits are left on the machine are paid out to the house, a dollar a credit.
        let leftover = max(session.credits, 0)
        if leftover > 0 {
            cash += leftover
            cashPop = ("+$\(leftover)", .now, Stage.pokerX - 50)
            sound.pay()
            caption = "The machine pays out the \(leftover) credits left on it — $\(leftover) for the house!"
            try await say(kelly, "Whoa! It's paying out real money — $\(leftover)!", 2.6)
            try await say(jen, "That's for Mommy!", 1.8)
        }
        try await say(kelly, "It says it's waiting for Mom to get home.", 2.4)
        try await say(jen, "Mommy! Hurry up!", 1.8)

        // At the store, Deidre has no idea.
        try await sceneChange {
            self.place = .town
            self.show([deidre])
            (deidre.x0, deidre.x1, deidre.moveDur, deidre.facing) = (-40, -40, 0, 0)
            deidre.mood = .happy
            self.cutNow(Stage.full)
        }
        caption = "At the grocery store, Deidre has no idea what's going on at home."
        try await walk(deidre, to: Stage.storeDoorX, speed: 140)
        deidre.visible = false
        caption = "She picks up a few things with what's left of her last paycheck."
        try await sleep(2)
        deidre.carrying = true
        deidre.groceries = true
        deidre.visible = true
        try await say(deidre, "Milk, eggs, bread… and a little treat for the girls.", 2.6)
        try await walk(deidre, to: Stage.W + 60, speed: 150)

        // Home again — the girls can't wait to tell her.
        try await sceneChange {
            self.place = .house
            self.show(self.cast)
            (deidre.x0, deidre.x1, deidre.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
        }
        caption = "Deidre comes home with the groceries."
        try await walk(deidre, to: 470, speed: 150)
        deidre.carrying = false
        deidre.groceries = false
        deidre.facing = 1
        try await say(deidre, "Girls, I'm home!", 1.8)
        try await walkAll([(jen, 520), (kelly, 565)], speed: 210)
        jen.facing = -1
        kelly.facing = -1
        try await look(at: Stage.shot(centerX: 515, height: 250))
        try await say(jen, "Mommy! Mommy! A poker machine showed up in the spare room, and I made it to game 10!", 3.4)
        deidre.mood = .shocked
        try await say(deidre, "A poker machine? In our spare room?", 2.2)
        try await say(kelly, "And it says it's been waiting for you to get home!", 2.6)
        deidre.mood = .happy
        try await say(deidre, "Well, this I have to see.", 2)

        try await look(at: Stage.full)
        try await walkAll([(deidre, Stage.pokerPlayerX - 90), (kelly, Stage.pokerPlayerX - 45), (jen, Stage.pokerPlayerX)], speed: 150)
        for p in cast { p.facing = 1 }
        try await look(at: Stage.shot(centerX: Stage.pokerX - 70, height: 280))
        pokerScreen = "GAME 10\nLOOK\nOUTSIDE!"
        let welcome = "Welcome home, Deidre! Game 10 is a prize for the whole family. Go and look outside!"
        poker?.say(welcome)
        caption = "The machine: “\(welcome)”"
        try await sleep(5)
    }

    /// Game 10: the alien clowns' cruise ship pulls up on the water alongside the house and takes the family aboard.
    private func shipAlongside() async throws {
        let (deidre, kelly, jen) = (deidre, kelly, jen)
        let visitors = [leader, crew[0], crew[1]]
        caption = "A ship's horn sounds, right outside the house…"
        sound.honk()
        try await look(at: Stage.full)
        tentShown = true
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 0)
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.dockY), over: 5)
        sound.hum(true)
        try await walkAll([(deidre, 452), (kelly, 494), (jen, 536)], speed: 170)
        for p in cast {
            p.facing = -1
            p.mood = .shocked
        }
        try await sleep(1.2)
        caption = "A cruise ship pulls up alongside their house!"
        try await look(at: Stage.shot(centerX: 330, height: 360))
        try await say(jen, "A CRUISE SHIP! Right outside our house!", 2.4)
        try await say(kelly, "On the water, right by our yard!", 2)

        caption = "A gangway slides out, and some weird-looking alien clowns come down it!"
        try await look(at: Stage.yardView)
        try await extendGangway()
        try await leaveShip(visitors, to: [372, 336, 300])
        sound.honk()
        try await say(leader, "HONK HONK! Congratulations, Jen — you made it to game 10!", 2.8)
        try await look(at: Stage.shot(centerX: 420, height: 300))
        try await say(kelly, "Are those… CLOWNS?", 2.2)
        try await say(leader, "Game 10 is a cruise for the whole family. All aboard!", 2.8)
        for p in cast { p.mood = .happy }
        try await say(deidre, "After yesterday? Girls, I think we could use a cruise!", 2.8)

        caption = "The family walks up the gangway onto the ship!"
        try await look(at: Stage.yardView)
        shout(cast, "All aboard!", 2)
        try await boardShip([jen, kelly, deidre] + visitors)
        try await retractGangway()
        pokerScreen = ""
        // The ship stays tied up right beside the house for their first transformation.
        sound.hum(false)
        caption = "The cruise ship stays docked right beside the house…"
        try await sleep(2.2)
    }

    private func reaction(_ kind: ClownKind) -> String {
        switch kind {
        case .moonbeam: "Moonbeam! I'm over the moon!"
        case .starburst: "Starburst! Look at this green fin!"
        case .lollipop: "Lollipop! Red hearts on my cheeks!"
        case .bigTop: "Big Top! I'm the whole circus!"
        case .dotty: "Dotty! I've gone completely dotty!"
        case .ragtime: "Ragtime! These spikes are wild!"
        case .cottonCandy: "Cotton Candy! Blue hearts on my cheeks!"
        case .jester: "Jester! Purple suits me!"
        case .bluebell: "Bluebell! A blue nose and pink cheeks!"
        case .shamrock: "Shamrock! A green nose and blue cheeks!"
        case .confetti: "Confetti! A full head of rainbow hair!"
        case .pinwheel: "Pinwheel! Pink, teal and purple curls!"
        case .bozo: "Bozo! Look at these big red wings of hair!"
        case .redBozo: "Red Bozo! Orange wings and a red suit!"
        }
    }

    // MARK: The machine

    /// Presses the glowing pink button: a tingle, then the change climbs from the feet to the face.
    /// Mini saucers, the Roswell Transformation Casino way: one flies out and hovers just over each head, hums and glows,
    /// beams them feet-first into alien clowns (a close-up of each), sparkles, cools with a puff of mist, then flies home.
    /// The caller sets the caption for the flight out. A long `flight` (off the ship into a house) is watched from far back.
    /// `chargeLines` are said while the saucers hum; `lines`, when given, are the lone rider's own lines under the beam.
    private func miniSaucers(_ riders: [(Person, ClownKind)], flight: Double = SaucerRun.lower, home: String,
                             chargeLines: [(Person, String)] = [], lines: [String]? = nil) async throws {
        let group = riders.map(\.0)
        let one = group.count == 1
        let names = one ? group[0].id : "They"
        let t0 = Date.now
        saucerFlight = flight
        saucerPeople = group
        saucerT0 = t0
        for (p, kind) in riders {
            p.clown = kind
            p.tingleT0 = t0 + flight
            p.changeT0 = t0 + flight + SaucerRun.charge * 0.5
            p.changeDur = SaucerRun.charge * 0.5 + SaucerRun.beam
            p.fade(to: 1, over: 0)
            p.shineT0 = .distantPast
            p.facing = 0
        }
        sound.hum(true)
        if flight > SaucerRun.lower { cut(to: Stage.full) }
        try await sleep(flight)
        sound.hum(false)

        // Close in on the saucers: tall enough for the tallest, wide enough for everyone.
        let top = group.map { Pose($0, feet: CGPoint(x: $0.x(at: .now), y: Stage.floorY), facing: 0, now: .now) }
            .map { $0.headTop - $0.hr * 3.2 }.min()!
        let xs = group.map { $0.x(at: .now) }
        let span = xs.max()! - xs.min()! + 140
        let groupShot = Stage.focus(CGPoint(x: (xs.min()! + xs.max()!) / 2, y: (top + Stage.floorY + 20) / 2),
                                    height: max(240, Stage.floorY + 20 - top, span * Stage.H / Stage.W))
        cut(to: groupShot)
        caption = one ? "The saucer hums and starts to glow…" : "The saucers hum and start to glow…"
        sound.beam(true)
        blurt(group, ["Ooh, it's humming!", "Here it comes!", "I'm so nervous!", "It's glowing!", "Ooh, it tingles in here!"], for: SaucerRun.charge)
        for (p, line) in chargeLines { mention(p, line, SaucerRun.charge - 0.2) }
        try await sleep(SaucerRun.charge)

        // A close-up of each of them as the beam changes her — the first few, then everyone else on deck.
        sound.zap(true)
        screen = "BEAMING"
        let shown = Array(riders.prefix(3))
        let rest = Array(group.dropFirst(shown.count))
        let slice = SaucerRun.beam / Double(shown.count + (rest.isEmpty ? 0 : 1))
        var used: Set<String> = []
        for (p, kind) in shown {
            cut(to: saucerCloseUp(p))
            caption = "ZZZAP! \(p.id) is turning into a \(kind.name) alien clown — feet first, all the way up to the face!"
            try await clownReact(p, for: slice, used: &used, lines: one ? lines : nil)
        }
        if !rest.isEmpty {
            cut(to: groupShot)
            caption = "…and the same thing is happening to everyone else under a saucer!"
            blurt(rest, ["My shoes are HUGE!", "I'm getting a clown suit!", "My face is turning white!", "Look at my hair!", "Honk honk!"], for: slice)
            try await sleep(slice)
        }
        cut(to: groupShot)
        sound.zap(false)
        sound.beam(false)
        sound.shimmer()
        caption = "Twinkle! Sparkles set the change in."
        blurt(group, ["It tickles!", "Sparkly!", "Hee hee hee!", "Ooh, twinkles!", "Wheee!"], for: SaucerRun.sparkle)
        try await sleep(SaucerRun.sparkle)
        caption = "Pssshh… the \(one ? "saucer cools" : "saucers cool") down with a puff of mist."
        try await sleep(SaucerRun.cool)

        for p in group {
            p.mood = .happy
            p.shineT0 = .now
        }
        sound.hum(true)
        caption = one ? "The mini saucer zips back into \(home)…" : "The mini saucers zip back into \(home)…"
        if flight > SaucerRun.lower { cut(to: Stage.full) }
        try await sleep(flight)
        sound.hum(false)
        saucerPeople = []
        screen = "COMPLETE"
        sound.honk()
        caption = "Ding! \(names) \(one ? "is an alien clown" : "are all alien clowns")!"
        try await sleep(1.2)
        screen = "READY"
    }

    /// A few lines for everyone at once, without waiting.
    private func blurt(_ group: [Person], _ lines: [String], for seconds: Double) {
        for (p, line) in zip(group, lines.shuffled()) { mention(p, line, seconds - 0.2) }
    }

    /// Her whole figure and the saucer above it, so the change can be watched climbing from her feet to her face.
    private func saucerCloseUp(_ p: Person) -> CGRect {
        let x = p.x(at: .now)
        let pose = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: p.facing, now: .now)
        let top = pose.headTop - pose.hr * 3.4
        let bottom = Stage.floorY + 16
        return Stage.focus(CGPoint(x: x, y: (top + bottom) / 2), height: max(200, bottom - top))
    }

    /// Her close-up under the beam: she reacts to whatever is changing right now — her feet and shoes early on,
    /// then her body and clothes, and finally her face and hair. Fills `seconds`.
    /// Lines in `used` are skipped (and hers are added) so people beside her say different things; `lines` replaces them all.
    private func clownReact(_ p: Person, for seconds: Double, used: inout Set<String>, lines own: [String]? = nil) async throws {
        let n = own?.count ?? (seconds >= 8 ? 3 : seconds >= 4.4 ? 2 : 1)
        let each = seconds / Double(n) - 0.2
        for k in 0..<n {
            if let own {
                p.mood = k == n - 1 ? .beaming : .shocked
                try await say(p, own[k], each)
                continue
            }
            let lv = p.clownLevels(at: .now + each / 2)
            let lines: [String]
            if lv.legs < 1 {
                lines = ["My feet are tingling!", "Whoa — my shoes are getting HUGE!", "Look at my legs!",
                         p.isKid ? "Mommy, look at my big clown shoes!" : "Oh my goodness — clown shoes!"]
            } else if lv.body < 1 {
                lines = ["My clothes are turning into a clown suit!", "I've got a ruffle collar!", "Big puffy gloves!",
                         p.isKid ? "I'm all sparkly and puffy!" : "This suit is so colorful!"]
            } else {
                lines = ["My face is turning white!", "I've got a big red nose!", "Look at my crazy hair!",
                         p.isKid ? "I'm a real alien clown! Yay!" : "Honk honk! This is out of this world!"]
            }
            // Grown-ups are mostly shocked; kids mostly love it.
            p.mood = Double.random(in: 0...1) < (p.isKid ? 0.3 : 0.65) ? .shocked : .happy
            let line = lines.filter { !used.contains($0) }.randomElement() ?? lines.randomElement()!
            used.insert(line)
            try await say(p, line, each)
        }
    }

    private func runMachine(_ riders: [(Person, ClownKind)], presser: Person?, change: Double,
                            tingleLine: (Person, String)? = nil, tingleShout: String? = nil, legsStartLine: (Person, String)? = nil,
                            legsLine: (Person, String)? = nil, bodyLine: (Person, String)? = nil, facesLine: String? = nil,
                            faceShouts: (Person, [(text: String, size: Double)])? = nil, beamOnShout: Int? = nil,
                            faceSpeakers: [[Person]]? = nil) async throws {
        // No presser: a mini saucer is already shining its beam on them.
        if let presser {
            presser.facing = presser.x(at: .now) < Stage.consoleX ? 1 : -1
            presser.reachTo = Stage.pinkButton
            try await sleep(0.7)
            consolePressT0 = .now
            sound.beep()
            try await sleep(0.4)
            presser.reachTo = nil
        }

        let t0 = Date.now + 0.2
        for (p, kind) in riders {
            p.clown = kind
            p.tingleT0 = t0
            p.changeT0 = t0 + Machine.tingle
            p.changeDur = change
            p.fade(to: 1, over: 0)
            p.shineT0 = .distantPast
        }
        let people = riders.map(\.0)
        let xs = people.map { $0.x(at: .now) }
        let cx = (xs.min()! + xs.max()!) / 2
        let h = max(170, (xs.max()! - xs.min()! + 180) / 2)
        let names = people.count == cast.count ? "They" : people.map(\.id).joined(separator: " and ")
        // Shouts spread over the face change, at the font size given for each.
        // From shout number `beamOnShout` on, the shouter breaks into a big open smile.
        // `faceSpeakers[i]`, when given, says line i instead of the faceShouts person.
        var cues: [(at: Date, text: String, size: Double, beam: Bool, by: [Person])] = []
        if let (p, lines) = faceShouts, !lines.isEmpty {
            let start = p.changeT0 + change * 0.44, span = change * 0.54 / Double(lines.count)
            cues = lines.enumerated().map { i, line in
                let by = faceSpeakers.flatMap { i < $0.count ? $0[i] : nil } ?? [p]
                return (start + Double(i) * span, line.text, line.size, beamOnShout.map { i >= $0 } ?? false, by)
            }
        }
        let shouters = faceShouts.map { [$0.0] + (faceSpeakers ?? []).flatMap { $0 } } ?? []
        func wait(_ seconds: Double) async throws {
            let end = Date.now + seconds
            while let cue = cues.first, cue.at < end {
                try await sleep(max(0, cue.at.timeIntervalSinceNow))
                cues.removeFirst()
                for p in cue.by {
                    p.voice = cue.size
                    if cue.beam { p.mood = .beaming }
                    mention(p, cue.text, (cues.first?.at ?? end + 1.5).timeIntervalSinceNow)
                }
                sound.honk()
            }
            try await sleep(max(0, end.timeIntervalSinceNow))
        }
        sound.tingle()
        caption = "\(names) first \(people.count == 1 ? "feels" : "feel") a tingling sensation…"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 100), height: max(h, 230)))
        if let (p, s) = tingleLine { mention(p, s, 2.2) }
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
        caption = "…then the machine starts turning \(people.count == 1 ? names : "them") into \(people.count == 1 ? "an alien clown" : "alien clowns"), starting from the feet!"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 45), height: h))
        if let (p, s) = legsStartLine { mention(p, s, 2.2) }
        if let (p, s) = legsLine {
            try await sleep(change * 0.08)
            mention(p, s, 2.4)
            try await sleep(change * 0.13)
        } else {
            try await sleep(change * 0.21)
        }
        caption = "It works its way up \(people.count == 1 ? "the body" : "their bodies")…"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 105), height: h))
        if let (p, s) = bodyLine { mention(p, s, 2.2) }
        if let facesLine, let first = people.first {
            // Everyone speaks up the instant their faces start to change.
            let faceStart = first.changeT0 + change * 0.42
            try await sleep(max(0, faceStart.timeIntervalSinceNow))
            shout(people, facesLine, 3)
            try await sleep(max(0, (faceStart + change * 0.02).timeIntervalSinceNow))
        } else {
            try await wait(change * 0.23)
        }
        let top = people.map { Pose($0, feet: CGPoint(x: $0.x(at: .now), y: Stage.floorY), facing: 0, now: .now).head.y }.min()!
        caption = "…until it reaches \(people.count == 1 ? "the face" : "their faces")!"
        cut(to: Stage.focus(CGPoint(x: cx, y: top + 12), height: h))
        try await wait(change * 0.2)
        caption = people.count == 1 ? "\(names)'s face slowly morphs into an alien clown head…"
                                    : "Their faces slowly morph into alien clown heads…"
        cut(to: Stage.focus(CGPoint(x: cx, y: top - 6), height: max(150, h * 0.8)))
        try await wait(change * 0.36 + 0.3)
        for p in shouters {
            p.voice = 15
            if p.mood == .beaming { p.mood = .happy }
        }
        sound.zap(false)
        sound.honk()
        screen = "COMPLETE"
        for p in people { p.shineT0 = .now }
        try await sleep(1.2)
        screen = "READY"
    }

    /// Lowers the big mirror in front of the chairs so `people` can see what they've turned into, then raises it.
    /// Anyone in `calm` keeps her own expression instead of looking surprised.
    private func showMirror(_ people: [Person], caption seen: String, seconds: Double = 4, calm: [Person] = []) async throws {
        sound.clunk()
        mirrorT0 = .now
        mirrorUpT0 = .distantPast
        try await sleep(1.6)
        let moods = people.map(\.mood)
        for p in people where !calm.contains(where: { $0 === p }) { p.mood = .shocked }
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
            if let kind = p.clown { album.add(AlbumEntry(date: .now, spec: PersonSpec(p, kind: kind))) }
        }
        try await sleep(1.4)
    }

    // MARK: The cruise ship

    private func moveTent(to point: CGPoint, over seconds: Double) {
        tentFrom = seconds == 0 ? point : tent(at: .now) ?? point
        tentTo = point
        tentT0 = .now
        tentDur = seconds
    }

    /// Runs the gangway out from the deck down to the ground.
    private func extendGangway() async throws {
        guard !gangwayOut else { return }
        gangwayOut = true
        gangwayT0 = .now
        sound.clunk()
        try await sleep(Self.gangwayDur + 0.2)
    }

    /// Pulls the gangway back in.
    private func retractGangway() async throws {
        guard gangwayOut else { return }
        gangwayOut = false
        gangwayT0 = .now
        sound.clunk()
        try await sleep(Self.gangwayDur + 0.1)
    }

    /// The gangway's ends where the ship sits right now (it is drawn from the same point).
    private var gangwayEnds: (top: CGPoint, foot: CGPoint) {
        let ship = tent(at: .now) ?? CGPoint(x: Stage.venueTentX, y: Stage.dockY)
        return (CGPoint(x: ship.x + Stage.gangwayTopDX, y: ship.y - 34), CGPoint(x: ship.x + Stage.gangwayFootDX, y: Stage.floorY))
    }

    /// Walks each person through her legs one after another, the people starting `gap` seconds apart.
    /// A leg with a `rise` climbs (or comes down) the gangway as she goes; `begin` runs as her first leg starts
    /// and `done` once her last leg ends.
    private func parade(_ people: [Person], legs: [(x: Double, rise: Double?)], gap: Double, speed: Double,
                        begin: (Person) -> Void = { _ in }, done: (Person) -> Void = { _ in }) async throws {
        let t0 = Date.now
        var next = people.map { _ in 0 }
        var endsAt = people.map { _ in Date.distantPast }
        var finished = Set<Int>()
        while finished.count < people.count {
            let now = Date.now
            for i in people.indices where !finished.contains(i) {
                guard now >= t0 + Double(i) * gap, now >= endsAt[i] else { continue }
                let p = people[i]
                if next[i] == legs.count {
                    finished.insert(i)
                    done(p)
                    continue
                }
                if next[i] == 0 { begin(p) }
                let leg = legs[next[i]]
                next[i] += 1
                let dur = beginWalk(p, to: leg.x, speed: speed)
                if let rise = leg.rise { p.float(to: rise, over: max(dur, 0.01), linear: true) }
                endsAt[i] = now + dur
            }
            try await sleep(0.04)
        }
    }

    /// Up the gangway and in through the ship's door, one after another.
    private func boardShip(_ people: [Person], speed: Double = 140) async throws {
        let (top, foot) = gangwayEnds
        let order = people.sorted { abs($0.x(at: .now) - foot.x) < abs($1.x(at: .now) - foot.x) }
        try await parade(order, legs: [(foot.x, nil), (top.x, Stage.floorY - top.y)], gap: 0.55, speed: speed,
                         done: { p in
                             p.visible = false
                             p.facing = 0
                             p.place(height: 0)
                         })
    }

    /// Down the gangway, one after another, and on to `xs` on the ground.
    private func leaveShip(_ people: [Person], to xs: [Double], speed: Double = 140) async throws {
        let (top, foot) = gangwayEnds
        for p in people {
            p.visible = false
            p.seated = false
        }
        try await parade(people, legs: [(foot.x, 0)], gap: 0.6, speed: speed, begin: { p in
            (p.x0, p.x1, p.moveDur) = (top.x, top.x, 0)
            p.place(height: Stage.floorY - top.y)
            p.visible = true
        })
        try await walkAll(zip(people, xs).map { ($0, $1) }, speed: speed)
        for p in people { p.facing = 0 }
    }

    /// Only these people are on stage.
    private func show(_ people: [Person]) {
        for p in everyone { p.visible = people.contains { $0 === p } }
    }

    // MARK: Funland

    /// Puts the house back the way it was (everyone where they stood) after a cut-away.
    private func backHome(_ spots: [(Person, Double, Double)], view: CGRect) async throws {
        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.tentShown = false
            self.tentFlying = false
            self.gangwayOut = false
            self.chairsStowed = false
            self.show(self.cast)
            for (p, x, f) in spots {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, f)
                p.seated = false
                p.place(height: 0)
            }
            self.cutNow(view)
        }
    }

    /// After the family's first cruise: back at Funland, Rita finds the Clowns of Poker on her phone. Once she makes it
    /// to game 10 she calls Sam and Tammy over, the S.S. Big Top pulls up at the boardwalk pier, and all three are
    /// transformed — then they join the crew and walk out on their jobs at the park.
    private func funlandRecruits() async throws {
        let (rita, sam, tammy, boss) = (extras[4], extras[5], extras[6], extras[3])
        let (repoMan, repoGuy) = (extras[0], extras[8])
        let spots = cast.map { ($0, $0.x(at: .now), $0.facing) }
        let crewmates = [rita, sam, tammy]

        // Funland's parking lot: the three of them out on the maintenance zambonis, with the boss watching.
        try await sceneChange {
            self.place = .park
            self.venue = nil
            self.zamboniShown = false
            self.flatbedShown = false
            self.scuffle = nil
            self.show(crewmates + [boss])
            for (p, x) in zip(crewmates, Stage.fleetStartX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
                p.mood = .glum
                p.clown = nil
                p.place(height: 0)
                p.seated = true
                p.tool = nil
            }
            self.fleet = zip(crewmates, Stage.fleetStartX).map { p, x in
                let z = ParkZamboni(at: x)
                z.rider = p
                return z
            }
            (boss.x0, boss.x1, boss.moveDur, boss.facing) = (Stage.parkOfficeX - 40, Stage.parkOfficeX - 40, 0, 1)
            boss.mood = .happy
            self.cutNow(Stage.full)
        }
        caption = "Meanwhile, back at Funland, Rita, Sam and Tammy are out on the maintenance zambonis — with Mr. Grimsby watching their every move."
        sound.hum(true)
        /// Everyone drives (or backs up) along the lot, still facing forward on the zamboni.
        func drive(_ xs: [Double]) -> Double {
            let longest = zip(crewmates, xs).map { beginWalk($0, to: $1, speed: 38) }.max() ?? 0
            for p in crewmates { p.facing = 1 }
            return longest
        }
        let out = drive(Stage.fleetStartX.map { $0 + 110 })
        try await sleep(1.4)
        try await say(boss, "Keep those lines straight! I'm watching every one of you!", 2.8)
        try await say(boss, "And nobody walks off one of MY zambonis like Deidre did!", 2.8)
        mention(tammy, "Scrub… turn… scrub…", 2.2)
        try await sleep(max(0, out - 6.8) + 0.3)
        _ = drive(Stage.fleetStartX.map { $0 + 40 })
        mention(sam, "Same lot, same lines, every single day…", 2.4)

        // In the middle of it, the repo men pull in.
        caption = "In the middle of their task, a big flatbed tow truck rolls into the lot…"
        flatbedFrom = -1100
        flatbedShown = true
        flatbedEmpty = false
        driveFlatbed(to: Stage.flatbedX, seconds: 3.6)
        sound.honk()
        try await sleep(1.8)
        for p in crewmates { stop(p); p.facing = 1 }
        sound.hum(false)
        try await sleep(2)
        sound.clunk()
        let cabX = Stage.flatbedX + Stage.flatbedLength + 30
        (repoMan.x0, repoMan.x1, repoMan.moveDur) = (cabX, cabX, 0)
        (repoGuy.x0, repoGuy.x1, repoGuy.moveDur) = (cabX + 30, cabX + 30, 0)
        repoMan.visible = true
        repoGuy.visible = true
        caption = "Two repo men climb down out of the cab."
        let tammyX = tammy.x(at: .now)
        try await walkAll([(repoMan, min(tammyX + 210, 1100)), (repoGuy, min(tammyX + 260, 1150))], speed: 120)
        (repoMan.facing, repoGuy.facing) = (-1, -1)
        try await look(at: Stage.shot(centerX: tammyX + 110, height: 330))
        try await say(repoMan, "You need to get off these zambonis.", 2.6)
        for p in crewmates { p.mood = .shocked }
        try await say(tammy, "Get off? But Mr. Grimsby told us to scrub the whole lot!", 2.8)

        // The boss storms over.
        try await look(at: Stage.full)
        boss.mood = .shocked
        try await walk(boss, to: repoMan.x(at: .now) - 70, speed: 170)
        boss.facing = 1
        try await look(at: Stage.shot(centerX: repoMan.x(at: .now) - 30, height: 320))
        try await say(boss, "Hey, what do you think you're doing?", 2.4)
        try await say(repoMan, "These maintenance zambonis are up for repossession — and so are your rides.", 3)
        try await say(boss, "These have been paid for!", 2.2)
        try await say(repoMan, "Well if you made your payments, we wouldn't be here.", 2.8)

        // The boss starts a fight.
        caption = "Mr. Grimsby starts fighting the repo men!"
        let repoX = repoMan.x(at: .now)
        mention(boss, "Get your hands off my zambonis!", 2.4)
        for k in 0..<4 {
            try await walk(boss, to: repoX - 36, speed: 380)
            scuffle = (repoX - 18, .now)
            sound.clunk()
            if k == 2 { mention(boss, "Take THAT!", 1.4) }
            try await walk(boss, to: repoX - 80, speed: 300)
            boss.facing = 1
        }
        repoGuy.facing = -1
        try await say(repoMan, "Sir, you need to back off.", 2.4)
        try await walk(boss, to: repoX - 95, speed: 120)
        boss.facing = 1
        try await say(repoGuy, "Back off, or the next call we make is to the police.", 2.8)

        // Off the zambonis — and the zambonis and the rides go up onto the flatbed together.
        caption = "Rita, Sam and Tammy climb down off the zambonis."
        try await look(at: Stage.full)
        for (z, p) in zip(fleet, crewmates) {
            z.parkedX = p.x(at: .now)
            z.rider = nil
            p.seated = false
            (p.x0, p.x1, p.moveDur) = (z.parkedX - 70, z.parkedX - 70, 0)
        }
        try await walkAll(zip(crewmates, [120.0, 170.0, 220.0]).map { ($0, $1) }, speed: 140)
        for p in crewmates { p.facing = 1 }
        try await walk(repoGuy, to: cabX - 40, speed: 160)
        repoGuy.facing = -1
        caption = "The repo men winch the zambonis AND the rides onto the flatbed, all at the same time!"
        for (z, slot) in zip(fleet, Stage.flatbedSlots) {
            z.slot = slot
            z.loadT0 = .now
        }
        parkHaul[.ferrisWheel] = .now
        parkHaul[.coaster] = .now
        sound.clunk()
        sound.buzz(true)
        mention(boss, "My zambonis! My Ferris wheel! My roller coaster!", 2.6)
        try await sleep(max(Self.loadDur, Self.rideLoadDur) + 0.4)
        sound.buzz(false)
        sound.clunk()
        boss.mood = .crying
        try await say(boss, "You can't do this! Those are MINE!", 2.4)
        try await say(repoMan, "Three zambonis, one Ferris wheel, one roller coaster. Have a nice day.", 3)
        try await walkAll([(repoMan, cabX), (repoGuy, cabX + 30)], speed: 150)
        repoMan.visible = false
        repoGuy.visible = false
        sound.clunk()

        caption = "The flatbed pulls away with all three zambonis and both rides…"
        driveFlatbed(to: Stage.W + 300, seconds: 4.6)
        sound.honk()
        try await sleep(0.8)
        boss.mood = .shocked
        mention(boss, "COME BACK HERE WITH MY RIDES!", 2.4)
        try await sleep(4)
        flatbedShown = false
        fleet = []
        scuffle = nil

        // The bank comes to shut the park down.
        let (banker, bankManager) = (extras[7], extras[9])
        caption = "Before Mr. Grimsby can catch his breath, two people in business suits walk into the lot…"
        (banker.x0, banker.x1, banker.moveDur, banker.facing) = (-60, -60, 0, 1)
        (bankManager.x0, bankManager.x1, bankManager.moveDur, bankManager.facing) = (-110, -110, 0, 1)
        banker.visible = true
        bankManager.visible = true
        boss.mood = .glum
        try await walk(boss, to: 640, speed: 120)
        boss.facing = -1
        try await walkAll([(banker, 520), (bankManager, 470)], speed: 110)
        (banker.facing, bankManager.facing) = (1, 1)
        try await look(at: Stage.shot(centerX: 560, height: 320))
        try await say(banker, "Mr. Grimsby? Shore Savings Bank.", 2.2)
        try await say(bankManager, "You haven't made a payment on Funland's loan in eight months.", 3)
        try await say(boss, "Not now! The repo men just took my zambonis AND my rides!", 2.8)
        try await say(banker, "Then you won't be needing the park. The loan is in default.", 2.8)
        try await say(bankManager, "As of today, the bank is shutting Funland down.", 2.6)
        boss.mood = .shocked
        try await say(boss, "Shutting it down?! You can't do that!", 2.4)
        try await say(banker, "We can, and we are. Here is the notice.", 2.4)

        caption = "The bank chains the front gate, posts the notice and switches off the power."
        try await look(at: Stage.full)
        let toBox = beginWalk(bankManager, to: Stage.powerBoxX + 26, speed: 130)
        let walkStart = Date.now
        try await walk(banker, to: 472, speed: 130)
        banker.facing = -1
        sound.clunk()
        funlandClosed = true
        try await sleep(1)
        bankManager.facing = -1
        try await sleep(max(0, toBox - Date.now.timeIntervalSince(walkStart)) + 0.3)
        sound.clunk()
        parkLightsOut = true
        caption = "CLUNK! Every light at Funland goes out. CLOSED BY THE BANK."
        try await sleep(2)
        bankManager.facing = 1
        try await walk(bankManager, to: 300, speed: 120)
        bankManager.facing = -1
        for p in crewmates { p.mood = .shocked; p.facing = 1 }
        try await say(bankManager, "I'm sorry, everyone. The park is closed for good. You'll all have to go home.", 3.2)
        try await say(tammy, "Closed? Then… we're all out of a job.", 2.4)
        try await say(banker, "Good day, Mr. Grimsby.", 2)
        bankManager.facing = -1
        banker.facing = -1
        try await walkAll([(banker, -80), (bankManager, -130)], speed: 120)
        banker.visible = false
        bankManager.visible = false
        boss.mood = .crying
        try await look(at: Stage.shot(centerX: 520, height: 320))
        try await say(boss, "My park… closed by the bank…", 2.6)
        boss.mood = .glum
        try await say(boss, "Well… at least I still have my motorcycle.", 2.6)

        // The repo men come back — for his motorcycle.
        caption = "Just then, the repo men's flatbed comes back — empty this time."
        flatbedFrom = -1100
        flatbedEmpty = true
        flatbedShown = true
        driveFlatbed(to: Stage.flatbedX, seconds: 3.6)
        sound.honk()
        try await look(at: Stage.full)
        try await sleep(3.8)
        sound.clunk()
        boss.facing = 1
        boss.mood = .shocked
        (repoMan.x0, repoMan.x1, repoMan.moveDur) = (cabX, cabX, 0)
        (repoGuy.x0, repoGuy.x1, repoGuy.moveDur) = (cabX + 30, cabX + 30, 0)
        repoMan.visible = true
        repoGuy.visible = true
        try await walkAll([(repoMan, 760), (repoGuy, 810)], speed: 130)
        (repoMan.facing, repoGuy.facing) = (-1, -1)
        try await look(at: Stage.shot(centerX: 700, height: 320))
        try await say(boss, "YOU again?! There's nothing left to take!", 2.4)
        try await say(repoMan, "There's one more thing, Mr. Grimsby. Your motorcycle.", 2.8)
        try await say(boss, "My motorcycle?! That's all I have left!", 2.4)
        try await say(repoGuy, "You stopped making payments on that too.", 2.4)

        caption = "The repo guy walks over to Mr. Grimsby's motorcycle…"
        try await look(at: Stage.full)
        try await walk(repoGuy, to: Stage.motorcycleX - 4, speed: 170)
        repoGuy.facing = 1
        repoGuy.seated = true
        motorcycleRider = repoGuy
        sound.clunk()
        try await sleep(0.6)
        sound.hum(true)
        mention(repoGuy, "VROOM VROOM!", 1.8)
        try await sleep(2)
        caption = "…hops on, and rides it right out of the lot!"
        let ride = beginWalk(repoGuy, to: Stage.W + 200, speed: 300)
        // Once it zooms past him, Grimsby runs after it…
        let passes = max(0, (boss.x(at: .now) - Stage.motorcycleX) / 300) + 0.3
        try await sleep(passes)
        mention(boss, "HEY! That's MY motorcycle!", 2)
        _ = beginWalk(boss, to: Stage.W + 120, speed: 240)
        try await sleep(1.2)
        mention(boss, "COME BACK HERE WITH MY MOTORCYCLE!", 2.4)
        try await sleep(max(0, ride - passes - 1.2) + 0.2)
        sound.hum(false)
        motorcycleShown = false
        motorcycleRider = nil
        repoGuy.seated = false
        repoGuy.visible = false
        try await sleep(2.6)
        boss.visible = false
        try await say(repoMan, "He'll never catch it. Have a nice day, folks.", 2.6)
        try await walk(repoMan, to: cabX, speed: 150)
        repoMan.visible = false
        sound.clunk()
        driveFlatbed(to: Stage.W + 300, seconds: 4.6)
        try await sleep(4.8)
        flatbedShown = false
        flatbedEmpty = false

        // …and he never comes back.
        caption = "Mr. Grimsby runs down the boardwalk after his motorcycle… and he never comes back."
        try await sleep(3.4)

        // With Grimsby gone for good, the three of them crack up.
        caption = "With Mr. Grimsby gone for good, the workers get a big laugh!"
        try await look(at: Stage.shot(centerX: 170, height: 280))
        for p in crewmates { p.mood = .beaming; p.facing = 0 }
        for (text, size) in [("Ha… ha ha…", 16.0), ("HA HA HA HA!", 21.0), ("HAHAHAHAHA!!", 26.0)] {
            for p in crewmates { p.voice = size }
            shout(crewmates, text, 1.8)
            try await sleep(2)
        }
        for p in crewmates { p.voice = 15 }
        try await say(sam, "Did you see him chasing that motorcycle?!", 2.4)
        try await say(tammy, "\"At least I still have my motorcycle!\" Not anymore!", 2.6)
        try await say(rita, "Serves him right, after the way he treated Deidre!", 2.6)
        try await say(sam, "Well if you don't pay your bills, this is what happens to your ass.", 3)
        for p in crewmates { p.mood = .happy }
        caption = "They wait… and wait… but Mr. Grimsby never comes back."
        try await sleep(2.4)
        for p in crewmates { p.facing = 1 }
        try await say(rita, "I guess he's not coming back.", 2.2)
        for p in crewmates { p.mood = .glum }
        try await say(tammy, "First Deidre walks out, and now the bank closes the whole park…", 2.8)

        // Then the Clowns of Poker downloads itself onto Rita's phone.
        try await look(at: Stage.shot(centerX: 170, height: 280))
        sound.chime()
        rita.tool = .phone
        rita.facing = 1
        try await say(rita, "Huh? An app just downloaded itself onto my phone…", 2.6)
        rita.mood = .shocked
        try await say(rita, "\"The Clowns of Poker\"? Well, we've got nothing but time now. Why not?", 2.8)
        rita.mood = .happy

        caption = "Rita plays the Clowns of Poker on her phone. Play the max bet all the way through to make it to game 10!"
        let session = PokerSession(player: rita.id, muted: muted)
        session.tenLine = "You are very, very good, Rita! You have made it to game 10. Game 10 is for the whole crew, so call your coworkers over."
        session.onSound = { [weak self] s in
            switch s {
            case .card: self?.sound.shutter()
            case .coin: self?.sound.pay()
            case .chime: self?.sound.chime()
            }
        }
        session.onEnd = { [weak self, weak session] ending in
            guard ending == .qualified else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(7))
                guard let self, let session, self.poker === session else { return }
                self.finishPoker()
            }
        }
        poker = session
        pokerPlaying = true
        session.begin()
        await withCheckedContinuation { cont in pokerDone = cont }
        try Task.checkCancellation()
        poker = nil

        rita.mood = .beaming
        try await say(rita, "I made it to game 10!", 2)
        rita.mood = .happy
        try await say(rita, "It says game 10 is for the whole crew… Sam! Tammy! Look at this!", 3)
        for p in [sam, tammy] { p.mood = .happy; p.facing = -1 }
        try await say(sam, "What is it, Rita? We just lost our jobs.", 2.4)
        try await say(rita, "Look! I made it to game 10 on the Clowns of Poker — and it's for all of us!", 3)
        try await say(tammy, "Game 10 of what, exactly?", 2)

        sound.honk()
        caption = "A ship's horn sounds from the boardwalk pier, right next to Funland!"
        for p in crewmates { p.mood = .shocked }
        try await say(sam, "Is that… a ship's horn?", 2)
        try await say(rita, "The phone says: go to the end of the pier!", 2.4)
        caption = "The three of them run down to the pier."
        for p in crewmates { p.facing = 1 }
        try await walkAll(crewmates.map { ($0, Stage.W + 80) }, speed: 220)

        // The pier: the S.S. Big Top sails up.
        try await sceneChange {
            self.dockScene(.wildwood)
            self.show(crewmates)
            for (p, x) in zip(crewmates, [760.0, 820.0, 880.0]) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
        }
        caption = "The S.S. Big Top pulls up to the boardwalk pier!"
        tentFlying = true
        sound.hum(true)
        try await sailIn()
        try await say(tammy, "A CRUISE SHIP! A circus cruise ship!", 2.2)
        caption = "The gangway slides out, and the alien clowns come down to meet them."
        let visitors = [leader, crew[0]]
        try await extendGangway()
        try await leaveShip(visitors, to: Stage.greetX)
        (leader.facing, crew[0].facing) = (1, 1)
        sound.honk()
        try await say(leader, "HONK HONK! Congratulations, Rita — you made it to game 10!", 2.8)
        try await say(leader, "Game 10 is a cruise for you and your coworkers. All aboard!", 2.8)
        for p in crewmates { p.mood = .happy }
        try await say(sam, "Clowns? On a cruise ship? Beats scrubbing the bumper cars!", 2.8)
        try await say(tammy, "Who needs Grimsby anyway? Let's go!", 2.2)
        caption = "Rita, Sam and Tammy walk up the gangway onto the ship!"
        try await boardShip(crewmates + visitors)
        try await retractGangway()
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 3)
        try await sleep(2.4)

        // Aboard: the chairs.
        try await sceneChange {
            self.place = .bigTop
            self.venue = nil
            self.tentShown = false
            self.chairsStowed = false
            self.seat(crewmates, chairs: [0, 1, 2])
            for (p, x) in zip(self.crew, Stage.crewX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
            }
            self.show(crewmates + self.crew)
            self.cutNow(Stage.chairsView)
        }
        tentFlying = false
        sound.hum(false)
        caption = "Aboard the S.S. Big Top, the three of them are shown to the clowns' chairs…"
        try await strap(crewmates)
        try await say(rita, "Ooh, seat belts! What happens now?", 2.2)
        try await say(leader, "Pick the type of alien clown you want to be!", 2.4)
        let riders = try await pickKinds(crewmates)
        try await look(at: Stage.full)
        try await say(leader, "Just relax and enjoy it.", 2)
        try await runMachine(riders, presser: leader, change: Machine.customerChange,
                             tingleLine: (tammy, "It tickles!"), legsStartLine: (sam, "My legs! Look at these big shoes!"),
                             bodyLine: (rita, "A sparkly suit — way better than this Funland shirt!"),
                             faceShouts: (rita, [("Here come our faces…", 15), ("Wheeeeeeeee!", 17)]), beamOnShout: 1,
                             faceSpeakers: [[rita], crewmates])
        try await look(at: Stage.full)
        try await say(leader, "The transformation is complete. Have a look!", 2.6)
        try await showMirror(crewmates, caption: "Rita, Sam and Tammy see themselves as alien clowns!", calm: crewmates)
        for p in crewmates { p.mood = .beaming }
        try await look(at: Stage.chairsView)
        shout(crewmates, "Wow!", 1.8)
        try await sleep(2)
        for p in crewmates { p.mood = .happy }

        // The offer.
        try await look(at: Stage.full)
        try await say(leader, "Our cruise ship could use a few more hands. How would you like to join the crew of the S.S. Big Top?", 3.6)
        try await say(rita, "Join the crew? We just lost our jobs — talk about perfect timing!", 2.8)
        try await say(sam, "No more Mr. Grimsby — wherever he ran off to!", 2.6)
        try await say(tammy, "Not after the way he treated Deidre. I'm in!", 2.6)
        try await say(rita, "Then it's settled. We're joining the crew!", 2.6)
        shout(crewmates, "Honk honk!", 1.8)
        sound.honk()
        try await sleep(2)
        try await snap(crewmates)
        unstrap(crewmates)
        rita.tool = nil
        recruits = crewmates
        caption = "Out of work after Funland closed, Rita, Sam and Tammy join the crew of the S.S. Big Top!"
        try await sleep(3)

        try await backHome(spots, view: Stage.shot(centerX: 520, height: 250))
        caption = "Back home, Deidre and the girls have no idea."
        try await sleep(1.6)
    }

    /// The morning after the first night: the family hears that the bank shut Funland down and Mr. Grimsby is gone.
    private func funlandNews() async throws {
        kelly.mood = .shocked
        try await say(kelly, "Mom! It's on the news — the repo men took Funland's zambonis AND its rides yesterday afternoon!", 3.4)
        try await say(kelly, "Then the bank shut the whole park down — Mr. Grimsby never paid back his loan!", 3.2)
        try await say(jen, "And the repo men took his motorcycle too! He ran after it…", 2.8)
        try await say(kelly, "…and nobody has seen him since!", 2.4)
        kelly.mood = .happy
        deidre.mood = .beaming
        try await say(deidre, "Well, well. Looks like Mr. Grimsby got the short end of the stick this time!", 3.2)
        deidre.mood = .happy
        try await say(jen, "And Rita, Sam and Tammy are on a circus cruise ship!", 2.6)
        try await say(deidre, "Good for them. We'll see them aboard!", 2.4)

        // Meanwhile on the S.S. Big Top, Rita, Sam and Tammy hear the news too.
        guard recruits.count == 3 else { return }
        let (rita, sam, tammy) = (recruits[0], recruits[1], recruits[2])
        let homeSpots = cast.map { ($0, $0.x(at: .now), $0.facing) }
        try await sceneChange {
            self.place = .bigTop
            self.venue = nil
            self.tentShown = false
            self.tentFlying = false
            self.chairsStowed = true
            self.customers = []
            for (p, x) in zip(self.recruits, Stage.deckX(3)) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
                p.seated = false
                p.mood = .happy
            }
            self.show(self.recruits)
            self.cutNow(Stage.full)
        }
        caption = "Meanwhile, aboard the S.S. Big Top, Rita, Sam and Tammy hear the news."
        try await look(at: Stage.shot(centerX: rita.x(at: .now) + 60, height: 300))
        sound.chime()
        rita.tool = .phone
        rita.facing = 1
        try await say(rita, "You guys! Funland made the morning news!", 2.6)
        for p in [sam, tammy] { p.mood = .shocked }
        try await say(rita, "\"Park closed by the bank. Owner last seen chasing his own motorcycle down the boardwalk.\"", 3.6)
        try await say(rita, "He never came back — nobody knows where he went!", 2.8)
        rita.tool = nil

        caption = "The three of them can't stop laughing!"
        let crew = [rita, sam, tammy]
        for p in crew { p.mood = .beaming; p.facing = 0 }
        for (text, size) in [("Ha… ha ha…", 16.0), ("HA HA HA HA!", 21.0), ("HAHAHAHAHA!!", 26.0)] {
            for p in crew { p.voice = size }
            shout(crew, text, 1.8)
            try await sleep(2)
        }
        for p in crew { p.voice = 15 }
        try await say(sam, "Told you — don't pay your bills, and this is what happens!", 2.8)
        try await say(tammy, "\"COME BACK HERE WITH MY MOTORCYCLE!\"", 2.4)
        shout(crew, "HAHAHA!", 1.6)
        try await sleep(1.8)
        try await say(rita, "Best news ever. Who needs Funland? We've got a whole circus ship!", 3)
        for p in crew { p.mood = .happy }

        try await backHome(homeSpots, view: Stage.shot(centerX: 520, height: 250))
    }

    // MARK: A cruise day

    /// One day aboard the S.S. Big Top. The player keeps planning the next part of the day — a day at port, where
    /// passers-by are invited on the cruise and transformed, or a day at sea, with card games just for fun —
    /// until she ends the day. Then every passenger is dropped off at the port she came aboard at.
    private func cruiseDay(keepAboard: Bool = false) async throws {
        if !keepAboard {
            passengers = []
            boardedAt = [:]
            dayEarned = 0
            dayFees = 0
        }
        stopsToday = 0
        while true {
            caption = stopsToday == 0 ? "Plan the day! A day at port, or a day at sea?"
                : "What next? Another port, a day at sea — or end the day? (\(passengers.count) \(passengers.count == 1 ? "passenger" : "passengers") aboard)"
            let plan = await withCheckedContinuation { cont in
                dayPick = cont
                choosingDay = true
            }
            try Task.checkCancellation()
            switch plan {
            case .port(let venue): try await portDay(venue)
            case .sea(let game): try await seaDay(game)
            case .end:
                try await dropOffs()
                return
            case .overnight:
                try await overnightAboard()
                try await dropOffs()
                return
            }
            stopsToday += 1
        }
    }

    /// Instead of ending the day, everyone — family, crew and passengers — spends the night aboard. The next morning the
    /// ship calls at two more ports (the player picks them), and then every passenger is taken back where they came aboard.
    private func overnightAboard() async throws {
        let (greeter, cashier, _) = roles
        try await say(leader, "Why go home tonight? Everyone stays aboard the S.S. Big Top!", 2.8)
        try await say(leader, "Tomorrow morning we call at two more ports — then we bring everyone back where they came aboard.", 3.6)
        if !passengers.isEmpty {
            try await say(leader, "And don't worry — nobody changes back while they're aboard the ship.", 3)
            try await say(passengers.randomElement()!, ["A sleepover on a circus cruise ship? YES!", "A night at sea as a clown? Best vacation ever!",
                                                        "I'll call home — they won't believe this!"].randomElement()!, 2.6)
        }
        try await say(greeter, "A night at sea! Girls, this is the life!", 2.4)

        assignCabins()
        let passengerCabins = cabins.filter { $0.label.hasPrefix("Cabin") }.count
        try await say(leader, passengers.isEmpty ? "Your cabins are all made up below deck — bunk beds and portholes!"
                      : "Every passenger gets a cabin below deck — \(passengerCabins) of them, with bunk beds and portholes!", 3)
        try await say(cashier, "Here are your cabin keys, everyone! Sweet dreams!", 2.4)
        caption = "Night falls over the ocean. Everyone heads below deck to their cabins…"
        try await sceneChange {
            self.place = .cabins
            self.show([])
            self.night = true
            self.cutNow(Stage.full)
        }
        caption = "Lights out in the cabins of the S.S. Big Top. Still alien clowns, everyone sleeps in their bunks."
        sound.hum(false)
        clockT0 = .now
        clockDur = 5
        clockLabel = "Hours till morning"
        clockSpan = 8 * 60
        try await sleep(5.5)
        night = false
        sound.chime()
        caption = "Morning sun streams in through the portholes. Rise and shine!"
        try await sleep(2.4)
        try await aboard(sailing: true)
        cabins = []
        caption = "The next morning, up on deck of the S.S. Big Top…"
        try await sleep(1.4)
        try await say(cashier, "Good morning! I slept like a rock in that bunk!", 2.4)
        // A new day: last night's passengers all go ashore first, back where they came aboard.
        if !passengers.isEmpty {
            try await say(leader, "Good morning, everyone! Before the new day starts, we'll take all of last night's passengers home.", 3.4)
            try await dropOffs(overnight: true)
            try await aboard(sailing: true)
            caption = "With every overnight passenger safely ashore, a new day begins aboard the S.S. Big Top."
            try await sleep(1.6)
        }
        try await say(leader, "A brand-new day! Two ports to go before we head home.", 2.8)

        for n in 1...2 {
            guard cash >= Venue.cheapestFee else {
                caption = "There isn't enough cash for another docking fee, so the ship skips port stop \(n)."
                try await say(greeter, "We can't cover another docking fee. Let's take everyone home.", 2.8)
                break
            }
            caption = "Port stop \(n) of 2 this morning — where to?"
            morningStop = n
            let plan = await withCheckedContinuation { cont in
                dayPick = cont
                choosingDay = true
            }
            morningStop = nil
            try Task.checkCancellation()
            guard case .port(let venue) = plan else { continue }
            try await portDay(venue)
            stopsToday += 1
        }
        caption = "That's both morning ports. Time to bring everyone back!"
        try await sleep(1.6)
    }

    /// Two to a cabin (a bunk bed each): the family first, then Rita, Sam and Tammy, then the passengers in the order
    /// they came aboard, so people who boarded together end up next door to each other.
    private func assignCabins() {
        func pairs(_ people: [Person]) -> [[Person]] {
            stride(from: 0, to: people.count, by: 2).map { Array(people[$0..<min($0 + 2, people.count)]) }
        }
        var list: [(String, [Person])] = pairs(team).map { ("Family", $0) } + pairs(recruits).map { ("Crew", $0) }
        list += pairs(passengers).enumerated().map { ("Cabin \(101 + $0.offset)", $0.element) }
        cabins = Array(list.prefix(Stage.cabinCount)).map { (label: $0.0, guests: $0.1) }
    }

    /// Who's who on the trip: two go down the gangway (one invites, one takes the fares) and one works the machine.
    private func portDay(_ venue: Venue) async throws {
        let (greeter, cashier, machinist) = roles
        caption = "The S.S. Big Top sets sail for \(venue.theName)!"
        tentFlying = true
        sound.hum(true)
        try await sleep(2.4)
        try await sceneChange {
            self.dockScene(venue)
            self.show([])
        }
        freshCrowd()
        let startCash = cash

        caption = "The cruise ship pulls into port at \(venue.theName)!"
        try await sailIn()
        caption = "Docking at \(venue.theName) costs $\(venue.fee)."
        cash -= venue.fee
        dayFees += venue.fee
        cashPop = ("-$\(venue.fee)", .now, Stage.cashX)
        try await sleep(1.8)

        caption = "The gangway slides out. \(greeter.id) and \(cashier.id) go ashore to invite passers-by, while \(machinist.id) stays aboard at the machine."
        try await extendGangway()
        try await leaveShip([greeter, cashier], to: Stage.greetX)
        (greeter.facing, cashier.facing) = (1, 1)
        sound.honk()
        try await say(greeter, "Step right up! Come on a cruise aboard the S.S. Big Top! Only $\(venue.price), kids $\(venue.kidPrice)!", 3.2)
        try await say(cashier, "Everyone who comes aboard gets turned into an alien clown!", 2.6)
        try await say(greeter, "And we'll bring you right back here at the end of the day!", 2.6)

        var boarded: [Person] = []
        for n in 1...venue.groups {
            if passengers.count >= capacity {
                caption = "The S.S. Big Top is full!"
                try await say(cashier, "That's it — the ship is full!", 2)
                break
            }
            caption = "Passer-by \(n) of \(venue.groups) comes strolling along the quay."
            boarded += try await serveGroup(venue, origin: venue)
        }

        caption = "Time to cast off from \(venue.theName)!"
        (greeter.facing, cashier.facing) = (0, 0)
        try await look(at: Stage.shot(centerX: 640, height: 260))
        if boarded.isEmpty {
            try await say(greeter, "Nobody wanted to come on the cruise here. Oh well!", 2.4)
        } else {
            try await say(greeter, "\(boarded.count) new \(boarded.count == 1 ? "passenger" : "passengers") from \(venue.shortName)!", 2.4)
        }
        try await say(cashier, "All aboard!", 1.6)
        try await look(at: Stage.full)
        try await boardShip([greeter, cashier])
        try await retractGangway()
        sound.honk()
        caption = "The S.S. Big Top casts off."
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 3)
        tentFlying = true
        sound.hum(true)
        try await sleep(2.4)

        if !boarded.isEmpty { try await miniTentShow(boarded, from: venue.shortName) }
        let record = EventRecord(date: .now, venue: venue, asked: asked, customers: served, fee: venue.fee, earned: earned,
                                 startCash: startCash, endCash: cash)
        album.add(record)
        result = record
        trips += 1
        totalProfit += record.profit
        totalTransformed += served.count
        try await aboard(sailing: true)
    }

    /// A new stop: nobody asked yet, and fresh names for the passers-by.
    private func freshCrowd() {
        served = []
        asked = 0
        earned = 0
        adultNames = (Self.menNames + Self.womenNames).shuffled()
        momNames = ["Brenda", "Denise", "Lena", "Tanya", "Monica", "Sara", "Wendy", "Sherry", "Michelle", "Christine", "Karla", "Dawn"].shuffled()
        kidNames = ["Amy", "Ben", "Cora", "Danny", "Ella", "Finn", "Gwen", "Hannah", "Jade", "Max", "Noah", "Kai", "Mary", "Sue", "Ellie", "Lori", "Christina", "Kiki", "Heidi"].shuffled()
    }

    /// Right after their first transformation, with the ship still docked beside the house, two of them go down the
    /// gangway and invite people strolling along the shore on the cruise — for a fare. Whoever comes aboard is
    /// transformed under the mini saucers and rides along all day; they're dropped back at the house that night.
    private static let homeGroups = 4

    private func homeInvites() async throws {
        let (greeter, cashier, machinist) = roles
        try await say(leader, "And there's no need to wait — we're still docked right beside your house!", 3)
        try await say(leader, "Folks stroll along the shore here all day. Invite them on the cruise, and they'll pay a fare to be transformed.", 3.8)
        try await say(leader, "And there's no docking fee here at home!", 2.2)
        try await say(deidre, "Our very own front yard. Let's do it!", 2.2)

        passengers = []
        boardedAt = [:]
        dayEarned = 0
        dayFees = 0
        freshCrowd()
        let venue = Venue.wildwood
        let startCash = cash
        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.customers = []
            self.tentFlying = false
            self.tentShown = true
            self.moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.dockY), over: 0)
            self.gangwayOut = false
            self.gangwayT0 = .distantPast
            self.chairsStowed = false
            self.show([])
            self.cutNow(Stage.full)
        }
        caption = "The gangway slides out. \(greeter.id) and \(cashier.id) go ashore to invite passers-by, while \(machinist.id) stays aboard at the machine."
        try await extendGangway()
        try await leaveShip([greeter, cashier], to: Stage.homeGreetX)
        (greeter.facing, cashier.facing) = (-1, -1)
        try await look(at: Stage.yardView)
        sound.honk()
        try await say(greeter, "Step right up! Come on a cruise aboard the S.S. Big Top! Only $\(venue.price), kids $\(venue.kidPrice)!", 3.2)
        try await say(cashier, "Everyone who comes aboard gets turned into an alien clown!", 2.6)
        try await say(greeter, "And we'll bring you right back here at the end of the day!", 2.6)

        var boarded: [Person] = []
        for n in 1...Self.homeGroups {
            caption = "Passer-by \(n) of \(Self.homeGroups) comes strolling along the shore."
            boarded += try await serveGroup(venue, entry: -160, stop: Stage.homeStopX, exit: -160, cashAt: Stage.homeGreetX[1], origin: nil)
        }

        caption = "Time to get going!"
        (greeter.facing, cashier.facing) = (0, 0)
        if boarded.isEmpty {
            try await say(greeter, "Nobody wanted to come along. Oh well — there's always the next port!", 2.8)
        } else {
            try await say(greeter, "\(boarded.count) \(boarded.count == 1 ? "passenger" : "passengers") from right here on our own shore!", 2.6)
        }
        try await say(cashier, "All aboard!", 1.6)
        try await look(at: Stage.full)
        try await boardShip([greeter, cashier])
        try await retractGangway()

        if !boarded.isEmpty { try await miniTentShow(boarded, from: "the house") }
        totalProfit += cash - startCash
        totalTransformed += served.count
        try await aboard(sailing: false)
    }

    /// Passers-by stroll along the quay from the right: a grown-up on their own, or a mother with one or two kids.
    /// A group comes aboard together or not at all. Returns whoever walked up the gangway.
    /// They come in from `entry`, stop at `stop` in front of the greeters, and walk on to `exit` if they say no.
    /// `origin` is where they get dropped off at the end of the day (`nil`: back at the house).
    private func serveGroup(_ venue: Venue, entry: Double = 1300, stop: Double = Stage.stopX[0], exit: Double = -150,
                            cashAt: Double = Stage.cashX, origin: Venue?) async throws -> [Person] {
        let (greeter, cashier, _) = roles
        if place != .house { try await look(at: Stage.full) }
        // Which side they come from: +1 from the right, -1 from the left.
        let side: Double = entry > stop ? 1 : -1
        let withKid = Double.random(in: 0...1) < venue.kidChance
        let kidCount = withKid ? (Double.random(in: 0...1) < 0.4 ? 2 : 1) : 0
        let kids = (0..<kidCount).map { i in Person.customer(kidNames.popLast() ?? "Kiddo", kid: true, x: entry + side * Double(i) * 70) }
        let first = kids.first
            ?? adultNames.popLast().map { Person.customer($0, kid: false, female: Self.womenNames.contains($0), x: entry) }
            ?? Person.customer("Guest", kid: false, female: false, x: entry)
        let mother = withKid ? Person.customer(momNames.popLast() ?? "Mrs. Smith", kid: false, x: entry + side * 35) : nil
        let group = (kids.isEmpty ? [first] : kids) + (mother.map { [$0] } ?? [])
        customers = group
        asked += group.count

        let stroll = 85.0
        let arrive = group.enumerated().map { i, p in beginWalk(p, to: stop + side * Double(i) * 30, speed: stroll) }.max() ?? 0
        try await sleep(arrive + 0.1)
        for p in group { p.facing = -side }
        (greeter.facing, cashier.facing) = (side, side)

        func walkOn() async throws {
            let away = group.map { beginWalk($0, to: exit, speed: stroll) }.max() ?? 0
            try await sleep(away + 0.1)
            customers = []
        }

        try await say(greeter, group.count == 1 ? "Hi! Want to come on a cruise? You'll be turned into an alien clown!"
                                                : "Hi, folks! Want to come on a cruise? You'll all be turned into alien clowns!", 2.8)
        if passengers.count + group.count > capacity {
            try await say(cashier, "Oh — sorry, there isn't room for \(group.count == 1 ? "one more" : "all of you") today!", 2.4)
            caption = "The ship is almost full."
            try await walkOn()
            return []
        }
        var goes: Bool
        if let mother {
            var kidsIn = false
            for (i, kid) in kids.enumerated() {
                let yes = Double.random(in: 0...1) < (i == 0 || !kidsIn ? venue.kidYes : 0.9)
                kidsIn = kidsIn || yes
                try await say(kid, yes ? ["A cruise? With CLOWNS? Yes!", "Can we go, Mom? Please?", "I want to be a clown on a cruise ship!"].randomElement()!
                                       : ["Clowns? No way!", "Hmm… I don't know…"].randomElement()!, 2.2)
            }
            goes = Double.random(in: 0...1) < (kidsIn ? min(0.9, venue.momYes + 0.2) : venue.momYes * 0.4)
            try await say(mother, goes ? (kidsIn ? "A cruise! Why not — let's all be clowns together!" : "Oh, come on, kids — it'll be fun! We're going!")
                                       : (kidsIn ? "Not today, kids. Maybe next time!" : "No thanks, we're off to have fun!"), 2.6)
        } else {
            goes = Double.random(in: 0...1) < venue.adultYes
            try await say(first, goes ? ["A cruise? Sign me up!", "Send in the clowns — I'm coming aboard!", "I've always wanted to run away with the circus!"].randomElement()!
                                      : ["No thanks!", "Not today!", "Uh… I'll pass."].randomElement()!, 2.2)
        }
        if !goes {
            // One more try.
            try await say(cashier, "Are you sure? It's a whole cruise — and the clown wears off in eight hours!", 2.8)
            goes = Double.random(in: 0...1) < 0.35
            let decider = mother ?? first
            try await say(decider, goes ? ["Oh, all right — you talked me into it!", "Well… okay! Why not!"].randomElement()!
                                        : ["Still no thanks — but have fun!", "Maybe next time!"].randomElement()!, 2.4)
        }
        guard goes else {
            caption = group.count == 1 ? "\(first.id) keeps walking." : "They keep walking."
            try await walkOn()
            return []
        }

        // Fares at the table at the foot of the gangway.
        let payer = mother ?? first
        let amount = group.reduce(0) { $0 + ($1.isKid ? venue.kidPrice : venue.price) }
        try await say(cashier, "That'll be $\(amount), please! Welcome aboard!", 2.4)
        caption = "\(payer.id) pays $\(amount)."
        payer.says = ["Here you go!", "Here's $\(amount)!", "Worth every penny!"].randomElement()!
        payer.saysUntil = .now + 1.6
        cash += amount
        earned += amount
        dayEarned += amount
        cashPop = ("+$\(amount)", .now, cashAt)
        sound.pay()
        try await sleep(1.8)

        caption = "\(ListFormatter.localizedString(byJoining: group.map(\.id))) \(group.count == 1 ? "walks" : "walk") up the gangway onto the S.S. Big Top!"
        try await boardShip(group)
        customers = []
        if let origin { for p in group { boardedAt[ObjectIdentifier(p)] = origin } }
        passengers += group
        return group
    }

    /// Aboard, the new passengers line up on the deck. Mini saucers zip out of the machine, one hovers over each of them,
    /// and they're all transformed at once.
    private func miniTentShow(_ boarded: [Person], from origin: String) async throws {
        let machinist = roles.machinist
        try await sceneChange {
            self.place = .bigTop
            self.venue = nil
            self.tentShown = false
            self.chairsStowed = true
            for (p, x) in zip(boarded, Stage.deckX(boarded.count)) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
                p.seated = false
            }
            (machinist.x0, machinist.x1, machinist.moveDur, machinist.facing) = (Stage.controlX, Stage.controlX, 0, -1)
            machinist.place(height: 0)
            machinist.seated = false
            self.show([machinist] + boarded)
            self.cutNow(Stage.full)
        }
        tentFlying = false
        sound.hum(false)
        caption = "Aboard, the new passengers from \(origin) gather on the deck."
        try await say(machinist, boarded.count == 1 ? "Welcome aboard the S.S. Big Top! What type of alien clown do you want to be?"
                                                    : "Welcome aboard the S.S. Big Top, everybody! What types of alien clown do you want to be?", 3)
        var riders: [(Person, ClownKind)] = []
        for (i, p) in boarded.enumerated() {
            let kind = ClownKind.allCases.randomElement()!
            riders.append((p, kind))
            if i < 4 {
                try await say(p, ["\(kind.name), please!", "I want to be \(kind.name)!", "\(kind.name)! Definitely \(kind.name)!"].randomElement()!, 1.8)
            }
        }
        if boarded.count > 4 {
            caption = "Everyone else picks too: " + riders.dropFirst(4).map { "\($0.0.id) — \($0.1.name)" }.joined(separator: ", ") + "."
            try await sleep(2.6)
        }
        try await say(machinist, "Stand still! Here come the mini saucers!", 2.2)

        caption = "The hatch on top of the machine slides open…"
        sound.chime()
        try await sleep(0.8)
        caption = boarded.count == 1 ? "Whirr… a mini saucer flies out of the machine and over \(boarded[0].id)'s head!"
                                     : "Whirr… a mini saucer flies out of the machine for each of them!"
        try await miniSaucers(riders, home: "the machine",
                              chargeLines: [(boarded[0], boarded.count == 1 ? "A little flying saucer, just for me!" : "We each get our own little flying saucer!")])

        try await say(machinist, "All done! Take a look in the mirror!", 2.2)
        caption = "\(machinist.id) lowers the big mirror…"
        try await showMirror(boarded, caption: boarded.count == 1 ? "\(boarded[0].id) sees an alien clown looking back!"
                                                                  : "They see a whole deck of alien clowns looking back!", seconds: 3)
        for (p, kind) in riders.shuffled().prefix(3) {
            try await say(p, p.isKid ? ["I'm a \(kind.name) clown!", kind.noseLine == nil ? "Look at my big red nose!" : "Look at me!", "Best cruise EVER!"].randomElement()!
                                     : ["Wow! Look at me!", "I'm a real alien clown!", "Honk honk! I love it!"].randomElement()!, 2.2)
            if let line = kind.noseLine { try await say(p, line, 2) }
        }
        for (p, kind) in riders { served.append(PersonSpec(p, kind: kind)) }
        try await say(machinist, "You'll be clowns for the whole cruise. At the end of the day we'll drop you off back at \(origin)!", 3.4)
    }

    /// A day at sea: everyone gathers on deck for a card game, just for fun. You play one of the girls' seats.
    private func seaDay(_ game: CasinoGame) async throws {
        caption = "A day at sea! The S.S. Big Top sails out onto the open ocean."
        try await aboard(sailing: true)
        try await sleep(1.6)
        try await say(leader, "A day at sea! Who's up for a game of \(game.name)? Just for fun!", 2.8)
        let me = team.contains { $0 === jen } ? jen : team.first(where: \.isKid) ?? team[0]
        let others = Array((passengers.shuffled() + team.filter { $0 !== me } + [leader]).prefix(game.funSeats - 1))
        if let guest = others.first(where: { p in passengers.contains { $0 === p } }) {
            try await say(guest, ["Ooh, I love \(game.name)!", "Deal me in!", "Cards on a cruise? Perfect!"].randomElement()!, 2)
        } else {
            try await say(others[0], "Deal me in!", 1.8)
        }
        _ = try await funTable(game, me: me, others: others)
        try await say(leader, "What a lovely day at sea!", 2)
    }

    /// A game of cards just for fun, with you playing `me`'s seat. Returns the winners.
    private func funTable(_ game: CasinoGame, me: Person, others: [Person]) async throws -> [Person] {
        var table = others.shuffled()
        let mine = Int.random(in: 0...table.count)
        table.insert(me, at: mine)
        you = me.id
        autoPlay = false
        caption = "You're \(me.id). Your cards show up under the table."
        try await sleep(1.2)
        let (scores, hands) = try await playFun(game, table, human: mine)
        let won = Tricks.winners(game, scores: scores, hands: hands) ?? [scores.indices.max { scores[$0] < scores[$1] }!]
        caption = "\(won.map { table[$0].id }.joined(separator: " & ")) win\(won.count == 1 ? "s" : "") the game of \(game.name)!"
        sound.chime()
        try await say(table[won[0]], ["Woo-hoo! I win!", "That was SO much fun!", "Best game ever!"].randomElement()!, 2.2)
        try await sleep(0.6)
        you = nil
        myHand = []
        humanRow = nil
        board = nil
        tableSeats = []
        tableGroups = []
        prompt = nil
        return won.map { table[$0] }
    }

    /// Deals hand after hand until someone reaches the target. You play `human`'s seat.
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
        let seats = tableHost(human: human)
        var hand = 0
        var dealer = Int.random(in: 0..<names.count)
        while Tricks.winners(game, scores: scores, hands: hand) == nil && hand < 30 {
            board?.status = "Hand \(hand + 1) · \(names[dealer]) deals · " + (game == .hearts ? "ends at \(game.target)" : game.byRounds ? "of \(game.target)" : "to \(game.target)")
            caption = "Hand \(hand + 1): \(names[dealer]) deals."
            sound.shutter()
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
        tableGroups = []
        return (scores, hand)
    }

    /// The end of the day: the ship calls at every port it picked people up at, in order, and they go ashore —
    /// still alien clowns, for another eight hours.
    private func dropOffs(overnight: Bool = false) async throws {
        guard !passengers.isEmpty else { return }
        let greeter = roles.greeter
        var stops: [Venue] = []
        for p in passengers {
            if let v = boardedAt[ObjectIdentifier(p)], !stops.contains(v) { stops.append(v) }
        }
        if !overnight {
            try await say(leader, "That's the end of the day! Time to take everyone back where they came aboard.", 3)
        }
        for venue in stops {
            let going = passengers.filter { boardedAt[ObjectIdentifier($0)] == venue }
            caption = "The S.S. Big Top sails back to \(venue.theName)…"
            tentFlying = true
            sound.hum(true)
            try await sleep(2)
            try await sceneChange {
                self.dockScene(venue)
                self.show([])
            }
            caption = "Back at \(venue.theName) to drop off \(going.count) \(going.count == 1 ? "passenger" : "passengers")."
            try await sailIn()
            try await extendGangway()
            try await leaveShip([greeter], to: [Stage.greetX[0]])
            greeter.facing = -1
            caption = "\(ListFormatter.localizedString(byJoining: going.map(\.id))) \(going.count == 1 ? "comes" : "come") down the gangway — still alien clowns!"
            try await leaveShip(going, to: going.indices.map { Stage.greetX[1] + 40 + Double($0) * 42 })
            for p in going { p.facing = -1 }
            try await say(greeter, "Thanks for cruising with us! Remember — it wears off in eight hours!", 2.8)
            try await say(going.randomElement()!, overnight ? ["Best sleepover EVER!", "Thanks for the bunk beds! Honk honk!", "Wait till everybody hears we slept on a clown ship!"].randomElement()!
                                                            : ["Best cruise EVER!", "Thank you! Honk honk!", "Wait till everybody sees us!"].randomElement()!, 2.2)
            for p in going { _ = beginWalk(p, to: 1320, speed: 110) }
            caption = "Off they go!"
            try await sleep(2.4)
            try await boardShip([greeter])
            try await retractGangway()
            sound.honk()
            moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 3)
            try await sleep(2.2)
            for p in going { p.visible = false }
            passengers.removeAll { p in going.contains { $0 === p } }
            customers = []
        }
        caption = "Everyone has been dropped off where they came from."
    }

    /// The quay at `venue`, with the ship out at sea, about to sail in.
    private func dockScene(_ venue: Venue) {
        tentFlying = false
        place = .venue
        self.venue = venue
        unstrap(team)
        customers = []
        chairsStowed = false
        gangwayOut = false
        gangwayT0 = .distantPast
        tentShown = true
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 0)
        cutNow(Stage.full)
    }

    /// The ship sails in along the water and ties up at the quay.
    private func sailIn() async throws {
        moveTent(to: CGPoint(x: Stage.venueTentX, y: Stage.dockY), over: 3.4)
        try await sleep(3.6)
        tentFlying = false
        sound.hum(false)
        sound.honk()
        try await sleep(0.6)
    }

    /// On deck with the chairs folded away: the trip's crew and today's passengers, out at sea or in port.
    private func aboard(sailing: Bool) async throws {
        try await sceneChange {
            self.place = .bigTop
            self.venue = nil
            self.tentShown = false
            self.tentFlying = sailing
            self.chairsStowed = true
            self.customers = []
            let people = self.team + self.recruits + self.passengers
            for (p, x) in zip(people, Stage.deckX(people.count)) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
                p.seated = false
            }
            (self.leader.x0, self.leader.x1, self.leader.moveDur, self.leader.facing) = (Stage.controlX, Stage.controlX, 0, -1)
            self.leader.place(height: 0)
            self.show(people + [self.leader])
            self.cutNow(Stage.full)
        }
        sound.hum(sailing)
    }

    /// The tent takes them home: the transformation fades 50%, then one minute later it's gone.
    /// `gather` sends everyone to the pink button afterwards; `stayedHome` were waiting in the house.
    /// `waiting` stands in the front yard as the tent lands, gasping `waitingLines` as it arrives and beams them down;
    /// `landing` runs once everyone is on the ground.
    private func comeHome(first: Bool, gather: Bool = true, stayedHome: [Person] = [], waiting: Person? = nil,
                          waitingLines: (tent: String, beam: String)? = nil,
                          landing: () async throws -> Void = {}) async throws {
        let team = team
        // Whoever does the talking: Mom if she went, otherwise a grown-up, otherwise her oldest girl.
        let lead = team.contains { $0 === deidre } ? deidre : team.first { !$0.isKid } ?? (team.contains { $0 === kelly } ? kelly : team[0])
        let other = team.first { $0 !== lead && !$0.isKid } ?? team.first { $0 !== lead } ?? lead
        caption = "The S.S. Big Top sails for home with the \(team.count == 4 ? "four" : "three") of them aboard."
        tentFlying = true
        sound.hum(true)
        try await sleep(2.2)

        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.customers = []
            self.tentFlying = false
            self.tentShown = true
            self.gangwayOut = false
            self.gangwayT0 = .distantPast
            self.chairsStowed = false
            self.show(stayedHome + (waiting.map { [$0] } ?? []))
            for (p, x) in zip(stayedHome, Stage.livingX.reversed()) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
            if let waiting { (waiting.x0, waiting.x1, waiting.moveDur, waiting.facing) = (40, 40, 0, 1) }
            self.moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 0)
            self.cutNow(Stage.full)
        }
        caption = waiting.map { "Home again! \($0.id) is in the front yard, waiting." } ?? "Home again! The ship pulls up alongside the house."
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.dockY), over: 2.4)
        if let waiting, let lines = waitingLines {
            try await sleep(0.9)
            waiting.mood = .shocked
            shout([waiting], lines.tent, 1.6)
            try await sleep(1.6)
        } else {
            try await sleep(2.5)
        }
        sound.hum(false)
        sound.honk()
        try await look(at: Stage.yardView)
        if let waiting, let lines = waitingLines { shout([waiting], lines.beam, 2.4) }
        try await extendGangway()
        try await leaveShip(team + [leader], to: (team.count > 3 ? [100] + Stage.yardLine : Stage.yardLine) + [330])
        // Anyone who came aboard from the shore here gets off at the house too — still alien clowns.
        let neighbors = passengers
        if !neighbors.isEmpty {
            caption = "The passengers who came aboard from the shore come down the gangway too — still alien clowns!"
            try await leaveShip(neighbors, to: neighbors.indices.map { 90 - Double($0) * 34 })
            for p in neighbors { p.facing = -1 }
            try await say(neighbors.randomElement()!, ["Thanks for the cruise! Honk honk!", "Best cruise EVER!", "Wait till the neighbors see us!"].randomElement()!, 2.4)
            for p in neighbors { _ = beginWalk(p, to: -160, speed: 110) }
            try await sleep(2.6)
            for p in neighbors { p.visible = false }
            passengers = []
        }
        try await payRecruits(lead: lead)
        try await landing()
        leader.facing = -1
        try await say(leader, "Now that we have brought you home, your transformation will wear off.", 3.2)
        try await say(leader, "First you change back 50%. Then one minute later, back to normal. Toodle-oo!", 3.6)
        try await boardShip([leader])
        try await retractGangway()
        sound.honk()
        caption = "The cruise ship sails away…"
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 2.6)
        try await sleep(2.7)
        tentShown = false
        sound.hum(false)
        for p in team { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 200, height: 250))

        for p in team { p.fade(to: 0.5, over: 2.5) }
        sound.shimmer()
        caption = "…and they change back 50 percent!"
        try await sleep(2.8)
        if let kid = team.first(where: \.isKid) {
            try await say(kid, "Look! I'm only half a clown now!", 2.4)
        } else {
            try await say(other, "Look at us — we're only half clown now!", 2.4)
        }
        try await say(lead, "One more minute and we'll be back to normal.", 2.4)

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
        try await say(lead, "We're ourselves again!", 2)

        let profit = dayProfit
        try await say(other, "We took in $\(dayEarned) in fares today!", 2.2)
        if dayFees == 0 {
            try await say(lead, "No docking fees today — just a lovely day at sea!", 2.6)
        } else if profit > 0 {
            try await say(lead, "That's $\(profit) profit after the docking fees!", 2.6)
        } else if profit == 0 {
            try await say(lead, "We broke even on the docking fees.", 2.4)
        } else {
            try await say(lead, "We lost $\(-profit) on the docking fees… but it sure was fun!", 2.8)
        }
        guard gather else { return }

        try await look(at: Stage.full)
        if first {
            caption = "Back in the house, they see a glowing pink button — with a note on it!"
            buttonShown = true
            try await gatherAtButton()
            try await say(jen, "There's a note on it!", 1.8)
            card = .note
            cardUntil = .now + 10
            try await sleep(10.2)
            try await say(deidre, "So we can do it again and make more money!", 2.6)
            try await say(kelly, "And next time we get to pick what type of clown we are!", 2.8)
        } else {
            caption = "The glowing pink button is still waiting in the living room."
            try await gatherAtButton()
        }
    }

    /// Rita, Sam and Tammy work every cruise too, so they get a fair share: the day's profit is split evenly among
    /// everyone who worked it. They come down the gangway for it and go back aboard.
    private func payRecruits(lead: Person) async throws {
        guard !recruits.isEmpty else { return }
        let workers = team.count + recruits.count
        let each = max(0, dayProfit / workers)
        guard each > 0 else { return }
        let total = each * recruits.count
        let names = ListFormatter.localizedString(byJoining: recruits.map(\.id))
        caption = "\(names) worked the cruise too, so the profit is split evenly \(workers) ways."
        try await leaveShip(recruits, to: [286, 362, 404])
        for p in recruits { p.facing = -1 }
        try await say(lead, "\(names) — here's your fair share: $\(each) each!", 2.8)
        cash -= total
        cashPop = ("-$\(total) to the crew", .now, 362)
        sound.pay()
        try await say(recruits[0], "Thanks, \(lead.id)! Best job we ever had!", 2.4)
        try await boardShip(recruits)
    }

    /// Everyone walks into the living room and stands round the pink button.
    private func gatherAtButton() async throws {
        try await walkAll(zip(cast, Stage.buttonSpots).map { ($0, $1) }, speed: 140)
        (deidre.facing, kelly.facing, jen.facing) = (1, -1, -1)
        try await look(at: Stage.shot(centerX: 520, height: 250))
    }

    /// All three go to their rooms; night falls and they sleep.
    private func goToBed() async throws {
        try await look(at: Stage.full)
        try await walkAll(zip(cast, Stage.roomX).map { ($0, $1) }, speed: 130)
        for p in cast { p.facing = 0 }
        try await sleep(0.4)
        try await sceneChange {
            self.night = true
            for p in self.cast {
                p.visible = false
                self.sleeping.insert(p.id)
            }
        }
        try await sleep(4.5)
    }

    /// Morning: everyone is up and standing by her bed.
    private func wakeUp() {
        night = false
        sleeping = []
        // Only Mom and the girls are home in the morning.
        show(cast)
        for (p, x) in zip(cast, Stage.roomX) {
            (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
            p.visible = true
        }
        cutNow(Stage.full)
    }

    /// After every second trip one of the women goes shopping and makes a deposit at the bank.
    /// When she comes home it gets dark, they all get some rest, and they can go again the following morning.
    private func restUntilMorning() async throws {
        // Mom does the shopping and the banking.
        let shopper = deidre
        let others = cast.filter { $0 !== shopper }
        try await say(shopper, "What a day! I'm going shopping, and I'll put our money in the bank.", 3.2)
        shout(others, "See you soon!", 1.6)
        try await sleep(1.8)
        try await look(at: Stage.full)
        caption = "\(shopper.id) heads out the front door."
        try await walk(shopper, to: -60, speed: 170)

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
        let wheels = try await visitShops(shopper)

        // Home again, and it gets dark.
        try await sceneChange {
            self.place = .house
            self.show(self.cast)
            (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
            if let wheels {
                // She brings the new wheels home herself.
                shopper.visible = false
                self.vehicles.insert(wheels)
                self.arriving = wheels
                self.rider = wheels == .scooter ? shopper : nil
                self.arriveT0 = .now + 0.8
            }
        }
        if let wheels {
            caption = wheels == .car ? "\(shopper.id) drives home in their new car!" : "\(shopper.id) rides home on their new scooter!"
            sound.hum(true)
            try await sleep(Self.arriveDur + 0.9)
            sound.hum(false)
            sound.honk()
            let spot = wheels == .car ? Stage.carX + 80 : Stage.scooterX + 40
            arriving = nil
            rider = nil
            (shopper.x0, shopper.x1, shopper.moveDur) = (spot, spot, 0)
            shopper.visible = true
            for p in others { p.facing = -1 }
            shout(others, wheels == .car ? "A CAR!" : "A SCOOTER!", 1.8)
            try await sleep(2)
        } else {
            caption = "\(shopper.id) comes home with the groceries."
        }
        try await walk(shopper, to: 440, speed: 150)
        shopper.carrying = false
        shopper.groceries = false
        shopper.facing = 1
        try await say(shopper, "I'm back! The groceries are in, and \(bank > 0 ? "we have $\(bank) in the bank" : "the bills are paid").", 3)
        if let wheels {
            try await say(shopper, wheels == .car ? "And the car is all ours — paid for out of our savings!" : "And the scooter is all ours — paid for out of our savings!", 3)
            let other = deidre === shopper ? others[0] : deidre
            try await say(other, wheels == .car ? (other === deidre ? "A car again! And nobody can repossess this one!" : "Nobody can repossess this one!")
                                                : "No more walking into town!", 2.8)
        }
        try await sceneChange { self.night = true }
        caption = "It gets dark, and they all get some rest."
        try await say(others[0], "It's dark already! Let's all get some rest.", 2.6)
        nights += 1
        let firstNight = nights == 1
        if firstNight { try await moveOn() }
        try await goToBed()

        try await sceneChange {
            self.place = .house
            self.wakeUp()
        }
        caption = "The following morning…"
        sound.chime()
        try await sleep(1.2)
        try await say(others[1], "Good morning, Mommy! I feel so rested!", 2.2)
        if firstNight { try await say(deidre, "I slept like a baby. First morning of my new life!", 2.8) }
        try await say(shopper, "Shall we do it again?", 1.8)
        try await gatherAtButton()
    }

    /// The middle of `p`'s head and its radius, wherever she is standing or sitting.
    private func headOf(_ p: Person) -> (c: CGPoint, r: Double) {
        let pose = Pose(p, feet: CGPoint(x: p.x(at: .now), y: Stage.floorY), facing: p.facing, now: .now)
        return (pose.head, pose.hr)
    }

    /// The first night home, before bed, Deidre thinks about Brad and Amber one last time and decides to move on.
    private func moveOn() async throws {
        try await say(deidre, "Wait — before we sleep, there's something I need to say.", 2.6)
        deidre.facing = 1
        try await look(at: Stage.shot(centerX: deidre.x1, height: 250))
        try await say(deidre, "I've been thinking about Brad and Amber all day.", 2.6)
        try await say(deidre, "I could stay angry at them forever… but what's the point?", 2.8)
        try await say(deidre, "I walked off my job, lost my car and my boyfriend in one day — and look at us now!", 3.2)
        try await say(deidre, "Brad and Amber deserve each other. I'm moving on.", 2.8)
        shout([kelly, jen], "Good for you, Mom!", 2)
        try await sleep(2.2)
        try await say(deidre, "A new job, my two girls, a new life. Goodnight, sweethearts!", 2.8)
        caption = "Deidre lets it all go, and they all go to bed."
    }

    /// Further along Main Street: the ship-supply shop, where cash buys upgrades for the S.S. Big Top, and the dealer,
    /// where the savings in the bank can buy a scooter or another car. Returns whatever she bought to take home.
    private func visitShops(_ shopper: Person) async throws -> Vehicle? {
        try await sceneChange {
            self.place = .shops
            (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
        }
        caption = "Further along Main Street: Shipshape Cruise Upgrades."
        try await walk(shopper, to: Stage.boutiqueDoorX, speed: 140)
        shopper.facing = 0
        func affordable() -> Bool {
            ShipUpgrade.allCases.contains { !upgrades.contains($0) && $0.price <= spendingMoney }
        }
        if upgrades.count == ShipUpgrade.allCases.count {
            try await say(shopper, "The S.S. Big Top already has every upgrade they sell!", 2.6)
        } else if !affordable() {
            try await say(shopper, "No ship upgrades today — we need the rest for a docking fee.", 2.8)
        } else {
            try await say(shopper, "Ooh, cruise ship upgrades! Let's fix up the S.S. Big Top.", 2.6)
            shopper.visible = false
            caption = "\(shopper.id) looks over the ship upgrades. What should the S.S. Big Top get?"
            var bought: [ShipUpgrade] = []
            choosingUpgrade = shopper
            while affordable() {
                let pick = await withCheckedContinuation { cont in upgradePick = cont }
                try Task.checkCancellation()
                guard let pick else { break }
                cash -= pick.price
                upgrades.insert(pick)
                bought.append(pick)
                cashPop = ("-$\(pick.price)", .now, Stage.boutiqueDoorX)
                sound.pay()
                caption = "\(shopper.id) orders \(pick.phrase) for $\(pick.price)."
            }
            choosingUpgrade = nil
            try await sleep(bought.isEmpty ? 0.4 : 1.4)
            shopper.visible = true
            shopper.facing = 0
            if bought.isEmpty {
                caption = "\(shopper.id) decides to save her money."
                try await say(shopper, "Just looking today.", 1.8)
            } else {
                caption = "The S.S. Big Top will be fitted with \(ListFormatter.localizedString(byJoining: bought.map(\.phrase)))."
                try await say(shopper, bought.contains(.deckChairs)
                              ? "Now the ship can take \(capacity) passengers. Wait till the girls see it!"
                              : "Wait till the girls see the ship!", 2.6)
            }
        }

        // The dealer next door
        let forSale = Vehicle.allCases.filter { !vehicles.contains($0) }
        var wheels: Vehicle?
        if let cheapest = forSale.min(by: { $0.price < $1.price }) {
            caption = "Next door: Wheels & Deals."
            try await walk(shopper, to: Stage.dealerDoorX, speed: 140)
            shopper.facing = 0
            if bank < cheapest.price {
                try await say(shopper, "A \(cheapest.name.lowercased()) is $\(cheapest.price). We have $\(bank) in the bank — one day!", 3.2)
            } else {
                try await say(shopper, "We have $\(bank) saved. That's enough for some wheels!", 2.8)
                caption = "They have $\(bank) in the bank. Buy a scooter, or perhaps another car?"
                wheels = await withCheckedContinuation { cont in
                    vehiclePick = cont
                    choosingVehicle = true
                }
                try Task.checkCancellation()
                if let wheels {
                    shopper.visible = false
                    bank -= wheels.price
                    cashPop = ("-$\(wheels.price) from savings", .now, Stage.dealerDoorX - 60)
                    sound.pay()
                    caption = "\(shopper.id) buys a \(wheels.name.lowercased()) for $\(wheels.price) out of their savings. Left in the bank: $\(bank)."
                    try await sleep(3)
                    return wheels
                }
                caption = "\(shopper.id) leaves the savings where they are."
                try await say(shopper, "Not today. Let's keep saving.", 2.2)
            }
        }
        try await walk(shopper, to: Stage.W + 60, speed: 150)
        return wheels
    }

    private static let groceryBill = 35
    private static let keepForSetup = 200

    // MARK: A kid's computer to the rescue

    /// The kids who find the Clowns of Poker on their computers, taking turns, and their moms.
    private static func makeRescueKid(_ n: Int) -> (kid: Person, mom: Person) {
        let looks: [(kid: String, girl: Bool, mom: String, skin: RGB, kidHair: RGB, kidStyle: HairStyle, momHair: RGB, momStyle: HairStyle,
                     kidShirt: RGB, momShirt: RGB)] = [
            ("Maddie", true, "Joanne", RGB(r: 0.97, g: 0.82, b: 0.70), RGB(r: 0.85, g: 0.62, b: 0.30), .pigtails,
             RGB(r: 0.80, g: 0.58, b: 0.28), .bob, RGB(r: 0.95, g: 0.45, b: 0.55), RGB(r: 0.40, g: 0.55, b: 0.80)),
            ("Tyler", false, "Sharon", RGB(r: 0.62, g: 0.44, b: 0.32), RGB(r: 0.10, g: 0.08, b: 0.06), .short,
             RGB(r: 0.12, g: 0.09, b: 0.07), .curly, RGB(r: 0.25, g: 0.65, b: 0.40), RGB(r: 0.85, g: 0.55, b: 0.25)),
            ("Becky", true, "Lorraine", RGB(r: 0.92, g: 0.74, b: 0.60), RGB(r: 0.35, g: 0.20, b: 0.10), .ponytail,
             RGB(r: 0.30, g: 0.18, b: 0.10), .long, RGB(r: 0.55, g: 0.75, b: 0.95), RGB(r: 0.70, g: 0.30, b: 0.50)),
        ]
        let l = looks[n % looks.count]
        let kid = Person(l.kid, height: 118, headScale: 0.15, skin: l.skin, hair: l.kidHair, style: l.kidStyle,
                         shirt: l.kidShirt, pants: RGB(r: 0.30, g: 0.42, b: 0.68), kid: true, female: l.girl, x: Stage.kidSeatX)
        let mom = Person(l.mom, height: 160, skin: l.skin, hair: l.momHair, style: l.momStyle,
                         shirt: l.momShirt, pants: RGB(r: 0.28, g: 0.28, b: 0.38), shorts: false, x: Stage.kidMomX)
        for p in [kid, mom] { p.visible = false }
        return (kid, mom)
    }

    /// Not enough cash for a docking fee: the Clowns of Poker downloads itself onto a kid's computer across town.
    /// Up to three kids get a try, one after another, until one makes it to game 10.
    private func kidRescue() async throws {
        var tries = 0
        while cash < Venue.cheapestFee && tries < 3 {
            _ = try await kidComputer(first: tries == 0)
            tries += 1
        }
        if cash < Venue.cheapestFee {
            try await say(deidre, "Nobody made it to game 10 this time. We're still short for a docking fee…", 3)
        }
    }

    /// One kid plays the Clowns of Poker on the computer. At game 10 the S.S. Big Top pulls up behind the house with
    /// Deidre and the girls aboard: the kid gets a quarter of the credits left on the machine and the family gets the rest.
    /// The kid is transformed, plays a game of cards for fun, and is beamed home — and tells Mom the whole story, just
    /// before a flying mini saucer comes in from the ship and transforms her too. Returns whether the kid made it.
    private func kidComputer(first: Bool) async throws -> Bool {
        let (kid, mom) = Self.makeRescueKid(rescues)
        rescues += 1
        let spots = cast.map { ($0, $0.x(at: .now), $0.facing) }
        if first {
            try await say(kelly, "What do we do now, Mom?", 2)
            try await say(jen, "Maybe the Clowns of Poker can help us out!", 2.4)
        }
        family = [mom, kid]
        rescueKidName = kid.id
        try await sceneChange {
            self.place = .kidHouse
            self.venue = nil
            self.night = false
            self.tentShown = false
            self.tentFlying = false
            self.gangwayOut = false
            self.gangwayT0 = .distantPast
            self.beamOn = false
            self.beamT0 = .distantPast
            self.pokerScreen = ""
            self.show([kid, mom])
            (kid.x0, kid.x1, kid.moveDur, kid.facing) = (Stage.kidSeatX, Stage.kidSeatX, 0, 1)
            (mom.x0, mom.x1, mom.moveDur, mom.facing) = (Stage.kidMomX, Stage.kidMomX, 0, 1)
            self.cutNow(Stage.full)
        }
        caption = "Meanwhile, across town, \(kid.id) is in the bedroom, and \(kid.id)'s mom, \(mom.id), is making breakfast."
        try await sleep(3)
        try await look(at: Stage.shot(centerX: Stage.kidDeskX - 40, height: 260))
        sound.chime()
        pokerScreen = "DOWNLOAD\nCOMPLETE"
        try await say(kid, "Huh? Something just downloaded itself onto my computer…", 2.6)
        kid.mood = .shocked
        try await say(kid, "\"The Clowns of Poker\"? Cool! I have to try this!", 2.6)
        kid.mood = .happy
        try await look(at: Stage.shot(centerX: Stage.kidMomX + 20, height: 260))
        try await say(mom, "\(kid.id)! Breakfast in twenty minutes!", 2.2)
        try await say(kid, "Okay, Mom!", 1.4)

        caption = "\(kid.id) plays the Clowns of Poker on the computer. Play the max bet all the way through to make it to game 10!"
        let session = PokerSession(player: kid.id, kidComputer: true, muted: muted)
        session.tenLine = "You are very, very good, \(kid.id)! You have made it to game 10. Go and look out your back window!"
        session.onSound = { [weak self] s in
            switch s {
            case .card: self?.sound.shutter()
            case .coin: self?.sound.pay()
            case .chime: self?.sound.chime()
            }
        }
        // On a kid's computer the sitting ends either way: game 10, or out of credits / off the max bet.
        session.onEnd = { [weak self, weak session] ending in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(ending == .qualified ? 7 : 4))
                guard let self, let session, self.poker === session else { return }
                self.finishPoker()
            }
        }
        poker = session
        pokerPlaying = true
        session.begin()
        await withCheckedContinuation { cont in pokerDone = cont }
        try Task.checkCancellation()
        poker = nil
        try await look(at: Stage.shot(centerX: Stage.kidDeskX - 40, height: 260))

        guard session.ending == .qualified else {
            pokerScreen = "GAME\nOVER"
            kid.mood = .glum
            try await say(kid, session.ending == .notMaxBet ? "Aww — I didn't play the max bet every hand. Game over!"
                                                             : "Aww, I ran out of credits. Game over!", 2.8)
            try await say(kid, "Oh well. Time for breakfast!", 2)
            kid.mood = .happy
            family = []
            try await backHome(spots, view: Stage.shot(centerX: 520, height: 250))
            pokerScreen = ""
            try await say(deidre, "Still no money for the docking fee…", 2.4)
            return false
        }

        let leftover = max(session.credits, 0)
        let kidShare = leftover / 4
        let familyShare = leftover - kidShare
        pokerScreen = "GAME 10\nLOOK OUT\nBACK!"
        kid.mood = .beaming
        try await say(kid, "I made it to game 10!", 2)
        sound.honk()
        caption = "A ship's horn sounds, right behind the house!"
        kid.mood = .shocked
        try await say(kid, "A ship's horn? Out back?", 2)
        kid.mood = .happy
        caption = "\(kid.id) tiptoes past the kitchen and out the back door…"
        try await look(at: Stage.full)
        tentShown = true
        tentFlying = true
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 0)
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.dockY), over: 4)
        sound.hum(true)
        try await walk(kid, to: 378, speed: 165)
        kid.facing = -1
        tentFlying = false
        sound.hum(false)
        sound.honk()
        caption = "The S.S. Big Top pulls up on the water behind \(kid.id)'s house!"
        try await look(at: Stage.yardView)
        kid.mood = .shocked
        try await say(kid, "A CRUISE SHIP! Right behind my house!", 2.4)
        caption = "The gangway slides out, and down come an alien clown, Deidre, Kelly and Jen."
        try await extendGangway()
        try await leaveShip([leader] + cast, to: [322, 150, 200, 250])
        leader.facing = 1
        for p in cast { p.facing = 1 }
        kid.mood = .happy
        sound.honk()
        try await say(leader, "HONK HONK! Congratulations, \(kid.id) — you made it to game 10!", 2.8)
        try await look(at: Stage.shot(centerX: 290, height: 280))
        try await say(deidre, "Hi, \(kid.id)! I'm Deidre, and these are my girls, Kelly and Jen.", 3)
        try await say(deidre, "We ran out of money for our docking fees — you just saved our cruise ship business!", 3.2)
        try await say(leader, "There were \(leftover) credits left on your machine. One quarter of it is yours, \(kid.id)!", 3.2)
        if kidShare > 0 {
            cashPop = ("$\(kidShare) for \(kid.id)", .now, kid.x(at: .now))
            sound.pay()
            caption = "\(kid.id) gets one quarter of what was left on the machine: $\(kidShare)."
            try await say(kid, "$\(kidShare)? For me? Wow!", 2.2)
        }
        if familyShare > 0 {
            cash += familyShare
            cashPop = ("+$\(familyShare)", .now, deidre.x(at: .now))
            sound.pay()
            caption = "The other three quarters — $\(familyShare) — go to Deidre for the docking fees."
            try await say(jen, "And $\(familyShare) for us! Thank you, \(kid.id)!", 2.6)
        }
        try await say(leader, "Game 10 is a cruise, and you get to be an alien clown! All aboard!", 3)
        try await say(kid, "Mom's busy making breakfast… I'll be right back!", 2.4)
        caption = "Everyone walks up the gangway onto the ship."
        try await boardShip([kid] + cast + [leader])
        try await retractGangway()
        sound.honk()
        tentFlying = true
        sound.hum(true)
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 3)
        try await sleep(2.4)

        // Aboard: the chairs.
        try await sceneChange {
            self.place = .bigTop
            self.venue = nil
            self.tentShown = false
            self.chairsStowed = false
            self.seat([kid], chairs: [1])
            for (p, x) in zip(self.crew, Stage.crewX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
            }
            (self.leader.x0, self.leader.x1, self.leader.facing) = (Stage.consoleX - 45, Stage.consoleX - 45, -1)
            for (p, x) in zip(self.cast, Stage.standByX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
                p.seated = false
                p.place(height: 0)
            }
            self.show(self.crew + self.cast + [kid])
            self.cutNow(Stage.chairsView)
        }
        tentFlying = false
        sound.hum(false)
        caption = "Aboard the S.S. Big Top, \(kid.id) is shown to a chair…"
        try await strap([kid])
        try await say(kid, "Seat belts? This is the best game 10 ever!", 2.4)
        try await say(leader, "Pick the type of alien clown you want to be!", 2.4)
        let picks = try await pickKinds([kid])
        let kind = picks[0].1
        try await look(at: Stage.full)
        try await say(leader, "Just relax and enjoy it.", 2)
        try await runMachine(picks, presser: leader, change: Machine.customerChange,
                             tingleLine: (kid, "Hee hee! It tickles!"), legsStartLine: (kid, "Look at my big clown shoes!"),
                             bodyLine: (jen, "Here comes the sparkly suit!"),
                             faceShouts: (kid, [("Here comes my face…", 15), ("Wheeeeee!", 17)]), beamOnShout: 1)
        try await look(at: Stage.full)
        try await say(leader, "The transformation is complete. Have a look!", 2.6)
        try await showMirror([kid], caption: "\(kid.id) sees an alien clown looking back!", seconds: 3)
        try await look(at: Stage.chairsView)
        try await say(kid, "I'm \(kind.name)! Honk honk!", 2.2)
        if let line = kind.noseLine { try await say(kid, line, 2) }
        try await snap([kid])
        unstrap([kid])
        totalTransformed += 1

        // A game of cards on deck, just for fun. You play the kid's seat.
        let game = CasinoGame.funGames.randomElement()!
        try await sceneChange {
            self.place = .bigTop
            self.tentShown = false
            self.tentFlying = true
            self.chairsStowed = true
            let people = [kid] + self.cast
            for (p, x) in zip(people, Stage.deckX(people.count)) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
                p.seated = false
            }
            (self.leader.x0, self.leader.x1, self.leader.moveDur, self.leader.facing) = (Stage.controlX, Stage.controlX, 0, -1)
            self.leader.place(height: 0)
            self.show(people + [self.leader])
            self.cutNow(Stage.full)
        }
        sound.hum(true)
        try await say(leader, "And now a game of \(game.name) on deck — just for fun!", 2.8)
        try await say(kid, "Deal me in!", 1.6)
        let won = try await funTable(game, me: kid, others: Array((cast + [leader]).prefix(game.funSeats - 1)))
        let kidWon = won.contains { $0 === kid }
        try await say(kid, kidWon ? "I won! Best morning ever!" : "That was so much fun!", 2.2)
        try await say(leader, "Time to beam you home, \(kid.id)!", 2.4)
        try await say(deidre, "Thank you again, \(kid.id). You saved the day!", 2.4)

        // Beamed home, still an alien clown.
        caption = "The S.S. Big Top sails back to \(kid.id)'s house…"
        try await sleep(1.6)
        try await sceneChange {
            self.place = .kidHouse
            self.tentShown = true
            self.tentFlying = true
            self.gangwayOut = false
            self.gangwayT0 = .distantPast
            self.chairsStowed = false
            self.pokerScreen = ""
            self.moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 0)
            self.show([mom])
            (mom.x0, mom.x1, mom.moveDur, mom.facing) = (Stage.kidMomX, Stage.kidMomX, 0, 1)
            self.cutNow(Stage.full)
        }
        caption = "…and pulls up behind the house again."
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.dockY), over: 3)
        try await sleep(3.2)
        tentFlying = false
        sound.hum(false)
        sound.honk()
        try await look(at: Stage.yardView)
        caption = "A pink beam shines down from the deck…"
        beamOn = true
        beamT0 = .now
        sound.shimmer()
        try await sleep(0.9)
        shout([kid], "Wheeeee!", 2)
        try await leaveShip([kid], to: [372], speed: 80)
        kid.facing = -1
        beamOn = false
        beamT0 = .now
        caption = "\(kid.id) is beamed home — still an alien clown!"
        try await say(kid, "Bye, everybody! Honk honk!", 2)

        // The whole story, in the kitchen.
        caption = "\(kid.id) goes in the back door to find Mom."
        try await look(at: Stage.full)
        try await walk(kid, to: Stage.kidMomX - 58, speed: 140)
        kid.facing = 1
        try await look(at: Stage.shot(centerX: Stage.kidMomX - 30, height: 250))
        try await say(kid, "Mom! I'm back!", 1.6)
        mom.facing = -1
        mom.mood = .shocked
        try await say(mom, "\(kid.id)?! Is that YOU? What on earth happened to you?", 3)
        caption = "\(kid.id) tells \(mom.id) the whole story."
        try await say(kid, "The Clowns of Poker downloaded itself onto my computer, all by itself!", 3)
        try await say(kid, "I played the max bet every hand, all the way to game 10!", 2.8)
        try await say(kid, "Then a cruise ship full of alien clowns pulled up behind our house!", 3)
        try await say(kid, "Deidre and her girls, Kelly and Jen, were aboard. They ran out of money for the docking fees, so I saved them!", 3.6)
        if kidShare > 0 {
            kid.reachTo = CGPoint(x: Stage.kidMomX - 26, y: Stage.floorY - 52)
            sound.pay()
            try await say(kid, "There were \(leftover) credits left on the machine, and I got one quarter — $\(kidShare)! Here, Mom!", 3.4)
            kid.reachTo = nil
        }
        try await say(kid, "They put me in a chair, and a machine turned me into \(kind.name) — from my feet all the way up to my face!", 3.6)
        try await say(kid, "We played \(game.name) on the deck, just for fun\(kidWon ? " — and I won" : "")!", 2.8)
        try await say(kid, "And then they beamed me home in a big pink beam!", 2.6)
        try await say(mom, "Feet first… a pink beam… \(kid.id), that is the wildest story I have ever heard!", 3.2)
        mom.mood = .happy
        try await say(mom, "But you do look adorable\(kidShare > 0 ? " — and $\(kidShare)!" : ".")", 2.6)

        // A flying mini saucer comes in from the ship for Mom.
        sound.honk()
        caption = "A horn honks outside the kitchen window…"
        try await say(kid, "Mom, look! A flying mini saucer is coming from the ship — I think it's for you!", 3.2)
        mom.mood = .shocked
        try await say(mom, "For ME?", 1.4)
        let momPick = try await pickKinds([mom], silent: true)
        try await look(at: Stage.full)
        miniTentFrom = CGPoint(x: Stage.yardTentX + 40, y: Stage.dockY - 110)
        caption = "Whirr… a mini saucer flies off the S.S. Big Top, in through the back door, and over \(mom.id)'s head!"
        try await miniSaucers(momPick, flight: SaucerRun.longFlight, home: "the ship",
                              chargeLines: [(mom, "It's shining a light all over me…"), (kid, "Here it comes, Mom — just like me!")],
                              lines: ["It's starting at my feet!", "My clothes are turning into a sparkly suit!", "Now my face… Wheeeeee!"])
        miniTentFrom = nil
        try await look(at: Stage.shot(centerX: Stage.kidMomX - 30, height: 250))
        mom.mood = .beaming
        try await say(mom, reaction(momPick[0].1), 2.4)
        if let line = momPick[0].1.noseLine { try await say(mom, line, 2) }
        mom.mood = .happy
        try await say(mom, "Now we match, \(kid.id)!", 2)
        try await say(kid, "Alien clowns together! Honk honk!", 2.2)
        try await snap([mom])
        totalTransformed += 1
        try await look(at: Stage.full)
        sound.honk()
        caption = "The S.S. Big Top sounds its horn and sails away. (It wears off in eight hours!)"
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 3)
        try await sleep(3.1)
        tentShown = false
        family = []

        // The ship drops Deidre and the girls back home.
        try await backHome(spots, view: Stage.shot(centerX: 520, height: 250))
        caption = "The S.S. Big Top drops Deidre and the girls back home."
        try await sleep(1.6)
        if cash >= Venue.cheapestFee {
            try await say(deidre, "Thanks to \(kid.id), we have $\(cash) — enough for the docking fees again!", 3)
            try await say(jen, "Let's do it again!", 1.6)
        } else {
            try await say(deidre, "Thanks to \(kid.id) we have $\(cash) — but it's still not quite enough for a docking fee.", 3.2)
        }
        return true
    }

    // MARK: An aunt and a cousin

    /// The morning after every odd night, one of Deidre's sisters (Linda, then Carol, then Rosa, in turn) comes over
    /// to take Deidre on an errand and leaves her little girl with Kelly and Jen. The girls take their cousin along to
    /// earn some money for her mother, and she gets a third of the profit. When the sisters get home the aunt has a go
    /// too — with no idea what's coming — while Deidre and one of the girls stay behind. Then aunt and cousin go home.
    private func babysitting() async throws {
        // The aunts take turns: Linda, then Carol, then Rosa, and round again. `daughter` is the sister who goes
        // out on the errand — Deidre — and her girls mind their little cousin.
        let familyKey = ["Kelly", "Jen", "Deidre"][familyVisits % 3]
        familyVisits += 1
        let daughter = deidre
        let (friendA, friendB) = (kelly, jen)
        let age = Int.random(in: 4...6)
        family = Self.makeFamily(age: age, for: familyKey)
        let (mom, sophie) = (family[0], family[1])
        let errand = ["DMV to renew your license", "dentist", "furniture store to pick out a new couch", "eye doctor"].randomElement()!

        // Ding-dong
        try await look(at: Stage.full)
        sound.chime()
        caption = "Ding-dong! It's Deidre's sister, Aunt \(mom.id), with her little girl \(sophie.id), who is \(age)."
        for p in family { p.visible = true }
        for (p, x) in [(daughter, 505.0), (friendA, 565), (friendB, 615)] { _ = beginWalk(p, to: x, speed: 120) }
        try await walkAll([(mom, 445), (sophie, 472)], speed: 150)
        for p in family { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(daughter, "\(mom.id)! Hi, \(sophie.id)!", 2)
        try await say(sophie, "Hi, Aunt \(daughter.id)! Hi, Kelly! Hi, Jen!", 2.2)
        try await say(mom, "Ready, sis? I'm driving you to the \(errand).", 2.8)
        try await say(mom, "\(friendA.id), \(friendB.id) — could you watch \(sophie.id) for me while we're gone?", 3)
        try await say(friendA, "Of course, Aunt \(mom.id)!", 1.8)
        try await say(friendB, "We'd love to!", 1.6)
        try await say(mom, "Be good, sweetie. We'll be back this afternoon.", 2.6)
        try await say(sophie, "Bye, Mommy! Bye, Aunt \(daughter.id)!", 2)
        caption = "Deidre and her sister head out."
        try await walkAll([(mom, -80), (daughter, -40)], speed: 150)
        mom.visible = false
        daughter.visible = false

        caption = "\(friendB.id) has an idea."
        try await walk(friendB, to: 520, speed: 110)
        friendB.facing = -1
        sophie.facing = 1
        try await look(at: Stage.shot(centerX: 520, height: 230))
        try await say(friendB, "\(sophie.id), how would you like to earn some money for your mother?", 3)
        try await say(sophie, "Yes! Yes! How?", 1.8)
        try await say(friendA, "See this glowing pink button? It calls a cruise ship full of alien clowns!", 3)
        try await say(sophie, "Clowns?! Can I be a clown too?", 2.2)
        try await say(friendB, "You sure can. Let's call the cruise ship!", 2.4)

        // Sophie's trip: she asks the passers-by, one of them takes the money and the other works the machine.
        let (taker, worker) = Bool.random() ? (friendB, friendA) : (friendA, friendB)
        team = [sophie, taker, worker]
        let trio = [friendA, sophie, friendB]
        try await callTheTent(trio, pusher: sophie, caller: friendB, seated: trio)
        try await transformAgain(trio, welcome: "Welcome back! And who's this little one? Everybody pick a type of alien clown!",
                                 legsStartLine: (sophie, "Hee hee! It tickles my toes!"), bodyLine: (friendA, "Here we go again!"))
        try await snap(trio)
        unstrap(trio)
        try await say(leader, "\(sophie.id) will invite the passers-by, \(taker.id) takes the fares, and \(worker.id) works the machine.", 3.4)
        try await cruiseDay()
        try await comeHome(first: false, gather: false)

        // One third of the profit is Sophie's.
        let profit = dayProfit
        let share = max(0, profit / 3)
        if share > 0 {
            caption = "\(sophie.id) gets one third of the profit: $\(share)."
            try await say(friendA, "And \(sophie.id) gets one third of the profit — $\(share), all yours!", 3)
            cash -= share
            cashPop = ("-$\(share) to \(sophie.id)", .now, sophie.x(at: .now))
            sound.pay()
            try await say(sophie, "$\(share)! I can't wait to show Mommy!", 2.6)
        } else {
            try await say(friendA, "No profit to share today, \(sophie.id) — but you were a big help!", 2.8)
            try await say(sophie, "That's okay! It was fun!", 2.2)
        }
        try await look(at: Stage.full)
        try await walkAll([(sophie, 490), (friendA, 565), (friendB, 615)], speed: 140)

        // That afternoon the daughter and her mother come home.
        caption = "That afternoon, Deidre and her sister come home."
        mom.visible = true
        daughter.visible = true
        for p in [mom, daughter] { (p.x0, p.x1, p.moveDur) = (-60, -60, 0) }
        try await walkAll([(mom, 455), (daughter, 428)], speed: 150)
        mom.facing = 1
        daughter.facing = 1
        sophie.facing = -1
        for p in [friendA, friendB] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 500, height: 230))
        try await say(mom, "We're back! Was she good?", 2)
        if share > 0 {
            sophie.reachTo = CGPoint(x: 472, y: Stage.floorY - 52)
            sound.pay()
            try await say(sophie, "Mommy! Look — I earned $\(share) for you!", 2.8)
            sophie.reachTo = nil
            mom.mood = .shocked
            try await say(mom, "$\(share)?! How did you ever get all that money?", 2.8)
        } else {
            try await say(sophie, "Mommy! I had the best day ever!", 2.2)
            mom.mood = .shocked
            try await say(mom, "Really? What did you do all day?", 2.4)
        }
        // Linda gets no explanation — she'll find out once she's up in the ship.
        try await say(sophie, "It's a secret!", 1.8)
        mom.mood = .happy
        try await say(mom, "A secret? \(friendA.id), \(friendB.id) — what have you girls been up to?", 3)
        try await say(taker, "It's easier to show you than to tell you.", 2.4)
        try await say(worker, "Come along with \(sophie.id) and me, and you'll see!", 2.4)
        sophie.facing = 1
        try await say(sophie, "Come with us, Mommy! Please?", 2.2)
        try await say(mom, "Well… now I have to know! All right, I'll come.", 2.6)
        try await say(daughter, "I'll stay behind and put my feet up. You're in for a surprise, sis!", 3)
        try await say(taker, "I'll stay here with Mom. Have fun, you three!", 2.6)

        // The aunt's trip: just her, her little girl and one of Deidre's girls. Nobody tells Linda a thing about the change —
        // all three are strapped in together, and she's game for whatever comes.
        team = [mom, sophie, worker]
        let three = [sophie, mom, worker]   // Linda in the middle chair
        let lines = Self.momLines(mom.id, kid: sophie.id)
        try await callTheTent(three, pusher: sophie, caller: worker, seated: three, newcomer: mom,
                              newcomerLines: (lines.spotTent, lines.beamUp))
        try await look(at: Stage.chairsView)
        try await say(mom, lines.inTent, 2.6)
        try await say(leader, "Welcome back! And who have we here?", 2.4)
        try await say(sophie, "This is my mommy!", 1.8)
        try await say(mom, lines.whatsNext, 2.8)
        try await say(worker, "Just sit back and enjoy it, \(mom.id). You'll love it!", 2.4)
        try await strap(three)
        caption = "Straps snap across all three of them at once!"
        try await say(mom, lines.straps, 2.8)
        let picks = try await pickKinds(three, silent: true)
        let kind = picks[1].1
        try await look(at: Stage.full)
        try await say(leader, "Just relax.", 1.8)
        caption = "The alien clown presses the glowing pink button…"
        // Smiling and loving it the whole way through.
        mom.mood = .happy
        try await runMachine(picks, presser: leader, change: Machine.change,
                             tingleLine: (mom, lines.tingle),
                             legsStartLine: (mom, lines.legs),
                             bodyLine: (mom, lines.body),
                             faceShouts: (mom, [(lines.face, 15), (lines.faceShout, 17)]), beamOnShout: 1)

        // The change is done: she feels her head.
        let (head, hr) = headOf(mom)
        cut(to: Stage.focus(CGPoint(x: head.x, y: head.y + hr * 0.6), height: 170))
        // The straps let go so she can reach up.
        strapped = []
        sound.clunk()
        try await sleep(0.6)
        caption = "\(mom.id) reaches up and feels her head…"
        mom.feelsHead = true
        try await sleep(2.2)
        try await say(mom, lines.headFeel, 3)
        mom.feelsHead = false
        mom.mood = .happy
        try await look(at: Stage.full)
        try await say(leader, "Have a look!", 1.8)
        caption = "The alien clowns lower the big mirror…"
        try await showMirror(three, caption: "…and \(mom.id) sees an alien clown looking back!", calm: [mom])
        try await look(at: Stage.chairsView)
        try await say(mom, reaction(kind), 2.4)
        if let line = kind.noseLine { try await say(mom, line, 2) }
        try await say(sophie, "Mommy, you're a clown just like me!", 2.4)
        try await say(worker, "And people pay us to turn them into clowns too — that's how \(sophie.id) earned the money!", 3.4)
        try await say(mom, lines.secret, 3)
        try await snap(three)
        unstrap(three)
        try await say(leader, "\(mom.id) invites the passers-by, \(sophie.id) takes the fares, and \(worker.id) works the machine.", 3.4)
        try await cruiseDay()
        try await comeHome(first: false, gather: false, stayedHome: [daughter, taker])

        // Linda and Sophie get one third of the profit.
        let momShare = max(0, dayProfit / 3)
        if momShare > 0 {
            caption = "\(mom.id) and \(sophie.id) get one third of the profit: $\(momShare)."
            try await say(friendB, "\(mom.id), you and \(sophie.id) get one third of the profit — $\(momShare)!", 3)
            cash -= momShare
            cashPop = ("-$\(momShare) to \(mom.id) & \(sophie.id)", .now, mom.x(at: .now))
            sound.pay()
            try await say(mom, "$\(momShare)! Thank you, girls!", 2.4)
            try await say(sophie, "We're rich, Mommy!", 2)
        } else {
            try await say(friendB, "No profit to share this time, \(mom.id) — sorry!", 2.6)
            try await say(mom, "Don't be! I wouldn't have missed it.", 2.4)
        }

        // Home time for Linda and Sophie.
        try await look(at: Stage.full)
        try await walkAll([(mom, 445), (sophie, 472), (friendA, 520), (friendB, 565)], speed: 150)
        for p in family { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(sophie, "Did you have fun, Mommy?", 2)
        try await say(mom, lines.bestDay, 2.8)
        try await say(mom, "Thank you for watching \(sophie.id), girls. Come on, sweetie — time to go home.", 3.2)
        try await say(sophie, "Bye! Honk honk!", 1.8)
        caption = "\(mom.id) and \(sophie.id) head home."
        try await walkAll([(mom, -80), (sophie, -50)], speed: 150)
        family = []
        try await walkAll(zip(cast, Stage.livingX).map { ($0, $1) }, speed: 140)
    }

    /// The visit is two trips and ends with another night: after every odd night one of Deidre's sisters
    /// drops off her little girl (Linda, Carol and Rosa take turns).
    private func morningVisit() async throws {
        try await babysitting()
        try await restUntilMorning()
    }

    /// Press the pink button: the ship comes back, and everyone picks her own type of clown.
    /// Sets up the next day. Returns true if that day's cruise has already been played (Brad's business trip),
    /// so the day loop goes straight to the evening.
    private func doItAgain() async throws -> Bool {
        // Every odd day from day 3 on, Brad drops Amber off before his business trip, and she tags along.
        let day = nights + 1
        if day >= 3 && day % 2 == 1 {
            try await bradsBusinessTrip()
            return true
        }
        try await say(deidre, "Let's do it again!", 1.8)
        rotation += 1
        team = (0..<3).map { cast[(rotation + $0) % 3] }
        try await callTheTent(cast, pusher: cast.randomElement()!, caller: kelly, seated: cast)
        try await transformAgain(cast, legsStartLine: (jen, "I feel funny again!"), bodyLine: (kelly, "We're being transformed again!"))
        try await snap(cast)
        unstrap(cast)
        return false
    }

    // MARK: Brad's business trip

    /// The morning of every odd day from day 3 on: Brad is off on a business trip and asks Deidre to keep Amber
    /// company. Amber tags along on the cruise to make some money for Brad — she invites the passers-by, gets
    /// transformed under a mini saucer, and earns a fair share of the day's profit, which she hands Brad when he
    /// picks her up that night.
    private func bradsBusinessTrip() async throws {
        let (brad, amber) = (extras[1], extras[2])
        bradVisits += 1
        let firstVisit = bradVisits == 1
        rotation += 1
        let order = (0..<3).map { cast[(rotation + $0) % 3] }

        try await look(at: Stage.full)
        sound.chime()
        caption = firstVisit ? "Ding-dong! It's Brad — Deidre's ex-boyfriend — with his new girlfriend, Amber."
                             : "Ding-dong! It's Brad and Amber again."
        for (p, x) in [(brad, -80.0), (amber, -50)] {
            p.clown = nil
            p.fade(to: 0, over: 0)
            p.mood = .happy
            (p.x0, p.x1, p.moveDur) = (x, x, 0)
            p.visible = true
        }
        for (p, x) in [(deidre, 505.0), (kelly, 565), (jen, 615)] { _ = beginWalk(p, to: x, speed: 120) }
        try await walkAll([(brad, 440), (amber, 470)], speed: 150)
        for p in [brad, amber] { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        if firstVisit {
            deidre.mood = .shocked
            try await say(deidre, "Brad?! What are you doing here?", 2.2)
            deidre.mood = .happy
            try await say(brad, "Hi, Deidre. I know things ended badly… but I need a favor.", 3)
            try await say(brad, "I'm going away on a business trip today. Could you keep Amber company while I'm gone?", 3.6)
            try await say(amber, "I don't know anybody in town yet, and I hate being all by myself.", 3)
            try await say(deidre, "…All right, Brad. Amber can tag along with us today.", 2.8)
            try await say(kelly, "We work on a cruise ship, Amber — full of alien clowns!", 2.8)
            try await say(amber, "Alien clowns? You're kidding!", 2)
            try await say(brad, "Amber, why don't you make some money for me while you're at it? Business trips aren't cheap.", 3.6)
            try await say(amber, "Anything for you, Brad!", 2)
            try await say(deidre, "She'll get a fair share of the day's profit, same as everybody.", 3)
        } else {
            try await say(deidre, "Brad. Another business trip?", 2.2)
            try await say(brad, "Afraid so, Deidre. Could you keep Amber company again while I'm away?", 3.2)
            try await say(amber, "Please? I had so much fun last time!", 2.4)
            try await say(deidre, "Of course. Amber can tag along again.", 2.4)
            try await say(brad, "And make some more money for me, Amber!", 2.4)
            try await say(amber, "You got it, Brad!", 1.8)
        }
        try await say(brad, "Thanks, Deidre. I'll pick her up tonight. Bye, sweetie!", 2.8)
        try await say(amber, "Bye, Brad! Have a good trip!", 2)
        caption = "Brad heads off on his business trip."
        try await walk(brad, to: -80, speed: 150)
        brad.visible = false
        amber.facing = 1
        try await say(deidre, "Let's do it again — and Amber's coming too!", 2.4)

        // Amber invites the passers-by; the girls take the fares and work the machine as usual.
        team = [amber, order[0], order[1], order[2]]
        guest = amber
        try await callTheTent(cast + [amber], pusher: firstVisit ? cast.randomElement()! : amber, caller: kelly, seated: cast,
                              newcomer: firstVisit ? amber : nil,
                              newcomerLines: ("A cruise ship… in the front yard?! Brad is never going to believe this!", "Wheee!"))
        try await transformAgain(cast, legsStartLine: (jen, "I feel funny again!"), bodyLine: (kelly, "We're being transformed again!"))
        try await snap(cast)
        unstrap(cast)

        // Amber's turn, on her own in the machine's chair.
        try await look(at: Stage.chairsView)
        try await say(leader, firstVisit ? "And now for our guest. Step right up, Amber!" : "Welcome back, Amber! Your turn.", 2.6)
        try await say(amber, firstVisit ? "Me too? Oh my gosh!" : "My turn! My turn!", 1.8)
        caption = "The girls step out of the chairs, and Amber takes the middle seat."
        try await walkAll(zip(cast, Stage.standByX).map { ($0, $1) } + [(amber, Stage.chairX[1])], speed: 140)
        for p in cast { p.facing = 1 }
        seat([amber], chairs: [1])
        try await strap([amber])
        try await say(amber, firstVisit ? "Seat belts? This is really happening!" : "Buckled in and ready!", 2.2)
        try await say(leader, "Pick the type of alien clown you want to be!", 2.4)
        let pick = try await pickKinds([amber])
        let kind = pick[0].1
        try await look(at: Stage.full)
        try await say(leader, "Just relax.", 1.8)
        caption = "The alien clown presses the glowing pink button — just for Amber this time…"
        try await runMachine(pick, presser: leader, change: firstVisit ? Machine.change : Machine.customerChange,
                             tingleLine: (amber, firstVisit ? "This feels really tingly!" : "Ooh, that tingle again!"),
                             legsStartLine: (amber, firstVisit ? "Something is happening to me!" : "Here come my big clown shoes!"),
                             bodyLine: (amber, firstVisit ? "I'm being turned into an alien clown!" : "My sparkly suit!"),
                             faceShouts: (amber, [("Ooh, my face is getting all bubbly…", 15), ("Yippeeeeeee!", 18)]), beamOnShout: 1)
        try await look(at: Stage.full)
        try await say(leader, "Have a look!", 1.8)
        caption = "The alien clowns lower the big mirror…"
        try await showMirror([amber], caption: "…and Amber sees an alien clown looking back!", seconds: 3, calm: [amber])
        try await look(at: Stage.chairsView)
        try await say(amber, reaction(kind), 2.4)
        if let line = kind.noseLine { try await say(amber, line, 2) }
        try await say(amber, "Wait till Brad sees me!", 2)
        try await snap([amber])
        unstrap([amber])
        totalTransformed += 1
        try await say(leader, "\(amber.id) invites the passers-by, \(order[0].id) takes the fares, and \(order[1].id) works the machine.", 3.4)
        try await cruiseDay()

        // Home again, with Brad back from his trip and waiting in the front yard.
        brad.mood = .happy
        try await comeHome(first: false, gather: false, waiting: brad,
                           waitingLines: ("Whoa! A cruise ship pulling up to the house?!", "Alien clowns?! …AMBER?!"))
        brad.mood = .happy
        let workers = team.count + recruits.count
        let share = max(0, dayProfit / workers)
        try await walk(amber, to: 85, speed: 110)
        (brad.facing, amber.facing) = (1, -1)
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 150, height: 250))
        try await say(brad, "Amber? Was that really you? You were a clown!", 2.6)
        try await say(amber, "An alien clown, Brad! We sailed all day and turned people into clowns!", 3.2)
        if share > 0 {
            caption = "Amber gets a fair share of the profit: $\(share)."
            try await say(deidre, "Amber worked hard today. Here's her fair share: $\(share).", 2.8)
            cash -= share
            cashPop = ("-$\(share) to Amber", .now, amber.x(at: .now))
            sound.pay()
            amber.reachTo = CGPoint(x: 62, y: Stage.floorY - 75)
            try await say(amber, "$\(share) — and it's all for you, Brad!", 2.6)
            amber.reachTo = nil
            brad.mood = .beaming
            try await say(brad, "$\(share)?! Amber, you're amazing!", 2.4)
            brad.mood = .happy
            try await say(brad, "Deidre… thank you. I mean it.", 2.4)
        } else {
            try await say(deidre, "No profit to share today, Amber — sorry.", 2.4)
            try await say(amber, "Sorry, Brad. Maybe next time!", 2.2)
            try await say(brad, "That's okay. Looks like you had a blast.", 2.4)
        }
        try await say(brad, "Come on, Amber. Let's go home.", 2.2)
        try await say(amber, "Bye, everybody! Honk honk!", 2)
        caption = "Amber goes home with Brad."
        try await walkAll([(brad, -80), (amber, -50)], speed: 150)
        brad.visible = false
        amber.visible = false
        guest = nil
        try await look(at: Stage.full)
        try await gatherAtButton()
        // No more sailing today — the day is over.
        caption = "With Amber safely home with Brad, the day is over."
        try await say(deidre, "That's it for today, girls. What a day!", 2.4)
    }

    /// `pusher` presses the glowing pink button in the living room, and the cruise ship pulls `riders` up out of the front yard.
    /// Inside, `seated` are in the chairs and anyone else stands by on the left.
    /// A `newcomer` has never seen the ship before, and is delighted by it.
    private func callTheTent(_ riders: [Person], pusher: Person, caller: Person, seated: [Person], newcomer: Person? = nil,
                             newcomerLines: (spot: String, beam: String) = ("Oh, how fun! A cruise ship full of clowns!", "Wheee!")) async throws {
        try await say(pusher, pusher.isKid ? "Can I press it? Please?" : ["I'll press it!", "Let me!", "Here goes!"].randomElement()!, 1.6)
        caption = "\(pusher.id) presses the glowing pink button…"
        try await walk(pusher, to: Stage.buttonX - 26)
        pusher.facing = 1
        pusher.reachTo = CGPoint(x: Stage.buttonX, y: Stage.floorY - min(75, pusher.height * 0.47))
        try await sleep(0.6)
        buttonPressT0 = .now
        sound.beep()
        try await sleep(0.5)
        pusher.reachTo = nil

        caption = "…and the cruise ship comes back alongside the house to take them to the clowns' setup!"
        try await look(at: Stage.full)
        tentShown = true
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 0)
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.dockY), over: 3)
        sound.hum(true)
        try await sleep(3.1)
        sound.honk()
        try await say(caller, "It's back! Come on!", 1.8)
        if let n = newcomer {
            try await say(n, newcomerLines.spot, 2.4)
        }
        caption = "Everyone hurries out to the front yard."
        let line = riders.count > 3 ? [100] + Stage.yardLine : Stage.yardLine
        try await walkAll(zip(riders, line).map { ($0, $1) }, speed: 170)
        try await look(at: Stage.yardView)
        for p in riders { p.facing = 0 }
        try await extendGangway()
        caption = newcomer.map { "Up the gangway they go — \($0.id) too!" } ?? "Up the gangway they go again!"
        if let n = newcomer { shout([n], newcomerLines.beam, 2) }
        try await boardShip(riders)
        try await retractGangway()
        sound.honk()
        moveTent(to: CGPoint(x: Stage.offshoreX, y: Stage.dockY), over: 2.6)
        try await sleep(2.2)

        try await sceneChange {
            self.place = .bigTop
            self.tentShown = false
            self.chairsStowed = false
            self.sound.hum(false)
            for (p, x) in zip(self.crew, Stage.crewX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
            }
            (self.leader.x0, self.leader.x1, self.leader.facing) = (Stage.consoleX - 45, Stage.consoleX - 45, -1)
            self.seat(seated, chairs: Array(0..<seated.count))
            let standing = riders.filter { p in !seated.contains { $0 === p } }
            for (p, x) in zip(standing, Stage.standByX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
                p.seated = false
                p.place(height: 0)
            }
            self.show(self.crew + riders)
            self.cutNow(Stage.full)
        }
    }

    /// Up to three of them in the chairs at the clowns' setup: each picks her type of clown, the ringmaster presses
    /// the pink button, and they see themselves in the mirror. `quick` is the shorter show for old hands.
    private func transformAgain(_ riders: [Person], quick: Bool = false, welcome: String? = nil, legsStartLine: (Person, String)? = nil,
                                bodyLine: (Person, String)? = nil) async throws {
        try await strap(riders)
        caption = "Strapped into the chairs again, surrounded by the alien clowns."
        try await say(leader, welcome ?? (quick ? "Welcome back! You know the drill — pick your clowns!"
                                                : "Welcome back! This time you choose what type of alien clown you want to be."), 3.4)
        let riders = try await pickKinds(riders)
        try await look(at: Stage.full)
        try await say(leader, "Just relax.", 1.8)
        caption = "The alien clown presses the glowing pink button…"
        try await runMachine(riders, presser: leader, change: quick ? Machine.customerChange : Machine.change,
                             tingleShout: "This really tingles!", legsStartLine: legsStartLine, bodyLine: bodyLine,
                             facesLine: "Now our faces!")
        try await look(at: Stage.full)
        try await say(leader, "Have a look!", 1.8)
        caption = "The alien clowns lower the big mirror…"
        try await showMirror(riders.map(\.0), caption: "…and they see what type of clown they picked!", seconds: quick ? 3 : 4)
        try await look(at: Stage.chairsView)
        for (p, kind) in riders {
            try await say(p, p.isKid ? "I'm \(kind.name)! Honk honk!" : reaction(kind), 2.4)
            if let line = kind.noseLine { try await say(p, line, 2) }
        }
    }

    /// The player picks each rider's type of clown, with the camera on her.
    /// `silent`: she doesn't know what's coming, so she doesn't announce her pick.
    private func pickKinds(_ riders: [Person], silent: Bool = false) async throws -> [(Person, ClownKind)] {
        var picked: [(Person, ClownKind)] = []
        for p in riders {
            try await look(at: Stage.focus(CGPoint(x: p.x(at: .now), y: Stage.floorY - 90), height: 230))
            caption = silent ? "Pick a type of alien clown for \(p.id)." : "What type of alien clown does \(p.id) want to be?"
            let kind = await withCheckedContinuation { cont in
                kindPick = cont
                choosingKind = p
            }
            try Task.checkCancellation()
            if !silent { try await say(p, "I want to be \(kind.name)!", 1.8) }
            picked.append((p, kind))
        }
        return picked
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
