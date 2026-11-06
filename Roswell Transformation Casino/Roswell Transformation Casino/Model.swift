import SwiftUI

struct RGB: Codable, Hashable {
    var r, g, b: Double

    var color: Color { Color(red: r, green: g, blue: b) }
}

enum HairStyle: String, Codable, CaseIterable {
    case long, ponytail, bun, short, curly, pigtails, bob
}

enum Mood { case happy, shocked }

/// The colours the machine can turn someone. Each person gets one at random as she sits down.
enum AlienColor: String, Codable, CaseIterable {
    case green, darkGreen, lightGreen, blue, lightBlue, pink

    /// Lower-case, for lines like "I'm light blue!".
    var name: String {
        switch self {
        case .green: "green"
        case .darkGreen: "dark green"
        case .lightGreen: "light green"
        case .blue: "blue"
        case .lightBlue: "light blue"
        case .pink: "pink"
        }
    }

    var skin: RGB {
        switch self {
        case .green: RGB(r: 0.52, g: 0.80, b: 0.42)
        case .darkGreen: RGB(r: 0.20, g: 0.50, b: 0.24)
        case .lightGreen: RGB(r: 0.72, g: 0.93, b: 0.58)
        case .blue: RGB(r: 0.32, g: 0.50, b: 0.90)
        case .lightBlue: RGB(r: 0.60, g: 0.82, b: 1.00)
        case .pink: RGB(r: 0.98, g: 0.62, b: 0.80)
        }
    }

    /// A brighter version for the machine's beam.
    var beam: RGB {
        switch self {
        case .green: RGB(r: 0.40, g: 1.00, b: 0.45)
        case .darkGreen: RGB(r: 0.20, g: 0.80, b: 0.30)
        case .lightGreen: RGB(r: 0.75, g: 1.00, b: 0.60)
        case .blue: RGB(r: 0.35, g: 0.55, b: 1.00)
        case .lightBlue: RGB(r: 0.60, g: 0.90, b: 1.00)
        case .pink: RGB(r: 1.00, g: 0.55, b: 0.85)
        }
    }
}

/// One trip through the transformation machine, in seconds from the moment the button is pressed.
enum BoothRun {
    static let lower = 1.2
    /// The emitters hum and glow brighter before the beam switches on.
    static let charge = 2.2
    /// The machine's "one minute" in the beam, sped up so nobody waits a real minute (long enough for a close-up of each sitter).
    static let beam = 9.0
    /// Sparkles settle the change in.
    static let sparkle = 2.6
    /// The emitters cool down with a puff of mist before they lift.
    static let cool = 3.0
    static let lift = 1.2
    static let total = lower + charge + beam + sparkle + cool + lift

    enum Phase { case lowering, charging, beaming, sparkling, cooling, lifting, done }

