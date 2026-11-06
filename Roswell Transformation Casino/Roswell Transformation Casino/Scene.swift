import SwiftUI

/// World layout: a cut-away side view of the single-story house, in points.
enum Stage {
    static let W = 1200.0
    static let H = 600.0
    static let floorY = 490.0
    static let ceilY = 180.0
    static let doorwayTop = floorY - 175

    static let rooms: [(name: String, x0: Double, x1: Double, wall: RGB)] = [
        ("Empty Room", 0, 440, RGB(r: 0.90, g: 0.90, b: 0.93)),
        ("Mom's Room", 440, 580, RGB(r: 0.98, g: 0.85, b: 0.80)),
        ("Bathroom", 580, 690, RGB(r: 0.78, g: 0.90, b: 0.95)),
        ("Living Room", 690, 860, RGB(r: 0.98, g: 0.92, b: 0.78)),
        ("Ava's Room", 860, 975, RGB(r: 0.80, g: 0.92, b: 0.90)),
        ("Mia's Room", 975, 1090, RGB(r: 0.88, g: 0.84, b: 0.96)),
        ("Rosie's Room", 1090, 1200, RGB(r: 1.00, g: 0.86, b: 0.92)),
    ]

    /// Three chairs, each with its own beam emitter; one glowing button starts them all.
    static let booth = CGRect(x: 15, y: floorY - 250, width: 285, height: 250)
    static let seatX = [70.0, 145.0, 220.0]
    /// The glowing button on its post beside the right-hand chair.
    static let button = CGPoint(x: 267, y: floorY - 74)
    /// Where a family member stands to press the button for the players at the casino.
    static let buttonStand = 292.0
    /// A wide mirror: up to three people can look into it at once.
    static let mirror = CGRect(x: 332, y: floorY - 215, width: 96, height: 160)
    /// Where each person stands when a group looks in the mirror together, nearest first.
    static let mirrorStands = [462.0, 487.0, 512.0]
    static let watchX = [322.0, 344.0, 366.0]
    static let doorX = 810.0
    static let couchX = [715.0, 745.0, 775.0]
    /// Where the aunt and cousin stand to turn in on a sleepover (air mattresses on the living-room floor).
    static let sleepoverX = [728.0, 790.0]
    /// Mom, Ava, Mia, Rosie.
    static let roomX = [505.0, 915.0, 1030.0, 1143.0]
    // The casino: the booth stays on the left, the card table is in the middle.
    static let table = CGRect(x: 560, y: floorY - 94, width: 400, height: 94)
    /// Mom deals from the middle of the table; players stand at these spots.
    static let dealerX = 760.0
    static let spotX = [610.0, 684.0, 836.0, 910.0]
    /// A big moneymaker table (up to six guests and the daughter) squeezes in tighter.
    static let crowdSpotX = [582.0, 624.0, 666.0, 708.0, 846.0, 888.0, 930.0]
    static func spots(_ n: Int) -> [Double] { Array((n <= spotX.count ? spotX : crowdSpotX).prefix(n)) }
    /// Where Ava, Mia and Rosie watch the game from.
    /// Ava, Mia and Rosie watch from here — and any girls the players brought along.
    static let girlsTableX = [985.0, 1008.0, 1031.0, 1054.0, 1077.0, 1100.0, 1123.0, 1146.0, 1169.0]
    /// A daughter who's the house stands beside Mom.
    static let houseX = 795.0

    /// Where someone's feet are: kids at the card table stand on a hidden step stool so they can see over it.
    static func feetY(_ p: Person) -> Double {
        p.atTable && p.isKid ? floorY - max(0, 142 - p.height) : floorY
    }
    /// Guests line up under the casino's EXIT sign on their way out, and turn human again there.
    // Main Street: a boutique, the grocery store and the bank, with the door each one is entered by.
    static let boutiqueDoorX = 230.0
    static let storeDoorX = 600.0
    static let bankDoorX = 985.0
    static let exitX = [1160.0, 1124.0, 1088.0, 1052.0, 1016.0, 980.0]
    /// Front doors on the guests' street, one house per household.
    static let guestDoorX = [150.0, 450.0, 750.0, 1050.0]
    /// While recruiting for a game at home, the last house on the street is the family's.
    static let familyDoorX = 1050.0
    /// Mom stops passers-by here, the girls just behind her.
    static let askX = 1005.0
    static let girlsAskX = [975.0, 950.0, 928.0]
    static let stopX = 1075.0
    /// New players (and their daughters) wait by the booth; the family stands just past them.
    static let waitX = [420.0, 432.0, 444.0, 456.0, 468.0, 480.0, 492.0, 504.0, 516.0, 528.0, 540.0, 552.0]
    static let boothSideX = [578.0, 598.0, 616.0, 634.0]

    // Camera shots, all the stage's 2:1 shape.
    static let full = CGRect(x: 0, y: 0, width: W, height: H)
    static let boothView = CGRect(x: 0, y: 215, width: 580, height: 290)
    static let tableShot = CGRect(x: 520, y: 215, width: 580, height: 290)
    /// Just-for-fun games at home: Mom deals in the living room, players around her, watchers by the bedrooms.
    static let homeDealerX = 785.0
    static let homeSpotX = [705.0, 730.0, 755.0, 815.0, 840.0]
    static let homeAudienceX = [880.0, 905.0, 930.0, 955.0, 1000.0, 1025.0, 1050.0]
    /// Where the family gathers in the living room to pick a game, and where a visiting aunt and cousin wait.
    static let homeFamilyX = [715.0, 745.0, 775.0, 800.0]
    static let homeCousinX = 905.0
    static let homeAuntX = 930.0

    /// A close-up `height` tall, centred on `centerX`, with a little floor showing.
    static func shot(centerX: Double, height: Double) -> CGRect {
        let width = height * W / H
        let x = min(max(centerX - width / 2, 0), W - width)
        return CGRect(x: x, y: floorY + 12 - height, width: width, height: height)
    }

    /// A close-up `height` tall centred on a point, never showing much below the floor.
    static func focus(_ c: CGPoint, height: Double) -> CGRect {
        let width = height * W / H
        return CGRect(x: min(max(c.x - width / 2, 0), W - width), y: min(max(c.y - height / 2, 0), floorY + 20 - height),
                      width: width, height: height)
    }
}

