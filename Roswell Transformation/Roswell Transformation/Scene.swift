import SwiftUI

/// World layout, in points. The same 1200×600 stage shows the house and backyard,
/// the inside of the flying saucer, or a venue.
enum Stage {
    static let W = 1200.0
    static let H = 600.0
    static let floorY = 490.0
    static let ceilY = 200.0
    static let doorwayTop = floorY - 175

    /// The backyard runs from the left edge to the back wall of the house.
    static let backWallX = 420.0
    static let rooms: [(name: String, x0: Double, x1: Double, wall: RGB)] = [
        ("Spare Room", 420, 570, RGB(r: 0.90, g: 0.90, b: 0.93)),
        ("Mom's Room", 570, 700, RGB(r: 0.98, g: 0.85, b: 0.80)),
        ("Living Room", 700, 860, RGB(r: 0.98, g: 0.92, b: 0.78)),
        ("Olivia's Room", 860, 975, RGB(r: 0.80, g: 0.92, b: 0.90)),
        ("Grace's Room", 975, 1090, RGB(r: 0.88, g: 0.84, b: 0.96)),
        ("Christina's Room", 1090, 1200, RGB(r: 1.00, g: 0.86, b: 0.92)),
    ]
    static let doorX = 810.0
    /// Rusty's Tavern: its front door, and where the bartender stands behind the counter.
    static let barDoorX = 90.0
    static let bartenderX = 900.0
    /// Mom, Olivia, Grace, Christina.
    static let roomX = [635.0, 915.0, 1030.0, 1143.0]
    /// Where the glowing green button turns up in the spare room.
    static let buttonX = 520.0
    static let spareX = [455.0, 480.0, 548.0, 470.0]
    static let livingX = [735.0, 765.0, 795.0, 820.0]

    /// The saucer sits over the middle of the backyard, or over the stand at a venue.
    static let yardSaucerX = 200.0
    static let venueSaucerX = 330.0
    /// Height of the saucer's middle above the ground: landed on its legs, or hovering to beam.
    static let landedLift = 74.0
    static let hoverLift = 250.0
    /// How far the beam lifts someone to get them into the hatch.
    static var beamRise: Double { hoverLift - 24 }
    /// The family lines up under the saucer.
    static let yardLine = [140.0, 180.0, 220.0, 260.0]

    // Inside the saucer
    static let chairX = [330.0, 470.0, 610.0, 750.0]
    static let crewX = [255.0, 400.0, 540.0, 680.0, 830.0]
    static let consoleX = 960.0
    static let greenButton = CGPoint(x: 960, y: floorY - 96)
    /// One works the controls; the other pushes the button.
    static let controlX = [905.0, 1010.0]

    // At a venue
    static let greetX = [640.0, 700.0]
    static let cashX = 745.0
    static let stopX = [850.0, 880.0]
    static let waitX = [560.0, 590.0]
    static let beamSpot = [280.0, 330.0, 380.0]
    /// Doors of the grocery store and the bank in town.
    static let storeDoorX = 330.0
    static let bankDoorX = 860.0
    /// Left edge of each bed: Mom, Olivia, Grace, Christina.
    static let bedX = [585.0, 870.0, 985.0, 1100.0]

    // Camera shots, all the stage's 2:1 shape.
    static let full = CGRect(x: 0, y: 0, width: W, height: H)
    static let yardView = CGRect(x: 0, y: 190, width: 600, height: 300)
    static let chairsView = CGRect(x: 230, y: 245, width: 520, height: 260)

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

enum Place { case house, ship, venue, town, bar }

enum Card { case deal, note, letter, papers }

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
    case .ship:
        drawShip(ctx, d: d, now: now)
        for p in people where p.crew { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for x in Stage.chairX { drawChairBack(ctx, x: x, d: d, now: now) }
        let seated = people.filter(\.seated)
        for p in seated { drawSeat(ctx, p, x: p.x(at: now)) }
        for p in seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for p in seated { drawStraps(ctx, p, d: d, now: now) }
        for p in people where !p.crew && !p.seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
    case .bar:
        drawBar(ctx, rampageT0: d.rampageT0, policeT0: d.policeT0, now: now)
        if let b = d.bartender, b.visible { drawPerson(ctx, b, feet: feet(b), facing: b.facing, now: now) }
        drawBarCounter(ctx, rampageT0: d.rampageT0, now: now)
        for p in people where p !== d.bartender { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
    case .house, .venue, .town:
        if d.place == .town {
            drawTown(ctx, now: now)
        } else if d.place == .house {
            drawHouse(ctx, d: d, now: now)
            for x in d.boxes { drawBox(ctx, center: CGPoint(x: x, y: Stage.floorY - 13), size: 30) }
        } else if let venue = d.venue {
            drawVenue(ctx, venue, now: now)
            drawCashTable(ctx, accent: venue.accent)
        }
        let saucer = d.saucer(at: now)
        for p in people.filter({ $0.rise(at: now) < 0.5 }).sorted(by: { $0.height > $1.height }) {
            drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now)
        }
        // Anyone in the beam disappears up into the hatch.
        var lifted = ctx
        if let saucer { lifted.clip(to: Path(CGRect(x: 0, y: saucer.y + 20, width: Stage.W, height: Stage.H))) }
        for p in people where p.rise(at: now) >= 0.5 {
            drawPerson(lifted, p, feet: feet(p), facing: p.facing, now: now)
        }
        if let saucer {
            drawSaucer(ctx, at: saucer, landed: d.saucerLanded, now: now)
            drawBeam(ctx, from: saucer, d: d, now: now)
        }
    }
    if d.place == .house && d.night { drawNight(ctx, now: now) }
    if d.place == .house { drawSnores(ctx, d: d, now: now) }
    // Speech is drawn on the screen itself so close-ups can't push a bubble out of frame.
    for p in people { drawSpeech(screen, p, feet: feet(p), now: now, cam: cam) }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, x: pop.x, age: now.timeIntervalSince(pop.t0)) }

    // Screen-space overlays
    let cardUp = d.card != nil && now < d.cardUntil
    if let card = d.card, cardUp { drawCard(screen, card, signT0: d.signT0, now: now) }
    if d.venue == nil && !cardUp { drawHUD(screen, d: d, now: now) }
    drawClock(screen, d: d, now: now)
    if d.place == .ship { drawMirror(screen, d: d, now: now) }
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

