import SwiftUI

/// World layout, in points. The same 1200×600 stage shows the house and front yard,
/// the inside of the alien clowns' cruise ship, or a venue.
enum Stage {
    static let W = 1200.0
    static let H = 600.0
    static let floorY = 490.0
    static let ceilY = 200.0
    static let doorwayTop = floorY - 175

    /// The house is on the shore: the front yard and driveway run from the beach to the front wall of the house.
    static let frontWallX = 420.0
    static let rooms: [(name: String, x0: Double, x1: Double, wall: RGB)] = [
        ("Living Room", 420, 650, RGB(r: 0.98, g: 0.92, b: 0.78)),
        ("Mom's Room", 650, 835, RGB(r: 0.98, g: 0.85, b: 0.80)),
        ("Kelly & Jen", 835, 1020, RGB(r: 0.80, g: 0.92, b: 0.90)),
        ("Spare Room", 1020, 1200, RGB(r: 0.88, g: 0.84, b: 0.96)),
    ]
    /// Deidre, Kelly, Jen: where each stands by her bed, and in the living room.
    static let roomX = [795.0, 925.0, 1005.0]
    static let livingX = [462.0, 560.0, 605.0]
    static let boyfriendX = 512.0
    /// Left edge and width of each bed: Mom's, then the girls' two little beds side by side.
    static let bedX = [662.0, 842.0, 930.0]
    static let bedW = [100.0, 80.0, 80.0]
    /// The Clowns of Poker cabinet in the spare room, and where the player stands at it.
    static let pokerX = 1110.0
    static var pokerPlayerX: Double { pokerX - 52 }
    /// Where the glowing pink button turns up in the living room, and where the three gather round it.
    static let buttonX = 500.0
    static let buttonSpots = [462.0, 548.0, 590.0]

    /// Deidre's car in the driveway, and the tow truck backed up to it.
    static let carX = 235.0
    static let truckX = 85.0
    /// Where a scooter of their own gets parked, at the street end of the driveway.
    static let scooterX = 70.0

    /// The ship pulls up on the water alongside the house, or ties up at the quay in port.
    static let yardTentX = 150.0
    /// Where the ship rides on the water, at home or in port (the middle of its keel line).
    static let dockY = 420.0
    /// Out of sight down the shore, where the ship sails in from and back out to.
    static let offshoreX = -560.0
    static let venueTentX = 300.0
    /// The gangway runs from the deck rail (this far right of the ship's middle) down to the ground (this far right).
    static let gangwayTopDX = 105.0
    static let gangwayFootDX = 245.0
    /// Where the family lines up in the front yard.
    static let yardLine = [150.0, 200.0, 250.0]
    /// At home: where the greeter and cashier stand at the foot of the gangway, and where people strolling along the shore stop.
    static let homeGreetX = [300.0, 350.0]
    static let homeStopX = 200.0

    // Inside the tent
    static let chairX = [400.0, 540.0, 680.0]
    static let crewX = [310.0, 470.0, 610.0, 770.0, 850.0]
    /// Where anyone not in a chair waits, left of the chairs.
    static let standByX = [235.0, 195.0, 155.0]
    static let consoleX = 960.0
    static let pinkButton = CGPoint(x: 960, y: floorY - 96)
    /// Whoever works the machine stands here.
    static let controlX = 1010.0
    /// Spots on deck for `n` people standing with the chairs folded away, spread out left of the machine.
    static func deckX(_ n: Int) -> [Double] {
        let step = n <= 1 ? 0 : min(110, 780 / Double(n - 1))
        let start = 500 - step * Double(max(n - 1, 0)) / 2
        return (0..<n).map { start + Double($0) * step }
    }
    /// How long a mini saucer takes to fly from the machine and hover over its passenger (and to lift off again).

    // At a venue
    static let greetX = [640.0, 700.0]
    static let cashX = 745.0
    static let stopX = [850.0, 880.0]
    /// Doors of the grocery store and the bank in town.
    static let storeDoorX = 330.0
    static let bankDoorX = 860.0
    /// Further along Main Street: the ship-supply shop and the dealer.
    static let boutiqueDoorX = 310.0
    /// The cabin deck: two rows of nine cabins.
    static let cabinCount = 18
    static func cabinRect(_ i: Int) -> CGRect {
        let w = W / 9, row = Double(i / 9)
        return CGRect(x: Double(i % 9) * w + 3, y: 46 + row * 276, width: w - 6, height: 266)
    }
    static let dealerDoorX = 1030.0
    // Funland's parking lot: the boss's office door, where the zamboni starts, and the shuttle's stop.
    static let parkOfficeX = 190.0
    static let zamboniStartX = 300.0
    /// The far end of Deidre's lap across the lot (the zamboni's driver's seat).
    static let zamboniEndX = 640.0
    /// The repo men's flatbed at Funland: where its bed's left end stops, how high the deck is, and where each
    /// zamboni (its driver's seat) sits on the bed, measured from the left end. The cab is past the bed's right end.
    static let flatbedX = 230.0
    static let flatbedLength = 800.0
    static let flatbedDeck = 30.0
    static let flatbedSlots = [40.0, 195.0, 350.0]
    /// Where Funland's Ferris wheel and roller coaster stand (bottom middle), behind the fence.
    static let ferrisAnchor = CGPoint(x: 820, y: 400)
    static let coasterAnchor = CGPoint(x: 1080, y: 400)
    /// Where the rides ride on the flatbed, behind the three zambonis (from the bed's left end).
    static let ferrisSlot = 560.0
    static let coasterSlot = 690.0
    /// Mr. Grimsby's motorcycle (its seat), parked in front of the park office.
    static let motorcycleX = 100.0
    /// The electric box on the park office's wall (the bank switches it off).
    static let powerBoxX = 246.0
    /// Where the coworkers' three zambonis start out on the lot.
    static let fleetStartX = [240.0, 500.0, 760.0]

    // A rescue kid's house across town: the back yard runs down to the water, then the kitchen, living room and the kid's room.
    static let kidRooms: [(x0: Double, x1: Double, wall: RGB)] = [
        (420, 700, RGB(r: 0.99, g: 0.94, b: 0.74)), (700, 930, RGB(r: 0.82, g: 0.90, b: 0.98)), (930, 1200, RGB(r: 0.96, g: 0.86, b: 0.94)),
    ]
    /// The kid's computer desk, where the kid sits at it, and where Mom stands at the kitchen counter.
    static let kidDeskX = 1125.0
    static let kidSeatX = 1070.0
    static let kidMomX = 600.0

    // Camera shots, all the stage's 2:1 shape.
    static let full = CGRect(x: 0, y: 0, width: W, height: H)
    static let yardView = CGRect(x: 0, y: 190, width: 600, height: 300)
    static let chairsView = CGRect(x: 270, y: 235, width: 540, height: 270)

    /// A close-up `height` tall centred on a point, never showing much below the floor.
    static func focus(_ c: CGPoint, height: Double) -> CGRect {
        let width = height * W / H
        return CGRect(x: min(max(c.x - width / 2, 0), W - width), y: min(max(c.y - height / 2, 0), floorY + 20 - height),
                      width: width, height: height)
    }

    /// A close-up `height` tall, centred on `centerX`, with a little floor showing.
    static func shot(centerX: Double, height: Double) -> CGRect {
        let width = height * W / H
        let x = min(max(centerX - width / 2, 0), W - width)
        return CGRect(x: x, y: floorY + 12 - height, width: width, height: height)
    }
}

enum Place { case house, bigTop, venue, town, shops, park, kidHouse, cabins }

enum InfoCard { case deal, note }

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

    let people = d.everyone.filter(\.visible)
    func feet(_ p: Person) -> CGPoint { CGPoint(x: p.x(at: now), y: Stage.floorY - p.rise(at: now)) }

    switch d.place {
    case .cabins:
        drawCabins(ctx, d: d, now: now)
    case .bigTop:
        drawBigTop(ctx, d: d, now: now)
        for p in people where p.crew { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        if !d.chairsStowed {
            for x in Stage.chairX { drawChairBack(ctx, x: x, d: d, now: now) }
        }
        let seated = people.filter(\.seated)
        for p in seated { drawSeat(ctx, p, x: p.x(at: now)) }
        for p in seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for p in seated { drawStraps(ctx, p, d: d, now: now) }
        for p in people where !p.crew && !p.seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        drawMiniTents(ctx, d: d, now: now)
    case .house, .venue, .town, .shops, .park, .kidHouse:
        if d.place == .kidHouse {
            drawKidHouse(ctx, d: d, now: now)
        } else if d.place == .park {
            drawPark(ctx, d: d, now: now)
        } else if d.place == .town {
            drawTown(ctx, now: now)
            if d.night { drawStreetNight(ctx, now: now) }
        } else if d.place == .shops {
            drawShops(ctx, now: now)
        } else if d.place == .house {
            drawHouse(ctx, d: d, now: now)
        } else if let venue = d.venue {
            drawVenue(ctx, venue, now: now)
            drawCashTable(ctx, accent: venue.accent)
        }
        // The ship rides on the water behind the front yard or the quay, so it goes behind everyone.
        if let tent = d.tent(at: now) { drawCruiseShip(ctx, at: tent, now: now, afloat: true, upgrades: d.upgrades) }
        if let g = d.gangway(at: now) { drawGangway(ctx, top: g.top, foot: g.foot, out: g.out) }
        if let b = d.shipBeam(at: now) { drawShipBeam(ctx, top: b.top, foot: b.foot, strength: b.strength, now: now) }
        for p in people.filter({ $0.rise(at: now) < 0.5 }).sorted(by: { $0.height > $1.height }) {
            drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now)
        }
        if d.place == .park { drawParkVehicles(ctx, d: d, now: now) }
        // Anyone on the gangway, climbing up into the ship or coming down from it.
        for p in people where p.rise(at: now) >= 0.5 {
            drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now)
        }
        // A mini saucer can fly off the ship and into a house, too.
        if d.place == .kidHouse { drawMiniTents(ctx, d: d, now: now) }
    }
    if d.place == .house && d.night { drawNight(ctx, now: now) }
    if d.place == .bigTop && d.night { drawDeckNight(ctx, d: d, now: now) }
    if d.place == .house { drawSnores(ctx, d: d, now: now) }
    for p in people { drawSpeech(ctx, p, feet: feet(p), cam: cam, now: now) }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, x: pop.x, age: now.timeIntervalSince(pop.t0)) }

    // Screen-space overlays
    let cardUp = d.card != nil && now < d.cardUntil
    if let card = d.card, cardUp { drawCard(screen, card) }
    // Nobody in the family is at Funland, so its scenes keep the top corner clear for speech bubbles.
    if d.venue == nil && !cardUp && d.place != .park && d.place != .cabins { drawHUD(screen, d: d, now: now) }
    drawClock(screen, d: d, now: now)
    if d.place == .bigTop { drawMirror(screen, d: d, now: now) }
    let fade = d.fade(at: now)
    if fade > 0 {
        screen.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(.black.opacity(fade)))
    }
    let flash = now.timeIntervalSince(d.flashT0)
    if flash >= 0 && flash < 0.6 {
        screen.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(.white.opacity(1 - flash / 0.6)))
    }
}

// MARK: Shared bits

private func fill(_ ctx: GraphicsContext, _ rect: CGRect, _ c: Color, corner: Double = 0) {
    ctx.fill(Path(roundedRect: rect, cornerRadius: corner), with: .color(c))
}

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

private let clownPink = Color(red: 1.0, green: 0.35, blue: 0.70)
private let tentRed = Color(red: 0.86, green: 0.14, blue: 0.20)
private let tentCream = Color(red: 1.0, green: 0.95, blue: 0.84)

func drawSky(_ ctx: GraphicsContext) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.50, green: 0.75, blue: 0.98), Color(red: 0.88, green: 0.95, blue: 1)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    ctx.fill(circle(CGPoint(x: 1115, y: 65), 35), with: .color(.yellow))
}

// MARK: House and front yard

private let livingWindow = CGRect(x: 462, y: 250, width: 76, height: 62)

