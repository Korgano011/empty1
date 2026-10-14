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
    case long, ponytail, bun, short, curly, pigtails, bob
}

enum Mood { case happy, shocked, smiling, angry }

/// The ten colours of Roswell alien the machine can make.
enum AlienColor: String, Codable, CaseIterable, Identifiable {
    case green, darkGreen, pink, purple, orange, lavender, lightBlue, brightRed, emerald, lightGreen

    var id: Self { self }

    /// Albums saved with colours that have since been swapped out still load:
    /// the first dark blue → lavender, gold / red / ruby → bright red, blue / the later dark blue / yellow → emerald, dark orange → light green.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "darkBlue": self = .lavender
        case "gold", "red", "ruby": self = .brightRed
        case "blue", "navy", "yellow": self = .emerald
        case "darkOrange": self = .lightGreen
        default: self = AlienColor(rawValue: raw) ?? .green
        }
    }

    var name: String {
        switch self {
        case .darkGreen: "Dark Green"
        case .lavender: "Lavender"
        case .lightBlue: "Light Blue"
        case .lightGreen: "Light Green"
        case .brightRed: "Bright Red"
        default: rawValue.capitalized
        }
    }

    var isDark: Bool { self == .darkGreen || self == .purple || self == .brightRed }

    var rgb: RGB {
        switch self {
        case .green: RGB(r: 0.42, g: 0.80, b: 0.36)
        case .darkGreen: RGB(r: 0.12, g: 0.42, b: 0.18)
        case .pink: RGB(r: 1.00, g: 0.55, b: 0.78)
        case .purple: RGB(r: 0.50, g: 0.26, b: 0.74)
        case .orange: RGB(r: 1.00, g: 0.58, b: 0.18)
        case .lavender: RGB(r: 0.74, g: 0.62, b: 0.93)
        case .lightBlue: RGB(r: 0.52, g: 0.80, b: 1.00)
        case .brightRed: RGB(r: 0.96, g: 0.10, b: 0.10)
        case .emerald: RGB(r: 0.02, g: 0.60, b: 0.42)
        case .lightGreen: RGB(r: 0.68, g: 0.95, b: 0.55)
        }
    }

    var color: Color { rgb.color }

    var blurb: String {
        switch self {
        case .green: "Classic little green alien"
        case .darkGreen: "Deep forest green alien"
        case .pink: "Bubblegum pink alien"
        case .purple: "Royal purple alien"
        case .orange: "Tangerine orange alien"
        case .lavender: "Soft lavender alien"
        case .lightBlue: "Sky blue alien"
        case .brightRed: "Bright fire-engine red alien"
        case .emerald: "Sparkling emerald alien"
        case .lightGreen: "Soft lime green alien"
        }
    }
}

/// How far someone's legs, body and head have turned alien, 0…1 each.
struct AlienLevels {
    var head, body, legs: Double

    static let none = AlienLevels(head: 0, body: 0, legs: 0)
    static let full = AlienLevels(head: 1, body: 1, legs: 1)

    /// The change starts at the legs and works its way up to the face;
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

/// One run of the transformation machine, in seconds from the green button being pressed.
enum Machine {
    /// "They first feel a tingling sensation…"
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
    let style: HairStyle
    let shirt: RGB
    let pants: RGB
    let isKid: Bool
    /// Wears shorts instead of long pants.
    let shorts: Bool
    let female: Bool
    /// One of the saucer's Roswell alien crew rather than a person.
    let crew: Bool

    var visible = true
    var x0: Double
    var x1: Double
    var moveT0 = Date.distantPast
    var moveDur = 0.0
    var facing = 1.0

    /// Height above the ground: the beam lifts people up into the saucer and sets them back down.
    private var y0 = 0.0
    private var y1 = 0.0
    private var riseT0 = Date.distantPast
    private var riseDur = 0.0

    var mood = Mood.happy
    var says: String?
    var saysUntil = Date.distantPast
    var carrying = false
    /// What she is carrying is a bag of groceries rather than a moving box.
    var groceries = false
    /// Wears a two-piece swimsuit (in her shirt colour) instead of a shirt and pants.
    var bikini = false
    /// Hands cuffed behind his back.
    var cuffed = false
    /// Sitting in one of the saucer's chairs.
    var seated = false
    /// Where her hand is reaching, e.g. the glowing green button.
    var reachTo: CGPoint?
    /// Both hands up, feeling the sides of her head.
    var feelHead = false
    /// Rocking her head from side to side.
    var rockT0 = Date.distantPast
    var rockDur = 0.0

    /// How far her head is tipped (degrees) while rocking: a few gentle swings that ease in and out.
    func rockAngle(at now: Date) -> Double {
        let t = now.timeIntervalSince(rockT0)
        guard t > 0, t < rockDur else { return 0 }
        let swing = 1.2
        return 16 * sin(t / swing * 2 * .pi) * sin(t / rockDur * .pi)
    }

    /// The colour of alien she is turning (or has turned) into.
    var alien: AlienColor?
    var tingleT0 = Date.distantFuture
    var changeT0 = Date.distantFuture
    var changeDur = 1.0
    /// When the finished change first twinkled.
    var shineT0 = Date.distantPast

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

    /// 0 = still human, 1 = alien from toes to face.
    func progress(at now: Date) -> Double {
        if crew { return 1 }
        guard alien != nil else { return 0 }
        return min(max(now.timeIntervalSince(changeT0) / changeDur, 0), 1)
    }