func drawStage(_ ctx: GraphicsContext, size: CGSize, director d: Director, now: Date) {
    var screen = ctx
    let s = min(size.width / Stage.W, size.height / Stage.H)
    screen.translateBy(x: (size.width - Stage.W * s) / 2, y: (size.height - Stage.H * s) / 2)
    screen.scaleBy(x: s, y: s)
    screen.clip(to: Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)))

    var ctx = screen
    let cam = d.camera(at: now)
    let zoom = Stage.W / cam.width
    ctx.scaleBy(x: zoom, y: zoom)
    ctx.translateBy(x: -cam.minX, y: -cam.minY)

    let outdoors = d.inTown || d.inNeighborhood
    if d.inTown {
        drawTown(ctx, now: now)
    } else if d.inNeighborhood {
        drawNeighborhood(ctx, now: now, day: d.daytime, home: d.outsideHome, doorOpen: now < d.doorOpenUntil)
    } else if d.atCasino {
        drawCasino(ctx, now: now)
        drawStandingMirror(ctx, accent: casinoGold)
    } else {
        drawHouse(ctx, d: d, now: now)
    }
    if !outdoors { drawBoothBack(ctx, d: d, now: now) }
    for x in d.boxes where !d.atCasino && !outdoors { drawBox(ctx, center: CGPoint(x: x, y: Stage.floorY - 13), size: 30) }

    let people = d.everyone.filter(\.visible)
    // Everyone standing at the mirror shows up in it, side by side.
    let looking = Stage.mirrorStands.compactMap { x in
        people.first { abs($0.x(at: now) - x) < 3 && !$0.isWalking(at: now) && !$0.seated }
    }
    for (i, p) in looking.enumerated() {
        drawReflection(ctx, p, now: now, slot: i, of: looking.count)
    }
    // Whoever is in the chair sits behind the beam and the glass; everyone else walks in front.
    for p in people where p.seated {
        drawPerson(ctx, p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: p.facing, now: now)
    }
    if !outdoors {
        drawEmitters(ctx, d: d, now: now)
        drawBoothFront(ctx, d: d)
    }
    // Players and the dealer stand behind the table; everyone else walks in front of it.
    for p in people where p.atTable && !p.seated {
        drawPerson(ctx, p, feet: CGPoint(x: p.x(at: now), y: Stage.feetY(p)), facing: p.facing, now: now)
    }
    if d.atCasino { drawTable(ctx, felt: d.felt) }
    let asleep = d.lightsOut && !outdoors && !d.atCasino
    if asleep {
        for (p, bed) in zip(d.cast, beds) where p.visible { drawAsleep(ctx, p, bed: bed, now: now) }
        for (p, m) in zip(sleepers(d), mattresses) where p.visible { drawOnMattress(ctx, p, m, now: now) }
    }
    let lyingDown = asleep ? d.cast + sleepers(d) : []
    let standing = people.filter { q in !q.seated && !q.atTable && !lyingDown.contains { $0 === q } }
    for p in standing.sorted(by: { $0.height > $1.height }) {
        drawPerson(ctx, p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: p.facing, now: now)
    }
    // Anyone changing back outside the machine twinkles while it happens.
    for p in people where !d.beamPeople.contains(where: { $0 === p }) {
        let level = p.alienLevel(at: now)
        if level > 0 && level < 1 { drawChangeSparkles(ctx, p, now: now) }
    }
    // Lights out: the house goes dark and sleepy Z's float up from everyone at home.
    if asleep {
        // Night sky: the sun gives way to a crescent moon.
        ctx.fill(circle(CGPoint(x: 1115, y: 65), 38), with: .color(Color(red: 0.50, green: 0.75, blue: 0.98)))
        ctx.fill(circle(CGPoint(x: 1115, y: 65), 30), with: .color(Color(red: 1, green: 0.97, blue: 0.8)))
        ctx.fill(circle(CGPoint(x: 1129, y: 57), 28), with: .color(Color(red: 0.50, green: 0.75, blue: 0.98)))
        ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(Color(red: 0.02, green: 0.03, blue: 0.12).opacity(0.62)))
        let t = now.timeIntervalSinceReferenceDate
        let spots = zip(d.cast, beds.map(\.x)).map { ($0, $1) } + zip(sleepers(d), mattresses.map(\.x)).map { ($0, $1) }
        for (k, (p, bedX)) in spots.enumerated() where p.visible {
            let x = bedX + 22
            for i in 0..<3 {
                let phase = (t * 0.5 + Double(i) / 3 + Double(k) * 0.17).truncatingRemainder(dividingBy: 1)
                ctx.draw(Text("Z").font(.system(size: 12 + Double(i) * 4, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white.opacity(1 - phase)),
                         at: CGPoint(x: x + 10 + phase * 24, y: Stage.floorY - 70 - phase * 50))
            }
        }
    }
    // Bubbles go on the screen, not the stage, so a close-up never crops them.
    var bubbles: [CGRect] = []
    for p in people.sorted(by: { $0.x(at: now) < $1.x(at: now) }) {
        if let box = drawSpeech(screen, p, now: now, cam: cam, avoiding: bubbles) { bubbles.append(box) }
    }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, x: pop.x, age: now.timeIntervalSince(pop.t0)) }

    // Screen-space overlays
    if now < d.signUntil { drawSignCard(screen) }
    if !d.atCasino && !outdoors { drawHUD(screen, d: d, now: now) }
    let fade = d.fade(at: now)
    if fade > 0 {
        screen.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(.black.opacity(fade)))
    }
    let flash = now.timeIntervalSince(d.flashT0)
    if flash >= 0 && flash < 0.6 {
        screen.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(.white.opacity(1 - flash / 0.6)))
    }
}

// MARK: House

private func fill(_ ctx: GraphicsContext, _ rect: CGRect, _ c: Color, corner: Double = 0) {
    ctx.fill(Path(roundedRect: rect, cornerRadius: corner), with: .color(c))
}

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

private func drawSky(_ ctx: GraphicsContext) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.50, green: 0.75, blue: 0.98), Color(red: 0.88, green: 0.95, blue: 1)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    ctx.fill(circle(CGPoint(x: 1115, y: 65), 35), with: .color(.yellow))
}

private func drawHouse(_ ctx: GraphicsContext, d: Director, now: Date) {
    drawSky(ctx)
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.45, green: 0.72, blue: 0.35))

    var roof = Path()
    roof.move(to: CGPoint(x: -10, y: Stage.ceilY))
    roof.addLine(to: CGPoint(x: Stage.W / 2, y: 70))
    roof.addLine(to: CGPoint(x: Stage.W + 10, y: Stage.ceilY))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.62, green: 0.32, blue: 0.28)))
    ctx.stroke(roof, with: .color(Color(red: 0.40, green: 0.20, blue: 0.18)), lineWidth: 4)

    for room in Stage.rooms {
        let r = CGRect(x: room.x0, y: Stage.ceilY, width: room.x1 - room.x0, height: Stage.floorY - Stage.ceilY)
        fill(ctx, r, room.wall.color)
        fill(ctx, CGRect(x: room.x0, y: Stage.floorY - 10, width: r.width, height: 10), Color(white: 0.97))
        ctx.draw(Text(room.name).font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.45)),
                 at: CGPoint(x: room.x0 == 0 ? 340 : (room.x0 + room.x1) / 2, y: Stage.ceilY + 18))
    }
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 14), Color(red: 0.55, green: 0.38, blue: 0.22))

    drawBed(ctx, x: beds[0].x, width: beds[0].width, blanket: beds[0].blanket)
    drawBathroom(ctx)
    drawLivingRoom(ctx, doorOpen: now < d.doorOpenUntil)
    for b in beds.dropFirst() { drawBed(ctx, x: b.x, width: b.width, blanket: b.blanket) }
    // A teddy bear on Rosie's bed, a plant for Mia, a lamp for Mom
    ctx.fill(circle(CGPoint(x: 1112, y: Stage.floorY - 56), 7), with: .color(Color(red: 0.70, green: 0.48, blue: 0.28)))
    ctx.fill(circle(CGPoint(x: 1112, y: Stage.floorY - 66), 5), with: .color(Color(red: 0.70, green: 0.48, blue: 0.28)))
    fill(ctx, CGRect(x: 1070, y: Stage.floorY - 34, width: 16, height: 24), Color(red: 0.75, green: 0.40, blue: 0.25), corner: 3)
    for (x, y) in [(-6.0, -50.0), (4.0, -58.0), (10.0, -46.0)] {
        ctx.fill(Path(ellipseIn: CGRect(x: 1078 + x - 7, y: Stage.floorY + y, width: 14, height: 24)), with: .color(Color(red: 0.25, green: 0.60, blue: 0.30)))
    }
    fill(ctx, CGRect(x: 556, y: Stage.floorY - 108, width: 22, height: 18), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 565, y: Stage.floorY - 90, width: 4, height: 80), .gray)

    drawMirror(ctx)

    // Partitions with doorways
    for room in Stage.rooms.dropFirst() {
        fill(ctx, CGRect(x: room.x0 - 5, y: Stage.ceilY, width: 10, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.72, green: 0.70, blue: 0.66))
    }
    ctx.stroke(Path(CGRect(x: 0, y: Stage.ceilY, width: Stage.W, height: Stage.floorY - Stage.ceilY)),
               with: .color(Color(red: 0.35, green: 0.33, blue: 0.30)), lineWidth: 8)
}

/// Mom's, Ava's, Mia's and Rosie's beds, in cast order.
private let beds: [(x: Double, width: Double, blanket: Color)] = [
    (452, 100, Color(red: 0.95, green: 0.50, blue: 0.45)),
    (870, 82, Color(red: 0.25, green: 0.60, blue: 0.60)),
    (985, 82, Color(red: 0.55, green: 0.40, blue: 0.80)),
    (1100, 72, Color(red: 0.98, green: 0.55, blue: 0.75)),
]

/// The aunt and cousin on a sleepover, if they're staying tonight.
@MainActor private func sleepers(_ d: Director) -> [Person] {
    d.sleepover ? [d.aunt, d.cousin].compactMap { $0 } : []
}

/// Air mattresses on the living-room floor for sleepover guests: the aunt's, then the cousin's.
private let mattresses: [(x: Double, width: Double, blanket: Color)] = [
    (692, 72, Color(red: 0.40, green: 0.55, blue: 0.90)),
    (767, 48, Color(red: 0.98, green: 0.70, blue: 0.30)),
]

/// A sleepover guest asleep on an air mattress, tucked into a sleeping bag.
private func drawOnMattress(_ ctx: GraphicsContext, _ p: Person, _ m: (x: Double, width: Double, blanket: Color), now: Date) {
    fill(ctx, CGRect(x: m.x, y: Stage.floorY - 18, width: m.width, height: 18), Color(red: 0.70, green: 0.82, blue: 0.95), corner: 7)
    fill(ctx, CGRect(x: m.x + 4, y: Stage.floorY - 26, width: 22, height: 11), Color(white: 0.96), corner: 5)
    let scale = (m.width - 8) / p.height
    var r = ctx
    r.translateBy(x: m.x + m.width - 4, y: Stage.floorY - 16)
    r.rotate(by: .degrees(-90))
    r.scaleBy(x: scale, y: scale)
    drawPerson(r, p, feet: .zero, facing: 0, now: now)
    fill(ctx, CGRect(x: m.x + 26, y: Stage.floorY - 26, width: m.width - 28, height: 20), m.blanket, corner: 6)
}