private func drawHouse(_ ctx: GraphicsContext, d: Director, now: Date) {
    drawSky(ctx)
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.45, green: 0.72, blue: 0.35))
    drawFrontYard(ctx, now: now)
    if let truck = d.truck(at: now) { drawTowTruck(ctx, x: truck, now: now) }
    if let car = d.car(at: now) { drawCar(ctx, x: car.x, hooked: car.hooked) }
    // Wheels of their own, bought out of their savings
    if let x = d.parked(.car, at: now) {
        drawCar(ctx, x: x, hooked: false, paint: Color(red: 0.85, green: 0.16, blue: 0.20), noseRight: true)
    }
    if let x = d.parked(.scooter, at: now) {
        if let rider = d.rider {
            drawPerson(ctx, rider, feet: CGPoint(x: x - 12, y: Stage.floorY - 16), facing: 1, now: now, still: true, levels: ClownLevels.none)
        }
        drawScooter(ctx, x: x)
    }

    var roof = Path()
    roof.move(to: CGPoint(x: Stage.frontWallX - 20, y: Stage.ceilY))
    roof.addLine(to: CGPoint(x: (Stage.frontWallX + Stage.W) / 2, y: 95))
    roof.addLine(to: CGPoint(x: Stage.W + 10, y: Stage.ceilY))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.62, green: 0.32, blue: 0.28)))
    ctx.stroke(roof, with: .color(Color(red: 0.40, green: 0.20, blue: 0.18)), lineWidth: 4)

    for room in Stage.rooms {
        let r = CGRect(x: room.x0, y: Stage.ceilY, width: room.x1 - room.x0, height: Stage.floorY - Stage.ceilY)
        fill(ctx, r, room.wall.color)
        fill(ctx, CGRect(x: room.x0, y: Stage.floorY - 10, width: r.width, height: 10), Color(white: 0.97))
        ctx.draw(Text(room.name).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Color.black.opacity(0.45)),
                 at: CGPoint(x: (room.x0 + room.x1) / 2, y: Stage.ceilY + 18))
    }
    fill(ctx, CGRect(x: Stage.frontWallX, y: Stage.floorY, width: Stage.W - Stage.frontWallX, height: 14), Color(red: 0.55, green: 0.38, blue: 0.22))

    // Living room: a window onto the front yard and a couch
    fill(ctx, livingWindow, Color(red: 0.70, green: 0.87, blue: 1))
    ctx.stroke(Path(livingWindow), with: .color(.white), lineWidth: 5)
    fill(ctx, CGRect(x: livingWindow.midX - 1.5, y: livingWindow.minY, width: 3, height: livingWindow.height), .white)
    let couch = Color(red: 0.80, green: 0.45, blue: 0.35)
    fill(ctx, CGRect(x: 552, y: Stage.floorY - 62, width: 86, height: 36), couch, corner: 10)
    fill(ctx, CGRect(x: 546, y: Stage.floorY - 40, width: 98, height: 32), couch.opacity(0.85), corner: 8)

    let blankets = [Color(red: 0.95, green: 0.50, blue: 0.45), Color(red: 0.25, green: 0.60, blue: 0.60), Color(red: 0.55, green: 0.40, blue: 0.80)]
    for ((x, w), blanket) in zip(zip(Stage.bedX, Stage.bedW), blankets) { drawBed(ctx, x: x, width: w, blanket: blanket) }
    drawSleepers(ctx, d: d)
    // A lamp for Mom, a poster over the girls' beds, a plant in the spare room
    fill(ctx, CGRect(x: 812, y: Stage.floorY - 108, width: 12, height: 18), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 816, y: Stage.floorY - 90, width: 4, height: 80), .gray)
    fill(ctx, CGRect(x: 900, y: 260, width: 40, height: 52), Color(red: 0.15, green: 0.15, blue: 0.35), corner: 2)
    ctx.fill(circle(CGPoint(x: 920, y: 280), 10), with: .color(Color(red: 1, green: 0.8, blue: 0.3)))
    fill(ctx, CGRect(x: 1174, y: Stage.floorY - 34, width: 18, height: 24), Color(red: 0.75, green: 0.42, blue: 0.28), corner: 3)
    for dx in [-8.0, 0, 8] {
        ctx.fill(Path(ellipseIn: CGRect(x: 1178 + dx, y: Stage.floorY - 66, width: 10, height: 36)), with: .color(Color(red: 0.22, green: 0.55, blue: 0.28)))
    }
    if d.buttonShown { drawPinkButtonStand(ctx, d: d, now: now) }
    if d.pokerShown { drawPokerCabinet(ctx, d: d, now: now) }

    // Partitions with doorways; the front wall has the front door onto the yard.
    for room in Stage.rooms.dropFirst() {
        fill(ctx, CGRect(x: room.x0 - 5, y: Stage.ceilY, width: 10, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.72, green: 0.70, blue: 0.66))
    }
    fill(ctx, CGRect(x: Stage.frontWallX - 6, y: Stage.ceilY, width: 12, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.35, green: 0.33, blue: 0.30))
    ctx.stroke(Path(CGRect(x: Stage.frontWallX, y: Stage.ceilY, width: Stage.W - Stage.frontWallX, height: Stage.floorY - Stage.ceilY)),
               with: .color(Color(red: 0.35, green: 0.33, blue: 0.30)), lineWidth: 8)
    // The front door, swung open against the wall
    fill(ctx, CGRect(x: Stage.frontWallX + 6, y: Stage.doorwayTop, width: 9, height: Stage.floorY - Stage.doorwayTop), Color(red: 0.45, green: 0.28, blue: 0.18))
}

/// The house sits on the shore: the ocean runs right up behind the front yard, with a strip of beach and dune grass.
private func drawFrontYard(_ ctx: GraphicsContext, now: Date, backYard: Bool = false) {
    let t = now.timeIntervalSinceReferenceDate
    let seaTop = 292.0, shore = 452.0
    ctx.fill(Path(CGRect(x: 0, y: seaTop, width: Stage.W, height: shore - seaTop)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.12, green: 0.42, blue: 0.70), Color(red: 0.30, green: 0.68, blue: 0.82)]),
                                   startPoint: CGPoint(x: 0, y: seaTop), endPoint: CGPoint(x: 0, y: shore)))
    for k in 0..<7 {
        var wave = Path()
        let y = seaTop + 10 + Double(k) * 21
        for x in stride(from: 0.0, through: Stage.frontWallX, by: 10) {
            let pt = CGPoint(x: x, y: y + sin(x / 28 + t * 1.4 + Double(k)) * 2.2)
            x == 0 ? wave.move(to: pt) : wave.addLine(to: pt)
        }
        ctx.stroke(wave, with: .color(.white.opacity(0.28)), lineWidth: 1.4)
    }
    // Surf rolling up the sand
    var surf = Path()
    surf.move(to: CGPoint(x: 0, y: shore + 2))
    for x in stride(from: 0.0, through: Stage.frontWallX, by: 8) {
        surf.addLine(to: CGPoint(x: x, y: shore - 3 + sin(x / 18 + t * 2.2) * 2.5))
    }
    surf.addLine(to: CGPoint(x: Stage.frontWallX, y: shore + 2))
    surf.closeSubpath()
    fill(ctx, CGRect(x: 0, y: shore, width: Stage.frontWallX, height: Stage.floorY - shore), Color(red: 0.95, green: 0.86, blue: 0.64))
    ctx.fill(surf, with: .color(.white.opacity(0.75)))
    // Dune grass along the edge of the yard
    for x in stride(from: 12.0, to: Stage.frontWallX, by: 46) {
        for k in -1...1 {
            var blade = Path()
            blade.move(to: CGPoint(x: x + Double(k) * 4, y: Stage.floorY))
            blade.addQuadCurve(to: CGPoint(x: x + Double(k) * 9 + sin(t * 1.5 + x) * 2, y: Stage.floorY - 22),
                               control: CGPoint(x: x + Double(k) * 3, y: Stage.floorY - 12))
            ctx.stroke(blade, with: .color(Color(red: 0.45, green: 0.62, blue: 0.30)), lineWidth: 2)
        }
    }
    if backYard {
        drawBackYardBits(ctx)
        return
    }
    // The driveway, and a path up to the front door
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: 330, height: Stage.H - Stage.floorY), Color(white: 0.62))
    fill(ctx, CGRect(x: 330, y: Stage.floorY, width: 90, height: Stage.H - Stage.floorY), Color(red: 0.80, green: 0.74, blue: 0.64))
    for x in stride(from: 0.0, to: 330, by: 66) { fill(ctx, CGRect(x: x, y: Stage.floorY, width: 1.5, height: Stage.H - Stage.floorY), Color(white: 0.52)) }
    // Mailbox by the door
    fill(ctx, CGRect(x: 386, y: Stage.floorY - 44, width: 4, height: 44), Color(red: 0.45, green: 0.30, blue: 0.18))
    fill(ctx, CGRect(x: 374, y: Stage.floorY - 58, width: 28, height: 16), Color(red: 0.20, green: 0.35, blue: 0.65), corner: 6)
    fill(ctx, CGRect(x: 398, y: Stage.floorY - 66, width: 3, height: 12), Color(red: 0.85, green: 0.15, blue: 0.15))
}

/// Deidre's little sedan, nose to the street. Hooked up, its front end hangs off the tow truck's boom.
func drawCar(_ ctx: GraphicsContext, x: Double, hooked: Bool, paint: Color = Color(red: 0.20, green: 0.45, blue: 0.78),
             noseRight: Bool = false, ground: Double = Stage.floorY) {
    var c = ctx
    if noseRight {
        c.translateBy(x: x, y: 0)
        c.scaleBy(x: -1, y: 1)
        c.translateBy(x: -x, y: 0)
    }
    if hooked {
        c.translateBy(x: x + 40, y: ground - 11)
        c.rotate(by: .degrees(9))
        c.translateBy(x: -(x + 40), y: -(ground - 11))
    }
    var cabin = Path()
    cabin.move(to: CGPoint(x: x - 34, y: ground - 40))
    cabin.addLine(to: CGPoint(x: x - 20, y: ground - 62))
    cabin.addLine(to: CGPoint(x: x + 26, y: ground - 62))
    cabin.addLine(to: CGPoint(x: x + 46, y: ground - 40))
    cabin.closeSubpath()
    c.fill(cabin, with: .color(paint))
    var glass = Path()
    glass.move(to: CGPoint(x: x - 27, y: ground - 41))
    glass.addLine(to: CGPoint(x: x - 17, y: ground - 57))
    glass.addLine(to: CGPoint(x: x + 23, y: ground - 57))
    glass.addLine(to: CGPoint(x: x + 38, y: ground - 41))
    glass.closeSubpath()
    c.fill(glass, with: .color(Color(red: 0.75, green: 0.90, blue: 1)))
    fill(c, CGRect(x: x + 1, y: ground - 58, width: 3, height: 18), paint)
    fill(c, CGRect(x: x - 66, y: ground - 42, width: 132, height: 28), paint, corner: 9)
    fill(c, CGRect(x: x - 68, y: ground - 30, width: 8, height: 6), Color(red: 1, green: 0.95, blue: 0.6), corner: 2)
    fill(c, CGRect(x: x + 61, y: ground - 32, width: 6, height: 7), Color(red: 0.85, green: 0.12, blue: 0.12), corner: 2)
    for wx in [x - 40, x + 40] {
        c.fill(circle(CGPoint(x: wx, y: ground - 11), 12), with: .color(Color(white: 0.12)))
        c.fill(circle(CGPoint(x: wx, y: ground - 11), 5), with: .color(Color(white: 0.75)))
    }
}

