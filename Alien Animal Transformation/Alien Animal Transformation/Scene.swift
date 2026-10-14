import SwiftUI

/// World layout, in points. The same 1200×600 stage shows the house and front yard,
/// the inside of the flying zoo, a venue, the airport roadway, or the cab company's office.
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
        ("Debbie's Room", 650, 835, RGB(r: 0.86, g: 0.90, b: 0.98)),
        ("Hailey's Room", 835, 1020, RGB(r: 0.98, g: 0.85, b: 0.90)),
        ("Molly's Room", 1020, 1200, RGB(r: 0.90, g: 0.96, b: 0.82)),
    ]
    /// Debbie, Hailey, Molly: where each stands in her own room, and in the living room.
    static let roomX = [795.0, 980.0, 1160.0]
    static let livingX = [462.0, 560.0, 605.0]
    /// Left edge of each bed.
    static let bedX = [662.0, 847.0, 1032.0]
    /// Where the glowing red button turns up in the living room, and where everyone gathers round it.
    static let buttonX = 500.0
    static let buttonSpots = [462.0, 548.0, 590.0]

    /// Debbie's motorcycle in the driveway, and the repo men's flatbed backed up to it.
    static let bikeX = 245.0
    static let truckX = 110.0
    /// Where wheels of their own get parked.
    static let carX = 250.0
    static let motorcycleX = 130.0
    static let scooterX = 45.0

    /// The zoo hovers over the front yard, or over the stand at a venue.
    static let yardPodX = 200.0
    static let venuePodX = 330.0
    /// Height of the zoo's hatch above the ground while it hovers.
    static let hoverLift = 250.0
    /// How far the beam lifts someone to get them through the hatch.
    static var beamRise: Double { hoverLift - 20 }
    /// Everyone lines up under the zoo.
    static let yardLine = [150.0, 200.0, 250.0]

    // Inside the zoo
    static let chairX = [400.0, 540.0, 680.0]
    static let crewX = [310.0, 470.0, 610.0, 770.0, 850.0]
    /// Where anyone not in a chair waits, left of the chairs.
    static let standByX = [235.0, 195.0, 155.0]
    static let consoleX = 960.0
    static let redButton = CGPoint(x: 960, y: floorY - 96)
    /// Whoever works the machine stands here.
    static let controlX = 1010.0

    // At a venue
    static let greetX = [640.0, 700.0]
    static let cashX = 745.0
    static let stopX = [850.0, 880.0]
    static let waitX = [560.0, 590.0]
    static let beamSpot = [280.0, 330.0, 380.0]
    /// Doors of the grocery store and the bank in town, and the dealer further along.
    static let storeDoorX = 330.0
    static let bankDoorX = 860.0
    static let dealerDoorX = 1030.0

    // The accident at the airport: where the cab and the shuttle bus meet.
    static let crashX = 600.0
    static let taxiLength = 210.0
    static let busLength = 300.0
    /// Where the airport police SUV and the operations pickup pull up after the crash.
    static let policeX = 250.0
    static let opsX = 1060.0
    // Sunshine Cab Company's office
    static let officeDoorX = 110.0
    static let bossDeskX = 880.0

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

enum Place { case house, pod, venue, town, shops, road, office }

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
    case .pod:
        drawPodInterior(ctx, d: d, now: now)
        for p in people where p.crew { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for x in Stage.chairX { drawChairBack(ctx, x: x, d: d, now: now) }
        let seated = people.filter(\.seated)
        for p in seated { drawSeat(ctx, p, x: p.x(at: now)) }
        for p in seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
        for p in seated { drawStraps(ctx, p, d: d, now: now) }
        for p in people where !p.crew && !p.seated { drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now) }
    case .house, .venue, .town, .shops, .road, .office:
        switch d.place {
        case .road:
            drawAirport(ctx, now: now)
            if let police = d.police(at: now) { drawAirportVehicle(ctx, x: police, police: true, now: now) }
            if let ops = d.ops(at: now) { drawAirportVehicle(ctx, x: ops, police: false, now: now) }
            if let bus = d.bus(at: now) { drawShuttleBus(ctx, x: bus, dented: d.crashT0 != nil) }
            if let taxi = d.taxi(at: now) { drawTaxi(ctx, x: taxi, dented: d.crashT0 != nil, now: now) }
            if let t0 = d.crashT0 { drawCrashSmoke(ctx, at: CGPoint(x: Stage.crashX, y: Stage.floorY - 40), since: t0, now: now) }
        case .office:
            drawCabOffice(ctx, now: now)
        case .town:
            drawTown(ctx, now: now)
        case .shops:
            drawShops(ctx, now: now)
        case .house:
            drawHouse(ctx, d: d, now: now)
        default:
            if let venue = d.venue {
                drawVenue(ctx, venue, now: now)
                drawCashTable(ctx, accent: venue.accent)
            }
        }
        let pod = d.pod(at: now)
        for p in people.filter({ $0.rise(at: now) < 0.5 }).sorted(by: { $0.height > $1.height }) {
            drawPerson(ctx, p, feet: feet(p), facing: p.facing, now: now)
        }
        // Anyone in the beam disappears up through the hatch.
        var lifted = ctx
        if let pod { lifted.clip(to: Path(CGRect(x: 0, y: pod.y + 20, width: Stage.W, height: Stage.H))) }
        for p in people where p.rise(at: now) >= 0.5 {
            drawPerson(lifted, p, feet: feet(p), facing: p.facing, now: now)
        }
        if let pod {
            drawFlyingPod(ctx, at: pod, now: now)
            drawBeam(ctx, from: pod, d: d, now: now)
        }
    }
    if d.place == .house && d.night { drawNight(ctx, now: now) }
    if d.place == .house { drawSnores(ctx, d: d, now: now) }
    var balloons: [CGRect] = []
    for p in people {
        if let box = drawSpeech(ctx, p, feet: feet(p), now: now, view: cam, avoiding: balloons) { balloons.append(box) }
    }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, x: pop.x, age: now.timeIntervalSince(pop.t0)) }

    // Screen-space overlays
    let cardUp = d.card != nil && now < d.cardUntil
    if let card = d.card, cardUp { drawCard(screen, card) }
    if d.venue == nil && !cardUp { drawHUD(screen, d: d, now: now) }
    drawClock(screen, d: d, now: now)
    if d.place == .pod { drawMirror(screen, d: d, now: now) }
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