private let alienGreen = Color(red: 0.35, green: 1.0, blue: 0.45)

func drawSky(_ ctx: GraphicsContext) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.50, green: 0.75, blue: 0.98), Color(red: 0.88, green: 0.95, blue: 1)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    ctx.fill(circle(CGPoint(x: 1115, y: 65), 35), with: .color(.yellow))
}

// MARK: House and backyard

private func drawHouse(_ ctx: GraphicsContext, d: Director, now: Date) {
    drawSky(ctx)
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.45, green: 0.72, blue: 0.35))
    drawBackyard(ctx)

    var roof = Path()
    roof.move(to: CGPoint(x: Stage.backWallX - 20, y: Stage.ceilY))
    roof.addLine(to: CGPoint(x: (Stage.backWallX + Stage.W) / 2, y: 95))
    roof.addLine(to: CGPoint(x: Stage.W + 10, y: Stage.ceilY))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.62, green: 0.32, blue: 0.28)))
    ctx.stroke(roof, with: .color(Color(red: 0.40, green: 0.20, blue: 0.18)), lineWidth: 4)

    for room in Stage.rooms {
        let r = CGRect(x: room.x0, y: Stage.ceilY, width: room.x1 - room.x0, height: Stage.floorY - Stage.ceilY)
        fill(ctx, r, room.wall.color)
        fill(ctx, CGRect(x: room.x0, y: Stage.floorY - 10, width: r.width, height: 10), Color(white: 0.97))
        ctx.draw(Text(room.name).font(.system(size: room.name.count > 14 ? 12 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.45)),
                 at: CGPoint(x: (room.x0 + room.x1) / 2, y: Stage.ceilY + 18))
    }
    fill(ctx, CGRect(x: Stage.backWallX, y: Stage.floorY, width: Stage.W - Stage.backWallX, height: 14), Color(red: 0.55, green: 0.38, blue: 0.22))

    drawBed(ctx, x: Stage.bedX[0], width: 100, blanket: Color(red: 0.95, green: 0.50, blue: 0.45))
    drawLivingRoom(ctx, doorOpen: now < d.doorOpenUntil)
    drawBed(ctx, x: Stage.bedX[1], width: 82, blanket: Color(red: 0.25, green: 0.60, blue: 0.60))
    drawBed(ctx, x: Stage.bedX[2], width: 82, blanket: Color(red: 0.55, green: 0.40, blue: 0.80))
    drawBed(ctx, x: Stage.bedX[3], width: 72, blanket: Color(red: 0.98, green: 0.55, blue: 0.75))
    ctx.fill(circle(CGPoint(x: 1112, y: Stage.floorY - 56), 7), with: .color(Color(red: 0.70, green: 0.48, blue: 0.28)))
    ctx.fill(circle(CGPoint(x: 1112, y: Stage.floorY - 66), 5), with: .color(Color(red: 0.70, green: 0.48, blue: 0.28)))
    drawSleepers(ctx, d: d)
    // A rocket poster in Christina's room, a lamp for Mom
    fill(ctx, CGRect(x: 1150, y: 260, width: 34, height: 48), Color(red: 0.15, green: 0.15, blue: 0.35), corner: 2)
    fill(ctx, CGRect(x: 1163, y: 268, width: 8, height: 26), .white, corner: 4)
    fill(ctx, CGRect(x: 686, y: Stage.floorY - 108, width: 12, height: 18), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 690, y: Stage.floorY - 90, width: 4, height: 80), .gray)

    // The spare room: empty, with a window onto the backyard
    let win = CGRect(x: 470, y: 250, width: 70, height: 62)
    fill(ctx, win, Color(red: 0.70, green: 0.87, blue: 1))
    ctx.stroke(Path(win), with: .color(.white), lineWidth: 5)
    fill(ctx, CGRect(x: win.midX - 1.5, y: win.minY, width: 3, height: win.height), .white)
    if d.buttonShown { drawGreenButtonStand(ctx, d: d, now: now) }

    // Partitions with doorways; the back wall has the back door onto the yard.
    for room in Stage.rooms.dropFirst() {
        fill(ctx, CGRect(x: room.x0 - 5, y: Stage.ceilY, width: 10, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.72, green: 0.70, blue: 0.66))
    }
    fill(ctx, CGRect(x: Stage.backWallX - 6, y: Stage.ceilY, width: 12, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.35, green: 0.33, blue: 0.30))
    ctx.stroke(Path(CGRect(x: Stage.backWallX, y: Stage.ceilY, width: Stage.W - Stage.backWallX, height: Stage.floorY - Stage.ceilY)),
               with: .color(Color(red: 0.35, green: 0.33, blue: 0.30)), lineWidth: 8)
    // The back door, swung open against the wall
    fill(ctx, CGRect(x: Stage.backWallX + 6, y: Stage.doorwayTop, width: 9, height: Stage.floorY - Stage.doorwayTop), Color(red: 0.45, green: 0.28, blue: 0.18))
}