/// A little motor scooter, nose to the house.
func drawScooter(_ ctx: GraphicsContext, x: Double, ground: Double = Stage.floorY) {
    let paint = Color(red: 0.35, green: 0.80, blue: 0.70)
    for wx in [x - 24, x + 26] {
        ctx.fill(circle(CGPoint(x: wx, y: ground - 9), 9), with: .color(Color(white: 0.12)))
        ctx.fill(circle(CGPoint(x: wx, y: ground - 9), 3.5), with: .color(Color(white: 0.75)))
    }
    fill(ctx, CGRect(x: x - 10, y: ground - 16, width: 34, height: 6), Color(white: 0.3), corner: 3)
    fill(ctx, CGRect(x: x - 38, y: ground - 34, width: 36, height: 22), paint, corner: 9)
    fill(ctx, CGRect(x: x - 36, y: ground - 40, width: 30, height: 8), Color(white: 0.18), corner: 4)
    var shield = Path()
    shield.move(to: CGPoint(x: x + 25, y: ground - 14))
    shield.addLine(to: CGPoint(x: x + 16, y: ground - 52))
    ctx.stroke(shield, with: .color(paint), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    var bars = Path()
    bars.move(to: CGPoint(x: x + 8, y: ground - 56))
    bars.addLine(to: CGPoint(x: x + 20, y: ground - 54))
    ctx.stroke(bars, with: .color(Color(white: 0.2)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    ctx.fill(circle(CGPoint(x: x + 22, y: ground - 42), 4), with: .color(Color(red: 1, green: 0.95, blue: 0.6)))
    fill(ctx, CGRect(x: x - 40, y: ground - 30, width: 4, height: 6), Color(red: 0.85, green: 0.12, blue: 0.12), corner: 1)
}

/// The repo man's tow truck, facing the street, with its boom over the back.
private func drawTowTruck(_ ctx: GraphicsContext, x: Double, now: Date) {
    let ground = Stage.floorY
    let body = Color(red: 0.95, green: 0.72, blue: 0.10)
    let dark = Color(white: 0.22)
    // Flatbed and boom
    fill(ctx, CGRect(x: x - 10, y: ground - 40, width: 78, height: 18), dark, corner: 3)
    var boom = Path()
    boom.move(to: CGPoint(x: x + 8, y: ground - 40))
    boom.addLine(to: CGPoint(x: x + 76, y: ground - 78))
    ctx.stroke(boom, with: .color(dark), style: StrokeStyle(lineWidth: 7, lineCap: .round))
    var cable = Path()
    cable.move(to: CGPoint(x: x + 76, y: ground - 78))
    cable.addLine(to: CGPoint(x: x + 84, y: ground - 44))
    ctx.stroke(cable, with: .color(Color(white: 0.4)), lineWidth: 2)
    ctx.stroke(circle(CGPoint(x: x + 84, y: ground - 40), 4), with: .color(Color(white: 0.4)), lineWidth: 2)
    // Cab
    var cab = Path()
    cab.move(to: CGPoint(x: x - 68, y: ground - 22))
    cab.addLine(to: CGPoint(x: x - 68, y: ground - 46))
    cab.addLine(to: CGPoint(x: x - 46, y: ground - 50))
    cab.addLine(to: CGPoint(x: x - 38, y: ground - 78))
    cab.addLine(to: CGPoint(x: x - 8, y: ground - 78))
    cab.addLine(to: CGPoint(x: x - 8, y: ground - 22))
    cab.closeSubpath()
    ctx.fill(cab, with: .color(body))
    var glass = Path()
    glass.move(to: CGPoint(x: x - 42, y: ground - 52))
    glass.addLine(to: CGPoint(x: x - 35, y: ground - 73))
    glass.addLine(to: CGPoint(x: x - 16, y: ground - 73))
    glass.addLine(to: CGPoint(x: x - 16, y: ground - 52))
    glass.closeSubpath()
    ctx.fill(glass, with: .color(Color(red: 0.75, green: 0.90, blue: 1)))
    ctx.draw(Text("REPO").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(dark), at: CGPoint(x: x - 38, y: ground - 36))
    fill(ctx, CGRect(x: x - 70, y: ground - 26, width: 140, height: 8), dark, corner: 3)
    // Flashing amber light on the roof
    let on = sin(now.timeIntervalSinceReferenceDate * 9) > 0
    fill(ctx, CGRect(x: x - 30, y: ground - 85, width: 14, height: 7), Color(red: 1, green: 0.6, blue: 0).opacity(on ? 1 : 0.4), corner: 3)
    if on { ctx.fill(circle(CGPoint(x: x - 23, y: ground - 82), 14), with: .color(Color(red: 1, green: 0.7, blue: 0.1).opacity(0.3))) }
    for wx in [x - 46, x + 40] {
        ctx.fill(circle(CGPoint(x: wx, y: ground - 13), 14), with: .color(Color(white: 0.12)))
        ctx.fill(circle(CGPoint(x: wx, y: ground - 13), 6), with: .color(Color(white: 0.75)))
    }
}

private func drawBed(_ ctx: GraphicsContext, x: Double, width: Double, blanket: Color) {
    let wood = Color(red: 0.60, green: 0.42, blue: 0.26)
    fill(ctx, CGRect(x: x, y: Stage.floorY - 80, width: 10, height: 80), wood, corner: 2)
    fill(ctx, CGRect(x: x + width - 8, y: Stage.floorY - 55, width: 8, height: 55), wood, corner: 2)
    fill(ctx, CGRect(x: x + 5, y: Stage.floorY - 44, width: width - 8, height: 22), .white, corner: 6)
    fill(ctx, CGRect(x: x + 10, y: Stage.floorY - 52, width: 24, height: 12), Color(white: 0.96), corner: 5)
    fill(ctx, CGRect(x: x + 32, y: Stage.floorY - 46, width: width - 36, height: 26), blanket, corner: 6)
}

// MARK: Bedtime

/// Anyone asleep shows as a head on her pillow with the blanket pulled up.
private func drawSleepers(_ ctx: GraphicsContext, d: Director) {
    for (p, x) in zip(d.cast, Stage.bedX) where d.sleeping.contains(p.id) {
        let head = CGPoint(x: x + 22, y: Stage.floorY - 52)
        ctx.fill(circle(CGPoint(x: head.x, y: head.y - 2), 11), with: .color(p.hair.color))
        ctx.fill(circle(head, 9), with: .color(p.skin.color))
        // Closed eyes
        for dx in [-3.5, 3.5] {
            var lid = Path()
            lid.addArc(center: CGPoint(x: head.x + dx, y: head.y), radius: 2.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            ctx.stroke(lid, with: .color(.black.opacity(0.7)), lineWidth: 1)
        }
    }
}

/// Night: outside goes dark with a moon and stars; inside the house stays softly lamp-lit.
/// Main Street after dark, drawn under the people so whoever is out walking stays lit by the street lamps.
private func drawStreetNight(_ ctx: GraphicsContext, now: Date) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(Color(red: 0.02, green: 0.04, blue: 0.16).opacity(0.66)))
    let t = now.timeIntervalSinceReferenceDate
    for (i, (x, y)) in [(80.0, 40.0), (230.0, 90.0), (400.0, 30.0), (560.0, 70.0), (760.0, 45.0), (930.0, 95.0), (1040.0, 30.0)].enumerated() {
        ctx.fill(circle(CGPoint(x: x, y: y), 1.6 + 0.6 * sin(t * 2 + Double(i))), with: .color(.white.opacity(0.9)))
    }
    var crescent = Path(ellipseIn: CGRect(x: 1085, y: 35, width: 60, height: 60))
    crescent = crescent.subtracting(Path(ellipseIn: CGRect(x: 1101, y: 27, width: 60, height: 60)))
    ctx.fill(crescent, with: .color(Color(red: 1, green: 0.97, blue: 0.80)))
    // Pools of lamplight along the sidewalk.
    for x in stride(from: 150.0, through: 1050, by: 300) {
        ctx.fill(Path(ellipseIn: CGRect(x: x - 110, y: Stage.floorY - 170, width: 220, height: 200)),
                 with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.85, blue: 0.5).opacity(0.35), .clear]),
                                       center: CGPoint(x: x, y: Stage.floorY - 60), startRadius: 0, endRadius: 115))
        ctx.fill(Path(CGRect(x: x - 2.5, y: Stage.floorY - 190, width: 5, height: 190)), with: .color(Color(white: 0.2)))
        ctx.fill(circle(CGPoint(x: x, y: Stage.floorY - 192), 9), with: .color(Color(red: 1, green: 0.9, blue: 0.6)))
    }
}

private func drawNight(_ ctx: GraphicsContext, now: Date) {
    let inside = CGRect(x: Stage.frontWallX, y: Stage.ceilY, width: Stage.W - Stage.frontWallX, height: Stage.floorY - Stage.ceilY)
    var outside = Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H))
    outside.addRect(inside)
    ctx.fill(outside, with: .color(Color(red: 0.02, green: 0.04, blue: 0.16).opacity(0.78)), style: FillStyle(eoFill: true))
    ctx.fill(Path(inside), with: .color(Color(red: 0.10, green: 0.08, blue: 0.25).opacity(0.28)))
    // The windows look out on the night sky.
    for w in [livingWindow] {
        let glass = w.insetBy(dx: 2.5, dy: 2.5)
        ctx.fill(Path(glass), with: .color(Color(red: 0.05, green: 0.08, blue: 0.25)))
        ctx.fill(circle(CGPoint(x: glass.minX + glass.width * 0.3, y: glass.minY + glass.height * 0.3), 1.5), with: .color(.white))
        ctx.fill(circle(CGPoint(x: glass.minX + glass.width * 0.75, y: glass.minY + glass.height * 0.55), 1.2), with: .color(.white))
        ctx.stroke(Path(w), with: .color(Color(white: 0.75)), lineWidth: 5)
        ctx.fill(Path(CGRect(x: w.midX - 1.5, y: w.minY, width: 3, height: w.height)), with: .color(Color(white: 0.75)))
    }
    let t = now.timeIntervalSinceReferenceDate
    for (i, (x, y)) in [(60.0, 50.0), (150.0, 110.0), (250.0, 40.0), (330.0, 150.0), (520.0, 60.0), (700.0, 35.0), (880.0, 70.0), (990.0, 30.0),
                        (40.0, 200.0), (200.0, 260.0), (300.0, 90.0), (410.0, 30.0), (620.0, 110.0), (1040.0, 120.0)].enumerated() {
        ctx.fill(circle(CGPoint(x: x, y: y), 1.6 + 0.6 * sin(t * 2 + Double(i))), with: .color(.white.opacity(0.9)))
    }
    let moon = CGPoint(x: 1115, y: 65)
    // Paint out the sun under the dark overlay.
    ctx.fill(circle(moon, 37), with: .color(Color(red: 0.126, green: 0.196, blue: 0.34)))
    var crescent = Path(ellipseIn: CGRect(x: moon.x - 30, y: moon.y - 30, width: 60, height: 60))
    crescent = crescent.subtracting(Path(ellipseIn: CGRect(x: moon.x - 14, y: moon.y - 38, width: 60, height: 60)))
    ctx.fill(crescent, with: .color(Color(red: 1, green: 0.97, blue: 0.80)))
}

// MARK: The cabins

/// Below deck on the S.S. Big Top: two corridors of cabins, each with a porthole and a bunk bed, and everyone asleep
/// (still alien clowns) under a blanket. At night the cabins are dark with moonlit portholes; in the morning, sunny.
private func drawCabins(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    fill(ctx, CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H), Color(red: 0.10, green: 0.16, blue: 0.40))
    ctx.draw(Text("S.S. BIG TOP · CABIN DECK").font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(clownPink),
             at: CGPoint(x: Stage.W / 2, y: 26))
    let walls: [Color] = [Color(red: 1, green: 0.93, blue: 0.86), Color(red: 0.88, green: 0.95, blue: 1), Color(red: 1, green: 0.90, blue: 0.95)]
    let blankets: [Color] = [tentRed, Color(red: 0.25, green: 0.50, blue: 0.85), Color(red: 0.30, green: 0.65, blue: 0.40), Color(red: 0.95, green: 0.65, blue: 0.15)]
    let wood = Color(red: 0.55, green: 0.36, blue: 0.20)
    // The family's and crew's cabins come first; the numbered passenger cabins follow on, empty ones included.
    let ownCabins = d.cabins.filter { !$0.label.hasPrefix("Cabin") }.count
    for i in 0..<Stage.cabinCount {
        let room = Stage.cabinRect(i)
        fill(ctx, room, walls[i % walls.count])
        fill(ctx, CGRect(x: room.minX, y: room.maxY - 12, width: room.width, height: 12), wood)
        // The porthole: night sky and the moon, or morning sea and sky
        let port = CGPoint(x: room.midX + 30, y: room.minY + 40)
        ctx.fill(circle(port, 17), with: .color(Color(white: 0.75)))
        if d.night {
            ctx.fill(circle(port, 13), with: .color(Color(red: 0.03, green: 0.05, blue: 0.22)))
            ctx.fill(circle(CGPoint(x: port.x + 4, y: port.y - 4), 4), with: .color(Color(red: 0.96, green: 0.96, blue: 0.86)))
        } else {
            ctx.fill(circle(port, 13), with: .color(Color(red: 0.55, green: 0.80, blue: 1)))
            var sea = ctx
            sea.clip(to: circle(port, 13))
            fill(sea, CGRect(x: port.x - 13, y: port.y + 2, width: 26, height: 12), Color(red: 0.15, green: 0.45, blue: 0.80))
        }
        // Door plate
        let label = i < d.cabins.count ? d.cabins[i].label : "Cabin \(101 + i - ownCabins)"
        fill(ctx, CGRect(x: room.minX + 6, y: room.minY + 6, width: 70, height: 16), Color(red: 0.10, green: 0.16, blue: 0.40), corner: 4)
        ctx.draw(Text(label).font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: room.minX + 41, y: room.minY + 14))
        // The bunk bed: lower and upper berth
        let berths = [room.maxY - 30, room.maxY - 112]
        fill(ctx, CGRect(x: room.minX + 8, y: berths[1] - 14, width: 4, height: room.maxY - 12 - berths[1] + 14), wood)
        fill(ctx, CGRect(x: room.maxX - 12, y: berths[1] - 14, width: 4, height: room.maxY - 12 - berths[1] + 14), wood)
        let guests = i < d.cabins.count ? d.cabins[i].guests : []
        for (b, top) in berths.enumerated() {
            let bed = CGRect(x: room.minX + 12, y: top, width: room.width - 24, height: 10)
            fill(ctx, CGRect(x: bed.minX, y: bed.maxY, width: bed.width, height: 5), wood)
            fill(ctx, bed, .white, corner: 3)
            fill(ctx, CGRect(x: bed.minX + 3, y: bed.minY - 7, width: 22, height: 9), Color(white: 0.97), corner: 4)
            if b < guests.count {
                let p = guests[b]
                let scale = 0.5
                var lie = ctx
                lie.translateBy(x: bed.maxX - 6, y: bed.minY - 9)
                lie.rotate(by: .degrees(-90))
                lie.scaleBy(x: scale, y: scale)
                drawPerson(lie, p, feet: .zero, facing: 0, now: now, still: true)
                let length = p.height * scale
                fill(ctx, CGRect(x: bed.maxX - 6 - length * 0.74, y: bed.minY - 16, width: length * 0.74 + 4, height: 17),
                     blankets[(i * 2 + b) % blankets.count], corner: 5)
                fill(ctx, CGRect(x: bed.maxX - 6 - length * 0.74, y: bed.minY - 16, width: 7, height: 17), .white.opacity(0.8), corner: 3)
                if d.night {
                    for k in 0..<3 {
                        let u = (t / 2.4 + Double(k) / 3 + Double(i * 2 + b) * 0.13).truncatingRemainder(dividingBy: 1)
                        let at = CGPoint(x: bed.maxX - 6 - length + 8 + u * 16, y: bed.minY - 22 - u * 30)
                        ctx.draw(Text("z").font(.system(size: 9 + u * 7, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 0.75, green: 0.80, blue: 1).opacity(1 - u)), at: at)
                    }
                }
            } else {
                // A made-up empty berth
                fill(ctx, CGRect(x: bed.minX + 30, y: bed.minY - 4, width: bed.width - 30, height: 6), blankets[(i + b) % blankets.count], corner: 3)
            }
        }
        ctx.stroke(Path(room), with: .color(Color(red: 0.10, green: 0.16, blue: 0.40)), lineWidth: 3)
    }
    if d.night {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(Color(red: 0.02, green: 0.04, blue: 0.18).opacity(0.55)))
        // A little glow from each porthole's moonlight
        for i in 0..<Stage.cabinCount {
            let room = Stage.cabinRect(i)
            let port = CGPoint(x: room.midX + 30, y: room.minY + 40)
            ctx.fill(circle(port, 30), with: .radialGradient(Gradient(colors: [Color(red: 0.8, green: 0.85, blue: 1).opacity(0.25), .clear]),
                                                            center: port, startRadius: 4, endRadius: 30))
        }
    }
}

