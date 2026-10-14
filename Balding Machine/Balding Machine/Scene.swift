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

    static let booth = CGRect(x: 20, y: floorY - 250, width: 240, height: 250)
    static let seatX = 105.0
    /// The glowing button on its post beside the chair.
    static let button = CGPoint(x: 152, y: floorY - 74)
    static let mirror = CGRect(x: 345, y: floorY - 190, width: 55, height: 125)
    static let mirrorStand = 425.0
    static let watchX = [285.0, 312.0, 339.0]
    static let doorX = 810.0
    static let couchX = [715.0, 745.0, 775.0]
    /// Mom, Ava, Mia, Rosie.
    static let roomX = [505.0, 915.0, 1030.0, 1143.0]
    /// At a venue the booth and a stand-up mirror move right by this much.
    static let venueShift = 470.0
    /// Venue spots: Rosie hosts, Ava and Mia greet, Mom takes the money, visitors stop, customers wait.
    static let hostX = 455.0
    static let greetX = [985.0, 1015.0]
    static let momX = 1047.0
    static let cashX = 1080.0
    static let stopX = [1135.0, 1165.0]
    static let waitX = [935.0, 960.0]

    // Camera shots, all the stage's 2:1 shape.
    static let full = CGRect(x: 0, y: 0, width: W, height: H)
    static let boothView = CGRect(x: 0, y: 215, width: 580, height: 290)

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

    // The booth and mirror are drawn in booth space, shifted to the middle at a venue.
    let dx = d.boothDX
    var booth = ctx
    booth.translateBy(x: dx, y: 0)
    if let venue = d.venue {
        drawVenue(ctx, venue, raised: d.raised, now: now)
        drawStandingMirror(booth, accent: venue.accent)
        drawCashTable(ctx, accent: venue.accent, charity: venue.isCharity)
    } else {
        drawHouse(ctx, d: d, now: now)
    }
    drawBoothBack(booth, d: d, now: now)
    for x in d.boxes where d.venue == nil { drawBox(ctx, center: CGPoint(x: x, y: Stage.floorY - 13), size: 30) }

    let people = d.everyone.filter(\.visible)
    for p in people where abs(p.x(at: now) - Stage.mirrorStand - dx) < 3 && !p.isWalking(at: now) && !p.seated {
        drawReflection(booth, p, now: now)
    }
    // Whoever is in the chair sits behind the dome and the glass; everyone else walks in front.
    for p in people where p.seated {
        drawPerson(ctx, p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: p.facing, now: now)
    }
    drawDome(booth, d: d, now: now)
    drawBoothFront(booth, d: d)
    for p in people.filter({ !$0.seated }).sorted(by: { $0.height > $1.height }) {
        drawPerson(ctx, p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: p.facing, now: now)
    }
    for p in people { drawSpeech(ctx, p, now: now) }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, x: pop.x, age: now.timeIntervalSince(pop.t0)) }

    // Screen-space overlays
    if now < d.signUntil { drawSignCard(screen) }
    if d.venue == nil { drawHUD(screen, d: d, now: now) }
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

    drawBed(ctx, x: 452, width: 100, blanket: Color(red: 0.95, green: 0.50, blue: 0.45))
    drawBathroom(ctx)
    drawLivingRoom(ctx, doorOpen: now < d.doorOpenUntil)
    drawBed(ctx, x: 870, width: 82, blanket: Color(red: 0.25, green: 0.60, blue: 0.60))
    drawBed(ctx, x: 985, width: 82, blanket: Color(red: 0.55, green: 0.40, blue: 0.80))
    drawBed(ctx, x: 1100, width: 72, blanket: Color(red: 0.98, green: 0.55, blue: 0.75))
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

