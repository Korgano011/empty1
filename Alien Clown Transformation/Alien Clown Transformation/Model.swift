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
    /// Clipped down to stubble, and then shaved smooth.
    case buzzed, bald
    /// A hair treatment left on far too long.
    case frizzy
}

/// What Deidre has in her hand at the styling station.
enum SalonTool {
    case clippers, cream, razor
}

/// Extras from the accessory store in town; whoever buys one wears it from then on.
enum Accessory: String, CaseIterable, Identifiable {
    case flower, scarf, sunglasses, sunHat, necklace, handbag

    var id: Self { self }

    var name: String {
        switch self {
        case .flower: "Hair Flower"
        case .scarf: "Silk Scarf"
        case .sunglasses: "Sunglasses"
        case .sunHat: "Sun Hat"
        case .necklace: "Necklace"
        case .handbag: "Handbag"
        }
    }

    /// For captions: "buys a silk scarf".
    var phrase: String {
        switch self {
        case .flower: "a flower for her hair"
        case .scarf: "a silk scarf"
        case .sunglasses: "a pair of sunglasses"
        case .sunHat: "a sun hat"
        case .necklace: "a necklace"
        case .handbag: "a handbag"
        }
    }

    var emoji: String {
        switch self {
        case .flower: "🌸"
        case .scarf: "🧣"
        case .sunglasses: "🕶️"
        case .sunHat: "👒"
        case .necklace: "📿"
        case .handbag: "👜"
        }
    }

    var price: Int {
        switch self {
        case .flower: 10
        case .scarf: 15
        case .sunglasses: 20
        case .sunHat: 25
        case .necklace: 30
        case .handbag: 40
        }
    }
}

/// Something to park in the driveway, bought out of the savings in the bank.
enum Vehicle: String, CaseIterable, Identifiable {
    case scooter, car

    var id: Self { self }

    var name: String {
        switch self {
        case .scooter: "Scooter"
        case .car: "Car"
        }
    }

    var emoji: String {
        switch self {
        case .scooter: "🛵"
        case .car: "🚗"
        }
    }

    var price: Int {
        switch self {
        case .scooter: 1500
        case .car: 6000
        }
    }
}

enum Mood { case happy, shocked, crying, beaming }

/// How an alien clown wears its hair.
enum ClownHair {
    /// Two big puffs over the ears and a bald top.
    case tufts
    /// One huge fuzzy puff on top.
    case puff
    /// A tall fin down the middle.
    case mohawk
    /// A fan of spikes.
    case spikes
    /// Side puffs with a big bow on top.
    case bow
    /// A single flame of hair.
    case topknot
    /// A full head of curly hair in many colors, all the way round.
    case mop
}

/// What is printed on an alien clown's jumpsuit.
enum ClownPattern { case moons, stars, dots, swirls, stripes, diamonds }

/// The twelve types of alien clown the machine can make.
enum ClownKind: String, Codable, CaseIterable, Identifiable {
    case moonbeam, starburst, lollipop, bigTop, dotty, ragtime, cottonCandy, jester, bluebell, shamrock, confetti, pinwheel

    var id: Self { self }