/// Little Zs drifting up from each sleeper.
/// A night aboard the ship: the deck goes dark under a moonlit porthole glow, and everyone dozes where they stand.
private func drawDeckNight(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(Color(red: 0.02, green: 0.04, blue: 0.18).opacity(0.72)))
    // The portholes look out on the night sea and the moon.
    for (i, c) in [CGPoint(x: 120, y: 260), CGPoint(x: 1080, y: 260)].enumerated() {
        ctx.fill(circle(c, 38), with: .color(Color(red: 0.03, green: 0.05, blue: 0.20)))
        ctx.fill(circle(CGPoint(x: c.x - 14, y: c.y - 12), 1.6), with: .color(.white))
        ctx.fill(circle(CGPoint(x: c.x + 16, y: c.y + 4), 1.3), with: .color(.white))
        if i == 1 { ctx.fill(circle(CGPoint(x: c.x + 8, y: c.y - 14), 10), with: .color(Color(red: 0.96, green: 0.96, blue: 0.86))) }
    }
    for (i, p) in d.everyone.filter({ $0.visible && !$0.crew }).enumerated() {
        let x = p.x(at: now)
        for k in 0..<3 {
            let u = (t / 2.4 + Double(k) / 3 + Double(i) * 0.17).truncatingRemainder(dividingBy: 1)
            let at = CGPoint(x: x + 12 + u * 22 + sin(u * 6) * 4, y: Stage.floorY - p.height - 10 - u * 50)
            ctx.draw(Text("z").font(.system(size: 11 + u * 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.75, green: 0.80, blue: 1).opacity(1 - u)), at: at)
        }
    }
}

private func drawSnores(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    for (i, (p, x)) in zip(d.cast, Stage.bedX).enumerated() where d.sleeping.contains(p.id) {
        for k in 0..<3 {
            let u = (t / 2.4 + Double(k) / 3 + Double(i) * 0.21).truncatingRemainder(dividingBy: 1)
            let at = CGPoint(x: x + 34 + u * 26 + sin(u * 6) * 4, y: Stage.floorY - 70 - u * 60)
            ctx.draw(Text("z").font(.system(size: 12 + u * 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.55).opacity(1 - u)), at: at)
        }
    }
}

/// The glowing pink button the alien clowns leave in the living room, with its note.
private func drawPinkButtonStand(_ ctx: GraphicsContext, d: Director, now: Date) {
    let x = Stage.buttonX
    let t = now.timeIntervalSinceReferenceDate
    // A little striped drum for a stand
    fill(ctx, CGRect(x: x - 16, y: Stage.floorY - 62, width: 32, height: 62), tentCream, corner: 4)
    for k in 0..<3 { fill(ctx, CGRect(x: x - 12 + Double(k) * 10, y: Stage.floorY - 62, width: 5, height: 62), tentRed) }
    fill(ctx, CGRect(x: x - 20, y: Stage.floorY - 68, width: 40, height: 8), Color(red: 0.95, green: 0.78, blue: 0.20), corner: 3)
    let c = CGPoint(x: x, y: Stage.floorY - 75)
    let pressed = now.timeIntervalSince(d.buttonPressT0)
    let glow = pressed >= 0 && pressed < 1.5 ? 1.0 : 0.6 + 0.4 * sin(t * 4)
    ctx.fill(circle(c, 22), with: .radialGradient(Gradient(colors: [clownPink.opacity(0.7 * glow), .clear]), center: c, startRadius: 4, endRadius: 22))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 10, y: c.y - 6, width: 20, height: 10)), with: .color(clownPink))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 5, y: c.y - 5, width: 6, height: 3)), with: .color(.white.opacity(0.8)))
    // The note taped to the stand
    var note = ctx
    note.translateBy(x: x + 3, y: Stage.floorY - 40)
    note.rotate(by: .degrees(-6))
    fill(note, CGRect(x: -11, y: -9, width: 22, height: 18), Color(red: 1, green: 0.97, blue: 0.75), corner: 1)
    for k in 0..<3 { fill(note, CGRect(x: -7, y: -5 + Double(k) * 4, width: 14, height: 1.2), Color(white: 0.5)) }
}

// MARK: The cruise ship

/// A striped wedge-shaped slice of tent roof or wall between two x positions.
private func stripes(_ ctx: GraphicsContext, count: Int, top: (Double) -> CGPoint, bottom: (Double) -> CGPoint) {
    for i in 0..<count {
        let u0 = Double(i) / Double(count), u1 = Double(i + 1) / Double(count)
        var wedge = Path()
        wedge.move(to: top(u0))
        wedge.addLine(to: top(u1))
        wedge.addLine(to: bottom(u1))
        wedge.addLine(to: bottom(u0))
        wedge.closeSubpath()
        ctx.fill(wedge, with: .color(i % 2 == 0 ? tentRed : tentCream))
    }
}

/// The alien clowns' cruise ship, the S.S. Big Top. `c` is the middle of its keel line, where the beam comes out.
/// `afloat`, it rides on the water with a wake; otherwise it flies on a pink glow. `upgrades` from the ship-supply shop are fitted.
private func drawCruiseShip(_ ctx: GraphicsContext, at c: CGPoint, now: Date, afloat: Bool, upgrades: Set<ShipUpgrade> = []) {
    let t = now.timeIntervalSinceReferenceDate
    let y = c.y + (afloat ? sin(t * 1.1) * 1.5 : 0)
    let stern = c.x - 185, bow = c.x + 190
    if !afloat {
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 160, y: y + 14, width: 320, height: 40)),
                 with: .radialGradient(Gradient(colors: [clownPink.opacity(0.55 + 0.15 * sin(t * 5)), .clear]),
                                       center: CGPoint(x: c.x, y: y + 34), startRadius: 8, endRadius: 160))
    }
    // Hull: navy below the pink stripe, white above, a raked bow on the right
    var hull = Path()
    hull.move(to: CGPoint(x: stern, y: y - 34))
    hull.addLine(to: CGPoint(x: bow, y: y - 44))
    hull.addQuadCurve(to: CGPoint(x: bow - 34, y: y + 28), control: CGPoint(x: bow - 6, y: y + 4))
    hull.addLine(to: CGPoint(x: stern + 12, y: y + 28))
    hull.addQuadCurve(to: CGPoint(x: stern, y: y - 34), control: CGPoint(x: stern - 6, y: y + 4))
    hull.closeSubpath()
    ctx.fill(hull, with: .color(.white))
    var lower = ctx
    lower.clip(to: hull)
    fill(lower, CGRect(x: stern - 10, y: y + 2, width: bow - stern + 20, height: 30), Color(red: 0.10, green: 0.16, blue: 0.40))
    if upgrades.contains(.rainbowHull) {
        let bands: [Color] = [.red, .orange, .yellow, .green, Color(red: 0.2, green: 0.5, blue: 1), .purple]
        for (k, col) in bands.enumerated() {
            fill(lower, CGRect(x: stern - 10, y: y - 12 + Double(k) * 2.5, width: bow - stern + 20, height: 2.6), col)
        }
    } else {
        fill(lower, CGRect(x: stern - 10, y: y - 6, width: bow - stern + 20, height: 7), clownPink)
    }
    for k in 0..<14 {
        let px = stern + 26 + Double(k) * 23
        lower.fill(circle(CGPoint(x: px, y: y - 19), 3.6), with: .color(Color(red: 0.25, green: 0.45, blue: 0.75)))
    }
    ctx.stroke(hull, with: .color(Color(red: 0.08, green: 0.10, blue: 0.25)), lineWidth: 1.5)
    ctx.draw(Text("S.S. BIG TOP").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.40)),
             at: CGPoint(x: bow - 70, y: y - 30))
    // Three white decks, stepping back, with rows of windows
    let decks: [(x0: Double, x1: Double)] = [(stern + 14, bow - 46), (stern + 34, bow - 74), (stern + 58, bow - 108)]
    for (i, dk) in decks.enumerated() {
        let top = y - 34 - Double(i + 1) * 20
        fill(ctx, CGRect(x: dk.x0, y: top, width: dk.x1 - dk.x0, height: 20), .white, corner: 3)
        ctx.stroke(Path(roundedRect: CGRect(x: dk.x0, y: top, width: dk.x1 - dk.x0, height: 20), cornerRadius: 3), with: .color(Color(white: 0.7)), lineWidth: 1)
        for k in 0..<Int((dk.x1 - dk.x0 - 10) / 14) {
            fill(ctx, CGRect(x: dk.x0 + 6 + Double(k) * 14, y: top + 6, width: 9, height: 7), Color(red: 0.25, green: 0.50, blue: 0.82), corner: 1.5)
        }
    }
    // A striped funnel with a pink clown star, and a puff of rainbow smoke
    let fx = c.x + 10, fTop = y - 34 - 60 - 52
    var funnel = Path()
    funnel.move(to: CGPoint(x: fx - 20, y: y - 94))
    funnel.addLine(to: CGPoint(x: fx - 14, y: fTop))
    funnel.addLine(to: CGPoint(x: fx + 22, y: fTop))
    funnel.addLine(to: CGPoint(x: fx + 24, y: y - 94))
    funnel.closeSubpath()
    ctx.fill(funnel, with: .color(tentRed))
    var bands = ctx
    bands.clip(to: funnel)
    for k in 0..<3 { fill(bands, CGRect(x: fx - 30, y: fTop + 8 + Double(k) * 16, width: 60, height: 7), tentCream) }
    ctx.draw(Text("★").font(.system(size: 18, weight: .black)).foregroundStyle(clownPink), at: CGPoint(x: fx + 4, y: fTop + 26))
    drawShipUpgrades(ctx, upgrades, c: c, y: y, stern: stern, bow: bow, t: t, afloat: afloat)
    let puffs: [Color] = [clownPink, .yellow, .cyan, .green]
    for k in 0..<4 {
        let u = (t * 0.35 + Double(k) / 4).truncatingRemainder(dividingBy: 1)
        ctx.fill(circle(CGPoint(x: fx + 4 - u * 70, y: fTop - 8 - u * 40), 7 + u * 10), with: .color(puffs[k].opacity(0.55 * (1 - u))))
    }
    // Masts fore and aft, strung with chasing bulbs
    let mastA = CGPoint(x: stern + 30, y: y - 140), mastB = CGPoint(x: bow - 40, y: y - 120)
    fill(ctx, CGRect(x: mastA.x - 1.5, y: mastA.y, width: 3, height: 106), Color(white: 0.8))
    fill(ctx, CGRect(x: mastB.x - 1.5, y: mastB.y, width: 3, height: 76), Color(white: 0.8))
    let lights: [Color] = [.red, .yellow, clownPink, .cyan, .green]
    for (from, to) in [(mastA, CGPoint(x: fx - 14, y: fTop + 4)), (CGPoint(x: fx + 22, y: fTop + 4), mastB)] {
        for i in 0...8 {
            let u = Double(i) / 8
            let p = CGPoint(x: from.x + (to.x - from.x) * u, y: from.y + (to.y - from.y) * u + sin(u * .pi) * 10)
            let on = (Int(t * 6) + i) % 3 == 0
            ctx.fill(circle(p, on ? 3.5 : 2.4), with: .color(lights[i % lights.count].opacity(on ? 1 : 0.5)))
        }
    }
    if upgrades.contains(.bunting) {
        // Party flags from each masthead down to the stern and the bow
        let pennants: [Color] = [.red, .yellow, .blue, .green, clownPink, .orange]
        for (from, to) in [(mastA, CGPoint(x: stern + 2, y: y - 36)), (mastB, CGPoint(x: bow - 4, y: y - 46))] {
            ctx.stroke(Path { p in p.move(to: from); p.addLine(to: to) }, with: .color(Color(white: 0.55)), lineWidth: 0.8)
            for i in 0..<9 {
                let u = (Double(i) + 0.5) / 9
                let p = CGPoint(x: from.x + (to.x - from.x) * u, y: from.y + (to.y - from.y) * u)
                let flap = sin(t * 7 + Double(i)) * 1.2
                var tri = Path()
                tri.move(to: CGPoint(x: p.x - 3, y: p.y))
                tri.addLine(to: CGPoint(x: p.x + 3, y: p.y))
                tri.addLine(to: CGPoint(x: p.x + flap, y: p.y + 7))
                tri.closeSubpath()
                ctx.fill(tri, with: .color(pennants[i % pennants.count]))
            }
        }
    }
    var flag = Path()
    flag.move(to: CGPoint(x: mastA.x + 1, y: mastA.y))
    flag.addQuadCurve(to: CGPoint(x: mastA.x + 30, y: mastA.y + 7 + sin(t * 8) * 3), control: CGPoint(x: mastA.x + 16, y: mastA.y - 3 + sin(t * 8 + 1) * 4))
    flag.addLine(to: CGPoint(x: mastA.x + 1, y: mastA.y + 15))
    flag.closeSubpath()
    ctx.fill(flag, with: .color(clownPink))
    // The beam hatch under the keel
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 40, y: y + 22, width: 80, height: 12)), with: .color(Color(red: 1, green: 0.55, blue: 0.80)))
    if afloat {
        // The waterline and a little wake
        for k in 0..<3 {
            let wy = y + 28 + Double(k) * 5
            var wake = Path()
            for x in stride(from: stern - 20 - Double(k) * 30, through: bow - 20, by: 8) {
                let pt = CGPoint(x: x, y: wy + sin(x / 14 + t * 3 + Double(k)) * 1.5)
                wake.move(to: pt)
                wake.addLine(to: CGPoint(x: pt.x + 4, y: pt.y))
            }
            ctx.stroke(wake, with: .color(.white.opacity(0.7 - Double(k) * 0.2)), lineWidth: 1.6)
        }
    }
}

