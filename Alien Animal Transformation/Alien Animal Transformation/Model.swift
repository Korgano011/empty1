import SwiftUI

struct RGB: Codable, Hashable {
    var r, g, b: Double

    var color: Color { Color(red: r, green: g, blue: b) }

    func mixed(with o: RGB, _ t: Double) -> RGB {
        let t = min(max(t, 0), 1)
        return RGB(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t)
    }

    func scaled(_ k: Double) -> RGB { RGB(r: r * k, g: g * k, b: b * k) }
}

enum HairStyle: String, Codable, CaseIterable {
    case long, waist, ponytail, bun, short, curly, pigtails, bob
}

/// What someone is carrying in front of her.
enum Load { case box, groceries, shopping, suitcase }

/// Something to park in the driveway, bought out of the savings in the bank.
enum Vehicle: String, CaseIterable, Identifiable {
    case scooter, motorcycle, car

    var id: Self { self }

    var name: String {
        switch self {
        case .scooter: "Scooter"
        case .motorcycle: "Motorcycle"
        case .car: "Car"
        }
    }

    var emoji: String {
        switch self {
        case .scooter: "🛵"
        case .motorcycle: "🏍️"
        case .car: "🚗"
        }
    }

    var price: Int {
        switch self {
        case .scooter: 1000
        case .motorcycle: 2500
        case .car: 5000
        }
    }

    var tint: Color {
        switch self {
        case .scooter: Color(red: 0.20, green: 0.65, blue: 0.58)
        case .motorcycle: Color(red: 0.15, green: 0.20, blue: 0.30)
        case .car: Color(red: 0.85, green: 0.16, blue: 0.20)
        }
    }
}

enum Mood { case happy, shocked, beaming }

/// What is on an alien animal's fur or hide.
enum AnimalPattern { case plain, tigerStripes, zebraStripes, armorBands, wrinkles, shaggy, scales, diamonds }

/// Ears on top (or at the sides) of the head.
enum AnimalEars { case small, round, pig, pointy, tiny, elephant, tall, armadillo, none }

/// The nose and mouth end of the face.
enum AnimalSnout { case ape, cat, pig, rhino, hippo, trunk, tube, pointy, horse, jaws, serpent }

enum AnimalTail { case none, tuft, curly, striped, thin, thick, banded, long, gator, serpent }

/// What her hands and feet turn into.
enum AnimalFeet { case hands, paws, trotters, hooves, pads, claws, scaly }

/// The overall shape of an alien animal's head.
enum AnimalHead { case round, wide, long }

/// The fourteen types of alien animal the machine can make.
enum AnimalKind: String, Codable, CaseIterable, Identifiable {
    case gorilla, lion, pig, tiger, rhinoceros, hippopotamus, elephant, aardvark, armadillo, zebra, horse, donkey, alligator, snake

    var id: Self { self }