    /// Album photos saved with a type that has since been retired (the Pierrots) load as Moonbeam.
    init(from decoder: Decoder) throws {
        self = ClownKind(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .moonbeam
    }

    var name: String {
        switch self {
        case .bigTop: "Big Top"
        case .cottonCandy: "Cotton Candy"
        default: rawValue.capitalized
        }
    }

    var blurb: String {
        switch self {
        case .moonbeam: "Pink suit, moons, red tufts"
        case .starburst: "Gold suit, stars, green fin"
        case .lollipop: "Blue nose, red heart cheeks"
        case .bigTop: "Red and yellow, orange puff"
        case .dotty: "Polka dots, green puff"
        case .ragtime: "Stripes and red spikes"
        case .cottonCandy: "Sky blue, blue heart cheeks"
        case .jester: "Purple, gold flame of hair"
        case .bluebell: "Blue nose, pink cheeks"
        case .shamrock: "Green nose, blue cheeks"
        case .confetti: "Orange nose, purple cheeks"
        case .pinwheel: "Purple nose, orange cheeks"
        }
    }

    /// The jumpsuit.
    var suit: RGB {
        switch self {
        case .moonbeam: RGB(r: 0.93, g: 0.22, b: 0.48)
        case .starburst: RGB(r: 0.97, g: 0.72, b: 0.16)
        case .lollipop: RGB(r: 0.99, g: 0.72, b: 0.76)
        case .bigTop: RGB(r: 0.88, g: 0.16, b: 0.14)
        case .dotty: RGB(r: 0.96, g: 0.96, b: 0.98)
        case .ragtime: RGB(r: 0.24, g: 0.16, b: 0.36)
        case .cottonCandy: RGB(r: 0.50, g: 0.80, b: 0.98)
        case .jester: RGB(r: 0.50, g: 0.24, b: 0.72)
        case .bluebell: RGB(r: 0.20, g: 0.78, b: 0.74)
        case .shamrock: RGB(r: 0.98, g: 0.56, b: 0.16)
        case .confetti: RGB(r: 0.20, g: 0.36, b: 0.86)
        case .pinwheel: RGB(r: 0.55, g: 0.85, b: 0.25)
        }
    }

    /// The ruff, cuffs and ankle frills.
    var trim: RGB {
        switch self {
        case .moonbeam: RGB(r: 0.99, g: 0.70, b: 0.80)
        case .starburst: RGB(r: 0.40, g: 0.76, b: 0.88)
        case .lollipop: RGB(r: 0.22, g: 0.62, b: 0.88)
        case .bigTop: RGB(r: 0.24, g: 0.68, b: 0.32)
        case .dotty: RGB(r: 0.96, g: 0.78, b: 0.16)
        case .ragtime: RGB(r: 0.92, g: 0.24, b: 0.40)
        case .cottonCandy: RGB(r: 1.00, g: 0.62, b: 0.82)
        case .jester: RGB(r: 0.98, g: 0.80, b: 0.22)
        case .bluebell: RGB(r: 1.00, g: 0.60, b: 0.80)
        case .shamrock: RGB(r: 0.36, g: 0.66, b: 0.98)
        case .confetti: RGB(r: 1.00, g: 0.85, b: 0.20)
        case .pinwheel: RGB(r: 0.62, g: 0.30, b: 0.86)
        }
    }

    /// The print on the suit, and the oversized shoes.
    var mark: RGB {
        switch self {
        case .moonbeam: RGB(r: 0.62, g: 0.88, b: 0.98)
        case .starburst: RGB(r: 0.92, g: 0.30, b: 0.52)
        case .lollipop: RGB(r: 0.94, g: 0.34, b: 0.52)
        case .bigTop: RGB(r: 0.99, g: 0.82, b: 0.18)
        case .dotty: RGB(r: 0.90, g: 0.18, b: 0.20)
        case .ragtime: RGB(r: 0.92, g: 0.24, b: 0.30)
        case .cottonCandy: RGB(r: 1.00, g: 1.00, b: 1.00)
        case .jester: RGB(r: 0.98, g: 0.80, b: 0.22)
        case .bluebell: RGB(r: 0.16, g: 0.36, b: 0.90)
        case .shamrock: RGB(r: 0.14, g: 0.66, b: 0.26)
        case .confetti: RGB(r: 0.98, g: 0.30, b: 0.34)
        case .pinwheel: RGB(r: 1.00, g: 0.42, b: 0.72)
        }
    }

    var hair: RGB {
        switch self {
        case .moonbeam: RGB(r: 0.92, g: 0.20, b: 0.16)
        case .starburst: RGB(r: 0.45, g: 0.82, b: 0.16)
        case .lollipop: RGB(r: 0.95, g: 0.26, b: 0.40)
        case .bigTop: RGB(r: 0.98, g: 0.56, b: 0.10)
        case .dotty: RGB(r: 0.52, g: 0.84, b: 0.12)
        case .ragtime: RGB(r: 0.90, g: 0.14, b: 0.14)
        case .cottonCandy: RGB(r: 1.00, g: 0.52, b: 0.78)
        case .jester: RGB(r: 0.98, g: 0.78, b: 0.14)
        case .bluebell: RGB(r: 0.22, g: 0.42, b: 0.96)
        case .shamrock: RGB(r: 0.18, g: 0.72, b: 0.28)
        case .confetti, .pinwheel: hairColors[0]
        }
    }

    /// The curls of a many-colored mop, in order round the head.
    var hairColors: [RGB] {
        switch self {
        case .confetti: [RGB(r: 0.95, g: 0.20, b: 0.22), RGB(r: 1.00, g: 0.58, b: 0.10), RGB(r: 1.00, g: 0.88, b: 0.16),
                         RGB(r: 0.30, g: 0.80, b: 0.26), RGB(r: 0.22, g: 0.52, b: 0.98), RGB(r: 0.62, g: 0.30, b: 0.88)]
        case .pinwheel: [RGB(r: 1.00, g: 0.40, b: 0.72), RGB(r: 0.16, g: 0.80, b: 0.78), RGB(r: 0.64, g: 0.36, b: 0.92),
                         RGB(r: 1.00, g: 0.86, b: 0.30)]
        default: [hair]
        }
    }

    /// The painted patches around the eyes.
    var makeup: RGB {
        switch self {
        case .moonbeam, .cottonCandy, .bluebell, .confetti: RGB(r: 0.30, g: 0.62, b: 0.92)
        case .starburst, .jester, .shamrock, .pinwheel: RGB(r: 0.45, g: 0.35, b: 0.80)
        case .lollipop, .bigTop: RGB(r: 0.60, g: 0.30, b: 0.62)
        case .dotty, .ragtime: RGB(r: 0.72, g: 0.16, b: 0.26)
        }
    }

    var hairShape: ClownHair {
        switch self {
        case .moonbeam, .bluebell: .tufts
        case .starburst: .mohawk
        case .lollipop: .bow
        case .bigTop, .dotty, .cottonCandy: .puff
        case .ragtime, .shamrock: .spikes
        case .jester: .topknot
        case .confetti, .pinwheel: .mop
        }
    }

    var pattern: ClownPattern {
        switch self {
        case .moonbeam: .moons
        case .starburst, .bluebell, .confetti: .stars
        case .lollipop, .pinwheel: .swirls
        case .bigTop, .ragtime: .stripes
        case .dotty, .cottonCandy: .dots
        case .jester, .shamrock: .diamonds
        }
    }

    /// The colour that stands for this type on buttons and photo frames.
    var color: Color { (self == .dotty ? mark : suit).color }

    /// The greasepaint-white skin every alien clown has.
    static let skin = RGB(r: 0.98, g: 0.92, b: 0.90)

    /// The big ball of a nose: red on every type but Bluebell's and Lollipop's blue, Shamrock's green,
    /// Confetti's orange and Pinwheel's purple.
    var nose: RGB {
        switch self {
        case .bluebell, .lollipop: RGB(r: 0.12, g: 0.32, b: 0.92)
        case .shamrock: RGB(r: 0.10, g: 0.62, b: 0.20)
        case .confetti: RGB(r: 1.00, g: 0.50, b: 0.05)
        case .pinwheel: RGB(r: 0.55, g: 0.18, b: 0.85)
        default: RGB(r: 0.90, g: 0.10, b: 0.14)
        }
    }

    /// The nose's highlight colour.
    var noseShine: RGB {
        switch self {
        case .bluebell, .lollipop: RGB(r: 0.45, g: 0.65, b: 1.00)
        case .shamrock: RGB(r: 0.55, g: 0.95, b: 0.45)
        case .confetti: RGB(r: 1.00, g: 0.78, b: 0.45)
        case .pinwheel: RGB(r: 0.82, g: 0.60, b: 1.00)
        default: RGB(r: 1.00, g: 0.35, b: 0.35)
        }
    }

    /// What she says about a nose that isn't the usual red.
    var noseLine: String? {
        switch self {
        case .bluebell, .lollipop: "I have a blue nose!"
        case .shamrock: "I have a green nose!"
        case .confetti: "I have an orange nose!"
        case .pinwheel: "I have a purple nose!"
        default: nil
        }
    }

    /// The circles (or hearts) on the jowls: red on most types, pink on Bluebell, blue on Shamrock and Cotton Candy,
    /// purple on Confetti, orange on Pinwheel.
    var cheeks: RGB {
        switch self {
        case .bluebell: RGB(r: 1.00, g: 0.36, b: 0.70)
        case .shamrock, .cottonCandy: RGB(r: 0.24, g: 0.52, b: 1.00)
        case .confetti: RGB(r: 0.60, g: 0.22, b: 0.88)
        case .pinwheel: RGB(r: 1.00, g: 0.52, b: 0.08)
        default: RGB(r: 0.90, g: 0.10, b: 0.14)
        }
    }

    /// Painted-on cheeks rather than a rosy blush.
    var boldCheeks: Bool { self == .bluebell || self == .shamrock || heartCheeks || bigCheeks }

    /// The multicolored-mop clowns wear extra-large cheek circles.
    var bigCheeks: Bool { self == .confetti || self == .pinwheel }

    /// Painted hearts instead of circles: red on Lollipop, blue on Cotton Candy.
    var heartCheeks: Bool { self == .lollipop || self == .cottonCandy }
}

/// How far someone's legs, body and head have turned alien clown, 0…1 each.
struct ClownLevels {
    var head, body, legs: Double