private func drawReflection(_ ctx: GraphicsContext, _ p: Person, now: Date) {
    let m = Stage.mirror
    var r = ctx
    r.clip(to: Path(roundedRect: m, cornerRadius: 26))
    r.opacity = 0.9
    let scale = 0.75
    r.translateBy(x: m.midX, y: m.maxY + p.height * 0.28)
    r.scaleBy(x: scale, y: scale)
    drawPerson(r, p, feet: .zero, facing: -p.facing, now: now, reflection: true)
    var sheen = Path()
    sheen.move(to: CGPoint(x: m.minX + 12, y: m.minY + 40))
    sheen.addLine(to: CGPoint(x: m.minX + 30, y: m.minY + 18))
    ctx.stroke(sheen, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
}

// MARK: Booth

private let boothFrame = Color(red: 0.20, green: 0.30, blue: 0.40)
private let glow = Color(red: 0.20, green: 0.95, blue: 0.85)
private let cream = Color(red: 1.0, green: 0.78, blue: 0.86)
private let water = Color(red: 0.55, green: 0.80, blue: 1.0)

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
    fill(ctx, sign, Color(red: 0.10, green: 0.14, blue: 0.18), corner: 6)
    let pulse = 0.75 + 0.25 * sin(t * 3)
    ctx.stroke(Path(roundedRect: sign, cornerRadius: 6), with: .color(glow.opacity(pulse)), lineWidth: 2.5)
    ctx.draw(Text("1-MINUTE HAIR REMOVAL").font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(glow.opacity(pulse)),
             at: CGPoint(x: sign.midX, y: sign.midY))

    fill(ctx, b, boothFrame, corner: 10)
    ctx.fill(Path(inner), with: .linearGradient(Gradient(colors: [Color(red: 0.86, green: 0.94, blue: 0.97), Color(red: 0.70, green: 0.82, blue: 0.88)]),
                                                startPoint: CGPoint(x: 0, y: inner.minY), endPoint: CGPoint(x: 0, y: inner.maxY)))
    // Tiles on the back wall and a drain in the floor
    for row in 0..<7 {
        for col in 0..<11 {
            ctx.stroke(Path(CGRect(x: inner.minX + Double(col) * 20, y: inner.minY + 40 + Double(row) * 20, width: 20, height: 20)),
                       with: .color(.white.opacity(0.5)), lineWidth: 1)
        }
    }
    fill(ctx, CGRect(x: inner.minX, y: inner.maxY - 8, width: inner.width, height: 8), Color(white: 0.55))
    fill(ctx, CGRect(x: Stage.seatX + 40, y: inner.maxY - 6, width: 26, height: 4), Color(white: 0.3), corner: 2)
    // Tanks of cream and water on the back wall
    for (i, (label, c)) in [("CREAM", cream), ("RINSE", water)].enumerated() {
        let tank = CGRect(x: inner.maxX - 48, y: inner.minY + 48 + Double(i) * 56, width: 36, height: 48)
        fill(ctx, tank, c, corner: 6)
        ctx.stroke(Path(roundedRect: tank, cornerRadius: 6), with: .color(Color(white: 0.5)), lineWidth: 1.5)
        ctx.draw(Text(label).font(.system(size: 7, weight: .heavy, design: .rounded)).foregroundStyle(.black.opacity(0.6)),
                 at: CGPoint(x: tank.midX, y: tank.midY))
    }

    // Header with the status screen
    let head = CGRect(x: b.minX, y: b.minY, width: b.width, height: 30)
    fill(ctx, head, Color(red: 0.10, green: 0.14, blue: 0.18), corner: 8)
    ctx.draw(Text("AUTO-BALD").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(glow),
             at: CGPoint(x: head.minX + 44, y: head.midY))
    let scr = CGRect(x: head.maxX - 104, y: head.minY + 6, width: 94, height: 18)
    fill(ctx, scr, .black, corner: 3)
    ctx.draw(Text(d.screenText(now)).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.green),
             at: CGPoint(x: scr.midX, y: scr.midY))

    // Salon chair facing right
    let chair = Color(red: 0.95, green: 0.45, blue: 0.60)
    let seatY = Stage.floorY - 30
    fill(ctx, CGRect(x: Stage.seatX - 38, y: seatY - 70, width: 11, height: 78), chair, corner: 5)
    fill(ctx, CGRect(x: Stage.seatX - 28, y: seatY, width: 60, height: 8), chair, corner: 4)
    fill(ctx, CGRect(x: Stage.seatX - 3, y: seatY + 8, width: 6, height: 17), Color(white: 0.6))
    fill(ctx, CGRect(x: Stage.seatX - 22, y: Stage.floorY - 6, width: 44, height: 5), Color(white: 0.45), corner: 2)

    // The glowing button on its post
    let bt = Stage.button
    fill(ctx, CGRect(x: bt.x - 5, y: bt.y + 4, width: 10, height: Stage.floorY - bt.y - 4), Color(white: 0.45), corner: 2)
    fill(ctx, CGRect(x: bt.x - 11, y: bt.y - 3, width: 22, height: 9), Color(white: 0.3), corner: 3)
    let pressed = now.timeIntervalSince(d.pressT0)
    let lit = d.domePerson == nil || (pressed >= 0 && pressed < 0.4)
    let gl = lit ? 0.55 + 0.45 * sin(t * 4) : 0.15
    ctx.fill(circle(bt, 16), with: .radialGradient(Gradient(colors: [Color.red.opacity(gl * 0.7), .clear]), center: bt, startRadius: 3, endRadius: 16))
    ctx.fill(circle(bt, 6.5), with: .color(lit ? Color(red: 1, green: 0.25, blue: 0.25) : Color(red: 0.45, green: 0.1, blue: 0.1)))
    ctx.fill(circle(CGPoint(x: bt.x - 2, y: bt.y - 2), 2), with: .color(.white.opacity(0.7)))
}