private func drawBackyard(_ ctx: GraphicsContext) {
    // Picket fence along the back
    let white = Color(white: 0.97)
    fill(ctx, CGRect(x: 0, y: 420, width: Stage.backWallX, height: 6), white)
    fill(ctx, CGRect(x: 0, y: 450, width: Stage.backWallX, height: 6), white)
    for x in stride(from: 6.0, to: Stage.backWallX, by: 22) {
        var picket = Path()
        picket.move(to: CGPoint(x: x, y: Stage.floorY))
        picket.addLine(to: CGPoint(x: x, y: 408))
        picket.addLine(to: CGPoint(x: x + 6, y: 400))
        picket.addLine(to: CGPoint(x: x + 12, y: 408))
        picket.addLine(to: CGPoint(x: x + 12, y: Stage.floorY))
        picket.closeSubpath()
        ctx.fill(picket, with: .color(white))
    }
    // A big shade tree and a swing
    fill(ctx, CGRect(x: 360, y: 300, width: 22, height: 190), Color(red: 0.45, green: 0.30, blue: 0.18), corner: 4)
    for (dx, dy, r) in [(0.0, 0.0, 60.0), (-45.0, 30.0, 45.0), (40.0, 35.0, 45.0), (5.0, -40.0, 45.0)] {
        ctx.fill(circle(CGPoint(x: 371 + dx, y: 290 + dy), r), with: .color(Color(red: 0.25, green: 0.55, blue: 0.25)))
    }
    for x in [322.0, 346.0] { fill(ctx, CGRect(x: x, y: 330, width: 2, height: 110), Color(white: 0.4)) }
    fill(ctx, CGRect(x: 316, y: 438, width: 36, height: 6), Color(red: 0.6, green: 0.4, blue: 0.2), corner: 2)
    // Flowers
    for (i, x) in stride(from: 20.0, to: 300, by: 38).enumerated() {
        let c: Color = [.red, .yellow, .pink, .orange][i % 4]
        fill(ctx, CGRect(x: x, y: Stage.floorY - 14, width: 2, height: 14), Color(red: 0.2, green: 0.5, blue: 0.2))
        ctx.fill(circle(CGPoint(x: x + 1, y: Stage.floorY - 16), 4), with: .color(c))
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

private func drawLivingRoom(_ ctx: GraphicsContext, doorOpen: Bool) {
    fill(ctx, CGRect(x: 715, y: 240, width: 60, height: 60), Color(red: 0.65, green: 0.85, blue: 1), corner: 3)
    ctx.stroke(Path(CGRect(x: 715, y: 240, width: 60, height: 60)), with: .color(.white), lineWidth: 5)
    let couch = Color(red: 0.80, green: 0.45, blue: 0.35)
    fill(ctx, CGRect(x: 712, y: Stage.floorY - 60, width: 70, height: 35), couch, corner: 10)
    fill(ctx, CGRect(x: 708, y: Stage.floorY - 38, width: 78, height: 30), couch.opacity(0.85), corner: 8)

    let door = CGRect(x: Stage.doorX - 22, y: Stage.floorY - 150, width: 44, height: 150)
    fill(ctx, door.insetBy(dx: -5, dy: -5), .white)
    if doorOpen {
        fill(ctx, door, Color(red: 0.55, green: 0.80, blue: 0.45))
        fill(ctx, CGRect(x: door.minX, y: door.minY, width: 12, height: door.height), Color(red: 0.45, green: 0.28, blue: 0.18))
    } else {
        fill(ctx, door, Color(red: 0.45, green: 0.28, blue: 0.18))
        ctx.fill(Path(ellipseIn: CGRect(x: door.maxX - 13, y: door.midY, width: 8, height: 8)), with: .color(.yellow))
    }
}

// MARK: Bedtime

/// Anyone asleep shows as a head on her pillow with the blanket pulled up.
private func drawSleepers(_ ctx: GraphicsContext, d: Director) {
    for (p, x) in d.beds where d.sleeping.contains(p.id) {
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
private func drawNight(_ ctx: GraphicsContext, now: Date) {
    let inside = CGRect(x: Stage.backWallX, y: Stage.ceilY, width: Stage.W - Stage.backWallX, height: Stage.floorY - Stage.ceilY)
    var outside = Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H))
    outside.addRect(inside)
    ctx.fill(outside, with: .color(Color(red: 0.02, green: 0.04, blue: 0.16).opacity(0.78)), style: FillStyle(eoFill: true))
    ctx.fill(Path(inside), with: .color(Color(red: 0.10, green: 0.08, blue: 0.25).opacity(0.28)))
    // The windows look out on the night sky.
    for w in [CGRect(x: 470, y: 250, width: 70, height: 62), CGRect(x: 715, y: 240, width: 60, height: 60)] {
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
    for (i, (p, x)) in d.beds.enumerated() where d.sleeping.contains(p.id) {
        for k in 0..<3 {
            let u = (t / 2.4 + Double(k) / 3 + Double(i) * 0.21).truncatingRemainder(dividingBy: 1)
            let at = CGPoint(x: x + 34 + u * 26 + sin(u * 6) * 4, y: Stage.floorY - 70 - u * 60)
            ctx.draw(Text("z").font(.system(size: 12 + u * 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.55).opacity(1 - u)), at: at)
        }
    }
}

/// The glowing green button the aliens leave in the spare room, with its note.
private func drawGreenButtonStand(_ ctx: GraphicsContext, d: Director, now: Date) {
    let x = Stage.buttonX
    let t = now.timeIntervalSinceReferenceDate
    fill(ctx, CGRect(x: x - 14, y: Stage.floorY - 62, width: 28, height: 62), Color(white: 0.35), corner: 4)
    fill(ctx, CGRect(x: x - 20, y: Stage.floorY - 68, width: 40, height: 8), Color(white: 0.55), corner: 3)
    let c = CGPoint(x: x, y: Stage.floorY - 75)
    let pressed = now.timeIntervalSince(d.buttonPressT0)
    let glow = pressed >= 0 && pressed < 1.5 ? 1.0 : 0.6 + 0.4 * sin(t * 4)
    ctx.fill(circle(c, 22), with: .radialGradient(Gradient(colors: [alienGreen.opacity(0.7 * glow), .clear]), center: c, startRadius: 4, endRadius: 22))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 10, y: c.y - 6, width: 20, height: 10)), with: .color(alienGreen))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 5, y: c.y - 5, width: 6, height: 3)), with: .color(.white.opacity(0.8)))
    // The note taped to the stand
    var note = ctx
    note.translateBy(x: x + 3, y: Stage.floorY - 40)
    note.rotate(by: .degrees(-6))
    fill(note, CGRect(x: -11, y: -9, width: 22, height: 18), Color(red: 1, green: 0.97, blue: 0.75), corner: 1)
    for k in 0..<3 { fill(note, CGRect(x: -7, y: -5 + Double(k) * 4, width: 14, height: 1.2), Color(white: 0.5)) }
}

