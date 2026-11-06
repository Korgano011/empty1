import SwiftUI

/// Something sliding along the street.
struct Slide {
    var from = 0.0, to = 0.0, t0 = Date.distantPast, dur = 0.0
    /// Pulls away slowly at first rather than rolling at a steady speed.
    var accelerate = false

    func x(at now: Date) -> Double {
        let u = min(max(now.timeIntervalSince(t0) / max(dur, 0.001), 0), 1)
        return from + (to - from) * (accelerate ? u * u : u)
    }

    static func parked(at x: Double) -> Slide { Slide(from: x, to: x) }
}

/// Thrown when the player chooses End Game.
struct EndGame: Error {}

/// What a visitor says on her first ride, start to finish — everyone loves it in her own way.
struct Intro {
    var spot, beamUp, inPod, whatsNext, straps, tingle, legs, body, face, faceShout, headFeel, secret, bestDay: String
    var again = "Here we go again!"
}

/// Runs the story. Only sets timestamps, positions and captions; Scene.swift
/// derives every frame from them.
@MainActor @Observable
final class Director {
    var debbie: Person
    var hailey: Person
    var molly: Person

    var cast: [Person] { [debbie, hailey, molly] }
    /// Nobody else for now.
    var extras: [Person] = []
    /// The flying zoo's alien animals; the last one is their commander.
    var crew: [Person] = []
    var customers: [Person] = []
    /// An aunt and cousin, or a babysitter, visiting for the day.
    var visitors: [Person] = []
    /// Who is on this trip: greeter, cashier, machinist.
    var team: [Person] = []
    var everyone: [Person] { cast + visitors + extras + crew + customers }
    /// The top-right meters: the family at home, plus any visitors once they have changed.
    var hudPeople: [Person] { cast.filter(\.visible) + visitors.filter { $0.animal != nil } }
    private var leader: Person { crew[crew.count - 1] }

    var caption = "Tap Start to begin."
    var running = false
    var finished = false
    var muted = false { didSet { sound.muted = muted; poker?.voice.muted = muted } }

    var place = Place.house
    /// The glowing red button the alien animals leave in the living room (no longer used: the cottage console has it).
    var buttonShown = false
    var buttonPressT0 = Date.distantPast

    // The spare room: the Animals of Poker machine and its mini saucer
    /// The sitting being played right now; ContentView puts the machine's screen up while it's set.
    var poker: PokerSession?
    var pokerScreen = "INSERT CREDITS"
    var miniShown = false
    /// Who is hiding under her blanket in bed (drawn as a trembling lump).
    var hiding: String?
    var miniBeamOn = false
    var miniBeamT0 = Date.distantPast
    var miniBeamTint = Color.green
    private var miniFrom = CGPoint.zero
    private var miniTo = CGPoint.zero
    private var miniT0 = Date.distantPast
    private var miniDur = 0.0

    // The backyard cottage, once the flying zoo installs its transformation machine
    var cottageMachine = false
    var cottageMachineT0 = Date.distantFuture

    // The flying zoo
    var podShown = false
    /// Clouds streak past the zoo's windows.
    var podFlying = false
    var beamOn = false
    var beamT0 = Date.distantPast
    private var podFrom = CGPoint.zero
    private var podTo = CGPoint.zero
    private var podT0 = Date.distantPast
    private var podDur = 0.0

    // The transformation chairs
    var strapped: Set<String> = []
    var strapT0 = Date.distantPast
    var consolePressT0 = Date.distantPast
    var screen = "READY"
    var mirrorT0 = Date.distantFuture
    var mirrorUpT0 = Date.distantPast
    /// Who the mirror reflects when it's a standing mirror in the house or spare room (not the chairs).
    var mirrorFolks: [String] = []
    /// Whoever is waiting for the player to pick her type of alien animal.
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
    var night = false
    var sleeping: Set<String> = []
    /// The babysitter, staying over on the couch.
    var couchSleeper: Person?

    // Trips to venues
    var venue: Venue?
    var choosingVenue = false
    var choosingNext = false
    var nextPrompt = ""
    var choosingVacation = false
    var cash = Venue.startCash
    var cashPop: (text: String, t0: Date, x: Double)?
    var result: EventRecord?
    var trips = 0
    /// The jobs rotate each time they do it again, so everyone gets a turn working the machine.
    var rotation = 0
    var nights = 0
    var auntVisits = 0
    var sitterVisits = 0
    var totalProfit = 0
    var totalTransformed = 0
    /// What has gone into the bank; setup fees come out of `cash` only.
    var bank = 0
    var vehicles: Set<Vehicle> = []
    /// The one being brought home from the dealer right now, and whoever is riding it.
    var arriving: Vehicle?
    var rider: Person?
    private var arriveT0 = Date.distantPast
    var choosingVehicle = false

    /// The last saved morning, if there is one: "Continue" picks the game up from there.
    var saved: SaveGame? = SaveGame.load()

    // Card games hosted at home
    /// Waiting for you to pick a flying zoo trip or a card game.
    var choosingOuting = false
    var cardGames = 0
    /// The scoreboard while a game is on; the table view seats one person per row.
    var board: TableBoard?
    /// Who sits in each scoreboard row.
    var tableSeats: [Person] = []
    /// The cards on the table, by game seat.
    var tableGroups: [FeltGroup] = []
    /// Your scoreboard row, if you're playing.
    var humanRow: Int?
    /// Who you are at this table, if you're playing.
    var you: String?
    /// Your cards, shown along the bottom of the table.
    var myHand: [PlayingCard] = []
    /// What the table is waiting for you to decide.
    var prompt: PlayerPrompt?
    /// Let the computer make your plays.
    var autoPlay = false

    static let vacationCost = 150

    @ObservationIgnored let sound = Sound()
    @ObservationIgnored let album = AlbumStore()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var venuePick: CheckedContinuation<Venue, Never>?
    @ObservationIgnored private var kindPick: CheckedContinuation<AnimalKind, Never>?
    @ObservationIgnored private var nextPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var vacationPick: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var vehiclePick: CheckedContinuation<Vehicle?, Never>?
    @ObservationIgnored private var pokerDone: CheckedContinuation<Void, Never>?
    /// Credits still on the Animals of Poker when the last player reached game 10; they're paid out to the family.
    @ObservationIgnored private var leftoverCredits = 0
    @ObservationIgnored private var outingPick: CheckedContinuation<Outing, Never>?
    @ObservationIgnored private var answerWait: CheckedContinuation<PlayerAnswer, Never>?
    /// What the computer would have played, used if you switch on auto-play or start over mid-question.
    @ObservationIgnored private var answerAuto: PlayerAnswer?
    @ObservationIgnored private var guestWomen: [String] = []
    @ObservationIgnored private var guestKids: [String] = []
    /// Someone new to all this, and what she says when the zoo comes to pick them up.
    @ObservationIgnored private var pickupNewcomer: (Person, (spot: String, beam: String))?
    @ObservationIgnored private var served: [PersonSpec] = []
    @ObservationIgnored private var asked = 0
    @ObservationIgnored private var earned = 0
    @ObservationIgnored private var adultNames: [String] = []
    private static let menNames = ["Carlos", "Eddie", "Hank", "Jamal", "Steve", "Victor", "Kenji", "Luis"]
    private static let womenNames = ["Gina", "Iris", "Paula", "Nadia", "Leilani", "Carmen", "Stacy", "Irene", "Lori", "Dawn"]
    @ObservationIgnored private var momNames: [String] = []
    @ObservationIgnored private var kidNames: [String] = []

    init() {
        (debbie, hailey, molly) = Self.makeCast()
        team = [debbie, hailey, molly]
    }

    /// Two go outside — the first asks passers-by, the second takes the money — and one stays in to work the machine.
    private var roles: (greeter: Person, cashier: Person, machinist: Person) { (team[0], team[1], team[2]) }

    private static let casualShirt = RGB(r: 0.20, g: 0.60, b: 0.65)

    private static func makeCast() -> (Person, Person, Person) {
        let skin = RGB(r: 0.96, g: 0.80, b: 0.68)
        let debbie = Person("Debbie", height: 162, skin: skin, hair: RGB(r: 0.50, g: 0.28, b: 0.14), style: .long,
                            shirt: RGB(r: 0.12, g: 0.12, b: 0.16), pants: RGB(r: 0.10, g: 0.10, b: 0.12), shorts: false, x: -60)
        let hailey = Person("Hailey", height: 126, headScale: 0.15, skin: skin, hair: RGB(r: 0.55, g: 0.35, b: 0.18), style: .ponytail,
                            shirt: RGB(r: 0.95, g: 0.45, b: 0.65), pants: RGB(r: 0.35, g: 0.45, b: 0.75), kid: true, x: Stage.livingX[1])
        let molly = Person("Molly", height: 98, headScale: 0.165, skin: skin, hair: RGB(r: 0.88, g: 0.72, b: 0.40), style: .pigtails,
                           shirt: RGB(r: 0.55, g: 0.80, b: 0.40), pants: RGB(r: 0.95, g: 0.75, b: 0.30), kid: true, x: Stage.livingX[2])
        for p in [debbie, hailey, molly] { p.visible = false }
        return (debbie, hailey, molly)
    }

    // MARK: Visitors

    private static let auntLooks: [(aunt: String, cousin: String, skin: RGB, auntHair: RGB, auntStyle: HairStyle, kidHair: RGB, kidStyle: HairStyle, auntShirt: RGB, kidShirt: RGB)] = [
        ("Carol", "Emma", RGB(r: 0.96, g: 0.80, b: 0.68), RGB(r: 0.72, g: 0.36, b: 0.16), .bob, RGB(r: 0.80, g: 0.45, b: 0.20), .ponytail,
         RGB(r: 0.30, g: 0.60, b: 0.45), RGB(r: 1.0, g: 0.85, b: 0.30)),
        ("Rosa", "Mia", RGB(r: 0.80, g: 0.60, b: 0.45), RGB(r: 0.08, g: 0.06, b: 0.06), .long, RGB(r: 0.08, g: 0.06, b: 0.06), .pigtails,
         RGB(r: 0.55, g: 0.30, b: 0.70), RGB(r: 0.45, g: 0.80, b: 0.90)),
        ("Linda", "Sophie", RGB(r: 0.85, g: 0.65, b: 0.50), RGB(r: 0.22, g: 0.16, b: 0.12), .bun, RGB(r: 0.10, g: 0.10, b: 0.10), .pigtails,
         RGB(r: 0.85, g: 0.40, b: 0.55), RGB(r: 1.0, g: 0.62, b: 0.76)),
        ("Gail", "Chloe", RGB(r: 0.99, g: 0.86, b: 0.76), RGB(r: 0.92, g: 0.78, b: 0.42), .ponytail, RGB(r: 0.92, g: 0.80, b: 0.45), .short,
         RGB(r: 0.25, g: 0.45, b: 0.85), RGB(r: 0.95, g: 0.30, b: 0.30)),
        ("Brenda", "Zoe", RGB(r: 0.62, g: 0.44, b: 0.32), RGB(r: 0.12, g: 0.08, b: 0.06), .curly, RGB(r: 0.12, g: 0.08, b: 0.06), .curly,
         RGB(r: 0.90, g: 0.20, b: 0.50), RGB(r: 0.70, g: 0.50, b: 0.95)),
    ]

    /// An aunt and her little daughter, who is `age`.
    private static func makeAunt(_ i: Int, age: Int) -> (aunt: Person, cousin: Person) {
        let l = auntLooks[i % auntLooks.count]
        let aunt = Person("Aunt \(l.aunt)", height: 160, skin: l.skin, hair: l.auntHair, style: l.auntStyle,
                          shirt: l.auntShirt, pants: RGB(r: 0.30, g: 0.30, b: 0.42), shorts: false, x: -60)
        let cousin = Person(l.cousin, height: 90 + Double(age - 3) * 8, headScale: 0.165, skin: l.skin, hair: l.kidHair,
                            style: l.kidStyle, shirt: l.kidShirt, pants: RGB(r: 0.55, g: 0.75, b: 0.95), kid: true, x: -60)
        for p in [aunt, cousin] { p.visible = false }
        return (aunt, cousin)
    }

    private static let sitterLooks: [(name: String, skin: RGB, hair: RGB, style: HairStyle, shirt: RGB)] = [
        ("Kayla", RGB(r: 0.99, g: 0.86, b: 0.76), RGB(r: 0.92, g: 0.78, b: 0.42), .ponytail, RGB(r: 1.0, g: 0.55, b: 0.70)),
        ("Megan", RGB(r: 0.96, g: 0.80, b: 0.68), RGB(r: 0.45, g: 0.28, b: 0.14), .bob, RGB(r: 0.30, g: 0.55, b: 0.80)),
        ("Brittany", RGB(r: 0.99, g: 0.86, b: 0.76), RGB(r: 0.75, g: 0.32, b: 0.14), .long, RGB(r: 0.95, g: 0.75, b: 0.20)),
        ("Jasmine", RGB(r: 0.55, g: 0.38, b: 0.26), RGB(r: 0.10, g: 0.08, b: 0.08), .curly, RGB(r: 0.60, g: 0.40, b: 0.80)),
        ("Tess", RGB(r: 0.85, g: 0.65, b: 0.50), RGB(r: 0.30, g: 0.18, b: 0.10), .bun, RGB(r: 0.30, g: 0.62, b: 0.40)),
    ]

    private static func makeSitter(_ i: Int) -> Person {
        let l = sitterLooks[i % sitterLooks.count]
        let p = Person(l.name, height: 158, skin: l.skin, hair: l.hair, style: l.style, shirt: l.shirt,
                       pants: RGB(r: 0.25, g: 0.30, b: 0.50), x: -60)
        p.visible = false
        return p
    }

    static func auntIntro(_ name: String, kid: String) -> Intro {
        switch name {
        case "Aunt Carol": Intro(
            spot: "Well, I'll be! A flying zoo over the backyard!", beamUp: "Up, up and awaaay!",
            inPod: "Oh my stars — a whole barnyard of aliens! Hello there, fellas!", whatsNext: "\(kid), sweetheart, I haven't been this excited since the county fair!",
            straps: "Buckled in, just like a roller coaster. I love roller coasters!", tingle: "Hee hee! It's like a hundred little feathers!",
            legs: "My legs are all furry — how cozy!", body: "A tail AND big strong arms? I could do twice the canning!",
            face: "Ooh, my nose is getting bigger and bigger…", faceShout: "Yahoooooooo!",
            headFeel: "Animal ears! Well, I'll be — I can hear a pin drop!", secret: "So THAT'S how \(kid) made the money! Count me in!",
            bestDay: "Best day of my life, and I've been to Dollywood!")
        case "Aunt Rosa": Intro(
            spot: "¡Ay, qué bonito! A flying zoo!", beamUp: "¡Wepa! Here I gooo!",
            inPod: "¡Mira! Animals everywhere! Hola, everybody!", whatsNext: "\(kid), mija, your abuela will never believe this!",
            straps: "Seat belts? Good — I want to stay for the whole show!", tingle: "Oh, that's a happy little tingle!",
            legs: "Look at my legs — I feel like dancing salsa!", body: "My whole body is getting furry! ¡Fantástico!",
            face: "Ooh, now my face… I have a snout!", faceShout: "¡Olé-é-é-éééé!",
            headFeel: "¡Ay! My new ears wiggle when I laugh!", secret: "So THAT'S your secret! ¡Vámonos! Let's go make some money!",
            bestDay: "¡Qué día! The most fun I've had since my wedding!")
        case "Aunt Gail": Intro(
            spot: "Whoa! Now THAT is a ride!", beamUp: "Let's gooo!",
            inPod: "Hey, team! Nice zoo you've got here!", whatsNext: "\(kid), kiddo, this beats soccer practice any day!",
            straps: "Strapped in and ready to play!", tingle: "Ha! That tickles like crazy!",
            legs: "Look at these legs — I could run a marathon!", body: "Look at these muscles! I'm basically a superhero!",
            face: "Ooh — here comes the face — game time…", faceShout: "GOOOOOAAAAL!",
            headFeel: "These ears! I can hear the whole field!", secret: "So THAT'S how \(kid) scored the cash! I'm on the team!",
            bestDay: "Best game I've ever played — and we won!")
        case "Aunt Brenda": Intro(
            spot: "Oh my, how chic! A flying zoo!", beamUp: "Darlings, I'm being beamed! Fabulous!",
            inPod: "Love the décor! Very… safari.", whatsNext: "\(kid), honey, is this some kind of makeover?",
            straps: "Seat belts? How very first class.", tingle: "Ooh, it's like a spa treatment!",
            legs: "My legs! So furry — like a designer coat!", body: "Real fur, and it's mine — very this season!",
            face: "Ooh, my face… the snout… so dramatic…", faceShout: "Gorgeouuuuuuus!",
            headFeel: "Animal ears — the ultimate accessory!", secret: "So THAT'S your little business! Sign me up, darlings!",
            bestDay: "Better than any shopping trip — and that's saying something!")
        default: Intro(
            spot: "Oh, how fun! A flying zoo!", beamUp: "Wheee!",
            inPod: "A real spaceship! Hello, everyone!", whatsNext: "\(kid), this is wonderful! What happens next?",
            straps: "Ooh, seat belts! This must be quite a ride!", tingle: "Ooh, this really tickles!",
            legs: "Ooh, my legs are changing!", body: "I'm turning into an alien animal! How fun!",
            face: "Here comes my face…", faceShout: "Wheeeeeeeeee!",
            headFeel: "I have animal ears — I love them!", secret: "So THAT'S your secret! Let's go make some money!",
            bestDay: "The most fun I've had in years!")
        }
    }