/// The ship-supply shop's upgrades on the S.S. Big Top's top deck (which runs from `stern + 58` to `bow - 108`
/// at `y - 94`): a water slide off the stern, deck chairs, a steam calliope and a neon sign either side of the funnel.
private func drawShipUpgrades(_ ctx: GraphicsContext, _ upgrades: Set<ShipUpgrade>, c: CGPoint, y: Double,
                              stern: Double, bow: Double, t: Double, afloat: Bool) {
    let deckTop = y - 94
    if upgrades.contains(.waterSlide) {
        // A yellow tube that loops out past the stern and splashes down into the sea
        let start = CGPoint(x: stern + 64, y: deckTop - 8)
        var slide = Path()
        slide.move(to: start)
        slide.addCurve(to: CGPoint(x: stern - 34, y: y - 50), control1: CGPoint(x: stern + 10, y: deckTop - 30),
                       control2: CGPoint(x: stern - 60, y: y - 90))
        slide.addCurve(to: CGPoint(x: stern - 28, y: y + 22), control1: CGPoint(x: stern - 10, y: y - 20),
                       control2: CGPoint(x: stern - 56, y: y + 4))
        ctx.stroke(slide, with: .color(Color(red: 0.98, green: 0.78, blue: 0.10)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        ctx.stroke(slide, with: .color(Color(red: 0.25, green: 0.65, blue: 0.95)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: [6, 5],
                                                                                                   dashPhase: -t * 30))
        fill(ctx, CGRect(x: start.x - 2, y: start.y, width: 4, height: 8), Color(white: 0.7))
        if afloat {
            for k in 0..<5 {
                let u = (t * 1.6 + Double(k) / 5).truncatingRemainder(dividingBy: 1)
                ctx.fill(circle(CGPoint(x: stern - 28 + Double(k - 2) * 5 * u, y: y + 22 - sin(u * .pi) * 10), 2.2),
                         with: .color(.white.opacity(0.8 * (1 - u))))
            }
        }
    }
    if upgrades.contains(.deckChairs) {
        // Five striped deck chairs, each with a little parasol over every other one
        let canvas: [Color] = [clownPink, .yellow, .cyan, .orange, .green]
        for k in 0..<5 {
            let x = stern + 76 + Double(k) * 11
            fill(ctx, CGRect(x: x, y: deckTop - 3, width: 7, height: 2), canvas[k])
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: deckTop - 2)); p.addLine(to: CGPoint(x: x - 3, y: deckTop - 9)) },
                       with: .color(canvas[k]), lineWidth: 2)
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x + 6, y: deckTop - 1)); p.addLine(to: CGPoint(x: x + 6, y: deckTop)) },
                       with: .color(Color(white: 0.4)), lineWidth: 1)
            if k % 2 == 0 {
                fill(ctx, CGRect(x: x + 3, y: deckTop - 16, width: 1, height: 13), Color(white: 0.5))
                var shade = Path()
                shade.move(to: CGPoint(x: x - 4, y: deckTop - 15))
                shade.addQuadCurve(to: CGPoint(x: x + 10, y: deckTop - 15), control: CGPoint(x: x + 3, y: deckTop - 23))
                shade.closeSubpath()
                ctx.fill(shade, with: .color(k == 2 ? .white : tentRed))
            }
        }
    }
    if upgrades.contains(.calliope) {
        // A row of brass pipes just aft of the funnel, puffing steam and music
        let base = c.x - 52
        let heights = [14.0, 18, 23, 27, 23, 18]
        fill(ctx, CGRect(x: base - 3, y: deckTop - 7, width: 40, height: 7), tentRed, corner: 2)
        for (k, h) in heights.enumerated() {
            fill(ctx, CGRect(x: base + Double(k) * 6, y: deckTop - 7 - h, width: 4, height: h), Color(red: 0.90, green: 0.72, blue: 0.25), corner: 1.5)
        }
        for k in 0..<3 {
            let u = (t * 0.5 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
            let x = base + 6 + Double(k) * 12 + sin(u * 6 + Double(k)) * 4
            ctx.fill(circle(CGPoint(x: x, y: deckTop - 36 - u * 26), 3 + u * 5), with: .color(.white.opacity(0.6 * (1 - u))))
            ctx.draw(Text(k == 1 ? "♫" : "♪").font(.system(size: 10, weight: .bold)).foregroundStyle(clownPink.opacity(1 - u)),
                     at: CGPoint(x: x + 10, y: deckTop - 30 - u * 34))
        }
    }
    if upgrades.contains(.neonSign) {
        // "BIG TOP" in buzzing pink neon on a frame forward of the funnel
        let sign = CGRect(x: c.x + 37, y: deckTop - 22, width: 44, height: 15)
        fill(ctx, CGRect(x: sign.minX + 6, y: sign.maxY, width: 2, height: 7), Color(white: 0.5))
        fill(ctx, CGRect(x: sign.maxX - 8, y: sign.maxY, width: 2, height: 7), Color(white: 0.5))
        fill(ctx, sign, Color(red: 0.12, green: 0.05, blue: 0.20), corner: 3)
        let flicker = sin(t * 23) > -0.85 ? 1.0 : 0.35
        ctx.fill(Path(roundedRect: sign.insetBy(dx: -6, dy: -6), cornerRadius: 8),
                 with: .radialGradient(Gradient(colors: [clownPink.opacity(0.45 * flicker), .clear]),
                                       center: CGPoint(x: sign.midX, y: sign.midY), startRadius: 2, endRadius: 34))
        ctx.stroke(Path(roundedRect: sign, cornerRadius: 3), with: .color(Color.cyan.opacity(flicker)), lineWidth: 1.2)
        ctx.draw(Text("BIG TOP").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(clownPink.opacity(flicker)),
                 at: CGPoint(x: sign.midX, y: sign.midY))
    }
}

/// The Clowns of Poker: a red-and-pink cabinet that turned up overnight in the spare room.
private func drawPokerCabinet(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let x = Stage.pokerX, base = Stage.floorY - 10
    let body = CGRect(x: x - 36, y: base - 170, width: 72, height: 170)
    // It sparkles into being.
    let age = now.timeIntervalSince(d.pokerAppearT0)
    let a = min(max(age / 2.5, 0), 1)
    var cab = ctx
    cab.opacity = a
    cab.fill(Path(roundedRect: body.insetBy(dx: -14, dy: -14), cornerRadius: 20),
             with: .radialGradient(Gradient(colors: [clownPink.opacity(0.35 + 0.15 * sin(t * 3)), .clear]),
                                   center: CGPoint(x: body.midX, y: body.midY), startRadius: 10, endRadius: 110))
    fill(cab, body, Color(red: 0.75, green: 0.10, blue: 0.22), corner: 8)
    fill(cab, CGRect(x: body.minX, y: body.minY, width: body.width, height: 26), Color(red: 0.98, green: 0.80, blue: 0.20), corner: 8)
    cab.draw(Text("CLOWNS\nOF POKER").font(.system(size: 8, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.7, green: 0.05, blue: 0.2)),
             at: CGPoint(x: body.midX, y: body.minY + 13))
    let screen = CGRect(x: body.minX + 8, y: body.minY + 34, width: body.width - 16, height: 52)
    fill(cab, screen, Color(red: 0.12, green: 0.03, blue: 0.14), corner: 4)
    cab.stroke(Path(roundedRect: screen, cornerRadius: 4), with: .color(clownPink), lineWidth: 2)
    if d.pokerScreen.isEmpty {
        // Five little cards and a clown nose
        for k in 0..<5 { fill(cab, CGRect(x: screen.minX + 4 + Double(k) * 10.5, y: screen.minY + 26, width: 9, height: 13), .white, corner: 1.5) }
        cab.fill(circle(CGPoint(x: screen.midX, y: screen.minY + 13), 6), with: .color(.red))
    } else {
        let blink = sin(t * 5) > -0.3
        cab.draw(Text(d.pokerScreen).font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(Color.yellow.opacity(blink ? 1 : 0.4)),
                 in: screen.insetBy(dx: 3, dy: 4))
    }
    // Buttons and a coin tray
    let buttons: [Color] = [.yellow, .green, .cyan, .orange, .red]
    for (k, col) in buttons.enumerated() {
        cab.fill(circle(CGPoint(x: body.minX + 12 + Double(k) * 12, y: body.minY + 100), 4.5), with: .color(col))
    }
    fill(cab, CGRect(x: body.minX + 18, y: body.maxY - 30, width: body.width - 36, height: 12), Color(white: 0.15), corner: 3)
    // Chasing bulbs down both sides
    for i in 0..<8 {
        let on = (Int(t * 6) + i) % 2 == 0
        for side in [body.minX + 3, body.maxX - 3] {
            cab.fill(circle(CGPoint(x: side, y: body.minY + 34 + Double(i) * 16), 2.4), with: .color((i % 2 == 0 ? Color.yellow : clownPink).opacity(on ? 1 : 0.4)))
        }
    }
    if age >= 0 && age < 3 {
        for k in 0..<10 {
            let u = (age / 3 + Double(k) / 10).truncatingRemainder(dividingBy: 1)
            let ang = Double(k) * 0.63 + age * 2
            let p = CGPoint(x: body.midX + cos(ang) * (30 + u * 50), y: body.midY + sin(ang) * (40 + u * 70))
            ctx.draw(Text("✦").font(.system(size: 10 + u * 8)).foregroundStyle(Color.yellow.opacity(1 - u)), at: p)
        }
    }
}