// MARK: Flying saucer

/// `c` is the middle of the saucer's disc.
private func drawSaucer(_ ctx: GraphicsContext, at c: CGPoint, landed: Bool, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let metal = Color(red: 0.72, green: 0.75, blue: 0.80)
    let dark = Color(red: 0.42, green: 0.45, blue: 0.52)
    if landed {
        for side in [-1.0, 1.0] {
            var leg = Path()
            leg.move(to: CGPoint(x: c.x + side * 85, y: c.y + 12))
            leg.addLine(to: CGPoint(x: c.x + side * 118, y: c.y + Stage.landedLift - 6))
            ctx.stroke(leg, with: .color(dark), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            fill(ctx, CGRect(x: c.x + side * 118 - 14, y: c.y + Stage.landedLift - 7, width: 28, height: 7), dark, corner: 3)
        }
    }
    // Glass dome with a little alien pilot inside
    let dome = CGRect(x: c.x - 62, y: c.y - 72, width: 124, height: 100)
    var domePath = Path()
    domePath.addArc(center: CGPoint(x: c.x, y: c.y - 16), radius: 62, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
    domePath.closeSubpath()
    ctx.fill(domePath, with: .linearGradient(Gradient(colors: [Color(red: 0.75, green: 1, blue: 0.85).opacity(0.85), Color(red: 0.35, green: 0.75, blue: 0.6).opacity(0.85)]),
                                             startPoint: CGPoint(x: dome.minX, y: dome.minY), endPoint: CGPoint(x: dome.maxX, y: dome.maxY)))
    let pilot = headShape(CGPoint(x: c.x, y: c.y - 38), hr: 13, alien: 1)
    ctx.fill(pilot.path, with: .color(Color(red: 0.62, green: 0.68, blue: 0.66)))
    for side in [-1.0, 1.0] {
        var eye = ctx
        eye.translateBy(x: c.x + side * 6.5, y: c.y - 38)
        eye.rotate(by: .degrees(side * 28))
        eye.fill(Path(ellipseIn: CGRect(x: -4.5, y: -2.4, width: 9, height: 4.8)), with: .color(.black))
    }
    var shine = Path()
    shine.addArc(center: CGPoint(x: c.x, y: c.y - 16), radius: 50, startAngle: .degrees(200), endAngle: .degrees(240), clockwise: false)
    ctx.stroke(shine, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

    // The disc
    let disc = CGRect(x: c.x - 145, y: c.y - 26, width: 290, height: 52)
    ctx.fill(Path(ellipseIn: disc), with: .linearGradient(Gradient(colors: [Color(white: 0.92), metal, dark]),
                                                          startPoint: CGPoint(x: c.x, y: disc.minY), endPoint: CGPoint(x: c.x, y: disc.maxY)))
    ctx.stroke(Path(ellipseIn: disc), with: .color(dark), lineWidth: 2)
    fill(ctx, CGRect(x: disc.minX + 18, y: c.y - 3, width: disc.width - 36, height: 6), dark.opacity(0.6), corner: 3)
    // Running lights chase around the rim.
    let lights: [Color] = [.red, .yellow, alienGreen, .cyan, .pink]
    for i in 0..<11 {
        let u = Double(i) / 10
        let x = disc.minX + 28 + u * (disc.width - 56)
        let y = c.y + 11 + sin(u * .pi) * 5
        let on = (Int(t * 6) + i) % 3 == 0
        ctx.fill(circle(CGPoint(x: x, y: y), on ? 5 : 3.5), with: .color(lights[i % lights.count].opacity(on ? 1 : 0.45)))
    }
    // The hatch underneath
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 40, y: c.y + 15, width: 80, height: 14)), with: .color(Color(red: 0.2, green: 0.8, blue: 0.4)))
}

private func drawBeam(_ ctx: GraphicsContext, from c: CGPoint, d: Director, now: Date) {
    let age = now.timeIntervalSince(d.beamT0)
    guard d.beamOn, age >= 0 else { return }
    let a = min(age / 0.5, 1)
    let top = c.y + 22
    let ground = Stage.floorY + 4
    var beam = Path()
    beam.move(to: CGPoint(x: c.x - 38, y: top))
    beam.addLine(to: CGPoint(x: c.x + 38, y: top))
    beam.addLine(to: CGPoint(x: c.x + 115, y: ground))
    beam.addLine(to: CGPoint(x: c.x - 115, y: ground))
    beam.closeSubpath()
    ctx.fill(beam, with: .linearGradient(Gradient(colors: [alienGreen.opacity(0.55 * a), alienGreen.opacity(0.22 * a)]),
                                         startPoint: CGPoint(x: c.x, y: top), endPoint: CGPoint(x: c.x, y: ground)))
    // Rings drifting up the beam
    let t = now.timeIntervalSinceReferenceDate
    for i in 0..<5 {
        let u = 1 - (t * 0.5 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
        let y = top + (ground - top) * u
        let hw = 38 + 77 * u
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - hw, y: y - 5, width: hw * 2, height: 10)), with: .color(.white.opacity(0.45 * a * (1 - u * 0.5))), lineWidth: 1.5)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 115, y: ground - 8, width: 230, height: 16)), with: .color(alienGreen.opacity(0.4 * a)))
}