/// Where the dome is and how big: resting up under the header, or down over the sitter's head.
private func domeGeometry(_ d: Director, now: Date) -> (center: CGPoint, rx: Double, ry: Double, head: (CGPoint, Double)?) {
    let rest = CGPoint(x: Stage.seatX, y: boothInner.minY + 34)
    guard let p = d.domePerson else { return (rest, 30, 28, nil) }
    let pose = Pose(p, feet: CGPoint(x: Stage.seatX, y: Stage.floorY), facing: p.facing, now: now)
    let target = CGPoint(x: pose.head.x, y: pose.head.y - pose.hr * 0.3)
    let (rx, ry) = (pose.hr * 1.9, pose.hr * 1.85)
    let t = now.timeIntervalSince(d.boothT0)
    let (phase, u) = BoothRun.phase(t)
    func ease(_ u: Double) -> Double { u * u * (3 - 2 * u) }
    let down: Double = switch phase {
    case .lowering: ease(u)
    case .lifting: 1 - ease(u)
    case .done: 0
    default: 1
    }
    let c = CGPoint(x: rest.x + (target.x - rest.x) * down, y: rest.y + (target.y - rest.y) * down)
    return (c, 30 + (rx - 30) * down, 28 + (ry - 28) * down, (pose.head, pose.hr))
}

