import SwiftUI

/// World layout, in points. The same 1200×600 stage shows the house and front yard,
/// the inside of the flying tent, or a venue.
enum Stage {
    static let W = 1200.0
    static let H = 600.0
    static let floorY = 490.0
    static let ceilY = 200.0
    static let doorwayTop = floorY - 175

    /// The front yard and driveway run from the left edge to the front wall of the house.
    static let frontWallX = 420.0
    static let rooms: [(name: String, x0: Double, x1: Double, wall: RGB)] = [
        ("Living Room", 420, 650, RGB(r: 0.98, g: 0.92, b: 0.78)),
        ("Deidre's Room", 650, 835, RGB(r: 0.98, g: 0.85, b: 0.80)),
        ("Kelly's Room", 835, 1020, RGB(r: 0.80, g: 0.92, b: 0.90)),
        ("Jen's Room", 1020, 1200, RGB(r: 0.88, g: 0.84, b: 0.96)),
    ]
    /// Deidre, Kelly, Jen: where each stands in her own room, and in the living room.
    static let roomX = [795.0, 980.0, 1160.0]
    static let livingX = [462.0, 560.0, 605.0]
    static let boyfriendX = 512.0
    /// Left edge of each bed.
    static let bedX = [662.0, 847.0, 1032.0]
    /// Where the glowing pink button turns up in the living room, and where the three gather round it.
    static let buttonX = 500.0
    static let buttonSpots = [462.0, 548.0, 590.0]

    /// Deidre's car in the driveway, and the tow truck backed up to it.
    static let carX = 235.0
    static let truckX = 85.0
    /// Where a scooter of their own gets parked, at the street end of the driveway.
    static let scooterX = 70.0

    /// The tent hovers over the front yard, or over the stand at a venue.
    static let yardTentX = 200.0
    static let venueTentX = 330.0
    /// Height of the tent's hem above the ground while it hovers.
    static let hoverLift = 250.0
    /// How far the beam lifts someone to get them through the flap.
    static var beamRise: Double { hoverLift - 20 }
    /// The three women line up under the tent.
    static let yardLine = [150.0, 200.0, 250.0]

    // Inside the tent
    static let chairX = [400.0, 540.0, 680.0]
    static let crewX = [310.0, 470.0, 610.0, 770.0, 850.0]
    /// Where anyone not in a chair waits, left of the chairs.
    static let standByX = [235.0, 195.0, 155.0]
    static let consoleX = 960.0
    static let pinkButton = CGPoint(x: 960, y: floorY - 96)
    /// Whoever works the machine stands here.
    static let controlX = 1010.0