// MARK: Inside the saucer

private func drawShip(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.10, green: 0.10, blue: 0.20), Color(red: 0.20, green: 0.24, blue: 0.34)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    // Curved ribs up the walls to the domed ceiling
    for x in stride(from: 40.0, to: Stage.W, by: 140) {
        var rib = Path()
        rib.move(to: CGPoint(x: x, y: Stage.floorY))
        rib.addQuadCurve(to: CGPoint(x: Stage.W / 2 + (x - Stage.W / 2) * 0.35, y: 30), control: CGPoint(x: x, y: 120))
        ctx.stroke(rib, with: .color(Color(red: 0.35, green: 0.40, blue: 0.52)), lineWidth: 6)
    }
    // Portholes onto space, the stars streaking by while the saucer flies
    for x in [120.0, 1080.0] {
        let c = CGPoint(x: x, y: 250)
        ctx.fill(circle(c, 46), with: .color(Color(red: 0.55, green: 0.60, blue: 0.70)))
        ctx.fill(circle(c, 38), with: .color(Color(red: 0.02, green: 0.02, blue: 0.08)))
        var stars = ctx
        stars.clip(to: circle(c, 38))
        for i in 0..<18 {
            let k = Double(i)
            let sx = c.x - 40 + ((k * 37 + (d.shipFlying ? t * 160 : 0)).truncatingRemainder(dividingBy: 80))
            let sy = c.y - 36 + (k * 23).truncatingRemainder(dividingBy: 72)
            if d.shipFlying {
                fill(stars, CGRect(x: sx - 10, y: sy, width: 12, height: 1.4), .white.opacity(0.8))
            } else {
                stars.fill(circle(CGPoint(x: sx, y: sy), 1.2), with: .color(.white.opacity(0.5 + 0.5 * sin(t * 2 + k))))
            }
        }
        ctx.fill(circle(CGPoint(x: c.x - 16, y: c.y - 16), 6), with: .color(.white.opacity(0.18)))
    }
    // Blinking light strips
    for i in 0..<24 {
        let x = 200 + Double(i) * 34
        let on = sin(t * 3 + Double(i) * 0.8) > 0
        ctx.fill(circle(CGPoint(x: x, y: 150), 3), with: .color((i % 3 == 0 ? alienGreen : i % 3 == 1 ? .cyan : .pink).opacity(on ? 0.9 : 0.25)))
    }
    ctx.draw(Text("◉ TRANSFORMATION DECK ◉").font(.system(size: 18, weight: .black, design: .monospaced)).foregroundStyle(alienGreen.opacity(0.8)),
             at: CGPoint(x: 600, y: 118))
    // Floor with glowing rings
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.28, green: 0.30, blue: 0.38))
    for x in Stage.chairX {
        ctx.stroke(Path(ellipseIn: CGRect(x: x - 60, y: Stage.floorY + 8, width: 120, height: 22)), with: .color(alienGreen.opacity(0.35 + 0.2 * sin(t * 2))), lineWidth: 2)
    }
    drawConsole(ctx, d: d, now: now)
}

private func drawConsole(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let x = Stage.consoleX
    let top = Stage.greenButton.y + 8
    fill(ctx, CGRect(x: x - 40, y: top, width: 80, height: Stage.floorY - top), Color(red: 0.40, green: 0.44, blue: 0.54), corner: 6)
    var desk = Path()
    desk.move(to: CGPoint(x: x - 55, y: top + 8))
    desk.addLine(to: CGPoint(x: x - 45, y: top - 8))
    desk.addLine(to: CGPoint(x: x + 45, y: top - 8))
    desk.addLine(to: CGPoint(x: x + 55, y: top + 8))
    desk.closeSubpath()
    ctx.fill(desk, with: .color(Color(red: 0.55, green: 0.60, blue: 0.70)))
    // Screen on a stalk
    let scr = CGRect(x: x - 55, y: top - 88, width: 110, height: 52)
    fill(ctx, CGRect(x: x - 3, y: scr.maxY, width: 6, height: top - 8 - scr.maxY), Color(white: 0.4))
    fill(ctx, scr.insetBy(dx: -4, dy: -4), Color(red: 0.3, green: 0.33, blue: 0.42), corner: 6)
    fill(ctx, scr, .black, corner: 4)
    let lines = d.screenText(now).split(separator: "\n")
    for (i, line) in lines.enumerated() {
        ctx.draw(Text(String(line)).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(alienGreen),
                 at: CGPoint(x: scr.midX, y: scr.midY + (Double(i) - Double(lines.count - 1) / 2) * 15))
    }
    // Little lights across the front
    for i in 0..<6 {
        let on = sin(t * 5 + Double(i) * 1.3) > 0
        ctx.fill(circle(CGPoint(x: x - 28 + Double(i) * 11, y: top + 22), 3), with: .color([Color.red, .yellow, .cyan][i % 3].opacity(on ? 1 : 0.3)))
    }
    // The big glowing green button
    let b = Stage.greenButton
    let pressed = now.timeIntervalSince(d.consolePressT0)
    let glow = pressed >= 0 && pressed < 1.2 ? 1.0 : 0.6 + 0.4 * sin(t * 4)
    ctx.fill(circle(b, 24), with: .radialGradient(Gradient(colors: [alienGreen.opacity(0.75 * glow), .clear]), center: b, startRadius: 4, endRadius: 24))
    let down = pressed >= 0 && pressed < 0.3 ? 2.0 : 0
    ctx.fill(Path(ellipseIn: CGRect(x: b.x - 12, y: b.y - 7 + down, width: 24, height: 12)), with: .color(alienGreen))
    ctx.fill(Path(ellipseIn: CGRect(x: b.x - 6, y: b.y - 5 + down, width: 7, height: 3)), with: .color(.white.opacity(0.8)))
}