/// The gangway: a ramp with handrails and cleats, sliding out from the deck rail (`top`) down to the ground (`foot`).
private func drawGangway(_ ctx: GraphicsContext, top: CGPoint, foot: CGPoint, out u: Double) {
    let end = CGPoint(x: top.x + (foot.x - top.x) * u, y: top.y + (foot.y - top.y) * u)
    // The ramp
    var ramp = Path()
    ramp.move(to: CGPoint(x: top.x, y: top.y - 2))
    ramp.addLine(to: CGPoint(x: end.x, y: end.y - 2))
    ramp.addLine(to: CGPoint(x: end.x, y: end.y + 5))
    ramp.addLine(to: CGPoint(x: top.x, y: top.y + 5))
    ramp.closeSubpath()
    ctx.fill(ramp, with: .color(Color(red: 0.72, green: 0.55, blue: 0.36)))
    ctx.stroke(ramp, with: .color(Color(red: 0.45, green: 0.32, blue: 0.20)), lineWidth: 1.2)
    let len = hypot(end.x - top.x, end.y - top.y)
    if len > 10 {
        // Cleats across the boards, and a pink-and-white rope handrail on posts
        for k in stride(from: 8.0, to: len, by: 12) {
            let f = k / len
            let p = CGPoint(x: top.x + (end.x - top.x) * f, y: top.y + (end.y - top.y) * f)
            ctx.stroke(Path { $0.move(to: CGPoint(x: p.x - 2, y: p.y - 2)); $0.addLine(to: CGPoint(x: p.x + 2, y: p.y + 4)) },
                       with: .color(Color(red: 0.45, green: 0.32, blue: 0.20)), lineWidth: 1.4)
        }
        var rail = Path()
        rail.move(to: CGPoint(x: top.x, y: top.y - 30))
        rail.addLine(to: CGPoint(x: end.x, y: end.y - 30))
        ctx.stroke(rail, with: .color(.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        ctx.stroke(rail, with: .color(clownPink), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 6]))
        for k in stride(from: 0.0, through: len, by: max(len / 4, 1)) {
            let f = k / len
            let p = CGPoint(x: top.x + (end.x - top.x) * f, y: top.y + (end.y - top.y) * f)
            fill(ctx, CGRect(x: p.x - 1.2, y: p.y - 30, width: 2.4, height: 30), Color(white: 0.85))
        }
    }
}

/// Where someone's mini saucer is: flying out of the machine (or off the ship), hovering just above her head, or flying home.
/// Same run as the Roswell Transformation Casino's mini saucers.
private func saucerGeometry(_ d: Director, _ p: Person, now: Date) -> (center: CGPoint, r: Double) {
    let x = p.x(at: now)
    let pose = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: p.facing, now: now)
    let r = max(26, pose.hr * 2.2)
    // Stop above where the clown head and hair will finish growing, so they never poke into the saucer.
    let target = CGPoint(x: x, y: pose.headTop - pose.hr * 1.4 - r * 0.2)
    let home = d.miniTentFrom ?? CGPoint(x: Stage.consoleX, y: Stage.pinkButton.y - 40)
    let (phase, u) = SaucerRun.phase(now.timeIntervalSince(d.saucerT0), flight: d.saucerFlight)
    func ease(_ u: Double) -> Double { u * u * (3 - 2 * u) }
    let out: Double = switch phase {
    case .lowering: ease(u)
    case .lifting: 1 - ease(u)
    case .done: 0
    default: 1
    }
    // Fly up out of the hatch, then arc over to her.
    let arc = sin(out * .pi) * 40
    let c = CGPoint(x: home.x + (target.x - home.x) * out, y: home.y + (target.y - home.y) * out - arc)
    return (c, 14 + (r - 14) * out)
}

private func drawMiniTents(_ ctx: GraphicsContext, d: Director, now: Date) {
    guard now.timeIntervalSince(d.saucerT0) < SaucerRun.total(flight: d.saucerFlight) else { return }
    for p in d.saucerPeople { drawSaucer(ctx, d: d, p, now: now) }
}

/// One mini saucer and the beam it shines down over the person it's changing.
private func drawSaucer(_ ctx: GraphicsContext, d: Director, _ p: Person, now: Date) {
    let (c, r) = saucerGeometry(d, p, now: now)
    // The beam glows the colour of the clown she's turning into.
    let tint = p.clown?.color ?? clownPink
    let tt = now.timeIntervalSinceReferenceDate
    let (phase, u) = SaucerRun.phase(now.timeIntervalSince(d.saucerT0), flight: d.saucerFlight)
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
        ctx.fill(cone, with: .linearGradient(Gradient(colors: [tint.opacity(beam * 0.6), tint.opacity(beam * 0.2)]),
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
        // Sparkles rising around her
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
        // A puff of cool mist drifts off the saucer.
        let fade = min(1, u * 5, (1 - u) * 5)
        for i in 0..<6 {
            let k = Double(i)
            let drift = (tt * 0.6 + k / 6).truncatingRemainder(dividingBy: 1)
            let pt = CGPoint(x: c.x + (k - 2.5) * r * 0.3 + sin(tt + k) * 4, y: c.y + 6 + drift * 40)
            ctx.fill(circle(pt, 5 + drift * 8), with: .color(.white.opacity(0.35 * fade * (1 - drift))))
        }
    }

    // The saucer: a silver disc, a glass bubble, and a ring of blinking lights.
    let charged: Double = switch phase {
    case .charging: u
    case .beaming, .sparkling: 1
    case .cooling: 1 - u
    default: 0.2
    }
    let bob = sin(tt * 4) * 1.5
    let c2 = CGPoint(x: c.x, y: c.y + bob)
    ctx.fill(Path(ellipseIn: CGRect(x: c2.x - r * 0.45, y: c2.y - r * 0.42, width: r * 0.9, height: r * 0.6)),
             with: .color(Color(red: 1.0, green: 0.85, blue: 0.92).opacity(0.75)))
    let disc = CGRect(x: c2.x - r, y: c2.y - r * 0.18, width: r * 2, height: r * 0.36)
    ctx.fill(Path(ellipseIn: disc), with: .linearGradient(Gradient(colors: [Color(white: 0.85), Color(white: 0.45)]),
                                                         startPoint: CGPoint(x: 0, y: disc.minY), endPoint: CGPoint(x: 0, y: disc.maxY)))
    ctx.stroke(Path(ellipseIn: disc), with: .color(Color(white: 0.3)), lineWidth: 1)
    for i in 0..<5 {
        let k = Double(i)
        let blink = 0.3 + 0.7 * charged * (0.5 + 0.5 * sin(tt * 10 + k * 1.3))
        ctx.fill(circle(CGPoint(x: c2.x + (k - 2) * r * 0.36, y: c2.y + r * 0.04), max(1.5, r * 0.07)), with: .color(clownPink.opacity(blink)))
    }
    if charged > 0.2 {
        ctx.fill(Path(ellipseIn: CGRect(x: c2.x - r * 0.5, y: c2.y + r * 0.08, width: r, height: r * 0.25)),
                 with: .radialGradient(Gradient(colors: [tint.opacity(charged), .clear]), center: CGPoint(x: c2.x, y: c2.y + r * 0.2),
                                       startRadius: 1, endRadius: r * 0.5))
    }
}

// MARK: Inside the ship

private func drawBigTop(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    // Striped canvas sweeping up to the king pole
    let peak = CGPoint(x: Stage.W / 2, y: -140)
    stripes(ctx, count: 16, top: { _ in peak }, bottom: { CGPoint(x: -200 + $0 * (Stage.W + 400), y: Stage.floorY) })
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.10, green: 0.04, blue: 0.20).opacity(0.72), Color(red: 0.25, green: 0.08, blue: 0.25).opacity(0.38)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    // Round windows in the canvas, the clouds streaking by while the tent flies
    for x in [120.0, 1080.0] {
        let c = CGPoint(x: x, y: 260)
        ctx.fill(circle(c, 46), with: .color(Color(red: 0.95, green: 0.78, blue: 0.20)))
        ctx.fill(circle(c, 38), with: .color(Color(red: 0.45, green: 0.72, blue: 0.98)))
        var sky = ctx
        sky.clip(to: circle(c, 38))
        for i in 0..<6 {
            let k = Double(i)
            let sx = c.x - 60 + ((k * 47 + (d.tentFlying ? t * 190 : t * 4)).truncatingRemainder(dividingBy: 120))
            let sy = c.y - 28 + (k * 23).truncatingRemainder(dividingBy: 58)
            fill(sky, CGRect(x: sx - 14, y: sy, width: d.tentFlying ? 40 : 22, height: d.tentFlying ? 5 : 9), .white.opacity(0.85), corner: 4)
        }
    }
    // Bunting and a string of bulbs
    let flags: [Color] = [tentRed, Color(red: 0.98, green: 0.80, blue: 0.20), Color(red: 0.25, green: 0.55, blue: 0.85), clownPink, Color(red: 0.30, green: 0.70, blue: 0.35)]
    let sway = d.tentFlying ? sin(t * 3) * 5 : 0
    for i in 0..<30 {
        let u = Double(i) / 29
        let x = 60 + u * 1080
        let y = 60 + sin(u * .pi) * 34 + sway * sin(u * .pi)
        var flag = Path()
        flag.move(to: CGPoint(x: x - 12, y: y))
        flag.addLine(to: CGPoint(x: x + 12, y: y))
        flag.addLine(to: CGPoint(x: x, y: y + 22))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(flags[i % flags.count]))
    }
    for i in 0..<24 {
        let x = 200 + Double(i) * 34
        let on = sin(t * 3 + Double(i) * 0.8) > 0
        ctx.fill(circle(CGPoint(x: x, y: 158), 3.5), with: .color((i % 3 == 0 ? clownPink : i % 3 == 1 ? .yellow : .cyan).opacity(on ? 0.95 : 0.3)))
    }
    ctx.draw(Text("★ S.S. BIG TOP · ALIEN CLOWN TRANSFORMATIONS ★").font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.88, blue: 0.35)),
             at: CGPoint(x: 600, y: 128))
    // Sawdust floor with a glowing ring under each chair
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.80, green: 0.66, blue: 0.44))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 5), Color(red: 0.62, green: 0.48, blue: 0.30))
    for x in Stage.chairX where !d.chairsStowed {
        ctx.stroke(Path(ellipseIn: CGRect(x: x - 60, y: Stage.floorY + 8, width: 120, height: 22)), with: .color(clownPink.opacity(0.5 + 0.25 * sin(t * 2))), lineWidth: 2.5)
    }
    drawConsole(ctx, d: d, now: now)
}

private func drawConsole(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let x = Stage.consoleX
    let top = Stage.pinkButton.y + 8
    fill(ctx, CGRect(x: x - 40, y: top, width: 80, height: Stage.floorY - top), Color(red: 0.78, green: 0.16, blue: 0.22), corner: 6)
    var desk = Path()
    desk.move(to: CGPoint(x: x - 55, y: top + 8))
    desk.addLine(to: CGPoint(x: x - 45, y: top - 8))
    desk.addLine(to: CGPoint(x: x + 45, y: top - 8))
    desk.addLine(to: CGPoint(x: x + 55, y: top + 8))
    desk.closeSubpath()
    ctx.fill(desk, with: .color(Color(red: 0.95, green: 0.78, blue: 0.20)))
    // Screen on a stalk
    let scr = CGRect(x: x - 55, y: top - 88, width: 110, height: 52)
    fill(ctx, CGRect(x: x - 3, y: scr.maxY, width: 6, height: top - 8 - scr.maxY), Color(white: 0.4))
    fill(ctx, scr.insetBy(dx: -4, dy: -4), Color(red: 0.3, green: 0.33, blue: 0.42), corner: 6)
    fill(ctx, scr, .black, corner: 4)
    let lines = d.screenText(now).split(separator: "\n")
    for (i, line) in lines.enumerated() {
        ctx.draw(Text(String(line)).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(clownPink),
                 at: CGPoint(x: scr.midX, y: scr.midY + (Double(i) - Double(lines.count - 1) / 2) * 15))
    }
    // Little lights across the front
    for i in 0..<6 {
        let on = sin(t * 5 + Double(i) * 1.3) > 0
        ctx.fill(circle(CGPoint(x: x - 28 + Double(i) * 11, y: top + 22), 3), with: .color([Color.red, .yellow, .cyan][i % 3].opacity(on ? 1 : 0.3)))
    }
    // The big glowing pink button
    let b = Stage.pinkButton
    let pressed = now.timeIntervalSince(d.consolePressT0)
    let glow = pressed >= 0 && pressed < 1.2 ? 1.0 : 0.6 + 0.4 * sin(t * 4)
    ctx.fill(circle(b, 24), with: .radialGradient(Gradient(colors: [clownPink.opacity(0.75 * glow), .clear]), center: b, startRadius: 4, endRadius: 24))
    let down = pressed >= 0 && pressed < 0.3 ? 2.0 : 0
    ctx.fill(Path(ellipseIn: CGRect(x: b.x - 12, y: b.y - 7 + down, width: 24, height: 12)), with: .color(clownPink))
    ctx.fill(Path(ellipseIn: CGRect(x: b.x - 6, y: b.y - 5 + down, width: 7, height: 3)), with: .color(.white.opacity(0.8)))
}