/// A flat-topped hexagon of radius `r`.
func hexagon(_ c: CGPoint, _ r: Double) -> Path {
    var p = Path()
    for i in 0..<6 {
        let a = Double(i) * .pi / 3
        let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath()
    return p
}

let buttonRed = Color(red: 1.0, green: 0.12, blue: 0.10)
private let hullDark = Color(red: 0.16, green: 0.24, blue: 0.16)
private let hullLight = Color(red: 0.42, green: 0.55, blue: 0.30)
private let amber = Color(red: 1.0, green: 0.72, blue: 0.20)

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
    if let truck = d.truck(at: now) { drawFlatbed(ctx, x: truck, now: now) }
    if let bike = d.repoBike(at: now) { drawMotorcycle(ctx, x: bike.x, ground: bike.ground, paint: Color(red: 0.10, green: 0.10, blue: 0.12)) }
    // Wheels of their own, bought out of their savings
    if let x = d.parked(.car, at: now) {
        drawCar(ctx, x: x, hooked: false, paint: Color(red: 0.85, green: 0.16, blue: 0.20), noseRight: true)
    }
    if let x = d.parked(.motorcycle, at: now) {
        if let rider = d.rider, d.arriving == .motorcycle {
            drawPerson(ctx, rider, feet: CGPoint(x: x - 6, y: Stage.floorY - 20), facing: 1, now: now, still: true, levels: AnimalLevels.none)
        }
        drawMotorcycle(ctx, x: x, paint: Color(red: 0.15, green: 0.35, blue: 0.85), noseRight: true)
    }
    if let x = d.parked(.scooter, at: now) {
        if let rider = d.rider, d.arriving == .scooter {
            drawPerson(ctx, rider, feet: CGPoint(x: x - 12, y: Stage.floorY - 16), facing: 1, now: now, still: true, levels: AnimalLevels.none)
        }
        drawScooter(ctx, x: x)
    }

    var roof = Path()
    roof.move(to: CGPoint(x: Stage.frontWallX - 20, y: Stage.ceilY))
    roof.addLine(to: CGPoint(x: (Stage.frontWallX + Stage.W) / 2, y: 95))
    roof.addLine(to: CGPoint(x: Stage.W + 10, y: Stage.ceilY))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.35, green: 0.40, blue: 0.55)))
    ctx.stroke(roof, with: .color(Color(red: 0.22, green: 0.25, blue: 0.36)), lineWidth: 4)

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
    let couch = Color(red: 0.40, green: 0.50, blue: 0.70)
    fill(ctx, CGRect(x: 552, y: Stage.floorY - 62, width: 86, height: 36), couch, corner: 10)
    fill(ctx, CGRect(x: 546, y: Stage.floorY - 40, width: 98, height: 32), couch.opacity(0.85), corner: 8)
    if d.couchSleeper != nil && d.night {
        // The babysitter, asleep on the couch under a blanket.
        fill(ctx, CGRect(x: 560, y: Stage.floorY - 52, width: 74, height: 16), Color(red: 0.95, green: 0.75, blue: 0.40), corner: 7)
        if let p = d.couchSleeper {
            ctx.fill(circle(CGPoint(x: 560, y: Stage.floorY - 50), 10), with: .color(p.hair.color))
            ctx.fill(circle(CGPoint(x: 562, y: Stage.floorY - 47), 8), with: .color(p.skin.color))
        }
    }

    let blankets = [Color(red: 0.35, green: 0.50, blue: 0.85), Color(red: 0.95, green: 0.50, blue: 0.65), Color(red: 0.50, green: 0.80, blue: 0.40)]
    for (x, blanket) in zip(Stage.bedX, blankets) { drawBed(ctx, x: x, width: x > 1000 ? 80 : 100, blanket: blanket) }
    drawSleepers(ctx, d: d)
    // A lamp for Debbie, a unicorn poster for Hailey, a teddy bear for Molly
    fill(ctx, CGRect(x: 812, y: Stage.floorY - 108, width: 12, height: 18), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 816, y: Stage.floorY - 90, width: 4, height: 80), .gray)
    fill(ctx, CGRect(x: 900, y: 258, width: 44, height: 56), Color(red: 0.70, green: 0.55, blue: 0.95), corner: 2)
    ctx.fill(circle(CGPoint(x: 922, y: 284), 11), with: .color(.white))
    ctx.fill(Path { p in p.move(to: CGPoint(x: 922, y: 270)); p.addLine(to: CGPoint(x: 926, y: 258)); p.addLine(to: CGPoint(x: 918, y: 268)) }, with: .color(.yellow))
    let bear = Color(red: 0.65, green: 0.45, blue: 0.28)
    ctx.fill(circle(CGPoint(x: 1172, y: Stage.floorY - 22), 12), with: .color(bear))
    ctx.fill(circle(CGPoint(x: 1172, y: Stage.floorY - 40), 9), with: .color(bear))
    for dx in [-7.0, 7] { ctx.fill(circle(CGPoint(x: 1172 + dx, y: Stage.floorY - 48), 4), with: .color(bear)) }
    if d.buttonShown { drawRedButtonStand(ctx, d: d, now: now) }

    // Partitions with doorways; the front wall has the front door onto the yard.
    for room in Stage.rooms.dropFirst() {
        fill(ctx, CGRect(x: room.x0 - 5, y: Stage.ceilY, width: 10, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.72, green: 0.70, blue: 0.66))
    }
    fill(ctx, CGRect(x: Stage.frontWallX - 6, y: Stage.ceilY, width: 12, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.35, green: 0.33, blue: 0.30))
    ctx.stroke(Path(CGRect(x: Stage.frontWallX, y: Stage.ceilY, width: Stage.W - Stage.frontWallX, height: Stage.floorY - Stage.ceilY)),
               with: .color(Color(red: 0.35, green: 0.33, blue: 0.30)), lineWidth: 8)
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