    static func cousinIntro(_ name: String) -> Intro {
        switch name {
        case "Emma": Intro(
            spot: "A flying zoo ship! Cool!", beamUp: "I'm flyyyying!", inPod: "Hi, animal people!", whatsNext: "What happens now?",
            straps: "Seat belts! Like in Mommy's car!", tingle: "Hee hee! My toes are giggling!", legs: "My legs are all furry!",
            body: "I have a tail! A real tail!", face: "My nose feels all wiggly…", faceShout: "Wheeeee!",
            headFeel: "I have animal ears! Boing boing!", secret: "", bestDay: "Bye! Roar roar!")
        case "Mia": Intro(
            spot: "¡Mira! A big flying zoo ship!", beamUp: "Weeee!", inPod: "¡Hola, animalitos! Hi, animals!", whatsNext: "Is it my turn?",
            straps: "Click, click!", tingle: "It tickles! Hee hee!", legs: "My legs are turning furry!",
            body: "I have a tail like a puppy!", face: "My face is changing…", faceShout: "Yaaaay!",
            headFeel: "Animal ears! Like a bunny!", secret: "", bestDay: "¡Adiós! Roar!")
        case "Chloe": Intro(
            spot: "Whoa! A spaceship!", beamUp: "Woo-hoo! Up I go!", inPod: "High five, animal guys!", whatsNext: "Let's go, let's go!",
            straps: "Buckled! Ready!", tingle: "Ha ha! That tickles!", legs: "Super animal legs! I'm so fast!",
            body: "Look at my muscles!", face: "Here comes my animal face…", faceShout: "Yeaaaah!",
            headFeel: "Animal ears! I win!", secret: "", bestDay: "Bye! That was awesome!")
        case "Zoe": Intro(
            spot: "Ooh, sparkly lights in the sky!", beamUp: "I'm floating like a fairy!", inPod: "Hello! You're so shiny!", whatsNext: "Am I getting sparkly too?",
            straps: "Princess seat belts!", tingle: "Hee hee! It's tickly!", legs: "My legs are so fluffy!",
            body: "My fur is so pretty!", face: "My face is going sparkly…", faceShout: "Sparkle sparkle sparkle!",
            headFeel: "Animal ears! Like a tiara!", secret: "", bestDay: "Bye-bye! Roar!")
        default: Intro(
            spot: "A flying zoo! Wow!", beamUp: "Wheee!", inPod: "Hi, animals!", whatsNext: "What's next?",
            straps: "Seat belts!", tingle: "Hee hee! It tickles my toes!", legs: "My legs are changing!",
            body: "I'm getting fur!", face: "My face feels funny…", faceShout: "Wheeeee!",
            headFeel: "I have animal ears!", secret: "", bestDay: "Bye! Roar!")
        }
    }

    static func sitterIntro(_ name: String) -> Intro {
        switch name {
        case "Megan": Intro(
            spot: "Whoa… an actual flying zoo!", beamUp: "Okay — staying calm — wheee!",
            inPod: "Fascinating! I'm a biology major, you know!", whatsNext: "Girls, this is going to make an amazing term paper!",
            straps: "Safety restraints. Very responsible.", tingle: "Ooh, that's a pleasant tingle!",
            legs: "Real fur and hide — amazing!", body: "A tail! I'm a real mammal now!",
            face: "Here comes the snout…", faceShout: "This is incrediiiiiible!",
            headFeel: "These ears — I can actually hear ultrasound!", secret: "Paid to be an animal? Best summer job ever!",
            bestDay: "Thank you, Debbie — that was the most educational babysitting job ever!", again: "Round two — for science!")
        case "Brittany": Intro(
            spot: "No way! A flying zoo!", beamUp: "Ready, set, beam me up!",
            inPod: "Gimme a Z! Gimme an O! Gimme an O!", whatsNext: "Hailey, Molly — this is better than cheer camp!",
            straps: "Strapped in! Let's do this!", tingle: "Eee! That tickles!",
            legs: "My legs! I could do the highest kick ever!", body: "A tail — think of the pom-pom routines!",
            face: "Ooh, my face, my face…", faceShout: "Go, animals, goooooo!",
            headFeel: "Animal ears! Like built-in pom-poms!", secret: "A third of the profit? That's a touchdown!",
            bestDay: "Best. Babysitting. Ever. Go, team!", again: "Again! Again!")
        case "Jasmine": Intro(
            spot: "Oh wow — it's like a dream!", beamUp: "La la laaa — I'm floating!",
            inPod: "Hello, beautiful animal people!", whatsNext: "Girls, this is pure magic!",
            straps: "All buckled. I'm ready to fly!", tingle: "Ooh, it tickles like music!",
            legs: "My legs are so soft!", body: "I'm getting fur — it shines like silk!",
            face: "Ooh… here comes my face… so lovely…", faceShout: "Laaaaa-la-la-laaaa!",
            headFeel: "These ears! I can hear the music in the air!", secret: "And I'm paid for this? I'm writing a song about it!",
            bestDay: "Thank you, Debbie — your girls are pure magic!", again: "Encore! Here we go!")
        case "Tess": Intro(
            spot: "Holy moly! That's no weather balloon!", beamUp: "Yeehaw! Up we go!",
            inPod: "Howdy, critters! Nice place you've got!", whatsNext: "Girls, this beats camping any day!",
            straps: "Buckled up like a trail ride!", tingle: "Ha! Feels like ants in my boots — the good kind!",
            legs: "My legs are furry — no more mosquito bites!", body: "Real fur! I'm my own sleeping bag!",
            face: "Ooh — here comes the face…", faceShout: "Yee-haaaaaw!",
            headFeel: "These ears! I can hear a coyote a mile off!", secret: "Paid to be an animal? Shucks, I'd have done it for free!",
            bestDay: "Thanks, Debbie — happy trails, girls!", again: "Saddle up! Round two!")
        default: Intro(
            spot: "OMG! Is that a flying saucer?!", beamUp: "Ahh! This is so cool!",
            inPod: "Hi! Wow, you guys are, like, a whole zoo!", whatsNext: "Girls, your mom did NOT mention this part!",
            straps: "Seat belts? Okay, I'm ready!", tingle: "Hee hee! It totally tickles!",
            legs: "My legs are, like, so fluffy!", body: "Wait — I have a tail! That is SO cute!",
            face: "Ooh, my face is getting all fizzy…", faceShout: "Woo-hoooooo!",
            headFeel: "Animal ears! These are adorable!", secret: "And I get a third of the profit? Best babysitting job EVER!",
            bestDay: "Seriously, call me anytime, Debbie!", again: "Here we go again! Woo!")
        }
    }

    /// Where the alien animals wait, off stage, before they close in around the chairs.
    private static let wingsX = [-60.0, -110, -160, 1260, 1310]

    private static func makeCrew() -> [Person] {
        let crew: [(String, AnimalKind, Double)] = [("Grubbo", .gorilla, 172), ("Zeeba", .zebra, 158), ("Hippa", .hippopotamus, 148),
                                                    ("Rhinox", .rhinoceros, 176), ("Commander Leo", .pinkTiger, 180)]
        return zip(crew, wingsX).map { member, x in
            let p = Person.alienAnimal(member.0, kind: member.1, height: member.2, x: x)
            p.visible = false
            return p
        }
    }

    // MARK: What the scene asks for

    /// The part of the stage on screen; eases from `camFrom` to `camTo` over 0.9s.
    func camera(at now: Date) -> CGRect {
        let t = min(max(now.timeIntervalSince(camT0) / 0.9, 0), 1)
        let e = t * t * (3 - 2 * t)
        func mix(_ a: Double, _ b: Double) -> Double { a + (b - a) * e }
        return CGRect(x: mix(camFrom.minX, camTo.minX), y: mix(camFrom.minY, camTo.minY),
                      width: mix(camFrom.width, camTo.width), height: mix(camFrom.height, camTo.height))
    }

    /// The middle of the zoo's hatch, bobbing gently while it hovers.
    func pod(at now: Date) -> CGPoint? {
        guard podShown else { return nil }
        let t = min(max(now.timeIntervalSince(podT0) / max(podDur, 0.001), 0), 1)
        let e = t * t * (3 - 2 * t)
        let bob = sin(now.timeIntervalSinceReferenceDate * 2) * 3
        return CGPoint(x: podFrom.x + (podTo.x - podFrom.x) * e, y: podFrom.y + (podTo.y - podFrom.y) * e + bob)
    }

    /// The Animals of Poker machine's mini saucer, bobbing while it's out.
    func miniSaucer(at now: Date) -> CGPoint? {
        guard miniShown else { return nil }
        let t = min(max(now.timeIntervalSince(miniT0) / max(miniDur, 0.001), 0), 1)
        let e = t * t * (3 - 2 * t)
        let bob = sin(now.timeIntervalSinceReferenceDate * 4) * 2
        return CGPoint(x: miniFrom.x + (miniTo.x - miniFrom.x) * e, y: miniFrom.y + (miniTo.y - miniFrom.y) * e + bob)
    }

    /// What the poker machine's screen says in the spare room.
    var pokerScreenText: String {
        if let poker { return poker.ending == .qualified ? "GAME 10!" : "GAME \(poker.game.number)" }
        return pokerScreen
    }

    /// 0 (empty cottage) … 1 (the chairs, console and mirror fully beamed in).
    func cottageMachineLevel(at now: Date) -> Double {
        guard cottageMachine else { return 0 }
        return min(max(now.timeIntervalSince(cottageMachineT0) / 2.5, 0), 1)
    }

    /// Where one of their own vehicles is: parked in the driveway, or rolling in from the street.
    func parked(_ vehicle: Vehicle, at now: Date) -> Double? {
        guard vehicles.contains(vehicle) else { return nil }
        let spot = switch vehicle {
        case .car: Stage.carX
        case .motorcycle: Stage.motorcycleX
        case .scooter: Stage.scooterX
        }
        guard arriving == vehicle else { return spot }
        let t = min(max(now.timeIntervalSince(arriveT0) / Self.arriveDur, 0), 1)
        return -160 + (spot + 160) * (1 - (1 - t) * (1 - t))
    }

    private static let arriveDur = 2.6