/// Someone asleep: lying on her bed, head on the pillow, tucked in under the blanket.
private func drawAsleep(_ ctx: GraphicsContext, _ p: Person, bed: (x: Double, width: Double, blanket: Color), now: Date) {
    let scale = (bed.width - 10) / p.height
    var r = ctx
    r.translateBy(x: bed.x + bed.width - 4, y: Stage.floorY - 40)
    r.rotate(by: .degrees(-90))
    r.scaleBy(x: scale, y: scale)
    drawPerson(r, p, feet: .zero, facing: 0, now: now)
    fill(ctx, CGRect(x: bed.x + 32, y: Stage.floorY - 50, width: bed.width - 36, height: 30), bed.blanket, corner: 6)
}

private func drawBed(_ ctx: GraphicsContext, x: Double, width: Double, blanket: Color) {
    let wood = Color(red: 0.60, green: 0.42, blue: 0.26)
    fill(ctx, CGRect(x: x, y: Stage.floorY - 80, width: 10, height: 80), wood, corner: 2)
    fill(ctx, CGRect(x: x + width - 8, y: Stage.floorY - 55, width: 8, height: 55), wood, corner: 2)
    fill(ctx, CGRect(x: x + 5, y: Stage.floorY - 44, width: width - 8, height: 22), .white, corner: 6)
    fill(ctx, CGRect(x: x + 10, y: Stage.floorY - 52, width: 24, height: 12), Color(white: 0.96), corner: 5)
    fill(ctx, CGRect(x: x + 32, y: Stage.floorY - 46, width: width - 36, height: 26), blanket, corner: 6)
}

/// Tiled bathroom with a tub, toilet and sink. The shelf is full of hair products.
private func drawBathroom(_ ctx: GraphicsContext) {
    let floor = Stage.floorY
    let x0 = 582.0
    for row in 0..<5 {
        for col in 0..<9 {
            fill(ctx, CGRect(x: x0 + Double(col) * 12, y: floor - 70 + Double(row) * 12, width: 11, height: 11), Color(red: 0.88, green: 0.95, blue: 0.98))
        }
    }
    fill(ctx, CGRect(x: x0 + 4, y: floor - 42, width: 46, height: 32), .white, corner: 8)
    fill(ctx, CGRect(x: x0 + 4, y: floor - 150, width: 48, height: 3), Color(white: 0.65))
    for i in 0..<5 {
        fill(ctx, CGRect(x: x0 + 5 + Double(i) * 6, y: floor - 147, width: 5, height: 95),
             (i % 2 == 0 ? Color(red: 0.55, green: 0.80, blue: 0.95) : Color(red: 0.95, green: 0.95, blue: 1)).opacity(0.9))
    }
    fill(ctx, CGRect(x: x0 + 58, y: floor - 58, width: 18, height: 22), .white, corner: 3)
    fill(ctx, CGRect(x: x0 + 54, y: floor - 34, width: 24, height: 10), .white, corner: 5)
    fill(ctx, CGRect(x: x0 + 60, y: floor - 26, width: 13, height: 16), .white, corner: 2)
    fill(ctx, CGRect(x: x0 + 89, y: floor - 60, width: 8, height: 50), .white)
    fill(ctx, CGRect(x: x0 + 82, y: floor - 70, width: 22, height: 12), .white, corner: 5)
    fill(ctx, CGRect(x: x0 + 84, y: floor - 125, width: 20, height: 34), Color(red: 0.80, green: 0.92, blue: 1), corner: 3)
    // Shampoo shelf
    fill(ctx, CGRect(x: x0 + 56, y: floor - 150, width: 46, height: 3), Color(white: 0.6))
    for (i, c) in [Color.purple, .pink, .orange, .teal, .yellow].enumerated() {
        fill(ctx, CGRect(x: x0 + 58 + Double(i) * 9, y: floor - 166, width: 7, height: 16), c.opacity(0.85), corner: 2)
    }
}

private func drawLivingRoom(_ ctx: GraphicsContext, doorOpen: Bool) {
    fill(ctx, CGRect(x: 705, y: 240, width: 60, height: 60), Color(red: 0.65, green: 0.85, blue: 1), corner: 3)
    ctx.stroke(Path(CGRect(x: 705, y: 240, width: 60, height: 60)), with: .color(.white), lineWidth: 5)
    let couch = Color(red: 0.80, green: 0.45, blue: 0.35)
    fill(ctx, CGRect(x: 700, y: Stage.floorY - 60, width: 88, height: 35), couch, corner: 10)
    fill(ctx, CGRect(x: 696, y: Stage.floorY - 38, width: 96, height: 30), couch.opacity(0.85), corner: 8)

    let door = CGRect(x: Stage.doorX - 25, y: Stage.floorY - 150, width: 50, height: 150)
    fill(ctx, door.insetBy(dx: -5, dy: -5), .white)
    if doorOpen {
        fill(ctx, door, Color(red: 0.55, green: 0.80, blue: 0.45))
        fill(ctx, CGRect(x: door.minX, y: door.minY, width: 14, height: door.height), Color(red: 0.45, green: 0.28, blue: 0.18))
    } else {
        fill(ctx, door, Color(red: 0.45, green: 0.28, blue: 0.18))
        ctx.fill(Path(ellipseIn: CGRect(x: door.maxX - 14, y: door.midY, width: 8, height: 8)), with: .color(.yellow))
    }
}

private func drawMirror(_ ctx: GraphicsContext) {
    let m = Stage.mirror
    fill(ctx, m.insetBy(dx: -6, dy: -6), Color(red: 0.85, green: 0.68, blue: 0.25), corner: 30)
    ctx.fill(Path(roundedRect: m, cornerRadius: 26),
             with: .linearGradient(Gradient(colors: [Color(red: 0.88, green: 0.96, blue: 1), Color(red: 0.70, green: 0.84, blue: 0.95)]),
                                   startPoint: CGPoint(x: m.minX, y: m.minY), endPoint: CGPoint(x: m.maxX, y: m.maxY)))
}