private func drawDome(_ ctx: GraphicsContext, d: Director, now: Date) {
    let (c, rx, ry, head) = domeGeometry(d, now: now)
    let dome = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
    let domePath = Path(ellipseIn: dome)

    // Telescoping arm from the ceiling
    let top = boothInner.minY
    fill(ctx, CGRect(x: c.x - 4, y: top, width: 8, height: dome.minY - top + 4), Color(white: 0.55))
    fill(ctx, CGRect(x: c.x - 7, y: top, width: 14, height: 10), Color(white: 0.4), corner: 2)

    ctx.fill(domePath, with: .color(Color(red: 0.75, green: 0.92, blue: 1).opacity(0.22)))

    if let (hd, hr) = head {
        let t = now.timeIntervalSince(d.boothT0)
        let (phase, u) = BoothRun.phase(t)
        let seal = hd.y - hr * 0.2
        var inside = ctx
        inside.clip(to: domePath)

        // Cream fills from the seal up; the rinse turns it to water, then it drains away.
        var level = 0.0
        var liquid = cream
        var opacity = 0.88
        switch phase {
        case .filling: level = u
        case .soaking: level = 1
        case .rinsing:
            level = u < 0.55 ? 1 : 1 - (u - 0.55) / 0.45
            liquid = u < 0.35 ? cream : water
            opacity = u < 0.35 ? 0.88 - u : 0.6
        default: level = 0
        }
        if level > 0 {
            let y = seal - (seal - dome.minY) * level
            inside.fill(Path(CGRect(x: dome.minX, y: y, width: dome.width, height: seal - y)), with: .color(liquid.opacity(opacity)))
            inside.fill(Path(CGRect(x: dome.minX, y: y, width: dome.width, height: 1.5)), with: .color(.white.opacity(0.9)))
            let tt = now.timeIntervalSinceReferenceDate
            if phase == .soaking || phase == .filling {
                // Fizzing bubbles
                for i in 0..<9 {
                    let k = Double(i)
                    let bx = dome.minX + dome.width * (0.15 + 0.7 * ((k * 0.37).truncatingRemainder(dividingBy: 1)))
                    let rise = (tt * 0.6 + k * 0.29).truncatingRemainder(dividingBy: 1)
                    let by = seal - (seal - y) * rise
                    inside.stroke(circle(CGPoint(x: bx, y: by), hr * (0.06 + 0.04 * sin(k))), with: .color(.white.opacity(0.9)), lineWidth: 1)
                }
            }
        }
        if phase == .filling || phase == .rinsing {
            // Spray from the nozzle at the top
            let tt = now.timeIntervalSinceReferenceDate
            for i in 0..<12 {
                let k = Double(i)
                let fall = (tt * 2.2 + k * 0.083).truncatingRemainder(dividingBy: 1)
                let a = (k / 11 - 0.5) * 1.6
                let pt = CGPoint(x: c.x + sin(a) * rx * 0.9 * fall, y: dome.minY + 4 + (seal - dome.minY) * fall)
                inside.fill(Path(ellipseIn: CGRect(x: pt.x - 1.2, y: pt.y - 2, width: 2.4, height: 4)),
                            with: .color((phase == .filling ? Color(red: 1, green: 0.75, blue: 0.85) : Color(red: 0.25, green: 0.55, blue: 1)).opacity(0.9)))
            }
        }
        if phase == .drying {
            // Warm air: a glowing heater at the top and wavy gusts swirling down around the head.
            let tt = now.timeIntervalSinceReferenceDate
            let fade = min(1, u * 5, (1 - u) * 5)
            inside.fill(Path(ellipseIn: CGRect(x: c.x - rx * 0.8, y: dome.minY - ry * 0.3, width: rx * 1.6, height: ry * 0.7)),
                        with: .radialGradient(Gradient(colors: [Color.orange.opacity(0.45 * fade), .clear]),
                                              center: CGPoint(x: c.x, y: dome.minY), startRadius: 2, endRadius: rx * 0.8))
            for i in 0..<7 {
                let k = Double(i)
                let fall = (tt * 1.4 + k / 7).truncatingRemainder(dividingBy: 1)
                let x0 = dome.minX + dome.width * (0.12 + 0.76 * k / 6)
                let y0 = dome.minY + 6 + (seal - dome.minY - 12) * fall
                var gust = Path()
                for step in 0...8 {
                    let s = Double(step) / 8
                    let pt = CGPoint(x: x0 + sin(s * .pi * 2 + tt * 6 + k) * hr * 0.12, y: y0 + s * hr * 0.5)
                    step == 0 ? gust.move(to: pt) : gust.addLine(to: pt)
                }
                inside.stroke(gust, with: .color(Color(red: 1, green: 0.6, blue: 0.25).opacity(0.75 * fade * sin(fall * .pi))),
                              style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
            // Last few droplets on the scalp shrink away.
            for i in 0..<5 {
                let a = (205.0 + Double(i) * 32) * .pi / 180
                let r = hr * 0.09 * max(0, 1 - u * 1.4)
                if r > 0.2 {
                    inside.fill(Path(ellipseIn: CGRect(x: hd.x + cos(a) * hr * 0.9 - r, y: hd.y + sin(a) * hr * 0.9 - r, width: r * 2, height: r * 2.4)),
                                with: .color(water.opacity(0.8)))
                }
            }
        }
        if phase != .lowering && phase != .lifting && phase != .done {
            // The soft seal band around the brow
            inside.fill(Path(CGRect(x: dome.minX, y: seal, width: dome.width, height: hr * 0.14)), with: .color(Color(red: 0.95, green: 0.55, blue: 0.70)))
        }
    }

    ctx.stroke(domePath, with: .color(.white.opacity(0.85)), lineWidth: 2)
    var sheen = Path()
    sheen.addArc(center: c, radius: min(rx, ry) * 0.78, startAngle: .degrees(200), endAngle: .degrees(245), clockwise: false)
    ctx.stroke(sheen, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    fill(ctx, CGRect(x: c.x - 6, y: dome.minY - 2, width: 12, height: 6), Color(white: 0.4), corner: 2)
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

private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, now: Date) {
    guard let text = p.says, now < p.saysUntil else { return }
    let resolved = ctx.resolve(Text(text).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.black))
    let size = resolved.measure(in: CGSize(width: 220, height: 200))
    let x = p.x(at: now)
    let pose = Pose(p, feet: CGPoint(x: x, y: Stage.floorY), facing: p.facing, now: now)
    var box = CGRect(x: x - size.width / 2 - 10, y: pose.headTop - size.height - 30, width: size.width + 20, height: size.height + 14)
    box.origin.x = min(max(box.minX, 6), Stage.W - box.width - 6)

    var bubble = Path(roundedRect: box, cornerRadius: 10)
    bubble.move(to: CGPoint(x: x - 7, y: box.maxY - 1))
    bubble.addLine(to: CGPoint(x: x, y: box.maxY + 12))
    bubble.addLine(to: CGPoint(x: x + 7, y: box.maxY - 1))
    ctx.fill(bubble, with: .color(.white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10), with: .color(.black.opacity(0.35)), lineWidth: 1.5)
    ctx.draw(resolved, in: box.insetBy(dx: 10, dy: 7))
}

/// The booth's instructions, drawn over whatever the camera shows.
private func drawSignCard(_ ctx: GraphicsContext) {
    let card = CGRect(x: 330, y: 30, width: 540, height: 200)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 14)
    fill(ctx, card, Color(red: 0.10, green: 0.14, blue: 0.18), corner: 14)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 14), with: .color(glow), lineWidth: 3)
    ctx.draw(Text("AUTO-BALD HAIR REMOVAL BOOTH").font(.system(size: 25, weight: .black, design: .rounded)).foregroundStyle(glow),
             at: CGPoint(x: card.midX, y: card.minY + 30))
    let steps = ["1. Sit in the chair", "2. Press the glowing button", "3. The dome fills with hair removal cream",
                 "4. One minute later: warm rinse", "5. Warm-air drying cycle", "6. Enjoy your smooth bald head!"]
    for (i, s) in steps.enumerated() {
        ctx.draw(Text(s).font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.92)),
                 at: CGPoint(x: card.minX + 40, y: card.minY + 62 + Double(i) * 23), anchor: .leading)
    }
    let head = CGPoint(x: card.maxX - 70, y: card.minY + 125)
    ctx.fill(circle(head, 36), with: .color(Color(red: 0.96, green: 0.80, blue: 0.68)))
}