    // At a venue
    static let greetX = [640.0, 700.0]
    static let cashX = 745.0
    static let stopX = [850.0, 880.0]
    static let waitX = [560.0, 590.0]
    static let beamSpot = [280.0, 330.0, 380.0]
    /// Doors of the grocery store and the bank in town.
    static let storeDoorX = 330.0
    static let bankDoorX = 860.0
    /// Further along Main Street: the accessory store and the dealer.
    static let boutiqueDoorX = 310.0
    static let dealerDoorX = 1030.0
    // Deidre's old salon: her styling station, and the owner's office behind the glass
    static let stationX = 270.0
    /// The power meter on the outside wall of the salon.
    static let meterX = 905.0
    static let meterY = 375.0
    /// The utility pole on the sidewalk, and where the salon's service wire is clamped to it.
    static let poleX = 1100.0
    static let dropClamp = CGPoint(x: 1092, y: 160)
    static let ownerDoorX = 760.0
    static let ownerDeskX = 1000.0
    /// A styling chair stands this far right of its station.
    static let salonChairOffset = 72.0

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

enum Place { case house, bigTop, venue, town, shops, salon, salonFront, bathroom }

/// The salon's equipment, piece by piece, as the movers carry it out.
nonisolated enum SalonItem: Hashable { case dryer, desk, station(Int), chair(Int) }

enum Card { case deal, note }

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
    case .bigTop:
        drawBigTop(ctx, d: d, now: now)
        for p in people where p.crew { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for x in Stage.chairX { drawChairBack(ctx, x: x, d: d, now: now) }
        let seated = people.filter(\.seated)
        for p in seated { drawSeat(ctx, p, x: p.x(at: now)) }
        for p in seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for p in seated { drawStraps(ctx, p, d: d, now: now) }
        for p in people where !p.crew && !p.seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
    case .house, .venue, .town, .shops, .salon, .salonFront, .bathroom:
        if d.place == .salon {
            drawSalon(ctx, now: now, cleared: d.salonCleared)
        } else if d.place == .salonFront {
            drawSalonFront(ctx, now: now, lightsOff: d.salonLightsOffT0)
        } else if d.place == .bathroom {
            drawBathroom(ctx, now: now)
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
        let tent = d.tent(at: now)
        for p in people.filter({ $0.rise(at: now) < 0.5 }).sorted(by: { $0.height > $1.height }) {
            drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now)
        }
        if d.place == .salon { drawSalonChairFronts(ctx, cleared: d.salonCleared) }
        if d.place == .salon || d.place == .bathroom {
            for c in d.clippings { drawClippings(ctx, c, now: now) }
        }
        if d.place == .salon, let t0 = d.salonLightsOffT0 { drawSalonLightsOut(ctx, since: t0, now: now) }
        // Anyone in the beam disappears up through the flap.
        var lifted = ctx
        if let tent { lifted.clip(to: Path(CGRect(x: 0, y: tent.y + 28, width: Stage.W, height: Stage.H))) }
        for p in people where p.rise(at: now) >= 0.5 {
            drawPerson(lifted, p, feet: feet(p), facing: p.facing, now: now)
        }
        if let tent {
            drawFlyingTent(ctx, at: tent, now: now)
            drawBeam(ctx, from: tent, d: d, now: now)
        }
    }
    if d.place == .house && d.night { drawNight(ctx, now: now) }
    if d.place == .house { drawSnores(ctx, d: d, now: now) }
    for p in people { drawSpeech(ctx, p, feet: feet(p), now: now) }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, x: pop.x, age: now.timeIntervalSince(pop.t0)) }

    // Screen-space overlays
    let cardUp = d.card != nil && now < d.cardUntil
    if let card = d.card, cardUp { drawCard(screen, card) }
    if d.venue == nil && !cardUp { drawHUD(screen, d: d, now: now) }
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
    drawFrontYard(ctx)
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
    for (x, blanket) in zip(Stage.bedX, blankets) { drawBed(ctx, x: x, width: 100, blanket: blanket) }
    drawSleepers(ctx, d: d)
    // A lamp for Deidre, a poster for Kelly, a plant for Jen
    fill(ctx, CGRect(x: 812, y: Stage.floorY - 108, width: 12, height: 18), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 816, y: Stage.floorY - 90, width: 4, height: 80), .gray)
    fill(ctx, CGRect(x: 900, y: 260, width: 40, height: 52), Color(red: 0.15, green: 0.15, blue: 0.35), corner: 2)
    ctx.fill(circle(CGPoint(x: 920, y: 280), 10), with: .color(Color(red: 1, green: 0.8, blue: 0.3)))
    fill(ctx, CGRect(x: 1174, y: Stage.floorY - 34, width: 18, height: 24), Color(red: 0.75, green: 0.42, blue: 0.28), corner: 3)
    for dx in [-8.0, 0, 8] {
        ctx.fill(Path(ellipseIn: CGRect(x: 1178 + dx, y: Stage.floorY - 66, width: 10, height: 36)), with: .color(Color(red: 0.22, green: 0.55, blue: 0.28)))
    }
    if d.buttonShown { drawPinkButtonStand(ctx, d: d, now: now) }

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