/// A little sedan, nose to the left unless `noseRight`.
func drawCar(_ ctx: GraphicsContext, x: Double, hooked: Bool, paint: Color = Color(red: 0.20, green: 0.45, blue: 0.78),
             noseRight: Bool = false, ground: Double = Stage.floorY, dented: Bool = false) {
    var c = ctx
    if noseRight {
        c.translateBy(x: x, y: 0)
        c.scaleBy(x: -1, y: 1)
        c.translateBy(x: -x, y: 0)
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
    if dented {
        // A crumpled front bumper
        var dent = Path()
        dent.move(to: CGPoint(x: x - 67, y: ground - 42))
        for (i, dy) in [6.0, 12, 17, 23, 28].enumerated() {
            dent.addLine(to: CGPoint(x: x - (i % 2 == 0 ? 56 : 64), y: ground - 42 + dy))
        }
        dent.addLine(to: CGPoint(x: x - 67, y: ground - 14))
        dent.closeSubpath()
        c.fill(dent, with: .color(Color(white: 0.25)))
    }
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

/// A motorcycle: big wheels, a teardrop tank, chrome pipes. Nose to the left unless `noseRight`.
func drawMotorcycle(_ ctx: GraphicsContext, x: Double, ground: Double = Stage.floorY, paint: Color, noseRight: Bool = false) {
    var c = ctx
    if noseRight {
        c.translateBy(x: x, y: 0)
        c.scaleBy(x: -1, y: 1)
        c.translateBy(x: -x, y: 0)
    }
    let chrome = Color(white: 0.78)
    for wx in [x - 32, x + 32] {
        c.fill(circle(CGPoint(x: wx, y: ground - 14), 14), with: .color(Color(white: 0.1)))
        c.fill(circle(CGPoint(x: wx, y: ground - 14), 7), with: .color(chrome))
        c.fill(circle(CGPoint(x: wx, y: ground - 14), 2.5), with: .color(Color(white: 0.3)))
    }
    var frame = Path()
    frame.move(to: CGPoint(x: x - 32, y: ground - 14))
    frame.addLine(to: CGPoint(x: x - 18, y: ground - 44))
    frame.addLine(to: CGPoint(x: x + 14, y: ground - 40))
    frame.addLine(to: CGPoint(x: x + 32, y: ground - 14))
    c.stroke(frame, with: .color(Color(white: 0.25)), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
    // Engine and exhaust
    fill(c, CGRect(x: x - 10, y: ground - 32, width: 22, height: 16), Color(white: 0.35), corner: 3)
    fill(c, CGRect(x: x - 4, y: ground - 18, width: 44, height: 5), chrome, corner: 2.5)
    // Tank and seat
    c.fill(Path(ellipseIn: CGRect(x: x - 24, y: ground - 54, width: 30, height: 16)), with: .color(paint))
    c.fill(Path(ellipseIn: CGRect(x: x - 19, y: ground - 52, width: 9, height: 4)), with: .color(.white.opacity(0.5)))
    fill(c, CGRect(x: x + 2, y: ground - 49, width: 28, height: 8), Color(white: 0.12), corner: 4)
    // Fork, handlebars and headlight
    var fork = Path()
    fork.move(to: CGPoint(x: x - 32, y: ground - 14))
    fork.addLine(to: CGPoint(x: x - 24, y: ground - 58))
    c.stroke(fork, with: .color(chrome), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    var bars = Path()
    bars.move(to: CGPoint(x: x - 30, y: ground - 64))
    bars.addLine(to: CGPoint(x: x - 16, y: ground - 58))
    c.stroke(bars, with: .color(Color(white: 0.2)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    c.fill(circle(CGPoint(x: x - 34, y: ground - 50), 5), with: .color(Color(red: 1, green: 0.95, blue: 0.6)))
    fill(c, CGRect(x: x + 30, y: ground - 46, width: 5, height: 5), Color(red: 0.85, green: 0.12, blue: 0.12), corner: 1)
}

/// The repo men's flatbed, facing the street, with a bed for loading the motorcycle.
private func drawFlatbed(_ ctx: GraphicsContext, x: Double, now: Date) {
    let ground = Stage.floorY
    let body = Color(red: 0.95, green: 0.72, blue: 0.10)
    let dark = Color(white: 0.22)
    fill(ctx, CGRect(x: x - 10, y: ground - 42, width: 130, height: 12), dark, corner: 2)
    fill(ctx, CGRect(x: x - 10, y: ground - 46, width: 130, height: 5), Color(white: 0.45), corner: 2)
    fill(ctx, CGRect(x: x + 116, y: ground - 60, width: 5, height: 18), Color(white: 0.45))
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
    fill(ctx, CGRect(x: x - 70, y: ground - 26, width: 192, height: 8), dark, corner: 3)
    // Flashing amber light on the roof
    let on = sin(now.timeIntervalSinceReferenceDate * 9) > 0
    fill(ctx, CGRect(x: x - 30, y: ground - 85, width: 14, height: 7), Color(red: 1, green: 0.6, blue: 0).opacity(on ? 1 : 0.4), corner: 3)
    if on { ctx.fill(circle(CGPoint(x: x - 23, y: ground - 82), 14), with: .color(Color(red: 1, green: 0.7, blue: 0.1).opacity(0.3))) }
    for wx in [x - 46, x + 40, x + 90] {
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
        for dx in [-3.5, 3.5] {
            var lid = Path()
            lid.addArc(center: CGPoint(x: head.x + dx, y: head.y), radius: 2.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            ctx.stroke(lid, with: .color(.black.opacity(0.7)), lineWidth: 1)
        }
    }
}

/// Night: outside goes dark with a moon and stars; inside the house stays softly lamp-lit.
private func drawNight(_ ctx: GraphicsContext, now: Date) {
    let inside = CGRect(x: Stage.frontWallX, y: Stage.ceilY, width: Stage.W - Stage.frontWallX, height: Stage.floorY - Stage.ceilY)
    var outside = Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H))
    outside.addRect(inside)
    ctx.fill(outside, with: .color(Color(red: 0.02, green: 0.04, blue: 0.16).opacity(0.78)), style: FillStyle(eoFill: true))
    ctx.fill(Path(inside), with: .color(Color(red: 0.10, green: 0.08, blue: 0.25).opacity(0.28)))
    let glass = livingWindow.insetBy(dx: 2.5, dy: 2.5)
    ctx.fill(Path(glass), with: .color(Color(red: 0.05, green: 0.08, blue: 0.25)))
    ctx.fill(circle(CGPoint(x: glass.minX + glass.width * 0.3, y: glass.minY + glass.height * 0.3), 1.5), with: .color(.white))
    ctx.fill(circle(CGPoint(x: glass.minX + glass.width * 0.75, y: glass.minY + glass.height * 0.55), 1.2), with: .color(.white))
    ctx.stroke(Path(livingWindow), with: .color(Color(white: 0.75)), lineWidth: 5)
    ctx.fill(Path(CGRect(x: livingWindow.midX - 1.5, y: livingWindow.minY, width: 3, height: livingWindow.height)), with: .color(Color(white: 0.75)))
    let t = now.timeIntervalSinceReferenceDate
    for (i, (x, y)) in [(60.0, 50.0), (150.0, 110.0), (250.0, 40.0), (330.0, 150.0), (520.0, 60.0), (700.0, 35.0), (880.0, 70.0), (990.0, 30.0),
                        (40.0, 200.0), (200.0, 260.0), (300.0, 90.0), (410.0, 30.0), (620.0, 110.0), (1040.0, 120.0)].enumerated() {
        ctx.fill(circle(CGPoint(x: x, y: y), 1.6 + 0.6 * sin(t * 2 + Double(i))), with: .color(.white.opacity(0.9)))
    }
    let moon = CGPoint(x: 1115, y: 65)
    ctx.fill(circle(moon, 37), with: .color(Color(red: 0.126, green: 0.196, blue: 0.34)))
    var crescent = Path(ellipseIn: CGRect(x: moon.x - 30, y: moon.y - 30, width: 60, height: 60))
    crescent = crescent.subtracting(Path(ellipseIn: CGRect(x: moon.x - 14, y: moon.y - 38, width: 60, height: 60)))
    ctx.fill(crescent, with: .color(Color(red: 1, green: 0.97, blue: 0.80)))
}

/// Little Zs drifting up from each sleeper.
private func drawSnores(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    var spots = zip(d.cast, Stage.bedX).filter { d.sleeping.contains($0.0.id) }.map { $0.1 + 34 }
    if d.night, d.couchSleeper != nil { spots.append(575) }
    for (i, x) in spots.enumerated() {
        for k in 0..<3 {
            let u = (t / 2.4 + Double(k) / 3 + Double(i) * 0.21).truncatingRemainder(dividingBy: 1)
            let at = CGPoint(x: x + u * 26 + sin(u * 6) * 4, y: Stage.floorY - 70 - u * 60)
            ctx.draw(Text("z").font(.system(size: 12 + u * 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.55).opacity(1 - u)), at: at)
        }
    }
}

/// The glowing red button the alien animals leave in the living room, with its note.
private func drawRedButtonStand(_ ctx: GraphicsContext, d: Director, now: Date) {
    let x = Stage.buttonX
    let t = now.timeIntervalSinceReferenceDate
    // A carved wooden zoo post
    var stand = Path()
    stand.move(to: CGPoint(x: x - 12, y: Stage.floorY - 62))
    stand.addLine(to: CGPoint(x: x + 12, y: Stage.floorY - 62))
    stand.addLine(to: CGPoint(x: x + 20, y: Stage.floorY))
    stand.addLine(to: CGPoint(x: x - 20, y: Stage.floorY))
    stand.closeSubpath()
    ctx.fill(stand, with: .linearGradient(Gradient(colors: [hullLight, hullDark]), startPoint: CGPoint(x: x - 20, y: 0), endPoint: CGPoint(x: x + 20, y: 0)))
    for k in 0..<4 { fill(ctx, CGRect(x: x - 16, y: Stage.floorY - 50 + Double(k) * 13, width: 32, height: 2), .black.opacity(0.3)) }
    fill(ctx, CGRect(x: x - 20, y: Stage.floorY - 68, width: 40, height: 8), amber, corner: 3)
    let c = CGPoint(x: x, y: Stage.floorY - 75)
    let pressed = now.timeIntervalSince(d.buttonPressT0)
    let glow = pressed >= 0 && pressed < 1.5 ? 1.0 : 0.6 + 0.4 * sin(t * 4)
    ctx.fill(circle(c, 22), with: .radialGradient(Gradient(colors: [buttonRed.opacity(0.7 * glow), .clear]), center: c, startRadius: 4, endRadius: 22))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 10, y: c.y - 6, width: 20, height: 10)), with: .color(buttonRed))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 5, y: c.y - 5, width: 6, height: 3)), with: .color(.white.opacity(0.8)))
    // The note stuck to the stand
    var note = ctx
    note.translateBy(x: x + 3, y: Stage.floorY - 36)
    note.rotate(by: .degrees(-6))
    fill(note, CGRect(x: -11, y: -9, width: 22, height: 18), Color(red: 1, green: 0.97, blue: 0.75), corner: 1)
    for k in 0..<3 { fill(note, CGRect(x: -7, y: -5 + Double(k) * 4, width: 14, height: 1.2), Color(white: 0.5)) }
}

// MARK: Flying zoo — a flying alien zoo

/// A little palm tree, `h` tall, standing on `base`.
private func drawPalm(_ ctx: GraphicsContext, base: CGPoint, h: Double, t: Double) {
    var trunk = Path()
    trunk.move(to: base)
    trunk.addQuadCurve(to: CGPoint(x: base.x + h * 0.12, y: base.y - h), control: CGPoint(x: base.x - h * 0.1, y: base.y - h * 0.5))
    ctx.stroke(trunk, with: .color(Color(red: 0.55, green: 0.38, blue: 0.20)), style: StrokeStyle(lineWidth: max(2, h * 0.09), lineCap: .round))
    let top = CGPoint(x: base.x + h * 0.12, y: base.y - h)
    let sway = sin(t * 1.5 + base.x) * 0.08
    for k in 0..<6 {
        let ang = (-160.0 + Double(k) * 28) * .pi / 180 + sway
        var frond = Path()
        let tip = CGPoint(x: top.x + cos(ang) * h * 0.55, y: top.y + sin(ang) * h * 0.4 + h * 0.18)
        frond.move(to: top)
        frond.addQuadCurve(to: tip, control: CGPoint(x: top.x + cos(ang) * h * 0.35, y: top.y + sin(ang) * h * 0.5))
        ctx.stroke(frond, with: .color(Color(red: 0.18, green: 0.58, blue: 0.24)), style: StrokeStyle(lineWidth: max(2, h * 0.1), lineCap: .round))
    }
}