private func drawReflection(_ ctx: GraphicsContext, _ p: Person, now: Date, slot: Int = 0, of count: Int = 1) {
    let m = Stage.mirror
    var r = ctx
    r.clip(to: Path(roundedRect: m, cornerRadius: 26))
    r.opacity = 0.9
    let scale = count == 1 ? 0.8 : 0.68
    // The nearest person shows up on the mirror's right, the others to her left.
    let x = m.maxX - m.width * (Double(slot) + 0.5) / Double(count)
    r.translateBy(x: x, y: m.maxY + p.height * 0.28 * scale / 0.75)
    r.scaleBy(x: scale, y: scale)
    drawPerson(r, p, feet: .zero, facing: -p.facing, now: now, reflection: true)
    var sheen = Path()
    sheen.move(to: CGPoint(x: m.minX + 12, y: m.minY + 40))
    sheen.addLine(to: CGPoint(x: m.minX + 30, y: m.minY + 18))
    ctx.stroke(sheen, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
}

// MARK: Booth

private let boothFrame = Color(red: 0.16, green: 0.18, blue: 0.24)
private let glow = Color(red: 0.45, green: 1.0, blue: 0.45)
private let beamGreen = Color(red: 0.40, green: 1.0, blue: 0.45)

private var boothInner: CGRect {
    let b = Stage.booth
    return CGRect(x: b.minX + 10, y: b.minY + 30, width: b.width - 20, height: b.height - 30)
}

private func drawBoothBack(_ ctx: GraphicsContext, d: Director, now: Date) {
    let b = Stage.booth
    let inner = boothInner
    let t = now.timeIntervalSinceReferenceDate

    // Neon sign on the wall above
    let sign = CGRect(x: b.minX + 14, y: b.minY - 40, width: b.width - 28, height: 30)
    fill(ctx, sign, Color(red: 0.08, green: 0.10, blue: 0.14), corner: 6)
    let pulse = 0.75 + 0.25 * sin(t * 3)
    ctx.stroke(Path(roundedRect: sign, cornerRadius: 6), with: .color(glow.opacity(pulse)), lineWidth: 2.5)
    ctx.draw(Text("ROSWELL TRANSFORMATION").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(glow.opacity(pulse)),
             at: CGPoint(x: sign.midX, y: sign.midY))

    fill(ctx, b, boothFrame, corner: 10)
    // A dark, starry chamber with green-lit wall panels
    ctx.fill(Path(inner), with: .linearGradient(Gradient(colors: [Color(red: 0.10, green: 0.10, blue: 0.22), Color(red: 0.18, green: 0.22, blue: 0.30)]),
                                                startPoint: CGPoint(x: 0, y: inner.minY), endPoint: CGPoint(x: 0, y: inner.maxY)))
    for i in 0..<18 {
        let k = Double(i)
        let star = CGPoint(x: inner.minX + inner.width * ((k * 0.618).truncatingRemainder(dividingBy: 1)),
                           y: inner.minY + 8 + (inner.height - 70) * ((k * 0.377).truncatingRemainder(dividingBy: 1)))
        ctx.fill(circle(star, 1 + 0.6 * sin(t * 2 + k)), with: .color(.white.opacity(0.55)))
    }
    for col in 0..<Int(inner.width / 45) {
        let panel = CGRect(x: inner.minX + 6 + Double(col) * 45, y: inner.maxY - 62, width: 36, height: 50)
        ctx.stroke(Path(roundedRect: panel, cornerRadius: 4), with: .color(glow.opacity(0.25)), lineWidth: 1)
        ctx.fill(circle(CGPoint(x: panel.midX, y: panel.minY + 8), 2.5), with: .color(glow.opacity(0.4 + 0.4 * sin(t * 3 + Double(col)))))
    }
    fill(ctx, CGRect(x: inner.minX, y: inner.maxY - 8, width: inner.width, height: 8), Color(white: 0.35))
    // A glowing landing ring under each chair
    for x in Stage.seatX {
        ctx.stroke(Path(ellipseIn: CGRect(x: x - 30, y: inner.maxY - 9, width: 60, height: 8)), with: .color(glow.opacity(0.6)), lineWidth: 1.5)
    }
    // Header with the status screen
    let head = CGRect(x: b.minX, y: b.minY, width: b.width, height: 30)
    fill(ctx, head, Color(red: 0.08, green: 0.10, blue: 0.14), corner: 8)
    ctx.draw(Text("ROSWELL-O-MATIC").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(glow),
             at: CGPoint(x: head.minX + 14, y: head.midY), anchor: .leading)
    let scr = CGRect(x: head.maxX - 104, y: head.minY + 6, width: 94, height: 18)
    fill(ctx, scr, .black, corner: 3)
    ctx.draw(Text(d.screenText(now)).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.green),
             at: CGPoint(x: scr.midX, y: scr.midY))

    // Three silver chairs facing right
    let chair = Color(red: 0.72, green: 0.75, blue: 0.82)
    let seatY = Stage.floorY - 30
    for x in Stage.seatX {
        fill(ctx, CGRect(x: x - 36, y: seatY - 70, width: 10, height: 78), chair, corner: 5)
        fill(ctx, CGRect(x: x - 27, y: seatY, width: 56, height: 8), chair, corner: 4)
        fill(ctx, CGRect(x: x - 3, y: seatY + 8, width: 6, height: 17), Color(white: 0.5))
        fill(ctx, CGRect(x: x - 20, y: Stage.floorY - 6, width: 40, height: 5), Color(white: 0.4), corner: 2)
    }

    // The glowing green button on its post
    let bt = Stage.button
    fill(ctx, CGRect(x: bt.x - 5, y: bt.y + 4, width: 10, height: Stage.floorY - bt.y - 4), Color(white: 0.45), corner: 2)
    fill(ctx, CGRect(x: bt.x - 11, y: bt.y - 3, width: 22, height: 9), Color(white: 0.3), corner: 3)
    let pressed = now.timeIntervalSince(d.pressT0)
    let lit = d.beamPeople.isEmpty || (pressed >= 0 && pressed < 0.4)
    let gl = lit ? 0.55 + 0.45 * sin(t * 4) : 0.15
    ctx.fill(circle(bt, 16), with: .radialGradient(Gradient(colors: [beamGreen.opacity(gl * 0.7), .clear]), center: bt, startRadius: 3, endRadius: 16))
    ctx.fill(circle(bt, 6.5), with: .color(lit ? Color(red: 0.3, green: 1, blue: 0.35) : Color(red: 0.1, green: 0.35, blue: 0.12)))
    ctx.fill(circle(CGPoint(x: bt.x - 2, y: bt.y - 2), 2), with: .color(.white.opacity(0.7)))
}

/// Where a chair's beam emitter is: resting up under the header, or lowered just above the sitter's head.
private func emitterGeometry(_ d: Director, seat x: Double, now: Date) -> (center: CGPoint, r: Double, sitter: Person?) {
    let rest = CGPoint(x: x, y: boothInner.minY + 18)
    guard let p = d.beamPeople.first(where: { abs($0.x(at: now) - x) < 2 }) else { return (rest, 26, nil) }
    let pose = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: p.facing, now: now)
    // Stop above where the alien head will finish growing, so it never pokes into the emitter.
    let target = CGPoint(x: x, y: pose.head.y - pose.hr * 2.1)
    let t = now.timeIntervalSince(d.boothT0)
    let (phase, u) = BoothRun.phase(t)
    func ease(_ u: Double) -> Double { u * u * (3 - 2 * u) }
    let down: Double = switch phase {
    case .lowering: ease(u)
    case .lifting: 1 - ease(u)
    case .done: 0
    default: 1
    }
    let c = CGPoint(x: x, y: rest.y + (max(rest.y, target.y) - rest.y) * down)
    return (c, 26 + (max(26, pose.hr * 2.2) - 26) * down, p)
}

private func drawEmitters(_ ctx: GraphicsContext, d: Director, now: Date) {
    for x in Stage.seatX { drawEmitter(ctx, d: d, seat: x, now: now) }
}