private func drawFrontYard(_ ctx: GraphicsContext) {
    // The neighbours' house and a hedge across the street
    fill(ctx, CGRect(x: 30, y: 372, width: 120, height: 70), Color(red: 0.93, green: 0.90, blue: 0.82))
    var gable = Path()
    gable.move(to: CGPoint(x: 20, y: 374))
    gable.addLine(to: CGPoint(x: 90, y: 332))
    gable.addLine(to: CGPoint(x: 160, y: 374))
    gable.closeSubpath()
    ctx.fill(gable, with: .color(Color(red: 0.45, green: 0.42, blue: 0.48)))
    fill(ctx, CGRect(x: 52, y: 394, width: 22, height: 20), Color(red: 0.70, green: 0.87, blue: 1))
    fill(ctx, CGRect(x: 104, y: 394, width: 22, height: 20), Color(red: 0.70, green: 0.87, blue: 1))
    for x in stride(from: -10.0, to: Stage.frontWallX, by: 34) {
        ctx.fill(circle(CGPoint(x: x + 17, y: 452), 24), with: .color(Color(red: 0.24, green: 0.52, blue: 0.26)))
    }
    fill(ctx, CGRect(x: 0, y: 452, width: Stage.frontWallX, height: 38), Color(red: 0.24, green: 0.52, blue: 0.26))
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

/// Little Zs drifting up from each sleeper.
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

// MARK: Flying tent

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

/// `c` is the middle of the tent's hem, where the roof meets the wall.
private func drawFlyingTent(_ ctx: GraphicsContext, at c: CGPoint, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let peak = CGPoint(x: c.x, y: c.y - 98)
    // A pink glow holding it up
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 120, y: c.y + 18, width: 240, height: 34)),
             with: .radialGradient(Gradient(colors: [clownPink.opacity(0.55 + 0.15 * sin(t * 5)), .clear]), center: CGPoint(x: c.x, y: c.y + 35), startRadius: 8, endRadius: 120))
    // Wall, roof, and the scalloped valance between them
    stripes(ctx, count: 10, top: { CGPoint(x: c.x - 125 + $0 * 250, y: c.y) }, bottom: { CGPoint(x: c.x - 112 + $0 * 224, y: c.y + 30) })
    stripes(ctx, count: 10, top: { _ in peak }, bottom: { CGPoint(x: c.x - 150 + $0 * 300, y: c.y) })
    var outline = Path()
    outline.move(to: CGPoint(x: c.x - 150, y: c.y))
    outline.addLine(to: peak)
    outline.addLine(to: CGPoint(x: c.x + 150, y: c.y))
    ctx.stroke(outline, with: .color(Color(red: 0.5, green: 0.08, blue: 0.12)), lineWidth: 2)
    for i in 0..<10 {
        let x = c.x - 135 + Double(i) * 30
        ctx.fill(circle(CGPoint(x: x, y: c.y + 1), 15), with: .color(i % 2 == 0 ? Color(red: 0.98, green: 0.80, blue: 0.20) : Color(red: 0.25, green: 0.55, blue: 0.85)))
    }
    fill(ctx, CGRect(x: c.x - 150, y: c.y - 8, width: 300, height: 9), Color(red: 0.98, green: 0.80, blue: 0.20), corner: 3)
    // Bulbs chase around the hem.
    let lights: [Color] = [.red, .yellow, clownPink, .cyan, .green]
    for i in 0..<13 {
        let x = c.x - 144 + Double(i) * 24
        let on = (Int(t * 6) + i) % 3 == 0
        ctx.fill(circle(CGPoint(x: x, y: c.y - 3.5), on ? 4.5 : 3), with: .color(lights[i % lights.count].opacity(on ? 1 : 0.5)))
    }
    // A pennant snapping at the top of the pole
    fill(ctx, CGRect(x: peak.x - 1.5, y: peak.y - 34, width: 3, height: 36), Color(white: 0.85))
    var flag = Path()
    flag.move(to: CGPoint(x: peak.x + 1, y: peak.y - 34))
    flag.addQuadCurve(to: CGPoint(x: peak.x + 34, y: peak.y - 26 + sin(t * 8) * 3), control: CGPoint(x: peak.x + 18, y: peak.y - 36 + sin(t * 8 + 1) * 4))
    flag.addLine(to: CGPoint(x: peak.x + 1, y: peak.y - 18))
    flag.closeSubpath()
    ctx.fill(flag, with: .color(clownPink))
    ctx.fill(circle(CGPoint(x: peak.x, y: peak.y - 36), 4), with: .color(Color(red: 0.98, green: 0.80, blue: 0.20)))
    // The flap underneath
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 42, y: c.y + 23, width: 84, height: 14)), with: .color(Color(red: 1, green: 0.55, blue: 0.80)))
}