    /// Anything unknown (an old insectoid photo) opens as a gorilla.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = AnimalKind(rawValue: raw) ?? .gorilla
    }

    var name: String { rawValue.capitalized }

    var blurb: String {
        switch self {
        case .gorilla: "Black fur, big strong hands"
        case .lion: "Golden fur, a big mane"
        case .pig: "Pink, curly tail, snout"
        case .tiger: "Orange with black stripes"
        case .rhinoceros: "Grey hide, two horns"
        case .hippopotamus: "Big pink muzzle"
        case .elephant: "Trunk, tusks, huge ears"
        case .aardvark: "Long snout, tall ears"
        case .armadillo: "Armor-banded shell"
        case .zebra: "Black & white stripes"
        case .horse: "Chestnut coat, flowing mane"
        case .donkey: "Grey, long ears, hee-haw"
        case .alligator: "Green scales, toothy jaws"
        case .snake: "Diamond scales, forked tongue"
        }
    }

    /// The main fur or hide.
    var fur: RGB {
        switch self {
        case .gorilla: RGB(r: 0.22, g: 0.22, b: 0.24)
        case .lion: RGB(r: 0.88, g: 0.68, b: 0.36)
        case .pig: RGB(r: 1.00, g: 0.72, b: 0.77)
        case .tiger: RGB(r: 0.96, g: 0.56, b: 0.14)
        case .rhinoceros: RGB(r: 0.60, g: 0.60, b: 0.62)
        case .hippopotamus: RGB(r: 0.58, g: 0.52, b: 0.64)
        case .elephant: RGB(r: 0.64, g: 0.66, b: 0.70)
        case .aardvark: RGB(r: 0.80, g: 0.63, b: 0.53)
        case .armadillo: RGB(r: 0.74, g: 0.63, b: 0.50)
        case .zebra: RGB(r: 0.98, g: 0.98, b: 0.97)
        case .horse: RGB(r: 0.64, g: 0.37, b: 0.18)
        case .donkey: RGB(r: 0.60, g: 0.58, b: 0.58)
        case .alligator: RGB(r: 0.30, g: 0.46, b: 0.22)
        case .snake: RGB(r: 0.74, g: 0.66, b: 0.24)
        }
    }

    /// Stripes, mane, hooves, claws and outlines.
    var dark: RGB {
        switch self {
        case .gorilla: RGB(r: 0.10, g: 0.10, b: 0.11)
        case .lion: RGB(r: 0.60, g: 0.34, b: 0.12)
        case .pig: RGB(r: 0.86, g: 0.48, b: 0.56)
        case .tiger: RGB(r: 0.12, g: 0.08, b: 0.06)
        case .rhinoceros: RGB(r: 0.38, g: 0.38, b: 0.40)
        case .hippopotamus: RGB(r: 0.38, g: 0.33, b: 0.45)
        case .elephant: RGB(r: 0.42, g: 0.44, b: 0.48)
        case .aardvark: RGB(r: 0.52, g: 0.36, b: 0.28)
        case .armadillo: RGB(r: 0.48, g: 0.38, b: 0.28)
        case .zebra: RGB(r: 0.08, g: 0.08, b: 0.08)
        case .horse: RGB(r: 0.30, g: 0.16, b: 0.08)
        case .donkey: RGB(r: 0.32, g: 0.30, b: 0.30)
        case .alligator: RGB(r: 0.14, g: 0.24, b: 0.10)
        case .snake: RGB(r: 0.30, g: 0.22, b: 0.08)
        }
    }

    /// Muzzle, belly and inner ears.
    var light: RGB {
        switch self {
        case .gorilla: RGB(r: 0.42, g: 0.40, b: 0.42)
        case .lion: RGB(r: 0.99, g: 0.91, b: 0.74)
        case .pig: RGB(r: 1.00, g: 0.84, b: 0.86)
        case .tiger: RGB(r: 1.00, g: 0.98, b: 0.94)
        case .rhinoceros: RGB(r: 0.72, g: 0.72, b: 0.74)
        case .hippopotamus: RGB(r: 0.98, g: 0.70, b: 0.72)
        case .elephant: RGB(r: 0.96, g: 0.74, b: 0.78)
        case .aardvark: RGB(r: 1.00, g: 0.76, b: 0.76)
        case .armadillo: RGB(r: 0.96, g: 0.84, b: 0.74)
        case .zebra: RGB(r: 0.28, g: 0.28, b: 0.28)
        case .horse: RGB(r: 0.46, g: 0.28, b: 0.17)
        case .donkey: RGB(r: 0.95, g: 0.93, b: 0.91)
        case .alligator: RGB(r: 0.88, g: 0.86, b: 0.62)
        case .snake: RGB(r: 0.96, g: 0.90, b: 0.60)
        }
    }

    var eye: RGB {
        switch self {
        case .lion: RGB(r: 0.85, g: 0.60, b: 0.10)
        case .tiger: RGB(r: 0.55, g: 0.80, b: 0.25)
        case .pig: RGB(r: 0.35, g: 0.55, b: 0.85)
        case .alligator: RGB(r: 0.86, g: 0.78, b: 0.16)
        case .snake: RGB(r: 0.96, g: 0.56, b: 0.10)
        default: RGB(r: 0.36, g: 0.22, b: 0.10)
        }
    }

    var pattern: AnimalPattern {
        switch self {
        case .tiger: .tigerStripes
        case .zebra: .zebraStripes
        case .armadillo: .armorBands
        case .rhinoceros, .elephant, .hippopotamus: .wrinkles
        case .gorilla: .shaggy
        case .alligator: .scales
        case .snake: .diamonds
        default: .plain
        }
    }

    var ears: AnimalEars {
        switch self {
        case .gorilla: .small
        case .lion, .tiger: .round
        case .pig: .pig
        case .rhinoceros, .zebra, .horse: .pointy
        case .hippopotamus: .tiny
        case .elephant: .elephant
        case .aardvark, .donkey: .tall
        case .armadillo: .armadillo
        case .alligator, .snake: .none
        }
    }

    var snout: AnimalSnout {
        switch self {
        case .gorilla: .ape
        case .lion, .tiger: .cat
        case .pig: .pig
        case .rhinoceros: .rhino
        case .hippopotamus: .hippo
        case .elephant: .trunk
        case .aardvark: .tube
        case .armadillo: .pointy
        case .zebra, .horse, .donkey: .horse
        case .alligator: .jaws
        case .snake: .serpent
        }
    }

    var tail: AnimalTail {
        switch self {
        case .gorilla: .none
        case .lion, .zebra, .donkey: .tuft
        case .horse: .long
        case .pig: .curly
        case .tiger: .striped
        case .rhinoceros, .hippopotamus, .elephant: .thin
        case .aardvark: .thick
        case .armadillo: .banded
        case .alligator: .gator
        case .snake: .serpent
        }
    }

    var feet: AnimalFeet {
        switch self {
        case .gorilla: .hands
        case .lion, .tiger: .paws
        case .pig: .trotters
        case .zebra, .horse, .donkey: .hooves
        case .rhinoceros, .hippopotamus, .elephant: .pads
        case .aardvark, .armadillo, .alligator: .claws
        case .snake: .scaly
        }
    }

    var head: AnimalHead {
        switch self {
        case .rhinoceros, .hippopotamus, .gorilla, .snake: .wide
        case .zebra, .aardvark, .elephant, .horse, .donkey, .alligator: .long
        default: .round
        }
    }

    /// How much wider than her own body the furry body grows.
    var bulk: Double {
        switch self {
        case .gorilla, .hippopotamus, .elephant: 1.55
        case .rhinoceros, .pig: 1.4
        case .lion, .tiger, .horse, .alligator: 1.25
        default: 1.18
        }
    }

    /// A pale belly patch down the front.
    var belly: Bool { [.lion, .tiger, .pig, .hippopotamus, .aardvark, .gorilla, .donkey, .alligator, .snake].contains(self) }

    /// Cats and reptiles have narrow slit pupils.
    var slitEyes: Bool { [.lion, .tiger, .alligator, .snake].contains(self) }

    /// Mane and tail hair, for the horse family.
    var mane: RGB? {
        switch self {
        case .horse: RGB(r: 0.22, g: 0.11, b: 0.05)
        case .donkey: RGB(r: 0.24, g: 0.22, b: 0.22)
        case .zebra: dark
        default: nil
        }
    }

    /// The colour that stands for this type on buttons and photo frames.
    var color: Color { (self == .zebra ? dark : fur).color }

    /// What she says when she sees herself.
    var reaction: String {
        switch self {
        case .gorilla: "Gorilla! Look at these big strong arms!"
        case .lion: "Lion! Check out my mane — ROAR!"
        case .pig: "Pig! A curly tail and a cute pink snout — oink!"
        case .tiger: "Tiger! Orange with black stripes — grrr!"
        case .rhinoceros: "Rhinoceros! I've got two horns!"
        case .hippopotamus: "Hippopotamus! What a big happy smile!"
        case .elephant: "Elephant! A trunk, tusks and giant ears!"
        case .aardvark: "Aardvark! This snout goes on forever!"
        case .armadillo: "Armadillo! I'm wearing my own armor!"
        case .zebra: "Zebra! Black and white stripes everywhere!"
        case .horse: "Horse! Look at my flowing mane and tail!"
        case .donkey: "Donkey! These ears are so long — hee-haw!"
        case .alligator: "Alligator! Look at all these teeth — snap snap!"
        case .snake: "Snake! Ssscales and a forked tongue — sss!"
        }
    }

    /// The sound she makes, for kids' happy lines.
    var sound: String {
        switch self {
        case .gorilla: "Ooh-ooh-ah-ah!"
        case .lion: "ROAR!"
        case .pig: "Oink oink!"
        case .tiger: "Grrr!"
        case .rhinoceros: "Snort snort!"
        case .hippopotamus: "Grunt grunt!"
        case .elephant: "Pawoo-oo!"
        case .aardvark: "Sniff sniff!"
        case .armadillo: "Roll roll!"
        case .zebra: "Neigh-hee-hee!"
        case .horse: "Neigh!"
        case .donkey: "Hee-haw!"
        case .alligator: "Snap snap!"
        case .snake: "Hissss!"
        }
    }
}