/// One chair's flying-saucer emitter, and the green beam it shines down over whoever is sitting there.
private func drawEmitter(_ ctx: GraphicsContext, d: Director, seat: Double, now: Date) {
    let (c, r, sitter) = emitterGeometry(d, seat: seat, now: now)
    // The beam glows the colour she's turning.
    let beamGreen = (sitter?.alienColor ?? .green).beam.color
    let tt = now.timeIntervalSinceReferenceDate
    let (phase, u) = sitter == nil ? (BoothRun.Phase.done, 1.0) : BoothRun.phase(now.timeIntervalSince(d.boothT0))
    let floor = Stage.floorY - 4

    // How bright the beam is: it builds while charging, blazes, then fades through the sparkles.
    let beam: Double = switch phase {
    case .charging: u * 0.35
    case .beaming: 0.55 + 0.15 * sin(tt * 7)
    case .sparkling: 0.5 * (1 - u)
    default: 0
    }
    if beam > 0 {
        var cone = Path()
        cone.move(to: CGPoint(x: c.x - r * 0.55, y: c.y + 4))
        cone.addLine(to: CGPoint(x: c.x + r * 0.55, y: c.y + 4))
        cone.addLine(to: CGPoint(x: c.x + r * 1.25, y: floor))
        cone.addLine(to: CGPoint(x: c.x - r * 1.25, y: floor))
        cone.closeSubpath()
        ctx.fill(cone, with: .linearGradient(Gradient(colors: [beamGreen.opacity(beam * 0.75), beamGreen.opacity(beam * 0.25)]),
                                             startPoint: CGPoint(x: c.x, y: c.y), endPoint: CGPoint(x: c.x, y: floor)))
        // Scanning rings slide down the beam.
        var inside = ctx
        inside.clip(to: cone)
        for i in 0..<4 {
            let k = (tt * 0.7 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
            let y = c.y + (floor - c.y) * k
            let w = r * (0.55 + 0.7 * k)
            inside.stroke(Path(ellipseIn: CGRect(x: c.x - w, y: y - 4, width: w * 2, height: 8)),
                          with: .color(.white.opacity(beam * 0.8 * sin(k * .pi))), lineWidth: 1.5)
        }
    }
    if phase == .beaming || phase == .sparkling {
        // Sparkles rising around the sitter
        let fade = phase == .sparkling ? 1 - u : 1
        for i in 0..<14 {
            let k = Double(i)
            let rise = (tt * 0.5 + k * 0.071).truncatingRemainder(dividingBy: 1)
            let x = c.x + sin(k * 2.3 + tt) * r * (0.6 + 0.4 * rise)
            let y = floor - (floor - c.y) * rise
            let s = 2.5 + 1.5 * sin(tt * 6 + k)
            var star = Path()
            star.move(to: CGPoint(x: x - s, y: y)); star.addLine(to: CGPoint(x: x + s, y: y))
            star.move(to: CGPoint(x: x, y: y - s)); star.addLine(to: CGPoint(x: x, y: y + s))
            ctx.stroke(star, with: .color(.white.opacity(0.9 * fade * sin(rise * .pi))), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        }
    }
    if phase == .cooling {
        // A puff of cool mist drifts off the emitter.
        let fade = min(1, u * 5, (1 - u) * 5)
        for i in 0..<6 {
            let k = Double(i)
            let drift = (tt * 0.6 + k / 6).truncatingRemainder(dividingBy: 1)
            let pt = CGPoint(x: c.x + (k - 2.5) * r * 0.3 + sin(tt + k) * 4, y: c.y + 6 + drift * 40)
            ctx.fill(circle(pt, 5 + drift * 8), with: .color(.white.opacity(0.35 * fade * (1 - drift))))
        }
    }

    // Telescoping arm from the ceiling
    let top = boothInner.minY
    fill(ctx, CGRect(x: c.x - 4, y: top, width: 8, height: c.y - top), Color(white: 0.55))
    fill(ctx, CGRect(x: c.x - 7, y: top, width: 14, height: 10), Color(white: 0.4), corner: 2)

    // The saucer-shaped emitter: a silver disc, a glass bubble, and a ring of blinking lights.
    let charged: Double = switch phase {
    case .charging: u
    case .beaming, .sparkling: 1
    case .cooling: 1 - u
    default: 0
    }
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.45, y: c.y - r * 0.42, width: r * 0.9, height: r * 0.6)),
             with: .color(Color(red: 0.7, green: 0.95, blue: 0.75).opacity(0.75)))
    let disc = CGRect(x: c.x - r, y: c.y - r * 0.18, width: r * 2, height: r * 0.36)
    ctx.fill(Path(ellipseIn: disc), with: .linearGradient(Gradient(colors: [Color(white: 0.85), Color(white: 0.45)]),
                                                         startPoint: CGPoint(x: 0, y: disc.minY), endPoint: CGPoint(x: 0, y: disc.maxY)))
    ctx.stroke(Path(ellipseIn: disc), with: .color(Color(white: 0.3)), lineWidth: 1)
    for i in 0..<5 {
        let k = Double(i)
        let blink = 0.3 + 0.7 * charged * (0.5 + 0.5 * sin(tt * 10 + k * 1.3))
        ctx.fill(circle(CGPoint(x: c.x + (k - 2) * r * 0.36, y: c.y + r * 0.04), max(1.5, r * 0.07)),
                 with: .color(glow.opacity(sitter == nil ? 0.45 : blink)))
    }
    if charged > 0 {
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.5, y: c.y + r * 0.08, width: r, height: r * 0.25)),
                 with: .radialGradient(Gradient(colors: [beamGreen.opacity(charged), .clear]), center: CGPoint(x: c.x, y: c.y + r * 0.2),
                                       startRadius: 1, endRadius: r * 0.5))
    }
}

private func drawBoothFront(_ ctx: GraphicsContext, d: Director) {
    let b = Stage.booth
    let inner = boothInner
    let glass = Color(red: 0.70, green: 0.88, blue: 1)
    if d.boothClosed {
        fill(ctx, inner, glass.opacity(0.12), corner: 3)
        for k in [0.15, 0.22] {
            var sheen = Path()
            sheen.move(to: CGPoint(x: inner.minX + inner.width * k, y: inner.minY + 20))
            sheen.addLine(to: CGPoint(x: inner.minX + inner.width * (k + 0.08), y: inner.minY + 4))
            ctx.stroke(sheen, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    } else {
        var door = Path()
        door.move(to: CGPoint(x: b.maxX, y: inner.minY))
        door.addLine(to: CGPoint(x: b.maxX + 26, y: inner.minY + 10))
        door.addLine(to: CGPoint(x: b.maxX + 26, y: inner.maxY - 6))
        door.addLine(to: CGPoint(x: b.maxX, y: inner.maxY))
        door.closeSubpath()
        ctx.fill(door, with: .color(glass.opacity(0.4)))
        ctx.stroke(door, with: .color(Color(white: 0.6)), lineWidth: 2)
    }
    fill(ctx, CGRect(x: b.minX, y: b.minY + 20, width: 10, height: b.height - 20), boothFrame)
    fill(ctx, CGRect(x: b.maxX - 10, y: b.minY + 20, width: 10, height: b.height - 20), boothFrame)
}

// MARK: Overlays

/// Green-and-white twinkles swirling around someone as the change wears off.
private func drawChangeSparkles(_ ctx: GraphicsContext, _ p: Person, now: Date) {
    let x = p.x(at: now)
    let tt = now.timeIntervalSinceReferenceDate
    for i in 0..<12 {
        let k = Double(i)
        let rise = (tt * 0.6 + k / 12).truncatingRemainder(dividingBy: 1)
        let pt = CGPoint(x: x + sin(k * 2.1 + tt * 2) * p.height * 0.28, y: Stage.floorY - p.height * 1.1 * rise)
        let s = 2.5 + 1.5 * sin(tt * 7 + k)
        var star = Path()
        star.move(to: CGPoint(x: pt.x - s, y: pt.y)); star.addLine(to: CGPoint(x: pt.x + s, y: pt.y))
        star.move(to: CGPoint(x: pt.x, y: pt.y - s)); star.addLine(to: CGPoint(x: pt.x, y: pt.y + s))
        ctx.stroke(star, with: .color((i.isMultiple(of: 2) ? glow : .white).opacity(0.9 * sin(rise * .pi))),
                   style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
}

/// A speech bubble over her head, drawn in screen space: it follows her through the camera, grows a little
/// in close-ups (never more than double) and stays inside the frame even when her head fills the screen.
/// Bubbles that would cover one already drawn are stacked above it. Returns where it went.
@discardableResult
private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, now: Date, cam: CGRect, avoiding others: [CGRect] = []) -> CGRect? {
    guard let text = p.says, now < p.saysUntil else { return nil }
    let zoom = Stage.W / cam.width
    let k = min(zoom, 2)
    let x = p.x(at: now)
    let pose = Pose(p, feet: CGPoint(x: x, y: Stage.feetY(p)), facing: p.facing, now: now)
    // Where the top of her head is on screen; skip anyone the camera has left out.
    let anchor = CGPoint(x: (x - cam.minX) * zoom, y: (pose.headTop - cam.minY) * zoom)
    guard anchor.x > -20 && anchor.x < Stage.W + 20 && anchor.y < Stage.H else { return nil }

    let resolved = ctx.resolve(Text(text).font(.system(size: 15 * k, weight: .medium, design: .rounded)).foregroundStyle(.black))
    let size = resolved.measure(in: CGSize(width: 220 * k, height: 200 * k))
    var box = CGRect(x: anchor.x - size.width / 2 - 10 * k, y: anchor.y - size.height - 30 * k,
                     width: size.width + 20 * k, height: size.height + 14 * k)
    box.origin.x = min(max(box.minX, 6), Stage.W - box.width - 6)
    box.origin.y = min(max(box.minY, 6), Stage.H - box.height - 70)
    // Stack above any bubble it would cover; if there's no room above, go below instead.
    for _ in 0..<others.count {
        guard let hit = others.first(where: { $0.insetBy(dx: -2, dy: -2).intersects(box) }) else { break }
        box.origin.y = hit.minY - box.height - 6 >= 6 ? hit.minY - box.height - 6 : hit.maxY + 6
    }
    let tipX = min(max(anchor.x, box.minX + 16 * k), box.maxX - 16 * k)

    var bubble = Path(roundedRect: box, cornerRadius: 10 * k)
    bubble.move(to: CGPoint(x: tipX - 7 * k, y: box.maxY - 1))
    bubble.addLine(to: CGPoint(x: tipX, y: box.maxY + 12 * k))
    bubble.addLine(to: CGPoint(x: tipX + 7 * k, y: box.maxY - 1))
    ctx.fill(bubble, with: .color(.white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10 * k), with: .color(.black.opacity(0.35)), lineWidth: 1.5)
    ctx.draw(resolved, in: box.insetBy(dx: 10 * k, dy: 7 * k))
    return box
}

/// The booth's instructions, drawn over whatever the camera shows.
private func drawSignCard(_ ctx: GraphicsContext) {
    let card = CGRect(x: 330, y: 30, width: 540, height: 200)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 14)
    fill(ctx, card, Color(red: 0.10, green: 0.14, blue: 0.18), corner: 14)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 14), with: .color(glow), lineWidth: 3)
    ctx.draw(Text("ROSWELL TRANSFORMATION MACHINE").font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(glow),
             at: CGPoint(x: card.midX, y: card.minY + 30))
    let steps = ["1. Up to 3 people: sit in the chairs", "2. Press the glowing green button", "3. The emitters lower and charge up",
                 "4. One minute in the green beam", "5. Sparkles set the change", "6. Enjoy being a Roswell alien!"]
    for (i, s) in steps.enumerated() {
        ctx.draw(Text(s).font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.92)),
                 at: CGPoint(x: card.minX + 40, y: card.minY + 62 + Double(i) * 23), anchor: .leading)
    }
    let head = CGPoint(x: card.maxX - 70, y: card.minY + 130)
    ctx.fill(headShape(head, hr: 30, alien: 1).path, with: .color(Person.alienSkin.color))
    drawAlienEyes(ctx, head: head, hr: 30, alien: 1)
}