/// The chair back and the transformation ring hanging over it.
private func drawChairBack(_ ctx: GraphicsContext, x: Double, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let back = CGRect(x: x - 42, y: Stage.floorY - 200, width: 84, height: 170)
    fill(ctx, back, Color(red: 0.62, green: 0.66, blue: 0.76), corner: 30)
    fill(ctx, back.insetBy(dx: 8, dy: 8), Color(red: 0.48, green: 0.52, blue: 0.62), corner: 24)
    fill(ctx, CGRect(x: x - 5, y: Stage.floorY - 30, width: 10, height: 30), Color(white: 0.45))
    fill(ctx, CGRect(x: x - 30, y: Stage.floorY - 6, width: 60, height: 6), Color(white: 0.4), corner: 3)
    // Cable up to a ring over the chair
    fill(ctx, CGRect(x: x - 2, y: 150, width: 4, height: back.minY - 190), Color(white: 0.5))
    let ring = CGRect(x: x - 48, y: back.minY - 44, width: 96, height: 22)
    let running = d.everyone.contains { $0.seated && abs($0.x(at: now) - x) < 2 && $0.isTingling(at: now) }
    let tint = d.everyone.first { $0.seated && abs($0.x(at: now) - x) < 2 }?.alien?.color ?? alienGreen
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
    fill(ctx, CGRect(x: x - 40, y: seatY, width: 80, height: 12), Color(red: 0.62, green: 0.66, blue: 0.76), corner: 5)
    for i in 0..<2 {
        let hd = pose.hand[i]
        fill(ctx, CGRect(x: hd.x - 12, y: hd.y + pose.armW * 0.3, width: 24, height: 8), Color(red: 0.55, green: 0.59, blue: 0.70), corner: 3)
        fill(ctx, CGRect(x: hd.x - 3, y: hd.y + pose.armW * 0.3 + 8, width: 6, height: seatY - hd.y), Color(red: 0.50, green: 0.54, blue: 0.64))
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
    fill(ctx, CGRect(x: chest.minX, y: chest.midY - 0.8, width: chest.width, height: 1.6), alienGreen.opacity(0.9), corner: 1)
    for pt in pose.hand + pose.foot {
        let r = CGRect(x: pt.x - 9 * u, y: pt.y - 3, width: 18 * u, height: 6)
        fill(ctx, r, band, corner: 2)
        fill(ctx, CGRect(x: r.minX, y: r.midY - 0.7, width: r.width, height: 1.4), alienGreen.opacity(0.9))
    }
}

/// The big mirror the aliens lower in front of the chairs, showing the family their reflection.
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
        screen.fill(circle(CGPoint(x: x, y: frame.minY + 9), 3.5), with: .color(alienGreen.opacity(0.8)))
    }

    // The reflection: the family in their chairs, left and right swapped.
    var m = screen
    m.clip(to: Path(roundedRect: glass, cornerRadius: 12))
    m.translateBy(x: glass.maxX, y: glass.minY)
    m.scaleBy(x: -w / view.width, y: w / view.width)
    m.translateBy(x: -view.minX, y: -view.minY)
    drawShip(m, d: d, now: now)
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

private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, now: Date, cam: CGRect) {
    guard let text = p.says, now < p.saysUntil else { return }
    // Bubbles grow with the zoom as before, but only up to double size.
    let zoom = Stage.W / cam.width
    let k = min(zoom, 2)
    let resolved = ctx.resolve(Text(text).font(.system(size: 15 * k, weight: .medium, design: .rounded)).foregroundStyle(.black))
    let size = resolved.measure(in: CGSize(width: 230 * k, height: 200 * k))
    let pose = Pose(p, feet: feet, facing: p.facing, now: now)
    let worldTop = pose.headTop - (p.alienLevels(at: now).head * pose.hr * 0.7)
    let x = (feet.x - cam.minX) * zoom
    let top = (worldTop - cam.minY) * zoom
    var box = CGRect(x: x - size.width / 2 - 10 * k, y: top - size.height - 30 * k,
                     width: size.width + 20 * k, height: size.height + 14 * k)
    box.origin.x = min(max(box.minX, 6), Stage.W - box.width - 6)
    box.origin.y = min(max(box.minY, 4), Stage.H - box.height - 70)
    let tipX = min(max(x, box.minX + 20), box.maxX - 20)

    var bubble = Path(roundedRect: box, cornerRadius: 10 * k)
    bubble.move(to: CGPoint(x: tipX - 7 * k, y: box.maxY - 1))
    bubble.addLine(to: CGPoint(x: tipX, y: box.maxY + 12 * k))
    bubble.addLine(to: CGPoint(x: tipX + 7 * k, y: box.maxY - 1))
    ctx.fill(bubble, with: .color(p.crew ? Color(red: 0.88, green: 1, blue: 0.88) : .white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10 * k), with: .color(p.crew ? Color(red: 0.1, green: 0.6, blue: 0.2) : .black.opacity(0.35)), lineWidth: 1.5 * k)
    ctx.draw(resolved, in: box.insetBy(dx: 10 * k, dy: 7 * k))
}