/// How far someone's legs, body and head have turned alien animal, 0…1 each.
struct AnimalLevels {
    var head, body, legs: Double

    static let none = AnimalLevels(head: 0, body: 0, legs: 0)
    static let full = AnimalLevels(head: 1, body: 1, legs: 1)

    /// The change starts at the feet and works its way up to the face;
    /// `strength` is how much of it is left (1 fresh, 0 back to normal).
    init(progress u: Double, strength s: Double) {
        func band(_ a: Double, _ b: Double) -> Double { min(max((u - a) / (b - a), 0), 1) * s }
        self.init(head: band(0.42, 1), body: band(0.2, 0.48), legs: band(0, 0.26))
    }

    init(head: Double, body: Double, legs: Double) {
        self.head = head
        self.body = body
        self.legs = legs
    }
}

/// One run of the transformation machine, in seconds from the red button being pressed.
enum Machine {
    /// "This really tickles."
    static let tingle = 5.0
    /// The machine's five minutes, sped up so nobody waits five real minutes.
    static let change = 34.0
    /// Customers get a slightly quicker show.
    static let customerChange = 22.0
}

final class Person: Identifiable {
    let id: String
    let height: Double
    let headScale: Double
    let skin: RGB
    let hair: RGB
    var style: HairStyle
    var shirt: RGB
    var pants: RGB
    let isKid: Bool
    /// Wears shorts instead of long pants.
    var shorts: Bool
    /// Wears a two-piece swimsuit (in her shirt colour) instead of a shirt and pants.
    var bikini = false
    let female: Bool
    /// One of the flying zoo's alien animals rather than a person.
    let crew: Bool