/// A giraffe standing at `foot`, `s` tall.
private func drawGiraffe(_ ctx: GraphicsContext, foot: CGPoint, s: Double, t: Double) {
    let tan = Color(red: 0.95, green: 0.76, blue: 0.36), spot = Color(red: 0.65, green: 0.38, blue: 0.16)
    for dx in [-0.18, -0.08, 0.1, 0.2] {
        ctx.stroke(Path { $0.move(to: CGPoint(x: foot.x + dx * s, y: foot.y)); $0.addLine(to: CGPoint(x: foot.x + dx * s, y: foot.y - s * 0.4)) },
                   with: .color(tan), lineWidth: max(1.2, s * 0.05))
    }
    let body = CGRect(x: foot.x - s * 0.24, y: foot.y - s * 0.55, width: s * 0.5, height: s * 0.2)
    ctx.fill(Path(ellipseIn: body), with: .color(tan))
    let nod = sin(t * 1.2) * s * 0.03
    let headC = CGPoint(x: foot.x + s * 0.32, y: foot.y - s * 1.05 + nod)
    ctx.stroke(Path { $0.move(to: CGPoint(x: foot.x + s * 0.18, y: foot.y - s * 0.5)); $0.addLine(to: headC) },
               with: .color(tan), style: StrokeStyle(lineWidth: max(1.5, s * 0.09), lineCap: .round))
    ctx.fill(Path(ellipseIn: CGRect(x: headC.x - s * 0.04, y: headC.y - s * 0.05, width: s * 0.16, height: s * 0.09)), with: .color(tan))
    for (dx, dy) in [(-0.1, -0.5), (0.05, -0.47), (0.2, -0.5), (0.22, -0.7), (0.27, -0.88)] {
        ctx.fill(circle(CGPoint(x: foot.x + dx * s, y: foot.y + dy * s), s * 0.03), with: .color(spot))
    }
    ctx.stroke(Path { $0.move(to: CGPoint(x: headC.x, y: headC.y - s * 0.03)); $0.addLine(to: CGPoint(x: headC.x - s * 0.02, y: headC.y - s * 0.1)) },
               with: .color(spot), lineWidth: max(1, s * 0.025))
}

/// A cartoon elephant facing right, `s` tall, standing at `foot`.
private func drawLittleElephant(_ ctx: GraphicsContext, foot: CGPoint, s: Double, t: Double) {
    let grey = Color(red: 0.62, green: 0.64, blue: 0.70)
    for dx in [-0.3, -0.1, 0.1, 0.28] {
        ctx.fill(Path(CGRect(x: foot.x + dx * s - s * 0.06, y: foot.y - s * 0.35, width: s * 0.12, height: s * 0.35)), with: .color(grey))
    }
    ctx.fill(Path(ellipseIn: CGRect(x: foot.x - s * 0.42, y: foot.y - s * 0.78, width: s * 0.8, height: s * 0.55)), with: .color(grey))
    let head = CGPoint(x: foot.x + s * 0.42, y: foot.y - s * 0.68)
    ctx.fill(circle(head, s * 0.22), with: .color(grey))
    ctx.fill(Path(ellipseIn: CGRect(x: head.x - s * 0.3, y: head.y - s * 0.2, width: s * 0.22, height: s * 0.32)), with: .color(Color(red: 0.95, green: 0.72, blue: 0.76)))
    var trunk = Path()
    trunk.move(to: CGPoint(x: head.x + s * 0.15, y: head.y))
    trunk.addQuadCurve(to: CGPoint(x: head.x + s * 0.32, y: head.y - s * 0.2 + sin(t * 2) * s * 0.06), control: CGPoint(x: head.x + s * 0.32, y: head.y + s * 0.3))
    ctx.stroke(trunk, with: .color(grey), style: StrokeStyle(lineWidth: max(1.5, s * 0.1), lineCap: .round))
    ctx.fill(circle(CGPoint(x: head.x + s * 0.06, y: head.y - s * 0.06), max(0.8, s * 0.03)), with: .color(.black))
}

/// A monkey swinging from a branch at `hang`, `s` tall.
private func drawMonkey(_ ctx: GraphicsContext, hang: CGPoint, s: Double, t: Double) {
    let brown = Color(red: 0.50, green: 0.30, blue: 0.16), face = Color(red: 0.92, green: 0.76, blue: 0.58)
    var g = ctx
    g.translateBy(x: hang.x, y: hang.y)
    g.rotate(by: .radians(sin(t * 2.2) * 0.35))
    g.stroke(Path { $0.move(to: .zero); $0.addLine(to: CGPoint(x: 0, y: s * 0.35)) }, with: .color(brown), lineWidth: max(1.2, s * 0.08))
    g.fill(Path(ellipseIn: CGRect(x: -s * 0.18, y: s * 0.32, width: s * 0.36, height: s * 0.42)), with: .color(brown))
    g.fill(circle(CGPoint(x: 0, y: s * 0.86), s * 0.17), with: .color(brown))
    g.fill(Path(ellipseIn: CGRect(x: -s * 0.11, y: s * 0.82, width: s * 0.22, height: s * 0.16)), with: .color(face))
    var tail = Path()
    tail.move(to: CGPoint(x: s * 0.1, y: s * 0.7))
    tail.addQuadCurve(to: CGPoint(x: s * 0.35, y: s * 0.5), control: CGPoint(x: s * 0.4, y: s * 0.85))
    g.stroke(tail, with: .color(brown), lineWidth: max(1, s * 0.05))
}