/// Who still has hair, top right.
private func drawHUD(_ ctx: GraphicsContext, d: Director, now: Date) {
    guard d.cast.contains(where: \.bald) || d.domePerson != nil else { return }
    for (i, p) in d.cast.enumerated() {
        let r = CGRect(x: Stage.W - 150, y: 12 + Double(i) * 30, width: 138, height: 25)
        fill(ctx, r, .black.opacity(0.55), corner: 12.5)
        ctx.draw(Text(p.id).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: r.minX + 12, y: r.midY), anchor: .leading)
        let left = p.hairLeft(at: now)
        let (label, color): (String, Color) = left <= 0 ? ("BALD", glow) : left < 1 ? ("\(Int(left * 100))% hair", .orange) : ("hair", .white.opacity(0.6))
        ctx.draw(Text(label).font(.system(size: 12, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(color),
                 at: CGPoint(x: r.maxX - 12, y: r.midY), anchor: .trailing)
    }
}

// MARK: Venues

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

extension Venue {
    var accent: Color {
        switch self {
        case .carnival: .red
        case .amusementPark: Color(red: 0.60, green: 0.30, blue: 0.85)
        case .stBaldricks: Color(red: 0.15, green: 0.60, blue: 0.30)
        }
    }

    var banner: String {
        switch self {
        case .stBaldricks: "ST. BALDRICK'S  ·  BRAVE THE SHAVE  ·  FREE SHAVES, DONATIONS WELCOME"
        default: "\(name.uppercased())  ·  BALD IN ONE MINUTE  ·  $\(price)  ·  KIDS $\(kidPrice)"
        }
    }
}

private func drawVenue(_ ctx: GraphicsContext, _ venue: Venue, raised: Int, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    switch venue {
    case .carnival: drawCarnival(ctx, t: t)
    case .amusementPark: drawPark(ctx, t: t)
    case .stBaldricks: drawBaldricks(ctx, raised: raised, t: t)
    }
    // A little stage under the booth and mirror
    let x0 = Stage.booth.minX + Stage.venueShift - 20
    fill(ctx, CGRect(x: x0, y: Stage.floorY, width: 440, height: 14), Color(red: 0.62, green: 0.42, blue: 0.24))
    for x in stride(from: x0, to: x0 + 440, by: 40) {
        fill(ctx, CGRect(x: x, y: Stage.floorY, width: 2, height: 14), Color(red: 0.45, green: 0.30, blue: 0.16))
    }
    ctx.draw(Text(venue.banner).font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(venue.accent),
             at: CGPoint(x: 600, y: 34))
}

private func drawCarnival(_ ctx: GraphicsContext, t: Double) {
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: Stage.H - 400), Color(red: 0.45, green: 0.72, blue: 0.35))
    let hub = CGPoint(x: 1060, y: 250)
    let r = 125.0
    for dx in [-60.0, 60.0] {
        var leg = Path()
        leg.move(to: hub)
        leg.addLine(to: CGPoint(x: hub.x + dx, y: 420))
        ctx.stroke(leg, with: .color(Color(white: 0.55)), lineWidth: 6)
    }
    ctx.stroke(circle(hub, r), with: .color(Color(white: 0.6)), lineWidth: 5)
    let colors: [Color] = [.red, .yellow, .blue, .green, .orange, .pink, .purple, .cyan]
    for i in 0..<8 {
        let a = t * 0.25 + Double(i) / 8 * 2 * .pi
        let rim = CGPoint(x: hub.x + cos(a) * r, y: hub.y + sin(a) * r)
        var spoke = Path()
        spoke.move(to: hub)
        spoke.addLine(to: rim)
        ctx.stroke(spoke, with: .color(Color(white: 0.65)), lineWidth: 2)
        fill(ctx, CGRect(x: rim.x - 13, y: rim.y, width: 26, height: 20), colors[i], corner: 5)
    }
    for (x, c) in [(110.0, Color.red), (260.0, Color.blue)] {
        var tent = Path()
        tent.move(to: CGPoint(x: x - 65, y: 420))
        tent.addLine(to: CGPoint(x: x, y: 320))
        tent.addLine(to: CGPoint(x: x + 65, y: 420))
        tent.closeSubpath()
        ctx.fill(tent, with: .color(c))
        for k in stride(from: -40.0, through: 40, by: 40) {
            var stripe = Path()
            stripe.move(to: CGPoint(x: x, y: 320))
            stripe.addLine(to: CGPoint(x: x + k - 8, y: 420))
            stripe.addLine(to: CGPoint(x: x + k + 8, y: 420))
            stripe.closeSubpath()
            ctx.fill(stripe, with: .color(.white))
        }
    }
    drawBunting(ctx, colors: colors)
}