private func drawBeam(_ ctx: GraphicsContext, from c: CGPoint, d: Director, now: Date) {
    let age = now.timeIntervalSince(d.beamT0)
    guard d.beamOn, age >= 0 else { return }
    let a = min(age / 0.5, 1)
    let top = c.y + 30
    let ground = Stage.floorY + 4
    var beam = Path()
    beam.move(to: CGPoint(x: c.x - 38, y: top))
    beam.addLine(to: CGPoint(x: c.x + 38, y: top))
    beam.addLine(to: CGPoint(x: c.x + 115, y: ground))
    beam.addLine(to: CGPoint(x: c.x - 115, y: ground))
    beam.closeSubpath()
    ctx.fill(beam, with: .linearGradient(Gradient(colors: [clownPink.opacity(0.55 * a), clownPink.opacity(0.22 * a)]),
                                         startPoint: CGPoint(x: c.x, y: top), endPoint: CGPoint(x: c.x, y: ground)))
    // Rings drifting up the beam
    let t = now.timeIntervalSinceReferenceDate
    for i in 0..<5 {
        let u = 1 - (t * 0.5 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
        let y = top + (ground - top) * u
        let hw = 38 + 77 * u
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - hw, y: y - 5, width: hw * 2, height: 10)), with: .color(.white.opacity(0.45 * a * (1 - u * 0.5))), lineWidth: 1.5)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 115, y: ground - 8, width: 230, height: 16)), with: .color(clownPink.opacity(0.4 * a)))
}

// MARK: Inside the tent

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
    ctx.draw(Text("★ ALIEN CLOWN TRANSFORMATIONS ★").font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.88, blue: 0.35)),
             at: CGPoint(x: 600, y: 128))
    // Sawdust floor with a glowing ring under each chair
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.80, green: 0.66, blue: 0.44))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 5), Color(red: 0.62, green: 0.48, blue: 0.30))
    for x in Stage.chairX {
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
    // Frame whoever is sitting in the chairs.
    let seated = d.everyone.filter { $0.visible && $0.seated && !$0.crew }
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
    for x in Stage.chairX { drawChairBack(m, x: x, d: d, now: now) }
    for p in seated { drawSeat(m, p, x: p.x(at: now)) }
    for p in seated { drawPerson(m, p, feet: feet(p), facing: -p.facing, now: now) }
    for p in seated { drawStraps(m, p, d: d, now: now) }

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

private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, now: Date) {
    guard let text = p.says, now < p.saysUntil else { return }
    let loud = p.voice > 15
    let resolved = ctx.resolve(Text(text).font(.system(size: p.voice, weight: loud ? .black : .medium, design: .rounded))
        .foregroundStyle(loud ? Color(red: 0.75, green: 0.05, blue: 0.10) : .black))
    let size = resolved.measure(in: CGSize(width: loud ? 420 : 230, height: 300))
    let x = feet.x
    let pose = Pose(p, feet: feet, facing: p.facing, now: now)
    let top = pose.headTop - (p.clownLevels(at: now).head * pose.hr * 1.2)
    var box = CGRect(x: x - size.width / 2 - 10, y: top - size.height - 30, width: size.width + 20, height: size.height + 14)
    box.origin.x = min(max(box.minX, 6), Stage.W - box.width - 6)
    box.origin.y = max(box.minY, 4)

    var bubble = Path(roundedRect: box, cornerRadius: 10)
    bubble.move(to: CGPoint(x: x - 7, y: box.maxY - 1))
    bubble.addLine(to: CGPoint(x: x, y: box.maxY + 12))
    bubble.addLine(to: CGPoint(x: x + 7, y: box.maxY - 1))
    ctx.fill(bubble, with: .color(p.crew ? Color(red: 1, green: 0.90, blue: 0.95) : .white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10), with: .color(p.crew ? Color(red: 0.8, green: 0.15, blue: 0.45) : .black.opacity(0.35)), lineWidth: 1.5)
    ctx.draw(resolved, in: box.insetBy(dx: 10, dy: 7))
}

/// The alien clowns' deal, or the note on the pink button, drawn over whatever the camera shows.
private func drawCard(_ ctx: GraphicsContext, _ card: Card) {
    let (title, lines): (String, [String]) = switch card {
    case .deal: ("THE ALIEN CLOWNS' DEAL", [
        "Our flying tent has pre-selected destinations:",
        "   Wildwood NJ, Las Vegas, Nassau along the Queen's Staircase, Bimini Bahamas,",
        "   Coco Cay, Catalina Island, St. Kitts, Italy near the Leaning Tower of Pisa,",
        "   Paris by the Eiffel Tower, and La Bufadora.",
        "The only catch: you have to pay for the setup.",
        "Two of you go outside to ask customers if they want to be an alien clown.",
        "One of you stays inside to work the machine.",
        "Their transformation wears off in 8 hours.",
        "Yours wears off after we bring you home from an event:",
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