/// The aliens' deal, or the note on the green button, drawn over whatever the camera shows.
private func drawCard(_ ctx: GraphicsContext, _ card: Card, signT0: Date, now: Date) {
    if card == .letter {
        drawLetter(ctx)
        return
    }
    if card == .papers {
        drawDivorcePapers(ctx, signT0: signT0, now: now)
        return
    }
    let (title, lines): (String, [String]) = switch card {
    case .deal: ("THE ALIENS' DEAL", [
        "We will fly you to a place of your choosing to get other people to try this:",
        "   Downtown Las Vegas, St. Kitts, Celebration Key, Half Moon Cay,",
        "   Catalina Island, Rio de Janeiro, Ocean Cay, La Bufadora, or King's Wharf Bermuda.",
        "The only catch: you have to pay for the setup.",
        "Two of you stand outside, while the other two work the machine.",
        "Each time you do it again, the two pairs trade places.",
        "Customers choose green, pink, orange, lavender, light blue, or bright red.",
        "After a customer pays, the beam pulls them into the chairs.",
        "Customers change back after eight hours.",
        "Yours fades 50% when we take you home — one minute later, back to normal.",
    ])
    case .note: ("A NOTE ON THE GLOWING GREEN BUTTON", [
        "If you want to do this again to make some more money,",
        "press this green button.",
        "",
        "You will have the choice of what color",
        "Roswell alien you want to be transformed into.",
    ])
    case .letter, .papers: ("", [])
    }
    let height = 110 + Double(lines.count) * 29
    let card = CGRect(x: 170, y: 24, width: 860, height: height)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 14)
    fill(ctx, card, Color(red: 0.06, green: 0.10, blue: 0.10), corner: 14)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 14), with: .color(alienGreen), lineWidth: 3)
    ctx.draw(Text(title).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(alienGreen),
             at: CGPoint(x: card.midX, y: card.minY + 34))
    for (i, c) in AlienColor.allCases.enumerated() {
        ctx.fill(circle(CGPoint(x: card.midX + (Double(i) - Double(AlienColor.allCases.count - 1) / 2) * 30, y: card.minY + 64), 8), with: .color(c.color))
    }
    for (i, s) in lines.enumerated() {
        ctx.draw(Text(s).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.93)),
                 at: CGPoint(x: card.minX + 34, y: card.minY + 98 + Double(i) * 29), anchor: .leading)
    }
}

/// The letter from Mom's husband: handwriting-style text on a sheet of cream notepaper.
private func drawLetter(_ ctx: GraphicsContext) {
    let lines = [
        "I have been working hard to keep you and your kids supported.",
        "It seems that you are not giving me that much in return.",
        "I know that I have been combative a lot, but it just pushed you further away.",
        "I have decided to file for a divorce.",
        "You should receive the papers in the mail soon. Just sign them.",
        "Don't make this any harder than it already is.",
    ]
    let card = CGRect(x: 170, y: 24, width: 860, height: 110 + Double(lines.count) * 34)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 4)
    fill(ctx, card, Color(red: 0.99, green: 0.97, blue: 0.90), corner: 4)
    for (i, _) in lines.enumerated() {
        fill(ctx, CGRect(x: card.minX + 26, y: card.minY + 104 + Double(i) * 34, width: card.width - 52, height: 1), Color(red: 0.55, green: 0.70, blue: 0.90).opacity(0.6))
    }
    fill(ctx, CGRect(x: card.minX + 60, y: card.minY, width: 1.5, height: card.height), Color(red: 0.90, green: 0.45, blue: 0.45).opacity(0.6))
    ctx.draw(Text("A LETTER FROM HER HUSBAND").font(.system(size: 22, weight: .heavy, design: .serif)).foregroundStyle(Color(red: 0.25, green: 0.22, blue: 0.30)),
             at: CGPoint(x: card.midX, y: card.minY + 34))
    for (i, s) in lines.enumerated() {
        ctx.draw(Text(s).font(.system(size: 19, weight: .regular, design: .serif).italic()).foregroundStyle(Color(red: 0.12, green: 0.15, blue: 0.40)),
                 at: CGPoint(x: card.minX + 72, y: card.minY + 88 + Double(i) * 34), anchor: .leading)
    }
}