    static let none = ClownLevels(head: 0, body: 0, legs: 0)
    static let full = ClownLevels(head: 1, body: 1, legs: 1)

    /// The change starts at the feet and works its way up to the face;
    /// `strength` is how much of it is left (1 fresh, 0.5 once home, 0 back to normal).
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

/// One run of the transformation machine, in seconds from the pink button being pressed.
enum Machine {
    /// "This really tingles."
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
    let shirt: RGB
    let pants: RGB
    let isKid: Bool
    /// Wears shorts instead of long pants.
    let shorts: Bool
    let female: Bool
    /// One of the flying tent's alien clowns rather than a person.
    let crew: Bool

    var visible = true
    var x0: Double
    var x1: Double
    var moveT0 = Date.distantPast
    var moveDur = 0.0
    var facing = 1.0

    /// Height above the ground: the beam lifts people up into the tent and sets them back down.
    private var y0 = 0.0
    private var y1 = 0.0
    private var riseT0 = Date.distantPast
    private var riseDur = 0.0

    var mood = Mood.happy
    var says: String?
    var saysUntil = Date.distantPast
    var carrying = false
    /// What she is carrying is a bag of groceries rather than a box.
    var groceries = false
    /// Sitting in one of the tent's chairs.
    var seated = false
    /// Where her hand is reaching, e.g. the glowing pink button.
    var reachTo: CGPoint?
    /// Both hands up, patting her head to feel what has happened to it.
    var feelsHead = false
    /// The clippers, can of shaving cream or razor in her reaching hand.
    var tool: SalonTool?
    /// How much of her scalp is covered in shaving cream (0–1), and how much of that the razor has wiped away, left to right.
    var lather = 0.0
    var shaved = 0.0
    /// A clear plastic processing cap over a hair treatment.
    var cap = false
    /// What she has bought at the accessory store and now wears.
    var accessories: Set<Accessory> = []