    var visible = true
    var x0: Double
    var x1: Double
    var moveT0 = Date.distantPast
    var moveDur = 0.0
    var facing = 1.0

    /// Height above the ground: the beam lifts people up into the zoo and sets them back down.
    private var y0 = 0.0
    private var y1 = 0.0
    private var riseT0 = Date.distantPast
    private var riseDur = 0.0

    var mood = Mood.happy
    var says: String?
    var saysUntil = Date.distantPast
    /// What she is carrying in front of her, if anything.
    var load: Load?
    /// A peaked cap: Debbie's for driving the cab, or the airport police officer's.
    var driverCap = false
    /// Sitting in one of the zoo's chairs.
    var seated = false
    /// Where her hand is reaching, e.g. the glowing red button.
    var reachTo: CGPoint?
    /// Both hands up, feeling her new animal ears.
    var feelsHead = false

    /// The type of alien animal she is turning (or has turned) into.
    var animal: AnimalKind?
    var tingleT0 = Date.distantFuture
    var changeT0 = Date.distantFuture
    var changeDur = 1.0
    /// When the finished change first twinkled.
    var shineT0 = Date.distantPast
    /// Speech-bubble font size; it goes up as she shouts louder.
    var voice = 15.0

    private var fadeFrom = 1.0
    private var fadeTo = 1.0
    private var fadeT0 = Date.distantPast
    private var fadeDur = 0.0