    /// What the console's screen says.
    func screenText(_ now: Date) -> String {
        if let p = everyone.first(where: { $0.seated && $0.isTingling(at: now) }) {
            if now < p.changeT0 { return "TINGLE\nPHASE" }
            let left = Int((1 - p.progress(at: now)) * 300)
            return String(format: "TRANSFORMING\n%d:%02d", left / 60, left % 60)
        }
        return screen
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

    // MARK: Controls

    /// `resume`: carry on from the last saved morning instead of starting a new game.
    func start(resume: Bool = false) {
        task?.cancel()
        venuePick?.resume(returning: .belmar)
        venuePick = nil
        kindPick?.resume(returning: .gorilla)
        kindPick = nil
        nextPick?.resume(returning: false)
        nextPick = nil
        vacationPick?.resume(returning: false)
        vacationPick = nil
        vehiclePick?.resume(returning: nil)
        vehiclePick = nil
        poker?.shutDown()
        poker = nil
        pokerDone?.resume()
        pokerDone = nil
        leftoverCredits = 0
        outingPick?.resume(returning: .trip)
        outingPick = nil
        choosingOuting = false
        releasePrompt()
        answerWait?.resume(returning: .option(0))
        answerWait = nil
        answerAuto = nil
        prompt = nil
        board = nil
        tableSeats = []
        tableGroups = []
        humanRow = nil
        you = nil
        myHand = []
        cardGames = 0
        guestWomen = []
        guestKids = []
        pickupNewcomer = nil
        sound.prepare()
        sound.stopAll()
        (debbie, hailey, molly) = Self.makeCast()
        team = [debbie, hailey, molly]
        visitors = []
        extras = []
        crew = Self.makeCrew()
        customers = []
        finished = false
        running = true
        place = .house
        buttonShown = false
        buttonPressT0 = .distantPast
        pokerScreen = "INSERT CREDITS"
        miniShown = false
        miniBeamOn = false
        hiding = nil
        cottageMachine = false
        cottageMachineT0 = .distantFuture
        podShown = false
        podFlying = false
        beamOn = false
        strapped = []
        mirrorT0 = .distantFuture
        mirrorFolks = []
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
        choosingVacation = false
        cash = Venue.startCash
        cashPop = nil
        result = nil
        trips = 0
        rotation = 0
        nights = 0
        auntVisits = 0
        sitterVisits = 0
        totalProfit = 0
        totalTransformed = 0
        bank = 0
        vehicles = []
        arriving = nil
        rider = nil
        choosingVehicle = false
        night = false
        sleeping = []
        couchSleeper = nil
        let save = resume ? SaveGame.load() : nil
        if let save { restore(save) }
        task = Task {
            do { try await story(resumed: save != nil) } catch {}
        }
    }

    func choose(_ venue: Venue) {
        venuePick?.resume(returning: venue)
        venuePick = nil
        choosingVenue = false
    }

    func choose(_ kind: AnimalKind) {
        kindPick?.resume(returning: kind)
        kindPick = nil
        choosingKind = nil
    }

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

    /// `nil` means not today.
    func choose(_ vehicle: Vehicle?) {
        vehiclePick?.resume(returning: vehicle)
        vehiclePick = nil
        choosingVehicle = false
    }

    func chooseOuting(_ outing: Outing) {
        outingPick?.resume(returning: outing)
        outingPick = nil
        choosingOuting = false
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

    // MARK: Story

    /// Puts the saved morning's money, counts and wheels back.
    private func restore(_ save: SaveGame) {
        cash = save.cash
        bank = save.bank
        nights = save.nights
        trips = save.trips
        cardGames = save.cardGames
        auntVisits = save.auntVisits
        sitterVisits = save.sitterVisits
        totalProfit = save.totalProfit
        totalTransformed = save.totalTransformed
        rotation = save.rotation
        team = (0..<3).map { cast[(rotation + $0) % 3] }
        vehicles = Set(save.vehicles.compactMap(Vehicle.init(rawValue:)))
        // By the first saved morning the zoo has already installed the machine in the cottage.
        cottageMachine = true
        cottageMachineT0 = .distantPast
    }

    /// Saves this morning so the game can be continued from here.
    private func saveProgress() {
        let save = SaveGame(cash: cash, bank: bank, nights: nights, trips: trips, cardGames: cardGames, auntVisits: auntVisits,
                            sitterVisits: sitterVisits, totalProfit: totalProfit, totalTransformed: totalTransformed,
                            rotation: rotation, vehicles: vehicles.map(\.rawValue))
        save.write()
        saved = save
    }

    /// Continuing a saved game: the family is up and gathered in the living room on the saved morning.
    private func resumeMorning() async throws {
        try await sceneChange {
            self.place = .house
            self.night = false
            self.sleeping = []
            self.show(self.cast)
            for (p, x) in zip(self.cast, Stage.buttonSpots) {
                (p.x0, p.x1, p.moveDur) = (x, x, 0)
                p.seated = false
                p.place(height: 0)
            }
            self.cutNow(Stage.full)
        }
        for (i, p) in cast.enumerated() { p.facing = i == 0 ? 1 : -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        caption = "Welcome back! Day \(nights + 1) — cash $\(cash), savings $\(bank)."
        sound.chime()
        try await say(debbie, "Good morning, girls! Where were we?", 2.2)
        try await say(molly, "Making alien animals!", 1.8)
    }

    private func story(resumed: Bool = false) async throws {
        do {
            if resumed {
                try await resumeMorning()
            } else {
                try await moveInDay()
                try await pokerMorning()
                try await zooGift()

                // The first day: two trips, then shopping, the bank, and bed.
                try await tripToVenue()
                try await comeHome(first: true)
                try await askNext("Next: a flying zoo trip, or a card game hosted right here at the house.")
                try await outing()
                try await restUntilMorning(shopper: debbie)
            }

            while true {
                // Every new morning is saved; "Continue" picks the game up from here.
                saveProgress()
                if nights % 2 == 1 {
                    // After the first and every odd night, an aunt comes to take Debbie clothes shopping.
                    let aunt = Self.auntLooks[auntVisits % Self.auntLooks.count].aunt
                    try await askNext("Aunt \(aunt) is coming over this morning to take Debbie clothes shopping.")
                    try await auntVisit()
                    try await restUntilMorning(shopper: debbie)
                } else {
                    try await askNext("A new day of trips in the flying zoo.")
                    if try await askVacation() {
                        try await babysitterDay()
                    } else {
                        try await say(debbie, "No vacation for me — let's get to work, girls!", 2.4)
                        try await outing()
                        try await askNext("One more today? A flying zoo trip or a card game at home.")
                        try await outing()
                        try await restUntilMorning(shopper: debbie)
                    }
                }
            }
        } catch is EndGame {}

        caption = "Game over! \(trips) \(trips == 1 ? "trip" : "trips") in the flying zoo, "
            + (cardGames > 0 ? "\(cardGames) card \(cardGames == 1 ? "game" : "games") at home, " : "")
            + "\(totalTransformed) customers transformed, "
            + "\(totalProfit >= 0 ? "$\(totalProfit) profit" : "$\(-totalProfit) lost"). Cash on hand: $\(cash), savings in the bank: $\(bank)."
            + (vehicles.isEmpty ? "" : " In the driveway: \(ListFormatter.localizedString(byJoining: Vehicle.allCases.filter(vehicles.contains).map { "a \($0.name.lowercased())" })), bought and paid for.")
        try await say(debbie, vehicles.contains(.motorcycle) ? "A brand-new motorcycle, all paid for. Best thing that ever happened to us!"
                                                            : "Best thing that ever happened to us, girls!", 3)
        finished = true
        running = false
    }

    /// Between trips: "Do It Again" carries on; "End Game" ends the story.
    private func askNext(_ prompt: String) async throws {
        if cash < Venue.cheapestFee {
            try await say(debbie, "We only have $\(cash) on hand — not enough for a zoo setup fee. But a card game at home costs nothing!", 3.2)
        }
        nextPrompt = prompt
        let again = await withCheckedContinuation { cont in
            nextPick = cont
            choosingNext = true
            caption = "Press the red button to do it again, or end the game?"
        }
        try Task.checkCancellation()
        guard again else { throw EndGame() }
    }

    private func askVacation() async throws -> Bool {
        try await look(at: Stage.shot(centerX: 520, height: 260))
        try await say(debbie, "You know what, girls? I could use a night away. A solo vacation is $\(Self.vacationCost).", 3)
        let go = await withCheckedContinuation { cont in
            vacationPick = cont
            choosingVacation = true
            caption = "Should Debbie take a solo vacation for the night? She'll hire a babysitter."
        }
        try Task.checkCancellation()
        return go
    }

    /// The opening: Debbie and her girls move into their new house. The spare room came with an old video poker machine.
    private func moveInDay() async throws {
        let (debbie, hailey, molly) = (debbie, hailey, molly)
        place = .house
        show([debbie, hailey, molly])
        for (i, p) in [debbie, hailey, molly].enumerated() {
            (p.x0, p.x1, p.moveDur, p.facing) = (-60 - Double(i) * 45, -60 - Double(i) * 45, 0, 1)
        }
        debbie.load = .box
        cutNow(Stage.full)
        caption = "Moving day! Debbie and her daughters walk up to their new house."
        try await walkAll([(debbie, 300), (hailey, 255), (molly, 215)], speed: 110)
        for p in cast { p.facing = 1 }
        try await look(at: Stage.shot(centerX: 290, height: 260))
        try await say(molly, "Is this our new house, Mommy?", 2)
        try await say(debbie, "This is it, girls! Our brand-new home.", 2.4)
        try await say(hailey, "It's so big! Do we each get our own room?", 2.4)
        try await say(debbie, "You sure do. Let's go have a look!", 2.2)

        caption = "They take the grand tour: the living room…"
        try await look(at: Stage.full)
        debbie.load = nil
        try await walkAll([(debbie, Stage.livingX[0]), (hailey, Stage.livingX[1]), (molly, Stage.livingX[2])], speed: 130)
        caption = "…a bedroom for Debbie, one for Hailey, and one for Molly."
        try await walkAll(zip(cast, Stage.roomX).map { ($0, $1) }, speed: 150)
        for p in cast { p.facing = 0 }
        try await say(molly, "I get the room with the teddy bear!", 2.2)
        try await say(hailey, "Mom! There's one more room down the hall — the spare room!", 2.6)

        // The spare room: an old video poker machine left behind by somebody.
        try await sceneChange {
            self.place = .spareRoom
            self.show(self.cast)
            for (i, p) in self.cast.enumerated() {
                let x = Stage.spareDoorX - Double(i) * 30
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
            }
            self.cutNow(Stage.full)
        }
        caption = "In the spare room, somebody left a video poker machine plugged in by the wall."
        try await walkAll([(debbie, Stage.spareWatchX[2]), (hailey, Stage.spareWatchX[1]), (molly, Stage.spareWatchX[0])], speed: 130)
        for p in cast { p.facing = 1 }
        try await look(at: Stage.shot(centerX: 740, height: 300))
        try await say(hailey, "\"ANIMALS OF POKER\"? Who leaves a game machine in a house?", 2.8)
        try await say(molly, "It has a tiger and an elephant on top! Can I play it?", 2.6)
        try await say(debbie, "Not today, sweetie. That thing is probably broken.", 2.4)
        try await say(debbie, "We've got boxes to unpack. Bedtime soon!", 2.2)

        try await sceneChange {
            self.place = .house
            self.show(self.cast)
            for (p, x) in zip(self.cast, Stage.livingX) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0) }
            self.cutNow(Stage.full)
        }
        caption = "After a long day of unpacking, everybody heads to bed in the new house."
        try await goToBed(cast)
        try await sceneChange {
            self.debbie.shirt = Self.casualShirt
            self.debbie.pants = RGB(r: 0.25, g: 0.30, b: 0.50)
            self.wakeUp(self.cast)
        }
        caption = "The next morning…"
        sound.chime()
        try await sleep(2)
    }

    /// Mom goes shopping. Molly, the youngest, sneaks into the spare room and plays the Animals of Poker;
    /// at game 10 a mini saucer pops out and turns her into an elephant. Then Hailey plays, and then Debbie.
    private func pokerMorning() async throws {
        let (debbie, hailey, molly) = (debbie, hailey, molly)
        try await walkAll(zip(cast, Stage.livingX).map { ($0, $1) }, speed: 140)
        debbie.facing = 1
        hailey.facing = -1
        molly.facing = -1
        try await look(at: Stage.shot(centerX: 530, height: 250))
        try await say(debbie, "Girls, I'm heading into town to shop for the new house. Curtains, towels, a welcome mat…", 3.4)
        try await say(debbie, "Hailey, keep an eye on your sister. Stay out of trouble!", 2.6)
        try await say(hailey, "We will, Mom!", 1.6)
        shout([hailey, molly], "Bye, Mom!", 1.6)
        try await sleep(1.6)
        caption = "Debbie heads out the front door."
        try await look(at: Stage.full)
        try await walk(debbie, to: -60, speed: 160)
        debbie.visible = false

        molly.facing = -1
        hailey.facing = 1
        try await look(at: Stage.shot(centerX: 560, height: 230))
        try await say(molly, "Hailey… can we play the game machine in the spare room? Pleeease?", 2.8)
        try await say(hailey, "Mom said stay out of trouble…", 2)
        try await say(hailey, "…but okay. You play, I'll watch.", 2.2)

        // Molly at the machine.
        try await toSpareRoom(player: molly, watchers: [hailey])
        try await say(molly, "It's lighting up! It says I have 200 credits!", 2.4)
        try await say(hailey, "Press BET MAX every time, Molly. It says you need the max bet to get to game 10.", 3.2)
        try await playPoker(molly)
        try await gameTen(molly, kind: .elephant,
                          lines: (spot: "A little flying saucer!", tingle: "It tickles!", legs: "My feet are getting big and gray!",
                                  body: "I'm getting a big round tummy!", face: "My nose is growing… it's a TRUNK!"))
        hailey.mood = .shocked
        try await say(hailey, "MOLLY! You're an ELEPHANT!", 2.2)
        try await say(hailey, "Look in the mirror!", 1.6)
        try await standingMirror([molly], caption: "Molly sees a little alien elephant in the spare room mirror!")
        molly.mood = .beaming
        try await say(molly, "I have a trunk! Toot-toot!", 2)
        try await say(molly, "Your turn, Hailey! It tickles!", 2)
        try await say(hailey, "You look SO cute, Molly! I want a trunk too!", 2.4)

        // The machine isn't done: the mini saucer pops back out and comes straight for Hailey, right where she stands.
        let haileyX = hailey.x1
        try await look(at: Stage.shot(centerX: 740, height: 300))
        caption = "Clunk! The top of the machine slides open again…"
        sound.clunk()
        miniShown = true
        moveMini(to: Stage.miniHome, over: 0)
        moveMini(to: CGPoint(x: Stage.pokerX, y: Stage.miniHome.y - 50), over: 1)
        sound.hum(true)
        try await sleep(1.1)
        hailey.mood = .shocked
        try await say(molly, "Hailey, it's coming for YOU!", 2)
        moveMini(to: CGPoint(x: haileyX, y: Stage.floorY - hailey.height - 70), over: 1.4)
        try await sleep(1.5)
        hailey.mood = .beaming
        try await say(hailey, "It picked me! Yay!", 2.2)
        try await say(hailey, "Okay, I'm ready! Make me an elephant too!", 2.2)
        try await say(hailey, "I am going to be transformed — yay!", 2.2)
        try await miniBeam(hailey, kind: .elephant, x: haileyX,
                           lines: (spot: "Here it comes!", tingle: "Ooh, Molly was right — it tickles!", legs: "My feet are getting big and gray!",
                                   body: "Big floppy ears and a round tummy!", face: "My nose… it's growing into a TRUNK!"))
        caption = "The mini saucer zips back into the machine."
        moveMini(to: CGPoint(x: Stage.pokerX, y: Stage.miniHome.y - 50), over: 1.2)
        try await sleep(1.3)
        moveMini(to: Stage.miniHome, over: 0.6)
        try await sleep(0.7)
        miniShown = false
        sound.hum(false)
        sound.clunk()
        hailey.facing = 1
        try await standingMirror([hailey, molly], caption: "Two little alien elephants look back from the spare room mirror!")
        try await snap([hailey])
        hailey.mood = .beaming
        try await say(hailey, "I'm an elephant, just like Molly! I LOVE it!", 2.6)

        // Debbie comes home to two alien animals in the living room.
        try await sceneChange {
            self.place = .house
            self.show([hailey, molly])
            (hailey.x0, hailey.x1, hailey.moveDur, hailey.facing) = (Stage.livingX[1], Stage.livingX[1], 0, -1)
            (molly.x0, molly.x1, molly.moveDur, molly.facing) = (Stage.livingX[2], Stage.livingX[2], 0, -1)
            hailey.mood = .happy
            molly.mood = .happy
            self.cutNow(Stage.full)
        }
        caption = "That afternoon, Debbie comes home from shopping…"
        (debbie.x0, debbie.x1, debbie.moveDur) = (-60, -60, 0)
        debbie.load = .shopping
        debbie.visible = true
        try await walk(debbie, to: Stage.livingX[0], speed: 150)
        debbie.facing = 1
        try await look(at: Stage.shot(centerX: 530, height: 250))
        shout([hailey, molly], "SURPRISE!", 1.8)
        sound.roar()
        try await sleep(1.6)
        debbie.mood = .shocked
        debbie.load = nil
        try await say(debbie, "AAAH! Girls?! What happened to you?!", 2.4)
        try await say(molly, "I got to game 10 on the machine, and a little flying saucer came out and — ZAP!", 3.2)
        try await say(hailey, "Then it came right out again and zapped me too! Now we're BOTH elephants!", 3)

        // The mini saucer comes up the hall for Debbie.
        miniShown = true
        moveMini(to: CGPoint(x: Stage.W + 60, y: Stage.ceilY + 45), over: 0)
        sound.hum(true)
        let momX = Stage.livingX[0]
        caption = "Hmmmm… the mini saucer comes humming down the hall, straight for Debbie!"
        try await look(at: Stage.full)
        moveMini(to: CGPoint(x: momX + 60, y: Stage.ceilY + 50), over: 2.4)
        try await sleep(2.5)
        try await look(at: Stage.shot(centerX: 520, height: 260))
        try await say(molly, "It's coming for you mom.", 1.8)
        moveMini(to: CGPoint(x: momX, y: Stage.floorY - debbie.height - 70), over: 1)
        try await sleep(1.1)
        try await miniBeam(debbie, kind: .pinkTiger, x: momX, watcher: (molly, "There goes Mommy."),
                           lines: (spot: "Me?! Oh my goodness!", tingle: "Oh my, that tickles!", legs: "Pink fur, from my toes on up!",
                                   body: "A striped tiger tail! Girls, look!", face: "And whiskers, and stripes on my face!"))
        caption = "Its job done, the mini saucer zips back to the spare room."
        moveMini(to: CGPoint(x: Stage.W + 60, y: Stage.ceilY + 45), over: 2)
        try await sleep(2.1)
        miniShown = false
        sound.hum(false)
        try await snap([debbie])
        try await say(molly, "Mommy, look in the hall mirror!", 1.8)
        try await standingMirror(cast, caption: "The hall mirror shows a pink tiger and two little elephants!")
        for p in cast { p.mood = .beaming }
        shout(cast, "Wow!", 1.8)
        try await sleep(2)
        try await say(debbie, "I'm a PINK TIGER! Who knew we could look this amazing?", 2.8)
        try await say(molly, "Two elephants and a pink tiger!", 2.2)
        for p in cast { p.mood = .happy }
    }

    /// Everyone heads down the hall to the spare room: `player` at the machine, `watchers` behind her.
    private func toSpareRoom(player: Person, watchers: [Person]) async throws {
        let people = [player] + watchers
        try await sceneChange {
            self.place = .spareRoom
            self.show(people)
            for (i, p) in people.enumerated() {
                let x = Stage.spareDoorX - Double(i) * 35
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
            }
            self.cutNow(Stage.full)
        }
        caption = "\(player.id) sits down at the Animals of Poker machine."
        try await walkAll([(player, Stage.pokerPlayerX)] + zip(watchers, Stage.spareWatchX.reversed()).map { ($0, $1) }, speed: 140)
        for p in people { p.facing = 1 }
        try await look(at: Stage.shot(centerX: 740, height: 300))
    }

    /// The last player steps back to watch, and `next` steps up to the machine.
    private func swapPlayer(to next: Person, from last: Person) async throws {
        try await look(at: Stage.full)
        caption = "\(next.id) steps up to the machine."
        try await walkAll([(last, Stage.spareWatchX[1]), (next, Stage.pokerPlayerX)], speed: 120)
        last.facing = 1
        next.facing = 1
        try await look(at: Stage.shot(centerX: 740, height: 300))
    }

    /// The player plays `p`'s nine games on the Animals of Poker. Running out of credits or not betting the max
    /// means inserting credits and starting over; reaching game 10 hands the story back.
    private func playPoker(_ p: Person) async throws {
        let session = PokerSession(player: p.id, host: .animals, muted: muted)
        session.onSound = { [weak self] s in
            switch s {
            case .card: self?.sound.beep()
            case .coin: self?.sound.pay()
            case .chime: self?.sound.chime()
            }
        }
        session.onEnd = { [weak self] ending in
            guard ending == .qualified else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4.5))
                self?.finishPoker(session)
            }
        }
        caption = "\(p.id) is playing the Animals of Poker. Bet the max every hand and reach game 10!"
        poker = session
        session.begin()
        await withCheckedContinuation { cont in pokerDone = cont }
        try Task.checkCancellation()
        leftoverCredits = session.credits
    }

    /// Whatever credits are left on the machine after game 10 come out as cash for the family, a dollar a credit.
    private func cashOutMachine(_ p: Person) async throws {
        let credits = leftoverCredits
        leftoverCredits = 0
        guard credits > 0 else { return }
        pokerScreen = "CASH OUT"
        caption = "\(p.id) presses CASH OUT: the \(credits) credits left on the machine come out as $\(credits) — and it all goes to the family!"
        sound.pay()
        cash += credits
        cashPop = ("+$\(credits) from the machine", .now, Stage.pokerX)
        let family = cast.contains { $0 === p }
        try await say(p, family ? (p.isKid ? "$\(credits) left on the machine! That's for the family, Mom!" : "$\(credits) left on the machine — that goes in the family pot!")
                                : "Here, Debbie — the $\(credits) left on the machine is for your family!", 2.8)
        try await sleep(0.8)
        pokerScreen = "INSERT CREDITS"
    }

    private func finishPoker(_ session: PokerSession) {
        guard poker === session else { return }
        session.shutDown()
        poker = nil
        pokerDone?.resume()
        pokerDone = nil
    }

    /// Game 10: the topper opens, the mini saucer flies out over the player and beams her into an alien animal,
    /// feet first, then tucks itself back inside the machine.
    private func gameTen(_ p: Person, kind: AnimalKind,
                         lines: (spot: String, tingle: String, legs: String, body: String, face: String)) async throws {
        pokerScreen = "GAME 10!"
        try await look(at: Stage.shot(centerX: 780, height: 340))
        caption = "GAME 10! The top of the machine slides open…"
        sound.chime()
        sound.clunk()
        miniShown = true
        moveMini(to: Stage.miniHome, over: 0)
        moveMini(to: CGPoint(x: Stage.pokerX, y: Stage.miniHome.y - 50), over: 1)
        sound.hum(true)
        try await sleep(1.1)
        let over = CGPoint(x: Stage.pokerPlayerX, y: Stage.floorY - p.height - 70)
        moveMini(to: over, over: 1.4)
        try await miniBeam(p, kind: kind, x: Stage.pokerPlayerX, lines: lines)

        caption = "The mini saucer zips back into the machine."
        moveMini(to: CGPoint(x: Stage.pokerX, y: Stage.miniHome.y - 50), over: 1.2)
        try await sleep(1.3)
        moveMini(to: Stage.miniHome, over: 0.6)
        try await sleep(0.7)
        miniShown = false
        sound.hum(false)
        sound.clunk()
        pokerScreen = "WINNER!"
        try await look(at: Stage.shot(centerX: 700, height: 300))
        try await snap([p])
        try await cashOutMachine(p)
        pokerScreen = "INSERT CREDITS"
    }

    /// The mini saucer, hovering over `p` (standing at `x`), shines its beam down and turns her into an alien animal,
    /// feet first. Works in the spare room or anywhere in the house.
    private func miniBeam(_ p: Person, kind: AnimalKind, x: Double, watcher: (Person, String)? = nil,
                          lines: (spot: String, tingle: String, legs: String, body: String, face: String)) async throws {
        let change = Machine.customerChange
        p.mood = .shocked
        try await say(p, lines.spot, 1.8)
        p.facing = 0
        miniBeamTint = kind.color
        miniBeamT0 = .now
        miniBeamOn = true
        sound.beam(true)
        caption = "…and the mini saucer shines its beam down on \(p.id)!"
        try await sleep(1.2)

        let t0 = Date.now + 0.2
        p.animal = kind
        p.tingleT0 = t0
        p.changeT0 = t0 + Machine.tingle
        p.changeDur = change
        p.fade(to: 1, over: 0)
        p.shineT0 = .distantPast
        sound.tingle()
        caption = "\(p.id) feels a tingling sensation…"
        if let (w, line) = watcher {
            // Someone watching calls out as the change begins.
            mention(w, line, 1.8)
            try await sleep(1.9)
        }
        cut(to: Stage.focus(CGPoint(x: x, y: Stage.floorY - p.height * 0.55), height: 260))
        try await sleep(0.6)
        p.mood = .happy
        mention(p, lines.tingle, 2.4)
        try await sleep(Machine.tingle - 0.4)

        sound.zap(true)
        caption = "…then the saucer turns \(p.id) into an alien \(kind.name), starting from the feet!"
        cut(to: Stage.focus(CGPoint(x: x, y: Stage.floorY - 40), height: 200))
        mention(p, lines.legs, 2.6)
        try await sleep(change * 0.3)
        caption = "It works its way up — fur, hide and a tail…"
        cut(to: Stage.focus(CGPoint(x: x, y: Stage.floorY - p.height * 0.5), height: 220))
        mention(p, lines.body, 2.6)
        try await sleep(change * 0.3)
        let head = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: 0, now: .now).head.y
        caption = "…until it reaches \(p.id)'s face!"
        cut(to: Stage.focus(CGPoint(x: x, y: head), height: 170))
        p.mood = .beaming
        mention(p, lines.face, 3)
        try await sleep(change * 0.4 + 0.4)
        sound.zap(false)
        sound.roar()
        p.shineT0 = .now
        miniBeamOn = false
        sound.beam(false)
        p.mood = .happy
    }

    /// The flying zoo arrives: its alien animals left the machine in the spare room, and now they give the family
    /// a transformation machine of their own in the backyard cottage — and explain the deal.
    private func zooGift() async throws {
        let (debbie, hailey, molly) = (debbie, hailey, molly)
        let visitors = [leader, crew[0], crew[1]]
        try await sceneChange {
            self.place = .house
            self.show(self.cast)
            for (p, x) in zip(self.cast, Stage.livingX) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0) }
            self.cutNow(Stage.full)
        }
        caption = "Jungle drums are beating somewhere up in the sky…"
        try await look(at: Stage.yardView)
        podShown = true
        movePod(to: CGPoint(x: Stage.yardPodX, y: -160), over: 0)
        movePod(to: CGPoint(x: Stage.yardPodX, y: Stage.floorY - Stage.hoverLift), over: 3.4)
        sound.hum(true)
        sound.drums(true)
        try await sleep(3.6)
        sound.drums(false)
        caption = "A flying zoo lands in the front yard, and alien animals come to the door!"
        try await beamDown(visitors, at: Stage.yardLine)
        try await walkAll([(leader, 392), (crew[0], 352), (crew[1], 312)], speed: 110)
        sound.roar()
        try await say(leader, "ROAR! Knock-knock! Anybody home?", 2.2)
        try await look(at: Stage.full)
        try await walkAll([(debbie, 452), (hailey, 494), (molly, 530)], speed: 150)
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 400, height: 300))
        try await say(molly, "Mommy! More animals! A gorilla, a zebra and a pink tiger!", 2.6)
        try await say(leader, "Well, well! We see you found our Animals of Poker machine.", 2.8)
        try await say(leader, "We left it in the spare room for whoever moved in next. And all three of you made it to game 10!", 3.6)
        try await say(debbie, "That was YOUR machine? Who are you?", 2.2)
        try await say(leader, "We are the alien animals of the flying zoo. Welcome to the neighborhood!", 3)
        try await say(leader, "And we have a housewarming gift: a transformation machine of your very own. Come out to your backyard cottage!", 4)

        // The backyard cottage: the zoo beams the machine in.
        try await sceneChange {
            self.place = .cottage
            self.cottageMachine = false
            self.cottageMachineT0 = .distantFuture
            self.movePod(to: CGPoint(x: Stage.backPodX, y: Stage.floorY - Stage.hoverLift), over: 0)
            self.show(self.cast + visitors)
            for (p, x) in zip(self.cast, [560.0, 620.0, 670.0]) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
            for (p, x) in zip(visitors, Stage.backLine.reversed()) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1) }
            self.cutNow(Stage.full)
        }
        caption = "The flying zoo floats over the backyard, and its beam fills the empty cottage…"
        beamOn = true
        beamT0 = .now
        sound.beam(true)
        try await sleep(1.2)
        sound.shimmer()
        cottageMachineT0 = .now
        cottageMachine = true
        try await sleep(3)
        beamOn = false
        sound.beam(false)
        sound.clunk()
        caption = "…and three transformation chairs, a console with a glowing red button and a big mirror appear inside!"
        try await walkAll([(debbie, 760), (hailey, 820), (molly, 870)], speed: 120)
        for p in cast { p.facing = -1; p.mood = .beaming }
        try await look(at: Stage.chairsView)
        try await say(hailey, "Our own transformation machine!", 2)
        try await say(molly, "In our backyard!", 1.6)
        for p in cast { p.mood = .happy }
        try await look(at: Stage.full)
        try await walk(leader, to: Stage.chairX[0] - 70, speed: 120)
        leader.facing = 1
        try await say(leader, "Sit in the chairs, pick your animal, and press the glowing red button. You change from your feet to your face.", 4)
        try await say(leader, "Once you are changed, the button calls us, and the flying zoo picks you up right here in the backyard.", 3.6)
        try await say(leader, "Here is the deal: our flying zoo has pre-selected destinations.", 3)
        caption = "The alien animals explain the deal…"
        card = .deal
        cardUntil = .now + 16
        try await sleep(16.2)
        try await say(leader, "The only catch is you have to pay for the setup.", 2.6)
        try await say(leader, "Two of you go outside to ask customers if they want to be an alien animal. One of you stays inside to work the machine.", 4.2)
        try await say(leader, "Their transformation will dissolve in 8 hours. Yours dissolves after we bring you home — it takes 5 minutes.", 4)
        try await say(debbie, "I have $\(Venue.startCash) left over after the move. Girls, we're in business!", 3)
        try await say(hailey, "Way better than a video poker game, Mom!", 2.2)
        try await say(molly, "Yay! Animal business!", 1.8)
        team = [debbie, hailey, molly]
        try await say(leader, "You are already changed — so let's go!", 2.2)
        caption = "The alien animals beam back up to the zoo."
        try await walkAll(zip(visitors, Stage.backLine).map { ($0, $1) }, speed: 150)
        try await beamUp(visitors)
        try await zooPickup(cast)
        try await say(leader, "Debbie asks the customers, Hailey takes the money, and Molly works the machine.", 3.4)
        try await say(molly, "I get to press the big red button!", 2.2)
    }

    // MARK: The machine

    /// Presses the glowing red button: a tingle, then the change climbs from the feet to the face.
    /// Anyone in `calmAtTingle` stops being frightened the moment the tickle starts.
    private func runMachine(_ riders: [(Person, AnimalKind)], presser: Person, change: Double, calmAtTingle: [Person] = [],
                            tingleLine: (Person, String)? = nil, tingleShout: String? = nil, legsStartLine: (Person, String)? = nil,
                            bodyLine: (Person, String)? = nil, facesLine: String? = nil,
                            faceShouts: (Person, [(text: String, size: Double)])? = nil, beamOnShout: Int? = nil,
                            faceSpeakers: [[Person]]? = nil) async throws {
        // A presser in one of the chairs hops up, presses the button, and hurries back.
        let chair = presser.seated ? presser.x(at: .now) : nil
        let wasStrapped = strapped.contains(presser.id)
        if chair != nil {
            strapped.remove(presser.id)
            presser.seated = false
            try await walk(presser, to: Stage.consoleX - 45, speed: 240)
        }
        presser.facing = presser.x(at: .now) < Stage.consoleX ? 1 : -1
        presser.reachTo = Stage.redButton
        try await sleep(0.7)
        consolePressT0 = .now
        sound.beep()
        try await sleep(0.4)
        presser.reachTo = nil
        if let chair {
            mention(presser, "Back to my chair!", 1.4)
            try await walk(presser, to: chair, speed: 300)
            presser.seated = true
            presser.facing = 0
            if wasStrapped {
                strapped.insert(presser.id)
                strapT0 = .now
                sound.clunk()
            }
        }

        let t0 = Date.now + 0.2
        for (p, kind) in riders {
            p.animal = kind
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
        let names = people.count == 3 ? "They" : people.map(\.id).joined(separator: " and ")
        // Shouts spread over the face change, at the font size given for each.
        // From shout number `beamOnShout` on, the shouter breaks into a big open smile.
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
                sound.roar()
            }
            try await sleep(max(0, end.timeIntervalSinceNow))
        }
        sound.tingle()
        caption = "\(names) first \(people.count == 1 ? "feels" : "feel") a tingling sensation…"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 100), height: max(h, 230)))
        try await sleep(0.4)
        for p in calmAtTingle { p.mood = .happy }
        if let (p, s) = tingleLine { mention(p, s, 2.2) }
        if let tingleShout {
            try await sleep(1.2)
            shout(people, tingleShout, 2.6)
            try await sleep(Machine.tingle - 1.4)
        } else {
            try await sleep(Machine.tingle - 0.2)
        }

        sound.zap(true)
        clockT0 = .now
        clockDur = change
        clockLabel = "Five minutes later…"
        clockSpan = 300
        caption = "…then the machine starts turning \(people.count == 1 ? names : "them") into \(people.count == 1 ? "an alien animal" : "alien animals"), starting from the feet!"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 45), height: h))
        if let (p, s) = legsStartLine { mention(p, s, 2.4) }
        try await sleep(change * 0.21)
        caption = "It works its way up \(people.count == 1 ? "the body" : "their bodies") — fur, stripes, hides and tails…"
        cut(to: Stage.focus(CGPoint(x: cx, y: Stage.floorY - 105), height: h))
        if let (p, s) = bodyLine { mention(p, s, 2.4) }
        if let facesLine, let first = people.first {
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
        caption = people.count == 1 ? "Animal ears and a snout grow on \(names)'s head…"
                                    : "Animal ears and snouts grow on their heads…"
        cut(to: Stage.focus(CGPoint(x: cx, y: top - 10), height: max(150, h * 0.85)))
        try await wait(change * 0.36 + 0.3)
        for p in shouters {
            p.voice = 15
            if p.mood == .beaming { p.mood = .happy }
        }
        sound.zap(false)
        sound.roar()
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

    /// A mirror in the house or spare room swings into view so `people` (standing) can see what they've turned into.
    private func standingMirror(_ people: [Person], caption seen: String, seconds: Double = 4) async throws {
        mirrorFolks = people.map(\.id)
        try await showMirror(people, caption: seen, seconds: seconds)
        mirrorFolks = []
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
            if let kind = p.animal { album.add(AlbumEntry(date: .now, spec: PersonSpec(p, kind: kind))) }
        }
        try await sleep(1.4)
    }

    // MARK: The flying zoo

    private func moveMini(to point: CGPoint, over seconds: Double) {
        miniFrom = seconds == 0 ? point : miniSaucer(at: .now) ?? point
        miniTo = point
        miniT0 = .now
        miniDur = seconds
    }

    private func movePod(to point: CGPoint, over seconds: Double) {
        podFrom = seconds == 0 ? point : pod(at: .now) ?? point
        podTo = point
        podT0 = .now
        podDur = seconds
    }

    /// The beam lifts everyone up through the hatch.
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
        let (greeter, cashier, machinist) = roles
        try await look(at: Stage.full)
        caption = "Pick one of the flying zoo's destinations. Setup has to be paid for — they have $\(cash)."
        let venue = await withCheckedContinuation { cont in
            venuePick = cont
            choosingVenue = true
        }
        try Task.checkCancellation()

        caption = "Whoosh! The flying zoo zooms off to \(venue.theName)!"
        podFlying = true
        sound.hum(true)
        try await sleep(2.6)

        try await sceneChange {
            self.podFlying = false
            self.place = .venue
            self.venue = venue
            self.unstrap(self.team)
            self.show([])
            self.customers = []
            self.podShown = true
            self.movePod(to: CGPoint(x: Stage.venuePodX, y: -160), over: 0)
            self.cutNow(Stage.full)
        }
        served = []
        asked = 0
        earned = 0
        adultNames = (Self.menNames + Self.womenNames).shuffled()
        momNames = ["Brenda", "Denise", "Lena", "Rita", "Tanya", "Monica", "Sara", "Wendy", "Sherry", "Michelle", "Christine", "Karla", "Dawn"].shuffled()
        kidNames = ["Amy", "Ben", "Cora", "Danny", "Ella", "Finn", "Gwen", "Hannah", "Jade", "Max", "Noah", "Kai", "Mary", "Sue", "Ellie", "Lori", "Christina", "Kiki", "Heidi"].shuffled()
        let startCash = cash

        movePod(to: CGPoint(x: Stage.venuePodX, y: Stage.floorY - Stage.hoverLift), over: 2.4)
        caption = "The flying zoo comes down at \(venue.theName)!"
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
        sound.roar()
        try await say(greeter, "Step right up! Get transformed into an alien animal! Only $\(venue.price), kids $\(venue.kidPrice)!", 3.2)
        try await say(cashier, "Pick any animal you like — gorilla, pink tiger, rainbow tiger, even an aardvark!", 2.6)
        try await say(greeter, "And it dissolves in eight hours!", 2.2)

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

        try await say(greeter, "Hi! Want to be turned into an alien animal?", 2.4)
        let firstYes = Double.random(in: 0...1) < (withKid ? venue.kidYes : venue.adultYes)
        if withKid {
            try await say(first, firstYes ? ["Yes! Can I? Please?", "A TIGER? Cool!", "In a flying zoo? YES!"].randomElement()!
                                           : ["No way, that's too wild!", "Nope! I'm scared of tigers!", "Maybe when I'm bigger."].randomElement()!, 2.2)
        } else {
            try await say(first, firstYes ? ["Sure, why not!", "Beam me up!", "I've always wanted to be a butterfly!"].randomElement()!
                                           : ["No thanks!", "Not today!", "Uh… I'll pass."].randomElement()!, 2.2)
        }
        var buyers = firstYes ? [first] : []
        if kids.count > 1 {
            let second = kids[1]
            try await say(greeter, "How about you?", 1.6)
            let secondYes = Double.random(in: 0...1) < (firstYes ? 0.85 : venue.kidYes * 0.5)
            try await say(second, secondYes ? (firstYes ? ["Me too! Me too!", "I want to be an animal too!"].randomElement()!
                                                        : ["Well, I'm not scared! I'll do it!", "I will! ROAR!"].randomElement()!)
                                            : ["No thanks, I'll watch.", "Nuh-uh, too wild for me!"].randomElement()!, 2.2)
            if secondYes { buyers.append(second) }
        }
        let kidsIn = !buyers.isEmpty
        let sweetie = buyers.count > 1 ? "kids" : "sweetie"
        if let mother {
            try await say(cashier, "Would you like to be transformed too?", 2.2)
            let momYes = Double.random(in: 0...1) < (kidsIn ? venue.momYes : venue.momYes * 0.5)
            if momYes {
                try await say(mother, kidsIn ? "Why not? Let's be animals together!" : "Ha! Sure — I'll do it!", 2.4)
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
        let holdouts = group.filter { $0.animal == nil }
        if !holdouts.isEmpty {
            for p in holdouts { p.facing = -1 }
            greeter.facing = 1
            caption = "\(greeter.id) offers \(ListFormatter.localizedString(byJoining: holdouts.map(\.id))) a second chance."
            try await say(greeter, holdouts.count == 1 ? "Now that you've seen it up close — want a second chance?"
                                                      : "Now that you've seen it up close — anyone want a second chance?", 2.6)
            var second: [Person] = []
            for p in holdouts {
                let isMother = p === mother
                if isMother, let kid = kids.first(where: { $0.animal != nil }) {
                    try await say(kid, "Come on, Mom! Do it! Do it!", 2)
                }
                let yes = Double.random(in: 0...1) < (isMother ? 0.7 : p.isKid ? 0.7 : 0.55)
                let line = switch (yes, p.isKid) {
                case (true, true): ["Okay! I'm not scared anymore!", "It looks so fun! Me too!", "I changed my mind! Roar!"].randomElement()!
                case (true, false): ["Oh, why not — I'll do it too!", "You talked me into it!", "Okay, now I want to be an animal too!"].randomElement()!
                case (false, true): ["Still too wild for me!", "Nope, I'll just watch."].randomElement()!
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

        caption = group.allSatisfy({ $0.animal != nil }) ? "Off they go, transformed into alien animals!"
                                                       : "Off they go — some animals, some not!"
        for p in group { _ = beginWalk(p, to: -150, speed: stroll) }
        try await sleep((Stage.waitX[1] + 150) / stroll)
        customers = []
    }

    /// One trip through the zoo for `buyers`: they pay the cashier, get beamed up and transformed, and come back down
    /// to the rest of `group`, who wait off to the side.
    private func transformRound(_ buyers: [Person], group: [Person], payer: Person, venue: Venue) async throws {
        let (greeter, cashier, machinist) = roles
        let amount = buyers.reduce(0) { $0 + ($1.isKid ? venue.kidPrice : venue.price) }
        try await say(cashier, "That'll be $\(amount), please! It dissolves in eight hours.", 2.8)
        caption = "\(payer.id) pays $\(amount)."
        payer.says = ["Here you go!", "Here's $\(amount)!", "Worth every penny!"].randomElement()!
        payer.saysUntil = .now + 1.6
        cash += amount
        earned += amount
        cashPop = ("+$\(amount)", .now, Stage.cashX)
        sound.pay()
        try await sleep(1.8)

        caption = "\(ListFormatter.localizedString(byJoining: buyers.map(\.id))) \(buyers.count == 1 ? "steps" : "step") under the flying zoo."
        var moves = zip(buyers, Stage.beamSpot).map { ($0, $1) }
        let others = group.filter { p in !buyers.contains { $0 === p } }
        for (p, x) in zip(others, Stage.waitX.reversed()) { moves.append((p, x)) }
        try await walkAll(moves)
        for p in others { p.facing = -1 }
        try await beamUp(buyers)

        // Inside, one of them works the machine.
        let deckView = buyers.count == 3 ? CGRect(x: 300, y: 120, width: 820, height: 410) : CGRect(x: 440, y: 190, width: 680, height: 340)
        try await sceneChange {
            self.place = .pod
            self.seat(buyers, chairs: buyers.count == 3 ? [0, 1, 2] : Array([1, 2].suffix(buyers.count)))
            (machinist.x0, machinist.x1, machinist.moveDur, machinist.facing) = (Stage.controlX, Stage.controlX, 0, -1)
            machinist.place(height: 0)
            machinist.seated = false
            self.show([machinist] + buyers)
            self.cutNow(deckView)
        }
        try await strap(buyers)
        try await say(machinist, buyers.count == 1 ? "Welcome aboard! What type of alien animal do you want to be?"
                                                  : "Welcome aboard! What types of alien animal do you want to be?", 2.8)
        var riders: [(Person, AnimalKind)] = []
        for p in buyers {
            let kind = AnimalKind.allCases.randomElement()!
            try await say(p, ["\(kind.name), please!", "I want to be a \(kind.name)!", "\(kind.name)! Definitely \(kind.name)!"].randomElement()!, 2)
            riders.append((p, kind))
        }
        try await say(machinist, machinist.isKid ? "Hold still! I'm pressing the big red button!" : "Just relax! I'm pressing the glowing red button!", 2.4)
        try await runMachine(riders, presser: machinist, change: Machine.customerChange,
                             tingleLine: (buyers[0], "Ooh, this really tickles!"))
        try await look(at: deckView)
        try await say(machinist, buyers.count == 1 ? "All done! Take a look in the mirror!" : "All done! Take a look in the mirror, everybody!", 2.4)
        caption = "\(machinist.id) lowers the big mirror in front of the chairs…"
        try await showMirror(buyers, caption: buyers.count == 1 ? "\(buyers[0].id) sees an alien animal looking back!"
                                                                 : "They see alien animals looking back!", seconds: 3)
        for (p, kind) in riders {
            try await say(p, p.isKid ? ["I'm a \(kind.name)! \(kind.sound)", "Look at my animal ears!", "Best day EVER!"].randomElement()!
                                     : ["Wow! Look at me!", "I'm a real alien animal!", kind.reaction].randomElement()!, 2.2)
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
        if let watcher = others.first(where: { $0.animal == nil }) ?? others.first {
            watcher.facing = -1
            try await say(watcher, watcher.animal == nil ? "Look at you! You're an ANIMAL!" : "Yay! Now we're animals together!", 2.2)
        }
        try await say(buyers.last!, ["Thank you! We love it!", "Best thing at the whole \(venue.shortName)!", "Wait till my friends see this!"].randomElement()!, 2.4)
        try await say(greeter, "Remember — it dissolves in eight hours!", 2.2)
    }

    /// The zoo takes them home, and over five minutes their transformation dissolves away.
    /// `gather` sends everyone to the red button afterwards; `stayedHome` were waiting in the house.
    private func comeHome(first: Bool = false, gather: Bool = true, stayedHome: [Person] = []) async throws {
        let team = team
        let bySize = team.sorted { $0.height > $1.height }
        let lead = team.contains { $0 === debbie } ? debbie : bySize[0]
        let other = bySize.first { $0 !== lead } ?? lead
        try await look(at: Stage.full)
        let (greeter, cashier, _) = roles
        caption = "\(greeter.id) and \(cashier.id) beam back up, and the flying zoo takes them home."
        try await walkAll([(greeter, Stage.beamSpot[0]), (cashier, Stage.beamSpot[1])])
        try await beamUp([greeter, cashier])
        sound.hum(true)
        movePod(to: CGPoint(x: Stage.venuePodX, y: -170), over: 1.6)
        try await sleep(1.4)

        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.customers = []
            self.show(stayedHome)
            for (p, x) in zip(stayedHome, Stage.livingX.reversed()) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
            self.movePod(to: CGPoint(x: Stage.yardPodX, y: -160), over: 0)
            self.cutNow(Stage.full)
        }
        caption = "Home again!"
        movePod(to: CGPoint(x: Stage.yardPodX, y: Stage.floorY - Stage.hoverLift), over: 2.4)
        try await sleep(2.5)
        try await look(at: Stage.yardView)
        try await beamDown(team + [leader], at: Stage.yardLine + [305])
        leader.facing = -1
        try await say(leader, "Now that we have brought you home, your transformation will dissolve.", 3.2)
        try await say(leader, "It will take five minutes to disappear. Roar-voir!", 2.8)
        try await walk(leader, to: Stage.yardLine[1], speed: 150)
        try await beamUp([leader])
        caption = "The flying zoo zooms away…"
        movePod(to: CGPoint(x: Stage.yardPodX + 500, y: -220), over: 2.2)
        try await sleep(2.3)
        podShown = false
        sound.hum(false)
        for p in team { p.facing = 0 }
        try await look(at: Stage.shot(centerX: 200, height: 250))

        // Five minutes, sped up: fur, tails, ears and snouts all fade away.
        clockT0 = .now
        clockDur = 13.5
        clockLabel = "Five minutes later…"
        clockSpan = 300
        caption = "Over the next five minutes, their transformation slowly dissolves…"
        for p in team { p.fade(to: 0, over: 12.9) }
        sound.shimmer()
        try await sleep(3.9)
        if let kid = team.first(where: \.isKid) {
            mention(kid, "My animal ears are shrinking!", 3)
        }
        try await sleep(4.5)
        mention(lead, "Our fur is melting away…", 3)
        try await sleep(5.1)
        sound.shimmer()
        caption = "Everyone is back to normal!"
        try await say(lead, lead.isKid ? "We're us again!" : "We're ourselves again!", 2)

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
            caption = "Back in the living room, they talk it over."
            try await gatherAtButton(cast)
            try await say(debbie, "With our own machine out back, we can do this again and make more money!", 3)
            try await say(molly, "And next time we get to pick what kind of animal we are!", 2.6)
        } else {
            caption = "The transformation machine is waiting out in the backyard cottage."
            try await gatherAtButton(cast.filter(\.visible))
        }
    }

    /// Everyone walks into the living room and stands round the red button.
    private func gatherAtButton(_ people: [Person]) async throws {
        try await walkAll(zip(people, Stage.buttonSpots).map { ($0, $1) }, speed: 140)
        for (i, p) in people.enumerated() { p.facing = i == 0 ? 1 : -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
    }

    /// Everyone home goes to her room; night falls and they sleep.
    private func goToBed(_ people: [Person]) async throws {
        try await look(at: Stage.full)
        try await walkAll(people.compactMap { p in cast.firstIndex { $0 === p }.map { (p, Stage.roomX[$0]) } }, speed: 130)
        for p in people { p.facing = 0 }
        try await sleep(0.4)
        try await sceneChange {
            self.night = true
            for p in people {
                p.visible = false
                self.sleeping.insert(p.id)
            }
            if let sitter = self.couchSleeper { sitter.visible = false }
        }
        try await sleep(4.5)
    }

    /// Morning: everyone home is up and standing by her bed (and the babysitter by the couch).
    private func wakeUp(_ people: [Person]) {
        night = false
        sleeping = []
        show(people + (couchSleeper.map { [$0] } ?? []))
        for p in people {
            guard let i = cast.firstIndex(where: { $0 === p }) else { continue }
            (p.x0, p.x1, p.moveDur, p.facing) = (Stage.roomX[i], Stage.roomX[i], 0, 0)
        }
        if let sitter = couchSleeper { (sitter.x0, sitter.x1, sitter.moveDur, sitter.facing) = (600, 600, 0, -1) }
        cutNow(Stage.full)
    }

    /// After every second trip someone goes shopping and makes a deposit at the bank. When she comes home
    /// it gets dark, they all get some rest, and they can go again the following morning.
    /// `away` is Debbie, off on vacation; `overnight` is the babysitter, sleeping on the couch.
    private func restUntilMorning(shopper: Person, away: Person? = nil, overnight: Person? = nil) async throws {
        let home = cast.filter { $0 !== away }
        let others = home.filter { $0 !== shopper }
        let waving = others + (overnight.map { [$0] } ?? [])
        try await say(shopper, shopper.isKid ? "That's it for today! I'll do the shopping and put our money in the bank, just like Mom does."
                                             : "That's it for today! I'm going shopping, and I'll put our money in the bank.", 3.2)
        if let overnight { try await say(overnight, "Go ahead, \(shopper.id). We'll wait right here.", 2.2) }
        shout(waving, "See you soon!", 1.6)
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
        shopper.load = .groceries
        shopper.visible = true
        shopper.facing = 0
        try await say(shopper, "Dinner and breakfast — done!", 2.2)

        caption = "Next stop: the bank."
        try await walk(shopper, to: Stage.bankDoorX, speed: 140)
        shopper.visible = false
        let deposit = max(0, (cash - Self.keepForSetup) / 10 * 10)
        try await sleep(1.4)
        if deposit > 0 {
            cash -= deposit
            bank += deposit
            cashPop = ("Deposited $\(deposit)", .now, Stage.bankDoorX)
            sound.pay()
            caption = "\(shopper.id) deposits $\(deposit) in the bank. Savings: $\(bank)."
        } else {
            caption = "\(shopper.id) keeps what they have for the next setup fee."
        }
        try await sleep(2.2)
        shopper.visible = true
        shopper.facing = 0
        try await say(shopper, deposit > 0 ? "Our savings are growing!" : "Nothing extra to deposit today — we need it for the setup fee.", 2.6)
        try await walk(shopper, to: Stage.W + 60, speed: 150)
        // Only Debbie can buy (and drive) new wheels.
        let wheels = shopper === debbie ? try await visitShops(shopper) : nil

        // Home again, and it gets dark.
        try await sceneChange {
            self.place = .house
            self.show(home + (overnight.map { [$0] } ?? []))
            for (p, x) in zip(others, Stage.livingX.reversed()) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
            if let overnight { (overnight.x0, overnight.x1, overnight.moveDur, overnight.facing) = (Stage.livingX[0] + 50, Stage.livingX[0] + 50, 0, -1) }
            (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
            if let wheels {
                shopper.visible = false
                self.vehicles.insert(wheels)
                self.arriving = wheels
                self.rider = wheels == .car ? nil : shopper
                self.arriveT0 = .now + 0.8
            }
        }
        if let wheels {
            caption = "\(shopper.id) \(wheels == .car ? "drives" : "rides") home on her new \(wheels.name.lowercased())!"
            sound.hum(true)
            try await sleep(Self.arriveDur + 0.9)
            sound.hum(false)
            sound.beep()
            let spot = switch wheels {
            case .car: Stage.carX + 80
            case .motorcycle: Stage.motorcycleX + 45
            case .scooter: Stage.scooterX + 40
            }
            arriving = nil
            rider = nil
            (shopper.x0, shopper.x1, shopper.moveDur) = (spot, spot, 0)
            shopper.visible = true
            shout(others, "A \(wheels.name.uppercased())!", 1.8)
            try await sleep(2)
        } else {
            caption = "\(shopper.id) comes home with the groceries."
        }
        try await walk(shopper, to: 440, speed: 150)
        shopper.load = nil
        shopper.facing = 1
        try await say(shopper, "I'm back! The groceries are in, and \(bank > 0 ? "we have $\(bank) in the bank" : "the bills are paid").", 3)
        if let wheels {
            try await say(shopper, wheels == .motorcycle ? "And a brand-new motorcycle — paid for out of our savings! Nobody can repossess this one!"
                                                         : "And the \(wheels.name.lowercased()) is all ours — paid for out of our savings!", 3.2)
            try await say(hailey, "Way to go, Mom!", 1.8)
        }
        try await sceneChange { self.night = true }
        caption = "It gets dark, and they all get some rest."
        try await say(others.first ?? shopper, "It's dark already! Let's all get some rest.", 2.4)
        if let overnight {
            caption = "\(overnight.id) stays over on the couch."
            couchSleeper = overnight
        }
        try await goToBed(home)
        nights += 1

        try await sceneChange {
            self.place = .house
            self.wakeUp(home)
            self.couchSleeper = nil
        }
        caption = "The following morning…"
        sound.chime()
        try await sleep(1.2)
        try await say(others.first ?? shopper, "Good morning! I feel so rested!", 2.2)
        guard away == nil else { return }
        try await gatherAtButton(cast)
    }

    /// The dealer along Main Street, where the savings in the bank can buy a scooter, a motorcycle or a car.
    private func visitShops(_ shopper: Person) async throws -> Vehicle? {
        try await sceneChange {
            self.place = .shops
            (shopper.x0, shopper.x1, shopper.moveDur) = (-40, -40, 0)
            self.cutNow(Stage.full)
        }
        let forSale = Vehicle.allCases.filter { !vehicles.contains($0) }
        guard let cheapest = forSale.min(by: { $0.price < $1.price }) else {
            caption = "Debbie walks past Wheels & Deals."
            try await walk(shopper, to: Stage.dealerDoorX, speed: 140)
            try await say(shopper, "A scooter, a motorcycle AND a car. We have everything we need!", 2.8)
            try await walk(shopper, to: Stage.W + 60, speed: 150)
            return nil
        }
        caption = "Further along Main Street: Wheels & Deals."
        try await walk(shopper, to: Stage.dealerDoorX, speed: 140)
        shopper.facing = 0
        if bank < cheapest.price {
            try await say(shopper, "A \(cheapest.name.lowercased()) is $\(cheapest.price). We have $\(bank) in the bank — one day!", 3.2)
            try await walk(shopper, to: Stage.W + 60, speed: 150)
            return nil
        }
        try await say(shopper, "We have $\(bank) saved. That's enough for some wheels!", 2.8)
        caption = "Debbie has $\(bank) in the bank. Buy a scooter, a motorcycle, or a car?"
        let wheels = await withCheckedContinuation { cont in
            vehiclePick = cont
            choosingVehicle = true
        }
        try Task.checkCancellation()
        if let wheels {
            shopper.visible = false
            bank -= wheels.price
            cashPop = ("-$\(wheels.price) from savings", .now, Stage.dealerDoorX - 60)
            sound.pay()
            caption = "Debbie buys a \(wheels.name.lowercased()) for $\(wheels.price) out of her savings. Left in the bank: $\(bank)."
            try await sleep(3)
            return wheels
        }
        caption = "Debbie leaves the savings where they are."
        try await say(shopper, "Not today. Let's keep saving.", 2.2)
        try await walk(shopper, to: Stage.W + 60, speed: 150)
        return nil
    }

    private static let groceryBill = 35
    private static let keepForSetup = 300

    // MARK: An aunt and a cousin

    /// After the first and every odd night, an aunt (five take turns) comes to take Debbie clothes shopping, and brings her
    /// little daughter. Debbie has the girls show their cousin how they make money; the cousin gets a third of the profit.
    /// When the grown-ups come home, the cousin shows her mother the money — and the button — and the aunt, the cousin and
    /// one of the girls go on a trip, with a third of the profit for the aunt and cousin.
    private func auntVisit() async throws {
        let age = Int.random(in: 3...7)
        let (aunt, cousin) = Self.makeAunt(auntVisits, age: age)
        auntVisits += 1
        visitors = [aunt, cousin]
        let al = Self.auntIntro(aunt.id, kid: cousin.id)
        let cl = Self.cousinIntro(cousin.id)
        let (debbie, hailey, molly) = (debbie, hailey, molly)

        // Ding-dong
        try await look(at: Stage.full)
        sound.chime()
        caption = "Ding-dong! It's \(aunt.id), with cousin \(cousin.id), who is \(age)."
        for p in visitors { p.visible = true }
        for (p, x) in [(debbie, 505.0), (hailey, 560), (molly, 605)] { _ = beginWalk(p, to: x, speed: 120) }
        try await walkAll([(aunt, 445), (cousin, 472)], speed: 150)
        for p in visitors { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        shout([hailey, molly], "\(aunt.id)! \(cousin.id)!", 1.8)
        try await sleep(2)
        try await say(aunt, "Good morning, Debbie! Ready to go clothes shopping? You need some new outfits for job hunting!", 3.6)
        try await say(debbie, "I sure am! Just give me one minute.", 2.2)
        try await say(aunt, "I'll go warm up the car. Don't be long!", 2.2)
        try await walk(aunt, to: -60, speed: 150)
        aunt.visible = false

        caption = "Before she leaves, Debbie has a quiet word with her girls."
        try await say(debbie, "Girls — while we're gone, show \(cousin.id) how we make money, and take her along on a trip.", 3.4)
        try await say(debbie, "She gets one third of the profit.", 2.2)
        try await say(hailey, "You got it, Mom!", 1.6)
        try await say(debbie, "Be good! See you this afternoon!", 2)
        try await walk(debbie, to: -60, speed: 150)
        debbie.visible = false

        cousin.facing = 1
        try await look(at: Stage.shot(centerX: 520, height: 230))
        try await say(cousin, "How do you make money?", 1.8)
        try await say(hailey, "We have a transformation machine out in our backyard cottage — and a flying zoo full of alien animals!", 3.4)
        try await say(cousin, "Animals?! Can I be one too?", 2)
        try await say(molly, "Yes! Come on — out back!", 1.8)

        // The cousin's trip: she asks the customers, Hailey takes the money, and Molly works the machine.
        team = [cousin, hailey, molly]
        let trio = [hailey, cousin, molly]
        try await callThePod(trio, pusher: cousin, caller: hailey, seated: trio, newcomer: cousin, newcomerLines: (cl.spot, cl.beamUp))
        try await look(at: Stage.chairsView)
        try await say(cousin, cl.inPod, 2.2)
        try await say(hailey, "Welcome to our animal cottage, \(cousin.id)!", 2.2)
        try await say(molly, "You get the middle chair!", 1.8)
        try await strap(trio)
        caption = "Straps snap across all three of them."
        try await say(cousin, cl.straps, 2)
        let picks = try await pickKinds(trio)
        let cousinKind = picks[1].1
        try await look(at: Stage.full)
        try await say(hailey, "Just relax. I'll press the button!", 2)
        caption = "Hailey hops up to press the glowing red button…"
        try await runMachine(picks, presser: hailey, change: Machine.change,
                             tingleLine: (cousin, cl.tingle), legsStartLine: (cousin, cl.legs), bodyLine: (cousin, cl.body),
                             faceShouts: (cousin, [(cl.face, 15), (cl.faceShout, 17)]), beamOnShout: 1)
        try await look(at: Stage.full)
        try await say(molly, "Look in the mirror!", 1.8)
        caption = "The big mirror rolls down…"
        try await showMirror(trio, caption: "…and \(cousin.id) sees an alien animal looking back!", calm: [cousin])
        try await look(at: Stage.chairsView)
        try await say(cousin, cl.headFeel, 2.4)
        try await say(cousin, cousinKind.reaction, 2.4)
        try await say(hailey, picks[0].1.reaction, 2.4)
        try await say(molly, picks[2].1.reaction, 2.4)
        try await snap(trio)
        unstrap(trio)
        try await zooPickup(trio)
        try await say(leader, "\(cousin.id) asks the customers, Hailey takes the money, and Molly works the machine.", 3.4)
        try await tripToVenue()
        try await comeHome(gather: false)

        let share = max(0, (result?.profit ?? 0) / 3)
        if share > 0 {
            caption = "\(cousin.id) gets one third of the profit: $\(share)."
            try await say(hailey, "\(cousin.id), one third of the profit is yours — $\(share)!", 2.8)
            cash -= share
            cashPop = ("-$\(share) to \(cousin.id)", .now, cousin.x(at: .now))
            sound.pay()
            try await say(cousin, "$\(share)! I can't wait to show Mommy!", 2.4)
        } else {
            try await say(hailey, "No profit to share today, \(cousin.id) — but you were a big help!", 2.8)
            try await say(cousin, "That's okay! It was fun!", 2)
        }
        try await look(at: Stage.full)
        try await walkAll([(cousin, 490), (hailey, 560), (molly, 605)], speed: 140)

        // That afternoon the grown-ups come home with their shopping.
        caption = "That afternoon, Debbie and \(aunt.id) come home from shopping."
        for p in [aunt, debbie] {
            (p.x0, p.x1, p.moveDur) = (-60, -60, 0)
            p.load = .shopping
            p.visible = true
        }
        try await walkAll([(aunt, 455), (debbie, 425)], speed: 150)
        for p in [aunt, debbie] { p.facing = 1 }
        for p in [cousin, hailey, molly] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 500, height: 230))
        try await say(debbie, "We're back! Wait till you see my new outfits!", 2.4)
        for p in [aunt, debbie] { p.load = nil }
        if share > 0 {
            cousin.reachTo = CGPoint(x: 472, y: Stage.floorY - 52)
            sound.pay()
            try await say(cousin, "Mommy! Look — I made $\(share) for you!", 2.6)
            cousin.reachTo = nil
            aunt.mood = .shocked
            try await say(aunt, "$\(share)?! How did you ever get all that money?", 2.6)
        } else {
            try await say(cousin, "Mommy! I had the best day ever!", 2)
            aunt.mood = .shocked
            try await say(aunt, "Really? What did you do all day?", 2.2)
        }
        aunt.mood = .happy
        try await say(cousin, "Come see! It's out back in the cottage!", 2)
        try await say(cousin, "There's a machine, and a flying zoo! Come on a trip with us, Mommy! Please?", 3)
        try await say(aunt, "A flying zoo? Well… now I have to see this!", 2.4)
        let sibling = Bool.random() ? hailey : molly
        let stayer = sibling === hailey ? molly : hailey
        try await say(debbie, "Go ahead! \(sibling.id) will show you. \(stayer.id) and I will put away my new clothes.", 3.2)

        // The aunt's trip: the aunt, the cousin and one of the girls.
        team = [aunt, cousin, sibling]
        let three = [cousin, aunt, sibling]   // the aunt in the middle chair
        try await callThePod(three, pusher: cousin, caller: sibling, seated: three, newcomer: aunt, newcomerLines: (al.spot, al.beamUp))
        try await look(at: Stage.chairsView)
        try await say(aunt, al.inPod, 2.6)
        try await say(sibling, "Welcome to our animal cottage, Aunt \(aunt.id)!", 2.4)
        try await say(aunt, al.whatsNext, 2.8)
        try await say(sibling, "Just sit back and enjoy it, \(aunt.id). You'll love it!", 2.4)
        try await strap(three)
        caption = "Straps snap across all three of them at once!"
        try await say(aunt, al.straps, 2.8)
        let picks2 = try await pickKinds(three, silent: true)
        let auntKind = picks2[1].1
        try await look(at: Stage.full)
        try await say(sibling, "Just relax. I'll press the button!", 2)
        caption = "\(sibling.id) hops up to press the glowing red button…"
        try await runMachine(picks2, presser: sibling, change: Machine.change,
                             tingleLine: (aunt, al.tingle), legsStartLine: (aunt, al.legs), bodyLine: (aunt, al.body),
                             faceShouts: (aunt, [(al.face, 15), (al.faceShout, 17)]), beamOnShout: 1)
        try await feelHead(aunt, line: al.headFeel)
        try await look(at: Stage.full)
        try await say(cousin, "Look in the mirror, Mommy!", 1.8)
        caption = "The big mirror rolls down…"
        try await showMirror(three, caption: "…and \(aunt.id) sees an alien animal looking back!", calm: [aunt])
        try await look(at: Stage.chairsView)
        try await say(aunt, auntKind.reaction, 2.4)
        try await say(cousin, "Mommy, you're an animal just like me!", 2.2)
        try await say(sibling, "And customers pay us to turn them into alien animals too — that's how \(cousin.id) made the money!", 3.4)
        try await say(aunt, al.secret, 3)
        try await snap(three)
        unstrap(three)
        try await zooPickup(three)
        try await say(leader, "\(aunt.id) asks the customers, \(cousin.id) takes the money, and \(sibling.id) works the machine.", 3.4)
        try await tripToVenue()
        try await comeHome(gather: false, stayedHome: [debbie, stayer])

        let momShare = max(0, (result?.profit ?? 0) / 3)
        if momShare > 0 {
            caption = "\(aunt.id) and \(cousin.id) get one third of the profit: $\(momShare)."
            try await say(debbie, "\(aunt.id), you and \(cousin.id) get one third of the profit — $\(momShare)!", 3)
            cash -= momShare
            cashPop = ("-$\(momShare) to \(aunt.id) & \(cousin.id)", .now, aunt.x(at: .now))
            sound.pay()
            try await say(aunt, "$\(momShare)! Thank you, Debbie!", 2.2)
            try await say(cousin, "We're rich, Mommy!", 1.8)
        } else {
            try await say(debbie, "No profit to share this time, \(aunt.id) — sorry!", 2.4)
            try await say(aunt, "Don't be! I wouldn't have missed it.", 2.2)
        }

        // Before they go, the cousin and the aunt each play the Animals of Poker in the spare room.
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(molly, "\(cousin.id), before you go — come play the game machine in the spare room!", 3)
        try await say(hailey, "Bet the max every hand, and at game 10 a little flying saucer comes out!", 3)
        try await say(cousin, "Can I, Mommy? Please?", 1.8)
        try await say(aunt, "Go on, sweetie. I'll watch.", 2)
        let cousinNew = AnimalKind.allCases.filter { $0 != cousinKind }.randomElement()!
        try await toSpareRoom(player: cousin, watchers: [aunt, molly])
        try await say(cousin, "It's lighting up! 200 credits!", 2)
        try await playPoker(cousin)
        try await gameTen(cousin, kind: cousinNew,
                          lines: (spot: "The flying saucer!", tingle: "Hee-hee, it tickles!", legs: "My feet are changing!",
                                  body: "I have fur and a tail again!", face: "Mommy, look at my face!"))
        cousin.mood = .beaming
        try await say(cousin, "I'm an alien \(cousinNew.name) now! Your turn, Mommy!", 2.4)
        cousin.mood = .happy
        try await say(aunt, "All right, all right — let me sit down.", 2.2)
        try await swapPlayer(to: aunt, from: cousin)
        try await say(aunt, "Bet max every hand… here goes!", 2)
        let auntNew = AnimalKind.allCases.filter { $0 != auntKind && $0 != cousinNew }.randomElement()!
        try await playPoker(aunt)
        try await gameTen(aunt, kind: auntNew,
                          lines: (spot: "Here it comes again!", tingle: "Oh, that tickles!", legs: "It's starting at my toes!",
                                  body: "There goes my tummy!", face: "Oh my — my face!"))
        aunt.mood = .beaming
        try await say(aunt, "An alien \(auntNew.name)! This machine is something else!", 2.6)
        aunt.mood = .happy
        try await say(cousin, "We're going home as animals, Mommy!", 2.2)
        try await sceneChange {
            self.place = .house
            self.show(self.cast + self.visitors)
            for (p, x) in zip(self.visitors + self.cast, [445.0, 472, 520, 565, 605]) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0) }
            self.cutNow(Stage.full)
        }

        // Home time for the aunt and cousin.
        try await look(at: Stage.full)
        try await walkAll([(aunt, 445), (cousin, 472), (debbie, 520), (hailey, 565), (molly, 605)], speed: 150)
        for p in visitors { p.facing = 1 }
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(cousin, "Did you have fun, Mommy?", 1.8)
        try await say(aunt, al.bestDay, 2.8)
        try await say(aunt, "Thanks for a wonderful day, Debbie. Come on, sweetie — time to go home.", 3)
        try await say(cousin, cl.bestDay, 1.8)
        caption = "\(aunt.id) and \(cousin.id) head home."
        try await walkAll([(aunt, -80), (cousin, -50)], speed: 150)
        visitors = []
        try await walkAll(zip(cast, Stage.livingX).map { ($0, $1) }, speed: 140)
    }

    // MARK: Debbie's night away

    /// Debbie pays for a night's solo vacation and hires a babysitter (five take turns). The girls show the sitter how they
    /// make money and give her a third of each trip's profit. After their second trip Hailey does the shopping and the bank;
    /// the sitter sleeps over on the couch, and Debbie comes home the next morning.
    private func babysitterDay() async throws {
        let (debbie, hailey, molly) = (debbie, hailey, molly)
        let fromBank = min(bank, Self.vacationCost)
        bank -= fromBank
        cash -= Self.vacationCost - fromBank
        cashPop = ("-$\(Self.vacationCost) vacation", .now, debbie.x(at: .now))
        sound.pay()
        let destination = ["a spa resort in the Poconos", "a beach inn in Cape May", "a hotel on the Atlantic City boardwalk",
                           "a cabin on Lake George", "a bed-and-breakfast in Vermont"].randomElement()!
        let sitter = Self.makeSitter(sitterVisits)
        sitterVisits += 1
        let sl = Self.sitterIntro(sitter.id)
        try await say(debbie, "I'm going! One night at \(destination) — just for me!", 2.8)
        try await say(hailey, "You deserve it, Mom!", 1.8)
        try await say(debbie, "I've hired a babysitter. Her name is \(sitter.id).", 2.4)

        // Ding-dong
        try await look(at: Stage.full)
        sound.chime()
        caption = "Ding-dong! It's the babysitter, \(sitter.id)."
        visitors = [sitter]
        sitter.visible = true
        for (p, x) in [(debbie, 505.0), (hailey, 560), (molly, 605)] { _ = beginWalk(p, to: x, speed: 120) }
        try await walk(sitter, to: 450, speed: 150)
        sitter.facing = 1
        for p in cast { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(sitter, "Hi! I'm \(sitter.id), the babysitter!", 2)
        try await say(debbie, "Thanks for coming, \(sitter.id). Girls — show \(sitter.id) how we make money, and give her one third of the profit.", 3.8)
        try await say(sitter, "Make money? Ooh, now I'm curious!", 2.2)
        debbie.load = .suitcase
        try await say(debbie, "Bye, girls! Be good for \(sitter.id)! I'll be home tomorrow morning.", 3)
        shout([hailey, molly], "Bye, Mom! Have fun!", 1.8)
        caption = "Debbie heads off on her vacation to \(destination)."
        try await walk(debbie, to: -60, speed: 150)
        debbie.visible = false
        debbie.load = nil

        try await look(at: Stage.shot(centerX: 520, height: 230))
        try await say(hailey, "\(sitter.id), we have a transformation machine in our backyard cottage — and a flying zoo!", 3)
        try await say(molly, "Full of animal people!", 1.8)
        try await say(sitter, "Animal people? Okay, I have to see this!", 2.2)

        // First trip: the sitter asks the customers, Molly takes the money, Hailey works the machine.
        team = [sitter, molly, hailey]
        let trio = [molly, sitter, hailey]   // the sitter in the middle chair
        try await callThePod(trio, pusher: molly, caller: hailey, seated: trio, newcomer: sitter, newcomerLines: (sl.spot, sl.beamUp))
        try await look(at: Stage.chairsView)
        try await say(sitter, sl.inPod, 2.6)
        try await say(molly, "Welcome to our animal cottage!", 2)
        try await say(hailey, "This is \(sitter.id), our babysitter!", 2)
        try await say(sitter, sl.whatsNext, 2.8)
        try await strap(trio)
        caption = "Straps snap across all three of them!"
        try await say(sitter, sl.straps, 2.4)
        let picks = try await pickKinds(trio, silent: true)
        let firstKind = picks[1].1
        try await look(at: Stage.full)
        try await say(hailey, "Just relax. I'll press the button!", 2)
        caption = "Hailey hops up to press the glowing red button…"
        try await runMachine(picks, presser: hailey, change: Machine.change,
                             tingleLine: (sitter, sl.tingle), legsStartLine: (sitter, sl.legs), bodyLine: (sitter, sl.body),
                             faceShouts: (sitter, [(sl.face, 15), (sl.faceShout, 17)]), beamOnShout: 1)
        try await feelHead(sitter, line: sl.headFeel)
        try await look(at: Stage.full)
        try await say(molly, "Look in the mirror!", 1.8)
        caption = "The big mirror rolls down…"
        try await showMirror(trio, caption: "…and \(sitter.id) sees an alien animal looking back!", calm: [sitter])
        try await look(at: Stage.chairsView)
        try await say(sitter, firstKind.reaction, 2.4)
        try await say(hailey, "Customers pay us to turn them into alien animals too — and you get a third of the profit!", 3.2)
        try await say(sitter, sl.secret, 2.8)
        try await snap(trio)
        unstrap(trio)
        try await zooPickup(trio)
        try await say(leader, "\(sitter.id) asks the customers, Molly takes the money, and Hailey works the machine.", 3.4)
        try await tripToVenue()
        try await comeHome(gather: false)
        var made = try await paySitter(sitter)

        // Second trip.
        try await say(hailey, "One more trip before bedtime!", 2)
        try await callThePod(trio, pusher: sitter, caller: molly, seated: trio)
        try await transformAgain(trio, presser: sitter, quick: true, welcome: "Pick your animals, everybody!", legsStartLine: (sitter, sl.again))
        try await snap(trio)
        unstrap(trio)
        try await zooPickup(trio)
        team = [hailey, sitter, molly]
        try await say(leader, "This time Hailey asks the customers, \(sitter.id) takes the money, and Molly works the machine.", 3.4)
        try await tripToVenue()
        try await comeHome(gather: false)
        made += try await paySitter(sitter)

        // Hailey does the shopping and the bank; the sitter sleeps over.
        try await restUntilMorning(shopper: hailey, away: debbie, overnight: sitter)

        // Debbie comes home.
        caption = "Debbie comes home from her vacation."
        (debbie.x0, debbie.x1, debbie.moveDur) = (-60, -60, 0)
        debbie.load = .suitcase
        debbie.visible = true
        try await walkAll([(debbie, 445), (hailey, 520), (molly, 560), (sitter, 605)], speed: 150)
        debbie.load = nil
        debbie.facing = 1
        for p in [hailey, molly, sitter] { p.facing = -1 }
        try await look(at: Stage.shot(centerX: 520, height: 250))
        try await say(debbie, "I'm home! The trip was wonderful — I feel like a new woman!", 2.8)
        shout([hailey, molly], "Mommy!", 1.6)
        try await sleep(1.8)
        try await say(hailey, "We did two trips, Mom! And I did the shopping AND the bank — we have $\(bank) saved!", 3.4)
        try await say(sitter, made > 0 ? "Your girls were angels, Debbie. And I made $\(made)!" : "Your girls were angels, Debbie!", 2.8)
        try await say(sitter, sl.bestDay, 2.8)
        try await say(debbie, "Thank you, \(sitter.id)! Come back anytime.", 2.4)
        caption = "\(sitter.id) heads home."
        try await walk(sitter, to: -60, speed: 150)
        visitors = []
        try await gatherAtButton(cast)
    }

    /// The babysitter's third of the last trip's profit. Returns what she was paid.
    private func paySitter(_ sitter: Person) async throws -> Int {
        let share = max(0, (result?.profit ?? 0) / 3)
        if share > 0 {
            caption = "\(sitter.id) gets one third of the profit: $\(share)."
            try await say(hailey, "\(sitter.id), one third of the profit is yours — $\(share)!", 2.8)
            cash -= share
            cashPop = ("-$\(share) to \(sitter.id)", .now, sitter.x(at: .now))
            sound.pay()
            try await say(sitter, "$\(share)! This is the best babysitting job ever!", 2.4)
        } else {
            try await say(hailey, "No profit to share this time, \(sitter.id) — sorry!", 2.4)
            try await say(sitter, "No worries! That was a blast!", 2)
        }
        return share
    }

    /// The straps let go, and she reaches up to feel her new head.
    private func feelHead(_ p: Person, line: String) async throws {
        let pose = Pose(p, feet: CGPoint(x: p.x(at: .now), y: Stage.floorY), facing: 0, now: .now)
        cut(to: Stage.focus(CGPoint(x: pose.head.x, y: pose.head.y + pose.hr * 0.4), height: 180))
        strapped = []
        sound.clunk()
        try await sleep(0.6)
        caption = "\(p.id) reaches up and feels her animal ears…"
        p.feelsHead = true
        try await sleep(2.2)
        try await say(p, line, 3)
        p.feelsHead = false
    }

    // MARK: Doing it again

    /// Out to the cottage: everyone picks her own type of alien animal, then the zoo picks them up.
    private func doItAgain() async throws {
        try await say(debbie, "Let's do it again!", 1.8)
        rotation += 1
        team = (0..<3).map { cast[(rotation + $0) % 3] }
        let presser = cast.randomElement()!
        try await callThePod(cast, pusher: presser, caller: hailey, seated: cast)
        try await transformAgain(cast, presser: presser, legsStartLine: (molly, "It tickles again!"), bodyLine: (hailey, "Here comes our fur!"))
        try await snap(cast)
        unstrap(cast)
        try await zooPickup(cast)
        let (g, c, m) = roles
        try await say(leader, "\(g.id) asks the customers, \(c.id) takes the money, and \(m.id) works the machine.", 3.4)
    }

    /// `pusher` leads everyone out back to the cottage; `seated` take the chairs and the rest stand by.
    /// A `newcomer` has never seen it before; her `newcomerLines` are saved for when the flying zoo picks them up.
    private func callThePod(_ riders: [Person], pusher: Person, caller: Person, seated: [Person], newcomer: Person? = nil,
                            newcomerLines: (spot: String, beam: String) = ("Oh, how fun! A flying zoo!", "Wheee!")) async throws {
        try await say(pusher, pusher.isKid ? "Come on! Out to the cottage!" : ["To the cottage!", "Out back, everybody!", "Let's go!"].randomElement()!, 1.8)
        pickupNewcomer = newcomer.map { ($0, newcomerLines) }
        try await sceneChange {
            self.place = .cottage
            self.podShown = false
            for (i, p) in riders.enumerated() {
                let x = -40 - Double(i) * 40
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
                p.seated = false
                p.place(height: 0)
            }
            self.show(riders)
            self.cutNow(Stage.full)
        }
        caption = "\(pusher.id) leads everyone across the backyard to the cottage."
        let standing = riders.filter { p in !seated.contains { $0 === p } }
        try await walkAll(zip(seated, Stage.chairX).map { ($0, $1) } + zip(standing, Stage.cottageStandX).map { ($0, $1) }, speed: 170)
        seat(seated, chairs: Array(0..<seated.count))
        for p in standing { p.facing = -1 }
        if let n = newcomer {
            try await say(n, n.isKid ? "Whoa! A transformation machine in your backyard?!" : "A transformation machine… in a backyard cottage?!", 2.6)
        }
        try await say(caller, "Sit back and get comfy!", 1.8)
    }

    /// Everyone walks out to the backyard; the flying zoo comes down (the red button called it), pulls them up,
    /// and they're aboard with the alien animals.
    private func zooPickup(_ riders: [Person]) async throws {
        let newcomer = pickupNewcomer
        pickupNewcomer = nil
        try await look(at: Stage.full)
        if !podShown {
            caption = "The glowing red button calls the flying zoo…"
            podShown = true
            movePod(to: CGPoint(x: Stage.backPodX - 400, y: -170), over: 0)
            movePod(to: CGPoint(x: Stage.backPodX, y: Stage.floorY - Stage.hoverLift), over: 3)
            sound.hum(true)
            try await sleep(3.1)
            sound.roar()
        }
        if let (n, lines) = newcomer {
            try await say(n, lines.spot, 2.4)
        }
        caption = "Everyone hurries out to the backyard."
        try await walkAll(zip(riders, Stage.backLine).map { ($0, $1) }, speed: 170)
        for p in riders { p.facing = 0 }
        caption = newcomer.map { "The zoo pulls them in — \($0.0.id) too!" } ?? "The zoo pulls them in!"
        if let (n, lines) = newcomer { shout([n], lines.beam, 2) }
        try await beamUp(riders)
        movePod(to: CGPoint(x: Stage.backPodX + 500, y: -220), over: 2.2)
        try await sleep(1.9)

        try await sceneChange {
            self.place = .pod
            self.podShown = false
            self.sound.hum(false)
            for (p, x) in zip(self.crew, Stage.crewX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.place(height: 0)
            }
            (self.leader.x0, self.leader.x1, self.leader.facing) = (Stage.consoleX - 45, Stage.consoleX - 45, -1)
            for (p, x) in zip(riders, [Stage.chairX[0], Stage.chairX[1], Stage.chairX[2], Stage.standByX[0]]) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
                p.seated = false
                p.place(height: 0)
            }
            self.show(self.crew + riders)
            self.cutNow(Stage.full)
        }
        caption = "Aboard the flying zoo!"
        sound.roar()
        try await say(leader, "Welcome aboard!", 1.6)
    }

    /// Up to three of them in the cottage chairs: each picks her type of alien animal, `presser` hops up and presses
    /// the red button, and they see themselves in the mirror. `quick` is the shorter show for old hands.
    private func transformAgain(_ riders: [Person], presser: Person, quick: Bool = false, welcome: String? = nil,
                                legsStartLine: (Person, String)? = nil, bodyLine: (Person, String)? = nil) async throws {
        try await strap(riders)
        caption = "Strapped into the chairs in the cottage."
        try await say(presser, welcome ?? (quick ? "You know the drill — pick your animals!"
                                                 : "This time we each choose what type of alien animal we want to be!"), 3)
        let riders = try await pickKinds(riders)
        try await look(at: Stage.full)
        caption = "\(presser.id) hops up to press the glowing red button…"
        try await runMachine(riders, presser: presser, change: quick ? Machine.customerChange : Machine.change,
                             tingleShout: "This really tickles!", legsStartLine: legsStartLine, bodyLine: bodyLine,
                             facesLine: "Now our faces!")
        try await look(at: Stage.full)
        caption = "The big mirror rolls down…"
        try await showMirror(riders.map(\.0), caption: "…and they see what type of animal they picked!", seconds: quick ? 3 : 4)
        try await look(at: Stage.chairsView)
        for (p, kind) in riders {
            try await say(p, p.isKid ? "I'm a \(kind.name)! \(kind.sound)" : kind.reaction, 2.4)
        }
    }

    /// The player picks each rider's type of alien animal, with the camera on her.
    /// `silent`: she doesn't know what's coming, so she doesn't announce her pick.
    private func pickKinds(_ riders: [Person], silent: Bool = false) async throws -> [(Person, AnimalKind)] {
        var picked: [(Person, AnimalKind)] = []
        for p in riders {
            try await look(at: Stage.focus(CGPoint(x: p.x(at: .now), y: Stage.floorY - 90), height: 230))
            caption = silent ? "Pick a type of alien animal for \(p.id)." : "What type of alien animal does \(p.id) want to be?"
            let kind = await withCheckedContinuation { cont in
                kindPick = cont
                choosingKind = p
            }
            try Task.checkCancellation()
            if !silent { try await say(p, "I want to be a \(kind.name)!", 1.8) }
            picked.append((p, kind))
        }
        return picked
    }

    // MARK: Card games at home

    /// The next outing: you pick a flying zoo trip or one of the card games, hosted at the house.
    private func outing() async throws {
        try await look(at: Stage.full)
        caption = "A flying zoo trip — or host a card game at the house?"
        let pick = await withCheckedContinuation { cont in
            outingPick = cont
            choosingOuting = true
        }
        try Task.checkCancellation()
        switch pick {
        case .trip:
            try await doItAgain()
            try await tripToVenue()
            try await comeHome()
        case .cards(let game):
            try await hostCardGame(game)
        }
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

    /// The bridge a game uses to ask you, lay cards on the table and update the scoreboard.
    private func tableHost(human: Int?) -> TableHost {
        TableHost(human: human,
                  ask: { [unowned self] p, auto in try await ask(p, auto: auto) },
                  show: { [unowned self] groups in tableGroups = groups },
                  hand: { [unowned self] cards in if human != nil { myHand = cards } },
                  notes: { [unowned self] notes in
                      guard var b = board else { return }
                      // Scoreboard rows line up with the seats.
                      for (i, n) in notes.enumerated() where b.rows.indices.contains(i) { b.rows[i].note = n }
                      board = b
                  },
                  caption: { [unowned self] text in caption = text },
                  pause: { [unowned self] seconds in try await sleep(seconds) })
    }

    /// No travel: the family hosts `game` at the house. Debbie and the girls invite passers-by from the front yard,
    /// every guest who plays goes out to the backyard cottage and is turned into an alien animal ($10 a transformation),
    /// then they all play at the house. Guests go home still animals — it dissolves in eight hours.
    private func hostCardGame(_ game: CasinoGame) async throws {
        let (debbie, hailey, molly) = (debbie, hailey, molly)
        let girls = [hailey, molly]
        let daughter = girls.randomElement()!
        let sister = girls.first { $0 !== daughter }!
        // Debbie and the daughter take two seats; guests fill the rest.
        let need = game.funSeats - 2
        let startCash = cash
        let fee = CasinoGame.transformFee
        served = []
        result = nil

        try await sceneChange {
            self.place = .house
            self.venue = nil
            self.customers = []
            self.show(self.cast)
            for (p, x) in zip(self.cast, Stage.livingX) {
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 0)
                p.seated = false
                p.place(height: 0)
            }
            self.cutNow(Stage.full)
        }
        try await look(at: Stage.shot(centerX: 530, height: 250))
        caption = "No flying zoo today — the family is hosting \(game.name) at home!"
        try await say(debbie, "No trip today, girls. Let's host a game of \(game.name) right here at our house!", 3)
        try await say(debbie, "Everybody who plays goes through the machine in the cottage first. $\(fee) a transformation!", 3)
        try await say(molly, "And we get turned into animals too, right, Mom?", 2.2)
        try await say(debbie, "You bet! It's a just-for-fun game — the whole family plays as alien animals!", 2.8)
        try await say(daughter, "Can I play too, Mom? Pleeease?", 2.2)
        try await say(debbie, "Sure, sweetie — you're in! Let's go find some players.", 2.6)

        // Out front, inviting the neighbors.
        caption = "Debbie and the girls head out to the front yard to invite people walking by."
        try await look(at: Stage.full)
        try await walkAll([(debbie, Stage.inviteX[0]), (hailey, Stage.inviteX[1]), (molly, Stage.inviteX[2])], speed: 150)
        for p in cast { p.facing = -1 }
        try await look(at: Stage.yardView)

        var players: [Person] = []
        // A girl who becomes an alien animal plays if there was a seat for her; otherwise she watches.
        var kids: [(kid: Person, mother: Person, alien: Bool, plays: Bool)] = []
        var asked = 0
        var filled = 0
        while filled < need {
            asked += 1
            // After nine no's, the tenth person says yes so there's a game.
            let mustSayYes = asked >= 10
            let waiting = players.count + kids.count
            if let (p, kid, alien, plays) = try await inviteNeighbor(game, waitSlot: waiting, filled: filled, need: need, mustSayYes: mustSayYes) {
                players.append(p)
                filled += 1 + (plays ? 1 : 0)
                if let kid { kids.append((kid, p, alien, plays)) }
            }
        }
        if filled < need {
            caption = "Debbie has asked \(asked) people — time to play with \(filled == 1 ? "one guest" : "\(filled) guests")."
            try await say(debbie, "That's enough asking — let's play!", 2.2)
        }
        let guests = players.flatMap { p in [p] + kids.filter { $0.mother === p && $0.plays }.map(\.kid) }
        let goingAnimal = players.flatMap { p in [p] + kids.filter { $0.mother === p && $0.alien }.map(\.kid) }

        // Out back to the cottage, three chairs at a time.
        try await say(debbie, players.count == 1 ? "First stop: the cottage out back!" : "First stop, everybody: the cottage out back!", 2.4)
        let presser = Bool.random() ? debbie : sister
        try await sceneChange {
            self.place = .cottage
            self.podShown = false
            let all = goingAnimal + self.cast
            self.show(all)
            for (i, p) in goingAnimal.enumerated() {
                let x = Stage.backyardWaitX[i % Stage.backyardWaitX.count]
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, 1)
                p.seated = false
                p.place(height: 0)
            }
            let helpers = self.cast.filter { $0 !== presser }
            (presser.x0, presser.x1, presser.moveDur, presser.facing) = (Stage.consoleX - 45, Stage.consoleX - 45, 0, -1)
            for (p, x) in zip(helpers, Stage.cottageStandX) { (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, -1) }
            for p in self.cast {
                p.seated = false
                p.place(height: 0)
            }
            self.cutNow(Stage.full)
        }
        if let guest = players.first {
            try await say(guest, ["A transformation machine… in your backyard?!", "Whoa! So this is the machine!", "Is this thing for real?"].randomElement()!, 2.6)
        }
        try await say(presser, presser.isKid ? "Sit down and pick any animal you want!" : "Have a seat, and pick any animal you like!", 2.4)
        var earned = 0
        for start in stride(from: 0, to: goingAnimal.count, by: 3) {
            let group = Array(goingAnimal[start..<min(start + 3, goingAnimal.count)])
            caption = group.count == 1 ? "\(group[0].id) takes a chair in the cottage." : "The machine takes three at a time — in they go!"
            try await look(at: Stage.full)
            try await walkAll(zip(group, Stage.chairX).map { ($0, $1) }, speed: 150)
            seat(group, chairs: Array(0..<group.count))
            try await strap(group)
            var riders: [(Person, AnimalKind)] = []
            for p in group {
                let kind = AnimalKind.allCases.randomElement()!
                try await say(p, ["\(kind.name), please!", "I want to be a \(kind.name)!", "Make me a \(kind.name)!"].randomElement()!, 2)
                riders.append((p, kind))
            }
            try await say(presser, presser.isKid ? "Hold still! I'm pressing the big red button!" : "Just relax! I'm pressing the glowing red button!", 2.4)
            try await runMachine(riders, presser: presser, change: Machine.customerChange,
                                 tingleLine: (group[0], "Ooh, this really tickles!"))
            try await look(at: Stage.full)
            caption = "The big mirror rolls down…"
            try await showMirror(group, caption: group.count == 1 ? "\(group[0].id) sees an alien animal looking back!"
                                                                  : "They see alien animals looking back!", seconds: 3)
            try await look(at: Stage.chairsView)
            for (p, kind) in riders {
                try await say(p, p.isKid ? ["I'm a \(kind.name)! \(kind.sound)", "Look at my animal ears!", "Best day EVER!"].randomElement()!
                                         : ["Wow! Look at me! Deal me in!", "An alien \(kind.name)! Now let's play some cards!", kind.reaction].randomElement()!, 2.2)
                served.append(PersonSpec(p, kind: kind))
            }
            // $10 a head for the transformation; moms pay for their girls.
            let amount = group.count * fee
            cash += amount
            earned += amount
            cashPop = ("+$\(amount) transformation\(group.count > 1 ? "s" : "")", .now, Stage.chairX[1])
            sound.pay()
            caption = "Debbie collects the $\(fee) transformation fee\(group.count > 1 ? " — $\(amount) for the group" : "")."
            try await say(debbie, group.count == 1 ? "That'll be $\(fee) for the transformation!" : "That's $\(fee) each for the transformations!", 2.4)
            let payer = group.first { !$0.isKid } ?? kids.first { $0.kid === group[0] }?.mother
            if let payer {
                try await say(payer, group.count == 1 && payer !== group[0] ? "Here's $\(fee) for \(group[0].id)." :
                                ["Worth every penny!", "Here you go — what a ride!", "Best ten bucks I ever spent!"].randomElement()!, 2.2)
            }
            unstrap(group)
            for p in group { p.seated = false }
            try await look(at: Stage.full)
            try await walkAll(group.enumerated().map { ($1, Stage.backyardWaitX[(start + $0) % Stage.backyardWaitX.count]) }, speed: 150)
            for p in group { p.facing = 1 }
        }

        // Once the guests are done, the family takes the chairs too (no charge for family).
        caption = "Now it's the family's turn in the cottage chairs!"
        try await say(debbie, "Our turn, girls! Everybody in a chair!", 2.2)
        try await look(at: Stage.full)
        try await walkAll(zip(cast, Stage.chairX).map { ($0, $1) }, speed: 170)
        seat(cast, chairs: [0, 1, 2])
        try await transformAgain(cast, presser: debbie, quick: true, welcome: "Pick your animals, girls — I'll hop up and press the button!")
        try await snap(cast)
        unstrap(cast)
        for p in cast { p.seated = false }
        if let guest = players.first {
            try await say(guest, "The whole family's animals too! Now THIS is a card party!", 2.6)
        }

        // Back in the house for the game. Girls who stayed human (or had no seat) watch with the sister.
        var seated = guests
        seated.insert(daughter, at: Int.random(in: 0...seated.count))
        let watching = kids.filter { !$0.plays }.map(\.kid)
        try await sceneChange {
            self.place = .house
            let inside = self.cast + players + kids.map(\.kid)
            self.show(inside)
            for (i, p) in inside.enumerated() {
                let x = Stage.tableCrowdX[i % Stage.tableCrowdX.count]
                (p.x0, p.x1, p.moveDur, p.facing) = (x, x, 0, i % 2 == 0 ? 1 : -1)
                p.seated = false
                p.place(height: 0)
            }
            self.cutNow(Stage.shot(centerX: 530, height: 260))
        }
        caption = "Everyone gathers round the card table in the living room."
        if !watching.isEmpty {
            try await say(sister, "\(ListFormatter.localizedString(byJoining: watching.map(\.id))), come watch with me!", 2.2)
        }
        you = daughter.id
        caption = "You're \(daughter.id). Your cards show up along the bottom of the table."
        try await say(debbie, "No buy-in — this one's just for fun! The winner gets bragging rights.", 2.8)

        let mySeat = seated.firstIndex { $0 === daughter }
        let table = [debbie] + seated
        let (scores, hands) = try await playFun(game, table, human: mySeat.map { $0 + 1 })
        let won = Tricks.winners(game, scores: scores, hands: hands) ?? [scores.indices.max { scores[$0] < scores[$1] }!]
        let winners = won.map { table[$0].id }
        caption = "\(winners.joined(separator: " & ")) win\(won.count == 1 ? "s" : "") the game!"
        sound.chime()
        if let star = won.map({ table[$0] }).first(where: { $0 === debbie || $0 === daughter }) {
            try await say(star, star === debbie ? (won.count == 1 ? "Debbie wins! Ha!" : "We did it, partner!") : "I WON! I won, Mom!", 2.2)
        } else {
            try await say(table[won[0]], ["Woo-hoo! I win!", "Ha! Beat you all!", "Best game ever!"].randomElement()!, 2.2)
            try await say(debbie, "Well played!", 1.8)
        }
        board = nil
        tableSeats = []
        tableGroups = []
        you = nil
        myHand = []
        humanRow = nil
        prompt = nil

        // The guests head home out the front door, still alien animals.
        try await look(at: Stage.full)
        if let p = players.randomElement() {
            try await say(p, ["Thanks for the game! I love being an alien animal!", "What a fun night! See you next time!",
                              "Best card party on the whole street!"].randomElement()!, 2.6)
        }
        try await say(debbie, "Thanks for coming! It dissolves in eight hours!", 2.4)
        shout(girls, "Bye!", 1.4)
        caption = "Out the front door they go — still alien animals!"
        let leaving = players + kids.map(\.kid)
        try await walkAll(leaving.enumerated().map { ($1, -60 - Double($0) * 35) }, speed: 140)
        customers = []

        // The family's change wears off once the guests have gone, over five minutes (sped up).
        try await gatherAtButton(cast)
        clockT0 = .now
        clockDur = 13.5
        clockLabel = "Five minutes later…"
        clockSpan = 300
        caption = "With the guests gone, the family's transformation slowly dissolves…"
        for p in cast { p.fade(to: 0, over: 12.9) }
        sound.shimmer()
        try await sleep(4)
        mention(molly, "My animal ears are shrinking!", 3)
        try await sleep(4.5)
        mention(debbie, "Our fur is melting away…", 3)
        try await sleep(5)
        sound.shimmer()
        caption = "Everyone is back to normal!"
        try await say(hailey, "We're us again!", 2)

        let record = EventRecord(date: .now, venue: .belmar, asked: asked, customers: served, fee: 0, earned: earned,
                                 startCash: startCash, endCash: cash, cardGame: game)
        album.add(record)
        result = record
        cardGames += 1
        totalProfit += record.profit
        totalTransformed += served.count

        try await gatherAtButton(cast)
        try await say(debbie, "\(served.count) alien \(served.count == 1 ? "animal" : "animals") at $\(fee) each — that's $\(earned) without leaving the house!", 3)
        if !winners.isEmpty {
            try await say(molly, "\(winners.joined(separator: " and ")) won the \(game.name)!", 2.2)
        }
        caption = "The \(game.name) game is saved in the album."
    }

    /// A passer-by on the sidewalk, sometimes with her daughter. Returns her, the girl, whether the girl becomes an animal,
    /// and whether the girl gets a seat, or nil if they walk on.
    private func inviteNeighbor(_ game: CasinoGame, waitSlot: Int, filled: Int, need: Int, mustSayYes: Bool) async throws -> (Person, Person?, Bool, Bool)? {
        let (debbie, hailey, molly) = (debbie, hailey, molly)
        if guestWomen.isEmpty {
            guestWomen = ["Angela", "Bonnie", "Brenda", "Carol", "Cheryl", "Denise", "Diane", "Donna", "Ellen", "Fran", "Gina", "Holly",
                          "Iris", "Joyce", "Karen", "Lena", "Linda", "Maria", "Nancy", "Olivia", "Paula", "Peggy", "Rachel", "Rita",
                          "Sandy", "Terri", "Tina", "Val", "Wendy", "Yolanda"].shuffled()
        }
        if guestKids.isEmpty {
            guestKids = ["Abby", "Bella", "Chloe", "Daisy", "Ellie", "Gracie", "Ivy", "Josie", "Katie", "Lily", "Maddie",
                         "Nora", "Piper", "Ruby", "Sophie", "Tessa", "Zoe"].shuffled()
        }
        let p = Person.customer(guestWomen.popLast()!, kid: false, x: -80)
        let kid = Double.random(in: 0...1) < 0.35 ? Person.customer(guestKids.popLast()!, kid: true, x: -115) : nil
        customers.append(p)
        if let kid { customers.append(kid) }
        let stroll = 85.0
        _ = beginWalk(p, to: Stage.inviteStopX[0], speed: stroll)
        if let kid { _ = beginWalk(kid, to: Stage.inviteStopX[1], speed: stroll) }
        caption = "\(p.id) comes strolling down the sidewalk\(kid.map { " with her daughter \($0.id)" } ?? "")."
        try await sleep((Stage.inviteStopX[0] + 80) / stroll + 0.2)
        p.facing = 1
        kid?.facing = 1
        debbie.facing = -1

        try await say(debbie, "Hi! Want to come in and play \(game.name) with us? It's just for fun!", 2.8)
        try await say(hailey, "Everybody who plays gets turned into an alien animal first — just $\(CasinoGame.transformFee)!", 2.6)
        guard mustSayYes || Double.random(in: 0...1) < 0.55 else {
            try await say(p, ["No thanks, I'm not much for cards.", "Not today, sorry!", "An alien animal? No way!",
                              "I'm just out walking the dog, thanks!", "Maybe another time."].randomElement()!, 2.4)
            caption = "\(p.id) keeps walking."
            p.facing = -1
            kid?.facing = -1
            _ = beginWalk(p, to: -150, speed: stroll)
            if let kid { _ = beginWalk(kid, to: -150, speed: stroll) }
            try await sleep(1.2)
            Task { [weak self] in
                try? await Task.sleep(for: .seconds((Stage.inviteStopX[0] + 150) / stroll))
                self?.customers.removeAll { $0 === p || $0 === kid }
            }
            return nil
        }
        try await say(p, ["Ooh, I love \(game.name)! Count me in!", "An alien animal AND cards? I'm in!", "Deal me in!",
                          "I haven't played \(game.name) in ages — I'm in!", "Sounds like fun! I'm in!"].randomElement()!, 2.6)
        var alien = false
        let roomForHer = need - filled >= 2
        if let kid {
            molly.facing = -1
            try await say(molly, roomForHer ? "Hi \(kid.id)! Want to be an alien animal and play too?"
                                            : "Hi \(kid.id)! The table's full — but you can be an alien animal and watch with us! Want to?", 2.8)
            if Double.random(in: 0...1) < 0.65 {
                try await say(kid, ["Yes! Can I, Mommy? Please?", "Ooh, yes! I want to be a tiger!", "Yay! Me too!"].randomElement()!, 2.4)
                try await say(p, "If you really want to, sweetie — sure!", 2.4)
                alien = true
            } else {
                try await say(kid, ["No thanks, I'm shy.", "Nope! I'll just watch.", "Maybe when I'm bigger."].randomElement()!, 2.4)
                try await say(p, "That's okay, honey. You can watch the game with the girls.", 2.6)
            }
        }
        let plays = alien && roomForHer
        let left = need - filled - 1 - (plays ? 1 : 0)
        let who = plays ? "\(p.id) and \(kid!.id) join" : kid != nil ? "\(p.id) joins, and \(kid!.id) will watch" : "\(p.id) joins"
        caption = left <= 0 ? "\(who) — that's a full table!" : "\(who)! \(left) more spot\(left == 1 ? "" : "s") to fill."
        try await say(debbie, kid == nil ? "Great! Go on in — make yourself at home!" : "Great! Go on in, you two — make yourselves at home!", 2.4)
        // Into the living room to wait.
        let walkers = [p] + (kid.map { [$0] } ?? [])
        for (i, w) in walkers.enumerated() { _ = beginWalk(w, to: Stage.guestWaitX[(waitSlot + i) % Stage.guestWaitX.count], speed: 130) }
        try await sleep(1.6)
        return (p, kid, alien, plays)
    }

    /// Deals hand after hand until someone reaches the target. You play `human`'s seat. Returns the final scores and hands dealt.
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
                           rows: rows())
        if game.isPartners {
            caption = "Partners: \(names[0]) & \(names[2]) vs. \(names[1]) & \(names[3])."
            try await sleep(2.4)
        }
        let seats = tableHost(human: human)
        var hand = 0
        var dealer = Int.random(in: 0..<names.count)
        while Tricks.winners(game, scores: scores, hands: hand) == nil && hand < 30 {
            board?.status = "Hand \(hand + 1) · \(names[dealer]) deals · " + (game == .hearts ? "ends at \(game.target)" : game == .diamonds ? "of \(game.target)" : "to \(game.target)")
            caption = "Hand \(hand + 1): \(names[dealer]) deals."
            sound.beep()
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

    // MARK: Helpers

    /// `p` shakes on the spot with fear for `seconds`.
    private func tremble(_ p: Person, for seconds: Double) async throws {
        let x = p.x(at: .now)
        let end = Date.now + seconds
        var side = 1.0
        while Date.now < end {
            (p.x0, p.x1, p.moveDur) = (x + side * 2.5, x + side * 2.5, 0)
            side = -side
            try await sleep(0.05)
        }
        (p.x0, p.x1, p.moveDur) = (x, x, 0)
    }

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