private func drawBunting(_ ctx: GraphicsContext, colors: [Color]) {
    for i in 0..<33 {
        let x = 4 + Double(i) * 36
        var flag = Path()
        flag.move(to: CGPoint(x: x, y: 70))
        flag.addLine(to: CGPoint(x: x + 30, y: 70))
        flag.addLine(to: CGPoint(x: x + 15, y: 95))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(colors[i % colors.count]))
    }
}

private func drawPark(_ ctx: GraphicsContext, t: Double) {
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: Stage.H - 400), Color(red: 0.45, green: 0.72, blue: 0.35))
    let stone = Color(red: 0.85, green: 0.80, blue: 0.90)
    fill(ctx, CGRect(x: 1020, y: 250, width: 150, height: 170), stone)
    for x in [1000.0, 1150.0] {
        fill(ctx, CGRect(x: x, y: 200, width: 40, height: 220), stone)
        var cone = Path()
        cone.move(to: CGPoint(x: x - 6, y: 200))
        cone.addLine(to: CGPoint(x: x + 20, y: 140))
        cone.addLine(to: CGPoint(x: x + 46, y: 200))
        cone.closeSubpath()
        ctx.fill(cone, with: .color(Color(red: 0.55, green: 0.30, blue: 0.80)))
    }
    fill(ctx, CGRect(x: 1075, y: 350, width: 40, height: 70), Color(red: 0.45, green: 0.30, blue: 0.20), corner: 18)
    func trackY(_ x: Double) -> Double { 260 + 90 * sin(x / 70) }
    for x in stride(from: 10.0, through: 400, by: 40) {
        fill(ctx, CGRect(x: x, y: trackY(x), width: 4, height: 420 - trackY(x)), Color(white: 0.6))
    }
    var track = Path()
    for x in stride(from: 0.0, through: 410, by: 5) {
        let pt = CGPoint(x: x, y: trackY(x))
        x == 0 ? track.move(to: pt) : track.addLine(to: pt)
    }
    ctx.stroke(track, with: .color(.red), lineWidth: 6)
    for k in 0..<3 {
        let x = (t * 90 + Double(k) * 26).truncatingRemainder(dividingBy: 410)
        fill(ctx, CGRect(x: x - 11, y: trackY(x) - 16, width: 22, height: 14), .yellow, corner: 4)
    }
    let colors: [Color] = [.red, .blue, .yellow, .green, .pink]
    for i in 0..<5 {
        let bx = 930 + Double(i) * 16
        let by = 340 + sin(t * 2 + Double(i)) * 4
        var string = Path()
        string.move(to: CGPoint(x: bx, y: by + 14))
        string.addLine(to: CGPoint(x: 960, y: 420))
        ctx.stroke(string, with: .color(.gray), lineWidth: 1)
        ctx.fill(Path(ellipseIn: CGRect(x: bx - 10, y: by - 14, width: 20, height: 28)), with: .color(colors[i]))
    }
}