    init(_ id: String, height: Double, headScale: Double = 0.12, skin: RGB, hair: RGB, style: HairStyle,
         shirt: RGB, pants: RGB, kid: Bool = false, shorts: Bool = true, female: Bool = true, crew: Bool = false, x: Double) {
        self.id = id
        self.height = height
        self.headScale = headScale
        self.skin = skin
        self.hair = hair
        self.style = style
        self.shirt = shirt
        self.pants = pants
        isKid = kid
        self.shorts = shorts
        self.female = female
        self.crew = crew
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

    func rise(at now: Date) -> Double {
        let t = now.timeIntervalSince(riseT0)
        if t >= riseDur { return y1 }
        if t <= 0 { return y0 }
        let u = t / riseDur
        return y0 + (y1 - y0) * u * u * (3 - 2 * u)
    }

    /// Floats up (or down) to `height` above the ground over `seconds`.
    func float(to height: Double, over seconds: Double) {
        let now = Date.now
        y0 = rise(at: now)
        y1 = height
        riseT0 = now
        riseDur = seconds
    }

    /// Puts her at a height straight away.
    func place(height: Double) {
        (y0, y1, riseDur) = (height, height, 0)
    }

    /// 0 = still human, 1 = alien animal from toes to face.
    func progress(at now: Date) -> Double {
        if crew { return 1 }
        guard animal != nil else { return 0 }
        return min(max(now.timeIntervalSince(changeT0) / changeDur, 0), 1)
    }

    /// True while the tingling has started but the change hasn't finished.
    func isTingling(at now: Date) -> Bool {
        animal != nil && now >= tingleT0 && progress(at: now) < 1
    }

    func strength(at now: Date) -> Double {
        if crew { return 1 }
        let t = now.timeIntervalSince(fadeT0)
        if t >= fadeDur { return fadeTo }
        if t <= 0 { return fadeFrom }
        return fadeFrom + (fadeTo - fadeFrom) * t / fadeDur
    }

    /// Eases the transformation to `level` (0…1) over `seconds`.
    func fade(to level: Double, over seconds: Double) {
        let now = Date.now
        fadeFrom = strength(at: now)
        fadeTo = level
        fadeT0 = now
        fadeDur = seconds
    }

    func animalLevels(at now: Date) -> AnimalLevels {
        if crew { return .full }
        guard animal != nil else { return .none }
        return AnimalLevels(progress: progress(at: now), strength: strength(at: now))
    }
}

extension Person {
    private static let skins = [RGB(r: 0.99, g: 0.86, b: 0.76), RGB(r: 0.96, g: 0.80, b: 0.68), RGB(r: 0.85, g: 0.65, b: 0.50),
                                RGB(r: 0.72, g: 0.52, b: 0.38), RGB(r: 0.55, g: 0.38, b: 0.26), RGB(r: 0.42, g: 0.28, b: 0.20)]
    private static let hairs = [RGB(r: 0.20, g: 0.12, b: 0.08), RGB(r: 0.45, g: 0.28, b: 0.14), RGB(r: 0.92, g: 0.78, b: 0.42),
                                RGB(r: 0.75, g: 0.32, b: 0.14), RGB(r: 0.10, g: 0.10, b: 0.10), RGB(r: 0.70, g: 0.70, b: 0.72)]
    private static let colors = [RGB(r: 0.90, g: 0.30, b: 0.30), RGB(r: 0.25, g: 0.55, b: 0.85), RGB(r: 0.30, g: 0.70, b: 0.40),
                                 RGB(r: 0.95, g: 0.75, b: 0.20), RGB(r: 0.60, g: 0.40, b: 0.80), RGB(r: 0.95, g: 0.50, b: 0.70),
                                 RGB(r: 0.20, g: 0.65, b: 0.65), RGB(r: 0.95, g: 0.55, b: 0.15), RGB(r: 0.35, g: 0.35, b: 0.45)]

    /// Mostly light skin: three in four passers-by get one of the three lightest tones.
    private static func randomSkin() -> RGB {
        Double.random(in: 0...1) < 0.75 ? skins[..<3].randomElement()! : skins[3...].randomElement()!
    }

    /// A random passer-by: a kid, a mother, or any grown-up.
    static func customer(_ name: String, kid: Bool, female: Bool = true, x: Double) -> Person {
        let styles: [HairStyle] = kid ? [.pigtails, .ponytail, .short, .curly, .bob]
            : female ? [.long, .ponytail, .bun, .bob, .curly] : [.short, .curly]
        // More than half of the girls who stroll by have long hair.
        let style = kid && Double.random(in: 0...1) < 0.55 ? .long : styles.randomElement()!
        let p = Person(name, height: kid ? .random(in: 92...118) : .random(in: 140...166), headScale: kid ? 0.155 : 0.12,
                       skin: randomSkin(), hair: hairs.randomElement()!, style: style,
                       shirt: colors.randomElement()!, pants: colors.randomElement()!, kid: kid, female: female, x: x)
        // Half of the grown women come along in a bikini.
        p.bikini = !kid && female && Bool.random()
        return p
    }

    /// One of the flying zoo's alien animals.
    static func alienAnimal(_ name: String, kind: AnimalKind, height: Double, x: Double) -> Person {
        let p = Person(name, height: height, headScale: 0.125, skin: kind.fur, hair: kind.dark, style: .short,
                       shirt: kind.fur, pants: kind.dark, shorts: false, female: false, crew: true, x: x)
        p.animal = kind
        return p
    }
}

/// Where the flying zoo takes them to transform customers.
enum Venue: String, Codable, CaseIterable, Identifiable {
    case belmar, disneyWorld, disneyland, sesamePlace, cozumel, waikiki, longBranch, atlanticCity, myrtleBeach, crystalCoast

    var id: Self { self }