    /// Which phase the machine is in `t` seconds after the press, and how far through it (0…1).
    static func phase(_ t: Double) -> (Phase, Double) {
        var start = 0.0
        for (phase, length) in [(Phase.lowering, lower), (.charging, charge), (.beaming, beam), (.sparkling, sparkle), (.cooling, cool), (.lifting, lift)] {
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
    /// Standing behind the card table, which hides her from the waist down.
    var atTable = false
    /// Where her hand is reaching, e.g. the booth's button.
    var reachTo: CGPoint?

    /// Fully turned into a Roswell alien.
    var alien = false
    var alienColor = AlienColor.green
    var changeT0 = Date.distantFuture
    var changeDur = 1.0
    /// The alien level the current change runs from and to: 0 → 1 to turn alien, 1 → 0 to turn back.
    var changeFrom = 0.0
    var changeTo = 1.0

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

    /// 0 = human, 1 = a Roswell alien. Grows while the beam is on, and shrinks back when the machine runs in reverse.
    func alienLevel(at now: Date) -> Double {
        if alien { return 1 }
        let u = min(max(now.timeIntervalSince(changeT0) / changeDur, 0), 1)
        return changeFrom + (changeTo - changeFrom) * u
    }

    /// How much of her clothes are left: they melt away over the last part of the change, and come back first when she turns back.
    func clothesLeft(at now: Date) -> Double {
        let u = min(max((alienLevel(at: now) - 0.55) / 0.45, 0), 1)
        return 1 - u * u * (3 - 2 * u)
    }
}

extension Person {
    /// The classic Roswell green, for the sign and the icon.
    static let alienSkin = AlienColor.green.skin

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

/// The tables Mom runs at the casino. Moneymaker games are played against Mom as the house;
/// the just-for-fun games are played at home for nothing but bragging rights.
enum CasinoGame: String, Codable, CaseIterable, Identifiable {
    case blackjack, crazy4, letItRide, threeCard, mississippiStud, paiGow, baccarat, caribbeanStud, texasHoldem, omaha
    case pitch, euchre, hearts, spades, knaves, pepper, ninetyNine, fourHundred, diamonds

    var id: Self { self }

    static let moneyGames: [CasinoGame] = [.blackjack, .crazy4, .letItRide, .threeCard, .mississippiStud, .paiGow, .baccarat, .caribbeanStud, .texasHoldem, .omaha]
    static let funGames: [CasinoGame] = [.pitch, .euchre, .hearts, .spades, .knaves, .pepper, .ninetyNine, .fourHundred, .diamonds]

    static let buyIn = 50
    static let startCash = 200
    /// Most people Mom adds to a moneymaker table, besides the daughter: women, and any girls who join them.
    static let maxPlayers = 3
    /// Mom stops asking at a moneymaker table after this many passers-by, even if spots are left.
    static let maxAsked = 6
    /// At a moneymaker table each player stays until her chips reach this many times her buy-in, or she runs out.
    static let goal = 2
    /// A safety stop: Mom closes a moneymaker table after this many hands even if a guest is still playing.
    static let handLimit = 150
    /// What the casino charges the family to set up each moneymaker table.
    static let setupFee = 25
    static let casinoName = "Roswell Transformation Casino"

    var isMoney: Bool { Self.moneyGames.contains(self) }

    var name: String {
        switch self {
        case .blackjack: "Blackjack"
        case .crazy4: "Crazy 4 Poker"
        case .letItRide: "Let It Ride"
        case .threeCard: "Three Card Poker"
        case .mississippiStud: "Mississippi Stud"
        case .paiGow: "Pai Gow Poker"
        case .baccarat: "Baccarat"
        case .caribbeanStud: "Caribbean Stud"
        case .texasHoldem: "Texas Hold'em"
        case .omaha: "Omaha Hold'em"
        case .pitch: "Pitch"
        case .euchre: "Euchre"
        case .hearts: "Hearts"
        case .spades: "Spades"
        case .knaves: "Knaves"
        case .pepper: "Pepper"
        case .ninetyNine: "99"
        case .fourHundred: "400"
        case .diamonds: "Diamonds"
        }
    }

    var icon: String {
        switch self {
        case .blackjack: "suit.club.fill"
        case .crazy4: "4.square.fill"
        case .letItRide: "arrow.right.circle.fill"
        case .threeCard: "3.square.fill"
        case .mississippiStud: "water.waves"
        case .paiGow: "rectangle.split.2x1.fill"
        case .baccarat: "crown.fill"
        case .caribbeanStud: "sun.max.fill"
        case .texasHoldem: "star.fill"
        case .omaha: "square.grid.2x2.fill"
        case .pitch: "baseball.fill"
        case .euchre: "person.2.fill"
        case .hearts: "suit.heart.fill"
        case .spades: "suit.spade.fill"
        case .knaves: "person.3.fill"
        case .pepper: "flame.fill"
        case .ninetyNine: "number.square.fill"
        case .fourHundred: "number.circle.fill"
        case .diamonds: "diamond.fill"
        }
    }

    var blurb: String {
        switch self {
        case .blackjack: "Get closer to 21 than Mom"
        case .crazy4: "Best 4 of 5 cards"
        case .letItRide: "Pull bets back or let them ride"
        case .threeCard: "Ante, then play or fold"
        case .mississippiStud: "Raise on each street"
        case .paiGow: "Split 7 cards into 5 + 2"
        case .baccarat: "Player, Banker or Tie"
        case .caribbeanStud: "5-card stud vs. Mom"
        case .texasHoldem: "2 hole cards + board vs. Mom"
        case .omaha: "4 hole cards, use exactly 2"
        case .pitch: "No partners · High, Low, Jack, Game · to \(target)"
        case .euchre: "Partners, bowers · to \(target)"
        case .hearts: "Dodge the Q♠ · ends at \(target)"
        case .spades: "Blind double nil · to \(target)"
        case .knaves: "Avoid the jacks · to \(target)"
        case .pepper: "Bid or get peppered · to \(target)"
        case .ninetyNine: "Hit your bid exactly · to \(target)"
        case .fourHundred: "Partners · one to \(target)"
        case .diamonds: "Collect crystals · \(target) rounds"
        }
    }

    /// Seats at a just-for-fun table, Mom included.
    var funSeats: Int { self == .knaves || self == .ninetyNine ? 3 : 4 }
    var isPartners: Bool { [.euchre, .spades, .pepper, .fourHundred].contains(self) }

    /// The score that ends a just-for-fun game.
    var target: Int {
        switch self {
        case .pitch: 11
        case .euchre: 10
        case .hearts: 100
        case .spades: 300
        case .knaves: 20
        case .pepper: 30
        case .ninetyNine: 100
        case .fourHundred: 41
        /// Diamonds goes by rounds, not points: one deal per player.
        case .diamonds: 4
        default: 0
        }
    }

    var accent: Color {
        isMoney ? Color(red: 0.85, green: 0.65, blue: 0.15) : Color(red: 0.20, green: 0.55, blue: 0.85)
    }
}

/// One line on the scoreboard: a player and her chips or score.
struct BoardRow: Identifiable {
    let id: String
    var value: String
    var note: String
    /// Partner games: 0 or 1.
    var team: Int?
    var out = false
}

struct TableBoard {
    let game: CasinoGame
    var status: String
    var rows: [BoardRow]
    var pot: Int?
}