/// Outdoor charity shave: a stage tent with shave chairs, green balloons and a donation thermometer.
private func drawBaldricks(_ ctx: GraphicsContext, raised: Int, t: Double) {
    let green = Venue.stBaldricks.accent
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: Stage.H - 400), Color(red: 0.45, green: 0.72, blue: 0.35))
    drawBunting(ctx, colors: [green, .orange, .white])

    // Stage tent on the left with a row of shave chairs
    let tent = CGRect(x: 20, y: 250, width: 400, height: 170)
    fill(ctx, tent, .white)
    var peak = Path()
    peak.move(to: CGPoint(x: tent.minX - 10, y: tent.minY))
    peak.addLine(to: CGPoint(x: tent.midX, y: tent.minY - 55))
    peak.addLine(to: CGPoint(x: tent.maxX + 10, y: tent.minY))
    peak.closeSubpath()
    ctx.fill(peak, with: .color(green))
    for i in 0..<8 {
        fill(ctx, CGRect(x: tent.minX + Double(i) * 50, y: tent.minY, width: 25, height: 16), i % 2 == 0 ? green : .orange)
    }
    ctx.draw(Text("BRAVE THE SHAVE").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(green),
             at: CGPoint(x: tent.midX, y: tent.minY + 45))
    ctx.draw(Text("for kids with cancer").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.orange),
             at: CGPoint(x: tent.midX, y: tent.minY + 72))
    for i in 0..<4 {
        let x = tent.minX + 70 + Double(i) * 85
        fill(ctx, CGRect(x: x - 16, y: 370, width: 32, height: 8), Color(white: 0.3), corner: 3)
        fill(ctx, CGRect(x: x - 16, y: 340, width: 7, height: 34), Color(white: 0.3), corner: 3)
        fill(ctx, CGRect(x: x - 2, y: 378, width: 4, height: 40), Color(white: 0.5))
    }

    // Donation thermometer
    let goal = 500.0
    let tube = CGRect(x: 425, y: 150, width: 22, height: 210)
    fill(ctx, tube.insetBy(dx: -4, dy: -4), .white, corner: 13)
    let level = min(Double(raised) / goal, 1)
    fill(ctx, CGRect(x: tube.minX, y: tube.maxY - tube.height * level, width: tube.width, height: tube.height * level), .red, corner: 11)
    ctx.fill(circle(CGPoint(x: tube.midX, y: tube.maxY + 14), 20), with: .color(.white))
    ctx.fill(circle(CGPoint(x: tube.midX, y: tube.maxY + 14), 16), with: .color(.red))
    ctx.draw(Text("$\(raised)").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(green),
             at: CGPoint(x: tube.midX, y: tube.minY - 18))
    ctx.draw(Text("GOAL $\(Int(goal))").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.black.opacity(0.6)),
             at: CGPoint(x: tube.midX, y: tube.minY - 4))

    let colors: [Color] = [green, .orange, green, .white, green]
    for i in 0..<5 {
        let bx = 890 + Double(i) * 16
        let by = 300 + sin(t * 2 + Double(i)) * 4
        var string = Path()
        string.move(to: CGPoint(x: bx, y: by + 14))
        string.addLine(to: CGPoint(x: 920, y: 400))
        ctx.stroke(string, with: .color(.gray), lineWidth: 1)
        ctx.fill(Path(ellipseIn: CGRect(x: bx - 10, y: by - 14, width: 20, height: 28)), with: .color(colors[i]))
    }
}