/// Who is still human, top right.
private func drawHUD(_ ctx: GraphicsContext, d: Director, now: Date) {
    guard d.cast.contains(where: \.alien) || !d.beamPeople.isEmpty else { return }
    for (i, p) in d.cast.enumerated() {
        let r = CGRect(x: Stage.W - 150, y: 12 + Double(i) * 30, width: 138, height: 25)
        fill(ctx, r, .black.opacity(0.55), corner: 12.5)
        ctx.draw(Text(p.id).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: r.minX + 12, y: r.midY), anchor: .leading)
        let level = p.alienLevel(at: now)
        let (label, color): (String, Color) = level >= 1 ? ("ALIEN", glow) : level > 0 ? ("\(Int(level * 100))% alien", .orange) : ("human", .white.opacity(0.6))
        ctx.draw(Text(label).font(.system(size: 12, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(color),
                 at: CGPoint(x: r.maxX - 12, y: r.midY), anchor: .trailing)
    }
}

// MARK: Town

/// Main Street, where Mom shops with her sister, buys groceries and makes a deposit at the bank.
private func drawTown(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let floor = Stage.floorY
    drawSky(ctx)
    // Sidewalk, curb and road
    fill(ctx, CGRect(x: 0, y: floor, width: Stage.W, height: 24), Color(white: 0.80))
    for x in stride(from: 0.0, to: Stage.W, by: 50) { fill(ctx, CGRect(x: x, y: floor, width: 1.5, height: 24), Color(white: 0.70)) }
    fill(ctx, CGRect(x: 0, y: floor + 24, width: Stage.W, height: 8), Color(white: 0.6))
    fill(ctx, CGRect(x: 0, y: floor + 32, width: Stage.W, height: Stage.H - floor - 32), Color(white: 0.30))
    for x in stride(from: 20.0, to: Stage.W, by: 90) { fill(ctx, CGRect(x: x, y: floor + 62, width: 44, height: 5), Color(red: 1, green: 0.85, blue: 0.2)) }

    // Bella's Boutique: pink front, scalloped awning, dresses in the window
    let shop = CGRect(x: 60, y: 250, width: 330, height: floor - 250)
    fill(ctx, shop, Color(red: 0.98, green: 0.84, blue: 0.90))
    fill(ctx, CGRect(x: shop.minX - 8, y: shop.minY - 10, width: shop.width + 16, height: 14), Color(red: 0.75, green: 0.35, blue: 0.55))
    fill(ctx, CGRect(x: shop.minX + 40, y: shop.minY + 14, width: 250, height: 42), Color(red: 0.85, green: 0.30, blue: 0.55), corner: 6)
    ctx.draw(Text("BELLA'S BOUTIQUE").font(.system(size: 22, weight: .black, design: .serif)).foregroundStyle(.white),
             at: CGPoint(x: shop.midX, y: shop.minY + 35))
    for k in 0..<11 {
        let x = shop.minX + Double(k) * 30
        fill(ctx, CGRect(x: x, y: shop.minY + 66, width: 30, height: 20), k % 2 == 0 ? Color(red: 0.85, green: 0.30, blue: 0.55) : .white)
        ctx.fill(circle(CGPoint(x: x + 15, y: shop.minY + 86), 15), with: .color(k % 2 == 0 ? Color(red: 0.85, green: 0.30, blue: 0.55) : .white))
    }
    let window = CGRect(x: shop.minX + 22, y: shop.minY + 116, width: 110, height: 90)
    fill(ctx, window, Color(red: 0.80, green: 0.90, blue: 0.97))
    for (i, c) in [Color.purple, .red, .teal].enumerated() {
        let cx = window.minX + 22 + Double(i) * 33
        var dress = Path()
        dress.move(to: CGPoint(x: cx - 6, y: window.minY + 16))
        dress.addLine(to: CGPoint(x: cx + 6, y: window.minY + 16))
        dress.addLine(to: CGPoint(x: cx + 14, y: window.maxY - 12))
        dress.addLine(to: CGPoint(x: cx - 14, y: window.maxY - 12))
        dress.closeSubpath()
        ctx.fill(dress, with: .color(c.opacity(0.8)))
        ctx.fill(circle(CGPoint(x: cx, y: window.minY + 10), 5), with: .color(Color(white: 0.85)))
    }
    ctx.stroke(Path(window), with: .color(.white), lineWidth: 4)
    shopDoor(ctx, x: Stage.boutiqueDoorX, color: Color(red: 0.85, green: 0.30, blue: 0.55))

    // The grocery store
    let store = CGRect(x: 430, y: 230, width: 360, height: floor - 230)
    fill(ctx, store, Color(red: 0.93, green: 0.88, blue: 0.78))
    fill(ctx, CGRect(x: store.minX - 8, y: store.minY - 10, width: store.width + 16, height: 14), Color(red: 0.55, green: 0.38, blue: 0.25))
    fill(ctx, CGRect(x: store.minX + 50, y: store.minY + 14, width: 260, height: 44), Color(red: 0.20, green: 0.50, blue: 0.25), corner: 6)
    ctx.draw(Text("FRESH MARKET").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: store.midX, y: store.minY + 36))
    for k in 0..<9 {
        fill(ctx, CGRect(x: store.minX + Double(k) * 40, y: store.minY + 70, width: 40, height: 26),
             k % 2 == 0 ? Color(red: 0.20, green: 0.60, blue: 0.30) : .white)
    }
    for wx in [store.minX + 20, store.maxX - 130] {
        let w = CGRect(x: wx, y: store.minY + 120, width: 110, height: 70)
        fill(ctx, w, Color(red: 0.75, green: 0.88, blue: 0.95))
        for (i, c) in [Color.red, .orange, .yellow, .green, .red, .orange].enumerated() {
            ctx.fill(circle(CGPoint(x: w.minX + 12 + Double(i) * 17, y: w.maxY - 12), 8), with: .color(c))
        }
        ctx.stroke(Path(w), with: .color(.white), lineWidth: 4)
    }
    shopDoor(ctx, x: Stage.storeDoorX, color: Color(red: 0.60, green: 0.80, blue: 0.90))
    for x in [store.maxX - 60, store.maxX - 38] {
        ctx.stroke(Path(CGRect(x: x, y: floor - 32, width: 30, height: 20)), with: .color(Color(white: 0.45)), lineWidth: 2)
        for wx in [x + 5, x + 25] { ctx.fill(circle(CGPoint(x: wx, y: floor - 6), 3), with: .color(Color(white: 0.2))) }
    }

    // The bank: stone front with columns and a pediment
    let bank = CGRect(x: 840, y: 270, width: 300, height: floor - 270)
    let stone = Color(red: 0.88, green: 0.87, blue: 0.84)
    fill(ctx, bank, stone)
    var pediment = Path()
    pediment.move(to: CGPoint(x: bank.minX - 14, y: bank.minY))
    pediment.addLine(to: CGPoint(x: bank.midX, y: bank.minY - 60))
    pediment.addLine(to: CGPoint(x: bank.maxX + 14, y: bank.minY))
    pediment.closeSubpath()
    ctx.fill(pediment, with: .color(Color(red: 0.80, green: 0.79, blue: 0.76)))
    fill(ctx, CGRect(x: bank.minX - 14, y: bank.minY, width: bank.width + 28, height: 26), Color(red: 0.80, green: 0.79, blue: 0.76))
    ctx.draw(Text("FIRST NATIONAL BANK").font(.system(size: 17, weight: .heavy, design: .serif)).foregroundStyle(Color(red: 0.25, green: 0.25, blue: 0.30)),
             at: CGPoint(x: bank.midX, y: bank.minY + 13))
    ctx.draw(Text("$").font(.system(size: 28, weight: .black, design: .serif)).foregroundStyle(Color(red: 0.15, green: 0.50, blue: 0.25)),
             at: CGPoint(x: bank.midX, y: bank.minY - 24))
    for k in 0..<5 {
        let cx = bank.minX + 30 + Double(k) * 60
        guard abs(cx - Stage.bankDoorX) > 40 else { continue }
        fill(ctx, CGRect(x: cx - 11, y: bank.minY + 32, width: 22, height: bank.height - 44), .white)
        for g in 0..<3 { fill(ctx, CGRect(x: cx - 7 + Double(g) * 6, y: bank.minY + 36, width: 1.5, height: bank.height - 52), Color(white: 0.85)) }
    }
    fill(ctx, CGRect(x: bank.minX - 10, y: bank.maxY - 12, width: bank.width + 20, height: 12), Color(red: 0.78, green: 0.77, blue: 0.74))
    let bankDoor = CGRect(x: Stage.bankDoorX - 30, y: floor - 112, width: 60, height: 100)
    ctx.fill(Path(roundedRect: bankDoor, cornerRadius: 30), with: .color(Color(red: 0.40, green: 0.26, blue: 0.16)))
    ctx.fill(circle(CGPoint(x: bankDoor.midX + 18, y: bankDoor.midY + 10), 3), with: .color(.yellow))

    // Street lamps and a little tree
    for x in [410.0, 815.0] {
        fill(ctx, CGRect(x: x - 3, y: floor - 150, width: 6, height: 150), Color(white: 0.2))
        ctx.fill(circle(CGPoint(x: x, y: floor - 154), 9), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
    }
    fill(ctx, CGRect(x: 1162, y: floor - 90, width: 10, height: 90), Color(red: 0.45, green: 0.30, blue: 0.18))
    ctx.fill(circle(CGPoint(x: 1167, y: floor - 110), 30 + sin(t) * 1), with: .color(Color(red: 0.25, green: 0.55, blue: 0.28)))
}

/// A glass shop door with a frame, standing on the sidewalk.
private func shopDoor(_ ctx: GraphicsContext, x: Double, color: Color) {
    let door = CGRect(x: x - 28, y: Stage.floorY - 100, width: 56, height: 100)
    fill(ctx, door, color.opacity(0.6))
    ctx.stroke(Path(door), with: .color(Color(white: 0.4)), lineWidth: 4)
    fill(ctx, CGRect(x: door.midX - 1.5, y: door.minY, width: 3, height: door.height), Color(white: 0.4))
}

// MARK: The guests' street

/// A quiet street: one little house per household, each with a front door at `Stage.guestDoorX`.
/// At night the stars are out and the windows are lit; after the day session it's a sunny afternoon.
private func drawNeighborhood(_ ctx: GraphicsContext, now: Date, day: Bool, home: Bool = false, doorOpen: Bool = false) {
    let floor = Stage.floorY
    let t = now.timeIntervalSinceReferenceDate
    if day {
        drawSky(ctx)
    } else {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
                 with: .linearGradient(Gradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.20), Color(red: 0.20, green: 0.18, blue: 0.40)]),
                                       startPoint: .zero, endPoint: CGPoint(x: 0, y: floor)))
        for i in 0..<45 {
            let x = Double((i * 7919) % 1200), y = Double((i * 104_729) % 230)
            let tw = 0.5 + 0.5 * sin(t * 2 + Double(i))
            ctx.fill(circle(CGPoint(x: x, y: y), 1 + tw), with: .color(.white.opacity(0.35 + 0.5 * tw)))
        }
        ctx.fill(circle(CGPoint(x: 1110, y: 70), 32), with: .color(Color(red: 1, green: 0.97, blue: 0.8)))
        ctx.fill(circle(CGPoint(x: 1124, y: 62), 30), with: .color(Color(red: 0.07, green: 0.08, blue: 0.22)))
    }
    // Lawns, sidewalk and the road
    fill(ctx, CGRect(x: 0, y: floor - 6, width: Stage.W, height: 6), Color(red: 0.14, green: 0.35, blue: 0.18))
    fill(ctx, CGRect(x: 0, y: floor, width: Stage.W, height: 24), Color(white: 0.55))
    fill(ctx, CGRect(x: 0, y: floor + 24, width: Stage.W, height: 8), Color(white: 0.42))
    fill(ctx, CGRect(x: 0, y: floor + 32, width: Stage.W, height: Stage.H - floor - 32), Color(white: 0.18))
    for x in stride(from: 20.0, to: Stage.W, by: 90) { fill(ctx, CGRect(x: x, y: floor + 62, width: 44, height: 5), Color(red: 0.8, green: 0.68, blue: 0.2)) }

    let walls = [Color(red: 0.62, green: 0.70, blue: 0.85), Color(red: 0.88, green: 0.76, blue: 0.55),
                 Color(red: 0.70, green: 0.82, blue: 0.66), Color(red: 0.86, green: 0.62, blue: 0.66)]
    let roofs = [Color(red: 0.30, green: 0.30, blue: 0.45), Color(red: 0.50, green: 0.28, blue: 0.20),
                 Color(red: 0.25, green: 0.40, blue: 0.30), Color(red: 0.45, green: 0.22, blue: 0.35)]
    for (i, x) in Stage.guestDoorX.enumerated() {
        let house = CGRect(x: x - 120, y: floor - 190, width: 240, height: 184)
        fill(ctx, house, walls[i].opacity(0.85))
        var roof = Path()
        roof.move(to: CGPoint(x: house.minX - 18, y: house.minY))
        roof.addLine(to: CGPoint(x: house.midX, y: house.minY - 80))
        roof.addLine(to: CGPoint(x: house.maxX + 18, y: house.minY))
        roof.closeSubpath()
        ctx.fill(roof, with: .color(roofs[i]))
        // Lit windows either side of the door
        for wx in [house.minX + 22, house.maxX - 82] {
            let w = CGRect(x: wx, y: house.minY + 40, width: 60, height: 50)
            fill(ctx, w, day ? Color(red: 0.62, green: 0.80, blue: 0.95) : Color(red: 1, green: 0.88, blue: 0.5))
            ctx.stroke(Path(w), with: .color(.white), lineWidth: 4)
            fill(ctx, CGRect(x: w.midX - 1.5, y: w.minY, width: 3, height: w.height), .white)
        }
        // Front door, house number and porch light
        let door = CGRect(x: x - 26, y: floor - 100, width: 52, height: 94)
        let ours = home && x == Stage.familyDoorX
        if ours && doorOpen {
            // The family's front door stands open for the guests.
            fill(ctx, door, Color(red: 0.98, green: 0.88, blue: 0.62), corner: 3)
            fill(ctx, CGRect(x: door.minX - 8, y: door.minY, width: 10, height: door.height), roofs[i], corner: 2)
        } else {
            fill(ctx, door, roofs[i], corner: 3)
            ctx.fill(circle(CGPoint(x: door.maxX - 10, y: door.midY + 4), 3.5), with: .color(.yellow))
        }
        if ours {
            let plaque = CGRect(x: x - 40, y: house.minY + 8, width: 80, height: 22)
            fill(ctx, plaque, .white, corner: 5)
            ctx.draw(Text("Our House").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color(red: 0.85, green: 0.3, blue: 0.5)),
                     at: CGPoint(x: plaque.midX, y: plaque.midY))
        }
        ctx.draw(Text("\(12 + i * 2)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: x, y: door.minY - 14))
        ctx.fill(circle(CGPoint(x: door.maxX + 16, y: door.minY + 10), 18), with: .color(Color(red: 1, green: 0.9, blue: 0.5).opacity(0.3)))
        ctx.fill(circle(CGPoint(x: door.maxX + 16, y: door.minY + 10), 6), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
    }
}

// MARK: Casino

private let casinoGold = Color(red: 0.85, green: 0.65, blue: 0.15)
private let felt = Color(red: 0.08, green: 0.45, blue: 0.25)

private func drawStandingMirror(_ ctx: GraphicsContext, accent: Color) {
    let m = Stage.mirror
    let wood = Color(red: 0.55, green: 0.38, blue: 0.20)
    for (top, foot) in [(m.minX + 8, m.minX - 8), (m.maxX - 8, m.maxX + 8)] {
        var leg = Path()
        leg.move(to: CGPoint(x: top, y: m.maxY))
        leg.addLine(to: CGPoint(x: foot, y: Stage.floorY))
        ctx.stroke(leg, with: .color(wood), style: StrokeStyle(lineWidth: 6, lineCap: .round))
    }
    drawMirror(ctx)
    let sign = CGRect(x: m.midX - 55, y: m.minY - 36, width: 110, height: 24)
    fill(ctx, sign, .white, corner: 5)
    ctx.stroke(Path(roundedRect: sign, cornerRadius: 5), with: .color(accent), lineWidth: 2)
    ctx.draw(Text("Check your new look!").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(accent),
             at: CGPoint(x: sign.midX, y: sign.midY))
}

/// The casino floor: dark walls, a patterned carpet, slot machines, chandeliers and a marquee.
private func drawCasino(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.16, green: 0.05, blue: 0.12), Color(red: 0.42, green: 0.10, blue: 0.18)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    // Gold pillars
    for x in stride(from: 40.0, through: 1160, by: 280) {
        fill(ctx, CGRect(x: x - 9, y: 60, width: 18, height: Stage.floorY - 60), casinoGold.opacity(0.35))
    }
    // Carpet
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.50, green: 0.08, blue: 0.12))
    for i in 0..<30 {
        for row in 0..<3 {
            let c = CGPoint(x: Double(i) * 42 + (row % 2 == 0 ? 0 : 21), y: Stage.floorY + 22 + Double(row) * 32)
            var diamond = Path()
            diamond.move(to: CGPoint(x: c.x, y: c.y - 9))
            diamond.addLine(to: CGPoint(x: c.x + 9, y: c.y))
            diamond.addLine(to: CGPoint(x: c.x, y: c.y + 9))
            diamond.addLine(to: CGPoint(x: c.x - 9, y: c.y))
            diamond.closeSubpath()
            ctx.fill(diamond, with: .color(casinoGold.opacity(0.45)))
        }
    }
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 6), casinoGold.opacity(0.7))

    // Marquee with chasing lights
    let sign = CGRect(x: 380, y: 22, width: 440, height: 58)
    fill(ctx, sign, Color(red: 0.10, green: 0.03, blue: 0.08), corner: 10)
    for i in 0..<36 {
        let k = Double(i)
        let on = (Int(t * 8) + i) % 3 == 0
        let pt = i < 18 ? CGPoint(x: sign.minX + 12 + k * 24, y: sign.minY + 6) : CGPoint(x: sign.minX + 12 + (k - 18) * 24, y: sign.maxY - 6)
        ctx.fill(circle(pt, 3), with: .color(on ? .yellow : casinoGold.opacity(0.4)))
    }
    ctx.draw(Text(CasinoGame.casinoName.uppercased()).font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(casinoGold),
             at: CGPoint(x: sign.midX, y: sign.midY))

    // Chandeliers
    for x in [250.0, 760.0] {
        fill(ctx, CGRect(x: x - 1, y: 0, width: 2, height: 105), casinoGold)
        ctx.fill(Path(ellipseIn: CGRect(x: x - 40, y: 100, width: 80, height: 22)), with: .color(casinoGold))
        for k in 0..<7 {
            let bx = x - 36 + Double(k) * 12
            ctx.fill(circle(CGPoint(x: bx, y: 128), 4), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
            ctx.fill(circle(CGPoint(x: bx, y: 128), 12), with: .radialGradient(Gradient(colors: [.yellow.opacity(0.35), .clear]),
                                                                            center: CGPoint(x: bx, y: 128), startRadius: 2, endRadius: 12))
        }
    }

    // The way out, top right
    let exit = CGRect(x: 1118, y: 200, width: 64, height: 26)
    fill(ctx, exit, Color(red: 0.05, green: 0.35, blue: 0.12), corner: 4)
    ctx.stroke(Path(roundedRect: exit, cornerRadius: 4), with: .color(.white.opacity(0.8)), lineWidth: 1.5)
    ctx.draw(Text("EXIT →").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: exit.midX, y: exit.midY))

    // A row of slot machines along the back wall on the right
    let colors: [Color] = [.red, .blue, .purple, .orange, .teal]
    for i in 0..<5 {
        let x = 975 + Double(i) * 44
        let m = CGRect(x: x, y: Stage.floorY - 130, width: 38, height: 130)
        fill(ctx, m, colors[i].opacity(0.85), corner: 6)
        fill(ctx, CGRect(x: m.minX + 4, y: m.minY + 6, width: 30, height: 14), .black.opacity(0.6), corner: 3)
        let blink = (Int(t * 2) + i) % 2 == 0
        ctx.draw(Text("777").font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(blink ? .yellow : .white),
                 at: CGPoint(x: m.midX, y: m.minY + 13))
        fill(ctx, CGRect(x: m.minX + 5, y: m.minY + 30, width: 28, height: 22), .white, corner: 3)
        for r in 0..<3 {
            ctx.draw(Text(["🍒", "⭐️", "🔔"][(r + i) % 3]).font(.system(size: 8)), at: CGPoint(x: m.minX + 10 + Double(r) * 9, y: m.minY + 41))
        }
        fill(ctx, CGRect(x: m.maxX - 2, y: m.minY + 30, width: 4, height: 30), Color(white: 0.7))
        ctx.fill(circle(CGPoint(x: m.maxX, y: m.minY + 28), 4), with: .color(.red))
    }
}