/// The chair back and the transformation ring hanging over it.
private func drawChairBack(_ ctx: GraphicsContext, x: Double, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let back = CGRect(x: x - 42, y: Stage.floorY - 200, width: 84, height: 170)
    fill(ctx, back, Color(red: 0.92, green: 0.74, blue: 0.22), corner: 30)
    fill(ctx, back.insetBy(dx: 8, dy: 8), Color(red: 0.50, green: 0.20, blue: 0.55), corner: 24)
    fill(ctx, CGRect(x: x - 5, y: Stage.floorY - 30, width: 10, height: 30), Color(white: 0.45))
    fill(ctx, CGRect(x: x - 30, y: Stage.floorY - 6, width: 60, height: 6), Color(white: 0.4), corner: 3)
    // Cable up to a ring over the chair
    fill(ctx, CGRect(x: x - 2, y: 150, width: 4, height: back.minY - 190), Color(white: 0.5))
    let ring = CGRect(x: x - 48, y: back.minY - 44, width: 96, height: 22)
    let running = d.everyone.contains { $0.seated && abs($0.x(at: now) - x) < 2 && $0.isTingling(at: now) }
    let tint = d.everyone.first { $0.seated && abs($0.x(at: now) - x) < 2 }?.clown?.color ?? clownPink
    ctx.stroke(Path(ellipseIn: ring), with: .color(Color(white: 0.75)), lineWidth: 6)
    ctx.stroke(Path(ellipseIn: ring), with: .color(tint.opacity(running ? 0.6 + 0.4 * sin(t * 12) : 0.25)), lineWidth: 3)
    if running {
        var rays = Path()
        rays.move(to: CGPoint(x: ring.minX + 8, y: ring.midY))
        rays.addLine(to: CGPoint(x: ring.maxX - 8, y: ring.midY))
        rays.addLine(to: CGPoint(x: x + 60, y: Stage.floorY))
        rays.addLine(to: CGPoint(x: x - 60, y: Stage.floorY))
        rays.closeSubpath()
        ctx.fill(rays, with: .linearGradient(Gradient(colors: [tint.opacity(0.35), tint.opacity(0.05)]),
                                             startPoint: CGPoint(x: x, y: ring.midY), endPoint: CGPoint(x: x, y: Stage.floorY)))
    }
}

/// The seat and armrests, sized to whoever is sitting.
private func drawSeat(_ ctx: GraphicsContext, _ p: Person, x: Double) {
    let pose = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: 0, now: .now)
    let seatY = pose.hip[0].y + p.height * 0.02
    fill(ctx, CGRect(x: x - 40, y: seatY, width: 80, height: 12), Color(red: 0.92, green: 0.74, blue: 0.22), corner: 5)
    for i in 0..<2 {
        let hd = pose.hand[i]
        fill(ctx, CGRect(x: hd.x - 12, y: hd.y + pose.armW * 0.3, width: 24, height: 8), Color(red: 0.85, green: 0.66, blue: 0.18), corner: 3)
        fill(ctx, CGRect(x: hd.x - 3, y: hd.y + pose.armW * 0.3 + 8, width: 6, height: seatY - hd.y), Color(red: 0.75, green: 0.58, blue: 0.15))
    }
}

/// Glowing straps snap across the chest, wrists and ankles.
private func drawStraps(_ ctx: GraphicsContext, _ p: Person, d: Director, now: Date) {
    guard d.strapped.contains(p.id) else { return }
    let u = min(max(now.timeIntervalSince(d.strapT0) / 0.4, 0), 1)
    let pose = Pose(p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: 0, now: now)
    let band = Color(red: 0.25, green: 0.28, blue: 0.35)
    let t = pose.torso
    let chest = CGRect(x: t.midX - (t.width / 2 + 8) * u, y: t.minY + t.height * 0.45, width: (t.width + 16) * u, height: max(4, p.height * 0.03))
    fill(ctx, chest, band, corner: 2)
    fill(ctx, CGRect(x: chest.minX, y: chest.midY - 0.8, width: chest.width, height: 1.6), clownPink.opacity(0.9), corner: 1)
    for pt in pose.hand + pose.foot {
        let r = CGRect(x: pt.x - 9 * u, y: pt.y - 3, width: 18 * u, height: 6)
        fill(ctx, r, band, corner: 2)
        fill(ctx, CGRect(x: r.minX, y: r.midY - 0.7, width: r.width, height: 1.4), clownPink.opacity(0.9))
    }
}

/// The big mirror the alien clowns lower in front of the chairs, showing the women their reflection.
private func drawMirror(_ screen: GraphicsContext, d: Director, now: Date) {
    let u = d.mirror(at: now)
    guard u > 0 else { return }
    // Frame whoever is sitting in the chairs — or, with the chairs folded away, everyone standing on deck.
    let seated = d.everyone.filter { $0.visible && !$0.crew && ($0.seated || d.chairsStowed) }
    guard let lo = seated.map({ $0.x(at: now) }).min(), let hi = seated.map({ $0.x(at: now) }).max() else { return }
    let vw = max(420, hi - lo + 200), vh = vw * Stage.H / Stage.W
    let view = CGRect(x: (lo + hi) / 2 - vw / 2, y: Stage.floorY + 15 - vh, width: vw, height: vh)
    let w = 820.0, h = w * view.height / view.width
    let glass = CGRect(x: (Stage.W - w) / 2, y: 50 - (h + 130) * (1 - u), width: w, height: h)
    let frame = glass.insetBy(dx: -18, dy: -18)
    // Chains up to the ceiling
    for x in [frame.minX + 60, frame.maxX - 60] where frame.minY > 0 {
        fill(screen, CGRect(x: x - 3, y: 0, width: 6, height: frame.minY), Color(white: 0.55))
    }
    fill(screen, frame.offsetBy(dx: 6, dy: 8), .black.opacity(0.3), corner: 26)
    screen.fill(Path(roundedRect: frame, cornerRadius: 26),
                with: .linearGradient(Gradient(colors: [Color(white: 0.92), Color(white: 0.6), Color(white: 0.85)]),
                                      startPoint: CGPoint(x: frame.minX, y: frame.minY), endPoint: CGPoint(x: frame.maxX, y: frame.maxY)))
    for i in 0..<10 {
        let x = frame.minX + 30 + Double(i) * (frame.width - 60) / 9
        screen.fill(circle(CGPoint(x: x, y: frame.minY + 9), 3.5), with: .color(clownPink.opacity(0.8)))
    }

    // The reflection: everyone in the chairs, left and right swapped.
    var m = screen
    m.clip(to: Path(roundedRect: glass, cornerRadius: 12))
    m.translateBy(x: glass.maxX, y: glass.minY)
    m.scaleBy(x: -w / view.width, y: w / view.width)
    m.translateBy(x: -view.minX, y: -view.minY)
    drawBigTop(m, d: d, now: now)
    func feet(_ p: Person) -> CGPoint { CGPoint(x: p.x(at: now), y: Stage.floorY - p.rise(at: now)) }
    if !d.chairsStowed {
        for x in Stage.chairX { drawChairBack(m, x: x, d: d, now: now) }
    }
    for p in seated where p.seated { drawSeat(m, p, x: p.x(at: now)) }
    for p in seated { drawPerson(m, p, feet: feet(p), facing: -p.facing, now: now) }
    for p in seated where p.seated { drawStraps(m, p, d: d, now: now) }

    // A silvery sheen across the glass
    var sheen = screen
    sheen.clip(to: Path(roundedRect: glass, cornerRadius: 12))
    sheen.fill(Path(glass), with: .color(Color(red: 0.75, green: 0.85, blue: 0.95).opacity(0.12)))
    var shine = Path()
    shine.move(to: CGPoint(x: glass.minX + 80, y: glass.minY))
    shine.addLine(to: CGPoint(x: glass.minX + 170, y: glass.minY))
    shine.addLine(to: CGPoint(x: glass.minX + 20, y: glass.maxY))
    shine.addLine(to: CGPoint(x: glass.minX - 70, y: glass.maxY))
    shine.closeSubpath()
    sheen.fill(shine, with: .color(.white.opacity(0.14)))
}

// MARK: Overlays

/// Bubbles stay inside what the camera is showing, so a speaker near the edge of a close-up is still readable.
private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, cam: CGRect, now: Date) {
    guard let text = p.says, now < p.saysUntil else { return }
    let loud = p.voice > 15
    let resolved = ctx.resolve(Text(text).font(.system(size: p.voice, weight: loud ? .black : .medium, design: .rounded))
        .foregroundStyle(loud ? Color(red: 0.75, green: 0.05, blue: 0.10) : .black))
    let size = resolved.measure(in: CGSize(width: min(loud ? 420 : 230, cam.width - 32), height: 300))
    let x = feet.x
    let pose = Pose(p, feet: feet, facing: p.facing, now: now)
    let top = pose.headTop - (p.clownLevels(at: now).head * pose.hr * 1.2)
    var box = CGRect(x: x - size.width / 2 - 10, y: top - size.height - 30, width: size.width + 20, height: size.height + 14)
    let pad = 6 * cam.width / Stage.W
    box.origin.x = min(max(box.minX, cam.minX + pad), cam.maxX - box.width - pad)
    box.origin.y = min(max(box.minY, cam.minY + pad), cam.maxY - box.height - 14 - pad)

    var bubble = Path(roundedRect: box, cornerRadius: 10)
    bubble.move(to: CGPoint(x: x - 7, y: box.maxY - 1))
    bubble.addLine(to: CGPoint(x: x, y: box.maxY + 12))
    bubble.addLine(to: CGPoint(x: x + 7, y: box.maxY - 1))
    ctx.fill(bubble, with: .color(p.crew ? Color(red: 1, green: 0.90, blue: 0.95) : .white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10), with: .color(p.crew ? Color(red: 0.8, green: 0.15, blue: 0.45) : .black.opacity(0.35)), lineWidth: 1.5)
    ctx.draw(resolved, in: box.insetBy(dx: 10, dy: 7))
}

/// The alien clowns' deal, or the note on the pink button, drawn over whatever the camera shows.
private func drawCard(_ ctx: GraphicsContext, _ card: InfoCard) {
    let (title, lines): (String, [String]) = switch card {
    case .deal: ("THE ALIEN CLOWNS' DEAL", [
        "Our cruise ship docks at pre-selected ports:",
        "   Wildwood NJ, Ocean City NJ, Great Stirrup Cay, Nassau along the Queen's Staircase,",
        "   Bimini Bahamas, Coco Cay, Catalina Island, St. Kitts, Italy near the Leaning Tower of Pisa,",
        "   Paris by the Eiffel Tower, and La Bufadora.",
        "The only catch: you pay the docking fee at every port.",
        "Two of you go down the gangway and invite passers-by on the cruise.",
        "One of you stays aboard to work the machine: mini saucers transform them all.",
        "A day at sea? Play card games just for fun with the passengers.",
        "The day isn't over until you say so — then everyone is dropped off where they came from.",
        "Theirs wears off in 8 hours. Yours wears off when we bring you home:",
        "   first you change back 50% — then one minute later, back to normal.",
    ])
    case .note: ("A NOTE ON THE GLOWING PINK BUTTON", [
        "If you want to do this again to make more money,",
        "press this button, and we will take you back",
        "to our setup to transform you again.",
        "",
        "You will then have a choice of what type",
        "of alien clown you want to be.",
    ])
    }
    let height = 110 + Double(lines.count) * 29
    let card = CGRect(x: 170, y: 24, width: 860, height: height)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 14)
    fill(ctx, card, Color(red: 0.14, green: 0.05, blue: 0.16), corner: 14)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 14), with: .color(clownPink), lineWidth: 3)
    ctx.draw(Text(title).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(clownPink),
             at: CGPoint(x: card.midX, y: card.minY + 34))
    for (i, kind) in ClownKind.allCases.enumerated() {
        ctx.fill(circle(CGPoint(x: card.midX + (Double(i) - Double(ClownKind.allCases.count - 1) / 2) * 30, y: card.minY + 64), 8), with: .color(kind.color))
    }
    for (i, s) in lines.enumerated() {
        ctx.draw(Text(s).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.93)),
                 at: CGPoint(x: card.minX + 34, y: card.minY + 98 + Double(i) * 29), anchor: .leading)
    }
}