/// `c` is the middle of the zoo's hatch, underneath.
private func drawFlyingPod(_ ctx: GraphicsContext, at c: CGPoint, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let trim = Color(red: 0.10, green: 0.26, blue: 0.14)
    // A red glow holding it up
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 140, y: c.y + 4, width: 280, height: 36)),
             with: .radialGradient(Gradient(colors: [buttonRed.opacity(0.5 + 0.15 * sin(t * 5)), .clear]), center: CGPoint(x: c.x, y: c.y + 22), startRadius: 8, endRadius: 140))
    // Pennants flying from the top of the dome
    for side in [-1.0, 1.0] {
        let pole = CGPoint(x: c.x + side * 52, y: c.y - 126)
        ctx.stroke(Path { $0.move(to: CGPoint(x: pole.x, y: pole.y + 20)); $0.addLine(to: CGPoint(x: pole.x, y: pole.y - 26)) }, with: .color(Color(white: 0.85)), lineWidth: 2)
        var flag = Path()
        flag.move(to: CGPoint(x: pole.x, y: pole.y - 26))
        flag.addLine(to: CGPoint(x: pole.x + side * 26, y: pole.y - 20 + sin(t * 6 + side) * 3))
        flag.addLine(to: CGPoint(x: pole.x, y: pole.y - 13))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(side < 0 ? Color(red: 1, green: 0.82, blue: 0.2) : Color(red: 0.95, green: 0.35, blue: 0.2)))
    }
    // The glass dome over a little zoo habitat
    let dome = CGRect(x: c.x - 100, y: c.y - 140, width: 200, height: 120)
    let domePath = Path(ellipseIn: dome)
    ctx.fill(domePath, with: .linearGradient(Gradient(colors: [Color(red: 0.55, green: 0.82, blue: 1.0).opacity(0.9), Color(red: 0.80, green: 0.95, blue: 1.0).opacity(0.85)]),
                                             startPoint: CGPoint(x: c.x, y: dome.minY), endPoint: CGPoint(x: c.x, y: dome.maxY)))
    var zoo = ctx
    zoo.clip(to: domePath)
    // Rolling grass, a rock and a pond
    var hill = Path()
    hill.move(to: CGPoint(x: dome.minX, y: dome.maxY - 30))
    hill.addQuadCurve(to: CGPoint(x: dome.maxX, y: dome.maxY - 34), control: CGPoint(x: c.x, y: dome.maxY - 52))
    hill.addLine(to: CGPoint(x: dome.maxX, y: dome.maxY)); hill.addLine(to: CGPoint(x: dome.minX, y: dome.maxY)); hill.closeSubpath()
    zoo.fill(hill, with: .color(Color(red: 0.36, green: 0.72, blue: 0.30)))
    zoo.fill(Path(ellipseIn: CGRect(x: c.x + 18, y: dome.maxY - 32, width: 46, height: 10)), with: .color(Color(red: 0.30, green: 0.60, blue: 0.90)))
    zoo.fill(Path(ellipseIn: CGRect(x: c.x - 82, y: dome.maxY - 44, width: 28, height: 18)), with: .color(Color(white: 0.6)))
    drawPalm(zoo, base: CGPoint(x: c.x - 62, y: dome.maxY - 36), h: 58, t: t)
    drawPalm(zoo, base: CGPoint(x: c.x + 74, y: dome.maxY - 36), h: 48, t: t + 1)
    drawGiraffe(zoo, foot: CGPoint(x: c.x - 26, y: dome.maxY - 38), s: 62, t: t)
    drawLittleElephant(zoo, foot: CGPoint(x: c.x + 28, y: dome.maxY - 36), s: 30, t: t)
    drawMonkey(zoo, hang: CGPoint(x: c.x + 76, y: dome.maxY - 76), s: 20, t: t)
    ctx.fill(Path(ellipseIn: CGRect(x: dome.minX + 30, y: dome.minY + 10, width: 60, height: 18)), with: .color(.white.opacity(0.45)))
    ctx.stroke(domePath, with: .color(.white.opacity(0.7)), lineWidth: 2)
    // The hull: jungle green with a zebra-striped band and leopard spots
    let hull = CGRect(x: c.x - 165, y: c.y - 62, width: 330, height: 80)
    let hullPath = Path(ellipseIn: hull)
    ctx.fill(hullPath, with: .linearGradient(Gradient(colors: [Color(red: 0.30, green: 0.62, blue: 0.36), Color(red: 0.10, green: 0.32, blue: 0.18)]),
                                             startPoint: CGPoint(x: c.x, y: hull.minY), endPoint: CGPoint(x: c.x, y: hull.maxY)))
    var skin = ctx
    skin.clip(to: hullPath)
    let band = CGRect(x: hull.minX, y: hull.midY - 12, width: hull.width, height: 22)
    skin.fill(Path(band), with: .color(.white))
    var stripes = skin
    stripes.clip(to: Path(band))
    for k in 0..<24 {
        let x = hull.minX + Double(k) * 15
        stripes.fill(Path { $0.move(to: CGPoint(x: x, y: band.minY)); $0.addLine(to: CGPoint(x: x + 8, y: band.minY)); $0.addLine(to: CGPoint(x: x + 2, y: band.maxY)); $0.addLine(to: CGPoint(x: x - 6, y: band.maxY)); $0.closeSubpath() },
                     with: .color(.black))
    }
    for (dx, dy) in [(-120.0, 10.0), (-80, 20), (-40, 12), (60, 18), (100, 10), (130, 2), (-140, -2), (20, 22)] {
        let sp = CGPoint(x: c.x + dx, y: c.y + dy - 6)
        skin.fill(Path(ellipseIn: CGRect(x: sp.x - 6, y: sp.y - 4, width: 12, height: 8)), with: .color(Color(red: 0.85, green: 0.68, blue: 0.30)))
        skin.stroke(Path(ellipseIn: CGRect(x: sp.x - 6, y: sp.y - 4, width: 12, height: 8)), with: .color(Color(red: 0.25, green: 0.15, blue: 0.08)), lineWidth: 2)
    }
    skin.fill(Path(ellipseIn: CGRect(x: hull.minX + 40, y: hull.minY + 6, width: 150, height: 14)), with: .color(.white.opacity(0.22)))
    ctx.stroke(hullPath, with: .color(trim), lineWidth: 3)
    // The sign on the front of the hull
    let sign = CGRect(x: c.x - 62, y: c.y - 58, width: 124, height: 22)
    ctx.fill(Path(roundedRect: sign, cornerRadius: 11), with: .color(Color(red: 0.98, green: 0.80, blue: 0.20)))
    ctx.stroke(Path(roundedRect: sign, cornerRadius: 11), with: .color(trim), lineWidth: 2)
    ctx.draw(Text("ALIEN ZOO").font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(trim), at: CGPoint(x: sign.midX, y: sign.midY))
    // Yellow and green lights chasing round the rim
    for i in 0..<12 {
        let ang = Double(i) / 12 * .pi
        let pt = CGPoint(x: c.x - cos(ang) * 150, y: c.y - 18 + sin(ang) * 24)
        let on = (Int(t * 6) + i) % 3 == 0
        let col = i % 2 == 0 ? Color(red: 1, green: 0.85, blue: 0.25) : Color(red: 0.55, green: 1, blue: 0.45)
        ctx.fill(circle(pt, on ? 5 : 3.5), with: .color(col.opacity(on ? 1 : 0.45)))
        if on { ctx.fill(circle(pt, 10), with: .color(col.opacity(0.25))) }
    }
    // Paw-shaped landing feet, tucked up
    for side in [-1.0, 1.0] {
        ctx.stroke(Path { $0.move(to: CGPoint(x: c.x + side * 100, y: c.y + 5)); $0.addLine(to: CGPoint(x: c.x + side * 118, y: c.y + 26)) },
                   with: .color(trim), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        let paw = CGPoint(x: c.x + side * 120, y: c.y + 30)
        ctx.fill(Path(ellipseIn: CGRect(x: paw.x - 10, y: paw.y - 5, width: 20, height: 11)), with: .color(trim))
        for k in -1...1 { ctx.fill(circle(CGPoint(x: paw.x + Double(k) * 7, y: paw.y - 8), 3), with: .color(trim)) }
    }
    // The hatch underneath
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 42, y: c.y + 8, width: 84, height: 14)), with: .color(buttonRed.opacity(0.85)))
}

private func drawBeam(_ ctx: GraphicsContext, from c: CGPoint, d: Director, now: Date) {
    let age = now.timeIntervalSince(d.beamT0)
    guard d.beamOn, age >= 0 else { return }
    let a = min(age / 0.5, 1)
    // The tractor beam glows red.
    let red = Color(red: 1.0, green: 0.12, blue: 0.10)
    let top = c.y + 16
    let ground = Stage.floorY + 4
    var beam = Path()
    beam.move(to: CGPoint(x: c.x - 38, y: top))
    beam.addLine(to: CGPoint(x: c.x + 38, y: top))
    beam.addLine(to: CGPoint(x: c.x + 115, y: ground))
    beam.addLine(to: CGPoint(x: c.x - 115, y: ground))
    beam.closeSubpath()
    ctx.fill(beam, with: .linearGradient(Gradient(colors: [red.opacity(0.5 * a), red.opacity(0.2 * a)]),
                                         startPoint: CGPoint(x: c.x, y: top), endPoint: CGPoint(x: c.x, y: ground)))
    // Rings drifting up the beam
    let t = now.timeIntervalSinceReferenceDate
    for i in 0..<5 {
        let u = 1 - (t * 0.5 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
        let y = top + (ground - top) * u
        let hw = 38 + 77 * u
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - hw, y: y - 5, width: hw * 2, height: 10)), with: .color(Color(red: 1, green: 0.75, blue: 0.72).opacity(0.55 * a * (1 - u * 0.5))), lineWidth: 1.5)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 115, y: ground - 8, width: 230, height: 16)), with: .color(red.opacity(0.4 * a)))
}

// MARK: Inside the zoo — the alien zoo