/// The card table, drawn over the lower half of whoever stands behind it, with the cards on its felt.
private func drawTable(_ ctx: GraphicsContext, felt cards: [FeltCards]) {
    let t = Stage.table
    let wood = Color(red: 0.35, green: 0.18, blue: 0.08)
    // Pedestal and skirt
    fill(ctx, CGRect(x: t.midX - 20, y: t.minY + 40, width: 40, height: t.height - 46), wood.opacity(0.9))
    fill(ctx, CGRect(x: t.midX - 70, y: Stage.floorY - 8, width: 140, height: 8), wood, corner: 3)
    fill(ctx, CGRect(x: t.minX + 14, y: t.minY + 44, width: t.width - 28, height: 22), wood, corner: 6)
    // Felt top, in perspective, with a padded rail
    let top = CGRect(x: t.minX, y: t.minY, width: t.width, height: 48)
    fill(ctx, top.insetBy(dx: -6, dy: -4), Color(red: 0.25, green: 0.12, blue: 0.06), corner: 26)
    fill(ctx, top, felt, corner: 22)
    ctx.stroke(Path(roundedRect: top.insetBy(dx: 10, dy: 6), cornerRadius: 16), with: .color(casinoGold.opacity(0.5)), lineWidth: 1)
    // Chip stacks off to the dealer's side
    for (i, c) in [Color.red, .blue, .green, .black].enumerated() {
        for k in 0..<3 {
            fill(ctx, CGRect(x: Stage.dealerX + 62 + Double(i) * 9, y: t.minY + 12 - Double(k) * 2.5, width: 8, height: 3), c, corner: 1.5)
        }
    }

    for group in cards { drawCards(ctx, group, rowY: group.back ? t.minY + 4 : t.minY + 24) }
}