private func drawCashTable(_ ctx: GraphicsContext, accent: Color, charity: Bool) {
    let cx = Stage.cashX
    fill(ctx, CGRect(x: cx - 22, y: Stage.floorY - 44, width: 44, height: 44), accent.opacity(0.85), corner: 3)
    fill(ctx, CGRect(x: cx - 27, y: Stage.floorY - 48, width: 54, height: 7), .white, corner: 2)
    if charity {
        // A clear donation jar
        let jar = CGRect(x: cx - 12, y: Stage.floorY - 72, width: 24, height: 25)
        fill(ctx, jar, Color(red: 0.85, green: 0.95, blue: 1).opacity(0.8), corner: 4)
        fill(ctx, CGRect(x: jar.minX + 3, y: jar.maxY - 10, width: jar.width - 6, height: 8), Color(red: 0.40, green: 0.70, blue: 0.40), corner: 2)
        ctx.draw(Text("♥").font(.system(size: 10, weight: .black)).foregroundStyle(.red), at: CGPoint(x: cx, y: jar.minY + 8))
    } else {
        fill(ctx, CGRect(x: cx - 14, y: Stage.floorY - 62, width: 28, height: 15), Color(red: 0.30, green: 0.55, blue: 0.30), corner: 3)
        ctx.draw(Text("$").font(.system(size: 11, weight: .black)).foregroundStyle(.white), at: CGPoint(x: cx, y: Stage.floorY - 54.5))
    }
}

private func drawCashPop(_ ctx: GraphicsContext, _ text: String, x: Double, age: Double) {
    guard age >= 0 && age < 2 else { return }
    let color: Color = text.hasPrefix("-") ? .red : Color(red: 0.10, green: 0.60, blue: 0.20)
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(color.opacity(1 - age / 2)),
             at: CGPoint(x: x, y: Stage.floorY - 215 - age * 30))
}