    /// The type of alien clown she is turning (or has turned) into.
    var clown: ClownKind?
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

    /// 0 = still human, 1 = alien clown from toes to face.
    func progress(at now: Date) -> Double {
        if crew { return 1 }
        guard clown != nil else { return 0 }
        return min(max(now.timeIntervalSince(changeT0) / changeDur, 0), 1)
    }

    /// True while the tingling has started but the change hasn't finished.
    func isTingling(at now: Date) -> Bool {
        clown != nil && now >= tingleT0 && progress(at: now) < 1
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

    func clownLevels(at now: Date) -> ClownLevels {
        if crew { return .full }
        guard clown != nil else { return .none }
        return ClownLevels(progress: progress(at: now), strength: strength(at: now))
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
        return Person(name, height: kid ? .random(in: 92...118) : .random(in: 140...166), headScale: kid ? 0.155 : 0.12,
                      skin: randomSkin(), hair: hairs.randomElement()!, style: style,
                      shirt: colors.randomElement()!, pants: colors.randomElement()!, kid: kid, female: female, x: x)
    }

    /// One of the flying tent's alien clowns, already in full costume.
    static func alienClown(_ name: String, kind: ClownKind, height: Double, x: Double) -> Person {
        let p = Person(name, height: height, headScale: 0.125, skin: ClownKind.skin, hair: kind.hair, style: .short,
                       shirt: kind.suit, pants: kind.suit, shorts: false, female: false, crew: true, x: x)
        p.clown = kind
        return p
    }
}

/// Where the flying tent takes the three women to transform customers.
enum Venue: String, Codable, CaseIterable, Identifiable {
    case wildwood, lasVegas, nassau, bimini, cocoCay, catalina, stKitts, pisa, paris, laBufadora