    /// Albums saved before the venues changed still open: each old venue becomes the one that replaced it.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        let renamed = ["wildwood": "belmar", "lasVegas": "disneyWorld", "nassau": "disneyland", "bimini": "sesamePlace", "cocoCay": "cozumel",
                       "catalina": "waikiki", "stKitts": "longBranch", "pisa": "atlanticCity", "paris": "myrtleBeach", "laBufadora": "crystalCoast"]
        self = Venue(rawValue: renamed[raw] ?? raw) ?? .belmar
    }

    var name: String {
        switch self {
        case .belmar: "Belmar, NJ"
        case .disneyWorld: "Disney World"
        case .disneyland: "Disneyland"
        case .sesamePlace: "Sesame Place"
        case .cozumel: "Cozumel, Mexico"
        case .waikiki: "Waikiki, Hawaii"
        case .longBranch: "Long Branch, NJ"
        case .atlanticCity: "Atlantic City, NJ"
        case .myrtleBeach: "Myrtle Beach, SC"
        case .crystalCoast: "The Crystal Coast, NC"
        }
    }

    var shortName: String {
        switch self {
        case .belmar: "Belmar"
        case .cozumel: "Cozumel"
        case .waikiki: "Waikiki"
        case .longBranch: "Long Branch"
        case .atlanticCity: "Atlantic City"
        case .myrtleBeach: "Myrtle Beach"
        case .crystalCoast: "Crystal Coast"
        default: name
        }
    }

    /// For captions: "off to Disney World", "off to the boardwalk in Atlantic City".
    var theName: String {
        switch self {
        case .belmar: "the beach in Belmar, New Jersey"
        case .disneyWorld: "Disney World in Orlando"
        case .disneyland: "Disneyland in California"
        case .sesamePlace: "Sesame Place"
        case .cozumel: "Cozumel, Mexico"
        case .waikiki: "Waikiki Beach in Hawaii"
        case .longBranch: "Pier Village in Long Branch, New Jersey"
        case .atlanticCity: "the boardwalk in Atlantic City"
        case .myrtleBeach: "the boardwalk in Myrtle Beach"
        case .crystalCoast: "the Crystal Coast of North Carolina"
        }
    }

    var blurb: String {
        switch self {
        case .belmar: "Beachgoers by the lifeguard stands"
        case .disneyWorld: "Families in front of the castle"
        case .disneyland: "Crowds by the pink castle"
        case .sesamePlace: "Kids by the water slides"
        case .cozumel: "Cruise passengers ashore"
        case .waikiki: "Surfers below Diamond Head"
        case .longBranch: "Strollers at Pier Village"
        case .atlanticCity: "Boardwalk crowds by the casinos"
        case .myrtleBeach: "Vacationers under the SkyWheel"
        case .crystalCoast: "Beachcombers by the lighthouse"
        }
    }

    var icon: String {
        switch self {
        case .belmar: "beach.umbrella.fill"
        case .disneyWorld: "sparkles"
        case .disneyland: "wand.and.stars"
        case .sesamePlace: "figure.water.fitness"
        case .cozumel: "ferry.fill"
        case .waikiki: "figure.surfing"
        case .longBranch: "building.2.fill"
        case .atlanticCity: "dice.fill"
        case .myrtleBeach: "circle.dotted"
        case .crystalCoast: "light.beacon.max.fill"
        }
    }

    var groups: Int { 6 }
    /// What it costs to set up there.
    var fee: Int {
        switch self {
        case .belmar: 40
        case .disneyWorld: 150
        case .disneyland: 140
        case .sesamePlace: 90
        case .cozumel: 120
        case .waikiki: 110
        case .longBranch: 50
        case .atlanticCity: 60
        case .myrtleBeach: 70
        case .crystalCoast: 100
        }
    }
    var price: Int {
        switch self {
        case .belmar: 20
        case .disneyWorld: 50
        case .disneyland: 46
        case .sesamePlace: 32
        case .cozumel: 40
        case .waikiki: 38
        case .longBranch: 22
        case .atlanticCity: 26
        case .myrtleBeach: 28
        case .crystalCoast: 36
        }
    }
    var kidPrice: Int { price / 2 }

    static let startCash = 250
    static var cheapestFee: Int { allCases.map(\.fee).min()! }

    /// Chance a passer-by is a kid out with their mother (rather than a grown-up on their own).
    var kidChance: Double {
        switch self {
        case .disneyWorld, .disneyland, .sesamePlace: 0.7
        case .belmar, .myrtleBeach, .cozumel: 0.6
        case .atlanticCity: 0.25
        default: 0.45
        }
    }
    var kidYes: Double { 0.8 }
    var adultYes: Double {
        switch self {
        case .atlanticCity: 0.75
        default: 0.7
        }
    }
    /// A mother is more likely to join in if her kid just said yes.
    var momYes: Double { 0.6 }
}