    /// True while the tingling has started but the change hasn't finished.
    func isTingling(at now: Date) -> Bool {
        alien != nil && now >= tingleT0 && progress(at: now) < 1
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

    func alienLevels(at now: Date) -> AlienLevels {
        if crew { return .full }
        guard alien != nil else { return .none }
        return AlienLevels(progress: progress(at: now), strength: strength(at: now))
    }

    /// The skin colour she's changing to: her alien colour, or a crew member's own grey.
    var alienRGB: RGB? { crew ? skin : alien?.rgb }
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
        // Most of the grown women come straight from the beach in a bikini.
        p.bikini = !kid && female && Double.random(in: 0...1) < 0.65
        return p
    }

    /// One of the saucer's grey Roswell aliens.
    static func alienCrew(_ name: String, x: Double) -> Person {
        let grey = [RGB(r: 0.70, g: 0.74, b: 0.72), RGB(r: 0.66, g: 0.70, b: 0.70), RGB(r: 0.74, g: 0.76, b: 0.70)].randomElement()!
        let suit = RGB(r: 0.78, g: 0.80, b: 0.86)
        return Person(name, height: .random(in: 112...124), headScale: 0.16, skin: grey, hair: grey, style: .short,
                      shirt: suit, pants: suit, shorts: false, female: false, crew: true, x: x)
    }
}

/// Where the flying saucer takes the family to transform customers.
enum Venue: String, Codable, CaseIterable, Identifiable {
    case lasVegas, stKitts, celebrationKey, halfMoonCay, catalina, rio, oceanCay, laBufadora, kingsWharf

    var id: Self { self }

    /// Albums saved before the carnival, boardwalk, amusement park, Point Pleasant, Seaside Heights, Miami, Yosemite,
    /// Fort Lauderdale and Honolulu were dropped still load.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "boardwalk", "pointPleasant": self = .lasVegas
        case "carnival", "amusementPark", "seasideHeights": self = .stKitts
        case "miami": self = .catalina
        case "yosemite": self = .kingsWharf
        case "fortLauderdale": self = .rio
        case "honolulu": self = .laBufadora
        default: self = Venue(rawValue: raw) ?? .lasVegas
        }
    }

    var name: String {
        switch self {
        case .lasVegas: "Downtown Las Vegas"
        case .stKitts: "St. Kitts"
        case .celebrationKey: "Celebration Key"
        case .halfMoonCay: "Half Moon Cay"
        case .catalina: "Catalina Island"
        case .rio: "Rio de Janeiro"
        case .oceanCay: "Ocean Cay"
        case .laBufadora: "La Bufadora, Mexico"
        case .kingsWharf: "King's Wharf, Bermuda"
        }
    }

    var shortName: String {
        switch self {
        case .lasVegas: "Fremont Street"
        case .catalina: "Catalina"
        case .rio: "Rio"
        case .laBufadora: "La Bufadora"
        case .kingsWharf: "King's Wharf"
        default: name
        }
    }

    /// For captions: "off to St. Kitts", "off to King's Wharf in Bermuda".
    var theName: String {
        switch self {
        case .lasVegas: "Fremont Street in Downtown Las Vegas"
        case .stKitts: "St. Kitts"
        case .celebrationKey: "Celebration Key"
        case .halfMoonCay: "Half Moon Cay"
        case .catalina: "Catalina Island"
        case .rio: "Copacabana Beach in Rio de Janeiro"
        case .oceanCay: "Ocean Cay"
        case .laBufadora: "La Bufadora in Mexico"
        case .kingsWharf: "King's Wharf in Bermuda"
        }
    }

    var blurb: String {
        switch self {
        case .lasVegas: "Fremont Street under the neon"
        case .stKitts: "Cruise passengers below the volcano"
        case .celebrationKey: "Carnival cruise passengers"
        case .halfMoonCay: "Cruise passengers on the crescent beach"
        case .catalina: "Day-trippers in Avalon harbor"
        case .rio: "Copacabana beach crowds"
        case .oceanCay: "Cruise ship passengers"
        case .laBufadora: "Geyser watchers on the cliffs"
        case .kingsWharf: "Cruise passengers at the Dockyard"
        }
    }

    var icon: String {
        switch self {
        case .lasVegas: "dice.fill"
        case .stKitts: "mountain.2.fill"
        case .celebrationKey: "party.popper"
        case .halfMoonCay: "moon.fill"
        case .catalina: "sailboat.fill"
        case .rio: "beach.umbrella.fill"
        case .oceanCay: "ferry.fill"
        case .laBufadora: "drop.fill"
        case .kingsWharf: "clock.fill"
        }
    }

    var groups: Int { 6 }
    /// What it costs to set up there.
    var fee: Int {
        switch self {
        case .lasVegas: 40
        case .stKitts: 60
        case .celebrationKey: 120
        case .halfMoonCay: 120
        case .catalina: 110
        case .rio: 140
        case .oceanCay: 120
        case .laBufadora: 100
        case .kingsWharf: 130
        }
    }
    var price: Int {
        switch self {
        case .lasVegas: 20
        case .stKitts: 24
        case .celebrationKey: 40
        case .halfMoonCay: 40
        case .catalina: 38
        case .rio: 48
        case .oceanCay: 40
        case .laBufadora: 36
        case .kingsWharf: 44
        }
    }
    var kidPrice: Int { price / 2 }

    static let startCash = 250
    static var cheapestFee: Int { allCases.map(\.fee).min()! }

    /// Chance a passer-by is a kid out with their mother (rather than a grown-up on their own).
    var kidChance: Double {
        switch self {
        case .celebrationKey: 0.65
        case .rio, .laBufadora: 0.5
        case .oceanCay, .halfMoonCay, .stKitts: 0.45
        case .lasVegas: 0.3
        case .catalina: 0.45
        case .kingsWharf: 0.45
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