private func drawPodInterior(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    // A jungle mural: sky above, distant green hills and trees below.
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.42, green: 0.70, blue: 0.90), Color(red: 0.72, green: 0.88, blue: 0.86)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: 330)))
    var hills = Path()
    hills.move(to: CGPoint(x: 0, y: 330))
    for k in 0...12 {
        let x = Double(k) * 100
        hills.addQuadCurve(to: CGPoint(x: x + 100, y: 330 + (k % 2 == 0 ? 6 : -10)), control: CGPoint(x: x + 50, y: k % 2 == 0 ? 280 : 300))
    }
    hills.addLine(to: CGPoint(x: Stage.W, y: Stage.floorY)); hills.addLine(to: CGPoint(x: 0, y: Stage.floorY)); hills.closeSubpath()
    ctx.fill(hills, with: .color(Color(red: 0.36, green: 0.62, blue: 0.34)))
    for (x, h) in [(60.0, 120.0), (300, 90), (880, 100), (1150, 130)] {
        drawPalm(ctx, base: CGPoint(x: x, y: 360), h: h, t: t)
    }
    // Zoo habitat windows, with animals inside, and clouds streaking by while the zoo flies
    for (i, x) in [150.0, 1050.0].enumerated() {
        let c = CGPoint(x: x, y: 250)
        let frame = CGRect(x: c.x - 70, y: c.y - 55, width: 140, height: 110)
        fill(ctx, frame.insetBy(dx: -8, dy: -8), Color(red: 0.50, green: 0.32, blue: 0.16), corner: 14)
        var win = ctx
        win.clip(to: Path(roundedRect: frame, cornerRadius: 10))
        win.fill(Path(frame), with: .linearGradient(Gradient(colors: [Color(red: 0.45, green: 0.72, blue: 0.98), Color(red: 0.75, green: 0.90, blue: 1)]),
                                                    startPoint: CGPoint(x: 0, y: frame.minY), endPoint: CGPoint(x: 0, y: frame.maxY)))
        for k in 0..<5 {
            let kk = Double(k)
            let sx = frame.minX - 40 + ((kk * 47 + (d.podFlying ? t * 190 : t * 4)).truncatingRemainder(dividingBy: frame.width + 60))
            let sy = frame.minY + 8 + (kk * 23).truncatingRemainder(dividingBy: 50)
            fill(win, CGRect(x: sx, y: sy, width: d.podFlying ? 40 : 24, height: d.podFlying ? 5 : 9), .white.opacity(0.85), corner: 4)
        }
        win.fill(Path(CGRect(x: frame.minX, y: frame.maxY - 22, width: frame.width, height: 22)), with: .color(Color(red: 0.40, green: 0.70, blue: 0.32)))
        if i == 0 {
            drawGiraffe(win, foot: CGPoint(x: c.x - 10, y: frame.maxY - 14), s: 82, t: t)
        } else {
            drawLittleElephant(win, foot: CGPoint(x: c.x - 14, y: frame.maxY - 12), s: 50, t: t)
            drawMonkey(win, hang: CGPoint(x: c.x + 46, y: frame.minY), s: 26, t: t)
        }
        // Bars across the habitat window
        for k in 1...5 { fill(ctx, CGRect(x: frame.minX + frame.width * Double(k) / 6 - 1.5, y: frame.minY, width: 3, height: frame.height), Color(white: 0.25).opacity(0.7)) }
    }
    // Jungle vines and big leaves hanging from the ceiling, swaying in flight
    let sway = d.podFlying ? sin(t * 3) * 6 : sin(t) * 2
    for i in 0..<16 {
        let x = 30 + Double(i) * 76
        let len = 40 + Double((i * 37) % 50)
        var vine = Path()
        vine.move(to: CGPoint(x: x, y: 0))
        vine.addQuadCurve(to: CGPoint(x: x + sway, y: len), control: CGPoint(x: x + 12, y: len * 0.5))
        ctx.stroke(vine, with: .color(Color(red: 0.16, green: 0.46, blue: 0.20)), lineWidth: 3)
        for k in 1...3 {
            let ly = len * Double(k) / 3.5
            ctx.fill(Path(ellipseIn: CGRect(x: x + sway * Double(k) / 3 - (k % 2 == 0 ? 14 : 0), y: ly, width: 14, height: 8)),
                     with: .color(Color(red: 0.22, green: 0.62, blue: 0.26)))
        }
    }
    // String lights across the top
    for i in 0..<22 {
        let x = 20 + Double(i) * 55
        let y = 70 + 14 * sin(Double(i) * .pi / 2.5)
        let on = 0.6 + 0.4 * sin(t * 2 + Double(i) * 0.9)
        let col = [Color(red: 1, green: 0.85, blue: 0.25), Color(red: 1, green: 0.45, blue: 0.3), Color(red: 0.55, green: 1, blue: 0.45)][i % 3]
        ctx.fill(circle(CGPoint(x: x, y: y), 5), with: .color(col.opacity(on)))
        ctx.fill(circle(CGPoint(x: x, y: y), 11), with: .color(col.opacity(0.2 * on)))
    }
    // The entrance arch sign, in wood, over the middle
    let sign = CGRect(x: 380, y: 100, width: 440, height: 40)
    fill(ctx, sign.insetBy(dx: -6, dy: -6), Color(red: 0.42, green: 0.26, blue: 0.12), corner: 14)
    fill(ctx, sign, Color(red: 0.62, green: 0.42, blue: 0.20), corner: 10)
    ctx.draw(Text("🦁  ALIEN ZOO · ANIMAL TRANSFORMATIONS  🦓").font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.92, blue: 0.6)),
             at: CGPoint(x: sign.midX, y: sign.midY))
    // A low wooden zoo fence along the back
    let fenceTop = Stage.floorY - 70
    fill(ctx, CGRect(x: 0, y: fenceTop + 12, width: Stage.W, height: 8), Color(red: 0.55, green: 0.36, blue: 0.18))
    fill(ctx, CGRect(x: 0, y: fenceTop + 42, width: Stage.W, height: 8), Color(red: 0.55, green: 0.36, blue: 0.18))
    for x in stride(from: 10.0, to: Stage.W, by: 40) {
        fill(ctx, CGRect(x: x, y: fenceTop, width: 10, height: 70), Color(red: 0.62, green: 0.42, blue: 0.22), corner: 3)
    }
    // A sandy zoo path for the floor, with paw prints and a glowing ring under each chair
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.86, green: 0.74, blue: 0.52))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 5), Color(red: 0.62, green: 0.50, blue: 0.32))
    for k in 0..<10 {
        let p = CGPoint(x: 60 + Double(k) * 115, y: Stage.floorY + 60 + (k % 2 == 0 ? 0 : 18))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 7, y: p.y - 4, width: 14, height: 10)), with: .color(Color(red: 0.70, green: 0.56, blue: 0.36)))
        for j in -1...1 { ctx.fill(circle(CGPoint(x: p.x + Double(j) * 5, y: p.y - 8), 2.5), with: .color(Color(red: 0.70, green: 0.56, blue: 0.36))) }
    }
    for x in Stage.chairX {
        ctx.stroke(Path(ellipseIn: CGRect(x: x - 60, y: Stage.floorY + 8, width: 120, height: 22)), with: .color(changeGlow.opacity(0.45 + 0.25 * sin(t * 2))), lineWidth: 2.5)
    }
    drawConsole(ctx, d: d, now: now)
}

private func drawConsole(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let x = Stage.consoleX
    let top = Stage.redButton.y + 8
    var pillar = Path()
    pillar.move(to: CGPoint(x: x - 30, y: top))
    pillar.addQuadCurve(to: CGPoint(x: x - 45, y: Stage.floorY), control: CGPoint(x: x - 20, y: (top + Stage.floorY) / 2))
    pillar.addLine(to: CGPoint(x: x + 45, y: Stage.floorY))
    pillar.addQuadCurve(to: CGPoint(x: x + 30, y: top), control: CGPoint(x: x + 20, y: (top + Stage.floorY) / 2))
    pillar.closeSubpath()
    ctx.fill(pillar, with: .linearGradient(Gradient(colors: [hullLight, hullDark]), startPoint: CGPoint(x: x - 40, y: 0), endPoint: CGPoint(x: x + 40, y: 0)))
    ctx.fill(Path(ellipseIn: CGRect(x: x - 55, y: top - 12, width: 110, height: 24)), with: .color(Color(red: 0.30, green: 0.36, blue: 0.24)))
    // Screen on a stalk
    let scr = CGRect(x: x - 55, y: top - 92, width: 110, height: 52)
    fill(ctx, CGRect(x: x - 3, y: scr.maxY, width: 6, height: top - 10 - scr.maxY), Color(white: 0.4))
    fill(ctx, scr.insetBy(dx: -4, dy: -4), Color(red: 0.30, green: 0.36, blue: 0.24), corner: 10)
    fill(ctx, scr, .black, corner: 8)
    let lines = d.screenText(now).split(separator: "\n")
    for (i, line) in lines.enumerated() {
        ctx.draw(Text(String(line)).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(changeGlow),
                 at: CGPoint(x: scr.midX, y: scr.midY + (Double(i) - Double(lines.count - 1) / 2) * 15))
    }
    for i in 0..<6 {
        let on = sin(t * 5 + Double(i) * 1.3) > 0
        ctx.fill(circle(CGPoint(x: x - 28 + Double(i) * 11, y: top + 26), 3), with: .color([changeGlow, amber, buttonRed][i % 3].opacity(on ? 1 : 0.3)))
    }
    // The big glowing red button
    let b = Stage.redButton
    let pressed = now.timeIntervalSince(d.consolePressT0)
    let glow = pressed >= 0 && pressed < 1.2 ? 1.0 : 0.6 + 0.4 * sin(t * 4)
    ctx.fill(circle(b, 24), with: .radialGradient(Gradient(colors: [buttonRed.opacity(0.75 * glow), .clear]), center: b, startRadius: 4, endRadius: 24))
    let down = pressed >= 0 && pressed < 0.3 ? 2.0 : 0
    ctx.fill(Path(ellipseIn: CGRect(x: b.x - 12, y: b.y - 7 + down, width: 24, height: 12)), with: .color(buttonRed))
    ctx.fill(Path(ellipseIn: CGRect(x: b.x - 6, y: b.y - 5 + down, width: 7, height: 3)), with: .color(.white.opacity(0.8)))
}