private func drawCards(_ ctx: GraphicsContext, _ g: FeltCards, rowY: Double) {
    let (w, h) = (15.0, 20.0)
    let step = g.cards.count > 5 ? 7.5 : 11.0
    let gap = g.splitAt == nil ? 0 : 6.0
    let width = w + step * Double(max(g.cards.count - 1, 0)) + gap
    var x = g.x - width / 2
    for (i, card) in g.cards.enumerated() {
        if i == g.splitAt { x += gap }
        let r = CGRect(x: x, y: rowY, width: w, height: h)
        if g.hidden.contains(i) {
            fill(ctx, r, Color(red: 0.20, green: 0.30, blue: 0.70), corner: 2)
            ctx.stroke(Path(roundedRect: r.insetBy(dx: 2, dy: 2), cornerRadius: 1), with: .color(.white.opacity(0.7)), lineWidth: 0.8)
        } else {
            fill(ctx, r, .white, corner: 2)
            ctx.stroke(Path(roundedRect: r, cornerRadius: 2), with: .color(.black.opacity(0.3)), lineWidth: 0.6)
            let ink: Color = card.isRed ? .red : .black
            ctx.draw(Text(card.rankText).font(.system(size: 7, weight: .heavy, design: .rounded)).foregroundStyle(ink),
                     at: CGPoint(x: r.minX + 1.5, y: r.minY + 1), anchor: .topLeading)
            ctx.draw(Text(card.suitText).font(.system(size: 9)).foregroundStyle(ink), at: CGPoint(x: r.midX + 1, y: r.midY + 3))
        }
        x += step
    }
    if let label = g.label {
        ctx.draw(Text(label).font(.system(size: 7, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.9)),
                 at: CGPoint(x: g.x, y: g.cards.isEmpty ? rowY + 6 : rowY + h + 4.5))
    }
}

private func drawCashPop(_ ctx: GraphicsContext, _ text: String, x: Double, age: Double) {
    guard age >= 0 && age < 2 else { return }
    let color: Color = text.hasPrefix("-") ? .red : Color(red: 0.10, green: 0.60, blue: 0.20)
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(color.opacity(1 - age / 2)),
             at: CGPoint(x: x, y: Stage.floorY - 215 - age * 30))
}