    var id: Self { self }

    var name: String {
        switch self {
        case .wildwood: "Wildwood, NJ"
        case .lasVegas: "Las Vegas"
        case .nassau: "Nassau, Bahamas"
        case .bimini: "Bimini, Bahamas"
        case .cocoCay: "Coco Cay"
        case .catalina: "Catalina Island"
        case .stKitts: "St. Kitts"
        case .pisa: "Pisa, Italy"
        case .paris: "Paris, France"
        case .laBufadora: "La Bufadora, Mexico"
        }
    }

    var shortName: String {
        switch self {
        case .wildwood: "Wildwood"
        case .lasVegas: "Fremont Street"
        case .nassau: "Queen's Staircase"
        case .bimini: "Bimini"
        case .catalina: "Catalina"
        case .pisa: "Pisa"
        case .paris: "Paris"
        case .laBufadora: "La Bufadora"
        default: name
        }
    }

    /// For captions: "off to St. Kitts", "off to the Queen's Staircase in Nassau".
    var theName: String {
        switch self {
        case .wildwood: "the boardwalk in Wildwood, New Jersey"
        case .lasVegas: "Fremont Street in Las Vegas"
        case .nassau: "the Queen's Staircase in Nassau"
        case .bimini: "Bimini in the Bahamas"
        case .cocoCay: "Coco Cay"
        case .catalina: "Catalina Island"
        case .stKitts: "St. Kitts"
        case .pisa: "the Leaning Tower of Pisa"
        case .paris: "the Eiffel Tower in Paris"
        case .laBufadora: "La Bufadora in Mexico"
        }
    }

    var blurb: String {
        switch self {
        case .wildwood: "Boardwalk crowds by the pier"
        case .lasVegas: "Fremont Street under the neon"
        case .nassau: "Tourists at the 66 steps"
        case .bimini: "Island hoppers on the beach"
        case .cocoCay: "Cruise passengers ashore"
        case .catalina: "Day-trippers in Avalon harbor"
        case .stKitts: "Cruise passengers by the volcano"
        case .pisa: "Sightseers at the Leaning Tower"
        case .paris: "Strollers by the Eiffel Tower"
        case .laBufadora: "Geyser watchers on the cliffs"
        }
    }

    var icon: String {
        switch self {
        case .wildwood: "beach.umbrella.fill"
        case .lasVegas: "dice.fill"
        case .nassau: "stairs"
        case .bimini: "fish.fill"
        case .cocoCay: "ferry.fill"
        case .catalina: "sailboat.fill"
        case .stKitts: "mountain.2.fill"
        case .pisa: "building.columns.fill"
        case .paris: "sparkles"
        case .laBufadora: "drop.fill"
        }
    }

    var groups: Int { 6 }
    /// What it costs to set up there.
    var fee: Int {
        switch self {
        case .wildwood: 40
        case .lasVegas: 60
        case .nassau: 100
        case .bimini: 110
        case .cocoCay: 120
        case .catalina: 110
        case .stKitts: 90
        case .pisa: 140
        case .paris: 150
        case .laBufadora: 100
        }
    }
    var price: Int {
        switch self {
        case .wildwood: 20
        case .lasVegas: 26
        case .nassau: 36
        case .bimini: 38
        case .cocoCay: 40
        case .catalina: 38
        case .stKitts: 32
        case .pisa: 46
        case .paris: 50
        case .laBufadora: 36
        }
    }
    var kidPrice: Int { price / 2 }

    static let startCash = 250
    static var cheapestFee: Int { allCases.map(\.fee).min()! }

    /// Chance a passer-by is a kid out with their mother (rather than a grown-up on their own).
    var kidChance: Double {
        switch self {
        case .wildwood, .cocoCay: 0.6
        case .lasVegas: 0.25
        case .pisa, .paris: 0.35
        default: 0.45
        }
    }
    var kidYes: Double { 0.8 }
    var adultYes: Double {
        switch self {
        case .lasVegas: 0.75
        default: 0.7
        }
    }
    /// A mother is more likely to join in if her kid just said yes.
    var momYes: Double { 0.6 }
}
