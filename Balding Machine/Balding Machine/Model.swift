import SwiftUI

struct RGB: Codable, Hashable {
    var r, g, b: Double

    var color: Color { Color(red: r, green: g, blue: b) }
}

enum HairStyle: String, Codable, CaseIterable {
    case long, ponytail, bun, short, curly, pigtails, bob
}

enum Mood { case happy, shocked }

/// One trip through the booth, in seconds from the moment the button is pressed.
enum BoothRun {
    static let lower = 1.2
    static let fill = 2.2
    /// The booth's "one minute" of cream, sped up so nobody waits a real minute.
    static let soak = 6.0
    static let rinse = 2.6
    /// Warm air blows the head dry before the dome lifts.
    static let dry = 3.0
    static let lift = 1.2
    static let total = lower + fill + soak + rinse + dry + lift

    enum Phase { case lowering, filling, soaking, rinsing, drying, lifting, done }

    /// Which phase the booth is in `t` seconds after the press, and how far through it (0…1).
    static func phase(_ t: Double) -> (Phase, Double) {
        var start = 0.0
        for (phase, length) in [(Phase.lowering, lower), (.filling, fill), (.soaking, soak), (.rinsing, rinse), (.drying, dry), (.lifting, lift)] {
            if t < start + length { return (phase, max(0, (t - start) / length)) }
            start += length
        }
        return (.done, 1)
    }
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

    var visible = true
    var x0: Double
    var x1: Double
    var moveT0 = Date.distantPast
    var moveDur = 0.0
    var facing = 1.0

    var mood = Mood.happy
    var says: String?
    var saysUntil = Date.distantPast
    var carrying = false
    var bags = false
    var seated = false
    /// Where her hand is reaching, e.g. the booth's button.
    var reachTo: CGPoint?

    var bald = false
    var hairFadeT0 = Date.distantFuture
    var hairFadeDur = 1.0

    init(_ id: String, height: Double, headScale: Double = 0.12, skin: RGB, hair: RGB, style: HairStyle,
         shirt: RGB, pants: RGB, kid: Bool = false, x: Double) {
        self.id = id
        self.height = height
        self.headScale = headScale
        self.skin = skin
        self.hair = hair
        self.style = style
        self.shirt = shirt
        self.pants = pants
        isKid = kid
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

    /// 1 = a full head of hair, 0 = bald. Dissolves while the cream soaks.
    func hairLeft(at now: Date) -> Double {
        if bald { return 0 }
        return 1 - min(max(now.timeIntervalSince(hairFadeT0) / hairFadeDur, 0), 1)
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

    /// A random passer-by, a grown-up or a kid.
    static func customer(_ name: String, kid: Bool, x: Double) -> Person {
        let styles: [HairStyle] = kid ? [.pigtails, .ponytail, .short, .curly, .bob] : [.long, .ponytail, .bun, .short, .curly, .bob]
        return Person(name, height: kid ? .random(in: 92...118) : .random(in: 140...162), headScale: kid ? 0.155 : 0.12,
                      skin: skins.randomElement()!, hair: hairs.randomElement()!, style: styles.randomElement()!,
                      shirt: colors.randomElement()!, pants: colors.randomElement()!, kid: kid, x: x)
    }
}

/// Where the family takes the booth for a public appearance.
enum Venue: String, Codable, CaseIterable, Identifiable {
    case carnival, amusementPark, stBaldricks

    var id: Self { self }

    var name: String {
        switch self {
        case .carnival: "Carnival"
        case .amusementPark: "Amusement Park"
        case .stBaldricks: "St. Baldrick's Event"
        }
    }

    var blurb: String {
        switch self {
        case .carnival: "Lots of families"
        case .amusementPark: "Big crowds, lots of kids"
        case .stBaldricks: "Shave for kids' cancer research"
        }
    }

    var icon: String {
        switch self {
        case .carnival: "party.popper"
        case .amusementPark: "sparkles"
        case .stBaldricks: "heart.fill"
        }
    }

    var groups: Int { 6 }
    /// What it costs to set up the booth there.
    var fee: Int {
        switch self {
        case .carnival: 40
        case .amusementPark: 80
        case .stBaldricks: 25
        }
    }
    /// At the St. Baldrick's event shaves are free and people donate to the charity instead.
    var isCharity: Bool { self == .stBaldricks }
    var price: Int {
        switch self {
        case .carnival: 10
        case .amusementPark: 15
        case .stBaldricks: 0
        }
    }
    var kidPrice: Int {
        switch self {
        case .carnival: 5
        case .amusementPark: 8
        case .stBaldricks: 0
        }
    }

    static let startCash = 200
    var adultYes: Double { isCharity ? 0.85 : 0.45 }
    /// Chance a passer-by has a kid along.
    var kidChance: Double {
        switch self {
        case .carnival: 0.6
        case .amusementPark: 0.7
        case .stBaldricks: 0.5
        }
    }
    var kidYes: Double { isCharity ? 0.8 : 0.6 }
}