/// The divorce papers: a typed legal form, with Mom's signature writing itself across the line from `signT0`.
private func drawDivorcePapers(_ ctx: GraphicsContext, signT0: Date, now: Date) {
    let page = CGRect(x: 300, y: 20, width: 600, height: 340)
    fill(ctx, page.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 3)
    fill(ctx, page, .white, corner: 3)
    let ink = Color(white: 0.15)
    ctx.draw(Text("PETITION FOR DISSOLUTION OF MARRIAGE").font(.system(size: 19, weight: .bold, design: .serif)).foregroundStyle(ink),
             at: CGPoint(x: page.midX, y: page.minY + 34))
    fill(ctx, CGRect(x: page.minX + 40, y: page.minY + 52, width: page.width - 80, height: 1.5), ink)
    let lines = [
        "The parties agree that the marriage is irretrievably broken.",
        "Both parties consent to this divorce and waive any further hearing.",
        "The petitioner and respondent each sign below.",
    ]
    for (i, s) in lines.enumerated() {
        ctx.draw(Text(s).font(.system(size: 14, design: .serif)).foregroundStyle(ink.opacity(0.85)),
                 at: CGPoint(x: page.minX + 40, y: page.minY + 82 + Double(i) * 24), anchor: .leading)
    }
    // Typed filler lines
    for i in 0..<3 {
        fill(ctx, CGRect(x: page.minX + 40, y: page.minY + 164 + Double(i) * 16, width: page.width - (i == 2 ? 220 : 80), height: 5), Color(white: 0.82), corner: 2)
    }
    // His signature, already there
    ctx.draw(Text("Respondent:").font(.system(size: 13, weight: .semibold, design: .serif)).foregroundStyle(ink),
             at: CGPoint(x: page.minX + 40, y: page.minY + 240), anchor: .leading)
    fill(ctx, CGRect(x: page.minX + 140, y: page.minY + 248, width: 200, height: 1.2), ink)
    var his = Path()
    his.move(to: CGPoint(x: page.minX + 150, y: page.minY + 244))
    for k in 1...12 {
        let x = page.minX + 150 + Double(k) * 14
        his.addQuadCurve(to: CGPoint(x: x, y: page.minY + 244 - (k % 2 == 0 ? 2 : 12)), control: CGPoint(x: x - 7, y: page.minY + 230 + (k % 3 == 0 ? 18 : 0)))
    }
    ctx.stroke(his, with: .color(Color(red: 0.10, green: 0.10, blue: 0.35)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
    // Her line, with a flag to "sign here"
    ctx.draw(Text("Petitioner:").font(.system(size: 13, weight: .semibold, design: .serif)).foregroundStyle(ink),
             at: CGPoint(x: page.minX + 40, y: page.minY + 296), anchor: .leading)
    let line = CGRect(x: page.minX + 140, y: page.minY + 304, width: 260, height: 1.2)
    fill(ctx, line, ink)
    let u = min(max(now.timeIntervalSince(signT0) / 2.6, 0), 1)
    if u < 1 {
        fill(ctx, CGRect(x: line.maxX + 20, y: line.minY - 22, width: 90, height: 24), Color(red: 1, green: 0.85, blue: 0.20), corner: 4)
        ctx.draw(Text("SIGN HERE ◀").font(.system(size: 11, weight: .heavy)).foregroundStyle(ink), at: CGPoint(x: line.maxX + 65, y: line.minY - 10))
    }
    // Her signature loops across the line as she writes it.
    var sig = Path()
    let y0 = line.minY - 6
    sig.move(to: CGPoint(x: line.minX + 8, y: y0))
    sig.addCurve(to: CGPoint(x: line.minX + 40, y: y0 - 4), control1: CGPoint(x: line.minX + 14, y: y0 - 34), control2: CGPoint(x: line.minX + 30, y: y0 - 30))
    for k in 0..<9 {
        let x = line.minX + 40 + Double(k + 1) * 22
        sig.addCurve(to: CGPoint(x: x, y: y0 - 2), control1: CGPoint(x: x - 18, y: y0 - (k % 2 == 0 ? 22 : 10)), control2: CGPoint(x: x - 6, y: y0 + 6))
    }
    sig.addQuadCurve(to: CGPoint(x: line.maxX - 10, y: y0 - 18), control: CGPoint(x: line.maxX - 30, y: y0 + 10))
    if u > 0 {
        let drawn = sig.trimmedPath(from: 0, to: u)
        ctx.stroke(drawn, with: .color(Color(red: 0.08, green: 0.20, blue: 0.65)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        if u < 1, let tip = drawn.currentPoint {
            // The pen
            var pen = ctx
            pen.translateBy(x: tip.x, y: tip.y)
            pen.rotate(by: .degrees(-35))
            fill(pen, CGRect(x: -3, y: -46, width: 6, height: 40), Color(red: 0.15, green: 0.15, blue: 0.20), corner: 2)
            var nib = Path()
            nib.move(to: CGPoint(x: -3, y: -6)); nib.addLine(to: CGPoint(x: 0, y: 0)); nib.addLine(to: CGPoint(x: 3, y: -6)); nib.closeSubpath()
            pen.fill(nib, with: .color(Color(white: 0.7)))
        }
    }
    ctx.draw(Text("Date: ____________").font(.system(size: 12, design: .serif)).foregroundStyle(ink.opacity(0.8)),
             at: CGPoint(x: page.maxX - 40, y: page.minY + 240), anchor: .trailing)
}

/// How alien each family member is, top right.
private func drawHUD(_ ctx: GraphicsContext, d: Director, now: Date) {
    guard d.team.contains(where: { $0.alien != nil }) else { return }
    for (i, p) in d.team.enumerated() {
        let r = CGRect(x: Stage.W - 220, y: 12 + Double(i) * 30, width: 208, height: 25)
        fill(ctx, r, .black.opacity(0.55), corner: 12.5)
        ctx.draw(Text(p.id).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: r.minX + 12, y: r.midY), anchor: .leading)
        let u = p.progress(at: now)
        let s = p.strength(at: now)
        let (label, color): (String, Color) = if p.alien != nil, now < p.changeT0, p.isTingling(at: now) { ("tingling…", .yellow) }
            else if p.alien != nil, u < 1, now >= p.changeT0 { ("changing \(Int(u * 100))%", .orange) }
            else if let alien = p.alien, s > 0.005, u >= 1 { ("\(alien.name.uppercased()) \(Int((s * 100).rounded()))%", .white) }
            else if p.alien != nil, u >= 1 { ("human again", .white.opacity(0.7)) } else { ("human", .white.opacity(0.6)) }
        if let alien = p.alien {
            ctx.fill(circle(CGPoint(x: r.minX + 72, y: r.midY), 5), with: .color(alien.color.opacity(max(0.25, s))))
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
    ctx.stroke(circle(c, 30), with: .color(alienGreen), lineWidth: 4)
    var wedge = Path()
    wedge.move(to: c)
    wedge.addArc(center: c, radius: 26, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * u), clockwise: false)
    wedge.closeSubpath()
    ctx.fill(wedge, with: .color(alienGreen.opacity(0.5)))
    var hand = Path()
    hand.move(to: c)
    hand.addLine(to: CGPoint(x: c.x + sin(u * 2 * .pi) * 24, y: c.y - cos(u * 2 * .pi) * 24))
    ctx.stroke(hand, with: .color(.black), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    ctx.draw(Text(d.clockLabel).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: card.minX + 90, y: card.minY + 30), anchor: .leading)
    let left = max(0, d.clockSpan - Int(u * Double(d.clockSpan)))
    ctx.draw(Text(String(format: "%d:%02d", left / 60, left % 60)).font(.system(size: 28, weight: .black, design: .monospaced)).foregroundStyle(alienGreen),
             at: CGPoint(x: card.minX + 90, y: card.minY + 62), anchor: .leading)
}

private func drawCashPop(_ ctx: GraphicsContext, _ text: String, x: Double, age: Double) {
    guard age >= 0 && age < 2 else { return }
    let color: Color = text.hasPrefix("-") ? .red : Color(red: 0.10, green: 0.60, blue: 0.20)
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(color.opacity(1 - age / 2)),
             at: CGPoint(x: x, y: Stage.floorY - 215 - age * 30))
}