/// The egg-shaped chair back and the transformation hood hanging over it.
private func drawChairBack(_ ctx: GraphicsContext, x: Double, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let back = CGRect(x: x - 44, y: Stage.floorY - 205, width: 88, height: 175)
    ctx.fill(Path(ellipseIn: back), with: .color(Color(red: 0.30, green: 0.36, blue: 0.24)))
    ctx.fill(Path(ellipseIn: back.insetBy(dx: 9, dy: 9)), with: .color(Color(red: 0.25, green: 0.12, blue: 0.30)))
    for k in 0..<3 {
        ctx.stroke(Path(ellipseIn: back.insetBy(dx: 16 + Double(k) * 7, dy: 18 + Double(k) * 14)), with: .color(.white.opacity(0.06)), lineWidth: 1)
    }
    fill(ctx, CGRect(x: x - 5, y: Stage.floorY - 32, width: 10, height: 32), Color(white: 0.3))
    fill(ctx, CGRect(x: x - 30, y: Stage.floorY - 6, width: 60, height: 6), Color(white: 0.25), corner: 3)
    // A stalk up to a glowing ring over the chair
    fill(ctx, CGRect(x: x - 2, y: 160, width: 4, height: back.minY - 200), Color(red: 0.30, green: 0.36, blue: 0.24))
    let ring = CGRect(x: x - 48, y: back.minY - 44, width: 96, height: 22)
    let running = d.everyone.contains { $0.seated && abs($0.x(at: now) - x) < 2 && $0.isTingling(at: now) }
    let tint = d.everyone.first { $0.seated && abs($0.x(at: now) - x) < 2 }?.animal?.color ?? changeGlow
    ctx.stroke(Path(ellipseIn: ring), with: .color(Color(red: 0.30, green: 0.36, blue: 0.24)), lineWidth: 7)
    ctx.stroke(Path(ellipseIn: ring), with: .color(tint.opacity(running ? 0.6 + 0.4 * sin(t * 12) : 0.3)), lineWidth: 3)
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
    let shellGreen = Color(red: 0.36, green: 0.44, blue: 0.28)
    fill(ctx, CGRect(x: x - 40, y: seatY, width: 80, height: 12), shellGreen, corner: 6)
    for i in 0..<2 {
        let hd = pose.hand[i]
        fill(ctx, CGRect(x: hd.x - 12, y: hd.y + pose.armW * 0.3, width: 24, height: 8), shellGreen, corner: 4)
        fill(ctx, CGRect(x: hd.x - 3, y: hd.y + pose.armW * 0.3 + 8, width: 6, height: seatY - hd.y), Color(red: 0.25, green: 0.30, blue: 0.20))
    }
}

/// Glowing straps snap across the chest, wrists and ankles.
private func drawStraps(_ ctx: GraphicsContext, _ p: Person, d: Director, now: Date) {
    guard d.strapped.contains(p.id) else { return }
    let u = min(max(now.timeIntervalSince(d.strapT0) / 0.4, 0), 1)
    let pose = Pose(p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: 0, now: now)
    let band = Color(red: 0.20, green: 0.24, blue: 0.18)
    let t = pose.torso
    let chest = CGRect(x: t.midX - (t.width / 2 + 8) * u, y: t.minY + t.height * 0.45, width: (t.width + 16) * u, height: max(4, p.height * 0.03))
    fill(ctx, chest, band, corner: 2)
    fill(ctx, CGRect(x: chest.minX, y: chest.midY - 0.8, width: chest.width, height: 1.6), changeGlow.opacity(0.9), corner: 1)
    for pt in pose.hand + pose.foot {
        let r = CGRect(x: pt.x - 9 * u, y: pt.y - 3, width: 18 * u, height: 6)
        fill(ctx, r, band, corner: 2)
        fill(ctx, CGRect(x: r.minX, y: r.midY - 0.7, width: r.width, height: 1.4), changeGlow.opacity(0.9))
    }
}

/// The big mirror the alien animals lower in front of the chairs.
private func drawMirror(_ screen: GraphicsContext, d: Director, now: Date) {
    let u = d.mirror(at: now)
    guard u > 0 else { return }
    let seated = d.everyone.filter { $0.visible && $0.seated && !$0.crew }
    guard let lo = seated.map({ $0.x(at: now) }).min(), let hi = seated.map({ $0.x(at: now) }).max() else { return }
    let vw = max(420, hi - lo + 200), vh = vw * Stage.H / Stage.W
    let view = CGRect(x: (lo + hi) / 2 - vw / 2, y: Stage.floorY + 15 - vh, width: vw, height: vh)
    let w = 820.0, h = w * view.height / view.width
    let glass = CGRect(x: (Stage.W - w) / 2, y: 50 - (h + 130) * (1 - u), width: w, height: h)
    let frame = glass.insetBy(dx: -18, dy: -18)
    for x in [frame.minX + 60, frame.maxX - 60] where frame.minY > 0 {
        fill(screen, CGRect(x: x - 3, y: 0, width: 6, height: frame.minY), Color(red: 0.30, green: 0.36, blue: 0.24))
    }
    fill(screen, frame.offsetBy(dx: 6, dy: 8), .black.opacity(0.3), corner: 26)
    screen.fill(Path(roundedRect: frame, cornerRadius: 26),
                with: .linearGradient(Gradient(colors: [hullLight, hullDark, hullLight]),
                                      startPoint: CGPoint(x: frame.minX, y: frame.minY), endPoint: CGPoint(x: frame.maxX, y: frame.maxY)))
    for i in 0..<10 {
        let x = frame.minX + 30 + Double(i) * (frame.width - 60) / 9
        screen.fill(hexagon(CGPoint(x: x, y: frame.minY + 9), 4.5), with: .color(changeGlow.opacity(0.85)))
    }

    // The reflection: everyone in the chairs, left and right swapped.
    var m = screen
    m.clip(to: Path(roundedRect: glass, cornerRadius: 12))
    m.translateBy(x: glass.maxX, y: glass.minY)
    m.scaleBy(x: -w / view.width, y: w / view.width)
    m.translateBy(x: -view.minX, y: -view.minY)
    drawPodInterior(m, d: d, now: now)
    func feet(_ p: Person) -> CGPoint { CGPoint(x: p.x(at: now), y: Stage.floorY - p.rise(at: now)) }
    for x in Stage.chairX { drawChairBack(m, x: x, d: d, now: now) }
    for p in seated { drawSeat(m, p, x: p.x(at: now)) }
    for p in seated { drawPerson(m, p, feet: feet(p), facing: -p.facing, now: now) }
    for p in seated { drawStraps(m, p, d: d, now: now) }

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

/// A speech balloon over someone's head, kept inside `view` (what the camera shows) so close-ups never cut it off,
/// and moved aside if it would cover a balloon in `taken`. Returns where it went.
@discardableResult
private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, now: Date, view: CGRect, avoiding taken: [CGRect] = []) -> CGRect? {
    guard let text = p.says, now < p.saysUntil else { return nil }
    // Close-ups zoom in, so the text shrinks to stay about the same size on screen and fit over their heads.
    let k = min(max(view.width / Stage.W, 0.5), 1)
    let loud = p.voice > 15
    let resolved = ctx.resolve(Text(text).font(.system(size: p.voice * k, weight: loud ? .black : .medium, design: .rounded))
        .foregroundStyle(loud ? Color(red: 0.10, green: 0.45, blue: 0.15) : .black))
    let size = resolved.measure(in: CGSize(width: (loud ? 420 : 240) * k, height: 300))
    let pad = 10 * k
    let x = feet.x
    let pose = Pose(p, feet: feet, facing: p.facing, now: now)
    let top = pose.headTop - (p.animalLevels(at: now).head * pose.hr * 1.5)
    let w = size.width + pad * 2, h = size.height + pad * 1.4
    let margin = 6 * view.width / Stage.W

    func fitted(_ r: CGRect) -> CGRect {
        var r = r
        r.origin.x = min(max(r.minX, view.minX + margin), view.maxX - r.width - margin)
        r.origin.y = min(max(r.minY, view.minY + margin), view.maxY - r.height - margin)
        return r
    }
    let usual = fitted(CGRect(x: x - w / 2, y: top - h - 26 * k, width: w, height: h))
    var box = usual
    if taken.contains(where: { $0.intersects(usual) }) {
        // Try above, then beside, then below whatever it bumps into.
        var tries: [CGRect] = []
        for other in taken where other.intersects(usual) {
            tries.append(CGRect(x: usual.minX, y: other.minY - h - 4 * k, width: w, height: h))
            tries.append(CGRect(x: other.maxX + 4 * k, y: usual.minY, width: w, height: h))
            tries.append(CGRect(x: other.minX - w - 4 * k, y: usual.minY, width: w, height: h))
            tries.append(CGRect(x: usual.minX, y: other.maxY + 4 * k, width: w, height: h))
        }
        if let free = tries.map(fitted).first(where: { r in !taken.contains { $0.intersects(r) } }) { box = free }
    }

    // The tail points from the balloon at whoever is talking, even when the balloon had to slide over.
    let tailX = min(max(x, box.minX + 16 * k), box.maxX - 16 * k)
    let below = box.minY > top
    var bubble = Path(roundedRect: box, cornerRadius: 10 * k)
    if below {
        bubble.move(to: CGPoint(x: tailX - 7 * k, y: box.minY + 1))
        bubble.addLine(to: CGPoint(x: x, y: box.minY - 12 * k))
        bubble.addLine(to: CGPoint(x: tailX + 7 * k, y: box.minY + 1))
    } else {
        bubble.move(to: CGPoint(x: tailX - 7 * k, y: box.maxY - 1))
        bubble.addLine(to: CGPoint(x: x, y: box.maxY + 12 * k))
        bubble.addLine(to: CGPoint(x: tailX + 7 * k, y: box.maxY - 1))
    }
    ctx.fill(bubble, with: .color(p.crew ? Color(red: 0.88, green: 1, blue: 0.88) : .white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10 * k), with: .color(p.crew ? Color(red: 0.15, green: 0.55, blue: 0.20) : .black.opacity(0.35)), lineWidth: 1.5 * k)
    ctx.draw(resolved, in: box.insetBy(dx: pad, dy: pad * 0.7))
    return box
}

