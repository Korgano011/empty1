import SwiftUI

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var deidre: Person
    var kelly: Person
    var jen: Person

    var cast: [Person] { [deidre, kelly, jen] }
    /// The repo man, Deidre's boyfriend, and his new girlfriend.
    var extras: [Person] = []
    /// The flying tent's alien clowns; the last one is their ringmaster.
    var crew: [Person] = []
    var customers: [Person] = []
    /// A roommate's mother and little sister (families take turns), who visit the morning after every odd night.
    var family: [Person] = []
    /// Who is on this trip: greeter, cashier, machinist, then anyone else along for the ride.
    var team: [Person] = []
    /// Amber, while Brad has left her with Deidre for the day (she is also in `extras`).
    var guest: Person?
    var everyone: [Person] { cast + family + extras + crew + customers }
    /// The top-right meters: the three women, plus any visitors once they have been clowns.
    var hudPeople: [Person] { cast + (family + (guest.map { [$0] } ?? [])).filter { $0.clown != nil } }
    private var leader: Person { crew[crew.count - 1] }

    var caption = "Tap Start to begin."
    var running = false
    var finished = false
    var muted = false { didSet { sound.muted = muted } }

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

    // The flying tent
    var tentShown = false
    /// Clouds streak past the tent's windows.
    var tentFlying = false
    var beamOn = false
    var beamT0 = Date.distantPast
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
    /// Hair falling from the salon chair while Deidre cuts: where, what colour, and for how long.
    var clippings: [(x: Double, y: Double, colors: [RGB], t0: Date, dur: Double)] = []
    /// What the movers have already carried out of Shear Elegance.
    var salonCleared: Set<SalonItem> = []
    /// When the movers flipped the salon's lights off, if they have.
    var salonLightsOffT0: Date?
    var result: EventRecord?
    var trips = 0
    /// The jobs rotate each time they do it again, so everyone gets a turn working the machine.
    var rotation = 0
    /// How many times a roommate's mother and little sister have come over.
    var familyVisits = 0
    /// How many times Brad has dropped Amber off; her salon story is told on the first.
    var amberVisits = 0
    var totalProfit = 0
    var totalTransformed = 0
    /// What has gone into the bank; setup fees come out of `cash` only.
    var bank = 0
    /// What they have bought out of their savings and parked in the driveway.
    var vehicles: Set<Vehicle> = []
    /// The one being brought home from the dealer right now, and whoever is riding it.
    var arriving: Vehicle?
    var rider: Person?
    private var arriveT0 = Date.distantPast
    /// Whoever is in the accessory store waiting for the player to pick something.
    var choosingAccessory: Person?
    var choosingVehicle = false

    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var venuePick: CheckedContinuation<Venue, Never>?
    @ObservationIgnored private var kindPick: CheckedContinuation<ClownKind, Never>?
    @ObservationIgnored private var nextPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var accessoryPick: CheckedContinuation<Accessory?, Never>?
    @ObservationIgnored private var vehiclePick: CheckedContinuation<Vehicle?, Never>?
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
        let kelly = Person("Kelly", height: 154, skin: RGB(r: 0.85, g: 0.65, b: 0.50), hair: RGB(r: 0.10, g: 0.10, b: 0.10), style: .curly,
                           shirt: RGB(r: 0.98, g: 0.80, b: 0.25), pants: RGB(r: 0.30, g: 0.42, b: 0.68), x: Stage.livingX[1])
        let jen = Person("Jen", height: 164, skin: RGB(r: 0.99, g: 0.86, b: 0.76), hair: RGB(r: 0.92, g: 0.78, b: 0.42), style: .ponytail,
                         shirt: RGB(r: 0.60, g: 0.40, b: 0.80), pants: RGB(r: 0.25, g: 0.25, b: 0.30), shorts: false, x: Stage.livingX[2])
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
        let boss = Person("Lorraine", height: 164, skin: RGB(r: 0.94, g: 0.78, b: 0.66), hair: RGB(r: 0.72, g: 0.22, b: 0.18), style: .bob,
                          shirt: RGB(r: 0.15, g: 0.15, b: 0.18), pants: RGB(r: 0.15, g: 0.15, b: 0.18), shorts: false, x: Stage.ownerDeskX)
        let client = Person("Gloria", height: 160, skin: RGB(r: 0.98, g: 0.84, b: 0.72), hair: RGB(r: 0.50, g: 0.30, b: 0.16), style: .long,
                            shirt: RGB(r: 0.20, g: 0.60, b: 0.62), pants: RGB(r: 0.25, g: 0.28, b: 0.45), shorts: false,
                            x: Stage.stationX + Stage.salonChairOffset)
        // The night the bank shuts the salon: Tina (Amber, extras[2], is the other customer), the bank's man and two movers.
        let tina = Person("Tina", height: 162, skin: RGB(r: 0.96, g: 0.80, b: 0.66), hair: RGB(r: 0.85, g: 0.66, b: 0.30), style: .long,
                          shirt: RGB(r: 0.95, g: 0.55, b: 0.25), pants: RGB(r: 0.25, g: 0.30, b: 0.50), shorts: false, x: -60)
        let banker = Person("Mr. Crane", height: 176, skin: RGB(r: 0.92, g: 0.76, b: 0.64), hair: RGB(r: 0.55, g: 0.55, b: 0.55), style: .short,
                            shirt: RGB(r: 0.18, g: 0.20, b: 0.28), pants: RGB(r: 0.18, g: 0.20, b: 0.28), shorts: false, female: false, x: -60)
        let movers = [RGB(r: 0.25, g: 0.45, b: 0.70), RGB(r: 0.70, g: 0.30, b: 0.20)].enumerated().map { i, shirt in
            Person("Mover \(i + 1)", height: 174 + Double(i) * 4, skin: RGB(r: 0.88, g: 0.68, b: 0.52), hair: RGB(r: 0.25, g: 0.18, b: 0.10),
                   style: .short, shirt: shirt, pants: RGB(r: 0.30, g: 0.30, b: 0.32), shorts: false, female: false, x: -60)
        }
        // …and the power company, there to cut her electricity off.
        let lineman = Person("Power Co. Man", height: 178, skin: RGB(r: 0.70, g: 0.50, b: 0.36), hair: RGB(r: 0.12, g: 0.10, b: 0.08), style: .short,
                             shirt: RGB(r: 0.85, g: 0.92, b: 0.20), pants: RGB(r: 0.22, g: 0.28, b: 0.40), shorts: false, female: false, x: -60)
        let all = [repo, brad, amber, boss, client, tina, banker] + movers + [lineman]
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
            spotTent: "Well, I'll be! A circus tent that flies!",
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
            spotTent: "¡Ay, qué bonito! A circus tent flying over the house!",
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
            spotTent: "Oh, how fun! A flying circus tent!",
            beamUp: "Wheee!",
            inTent: "A real circus tent in the sky! Hello, everyone!",
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

    /// The mother and little sister of the roommate named `daughter`.
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

    /// The middle of the tent's hem, bobbing gently while it hovers.
    func tent(at now: Date) -> CGPoint? {
        guard tentShown else { return nil }
        let t = min(max(now.timeIntervalSince(tentT0) / max(tentDur, 0.001), 0), 1)
        let e = t * t * (3 - 2 * t)
        let bob = sin(now.timeIntervalSinceReferenceDate * 2) * 3
        return CGPoint(x: tentFrom.x + (tentTo.x - tentFrom.x) * e, y: tentFrom.y + (tentTo.y - tentFrom.y) * e + bob)
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

    /// What is left to spend on accessories once the cheapest setup fee is set aside.
    var spendingMoney: Int { cash - Venue.cheapestFee }

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
        venuePick?.resume(returning: .wildwood)
        venuePick = nil
        kindPick?.resume(returning: .moonbeam)
        kindPick = nil
        nextPick?.resume(returning: false)
        nextPick = nil
        accessoryPick?.resume(returning: nil)
        accessoryPick = nil
        vehiclePick?.resume(returning: nil)
        vehiclePick = nil
        sound.prepare()
        sound.stopAll()
        (deidre, kelly, jen) = Self.makeCast()
        team = [deidre, kelly, jen]
        family = []
        guest = nil
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
        beamOn = false
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
        choosingVenue = false
        choosingNext = false
        cash = Venue.startCash
        cashPop = nil
        clippings = []
        salonCleared = []
        result = nil
        trips = 0
        rotation = 0
        familyVisits = 0
        amberVisits = 0
        totalProfit = 0
        totalTransformed = 0
        bank = 0
        vehicles = []
        arriving = nil
        rider = nil
        choosingAccessory = nil
        choosingVehicle = false
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
    func choose(_ accessory: Accessory?) {
        accessoryPick?.resume(returning: accessory)
        accessoryPick = nil
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

    private func story() async throws {
        let (deidre, kelly, jen) = (deidre, kelly, jen)
        let (repoMan, brad, amber, boss) = (extras[0], extras[1], extras[2], extras[3])

        try await laidOff(boss: boss, client: extras[4])
        try await worstDayEver(repoMan: repoMan, brad: brad, amber: amber)
        try await clownsAtTheDoor()

        // Inside the tent
        try await sceneChange {
            self.place = .bigTop
            self.tentShown = false
            self.tentFlying = true
            self.seat(self.cast, chairs: [0, 1, 2])
            for (p, x) in zip(self.crew, Self.wingsX) {
                (p.x0, p.x1, p.moveDur) = (x, x, 0)
                p.place(height: 0)
            }
            self.show(self.cast)
            self.cutNow(Stage.chairsView)
        }
        caption = "…and takes them to the clowns' setup."
        try await sleep(2.2)
        tentFlying = false
        sound.hum(false)
        try await strap(cast)
        caption = "They are strapped into chairs…"
        try await say(kelly, "Ooh, seat belts! This must be some ride!", 2.4)
        try await say(jen, "A real circus tent in the sky! How cool is this?", 2.6)

        caption = "…and are surrounded by the alien clowns!"
        try await look(at: Stage.full)
        for p in crew { p.visible = true }
        sound.honk()
        try await walkAll(zip(crew, Stage.crewX).map { ($0, $1) }, speed: 120)
        for p in crew { p.facing = 0 }
        try await look(at: Stage.chairsView)
        try await say(kelly, "Hi, everybody! Love the outfits!", 2.2)
        try await say(deidre, "Well, hello! Whatever you have in mind, I'm ready for a fresh start.", 3)
        try await say(deidre, "Yesterday I lost my job, my car, and my boyfriend!", 3.2)
        try await say(deidre, "So things can only go up from here!", 2.4)
        try await look(at: Stage.full)
        try await walk(leader, to: Stage.consoleX - 45, speed: 100)
        leader.facing = -1
        try await say(leader, "We know. We are here to help you with that.", 3)
        try await say(jen, "See, Deidre? Your luck is already changing!", 2.6)

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
        try await showMirror(cast, caption: "…and the three women see themselves for the first time!", calm: cast)
        for p in cast { p.mood = .beaming }
        try await look(at: Stage.chairsView)
        shout(cast, "Wow!", 1.8)
        try await sleep(2)
        try await say(deidre, "Would you look at us? We're alien clowns!", 2.6)
        try await say(kelly, "I've never looked so cheerful in my life!", 2.4)
        try await say(jen, "This is the best surprise ever!", 2.2)
        for p in cast { p.mood = .happy }

        try await look(at: Stage.full)
        try await say(leader, "We said we are here to help you.", 2.6)
        try await say(leader, "Here is the deal: our flying tent has pre-selected destinations.", 3.2)
        caption = "The alien clowns explain the deal…"
        card = .deal
        cardUntil = .now + 16
        try await sleep(16.2)
        try await say(leader, "The only catch is you have to pay for the setup.", 2.8)
        try await say(leader, "Two of you go outside to ask customers. One of you stays inside to work the machine.", 3.8)
        try await say(deidre, "Between us we have $\(Venue.startCash). Ladies, we're in business!", 3)
        try await say(jen, "Way better than job hunting!", 1.8)
        try await say(deidre, "A new job already — this is turning into a great day!", 2.8)
        try await snap(cast)
        unstrap(cast)

        var first = true
        var visit = false
        while true {
            if visit {
                try await morningVisit()
            } else {
                try await tripToVenue()
                try await comeHome(first: first)
                if trips % 2 == 0 {
                    try await restUntilMorning()
                    if cash >= Venue.cheapestFee { try await morningVisit() }
                }
            }
            if cash < Venue.cheapestFee {
                try await say(deidre, "We only have $\(cash) on hand — not enough for another setup fee.", 2.8)
            }
            first = false
            let again = await withCheckedContinuation { cont in
                nextPick = cont
                choosingNext = true
                caption = "Press the pink button to do it again, or end the game?"
            }
            try Task.checkCancellation()
            guard again else { break }
            // Once they have slept a night, every morning brings visitors.
            visit = trips >= 2 && cash >= Venue.cheapestFee
            if !visit { try await doItAgain() }
        }

        caption = "Game over! \(trips) \(trips == 1 ? "trip" : "trips") in the flying tent, \(totalTransformed) customers transformed, "
            + "\(totalProfit >= 0 ? "$\(totalProfit) profit" : "$\(-totalProfit) lost"). Cash on hand: $\(cash), savings in the bank: $\(bank)."
            + (vehicles.isEmpty ? "" : " In the driveway: \(ListFormatter.localizedString(byJoining: Vehicle.allCases.filter(vehicles.contains).map { "a \($0.name.lowercased())" })), bought and paid for.")
        try await say(deidre, vehicles.contains(.car) ? "A new job, and a car nobody can repossess. Best thing that ever happened to us!"
                                                      : "Best thing that ever happened to us!", 3)
        finished = true
        running = false
    }

    /// The opening: at the beauty salon, the owner calls Deidre in and lays her off.
    private func laidOff(boss: Person, client: Person) async throws {
        let deidre = deidre
        place = .salon
        show([deidre, boss, client])
        let chairX = Stage.stationX + Stage.salonChairOffset
        (deidre.x0, deidre.x1, deidre.moveDur, deidre.facing) = (Stage.stationX, Stage.stationX, 0, 1)
        (boss.x0, boss.x1, boss.moveDur, boss.facing) = (Stage.ownerDeskX, Stage.ownerDeskX, 0, 0)
        (client.x0, client.x1, client.moveDur, client.facing) = (chairX, chairX, 0, 0)
        client.seated = true
        cutNow(Stage.full)
        caption = "Deidre is a hairstylist at the Shear Elegance beauty salon."
        try await sleep(2.4)

        // Her last customer: Gloria wants her head shaved bald — clippers, shaving cream, then a hand razor.
        try await look(at: Stage.shot(centerX: Stage.stationX + 36, height: 300))
        try await say(deidre, "So what are we doing today, Gloria?", 2.4)
        try await say(client, "Something totally new. I want it all off. Shave my head bald!", 3)
        try await say(deidre, "Bald? Are you sure? You have such long hair!", 2.6)
        try await say(client, "I'm sure. I've wanted to do this for years!", 2.4)
        try await say(deidre, "Okay! Clippers first.", 2)
        caption = "Bzzzz… Deidre runs the clippers over Gloria's head."
        try await clipHeads([(deidre, client)]) { self.caption = "…and her long hair falls to the floor." }
        try await say(client, "It feels so fuzzy!", 2)
        try await say(deidre, "Now for the smooth part. Shaving cream!", 2.4)
        caption = "Deidre spreads shaving cream all over Gloria's scalp."
        try await latherHeads([(deidre, client)])
        try await say(client, "Ooh, that's cold!", 1.8)
        caption = "Stroke by stroke, Deidre goes over it with a hand razor."
        try await razorHeads([(deidre, client)])
        caption = "A warm towel wipes away the last of the cream."
        try await sleep(1.2)
        try await say(deidre, "All done! Take a look in the mirror.", 2.4)
        client.mood = .shocked
        try await say(client, "Wow! It's so smooth!", 2)
        client.mood = .happy
        try await say(client, "I love it! You're the best, Deidre!", 2.4)
        try await say(client, "I'm going to keep it shaved. No more bad hair days for me!", 3)
        try await say(deidre, "It suits you, Gloria!", 2)
        caption = "Gloria pays at the front and heads out."
        client.seated = false
        try await walk(client, to: -60, speed: 120)
        client.visible = false
        try await look(at: Stage.full)
        try await walk(boss, to: Stage.ownerDoorX - 40, speed: 110)
        boss.facing = -1
        try await say(boss, "Deidre, could you step into my office for a minute?", 2.8)
        deidre.facing = 1
        try await say(deidre, "Sure, Lorraine.", 1.8)
        _ = beginWalk(boss, to: Stage.ownerDeskX - 30, speed: 110)
        try await walk(deidre, to: Stage.ownerDeskX - 140, speed: 110)
        boss.facing = -1
        deidre.facing = 1
        try await look(at: Stage.shot(centerX: Stage.ownerDeskX - 85, height: 300))
        try await say(boss, "There's no easy way to say this. Ever since more women are shaving their heads by themselves, business has been really bad.", 3.6)
        try await say(boss, "I have to cut back to two stylists, and I'm afraid I have to let you go.", 3.2)
        deidre.mood = .shocked
        try await say(deidre, "I'm being laid off? I've done hair here for five years!", 2.8)
        try await say(boss, "It isn't your work, Deidre. Your clients love you. Unfortunately we are losing money. Today will be your last day.", 3.6)
        try await say(boss, "I'm sorry. You'll get two weeks' pay.", 2.4)
        try await say(deidre, "I can't believe this…", 2.2)

        caption = "Deidre packs up her styling station."
        try await look(at: Stage.full)
        try await walk(deidre, to: Stage.stationX, speed: 110)
        deidre.facing = 0
        try await sleep(1.2)
        deidre.carrying = true
        try await say(deidre, "My scissors, my brushes… five years, and it all fits in one box.", 2.8)
        try await walk(deidre, to: -60, speed: 110)
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
        caption = "Deidre is walking home with her box. She has just been laid off from her job at the beauty salon."
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

        caption = "When she enters the house she sees her two roommates — and her boyfriend."
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
        try await say(kelly, "Oh, Deidre. What a rotten day.", 2.4)
        try await say(jen, "Let's all get some rest and think it over in the morning.", 3)
        caption = "After this bad day, Deidre and her roommates decide to get some rest and think it over in the morning."
        try await goToBed()
        try await sceneChange { self.wakeUp() }
        caption = "The next morning…"
        sound.chime()
        try await sleep(2)
    }

    /// Some weird-looking alien clowns show up at the front door with a flying tent, and the tent pulls the women inside.
    private func clownsAtTheDoor() async throws {
        let (deidre, kelly, jen) = (deidre, kelly, jen)
        let visitors = [leader, crew[0], crew[1]]
        caption = "Something striped is coming down out of the sky…"
        try await look(at: Stage.yardView)
        tentShown = true
        moveTent(to: CGPoint(x: Stage.yardTentX, y: -140), over: 0)
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.floorY - Stage.hoverLift), over: 3.4)
        sound.hum(true)
        try await sleep(3.6)
        caption = "Some weird-looking alien clowns show up at the front door with a flying tent!"
        try await beamDown(visitors, at: Stage.yardLine)
        try await walkAll([(leader, 392), (crew[0], 352), (crew[1], 312)], speed: 110)
        sound.honk()
        try await say(leader, "HONK HONK! Anybody home?", 2.2)

        try await look(at: Stage.full)
        try await say(deidre, "Who is honking at this hour?", 2.2)
        try await walkAll([(deidre, 452), (kelly, 494), (jen, 536)], speed: 150)
        for p in cast {
            p.facing = -1
            p.mood = .shocked
        }
        try await look(at: Stage.shot(centerX: 400, height: 300))
        try await say(kelly, "Are those… CLOWNS?", 2.2)
        try await say(jen, "And is that a FLYING TENT?!", 2.4)
        try await say(leader, "Good morning, ladies! Step right up!", 2.6)

        caption = "The tent pulls the three women inside!"
        try await look(at: Stage.yardView)
        try await walkAll([(leader, 330), (crew[0], 365), (crew[1], 400)], speed: 160)
        beamOn = true
        beamT0 = .now
        sound.beam(true)
        shout(cast, "WHOOOA!", 2)
        try await walkAll(zip([deidre, kelly, jen], Stage.yardLine).map { ($0, $1) }, speed: 210)
        try await beamUp(cast)
        for p in cast { p.mood = .happy }
        try await walkAll(zip(visitors, Stage.yardLine).map { ($0, $1) }, speed: 150)
        try await beamUp(visitors)
        caption = "The flying tent lifts off…"
        moveTent(to: CGPoint(x: Stage.yardTentX + 500, y: -220), over: 2.2)
        try await sleep(1.9)
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
        }
    }

    // MARK: The machine

    /// Presses the glowing pink button: a tingle, then the change climbs from the feet to the face.
    private func runMachine(_ riders: [(Person, ClownKind)], presser: Person, change: Double,
                            tingleLine: (Person, String)? = nil, tingleShout: String? = nil, legsStartLine: (Person, String)? = nil,
                            legsLine: (Person, String)? = nil, bodyLine: (Person, String)? = nil, facesLine: String? = nil,
                            faceShouts: (Person, [(text: String, size: Double)])? = nil, beamOnShout: Int? = nil,
                            faceSpeakers: [[Person]]? = nil) async throws {
        presser.facing = presser.x(at: .now) < Stage.consoleX ? 1 : -1
        presser.reachTo = Stage.pinkButton
        try await sleep(0.7)
        consolePressT0 = .now
        sound.beep()
        try await sleep(0.4)
        presser.reachTo = nil

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

    // MARK: The flying tent

    private func moveTent(to point: CGPoint, over seconds: Double) {
        tentFrom = seconds == 0 ? point : tent(at: .now) ?? point
        tentTo = point
        tentT0 = .now
        tentDur = seconds
    }

    /// The beam lifts everyone up through the flap, while `watcherLine` is called out from the ground.
    private func beamUp(_ people: [Person], watcherLine: (Person, String)? = nil) async throws {
        beamOn = true
        beamT0 = .now
        sound.beam(true)
        try await sleep(0.5)
        for (i, p) in people.enumerated() {
            p.facing = 0
            stop(p)
            p.float(to: Stage.beamRise, over: 2.4 + Double(i) * 0.15)
        }
        if let (watcher, line) = watcherLine { mention(watcher, line, 2.4) }
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
        let (greeter, cashier, machinist) = roles
        try await look(at: Stage.full)
        caption = "Pick one of the flying tent's destinations. Setup has to be paid for — they have $\(cash)."
        let venue = await withCheckedContinuation { cont in
            venuePick = cont
            choosingVenue = true
        }
        try Task.checkCancellation()

        caption = "Whoosh! The flying tent sails off to \(venue.theName)!"
        tentFlying = true
        sound.hum(true)
        try await sleep(2.6)

        try await sceneChange {
            self.tentFlying = false
            self.place = .venue
            self.venue = venue
            self.unstrap(self.team)
            self.show([])
            self.customers = []
            self.tentShown = true
            self.moveTent(to: CGPoint(x: Stage.venueTentX, y: -140), over: 0)
            self.cutNow(Stage.full)
        }
        served = []
        asked = 0
        earned = 0
        adultNames = (Self.menNames + Self.womenNames).shuffled()
        momNames = ["Brenda", "Denise", "Lena", "Rita", "Tanya", "Monica", "Sara", "Wendy", "Sherry", "Michelle", "Christine", "Karla", "Dawn"].shuffled()
        kidNames = ["Amy", "Ben", "Cora", "Danny", "Ella", "Finn", "Gwen", "Hannah", "Jade", "Max", "Noah", "Kai", "Mary", "Sue", "Ellie", "Lori", "Christina", "Kiki", "Heidi"].shuffled()
        let startCash = cash

        moveTent(to: CGPoint(x: Stage.venueTentX, y: Stage.floorY - Stage.hoverLift), over: 2.4)
        caption = "The flying tent comes down at \(venue.theName)!"
        try await sleep(2.6)
        sound.hum(false)
        caption = "Setting up at \(venue.theName) costs $\(venue.fee)."
        cash -= venue.fee
        cashPop = ("-$\(venue.fee)", .now, Stage.cashX)
        try await sleep(2)

        caption = "\(greeter.id) and \(cashier.id) go outside to ask customers, while \(machinist.id) stays inside to work the machine."
        try await beamDown([greeter, cashier], at: Stage.beamSpot)
        try await walkAll([(greeter, Stage.greetX[0]), (cashier, Stage.greetX[1])])
        (greeter.facing, cashier.facing) = (1, 1)
        sound.honk()
        try await say(greeter, "Step right up! Get transformed into an alien clown! Only $\(venue.price), kids $\(venue.kidPrice)!", 3.2)
        try await say(cashier, "Pick any type of clown you like!", 2.4)
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
        let (greeter, cashier, _) = roles
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

        try await say(greeter, "Hi! Want to be turned into an alien clown?", 2.4)
        let firstYes = Double.random(in: 0...1) < (withKid ? venue.kidYes : venue.adultYes)
        if withKid {
            try await say(first, firstYes ? ["Yes! Can I? Please?", "A CLOWN? Cool!", "In a flying tent? YES!"].randomElement()!
                                           : ["No way, clowns are creepy!", "Nope! I'm scared of clowns!", "Maybe when I'm bigger."].randomElement()!, 2.2)
        } else {
            try await say(first, firstYes ? ["Sure, why not!", "Send in the clowns!", "I've always wanted to run away with the circus!"].randomElement()!
                                           : ["No thanks!", "Not today!", "Uh… I'll pass."].randomElement()!, 2.2)
        }
        var buyers = firstYes ? [first] : []
        if kids.count > 1 {
            let second = kids[1]
            try await say(greeter, "How about you?", 1.6)
            // A little brother or sister usually wants whatever the first kid gets.
            let secondYes = Double.random(in: 0...1) < (firstYes ? 0.85 : venue.kidYes * 0.5)
            try await say(second, secondYes ? (firstYes ? ["Me too! Me too!", "I want to be a clown too!"].randomElement()!
                                                        : ["Well, I'm not scared! I'll do it!", "I will! Honk honk!"].randomElement()!)
                                            : ["No thanks, I'll watch.", "Nuh-uh, too silly!"].randomElement()!, 2.2)
            if secondYes { buyers.append(second) }
        }
        let kidsIn = !buyers.isEmpty
        let sweetie = buyers.count > 1 ? "kids" : "sweetie"
        if let mother {
            try await say(cashier, "Would you like to be transformed too?", 2.2)
            let momYes = Double.random(in: 0...1) < (kidsIn ? venue.momYes : venue.momYes * 0.5)
            if momYes {
                try await say(mother, kidsIn ? "Why not? Let's be clowns together!" : "Ha! Sure — I'll do it!", 2.4)
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
        let holdouts = group.filter { $0.clown == nil }
        if !holdouts.isEmpty {
            for p in holdouts { p.facing = -1 }
            greeter.facing = 1
            caption = "\(greeter.id) offers \(ListFormatter.localizedString(byJoining: holdouts.map(\.id))) a second chance."
            try await say(greeter, holdouts.count == 1 ? "Now that you've seen it up close — want a second chance?"
                                                      : "Now that you've seen it up close — anyone want a second chance?", 2.6)
            var second: [Person] = []
            for p in holdouts {
                let isMother = p === mother
                if isMother, let kid = kids.first(where: { $0.clown != nil }) {
                    try await say(kid, "Come on, Mom! Do it! Do it!", 2)
                }
                let yes = Double.random(in: 0...1) < (isMother ? 0.7 : p.isKid ? 0.7 : 0.55)
                let line = switch (yes, p.isKid) {
                case (true, true): ["Okay! I'm not scared anymore!", "It looks so fun! Me too!", "I changed my mind! Honk honk!"].randomElement()!
                case (true, false): ["Oh, why not — I'll do it too!", "You talked me into it!", "Okay, now I want to be a clown too!"].randomElement()!
                case (false, true): ["Still too silly for me!", "Nope, I'll just watch."].randomElement()!
                case (false, false): ["No, I'm happy watching.", "Still no thanks — but it looks great!"].randomElement()!
                }
                try await say(p, line, 2.2)
                if yes { second.append(p) }
            }
            if second.isEmpty {
                caption = "Maybe next time!"
                try await sleep(1.4)
            } else {
                // A kid left on the ground watches Mom float up into the tent.
                let watcher = second.contains { $0 === mother } ? kids.first { k in !second.contains { $0 === k } } : nil
                try await transformRound(second, group: group, payer: mother ?? first, venue: venue,
                                         watcherLine: watcher.map { ($0, "There goes Mommy!") })
            }
        }

        caption = group.allSatisfy({ $0.clown != nil }) ? "Off they go, transformed into alien clowns!"
                                                         : "Off they go — some clowns, some not!"
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((Stage.waitX[1] + 150) / stroll)
        customers = []
    }

    /// One trip through the tent for `buyers`: they pay the cashier, get beamed up and transformed, and come back down
    /// to the rest of `group`, who wait off to the side. `watcherLine` is said from the ground as the beam lifts them.
    private func transformRound(_ buyers: [Person], group: [Person], payer: Person, venue: Venue,
                                watcherLine: (Person, String)? = nil) async throws {
        let (greeter, cashier, machinist) = roles
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

        caption = "\(ListFormatter.localizedString(byJoining: buyers.map(\.id))) \(buyers.count == 1 ? "steps" : "step") under the flying tent."
        var moves = zip(buyers, Stage.beamSpot).map { ($0, $1) }
        let others = group.filter { p in !buyers.contains { $0 === p } }
        for (p, x) in zip(others, Stage.waitX.reversed()) { moves.append((p, x)) }
        try await walkAll(moves)
        for p in group where !buyers.contains(where: { $0 === p }) { p.facing = -1 }
        try await beamUp(buyers, watcherLine: watcherLine)

        // Inside, one of the three works the machine.
        let deckView = buyers.count == 3 ? CGRect(x: 300, y: 120, width: 820, height: 410) : CGRect(x: 440, y: 190, width: 680, height: 340)
        try await sceneChange {
            self.place = .bigTop
            self.seat(buyers, chairs: buyers.count == 3 ? [0, 1, 2] : Array([1, 2].suffix(buyers.count)))
            (machinist.x0, machinist.x1, machinist.moveDur, machinist.facing) = (Stage.controlX, Stage.controlX, 0, -1)
            machinist.place(height: 0)
            machinist.seated = false
            self.show([machinist] + buyers)
            self.cutNow(deckView)
        }
        try await strap(buyers)
        try await say(machinist, buyers.count == 1 ? "Welcome aboard! What type of alien clown do you want to be?"
                                                  : "Welcome aboard! What types of alien clown do you want to be?", 2.8)
        var riders: [(Person, ClownKind)] = []
        for p in buyers {
            let kind = ClownKind.allCases.randomElement()!
            try await say(p, ["\(kind.name), please!", "I want to be \(kind.name)!", "\(kind.name)! Definitely \(kind.name)!"].randomElement()!, 2)
            riders.append((p, kind))
        }
        try await say(machinist, "Just relax! I'm pressing the glowing pink button!", 2.4)
        try await runMachine(riders, presser: machinist, change: Machine.customerChange,
                             tingleLine: (buyers[0], "Ooh, this really tingles!"))
        try await look(at: deckView)
        try await say(machinist, buyers.count == 1 ? "All done! Take a look in the mirror!" : "All done! Take a look in the mirror, everybody!", 2.4)
        caption = "\(machinist.id) lowers the big mirror in front of the chairs…"
        try await showMirror(buyers, caption: buyers.count == 1 ? "\(buyers[0].id) sees an alien clown looking back!"
                                                                 : "They see alien clowns looking back!", seconds: 3)
        for (p, kind) in riders {
            try await say(p, p.isKid ? ["I'm a \(kind.name) clown!", kind.noseLine == nil ? "Look at my big red nose!" : "Look at me!", "Best day EVER!"].randomElement()!
                                     : ["Wow! Look at me!", "I'm a real alien clown!", "Honk honk! I love it!"].randomElement()!, 2.2)
            if let line = kind.noseLine { try await say(p, line, 2) }
            served.append(PersonSpec(p, kind: kind))
        }
        try await say(machinist, "You'll change back in eight hours. Enjoy!", 2.4)
        unstrap(buyers)

        // Back outside
        try await sceneChange {
            self.place = .venue
            self.show([greeter, cashier] + others)
            self.cutNow(Stage.full)
        }
        try await beamDown(buyers, at: Array(Stage.beamSpot.prefix(buyers.count)))
        // Someone still human cheers them on; if everyone waiting is already a clown, one of them welcomes the newcomers.
        if let watcher = others.first(where: { $0.clown == nil }) ?? others.first {
            watcher.facing = -1
            try await say(watcher, watcher.clown == nil ? "Look at you! You're a CLOWN!" : "Yay! Now we're clowns together!", 2.2)
        }
        try await say(buyers.last!, ["Thank you! We love it!", "Best thing at the whole \(venue.shortName)!", "Wait till my friends see this!"].randomElement()!, 2.4)
        try await say(greeter, "Remember — it wears off in eight hours!", 2.2)
    }

    /// The tent takes them home: the transformation fades 50%, then one minute later it's gone.
    /// `gather` sends everyone to the pink button afterwards; `stayedHome` were waiting in the house.
    /// `waiting` stands in the front yard as the tent lands, gasping `waitingLines` as it arrives and beams them down;
    /// `landing` runs once everyone is on the ground.
    private func comeHome(first: Bool, gather: Bool = true, stayedHome: [Person] = [], waiting: Person? = nil,
                          waitingLines: (tent: String, beam: String)? = nil,
                          landing: () async throws -> Void = {}) async throws {
        let team = team
        let adults = team.filter { !$0.isKid }
        let lead = team.contains { $0 === deidre } ? deidre : adults[0]
        let other = adults.first { $0 !== lead } ?? lead
        try await look(at: Stage.full)
        let (greeter, cashier, _) = roles
        caption = "\(greeter.id) and \(cashier.id) beam back up, and the flying tent takes the \(team.count == 4 ? "four" : "three") of them home."
        try await walkAll([(greeter, Stage.beamSpot[0]), (cashier, Stage.beamSpot[1])])
        try await beamUp([greeter, cashier])
        sound.hum(true)
        moveTent(to: CGPoint(x: Stage.venueTentX, y: -170), over: 1.6)
        try await sleep(1.4)

        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.customers = []
            self.show(stayedHome + (waiting.map { [$0] } ?? []))
            for (p, x) in zip(stayedHome, Stage.livingX.reversed()) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
            if let waiting { (waiting.x0, waiting.x1, waiting.moveDur, waiting.facing) = (40, 40, 0, 1) }
            self.moveTent(to: CGPoint(x: Stage.yardTentX, y: -140), over: 0)
            self.cutNow(Stage.full)
        }
        caption = waiting.map { "Home again! \($0.id) is in the front yard, waiting." } ?? "Home again!"
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.floorY - Stage.hoverLift), over: 2.4)
        if let waiting, let lines = waitingLines {
            try await sleep(0.9)
            waiting.mood = .shocked
            shout([waiting], lines.tent, 1.6)
            try await sleep(1.6)
        } else {
            try await sleep(2.5)
        }
        try await look(at: Stage.yardView)
        if let waiting, let lines = waitingLines { shout([waiting], lines.beam, 2.4) }
        try await beamDown(team + [leader], at: (team.count > 3 ? [100] + Stage.yardLine : Stage.yardLine) + [305])
        try await landing()
        leader.facing = -1
        try await say(leader, "Now that we have brought you home, your transformation will wear off.", 3.2)
        try await say(leader, "First you change back 50%. Then one minute later, back to normal. Toodle-oo!", 3.6)
        try await walk(leader, to: Stage.yardLine[1], speed: 150)
        try await beamUp([leader])
        caption = "The flying tent sails away…"
        moveTent(to: CGPoint(x: Stage.yardTentX + 500, y: -220), over: 2.2)
        try await sleep(2.3)
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
        try await say(adults.last!, "One more minute and we'll be back to normal.", 2.4)

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

        let profit = result?.profit ?? 0
        let earned = result?.earned ?? 0
        try await say(other, "We took in $\(earned) today!", 2.2)
        if profit > 0 {
            try await say(lead, "That's $\(profit) profit after the setup fee!", 2.6)
        } else if profit == 0 {
            try await say(lead, "We broke even on the setup fee.", 2.4)
        } else {
            try await say(lead, "We lost $\(-profit) on the setup… but it sure was fun!", 2.8)
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
        // Only the three roommates are home in the morning (Tina and Amber stay at their apartment).
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
        let shopper = cast[(trips / 2 - 1) % cast.count]
        let others = cast.filter { $0 !== shopper }
        try await say(shopper, "That's two trips! I'm going shopping, and I'll put our money in the bank.", 3.2)
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
        let firstNight = trips == 2
        if firstNight { try await moveOn() }
        try await goToBed()
        if firstNight {
            try await salonEviction()
            try await shaveAtHome()
        }

        try await sceneChange {
            self.place = .house
            self.wakeUp()
        }
        caption = "The following morning…"
        sound.chime()
        try await sleep(1.2)
        try await say(others[1], "Good morning! I feel so rested!", 2.2)
        if firstNight { try await say(deidre, "I slept like a baby. First morning of my new life!", 2.8) }
        try await say(shopper, "Shall we do it again?", 1.8)
        try await gatherAtButton()
    }

    // MARK: Shaving a head bald

    /// The middle of `p`'s head and its radius, wherever she is standing or sitting.
    private func headOf(_ p: Person) -> (c: CGPoint, r: Double) {
        let pose = Pose(p, feet: CGPoint(x: p.x(at: .now), y: Stage.floorY), facing: p.facing, now: .now)
        return (pose.head, pose.hr)
    }

    /// A point over the top of `p`'s head: `u` runs from her left (-1) to right (1), `lift` head-radii above the crown.
    private func scalpPoint(_ p: Person, _ u: Double, _ lift: Double) -> CGPoint {
        let (c, r) = headOf(p)
        return CGPoint(x: c.x + u * r * 0.9, y: c.y - r * (lift + (1 - u * u) * 0.5))
    }

    /// Electric clippers take each head down to stubble. `pairs` are (who shaves, whose head); someone may do her own.
    private func clipHeads(_ pairs: [(Person, Person)], halfway: () -> Void = {}) async throws {
        for (shaver, _) in pairs { shaver.tool = .clippers }
        sound.buzz(true)
        clippings += pairs.map { _, head in
            let c = headOf(head).c
            return (c.x, c.y, head.style == .frizzy ? frizzPalette : [head.hair], .now, 6)
        }
        for i in 0..<10 {
            for (shaver, head) in pairs { shaver.reachTo = scalpPoint(head, Double(i % 5) / 2 - 1, i % 2 == 0 ? 0.6 : 0.45) }
            if i == 5 {
                for (_, head) in pairs { head.style = .buzzed }
                halfway()
            }
            try await sleep(0.6)
        }
        sound.buzz(false)
        for (shaver, _) in pairs { shaver.reachTo = nil }
        try await sleep(0.4)
    }

    /// Shaving cream, dab by dab, all over each stubbly scalp.
    private func latherHeads(_ pairs: [(Person, Person)]) async throws {
        for (shaver, _) in pairs { shaver.tool = .cream }
        for i in 0..<6 {
            for (shaver, head) in pairs {
                shaver.reachTo = scalpPoint(head, Double(i) / 2.5 - 1, 0.55)
                head.lather = Double(i + 1) / 6
            }
            try await sleep(0.5)
        }
        for (shaver, _) in pairs { shaver.reachTo = nil }
    }

    /// A hand razor wipes the cream away stroke by stroke, leaving each head bald and smooth.
    private func razorHeads(_ pairs: [(Person, Person)]) async throws {
        for (shaver, head) in pairs {
            shaver.tool = .razor
            head.style = .bald
        }
        for i in 0..<8 {
            let u = Double(i) / 3.5 - 1
            for (shaver, head) in pairs { shaver.reachTo = scalpPoint(head, u, 0.75) }
            sound.shutter()
            try await sleep(0.3)
            for (shaver, head) in pairs {
                shaver.reachTo = scalpPoint(head, u, 0.3)
                head.shaved = Double(i + 1) / 8
            }
            try await sleep(0.4)
        }
        for (shaver, head) in pairs {
            shaver.reachTo = nil
            shaver.tool = nil
            head.lather = 0
            head.shaved = 0
        }
        sound.shimmer()
    }

    // MARK: Meanwhile, at Shear Elegance

    /// The movers carry out the next pieces of the salon, one each.
    private func haulOut(_ movers: [Person], _ loads: [(item: SalonItem, x: Double)]) async throws {
        try await walkAll(zip(movers, loads).map { ($0, $1.x) }, speed: 190)
        for (m, load) in zip(movers, loads) {
            salonCleared.insert(load.item)
            m.carrying = true
            m.facing = -1
        }
        sound.clunk()
        try await sleep(0.4)
        try await walkAll(movers.prefix(loads.count).map { ($0, -60) }, speed: 190)
        for m in movers { m.carrying = false }
    }

    /// While the three of them sleep, the bank shuts down Shear Elegance in the middle of Tina and Amber's treatment.
    private func salonEviction() async throws {
        let (boss, tina, amber, banker) = (extras[3], extras[5], extras[2], extras[6])
        let movers = [extras[7], extras[8]]
        let chairs = [100 + Stage.salonChairOffset, 440 + Stage.salonChairOffset]
        try await sceneChange {
            self.place = .salon
            self.clippings = []
            self.salonCleared = []
            self.salonLightsOffT0 = nil
            self.show([boss, tina, amber])
            for (p, x) in zip([tina, amber], chairs) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.seated = true
            }
            (boss.x0, boss.x1, boss.moveDur, boss.facing) = (100, 100, 0, 1)
            self.cutNow(Stage.full)
        }
        caption = "Meanwhile, across town, Shear Elegance is open late…"
        try await sleep(2.4)
        try await look(at: Stage.shot(centerX: 320, height: 320))
        caption = "In the chairs: Tina, and Amber — Brad's new girlfriend."
        try await sleep(2.6)
        try await say(tina, "Where's Deidre tonight? She always does our hair.", 2.8)
        try await say(boss, "Never mind that. Tonight you get my special smoothing treatment!", 3)
        caption = "Lorraine paints the treatment through Tina's hair…"
        for i in 0..<4 {
            boss.reachTo = scalpPoint(tina, Double(i) / 1.5 - 1, 0.4)
            try await sleep(0.45)
        }
        boss.reachTo = nil
        tina.cap = true
        try await walk(boss, to: 440, speed: 110)
        boss.facing = 1
        caption = "…and Amber's, then covers them with processing caps."
        for i in 0..<4 {
            boss.reachTo = scalpPoint(amber, Double(i) / 1.5 - 1, 0.4)
            try await sleep(0.45)
        }
        boss.reachTo = nil
        amber.cap = true
        try await say(boss, "Twenty minutes, then we rinse it out. Not a minute more!", 2.8)

        // The bank's man walks in.
        try await look(at: Stage.full)
        banker.visible = true
        (banker.x0, banker.x1, banker.moveDur) = (-60, -60, 0)
        caption = "The door opens. A man in a dark suit walks in."
        try await walk(banker, to: 620, speed: 120)
        banker.facing = -1
        try await look(at: Stage.shot(centerX: 540, height: 300))
        try await say(banker, "I'm looking for Lorraine.", 2.2)
        try await walk(boss, to: 540, speed: 110)
        boss.facing = 1
        try await say(boss, "I'm Lorraine. Can I help you?", 2.2)
        try await say(banker, "By order of the bank, this salon is up for repossession, and so is your eqipment.", 3.2)
        boss.mood = .shocked
        try await say(boss, "Why?", 1.6)
        try await say(banker, "According to their records, you are several months behind.", 3.2)
        try await say(boss, "Months behind? There must be some mistake!", 2.6)
        try await say(banker, "Lorraine you need to calm down.", 2.4)

        // The movers strip the place while Lorraine chases after them.
        for m in movers {
            m.visible = true
            (m.x0, m.x1, m.moveDur) = (-60, -60, 0)
        }
        try await look(at: Stage.full)
        caption = "The movers start carrying out everything she owns."
        try await haulOut(movers, [(.dryer, 640), (.desk, Stage.ownerDeskX)])
        mention(boss, "Not my dryer! Not my desk!", 2.4)
        _ = beginWalk(boss, to: 300, speed: 150)
        try await haulOut(movers, [(.station(1), Stage.stationX), (.chair(1), Stage.stationX + Stage.salonChairOffset)])
        mention(tina, "Lorraine? Isn't it time to rinse?", 2.4)
        try await sleep(0.6)
        mention(boss, "Not now! Put that mirror back!", 2.4)
        // The movers come back in, and the first one has had enough of her.
        try await walkAll([(movers[0], 220), (movers[1], 160)], speed: 190)
        movers[0].facing = 1
        try await sleep(1)
        try await say(movers[0], "Lorraine, back off!", 2.4)
        try await haulOut(movers, [(.station(0), 100), (.station(2), 440)])
        caption = "Lorraine chases the movers in and out… and forgets all about the treatment."
        try await say(amber, "Hello? It's been way more than twenty minutes!", 2.6)
        try await sleep(0.8)

        // Too late: the caps come off.
        try await look(at: Stage.shot(centerX: 340, height: 320))
        caption = "Tina and Amber pull off their processing caps…"
        try await sleep(1.2)
        for p in [tina, amber] {
            p.cap = false
            p.style = .frizzy
            p.mood = .shocked
        }
        sound.clunk()
        shout([tina, amber], "AAAAH! My hair!", 2)
        try await sleep(2.2)
        try await say(amber, "It's all frizzy — and every color of the rainbow! Look at us!", 2.8)
        try await say(movers[0], "Sorry, ladies. We need those chairs.", 2.4)
        for p in [tina, amber] { p.seated = false }
        try await sleep(0.4)
        try await look(at: Stage.full)
        _ = beginWalk(tina, to: 230, speed: 120)
        try await walk(amber, to: 320, speed: 120)
        try await haulOut(movers, [(.chair(0), chairs[0]), (.chair(1), chairs[1])])
        salonCleared.insert(.chair(2))

        try await walk(boss, to: 400, speed: 140)
        boss.facing = -1
        (tina.facing, amber.facing) = (1, 1)
        try await look(at: Stage.shot(centerX: 320, height: 300))
        try await say(tina, "Where IS Deidre? She would never have let this happen!", 2.8)
        try await say(boss, "I… I laid her off.", 2.2)
        try await say(tina, "It seems you laid Deidre off. This serves you right, you idiot!", 3.4)
        try await say(amber, "Well Lorraine, if you don't pay your bills, this is what happens to you.", 3.2)
        try await say(amber, "There's only one way to fix this frizz.", 2.4)
        (tina.mood, amber.mood) = (.happy, .happy)
        try await say(tina, "Let's go home and shave it all off — clippers, shaving cream and a razor, just like Deidre does!", 3.6)
        amber.facing = 1
        try await say(amber, "And Lorraine? I'm not going to even pay you 2 cents.", 3)

        // Outside, the power company climbs the utility pole and cuts the salon's service wire.
        let inside = everyone.filter(\.visible)
        let lineman = extras[9]
        try await sceneChange {
            self.place = .salonFront
            self.show([lineman])
            (lineman.x0, lineman.x1, lineman.moveDur) = (Stage.W + 60, Stage.W + 60, 0)
            lineman.place(height: 0)
            self.cutNow(Stage.full)
        }
        caption = "Out on the street, a man from the power company walks up to the utility pole."
        try await walk(lineman, to: Stage.poleX + 24, speed: 140)
        lineman.facing = -1
        try await look(at: Stage.shot(centerX: Stage.poleX - 120, height: 380))
        try await say(lineman, "Shear Elegance. This bill hasn't been paid in months either.", 3)
        try await say(lineman, "Time to shut it off — right at the pole.", 2.4)
        caption = "He climbs up the pole, step by step."
        try await look(at: Stage.full)
        lineman.float(to: Stage.floorY - Stage.dropClamp.y - 110, over: 3)
        try await sleep(3.2)
        try await look(at: Stage.focus(CGPoint(x: Stage.poleX - 120, y: Stage.dropClamp.y + 40), height: 300))
        try await say(lineman, "Disconnecting service to the salon.", 2.2)
        lineman.reachTo = CGPoint(x: Stage.dropClamp.x - 4, y: Stage.dropClamp.y)
        try await sleep(0.8)
        sound.zap(true)
        sound.clunk()
        salonLightsOffT0 = .now
        caption = "Snap! He cuts the wire at the pole — sparks fly, and the salon goes dark."
        try await sleep(0.5)
        sound.zap(false)
        lineman.reachTo = nil
        try await sleep(0.7)
        try await look(at: Stage.full)
        lineman.float(to: 0, over: 2.4)
        try await sleep(2.6)
        try await say(lineman, "That's that.", 1.6)

        // Back inside, in the dark.
        try await sceneChange {
            self.place = .salon
            self.show(inside)
            self.cutNow(Stage.shot(centerX: 320, height: 300))
        }
        boss.mood = .shocked
        caption = "Inside, the lights go out on Lorraine's salon."
        try await say(boss, "Not the power too! My salon…", 2.4)
        try await say(tina, "That's our cue. Come on, Amber.", 2.2)
        _ = beginWalk(tina, to: -60, speed: 150)
        try await walk(amber, to: -60, speed: 150)
        try await look(at: Stage.full)
        caption = "Lorraine is left standing alone in her dark, empty salon."
        banker.facing = -1
        try await say(banker, "Keys, please.", 2)
        try await sleep(1)

        // Lorraine walks out of her dark, empty salon for the last time.
        caption = "Lorraine walks out the door for the last time, sobbing."
        boss.mood = .crying
        _ = beginWalk(banker, to: -60, speed: 110)
        try await walk(boss, to: 60, speed: 90)
        boss.facing = 1
        try await say(boss, "Ah cripes. All these beauty salon years down the drain.", 3)
        try await say(boss, "Might as well join the St. Baldrick's Foundation.", 2.8)
        boss.facing = -1
        try await walk(boss, to: -60, speed: 90)
        boss.mood = .happy
        for p in [boss, banker] { p.visible = false }
        try await sleep(1.6)
    }

    /// Back at their apartment, Tina and Amber each shave their own frizzy heads smooth.
    private func shaveAtHome() async throws {
        let (tina, amber) = (extras[5], extras[2])
        try await sceneChange {
            self.place = .bathroom
            self.clippings = []
            self.show([tina, amber])
            for (p, x) in zip([tina, amber], [480.0, 720]) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
            }
            self.cutNow(Stage.full)
        }
        caption = "Tina and Amber's apartment. They stand in front of the bathroom mirror."
        try await sleep(2)
        try await look(at: Stage.shot(centerX: 600, height: 320))
        try await say(amber, "Ready?", 1.4)
        try await say(tina, "Ready! Clippers first!", 2)
        caption = "Bzzzz… each of them runs the clippers over her own head."
        try await clipHeads([(tina, tina), (amber, amber)]) { self.caption = "Clumps of frizz fall into the sink and onto the floor." }
        shout([tina, amber], "So fuzzy!", 1.6)
        try await sleep(1.8)
        caption = "Next, shaving cream all over their scalps."
        try await latherHeads([(tina, tina), (amber, amber)])
        try await say(amber, "Brr, cold!", 1.6)
        caption = "Then, stroke by stroke, they go over it with hand razors."
        try await razorHeads([(tina, tina), (amber, amber)])
        caption = "They rinse off the last of the cream."
        try await sleep(1.2)
        (tina.facing, amber.facing) = (1, -1)
        try await say(tina, "Smooth as can be! No more frizz, ever!", 2.6)
        try await say(amber, "And no more Lorraine!", 2.2)
        try await say(tina, "I'm keeping it shaved from now on!", 2.4)
        try await say(amber, "Me too! We'll shave it every week, just like tonight.", 2.8)
        shout([tina, amber], "We look amazing!", 2)
        try await sleep(2.4)
    }

    /// The first night home, before bed, Deidre thinks about Brad and Amber one last time and decides to move on.
    private func moveOn() async throws {
        try await say(deidre, "Wait — before we sleep, there's something I need to say.", 2.6)
        deidre.facing = 1
        try await look(at: Stage.shot(centerX: deidre.x1, height: 250))
        try await say(deidre, "I've been thinking about Brad and Amber all day.", 2.6)
        try await say(deidre, "I could stay angry at them forever… but what's the point?", 2.8)
        try await say(deidre, "I lost my job, my car and my boyfriend in one day — and look at us now!", 3.2)
        try await say(deidre, "Brad and Amber deserve each other. I'm moving on.", 2.8)
        shout([kelly, jen], "Good for you, Deidre!", 2)
        try await sleep(2.2)
        try await say(deidre, "New job, new friends, new life. Goodnight, girls!", 2.6)
        caption = "Deidre lets it all go, and they all go to bed."
    }

    /// Further along Main Street: the accessory store, and the dealer, where the savings in the bank
    /// can buy a scooter or another car. Returns whatever she bought to take home.
    private func visitShops(_ shopper: Person) async throws -> Vehicle? {
        try await sceneChange {
            self.place = .shops
            (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
        }
        caption = "Further along Main Street: the accessory store."
        try await walk(shopper, to: Stage.boutiqueDoorX, speed: 140)
        shopper.facing = 0
        func affordable() -> Bool {
            Accessory.allCases.contains { !shopper.accessories.contains($0) && $0.price <= spendingMoney }
        }
        if shopper.accessories.count == Accessory.allCases.count {
            try await say(shopper, "I already have one of everything in there!", 2.4)
        } else if !affordable() {
            try await say(shopper, "Nothing I can afford today — we need the rest for a setup fee.", 2.8)
        } else {
            try await say(shopper, "Ooh, accessories! Let's have a look.", 2.2)
            shopper.visible = false
            caption = "\(shopper.id) browses the accessories. What should she buy?"
            var bought: [Accessory] = []
            choosingAccessory = shopper
            while affordable() {
                let pick = await withCheckedContinuation { cont in accessoryPick = cont }
                try Task.checkCancellation()
                guard let pick else { break }
                cash -= pick.price
                shopper.accessories.insert(pick)
                bought.append(pick)
                cashPop = ("-$\(pick.price)", .now, Stage.boutiqueDoorX)
                sound.pay()
                caption = "\(shopper.id) buys \(pick.phrase) for $\(pick.price)."
            }
            choosingAccessory = nil
            try await sleep(bought.isEmpty ? 0.4 : 1.4)
            shopper.visible = true
            shopper.facing = 0
            if bought.isEmpty {
                caption = "\(shopper.id) decides to save her money."
                try await say(shopper, "Just looking today.", 1.8)
            } else {
                caption = "\(shopper.id) comes out wearing \(ListFormatter.localizedString(byJoining: bought.map(\.phrase)))."
                try await say(shopper, "How do I look?", 2.2)
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

    // MARK: A roommate's little sister

    /// The morning after every odd night, one roommate's mother (Kelly's, then Jen's, then Deidre's, in turn) comes over
    /// to do her a favor and leaves the little sister with the other two. They take her along to earn some money for her
    /// mother, and she gets a third of the profit. When her mother gets home she has a go too — with no idea what's coming —
    /// while her daughter and one other roommate stay behind. Then mother and little sister both go home.
    private func babysitting() async throws {
        // The families take turns: Kelly's, then Jen's, then Deidre's, and round again.
        let daughter = [kelly, jen, deidre][familyVisits % 3]
        familyVisits += 1
        let others = cast.filter { $0 !== daughter }
        let (friendA, friendB) = (others[0], others[1])
        let age = Int.random(in: 4...6)
        family = Self.makeFamily(age: age, for: daughter.id)
        let (mom, sophie) = (family[0], family[1])
        let errand = ["DMV to renew your license", "dentist", "furniture store to pick out that new couch", "eye doctor"].randomElement()!

        // Ding-dong
        try await look(at: Stage.full)
        sound.chime()
        caption = "Ding-dong! It's \(daughter.id)'s mother, \(mom.id), with \(daughter.id)'s little sister \(sophie.id), who is \(age)."
        for p in family { p.visible = true }
        for (p, x) in [(daughter, 505.0), (friendA, 565), (friendB, 615)] { _ = beginWalk(p, to: x, speed: 120) }
        try await walkAll([(mom, 445), (sophie, 472)], speed: 150)
        for p in family { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(daughter, "Hi, Mom! Hi, \(sophie.id)!", 2)
        try await say(sophie, "Hi, \(daughter.id)!", 1.6)
        try await say(mom, "Ready, honey? I'm driving you to the \(errand).", 2.8)
        try await say(mom, "\(friendA.id), \(friendB.id) — could you watch \(sophie.id) for me while we're gone?", 3)
        try await say(friendA, "Of course, \(mom.id)!", 1.8)
        try await say(friendB, "We'd love to!", 1.6)
        try await say(mom, "Be good, sweetie. We'll be back this afternoon.", 2.6)
        try await say(sophie, "Bye, Mommy! Bye, \(daughter.id)!", 2)
        caption = "\(daughter.id) and her mother head out."
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
        try await say(friendA, "See this glowing pink button? It calls a flying tent full of alien clowns!", 3)
        try await say(sophie, "Clowns?! Can I be a clown too?", 2.2)
        try await say(friendB, "You sure can. Let's call the flying tent!", 2.4)

        // Sophie's trip: she asks the passers-by, one of them takes the money and the other works the machine.
        let (taker, worker) = Bool.random() ? (friendB, friendA) : (friendA, friendB)
        team = [sophie, taker, worker]
        let trio = [friendA, sophie, friendB]
        try await callTheTent(trio, pusher: sophie, caller: friendB, seated: trio)
        try await transformAgain(trio, welcome: "Welcome back! And who's this little one? Everybody pick a type of alien clown!",
                                 legsStartLine: (sophie, "Hee hee! It tickles my toes!"), bodyLine: (friendA, "Here we go again!"))
        try await snap(trio)
        unstrap(trio)
        try await say(leader, "\(sophie.id) will ask the customers, \(taker.id) takes the money, and \(worker.id) works the machine.", 3.4)
        try await tripToVenue()
        try await comeHome(first: false, gather: false)

        // One third of the profit is Sophie's.
        let profit = result?.profit ?? 0
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
        caption = "That afternoon, \(daughter.id) and her mother come home."
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
        // Linda gets no explanation — she'll find out once she's up in the tent.
        try await say(sophie, "It's a secret!", 1.8)
        mom.mood = .happy
        try await say(mom, "A secret? \(friendA.id), \(friendB.id) — what have you girls been up to?", 3)
        try await say(taker, "It's easier to show you than to tell you.", 2.4)
        try await say(worker, "Come along with \(sophie.id) and me, and you'll see!", 2.4)
        sophie.facing = 1
        try await say(sophie, "Come with us, Mommy! Please?", 2.2)
        try await say(mom, "Well… now I have to know! All right, I'll come.", 2.6)
        try await say(daughter, "I'll stay behind and put my feet up. You're in for a surprise, Mom!", 3)
        try await say(taker, "I'll stay here with \(daughter.id). Have fun, you three!", 2.6)

        // Linda's trip: just Linda, Sophie and one roommate. Nobody tells Linda a thing about the change —
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
        try await say(leader, "\(mom.id) asks the customers, \(sophie.id) takes the money, and \(worker.id) works the machine.", 3.4)
        try await tripToVenue()
        try await comeHome(first: false, gather: false, stayedHome: [daughter, taker])

        // Linda and Sophie get one third of the profit.
        let momShare = max(0, (result?.profit ?? 0) / 3)
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

    /// Each visit is two trips and ends with another night: after an odd night a roommate's mom drops off her
    /// little sister (Kelly's, Jen's, Deidre's in turn); after an even night Brad drops off Amber.
    private func morningVisit() async throws {
        if trips % 4 == 2 {
            try await babysitting()
        } else {
            try await amberVisit()
        }
        try await restUntilMorning()
    }

    // MARK: Brad drops off Amber

    /// The morning after every even night, Brad leaves Amber with Deidre while he's at work. Amber spots the glowing
    /// pink button and goes on two trips with Deidre and one roommate while the other stays home. That evening Brad
    /// is waiting in the yard; Amber shows him the money she made for him and tells him the whole story.
    private func amberVisit() async throws {
        let (brad, amber) = (extras[1], extras[2])
        let buddy = Bool.random() ? kelly : jen
        let stayer = buddy === kelly ? jen : kelly
        let trio = [deidre, amber, buddy]   // Amber in the middle chair
        for p in [brad, amber] { p.mood = .happy }
        amber.style = .bald   // shaved smooth at home after the salon disaster
        guest = amber
        amberVisits += 1

        // Ding-dong
        try await look(at: Stage.full)
        sound.chime()
        caption = "Ding-dong! It's Brad — with Amber."
        for (p, x) in [(brad, -80.0), (amber, -40)] {
            (p.x0, p.x1, p.moveDur) = (x, x, 0)
            p.visible = true
        }
        for (p, x) in [(deidre, 505.0), (kelly, 565), (jen, 615)] { _ = beginWalk(p, to: x, speed: 120) }
        try await walkAll([(brad, 445), (amber, 418)], speed: 150)
        for p in [brad, amber] { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 500, height: 250))
        try await say(deidre, "Brad? Amber? What brings you two here?", 2.4)
        if amberVisits == 1 {
            try await look(at: Stage.shot(centerX: 470, height: 220))
            deidre.mood = .shocked
            try await say(deidre, "Amber! What happened to your hair?", 2.4)
            deidre.mood = .happy
            try await say(amber, "Oh, Deidre — you won't believe it. Tina and I went to Shear Elegance last night.", 3.4)
            try await say(amber, "Lorraine said she'd give us her special smoothing treatment, and put caps on us.", 3.4)
            try await say(amber, "Then a man from the bank walked in and said she was months behind on her bills!", 3.4)
            try await say(amber, "Movers carried out everything — and Lorraine forgot all about our treatment.", 3.2)
            try await say(amber, "When we took the caps off, our hair was all frizzy, every color of the rainbow!", 3.4)
            try await say(amber, "Then the power company shut off her electricity, and the whole salon went dark.", 3.2)
            try await say(amber, "So Tina and I went home and shaved it all off — clippers, cream and a razor, just like you do.", 3.6)
            // Deidre can't hold it in — a big belly laugh.
            caption = "Deidre bursts out laughing."
            deidre.mood = .beaming
            for (text, size) in [("Ha… ha ha…", 16.0), ("HA HA HA HA!", 21), ("HAHAHAHAHA!!", 26)] {
                deidre.voice = size
                try await say(deidre, text, 1.6)
            }
            deidre.voice = 15
            try await say(deidre, "Oh, I'm sorry, Amber — I can't help it! Lorraine lost the salon?!", 3)
            try await say(deidre, "After laying me off? I guess she had it coming!", 2.6)
            deidre.mood = .happy
            try await say(amber, "Honestly, I love it. No more bad hair days — ever!", 2.6)
            try await say(brad, "I think it looks great on her.", 2.2)
            try await look(at: Stage.shot(centerX: 500, height: 250))
        }
        try await say(brad, "Morning, Deidre. I have to attend an important meeting at work…", 2.8)
        try await say(brad, "…and I won't be home until tonight.", 2.2)
        try await say(brad, "Would you keep Amber company until I get back?", 2.6)
        try await say(deidre, "Sure, Brad. We'll keep her company.", 2.2)
        try await say(amber, "Thanks, Deidre! I won't be any trouble, I promise.", 2.6)
        try await say(brad, "See you tonight, Amber!", 1.8)
        caption = "Brad heads off to work."
        try await walk(brad, to: -80, speed: 150)
        brad.visible = false

        // The glowing pink button
        caption = "Amber notices something glowing in the living room…"
        try await walk(amber, to: 470, speed: 100)
        amber.facing = 1
        try await look(at: Stage.shot(centerX: 520, height: 230))
        try await say(amber, "Ooh! What's this glowing pink button?", 2.2)
        try await say(deidre, "That's our new moneymaker!", 2)
        try await say(amber, "A moneymaker? How does it work?", 2.2)
        try await say(buddy, "Come along with Deidre and me, and you'll see. You're going to love it!", 3)
        try await say(stayer, "I'll stay home and hold down the fort. Have fun, you three!", 2.8)
        try await say(amber, "Count me in!", 1.6)

        // Amber's first time: everyone tells her what a treat she's in for.
        try await callTheTent(trio, pusher: amber, caller: buddy, seated: trio, newcomer: amber)
        try await look(at: Stage.chairsView)
        try await say(amber, "A real circus tent in the sky! This is amazing!", 2.6)
        try await say(leader, "Welcome aboard, Amber! You're in for a real treat.", 2.6)
        try await say(leader, "Our glowing pink button turns you into an alien clown — from your toes to the top of your head!", 3.4)
        try await say(amber, "An alien clown? Ooh, how fun!", 2.2)
        try await say(deidre, "It feels wonderful, Amber. And it wears off in eight hours.", 2.8)
        try await say(buddy, "Then we fly off and turn paying customers into clowns too!", 2.8)
        try await strap(trio)
        caption = "Straps snap across all three of them."
        try await say(amber, "Ooh, seat belts! Here we go!", 2)
        let picks = try await pickKinds(trio)
        let firstKind = picks[1].1
        try await look(at: Stage.full)
        try await say(leader, "Just relax and enjoy it.", 2)
        caption = "The alien clown presses the glowing pink button…"
        amber.mood = .happy
        try await runMachine(picks, presser: leader, change: Machine.change,
                             tingleLine: (amber, "Ooh, it tickles!"),
                             legsStartLine: (amber, "Look, my legs are changing! So cool!"),
                             bodyLine: (amber, "I'm really turning into an alien clown!"),
                             faceShouts: (amber, [("Ooh, my face is getting all bubbly…", 15), ("Yippeeeeeee!", 17)]), beamOnShout: 1)
        try await look(at: Stage.full)
        try await say(leader, "Have a look!", 1.8)
        caption = "The alien clowns lower the big mirror…"
        try await showMirror(trio, caption: "…and Amber sees an alien clown looking back!", calm: [amber])
        try await look(at: Stage.chairsView)
        for (p, kind) in [picks[1], picks[0], picks[2]] {
            try await say(p, reaction(kind), 2.4)
            if let line = kind.noseLine { try await say(p, line, 2) }
        }
        try await say(amber, "I love it! Best day ever!", 2.2)
        try await snap(trio)
        unstrap(trio)

        // Trip one: Amber asks the customers.
        team = [amber, deidre, buddy]
        try await say(leader, "Amber asks the customers, Deidre takes the money, and \(buddy.id) works the machine.", 3.4)
        try await tripToVenue()
        let firstVenue = result?.venue
        try await comeHome(first: false, gather: false, stayedHome: [stayer])
        var made = 0
        let firstShare = max(0, (result?.profit ?? 0) / 3)
        if firstShare > 0 {
            caption = "Amber gets one third of the profit: $\(firstShare)."
            try await say(deidre, "Amber, one third of the profit is yours — $\(firstShare)!", 2.8)
            cash -= firstShare
            made += firstShare
            cashPop = ("-$\(firstShare) to Amber", .now, amber.x(at: .now))
            sound.pay()
            try await say(amber, "$\(firstShare)! I'm saving every penny for Brad!", 2.6)
        } else {
            try await say(deidre, "No profit to share this time, Amber — sorry!", 2.4)
            try await say(amber, "That's okay! Can we go again?", 2)
        }

        // Trip two, before Brad gets home.
        try await say(deidre, "One more trip before Brad gets back!", 2.2)
        try await callTheTent(trio, pusher: amber, caller: deidre, seated: trio)
        try await transformAgain(trio, quick: true, welcome: "Welcome back, Amber! Pick your clowns, everybody!",
                                 legsStartLine: (amber, "Here we go again! Wheee!"))
        let secondKind = amber.clown ?? firstKind
        try await snap(trio)
        unstrap(trio)
        team = [deidre, amber, buddy]
        try await say(leader, "This time Deidre asks the customers, Amber takes the money, and \(buddy.id) works the machine.", 3.4)
        try await tripToVenue()
        let secondVenue = result?.venue

        // That evening Brad is waiting in the front yard when the tent lands.
        try await comeHome(first: false, gather: false, stayedHome: [stayer], waiting: brad,
                           waitingLines: ("What the…?! A circus tent — FLYING?!", "Holy cow! Clowns are coming down out of a pink beam!")) {
            brad.mood = .shocked
            try await self.say(brad, "Whoa! Alien clowns just beamed down in front of Deidre's house!", 2.8)
            try await self.say(brad, "Am I dreaming? I only had one coffee at that meeting!", 2.8)
            amber.facing = -1
            try await self.say(amber, "Brad! It's me, Amber!", 2)
            try await self.say(brad, "AMBER?!", 1.6)
            try await self.say(amber, "Just wait a minute — you'll see!", 2)
            amber.facing = 0
        }
        let secondShare = max(0, (result?.profit ?? 0) / 3)
        if secondShare > 0 {
            try await say(deidre, "And another third for you, Amber — $\(secondShare)!", 2.6)
            cash -= secondShare
            made += secondShare
            cashPop = ("-$\(secondShare) to Amber", .now, amber.x(at: .now))
            sound.pay()
        }

        // Amber shows Brad what she made for him.
        brad.mood = .happy
        try await walkAll([(amber, 92), (deidre, 160), (buddy, 205)], speed: 120)
        amber.facing = -1
        brad.facing = 1
        try await look(at: Stage.shot(centerX: 110, height: 230))
        if made > 0 {
            amber.reachTo = CGPoint(x: 66, y: Stage.floorY - 70)
            sound.pay()
            try await say(amber, "Brad, look — I made $\(made) for you today!", 2.8)
            amber.reachTo = nil
            brad.mood = .shocked
            try await say(brad, "$\(made)?! How did you ever make all that money?", 2.6)
        } else {
            try await say(amber, "Brad! I didn't make any money for you today… but I had the best day ever!", 3)
            brad.mood = .shocked
            try await say(brad, "And what was all that about alien clowns?!", 2.4)
        }
        brad.mood = .happy

        // …and tells him the whole story.
        caption = "Amber tells Brad the whole story."
        try await say(amber, "Deidre has a glowing pink button in her living room. I asked about it, and she said it's their new moneymaker!", 4)
        try await say(amber, "I pressed it, and a flying circus tent full of alien clowns came down and beamed us right up!", 3.6)
        try await say(amber, "They strapped us into chairs, pressed another pink button, and turned us into alien clowns — from our toes to our faces!", 4.2)
        try await say(amber, firstKind == secondKind ? "I was \(firstKind.name) both times!"
                                                      : "I was \(firstKind.name) the first time and \(secondKind.name) the second!", 2.6)
        let places = firstVenue == secondVenue ? (firstVenue.map { "\($0.theName) — twice" } ?? "")
                                               : ListFormatter.localizedString(byJoining: [firstVenue, secondVenue].compactMap { $0?.theName })
        try await say(amber, "Then the tent flew us to \(places), and we turned customers into alien clowns too — they paid us for it!", 4.2)
        try await say(amber, "When the tent brought us home, it wore off — halfway first, then all the way. That's what you just saw!", 3.8)
        try await say(brad, "You were an ALIEN CLOWN? That's incredible!", 2.4)
        if made > 0 { try await say(amber, "And a third of the profit was mine — all for you!", 2.4) }

        // Goodbyes
        caption = "\(stayer.id) comes out to say goodbye."
        try await look(at: Stage.yardView)
        try await walk(stayer, to: 250, speed: 150)
        for p in cast { p.facing = -1 }
        try await say(amber, "Thank you for keeping me company, everyone. I had so much fun!", 2.8)
        shout(cast, "Bye, Amber!", 1.8)
        try await sleep(2)
        try await say(brad, "Deidre — thank you for keeping Amber company today. I really appreciate it.", 3.2)
        try await say(deidre, "You're welcome, Brad. Take good care of her.", 2.4)
        try await say(brad, "Goodnight, girls!", 1.6)
        try await say(amber, "Bye! Honk honk!", 1.6)
        caption = "Brad and Amber head home."
        try await walkAll([(brad, -90), (amber, -50)], speed: 150)
        for p in [brad, amber] { p.visible = false }
        guest = nil
        try await look(at: Stage.full)
        try await walkAll(zip(cast, Stage.livingX).map { ($0, $1) }, speed: 140)
    }

    /// Press the pink button: the tent comes back, and everyone picks her own type of clown.
    private func doItAgain() async throws {
        try await say(deidre, "Let's do it again!", 1.8)
        rotation += 1
        team = (0..<3).map { cast[(rotation + $0) % 3] }
        try await callTheTent(cast, pusher: cast.randomElement()!, caller: kelly, seated: cast)
        try await transformAgain(cast, legsStartLine: (jen, "I feel funny again!"), bodyLine: (kelly, "We're being transformed again!"))
        try await snap(cast)
        unstrap(cast)
    }

    /// `pusher` presses the glowing pink button in the living room, and the flying tent pulls `riders` up out of the front yard.
    /// Inside, `seated` are in the chairs and anyone else stands by on the left.
    /// A `newcomer` has never seen the tent before, and is delighted by it.
    private func callTheTent(_ riders: [Person], pusher: Person, caller: Person, seated: [Person], newcomer: Person? = nil,
                             newcomerLines: (spot: String, beam: String) = ("Oh, how fun! A flying circus tent!", "Wheee!")) async throws {
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

        caption = "…and the flying tent comes back to take them to the clowns' setup!"
        try await look(at: Stage.full)
        tentShown = true
        moveTent(to: CGPoint(x: Stage.yardTentX - 400, y: -170), over: 0)
        moveTent(to: CGPoint(x: Stage.yardTentX, y: Stage.floorY - Stage.hoverLift), over: 3)
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
        caption = newcomer.map { "The tent pulls them in — \($0.id) too!" } ?? "The tent pulls them in again!"
        if let n = newcomer { shout([n], newcomerLines.beam, 2) }
        try await beamUp(riders)
        moveTent(to: CGPoint(x: Stage.yardTentX + 500, y: -220), over: 2.2)
        try await sleep(1.9)

        try await sceneChange {
            self.place = .bigTop
            self.tentShown = false
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