/// How much of an alien clown each of the three women (and any visiting family) is, top right.
private func drawHUD(_ ctx: GraphicsContext, d: Director, now: Date) {
    guard d.cast.contains(where: { $0.clown != nil }) else { return }
    for (i, p) in d.hudPeople.enumerated() {
        let r = CGRect(x: Stage.W - 236, y: 12 + Double(i) * 30, width: 224, height: 25)
        fill(ctx, r, .black.opacity(0.55), corner: 12.5)
        ctx.draw(Text(p.id).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: r.minX + 12, y: r.midY), anchor: .leading)
        let u = p.progress(at: now)
        let s = p.strength(at: now)
        let (label, color): (String, Color) = if p.clown != nil, now < p.changeT0, p.isTingling(at: now) { ("tingling…", .yellow) }
            else if p.clown != nil, u < 1, now >= p.changeT0 { ("changing \(Int(u * 100))%", .orange) }
            else if let kind = p.clown, s > 0.005, u >= 1 { ("\(kind.name.uppercased()) \(Int((s * 100).rounded()))%", .white) }
            else if p.clown != nil, u >= 1 { ("human again", .white.opacity(0.7)) } else { ("human", .white.opacity(0.6)) }
        if let kind = p.clown {
            ctx.fill(circle(CGPoint(x: r.minX + 66, y: r.midY), 5), with: .color(kind.color.opacity(max(0.25, s))))
        }
        ctx.draw(Text(label).font(.system(size: 12, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(color),
                 at: CGPoint(x: r.maxX - 12, y: r.midY), anchor: .trailing)
    }
}

/// "Five minutes later…" / "One minute later…" — a stopwatch counting down.
private func drawClock(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSince(d.clockT0)
    guard t >= 0 && t < d.clockDur + 1 else { return }
    let u = min(t / d.clockDur, 1)
    let card = CGRect(x: 20, y: 20, width: 270, height: 90)
    fill(ctx, card, .black.opacity(0.6), corner: 16)
    let c = CGPoint(x: card.minX + 45, y: card.midY)
    ctx.fill(circle(c, 30), with: .color(.white))
    ctx.stroke(circle(c, 30), with: .color(clownPink), lineWidth: 4)
    var wedge = Path()
    wedge.move(to: c)
    wedge.addArc(center: c, radius: 26, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * u), clockwise: false)
    wedge.closeSubpath()
    ctx.fill(wedge, with: .color(clownPink.opacity(0.5)))
    var hand = Path()
    hand.move(to: c)
    hand.addLine(to: CGPoint(x: c.x + sin(u * 2 * .pi) * 24, y: c.y - cos(u * 2 * .pi) * 24))
    ctx.stroke(hand, with: .color(.black), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    ctx.draw(Text(d.clockLabel).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: card.minX + 90, y: card.minY + 30), anchor: .leading)
    let left = max(0, d.clockSpan - Int(u * Double(d.clockSpan)))
    ctx.draw(Text(String(format: "%d:%02d", left / 60, left % 60)).font(.system(size: 28, weight: .black, design: .monospaced)).foregroundStyle(clownPink),
             at: CGPoint(x: card.minX + 90, y: card.minY + 62), anchor: .leading)
}

private func drawCashPop(_ ctx: GraphicsContext, _ text: String, x: Double, age: Double) {
    guard age >= 0 && age < 2 else { return }
    let color: Color = text.hasPrefix("-") ? .red : Color(red: 0.10, green: 0.60, blue: 0.20)
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(color.opacity(1 - age / 2)),
             at: CGPoint(x: x, y: Stage.floorY - 215 - age * 30))
}

// MARK: A rescue kid's house

/// The kid's back yard: a lawn down to the water, a little wooden fence and a garden path to the back door.
private func drawBackYardBits(_ ctx: GraphicsContext) {
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.frontWallX, height: Stage.H - Stage.floorY), Color(red: 0.42, green: 0.70, blue: 0.33))
    fill(ctx, CGRect(x: 330, y: Stage.floorY, width: 90, height: Stage.H - Stage.floorY), Color(red: 0.80, green: 0.74, blue: 0.64))
    let wood = Color(red: 0.92, green: 0.90, blue: 0.84)
    for x in stride(from: 300.0, through: 404, by: 13) {
        var picket = Path()
        picket.move(to: CGPoint(x: x, y: Stage.floorY))
        picket.addLine(to: CGPoint(x: x, y: Stage.floorY - 34))
        picket.addLine(to: CGPoint(x: x + 4, y: Stage.floorY - 40))
        picket.addLine(to: CGPoint(x: x + 8, y: Stage.floorY - 34))
        picket.addLine(to: CGPoint(x: x + 8, y: Stage.floorY))
        picket.closeSubpath()
        ctx.fill(picket, with: .color(wood))
    }
    fill(ctx, CGRect(x: 298, y: Stage.floorY - 26, width: 116, height: 4), wood)
    // Flower pots by the back door
    for (x, c) in [(386.0, Color.red), (404.0, Color.yellow)] {
        fill(ctx, CGRect(x: x - 6, y: Stage.floorY - 12, width: 12, height: 12), Color(red: 0.75, green: 0.42, blue: 0.28), corner: 2)
        ctx.fill(circle(CGPoint(x: x, y: Stage.floorY - 18), 6), with: .color(c))
    }
}

private func drawKidHouse(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.42, green: 0.70, blue: 0.33))
    drawFrontYard(ctx, now: now, backYard: true)

    var roof = Path()
    roof.move(to: CGPoint(x: Stage.frontWallX - 20, y: Stage.ceilY))
    roof.addLine(to: CGPoint(x: (Stage.frontWallX + Stage.W) / 2, y: 100))
    roof.addLine(to: CGPoint(x: Stage.W + 10, y: Stage.ceilY))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.35, green: 0.42, blue: 0.55)))
    ctx.stroke(roof, with: .color(Color(red: 0.22, green: 0.27, blue: 0.36)), lineWidth: 4)

    let names = ["Kitchen", "Living Room", d.rescueKidName.isEmpty ? "Bedroom" : "\(d.rescueKidName)'s Room"]
    for (room, name) in zip(Stage.kidRooms, names) {
        let r = CGRect(x: room.x0, y: Stage.ceilY, width: room.x1 - room.x0, height: Stage.floorY - Stage.ceilY)
        fill(ctx, r, room.wall.color)
        fill(ctx, CGRect(x: room.x0, y: Stage.floorY - 10, width: r.width, height: 10), Color(white: 0.97))
        ctx.draw(Text(name).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Color.black.opacity(0.45)),
                 at: CGPoint(x: (room.x0 + room.x1) / 2, y: Stage.ceilY + 18))
    }
    fill(ctx, CGRect(x: Stage.frontWallX, y: Stage.floorY, width: Stage.W - Stage.frontWallX, height: 14), Color(red: 0.55, green: 0.38, blue: 0.22))

    // Kitchen: the back window onto the yard, cupboards, a counter and the fridge
    let window = CGRect(x: 450, y: 250, width: 76, height: 62)
    fill(ctx, window, Color(red: 0.70, green: 0.87, blue: 1))
    ctx.stroke(Path(window), with: .color(.white), lineWidth: 5)
    fill(ctx, CGRect(x: window.midX - 1.5, y: window.minY, width: 3, height: window.height), .white)
    let cabinet = Color(red: 0.62, green: 0.80, blue: 0.70)
    fill(ctx, CGRect(x: 560, y: 248, width: 92, height: 44), cabinet, corner: 3)
    fill(ctx, CGRect(x: 605, y: 248, width: 2, height: 44), Color.black.opacity(0.15))
    fill(ctx, CGRect(x: 560, y: Stage.floorY - 56, width: 92, height: 46), cabinet, corner: 3)
    fill(ctx, CGRect(x: 556, y: Stage.floorY - 60, width: 100, height: 7), Color(white: 0.92), corner: 2)
    // A frying pan on the counter, and toast
    fill(ctx, CGRect(x: 572, y: Stage.floorY - 66, width: 26, height: 6), Color(white: 0.2), corner: 3)
    fill(ctx, CGRect(x: 618, y: Stage.floorY - 72, width: 14, height: 12), Color(red: 0.88, green: 0.68, blue: 0.40), corner: 3)
    fill(ctx, CGRect(x: 660, y: Stage.floorY - 132, width: 34, height: 122), Color(white: 0.96), corner: 4)
    fill(ctx, CGRect(x: 660, y: Stage.floorY - 92, width: 34, height: 2), Color(white: 0.75))
    fill(ctx, CGRect(x: 664, y: Stage.floorY - 120, width: 3, height: 20), Color(white: 0.6))

    // Living room: a couch and a lamp
    let couch = Color(red: 0.45, green: 0.50, blue: 0.80)
    fill(ctx, CGRect(x: 760, y: Stage.floorY - 62, width: 96, height: 36), couch, corner: 10)
    fill(ctx, CGRect(x: 754, y: Stage.floorY - 40, width: 108, height: 32), couch.opacity(0.85), corner: 8)
    fill(ctx, CGRect(x: 884, y: Stage.floorY - 112, width: 16, height: 20), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 890, y: Stage.floorY - 92, width: 4, height: 82), .gray)

    // The kid's room: a bed, a poster, and the computer desk
    drawBed(ctx, x: 945, width: 90, blanket: Color(red: 0.98, green: 0.62, blue: 0.30))
    fill(ctx, CGRect(x: 965, y: 255, width: 40, height: 52), Color(red: 0.95, green: 0.30, blue: 0.45), corner: 2)
    ctx.draw(Text("★").font(.system(size: 22)).foregroundStyle(Color.yellow), at: CGPoint(x: 985, y: 281))
    let desk = Color(red: 0.70, green: 0.50, blue: 0.32)
    let x = Stage.kidDeskX
    fill(ctx, CGRect(x: x - 50, y: Stage.floorY - 62, width: 100, height: 7), desk, corner: 2)
    fill(ctx, CGRect(x: x - 46, y: Stage.floorY - 55, width: 6, height: 45), desk)
    fill(ctx, CGRect(x: x + 40, y: Stage.floorY - 55, width: 6, height: 45), desk)
    // The monitor
    fill(ctx, CGRect(x: x - 4, y: Stage.floorY - 76, width: 8, height: 14), Color(white: 0.3))
    let monitor = CGRect(x: x - 34, y: Stage.floorY - 124, width: 68, height: 50)
    fill(ctx, monitor, Color(white: 0.18), corner: 4)
    let screen = monitor.insetBy(dx: 4, dy: 4)
    fill(ctx, screen, Color(red: 0.12, green: 0.03, blue: 0.14), corner: 2)
    if d.pokerScreen.isEmpty {
        fill(ctx, screen, Color(red: 0.30, green: 0.55, blue: 0.85).opacity(0.8), corner: 2)
    } else {
        ctx.fill(Path(roundedRect: monitor.insetBy(dx: -10, dy: -10), cornerRadius: 12),
                 with: .radialGradient(Gradient(colors: [clownPink.opacity(0.30 + 0.12 * sin(t * 3)), .clear]),
                                       center: CGPoint(x: monitor.midX, y: monitor.midY), startRadius: 6, endRadius: 70))
        let blink = sin(t * 5) > -0.3
        ctx.draw(Text(d.pokerScreen).font(.system(size: 7, weight: .heavy, design: .rounded)).foregroundStyle(Color.yellow.opacity(blink ? 1 : 0.4)),
                 in: screen.insetBy(dx: 2, dy: 3))
    }
    fill(ctx, CGRect(x: x - 26, y: Stage.floorY - 68, width: 52, height: 5), Color(white: 0.85), corner: 1)

    // Partitions with doorways; the back wall has the back door onto the yard.
    for room in Stage.kidRooms.dropFirst() {
        fill(ctx, CGRect(x: room.x0 - 5, y: Stage.ceilY, width: 10, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.72, green: 0.70, blue: 0.66))
    }
    fill(ctx, CGRect(x: Stage.frontWallX - 6, y: Stage.ceilY, width: 12, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.35, green: 0.33, blue: 0.30))
    ctx.stroke(Path(CGRect(x: Stage.frontWallX, y: Stage.ceilY, width: Stage.W - Stage.frontWallX, height: Stage.floorY - Stage.ceilY)),
               with: .color(Color(red: 0.35, green: 0.33, blue: 0.30)), lineWidth: 8)
    fill(ctx, CGRect(x: Stage.frontWallX + 6, y: Stage.doorwayTop, width: 9, height: Stage.floorY - Stage.doorwayTop), Color(red: 0.95, green: 0.95, blue: 0.95))
}

/// The ship's pink beam, slanting from the deck rail down to the ground, that beams a passenger ashore.
private func drawShipBeam(_ ctx: GraphicsContext, top: CGPoint, foot: CGPoint, strength u: Double, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    var chute = Path()
    chute.move(to: CGPoint(x: top.x - 14, y: top.y))
    chute.addLine(to: CGPoint(x: top.x + 14, y: top.y))
    chute.addLine(to: CGPoint(x: foot.x + 36, y: foot.y))
    chute.addLine(to: CGPoint(x: foot.x - 36, y: foot.y))
    chute.closeSubpath()
    ctx.fill(chute, with: .linearGradient(Gradient(colors: [clownPink.opacity(0.65 * u), clownPink.opacity(0.25 * u)]),
                                          startPoint: top, endPoint: foot))
    for k in 0..<4 {
        let f = (t * 0.8 + Double(k) / 4).truncatingRemainder(dividingBy: 1)
        let c = CGPoint(x: top.x + (foot.x - top.x) * f, y: top.y + (foot.y - top.y) * f)
        let half = 14 + 22 * f
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - half, y: c.y - 3, width: half * 2, height: 6)), with: .color(.white.opacity(0.5 * u * (1 - f))), lineWidth: 1.5)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: foot.x - 40, y: foot.y - 5, width: 80, height: 10)), with: .color(clownPink.opacity(0.45 * u)))
    for k in 0..<3 {
        let a = t * 2.4 + Double(k) * 2.1
        let f = 0.5 + 0.4 * sin(a)
        drawSparkle(ctx, at: CGPoint(x: top.x + (foot.x - top.x) * f + cos(a) * 14, y: top.y + (foot.y - top.y) * f), size: 5, alpha: 0.8 * u)
    }
}