/// The alien animals' deal, or the note on the red button, drawn over whatever the camera shows.
private func drawCard(_ ctx: GraphicsContext, _ card: Card) {
    let (title, lines): (String, [String]) = switch card {
    case .deal: ("THE ALIEN ANIMALS' DEAL", [
        "Our flying zoo has pre-selected destinations:",
        "   Belmar NJ, Disney World, Disneyland, Sesame Place, Cozumel, Waikiki,",
        "   Long Branch NJ, the Atlantic City boardwalk, Myrtle Beach,",
        "   and the Crystal Coast of North Carolina.",
        "The only catch: you have to pay for the setup.",
        "Two of you go outside to ask customers if they want to be an alien animal.",
        "One of you stays inside to work the machine.",
        "Their transformation will dissolve in 8 hours.",
        "Yours dissolves after we bring you home from an event —",
        "   it takes 5 minutes to disappear.",
    ])
    case .note: ("A NOTE ON THE GLOWING RED BUTTON", [
        "If you want to do this again to make more money,",
        "press this button, and we will take you back",
        "to our zoo to transform you again.",
        "",
        "You will then have a choice of what type",
        "of alien animal you want to be.",
    ])
    }
    let height = 110 + Double(lines.count) * 29
    let card = CGRect(x: 170, y: 24, width: 860, height: height)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 14)
    fill(ctx, card, Color(red: 0.06, green: 0.12, blue: 0.07), corner: 14)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 14), with: .color(changeGlow), lineWidth: 3)
    ctx.draw(Text(title).font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(changeGlow),
             at: CGPoint(x: card.midX, y: card.minY + 34))
    for (i, kind) in AnimalKind.allCases.enumerated() {
        ctx.fill(hexagon(CGPoint(x: card.midX + (Double(i) - Double(AnimalKind.allCases.count - 1) / 2) * 30, y: card.minY + 64), 9), with: .color(kind.color))
    }
    for (i, s) in lines.enumerated() {
        ctx.draw(Text(s).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.93)),
                 at: CGPoint(x: card.minX + 34, y: card.minY + 98 + Double(i) * 29), anchor: .leading)
    }
}

/// How much of an alien animal each of the family (and any visitors) is, top right.
private func drawHUD(_ ctx: GraphicsContext, d: Director, now: Date) {
    let people = d.hudPeople
    guard people.contains(where: { $0.animal != nil }) else { return }
    for (i, p) in people.enumerated() {
        let r = CGRect(x: Stage.W - 236, y: 12 + Double(i) * 30, width: 224, height: 25)
        fill(ctx, r, .black.opacity(0.55), corner: 12.5)
        ctx.draw(Text(p.id).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.white),
                 at: CGPoint(x: r.minX + 12, y: r.midY), anchor: .leading)
        let u = p.progress(at: now)
        let s = p.strength(at: now)
        let (label, color): (String, Color) = if p.animal != nil, now < p.changeT0, p.isTingling(at: now) { ("tingling…", .yellow) }
            else if p.animal != nil, u < 1, now >= p.changeT0 { ("changing \(Int(u * 100))%", .orange) }
            else if let kind = p.animal, s > 0.005, u >= 1 { ("\(kind.name.uppercased()) \(Int((s * 100).rounded()))%", .white) }
            else if p.animal != nil, u >= 1 { ("human again", .white.opacity(0.7)) } else { ("human", .white.opacity(0.6)) }
        if let kind = p.animal {
            ctx.fill(hexagon(CGPoint(x: r.minX + 76, y: r.midY), 5.5), with: .color(kind.color.opacity(max(0.25, s))))
        }
        ctx.draw(Text(label).font(.system(size: 12, weight: .heavy, design: .rounded).monospacedDigit()).foregroundStyle(color),
                 at: CGPoint(x: r.maxX - 12, y: r.midY), anchor: .trailing)
    }
}

/// "Five minutes later…" — a stopwatch counting down.
private func drawClock(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSince(d.clockT0)
    guard t >= 0 && t < d.clockDur + 1 else { return }
    let u = min(t / d.clockDur, 1)
    let card = CGRect(x: 20, y: 20, width: 270, height: 90)
    fill(ctx, card, .black.opacity(0.6), corner: 16)
    let c = CGPoint(x: card.minX + 45, y: card.midY)
    ctx.fill(circle(c, 30), with: .color(.white))
    ctx.stroke(circle(c, 30), with: .color(changeGlow), lineWidth: 4)
    var wedge = Path()
    wedge.move(to: c)
    wedge.addArc(center: c, radius: 26, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * u), clockwise: false)
    wedge.closeSubpath()
    ctx.fill(wedge, with: .color(changeGlow.opacity(0.5)))
    var hand = Path()
    hand.move(to: c)
    hand.addLine(to: CGPoint(x: c.x + sin(u * 2 * .pi) * 24, y: c.y - cos(u * 2 * .pi) * 24))
    ctx.stroke(hand, with: .color(.black), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    ctx.draw(Text(d.clockLabel).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: card.minX + 90, y: card.minY + 30), anchor: .leading)
    let left = max(0, d.clockSpan - Int(u * Double(d.clockSpan)))
    ctx.draw(Text(String(format: "%d:%02d", left / 60, left % 60)).font(.system(size: 28, weight: .black, design: .monospaced)).foregroundStyle(changeGlow),
             at: CGPoint(x: card.minX + 90, y: card.minY + 62), anchor: .leading)
}

private func drawCashPop(_ ctx: GraphicsContext, _ text: String, x: Double, age: Double) {
    guard age >= 0 && age < 2 else { return }
    let color: Color = text.hasPrefix("-") ? .red : Color(red: 0.10, green: 0.60, blue: 0.20)
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(color.opacity(1 - age / 2)),
             at: CGPoint(x: x, y: Stage.floorY - 215 - age * 30))
}
