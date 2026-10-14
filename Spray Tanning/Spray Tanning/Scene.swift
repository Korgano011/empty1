import SwiftUI

/// World layout: a cut-away side view of the one-story house, in points.
enum Stage {
    static let W = 1200.0
    static let H = 600.0
    static let floorY = 490.0
    static let ceilY = 180.0
    static let doorwayTop = floorY - 175

    static let rooms: [(name: String, x0: Double, x1: Double, wall: RGB)] = [
        ("Empty Room", 0, 400, RGB(r: 0.93, g: 0.93, b: 0.90)),
        ("Bathroom", 400, 560, RGB(r: 0.78, g: 0.90, b: 0.95)),
        ("Living Room", 560, 830, RGB(r: 0.98, g: 0.90, b: 0.75)),
        ("Girls' Room", 830, 1015, RGB(r: 0.98, g: 0.80, b: 0.88)),
        ("Mom's Room", 1015, 1200, RGB(r: 0.85, g: 0.88, b: 0.78)),
    ]

    static let booth = CGRect(x: 25, y: floorY - 205, width: 110, height: 205)
    static let boothX = 80.0
    static let mirror = CGRect(x: 155, y: floorY - 185, width: 62, height: 125)
    static let mirrorStand = 250.0
    static let sinkX = 490.0
    static let doorX = 790.0
    /// Main Street in town: the grocery store and the bank.
    static let storeDoorX = 330.0
    static let bankDoorX = 860.0
    /// At a venue the booth and mirror move right by this much, to the centre.
    static let venueShift = 520.0
    /// Gia's spots at the tanning salon and at the convention.
    static let salonGiaX = 560.0
    static let salonDeskX = 980.0
    static let conventionGiaX = 450.0
    static let conventionGuestX = 880.0
    /// Where Mom stands behind the cash table at a venue.
    static let cashX = 420.0

    // Camera shots, all the stage's 2:1 shape.
    static let full = CGRect(x: 0, y: 0, width: W, height: H)
    static let boothView = CGRect(x: 0, y: floorY - 205, width: 420, height: 210)

    /// A close-up `height` tall, centred on a point.
    static func focus(_ c: CGPoint, height: Double) -> CGRect {
        let width = height * W / H
        let x = min(max(c.x - width / 2, 0), W - width)
        let y = min(max(c.y - height / 2, 0), H - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Where someone's face is, standing on the floor.
    static func headY(of p: Person) -> Double {
        floorY - p.height * 0.74 - p.height * p.headScale * 0.85
    }

    /// A close-up `height` tall, centred on `centerX`, with a little floor showing.
    static func shot(centerX: Double, height: Double) -> CGRect {
        let width = height * W / H
        let x = min(max(centerX - width / 2, 0), W - width)
        return CGRect(x: x, y: floorY + 12 - height, width: width, height: height)
    }
}

func drawStage(_ ctx: GraphicsContext, size: CGSize, director d: Director, now: Date) {
    var ctx = ctx
    let s = min(size.width / Stage.W, size.height / Stage.H)
    ctx.translateBy(x: (size.width - Stage.W * s) / 2, y: (size.height - Stage.H * s) / 2)
    ctx.scaleBy(x: s, y: s)
    ctx.clip(to: Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)))
    let screen = ctx

    let cam = d.camera(at: now)
    let zoom = Stage.W / cam.width
    ctx.scaleBy(x: zoom, y: zoom)
    ctx.translateBy(x: -cam.minX, y: -cam.minY)

    if d.inTown {
        drawTown(ctx, now: now)
    } else if d.place == .salon {
        drawSalon(ctx, d: d, now: now)
    } else if d.place == .convention {
        drawConvention(ctx, now: now)
    } else if let venue = d.venue {
        drawVenue(ctx, venue, now: now)
    } else {
        drawHouse(ctx, d: d, now: now)
    }
    // Booth and mirror are drawn in booth-local coordinates, shifted to the centre at a venue.
    let dx = d.venue == nil && d.place != .convention ? 0 : Stage.venueShift
    var boothCtx = ctx
    boothCtx.translateBy(x: dx, y: 0)
    let showBooth = !d.inTown && d.place != .salon && !d.boothHidden
    if showBooth {
        drawBoothBack(boothCtx, sign: !d.boothCovered)
        for p in d.everyone where p.visible && abs(p.x(at: now) - Stage.mirrorStand - dx) < 3 && !p.isWalking(at: now) {
            drawReflection(boothCtx, p, now: now)
        }
    }
    if let bx = d.bagsX { drawBags(ctx, at: CGPoint(x: bx, y: Stage.floorY), scale: 1.1) }

    let order = d.everyone.filter(\.visible).sorted { $0.height > $1.height }
    for p in order {
        drawPerson(ctx, p, feet: CGPoint(x: p.x(at: now), y: Stage.floorY), facing: p.facing, now: now)
    }

    if showBooth {
        drawBoothFront(boothCtx, d: d, now: now, dx: dx)
        if d.boothCovered { drawBoothCover(boothCtx) }
    }
    if d.night && d.venue == nil && !d.inTown { drawNight(ctx, d: d, now: now) }
    for p in order { drawSpeech(ctx, p, now: now, view: cam) }
    if now < d.signUntil { drawSignCard(ctx) }
    if now < d.flyerUntil { drawFlyer(ctx) }
    if let pop = d.cashPop { drawCashPop(ctx, pop.text, age: now.timeIntervalSince(pop.t0)) }

    drawClock(screen, d: d, now: now)

    let fade = d.fade(at: now)
    if fade > 0 {
        ctx.fill(Path(CGRect(x: -2000, y: -2000, width: 6000, height: 6000)), with: .color(.black.opacity(fade)))
    }
}

/// While the booth sprays: a five-minute countdown in the corner of the screen.
private func drawClock(_ ctx: GraphicsContext, d: Director, now: Date) {
    let u = now.timeIntervalSince(d.clockT0) / d.clockDur
    guard u >= 0 && u < 1.15 else { return }
    let left = max(0, Int((300 * (1 - min(u, 1))).rounded(.up)))
    let card = CGRect(x: Stage.W - 230, y: 20, width: 210, height: 84)
    fill(ctx, card, Color.black.opacity(0.6), corner: 12)
    ctx.draw(Text("SPRAY TAN · 5 MINUTES").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(.orange),
             at: CGPoint(x: card.midX, y: card.minY + 20))
    ctx.draw(Text(String(format: "%d:%02d", left / 60, left % 60)).font(.system(size: 34, weight: .black, design: .monospaced)).foregroundStyle(.white),
             at: CGPoint(x: card.midX, y: card.minY + 52))
    let bar = CGRect(x: card.minX + 14, y: card.maxY - 12, width: card.width - 28, height: 5)
    fill(ctx, bar, .white.opacity(0.25), corner: 2.5)
    fill(ctx, CGRect(x: bar.minX, y: bar.minY, width: bar.width * min(u, 1), height: bar.height), .orange, corner: 2.5)
}

// MARK: Night and town

/// Nighttime: a dark sky with a moon and stars outside, lamplight inside, and Zs over everyone asleep.
private func drawNight(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let house = CGRect(x: 0, y: Stage.ceilY, width: Stage.W, height: Stage.floorY - Stage.ceilY)
    var outside = Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H))
    outside.addPath(Path(house))
    ctx.fill(outside, with: .color(Color(red: 0.04, green: 0.06, blue: 0.20).opacity(0.78)), style: FillStyle(eoFill: true))
    ctx.fill(Path(house), with: .color(Color(red: 0.05, green: 0.05, blue: 0.25).opacity(0.28)))
    ctx.fill(Path(ellipseIn: CGRect(x: 1070, y: 22, width: 64, height: 64)), with: .color(Color(red: 1, green: 0.97, blue: 0.82)))
    ctx.fill(Path(ellipseIn: CGRect(x: 1088, y: 14, width: 60, height: 60)), with: .color(Color(red: 0.06, green: 0.08, blue: 0.24)))
    for i in 0..<26 {
        let p = CGPoint(x: Double((i * 97 + 31) % 1200), y: 12 + Double((i * 53) % 60))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3)),
                 with: .color(.white.opacity(0.5 + 0.4 * sin(t * 2 + Double(i)))))
    }
    for (i, s) in d.sleepers.enumerated() {
        for k in 0..<3 {
            let u = (t * 0.4 + Double(k) / 3 + Double(i) * 0.17).truncatingRemainder(dividingBy: 1)
            ctx.draw(Text("z").font(.system(size: 12 + u * 12, weight: .heavy, design: .rounded)).foregroundStyle(Color(red: 0.2, green: 0.25, blue: 0.55).opacity(1 - u)),
                     at: CGPoint(x: s.x + u * 26 + Double(i % 3) * 6, y: Stage.floorY - 70 - u * 70))
        }
    }
}

/// Main Street: the grocery store and the bank.
private func drawTown(_ ctx: GraphicsContext, now: Date) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.98, green: 0.70, blue: 0.45), Color(red: 0.98, green: 0.88, blue: 0.70)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 30), Color(white: 0.78))
    fill(ctx, CGRect(x: 0, y: Stage.floorY + 30, width: Stage.W, height: Stage.H - Stage.floorY - 30), Color(white: 0.35))
    for x in stride(from: 30.0, to: Stage.W, by: 120) { fill(ctx, CGRect(x: x, y: Stage.floorY + 62, width: 50, height: 5), Color(red: 1, green: 0.85, blue: 0.2)) }
    // Grocery store
    let store = CGRect(x: 170, y: 250, width: 320, height: Stage.floorY - 250)
    fill(ctx, store, Color(red: 0.85, green: 0.30, blue: 0.25))
    for k in 0..<8 { fill(ctx, CGRect(x: store.minX + Double(k) * 40, y: store.minY + 44, width: 40, height: 18), k % 2 == 0 ? .white : Color(red: 0.30, green: 0.65, blue: 0.35)) }
    ctx.draw(Text("FRESH MARKET").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: store.midX, y: store.minY + 22))
    for x in [store.minX + 22, store.maxX - 102] { fill(ctx, CGRect(x: x, y: store.minY + 80, width: 80, height: 70), Color(red: 0.75, green: 0.90, blue: 1)) }
    fill(ctx, CGRect(x: Stage.storeDoorX - 30, y: Stage.floorY - 110, width: 60, height: 110), Color(red: 0.65, green: 0.85, blue: 0.95))
    // Bank
    let bank = CGRect(x: 700, y: 230, width: 320, height: Stage.floorY - 230)
    fill(ctx, bank, Color(red: 0.90, green: 0.88, blue: 0.82))
    var pediment = Path()
    pediment.move(to: CGPoint(x: bank.minX - 10, y: bank.minY))
    pediment.addLine(to: CGPoint(x: bank.midX, y: bank.minY - 50))
    pediment.addLine(to: CGPoint(x: bank.maxX + 10, y: bank.minY))
    pediment.closeSubpath()
    ctx.fill(pediment, with: .color(Color(red: 0.82, green: 0.80, blue: 0.74)))
    ctx.draw(Text("FIRST NATIONAL BANK").font(.system(size: 18, weight: .black, design: .serif)).foregroundStyle(Color(red: 0.25, green: 0.30, blue: 0.45)),
             at: CGPoint(x: bank.midX, y: bank.minY + 24))
    for x in stride(from: bank.minX + 30, to: bank.maxX - 20, by: 58) where abs(x - Stage.bankDoorX) > 40 {
        fill(ctx, CGRect(x: x, y: bank.minY + 50, width: 16, height: bank.height - 50), Color(white: 0.97))
    }
    fill(ctx, CGRect(x: Stage.bankDoorX - 32, y: Stage.floorY - 120, width: 64, height: 120), Color(red: 0.40, green: 0.28, blue: 0.18))
    ctx.draw(Text("$").font(.system(size: 30, weight: .black)).foregroundStyle(Color(red: 0.85, green: 0.70, blue: 0.20)), at: CGPoint(x: Stage.bankDoorX, y: Stage.floorY - 145))
}

// MARK: House

private func fill(_ ctx: GraphicsContext, _ rect: CGRect, _ c: Color, corner: Double = 0) {
    ctx.fill(Path(roundedRect: rect, cornerRadius: corner), with: .color(c))
}

private func drawHouse(_ ctx: GraphicsContext, d: Director, now: Date) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.55, green: 0.78, blue: 0.98), Color(red: 0.85, green: 0.94, blue: 1)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    ctx.fill(Path(ellipseIn: CGRect(x: 1080, y: 30, width: 70, height: 70)), with: .color(.yellow))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.45, green: 0.72, blue: 0.35))

    var roof = Path()
    roof.move(to: CGPoint(x: -10, y: Stage.ceilY))
    roof.addLine(to: CGPoint(x: Stage.W / 2, y: 70))
    roof.addLine(to: CGPoint(x: Stage.W + 10, y: Stage.ceilY))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.55, green: 0.25, blue: 0.20)))
    ctx.stroke(roof, with: .color(Color(red: 0.35, green: 0.15, blue: 0.12)), lineWidth: 4)

    for room in Stage.rooms {
        let r = CGRect(x: room.x0, y: Stage.ceilY, width: room.x1 - room.x0, height: Stage.floorY - Stage.ceilY)
        fill(ctx, r, room.wall.color)
        fill(ctx, CGRect(x: room.x0, y: Stage.floorY - 10, width: r.width, height: 10), Color(white: 0.97))
        ctx.draw(Text(room.name).font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.45)),
                 at: CGPoint(x: (room.x0 + room.x1) / 2, y: Stage.ceilY + 18))
    }
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: 14), Color(red: 0.55, green: 0.38, blue: 0.22))

    drawBathroom(ctx)
    drawLivingRoom(ctx, doorOpen: now < d.doorOpenUntil, machineBlinking: d.machineBlinking, now: now)
    drawGirlsRoom(ctx)
    drawMomsRoom(ctx)
    drawMirror(ctx)

    // Partitions with doorways.
    for room in Stage.rooms.dropFirst() {
        fill(ctx, CGRect(x: room.x0 - 5, y: Stage.ceilY, width: 10, height: Stage.doorwayTop - Stage.ceilY), Color(red: 0.75, green: 0.70, blue: 0.62))
    }
    let outline = Color(red: 0.45, green: 0.35, blue: 0.28)
    ctx.stroke(Path(CGRect(x: 0, y: Stage.ceilY, width: Stage.W, height: Stage.floorY - Stage.ceilY)), with: .color(outline), lineWidth: 8)
}

private func drawBathroom(_ ctx: GraphicsContext) {
    // Tub
    fill(ctx, CGRect(x: 408, y: Stage.floorY - 55, width: 45, height: 55), .white, corner: 10)
    // Sink + little mirror
    fill(ctx, CGRect(x: Stage.sinkX + 18, y: Stage.floorY - 70, width: 12, height: 70), .white)
    fill(ctx, CGRect(x: Stage.sinkX, y: Stage.floorY - 82, width: 48, height: 16), .white, corner: 6)
    fill(ctx, CGRect(x: Stage.sinkX + 21, y: Stage.floorY - 94, width: 5, height: 14), .gray)
    fill(ctx, CGRect(x: Stage.sinkX + 4, y: Stage.floorY - 170, width: 40, height: 55), Color(red: 0.80, green: 0.92, blue: 1), corner: 4)
}

private func drawLivingRoom(_ ctx: GraphicsContext, doorOpen: Bool, machineBlinking: Bool, now: Date) {
    // Window
    fill(ctx, CGRect(x: 600, y: 240, width: 80, height: 70), Color(red: 0.65, green: 0.85, blue: 1), corner: 3)
    ctx.stroke(Path(CGRect(x: 600, y: 240, width: 80, height: 70)), with: .color(.white), lineWidth: 5)
    // Couch
    let couch = Color(red: 0.45, green: 0.55, blue: 0.75)
    fill(ctx, CGRect(x: 585, y: Stage.floorY - 60, width: 110, height: 35), couch, corner: 10)
    fill(ctx, CGRect(x: 580, y: Stage.floorY - 38, width: 120, height: 30), couch.opacity(0.85), corner: 8)
    // End table with the answering machine; its red light blinks when there are messages.
    let wood = Color(red: 0.55, green: 0.35, blue: 0.20)
    fill(ctx, CGRect(x: 706, y: Stage.floorY - 52, width: 44, height: 7), wood, corner: 2)
    fill(ctx, CGRect(x: 710, y: Stage.floorY - 46, width: 5, height: 46), wood)
    fill(ctx, CGRect(x: 741, y: Stage.floorY - 46, width: 5, height: 46), wood)
    fill(ctx, CGRect(x: 712, y: Stage.floorY - 66, width: 32, height: 14), Color(white: 0.18), corner: 3)
    fill(ctx, CGRect(x: 716, y: Stage.floorY - 63, width: 14, height: 8), Color(white: 0.35), corner: 2)
    let lit = machineBlinking && Int(now.timeIntervalSinceReferenceDate * 2.5) % 2 == 0
    ctx.fill(Path(ellipseIn: CGRect(x: 734, y: Stage.floorY - 62, width: 6, height: 6)),
             with: .color(lit ? .red : Color(red: 0.35, green: 0.1, blue: 0.1)))
    // Front door
    let door = CGRect(x: Stage.doorX - 27, y: Stage.floorY - 150, width: 54, height: 150)
    fill(ctx, door.insetBy(dx: -5, dy: -5), .white)
    if doorOpen {
        fill(ctx, door, Color(red: 0.55, green: 0.80, blue: 0.45))
        fill(ctx, CGRect(x: door.minX, y: door.minY, width: 14, height: door.height), Color(red: 0.55, green: 0.32, blue: 0.18))
    } else {
        fill(ctx, door, Color(red: 0.62, green: 0.36, blue: 0.20))
        ctx.fill(Path(ellipseIn: CGRect(x: door.maxX - 14, y: door.midY, width: 8, height: 8)), with: .color(.yellow))
    }
}

private func drawGirlsRoom(_ ctx: GraphicsContext) {
    // Bunk bed
    let wood = Color(red: 0.70, green: 0.50, blue: 0.30)
    fill(ctx, CGRect(x: 845, y: Stage.floorY - 150, width: 8, height: 150), wood)
    fill(ctx, CGRect(x: 950, y: Stage.floorY - 150, width: 8, height: 150), wood)
    fill(ctx, CGRect(x: 850, y: Stage.floorY - 40, width: 105, height: 18), Color(red: 0.95, green: 0.55, blue: 0.70), corner: 4)
    fill(ctx, CGRect(x: 850, y: Stage.floorY - 118, width: 105, height: 18), Color(red: 0.60, green: 0.45, blue: 0.85), corner: 4)
    // Poster
    fill(ctx, CGRect(x: 965, y: 235, width: 36, height: 48), Color(red: 1, green: 0.85, blue: 0.3), corner: 2)
    ctx.draw(Text("★").font(.system(size: 26)).foregroundStyle(.white), at: CGPoint(x: 983, y: 259))
}

private func drawMomsRoom(_ ctx: GraphicsContext) {
    fill(ctx, CGRect(x: 1040, y: Stage.floorY - 90, width: 12, height: 90), Color(red: 0.50, green: 0.33, blue: 0.20))
    fill(ctx, CGRect(x: 1045, y: Stage.floorY - 45, width: 130, height: 28), Color(red: 0.95, green: 0.95, blue: 0.98), corner: 6)
    fill(ctx, CGRect(x: 1045, y: Stage.floorY - 52, width: 30, height: 12), .white, corner: 5)
    fill(ctx, CGRect(x: 1070, y: Stage.floorY - 40, width: 105, height: 24), Color(red: 0.55, green: 0.70, blue: 0.55), corner: 6)
    // Lamp
    fill(ctx, CGRect(x: 1150, y: Stage.floorY - 110, width: 30, height: 22), Color(red: 1, green: 0.92, blue: 0.6), corner: 3)
    fill(ctx, CGRect(x: 1163, y: Stage.floorY - 88, width: 4, height: 40), .gray)
}

// MARK: Booth and mirror

private func drawBoothBack(_ ctx: GraphicsContext, sign showSign: Bool = true) {
    let b = Stage.booth
    fill(ctx, b, Color(red: 0.85, green: 0.87, blue: 0.92), corner: 8)
    fill(ctx, b.insetBy(dx: 10, dy: 22).offsetBy(dx: 0, dy: 12), Color(red: 0.97, green: 0.93, blue: 0.85), corner: 4)
    // Nozzles on the inside walls
    for i in 0..<5 {
        let y = b.minY + 45 + Double(i) * 32
        fill(ctx, CGRect(x: b.minX + 10, y: y, width: 8, height: 6), .gray, corner: 2)
        fill(ctx, CGRect(x: b.maxX - 18, y: y, width: 8, height: 6), .gray, corner: 2)
    }
    // Sign on the wall above
    guard showSign else { return }
    let sign = CGRect(x: b.minX + 5, y: Stage.ceilY + 40, width: b.width - 10, height: 50)
    fill(ctx, sign, .white, corner: 4)
    ctx.stroke(Path(roundedRect: sign, cornerRadius: 4), with: .color(.orange), lineWidth: 2)
    ctx.draw(Text("SPRAY TAN\nread first!").font(.system(size: 12, weight: .bold)).foregroundStyle(.orange),
             at: CGPoint(x: sign.midX, y: sign.midY))
}

private func drawBoothFront(_ ctx: GraphicsContext, d: Director, now: Date, dx: Double) {
    let b = Stage.booth
    let inner = b.insetBy(dx: 8, dy: 22).offsetBy(dx: 0, dy: 12)

    // Mist, rising with the spray from the feet to the face of whoever is in the booth
    let t = now.timeIntervalSince(d.sprayT0)
    let tanned = d.everyone.first { $0.visible && abs($0.x(at: now) - Stage.boothX - dx) < 2 }
    let reach = (tanned?.height ?? 150) * 0.92
    if t >= 0 && t < d.sprayDur + 0.6 {
        let fade = t > d.sprayDur ? 1 - (t - d.sprayDur) / 0.6 : 1
        var mist = ctx
        mist.clip(to: Path(inner))
        for i in 0..<90 {
            let side = i % 2 == 0 ? 0.0 : 1.0
            let row = Double(i % 5)
            let u = (t * 1.6 + rand(i, 1)).truncatingRemainder(dividingBy: 1)
            let x = side == 0 ? inner.minX + u * inner.width * 0.7 : inner.maxX - u * inner.width * 0.7
            // The jets follow the spray up from the feet to the face.
            let rise = min(1, t / max(d.sprayDur, 0.001))
            let band = Stage.floorY - 10 - rise * reach
            let y = band + (row - 2) * 9 + (rand(i, 2) - 0.5) * 30 * u
            let r = 3 + u * 9
            mist.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                      with: .color(Color(red: 0.75, green: 0.50, blue: 0.30).opacity((1 - u) * 0.45 * fade)))
        }
    }

    // Drying: warm wavy air blows in from the side vents, with an orange glow.
    let dt = now.timeIntervalSince(d.dryT0)
    if dt >= 0 && dt < d.dryDur {
        let fade = min(1, dt * 4, (d.dryDur - dt) * 4)
        var air = ctx
        air.clip(to: Path(inner))
        air.fill(Path(inner), with: .color(Color.orange.opacity(0.12 * fade)))
        let tt = now.timeIntervalSinceReferenceDate
        for i in 0..<20 {
            let right = i % 2 == 1
            let row = Double(i / 2 % 5)
            let u = (tt * 1.3 + rand(i, 3)).truncatingRemainder(dividingBy: 1)
            let x0 = right ? inner.maxX - u * inner.width * 0.6 : inner.minX + u * inner.width * 0.6
            let y0 = b.minY + 48 + row * 32 + (rand(i, 4) - 0.5) * 10
            var gust = Path()
            for step in 0...8 {
                let s = Double(step) / 8
                let pt = CGPoint(x: x0 + (right ? -1 : 1) * s * 22, y: y0 + sin(s * .pi * 2 + tt * 7 + Double(i)) * 3)
                step == 0 ? gust.move(to: pt) : gust.addLine(to: pt)
            }
            air.stroke(gust, with: .color(Color(red: 1, green: 0.55, blue: 0.2).opacity(0.7 * fade * sin(u * .pi))),
                       style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }

    // Glass door: closed across the front, or swung open to the right.
    let glass = Color(red: 0.70, green: 0.88, blue: 1)
    if d.boothClosed {
        fill(ctx, inner, glass.opacity(0.28), corner: 3)
        ctx.stroke(Path(roundedRect: inner, cornerRadius: 3), with: .color(Color(white: 0.6)), lineWidth: 3)
    } else {
        var door = Path()
        door.move(to: CGPoint(x: b.maxX, y: inner.minY))
        door.addLine(to: CGPoint(x: b.maxX + 22, y: inner.minY + 8))
        door.addLine(to: CGPoint(x: b.maxX + 22, y: inner.maxY - 8))
        door.addLine(to: CGPoint(x: b.maxX, y: inner.maxY))
        door.closeSubpath()
        ctx.fill(door, with: .color(glass.opacity(0.5)))
        ctx.stroke(door, with: .color(Color(white: 0.6)), lineWidth: 2)
    }

    // Header panel with the four level buttons
    let head = CGRect(x: b.minX, y: b.minY, width: b.width, height: 24)
    fill(ctx, head, Color(red: 0.25, green: 0.28, blue: 0.35), corner: 6)
    for (i, level) in TanLevel.allCases.enumerated() {
        let lit = d.boothClosed && d.choosingFor == nil && (t < d.sprayDur || dt < d.dryDur)
            && d.everyone.contains { $0.level == level && abs($0.x(at: now) - Stage.boothX - dx) < 2 }
        let c = CGRect(x: head.minX + 17 + Double(i) * 22, y: head.minY + 6, width: 12, height: 12)
        ctx.fill(Path(ellipseIn: c.insetBy(dx: lit ? -3 : 0, dy: lit ? -3 : 0)), with: .color(level.skin.color))
        ctx.stroke(Path(ellipseIn: c), with: .color(.white.opacity(0.7)), lineWidth: 1)
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
    // Glass sheen
    var sheen = Path()
    sheen.move(to: CGPoint(x: m.minX + 12, y: m.minY + 40))
    sheen.addLine(to: CGPoint(x: m.minX + 30, y: m.minY + 18))
    ctx.stroke(sheen, with: .color(.white.opacity(0.8)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
}

private func drawSignCard(_ ctx: GraphicsContext) {
    let card = CGRect(x: 170, y: 40, width: 330, height: 150)
    fill(ctx, card.offsetBy(dx: 4, dy: 5), .black.opacity(0.2), corner: 12)
    fill(ctx, card, .white, corner: 12)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 12), with: .color(.orange), lineWidth: 3)
    ctx.draw(Text("SPRAY TAN BOOTH").font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(.orange),
             at: CGPoint(x: card.midX, y: card.minY + 24))
    ctx.draw(Text("Dress in a bikini before using.").font(.system(size: 16, weight: .medium)).foregroundStyle(.black),
             at: CGPoint(x: card.midX, y: card.minY + 60))
    ctx.draw(Text("Select your desired level:").font(.system(size: 16, weight: .medium)).foregroundStyle(.black),
             at: CGPoint(x: card.midX, y: card.minY + 84))
    for (i, level) in TanLevel.allCases.enumerated() {
        let cx = card.minX + 50 + Double(i) * 77
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 9, y: card.minY + 103, width: 18, height: 18)), with: .color(level.skin.color))
        ctx.draw(Text(level.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.black),
                 at: CGPoint(x: cx, y: card.minY + 134))
    }
}

// MARK: People

/// Deterministic pseudo-random value in 0..<1.
private func rand(_ i: Int, _ k: Int) -> Double {
    let v = sin(Double(i) * 12.9898 + Double(k) * 78.233) * 43758.5453
    return v - floor(v)
}

private func drawBags(_ ctx: GraphicsContext, at p: CGPoint, scale: Double) {
    let paper = Color(red: 0.80, green: 0.65, blue: 0.45)
    for (dx, h) in [(-10.0, 26.0), (8.0, 22.0)] {
        let r = CGRect(x: p.x + dx * scale - 9 * scale, y: p.y - h * scale, width: 18 * scale, height: h * scale)
        fill(ctx, r, paper, corner: 2)
        ctx.draw(Text("🥖").font(.system(size: 10 * scale)), at: CGPoint(x: r.midX, y: r.minY - 2 * scale))
    }
}

func drawPerson(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, facing: Double, now: Date, reflection: Bool = false) {
    let h = p.height
    // The tan climbs from the legs up to the face.
    let skin = p.skin(at: now, part: .body).color
    let legSkin = p.skin(at: now, part: .legs).color
    let faceSkin = p.skin(at: now, part: .head).color
    let walking = !reflection && p.isWalking(at: now)
    let t = now.timeIntervalSinceReferenceDate
    let swing = walking ? sin(t * 9) : 0
    let bob = walking ? abs(swing) * 2 : 0
    let scrubbing = !reflection && now < p.scrubUntil

    let x = feet.x
    let fy = feet.y - bob
    let legLen = h * 0.44
    let torso = h * 0.30
    let hipY = fy - legLen
    let shY = hipY - torso
    let hr = h * p.headScale
    let headY = shY - hr * 0.85
    let w = h * 0.22
    let limb = StrokeStyle(lineWidth: h * 0.075, lineCap: .round)

    let shirt = (p.uniform ?? p.shirt).color
    let bottoms = (p.uniform ?? p.bottoms).color
    // Long hair hangs behind the body.
    if p.style == .long && !p.isMan {
        fill(ctx, CGRect(x: x - hr * 1.1, y: headY - hr * 0.6, width: hr * 2.2, height: hr * 2.6), p.hair.color, corner: hr * 0.8)
    }

    // Legs
    for side in [-1.0, 1.0] {
        let hip = CGPoint(x: x + side * w * 0.22, y: hipY)
        let foot = CGPoint(x: hip.x + side * swing * legLen * 0.3, y: fy)
        var leg = Path()
        leg.move(to: hip)
        leg.addLine(to: foot)
        ctx.stroke(leg, with: .color(legSkin), style: limb)
        if (p.isMan || p.uniform != nil) && p.outfit == .clothes {
            // Trousers (or the uniform's coverall legs).
            ctx.stroke(leg, with: .color(bottoms), style: StrokeStyle(lineWidth: h * 0.085, lineCap: .round))
        }
        let shoe = p.outfit == .clothes ? Color(white: 0.25) : legSkin
        ctx.fill(Path(ellipseIn: CGRect(x: foot.x - h * 0.05 + facing * h * 0.02, y: fy - h * 0.035, width: h * 0.1, height: h * 0.05)),
                 with: .color(shoe))
    }

    // Torso and clothes
    fill(ctx, CGRect(x: x - h * 0.03, y: shY - hr * 0.2, width: h * 0.06, height: hr * 0.4), skin)
    let body = CGRect(x: x - w / 2, y: shY, width: w, height: torso + h * 0.02)
    switch p.outfit {
    case .clothes:
        fill(ctx, body, shirt, corner: w * 0.3)
        if p.isMan {
            // A tie.
            var tie = Path()
            tie.move(to: CGPoint(x: x - h * 0.012, y: shY + 2))
            tie.addLine(to: CGPoint(x: x + h * 0.012, y: shY + 2))
            tie.addLine(to: CGPoint(x: x + h * 0.02, y: shY + torso * 0.6))
            tie.addLine(to: CGPoint(x: x, y: shY + torso * 0.7))
            tie.addLine(to: CGPoint(x: x - h * 0.02, y: shY + torso * 0.6))
            tie.closeSubpath()
            ctx.fill(tie, with: .color(p.swim.color))
        } else if p.uniform != nil {
            // Name patch on the uniform.
            fill(ctx, CGRect(x: x + w * 0.05, y: shY + torso * 0.2, width: w * 0.32, height: torso * 0.14), .white, corner: 2)
        }
        var skirt = Path()
        skirt.move(to: CGPoint(x: x - w / 2, y: hipY - 4))
        skirt.addLine(to: CGPoint(x: x + w / 2, y: hipY - 4))
        skirt.addLine(to: CGPoint(x: x + w * 0.62, y: hipY + legLen * 0.34))
        skirt.addLine(to: CGPoint(x: x - w * 0.62, y: hipY + legLen * 0.34))
        skirt.closeSubpath()
        if !p.isMan && p.uniform == nil { ctx.fill(skirt, with: .color(bottoms)) }
    case .swim:
        fill(ctx, body, skin, corner: w * 0.3)
        if p.onePiece {
            fill(ctx, CGRect(x: x - w / 2, y: shY + torso * 0.15, width: w, height: torso * 0.85 + legLen * 0.1), p.swim.color, corner: w * 0.25)
        } else {
            fill(ctx, CGRect(x: x - w / 2, y: shY + torso * 0.2, width: w, height: torso * 0.2), p.swim.color, corner: 3)
            fill(ctx, CGRect(x: x - w / 2, y: hipY - torso * 0.1, width: w, height: legLen * 0.14), p.swim.color, corner: 3)
        }
    }

    // Arms
    for side in [-1.0, 1.0] {
        let shoulder = CGPoint(x: x + side * (w / 2 + h * 0.01), y: shY + h * 0.03)
        var hand = CGPoint(x: x + side * (w / 2 + h * 0.05) - side * swing * torso * 0.3, y: shY + torso * 0.95)
        if scrubbing {
            hand = CGPoint(x: x + side * w * 0.3 + sin(t * 18 + side) * 6, y: shY + torso * 0.35 + cos(t * 14) * 5)
        }
        var arm = Path()
        arm.move(to: shoulder)
        arm.addLine(to: hand)
        ctx.stroke(arm, with: .color(skin), style: StrokeStyle(lineWidth: h * 0.06, lineCap: .round))
        if p.outfit == .clothes {
            var sleeve = Path()
            sleeve.move(to: shoulder)
            sleeve.addLine(to: CGPoint(x: shoulder.x + (hand.x - shoulder.x) * 0.3, y: shoulder.y + (hand.y - shoulder.y) * 0.3))
            ctx.stroke(sleeve, with: .color(shirt), style: StrokeStyle(lineWidth: h * 0.075, lineCap: .round))
        }
        if p.mop && !reflection && side == (facing >= 0 ? 1 : -1) {
            // A mop, swishing back and forth when she's standing still.
            let swish = walking ? 0 : sin(t * 5) * 14
            let head = CGPoint(x: hand.x + side * 22 + swish, y: fy - 4)
            var stick = Path()
            stick.move(to: CGPoint(x: hand.x, y: hand.y - 30))
            stick.addLine(to: head)
            ctx.stroke(stick, with: .color(Color(red: 0.60, green: 0.45, blue: 0.25)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            for k in -3...3 {
                var strand = Path()
                strand.move(to: CGPoint(x: head.x, y: head.y - 6))
                strand.addLine(to: CGPoint(x: head.x + Double(k) * 4, y: fy))
                ctx.stroke(strand, with: .color(Color(white: 0.92)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        if p.carrying && !reflection && side == (facing >= 0 ? -1 : 1) {
            drawBags(ctx, at: CGPoint(x: hand.x, y: hand.y + 24), scale: 0.9)
        }
    }

    // Pigtails / ponytail sit behind the head.
    let head = CGPoint(x: x, y: headY)
    switch p.isMan ? HairStyle.long : p.style {
    case .pigtails:
        for side in [-1.0, 1.0] {
            let c = CGPoint(x: x + side * hr * 1.05, y: headY + hr * 0.2)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - hr * 0.35, y: c.y - hr * 0.2, width: hr * 0.7, height: hr * 1.1)), with: .color(p.hair.color))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - hr * 0.2, y: c.y - hr * 0.3, width: hr * 0.4, height: hr * 0.3)), with: .color(p.swim.color))
        }
    case .ponytail:
        let back = facing == 0 ? 1.0 : -facing
        ctx.fill(Path(ellipseIn: CGRect(x: x + back * hr * 0.8 - hr * 0.35, y: headY - hr * 0.3, width: hr * 0.7, height: hr * 1.6)), with: .color(p.hair.color))
    case .long:
        break
    }

    ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr, y: head.y - hr, width: hr * 2, height: hr * 2)), with: .color(faceSkin))

    // Fringe
    var fringe = Path()
    for step in 0...16 {
        let a = (190.0 + Double(step) * 10) * .pi / 180
        let pt = CGPoint(x: head.x + cos(a) * hr * 1.05, y: head.y + sin(a) * hr * 1.05)
        step == 0 ? fringe.move(to: pt) : fringe.addLine(to: pt)
    }
    fringe.addQuadCurve(to: CGPoint(x: head.x - hr * 1.0, y: head.y - hr * 0.1),
                        control: CGPoint(x: head.x + facing * hr * 0.2, y: head.y - hr * 0.35))
    ctx.fill(fringe, with: .color(p.hair.color))

    // Face
    let look = facing * hr * 0.15
    for side in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + side * hr * 0.35 + look, y: head.y + hr * 0.1)
        ctx.fill(Path(ellipseIn: CGRect(x: e.x - hr * 0.1, y: e.y - hr * 0.12, width: hr * 0.2, height: hr * 0.24)), with: .color(.black))
    }
    let cheek: Color = p.mood == .angry ? .red.opacity(0.55) : .pink.opacity(0.5)
    ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.75 + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)), with: .color(cheek))
    ctx.fill(Path(ellipseIn: CGRect(x: head.x + hr * 0.45 + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)), with: .color(cheek))
    if p.mood == .scared {
        // Scared: a little "o" of a mouth, brows raised high, and white around the eyes.
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.12 + look, y: head.y + hr * 0.42, width: hr * 0.24, height: hr * 0.3)),
                 with: .color(Color(red: 0.55, green: 0.12, blue: 0.12)))
        for side in [-1.0, 1.0] {
            let e = CGPoint(x: head.x + side * hr * 0.35 + look, y: head.y + hr * 0.1)
            ctx.stroke(Path(ellipseIn: CGRect(x: e.x - hr * 0.17, y: e.y - hr * 0.19, width: hr * 0.34, height: hr * 0.38)),
                       with: .color(.white), lineWidth: max(1, hr * 0.06))
            var brow = Path()
            brow.move(to: CGPoint(x: e.x - hr * 0.18, y: head.y - hr * 0.3))
            brow.addQuadCurve(to: CGPoint(x: e.x + hr * 0.18, y: head.y - hr * 0.3), control: CGPoint(x: e.x, y: head.y - hr * 0.48))
            ctx.stroke(brow, with: .color(p.hair.mix(RGB(r: 0, g: 0, b: 0), 0.5).color), style: StrokeStyle(lineWidth: max(1.5, hr * 0.09), lineCap: .round))
        }
    } else {
        // Angry and sad faces turn the smile upside down.
        let corner = p.mood == .normal ? (scrubbing ? hr * 0.3 : hr * 0.7) : hr * 0.22
        let ends = p.mood == .normal ? hr * 0.45 : hr * 0.58
        var mouth = Path()
        mouth.move(to: CGPoint(x: head.x - hr * 0.25 + look, y: head.y + ends))
        mouth.addQuadCurve(to: CGPoint(x: head.x + hr * 0.25 + look, y: head.y + ends),
                           control: CGPoint(x: head.x + look, y: head.y + corner))
        ctx.stroke(mouth, with: .color(Color(red: 0.6, green: 0.15, blue: 0.15)), style: StrokeStyle(lineWidth: max(1.5, hr * 0.1), lineCap: .round))
    }
    if p.mood == .angry || p.mood == .sad {
        // Brows: angry slant down toward the nose; sad ones lift in the middle.
        for side in [-1.0, 1.0] {
            let inner = CGPoint(x: head.x + side * hr * 0.14 + look, y: head.y - hr * (p.mood == .angry ? 0.1 : 0.32))
            let outer = CGPoint(x: head.x + side * hr * 0.55 + look, y: head.y - hr * (p.mood == .angry ? 0.32 : 0.12))
            var brow = Path()
            brow.move(to: inner)
            brow.addLine(to: outer)
            ctx.stroke(brow, with: .color(p.hair.mix(RGB(r: 0, g: 0, b: 0), 0.5).color),
                       style: StrokeStyle(lineWidth: max(1.5, hr * (p.mood == .angry ? 0.14 : 0.1)), lineCap: .round))
        }
    }
    if p.mood == .sad && !reflection {
        // Tears running down both cheeks.
        let tt = now.timeIntervalSinceReferenceDate
        let blue = Color(red: 0.45, green: 0.75, blue: 1.0)
        for side in [-1.0, 1.0] {
            let e = CGPoint(x: head.x + side * hr * 0.35 + look, y: head.y + hr * 0.22)
            var streak = Path()
            streak.move(to: e)
            streak.addLine(to: CGPoint(x: e.x + side * hr * 0.05, y: head.y + hr * 0.8))
            ctx.stroke(streak, with: .color(blue.opacity(0.6)), style: StrokeStyle(lineWidth: max(1.2, hr * 0.08), lineCap: .round))
            for k in 0..<2 {
                let u = (tt * 0.9 + Double(k) * 0.5 + (side > 0 ? 0.25 : 0)).truncatingRemainder(dividingBy: 1)
                let dy = e.y + u * hr * 1.3
                let r = max(1.5, hr * 0.1)
                var drop = Path()
                drop.move(to: CGPoint(x: e.x + side * hr * 0.05 * u, y: dy - r * 1.8))
                drop.addQuadCurve(to: CGPoint(x: e.x + side * hr * 0.05 * u, y: dy + r),
                                  control: CGPoint(x: e.x + side * hr * 0.05 * u + r * 1.6, y: dy + r))
                drop.addQuadCurve(to: CGPoint(x: e.x + side * hr * 0.05 * u, y: dy - r * 1.8),
                                  control: CGPoint(x: e.x + side * hr * 0.05 * u - r * 1.6, y: dy + r))
                ctx.fill(drop, with: .color(blue.opacity(1 - u * 0.6)))
            }
        }
    }

    guard !reflection else { return }

    if p.onPhone {
        // A phone handset held to the ear.
        let side = facing >= 0 ? 1.0 : -1.0
        let ear = CGPoint(x: head.x + side * hr * 0.95, y: head.y + hr * 0.1)
        var handset = Path()
        handset.addRoundedRect(in: CGRect(x: ear.x - hr * 0.2, y: ear.y - hr * 0.75, width: hr * 0.4, height: hr * 1.5),
                               cornerSize: CGSize(width: hr * 0.18, height: hr * 0.18))
        ctx.fill(handset, with: .color(Color(white: 0.15)))
        ctx.fill(Path(ellipseIn: CGRect(x: ear.x - hr * 0.22, y: ear.y + hr * 0.05, width: hr * 0.44, height: hr * 0.44)), with: .color(skin))
    }

    // Soap bubbles while scrubbing
    if scrubbing {
        for i in 0..<14 {
            let u = (t * 0.8 + rand(i, 3)).truncatingRemainder(dividingBy: 1)
            let bx = x + (rand(i, 4) - 0.5) * w * 1.8
            let by = shY + torso * 0.5 - u * h * 0.5
            let r = 3 + rand(i, 5) * 5
            ctx.stroke(Path(ellipseIn: CGRect(x: bx - r, y: by - r, width: r * 2, height: r * 2)),
                       with: .color(.white.opacity(1 - u)), lineWidth: 1.5)
        }
    }

    // Costume-change poof
    let pt = now.timeIntervalSince(p.poofT0)
    if pt >= 0 && pt < 0.8 {
        let grow = 0.6 + pt
        let alpha = pt < 0.35 ? 1 : 1 - (pt - 0.35) / 0.45
        for i in 0..<9 {
            let a = Double(i) / 9 * 2 * .pi
            let c = CGPoint(x: x + cos(a) * w * 0.9 * grow, y: fy - h * 0.5 + sin(a) * h * 0.4 * grow)
            let r = h * 0.14 * grow
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(alpha)))
        }
    }
}

/// A speech balloon over someone's head, kept inside `view` (what the camera shows). In close-ups the text shrinks
/// so the balloon stays about the same size on screen and doesn't swallow the shot.
private func drawSpeech(_ ctx: GraphicsContext, _ p: Person, now: Date, view: CGRect) {
    guard let text = p.says, now < p.saysUntil else { return }
    let k = min(1, 1.4 * view.width / Stage.W)
    let resolved = ctx.resolve(Text(text).font(.system(size: 15 * k, weight: .medium, design: .rounded)).foregroundStyle(.black))
    let size = resolved.measure(in: CGSize(width: 220 * k, height: 200))
    let x = p.x(at: now)
    let headTop = Stage.floorY - p.height * (0.74 + p.headScale * 1.85)
    let margin = 6 * view.width / Stage.W
    var box = CGRect(x: x - size.width / 2 - 10 * k, y: headTop - size.height - 28 * k, width: size.width + 20 * k, height: size.height + 14 * k)
    box.origin.x = min(max(box.minX, view.minX + margin), view.maxX - box.width - margin)
    box.origin.y = min(max(box.minY, view.minY + margin), view.maxY - box.height - margin)
    let tailX = min(max(x, box.minX + 14 * k), box.maxX - 14 * k)

    var bubble = Path(roundedRect: box, cornerRadius: 10 * k)
    bubble.move(to: CGPoint(x: tailX - 7 * k, y: box.maxY - 1))
    bubble.addLine(to: CGPoint(x: x, y: box.maxY + 12 * k))
    bubble.addLine(to: CGPoint(x: tailX + 7 * k, y: box.maxY - 1))
    ctx.fill(bubble, with: .color(.white))
    ctx.stroke(Path(roundedRect: box, cornerRadius: 10 * k), with: .color(.black.opacity(0.35)), lineWidth: 1.5 * k)
    ctx.draw(resolved, in: box.insetBy(dx: 10 * k, dy: 7 * k))
}


// MARK: Gia's salon and the convention

/// A sheet thrown over the booth, hiding Gia's surprise until morning.
private func drawBoothCover(_ ctx: GraphicsContext) {
    // Wide enough to hide the door and the button panel on top too.
    let b = Stage.booth.insetBy(dx: -14, dy: 0).offsetBy(dx: 12, dy: 0)
    var sheet = Path()
    sheet.move(to: CGPoint(x: b.minX - 8, y: Stage.floorY))
    sheet.addLine(to: CGPoint(x: b.minX - 4, y: b.minY))
    sheet.addQuadCurve(to: CGPoint(x: b.maxX + 4, y: b.minY), control: CGPoint(x: b.midX, y: b.minY - 50))
    sheet.addLine(to: CGPoint(x: b.maxX + 8, y: Stage.floorY))
    for k in stride(from: 4, through: 0, by: -1) {
        let x = b.minX - 8 + Double(k) * (b.width + 16) / 4
        sheet.addQuadCurve(to: CGPoint(x: x, y: Stage.floorY), control: CGPoint(x: x + (b.width + 16) / 8, y: Stage.floorY - 10))
    }
    sheet.closeSubpath()
    ctx.fill(sheet, with: .linearGradient(Gradient(colors: [Color(red: 0.86, green: 0.90, blue: 0.98), Color(red: 0.70, green: 0.76, blue: 0.90)]),
                                          startPoint: CGPoint(x: b.minX, y: b.minY), endPoint: CGPoint(x: b.maxX, y: Stage.floorY)))
    ctx.stroke(sheet, with: .color(Color(red: 0.50, green: 0.56, blue: 0.72)), lineWidth: 2)
    // Folds
    for k in 1...3 {
        let x = b.minX + Double(k) * b.width / 4
        var fold = Path()
        fold.move(to: CGPoint(x: x + 6, y: b.minY + 30))
        fold.addQuadCurve(to: CGPoint(x: x - 4, y: Stage.floorY - 10), control: CGPoint(x: x - 10, y: b.midY))
        ctx.stroke(fold, with: .color(Color(red: 0.55, green: 0.62, blue: 0.80).opacity(0.7)), lineWidth: 2)
    }
}

private func drawSalon(_ ctx: GraphicsContext, d: Director, now: Date) {
    let dim = d.salonClosed
    // Peach walls and a checkerboard floor.
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY)),
             with: .linearGradient(Gradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.68), Color(red: 1.0, green: 0.92, blue: 0.82)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    for i in 0..<30 {
        for j in 0..<3 {
            fill(ctx, CGRect(x: Double(i) * 40, y: Stage.floorY + Double(j) * 40, width: 40, height: 40),
                 (i + j) % 2 == 0 ? Color(white: 0.95) : Color(red: 0.95, green: 0.55, blue: 0.35))
        }
    }
    fill(ctx, CGRect(x: 0, y: Stage.floorY - 12, width: Stage.W, height: 12), Color(red: 0.85, green: 0.45, blue: 0.25))

    // Big sign with a sun.
    let sign = CGRect(x: 360, y: 40, width: 480, height: 80)
    fill(ctx, sign, Color(red: 0.95, green: 0.45, blue: 0.20), corner: 16)
    ctx.fill(Path(ellipseIn: CGRect(x: sign.minX + 18, y: sign.minY + 14, width: 52, height: 52)), with: .color(.yellow))
    ctx.draw(Text("SUNNY GLOW TANNING").font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: sign.midX + 30, y: sign.midY))

    // Two salon booths on the left.
    for (k, x) in [40.0, 190.0].enumerated() {
        let b = CGRect(x: x, y: Stage.floorY - 215, width: 115, height: 215)
        fill(ctx, b, Color(red: 0.85, green: 0.87, blue: 0.92), corner: 10)
        fill(ctx, b.insetBy(dx: 12, dy: 30).offsetBy(dx: 0, dy: 14), Color(red: 0.98, green: 0.80, blue: 0.55), corner: 6)
        fill(ctx, CGRect(x: b.minX + 10, y: b.minY + 8, width: b.width - 20, height: 20), .white, corner: 4)
        ctx.draw(Text("BOOTH \(k + 1)").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(.orange),
                 at: CGPoint(x: b.midX, y: b.minY + 18))
        if d.salonBroken {
            // Nobody maintains them any more: taped-on OUT OF ORDER signs.
            let tag = CGRect(x: b.midX - 46, y: b.midY - 22, width: 92, height: 44)
            var tilted = ctx
            tilted.translateBy(x: tag.midX, y: tag.midY)
            tilted.rotate(by: .degrees(k == 0 ? -8 : 6))
            let local = CGRect(x: -tag.width / 2, y: -tag.height / 2, width: tag.width, height: tag.height)
            fill(tilted, local, Color(red: 1, green: 0.97, blue: 0.85), corner: 3)
            tilted.stroke(Path(roundedRect: local, cornerRadius: 3), with: .color(.red), lineWidth: 2)
            tilted.draw(Text("OUT OF\nORDER").font(.system(size: 13, weight: .black)).foregroundStyle(.red), at: .zero)
        }
    }

    // Posters
    for (x, text) in [(380.0, "GET YOUR\nGLOW!"), (650.0, "SPRAY TAN\nSPECIALS")] {
        let r = CGRect(x: x, y: 170, width: 110, height: 120)
        fill(ctx, r, .white, corner: 6)
        ctx.stroke(Path(roundedRect: r, cornerRadius: 6), with: .color(.orange), lineWidth: 3)
        ctx.draw(Text(text).font(.system(size: 17, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.90, green: 0.40, blue: 0.15)),
                 at: CGPoint(x: r.midX, y: r.midY))
    }

    // Maintenance closet with a mop bucket.
    let closet = CGRect(x: 820, y: Stage.floorY - 170, width: 70, height: 170)
    fill(ctx, closet, Color(red: 0.55, green: 0.58, blue: 0.62), corner: 3)
    fill(ctx, CGRect(x: closet.minX + 6, y: closet.minY + 14, width: closet.width - 12, height: 18), .white, corner: 2)
    ctx.draw(Text("MAINTENANCE").font(.system(size: 8, weight: .heavy)).foregroundStyle(.black), at: CGPoint(x: closet.midX, y: closet.minY + 23))
    ctx.fill(Path(ellipseIn: CGRect(x: closet.maxX - 18, y: closet.midY, width: 8, height: 8)), with: .color(.yellow))
    var bucket = Path()
    bucket.move(to: CGPoint(x: 770, y: Stage.floorY - 34))
    bucket.addLine(to: CGPoint(x: 806, y: Stage.floorY - 34))
    bucket.addLine(to: CGPoint(x: 800, y: Stage.floorY))
    bucket.addLine(to: CGPoint(x: 776, y: Stage.floorY))
    bucket.closeSubpath()
    ctx.fill(bucket, with: .color(.yellow))

    // Reception desk with a till and a palm.
    let desk = CGRect(x: Stage.salonDeskX - 10, y: Stage.floorY - 90, width: 190, height: 90)
    fill(ctx, CGRect(x: desk.minX, y: desk.minY - 8, width: desk.width, height: 10), Color(red: 0.98, green: 0.98, blue: 0.95), corner: 3)
    fill(ctx, desk, Color(red: 0.95, green: 0.50, blue: 0.25), corner: 4)
    ctx.draw(Text("RECEPTION").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: desk.midX, y: desk.midY))
    fill(ctx, CGRect(x: desk.midX + 30, y: desk.minY - 38, width: 46, height: 30), Color(white: 0.2), corner: 4)
    fill(ctx, CGRect(x: 1150, y: Stage.floorY - 40, width: 34, height: 40), Color(red: 0.65, green: 0.40, blue: 0.25), corner: 3)
    for a in stride(from: -70.0, through: 70, by: 35) {
        var leaf = Path()
        leaf.move(to: CGPoint(x: 1167, y: Stage.floorY - 40))
        leaf.addQuadCurve(to: CGPoint(x: 1167 + a, y: Stage.floorY - 120 + abs(a) * 0.5), control: CGPoint(x: 1167 + a * 0.3, y: Stage.floorY - 130))
        ctx.stroke(leaf, with: .color(Color(red: 0.20, green: 0.60, blue: 0.30)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    }

    if dim {
        // Shut down by the health department: lights off and a notice on the wall.
        ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color(.black.opacity(0.25)))
        let n = CGRect(x: 900, y: 170, width: 260, height: 140)
        fill(ctx, n, .white, corner: 6)
        ctx.stroke(Path(roundedRect: n, cornerRadius: 6), with: .color(.red), lineWidth: 5)
        ctx.draw(Text("CLOSED").font(.system(size: 34, weight: .black)).foregroundStyle(.red), at: CGPoint(x: n.midX, y: n.minY + 34))
        ctx.draw(Text(d.salonPermanent ? "PERMANENTLY\nby order of the\nLocal Health Department" : "by order of the\nLocal Health Department\nfor 2 days")
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(.black),
                 at: CGPoint(x: n.midX, y: n.minY + 92))
    }
}

/// The flyer for the spray tan convention, held up to the screen.
private func drawFlyer(_ ctx: GraphicsContext) {
    let card = CGRect(x: 380, y: 60, width: 440, height: 250)
    fill(ctx, card.offsetBy(dx: 5, dy: 6), .black.opacity(0.25), corner: 14)
    fill(ctx, card, Color(red: 1.0, green: 0.96, blue: 0.85), corner: 14)
    ctx.stroke(Path(roundedRect: card, cornerRadius: 14), with: .color(Color(red: 0.90, green: 0.40, blue: 0.15)), lineWidth: 4)
    ctx.draw(Text("☀️ SPRAY TAN CONVENTION ☀️").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.90, green: 0.40, blue: 0.15)),
             at: CGPoint(x: card.midX, y: card.minY + 40))
    ctx.draw(Text("This Saturday · Downtown Convention Center").font(.system(size: 17, weight: .bold)).foregroundStyle(.black),
             at: CGPoint(x: card.midX, y: card.minY + 90))
    ctx.draw(Text("Live demos · The newest booths · Vendors · Prizes").font(.system(size: 15, weight: .medium)).foregroundStyle(.black.opacity(0.8)),
             at: CGPoint(x: card.midX, y: card.minY + 130))
    ctx.draw(Text("Spray tanners wanted for the demo booth!").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(Color(red: 0.75, green: 0.20, blue: 0.40)),
             at: CGPoint(x: card.midX, y: card.minY + 185))
}

private func drawConvention(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    // Hall walls, spotlights and carpet.
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.12, green: 0.14, blue: 0.30), Color(red: 0.25, green: 0.25, blue: 0.45)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.55, green: 0.12, blue: 0.20))
    for i in 0..<6 {
        let x = 100 + Double(i) * 200
        var beam = Path()
        beam.move(to: CGPoint(x: x - 8, y: 0))
        beam.addLine(to: CGPoint(x: x + 8, y: 0))
        beam.addLine(to: CGPoint(x: x + 70 + sin(t * 0.7 + Double(i)) * 30, y: Stage.floorY))
        beam.addLine(to: CGPoint(x: x - 70 + sin(t * 0.7 + Double(i)) * 30, y: Stage.floorY))
        beam.closeSubpath()
        ctx.fill(beam, with: .color(.white.opacity(0.06)))
    }

    // The hanging banner.
    let banner = CGRect(x: 300, y: 20, width: 600, height: 70)
    for x in [banner.minX + 20, banner.maxX - 20] { fill(ctx, CGRect(x: x - 1, y: 0, width: 2, height: banner.minY), Color(white: 0.7)) }
    fill(ctx, banner, Color(red: 0.95, green: 0.55, blue: 0.15), corner: 8)
    ctx.draw(Text("SPRAY TAN CONVENTION").font(.system(size: 36, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: banner.midX, y: banner.midY))

    // Exhibitor stands on both sides.
    let stands: [(Double, String, Color)] = [(20, "SunMist Pro", Color(red: 0.95, green: 0.75, blue: 0.20)), (175, "Glow Lab", Color(red: 0.85, green: 0.35, blue: 0.60)),
                                             (905, "BronzeBabe", Color(red: 0.75, green: 0.45, blue: 0.25)), (1050, "TanTastic", Color(red: 0.25, green: 0.70, blue: 0.75))]
    for (x, name, c) in stands {
        fill(ctx, CGRect(x: x, y: 190, width: 135, height: Stage.floorY - 190), c.opacity(0.85), corner: 6)
        fill(ctx, CGRect(x: x + 8, y: 200, width: 119, height: 34), .white, corner: 4)
        ctx.draw(Text(name).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(c), at: CGPoint(x: x + 67, y: 217))
        fill(ctx, CGRect(x: x + 10, y: Stage.floorY - 70, width: 115, height: 70), Color(white: 0.95), corner: 3)
        for k in 0..<3 {
            fill(ctx, CGRect(x: x + 22 + Double(k) * 34, y: Stage.floorY - 92, width: 18, height: 22), c, corner: 4)
        }
    }

    // Demo stage under the booth.
    fill(ctx, CGRect(x: 330, y: Stage.floorY, width: 560, height: 16), Color(red: 0.35, green: 0.35, blue: 0.40))
    let demo = CGRect(x: 450, y: 110, width: 300, height: 40)
    fill(ctx, demo, Color(red: 0.85, green: 0.20, blue: 0.45), corner: 20)
    ctx.draw(Text("★ LIVE DEMO ★").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: demo.midX, y: demo.midY))
    drawStandMirror(ctx, accent: Color(red: 0.85, green: 0.20, blue: 0.45))
}

/// The free-standing "Check your tan!" mirror beside the booth at a venue or the convention.
private func drawStandMirror(_ ctx: GraphicsContext, accent: Color) {
    var mirror = ctx
    mirror.translateBy(x: Stage.venueShift, y: 0)
    let m = Stage.mirror
    let wood = Color(red: 0.55, green: 0.38, blue: 0.20)
    for (top, foot) in [(m.minX + 8, m.minX - 6), (m.maxX - 8, m.maxX + 6)] {
        var leg = Path()
        leg.move(to: CGPoint(x: top, y: m.maxY))
        leg.addLine(to: CGPoint(x: foot, y: Stage.floorY))
        mirror.stroke(leg, with: .color(wood), style: StrokeStyle(lineWidth: 6, lineCap: .round))
    }
    drawMirror(mirror)
    let sign = CGRect(x: m.midX - 50, y: m.minY - 40, width: 100, height: 24)
    fill(mirror, sign, .white, corner: 5)
    mirror.stroke(Path(roundedRect: sign, cornerRadius: 5), with: .color(accent), lineWidth: 2)
    mirror.draw(Text("Check your tan!").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(accent),
                at: CGPoint(x: sign.midX, y: sign.midY))
}

// MARK: Venues

private func drawVenue(_ ctx: GraphicsContext, _ venue: Venue, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.45, green: 0.72, blue: 0.98), Color(red: 0.88, green: 0.95, blue: 1)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: Stage.floorY)))
    ctx.fill(Path(ellipseIn: CGRect(x: 1080, y: 30, width: 70, height: 70)), with: .color(.yellow))

    switch venue {
    case .stateFair: drawFairScenery(ctx, t: t)
    case .boardwalk: drawBoardwalkScenery(ctx, t: t)
    case .park: drawParkScenery(ctx, t: t)
    case .californiaCoast: drawCaliforniaScenery(ctx, t: t)
    case .tahiti: drawTahitiScenery(ctx, t: t)
    case .longBeachIsland: drawLBIScenery(ctx, t: t)
    case .capeCod: drawCapeCodScenery(ctx, t: t)
    case .keansburg: drawKeansburgScenery(ctx, t: t)
    }

    // Wooden stage under the booth
    fill(ctx, CGRect(x: 330, y: Stage.floorY, width: 560, height: 16), Color(red: 0.62, green: 0.42, blue: 0.24))
    for x in stride(from: 330.0, to: 890, by: 40) {
        fill(ctx, CGRect(x: x, y: Stage.floorY, width: 2, height: 16), Color(red: 0.45, green: 0.30, blue: 0.16))
    }

    // Striped canopy with the price banner, centred over the booth
    let accent: Color = switch venue {
    case .stateFair: .red
    case .boardwalk: Color(red: 0.10, green: 0.55, blue: 0.85)
    case .park: Color(red: 0.60, green: 0.30, blue: 0.85)
    case .californiaCoast: Color(red: 0.95, green: 0.50, blue: 0.15)
    case .tahiti: Color(red: 0.00, green: 0.62, blue: 0.62)
    case .longBeachIsland: Color(red: 0.90, green: 0.35, blue: 0.40)
    case .capeCod: Color(red: 0.15, green: 0.25, blue: 0.50)
    case .keansburg: Color(red: 0.20, green: 0.62, blue: 0.32)
    }
    let left = 360.0
    for x in [left + 4, left + 470] { fill(ctx, CGRect(x: x, y: 150, width: 10, height: Stage.floorY - 150), Color(white: 0.85)) }
    for i in 0..<12 {
        let x = left + Double(i) * 40
        fill(ctx, CGRect(x: x, y: 130, width: 40, height: 34), i % 2 == 0 ? accent : .white)
        var scallop = Path()
        scallop.addArc(center: CGPoint(x: x + 20, y: 164), radius: 20, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
        ctx.fill(scallop, with: .color(i % 2 == 0 ? accent : .white))
    }
    ctx.draw(Text("SPRAY TAN DEMO  ·  $\(venue.price)").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(.black.opacity(0.75)),
             at: CGPoint(x: left + 240, y: 110))

    // Free-standing mirror for customers
    drawStandMirror(ctx, accent: accent)

    // Cash table
    let cx = Stage.cashX
    fill(ctx, CGRect(x: cx - 30, y: Stage.floorY - 48, width: 60, height: 48), accent.opacity(0.85), corner: 3)
    fill(ctx, CGRect(x: cx - 36, y: Stage.floorY - 52, width: 72, height: 8), .white, corner: 2)
    fill(ctx, CGRect(x: cx - 18, y: Stage.floorY - 66, width: 36, height: 16), Color(red: 0.30, green: 0.55, blue: 0.30), corner: 3)
    ctx.draw(Text("$").font(.system(size: 12, weight: .black)).foregroundStyle(.white), at: CGPoint(x: cx, y: Stage.floorY - 58))
}

private func drawFairScenery(_ ctx: GraphicsContext, t: Double) {
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: Stage.H - 400), Color(red: 0.45, green: 0.72, blue: 0.35))
    // Ferris wheel
    let hub = CGPoint(x: 1040, y: 260)
    let r = 125.0
    for dx in [-60.0, 60.0] {
        var leg = Path()
        leg.move(to: hub)
        leg.addLine(to: CGPoint(x: hub.x + dx, y: 420))
        ctx.stroke(leg, with: .color(Color(white: 0.55)), lineWidth: 6)
    }
    ctx.stroke(Path(ellipseIn: CGRect(x: hub.x - r, y: hub.y - r, width: r * 2, height: r * 2)), with: .color(Color(white: 0.6)), lineWidth: 5)
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
    // Tents
    for (x, c) in [(110.0, Color.red), (250.0, Color.blue)] {
        var tent = Path()
        tent.move(to: CGPoint(x: x - 60, y: 420))
        tent.addLine(to: CGPoint(x: x, y: 330))
        tent.addLine(to: CGPoint(x: x + 60, y: 420))
        tent.closeSubpath()
        ctx.fill(tent, with: .color(c))
        for k in stride(from: -40.0, through: 40, by: 40) {
            var stripe = Path()
            stripe.move(to: CGPoint(x: x, y: 330))
            stripe.addLine(to: CGPoint(x: x + k - 8, y: 420))
            stripe.addLine(to: CGPoint(x: x + k + 8, y: 420))
            stripe.closeSubpath()
            ctx.fill(stripe, with: .color(.white))
        }
    }
    // Bunting
    for i in 0..<29 {
        let x = 20 + Double(i) * 36
        var flag = Path()
        flag.move(to: CGPoint(x: x, y: 60))
        flag.addLine(to: CGPoint(x: x + 30, y: 60))
        flag.addLine(to: CGPoint(x: x + 15, y: 85))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(colors[i % colors.count]))
    }
    ctx.draw(Text("STATE FAIR").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.red), at: CGPoint(x: 600, y: 30))
}

private func drawBoardwalkScenery(_ ctx: GraphicsContext, t: Double) {
    ctx.fill(Path(CGRect(x: 0, y: 300, width: Stage.W, height: 130)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.15, green: 0.50, blue: 0.80), Color(red: 0.35, green: 0.75, blue: 0.90)]),
                                   startPoint: CGPoint(x: 0, y: 300), endPoint: CGPoint(x: 0, y: 430)))
    for row in 0..<4 {
        var wave = Path()
        let y = 320 + Double(row) * 28
        for x in stride(from: 0.0, through: Stage.W, by: 10) {
            let pt = CGPoint(x: x, y: y + sin(x / 30 + t * 1.5 + Double(row)) * 4)
            x == 0 ? wave.move(to: pt) : wave.addLine(to: pt)
        }
        ctx.stroke(wave, with: .color(.white.opacity(0.4)), lineWidth: 2)
    }
    fill(ctx, CGRect(x: 0, y: 425, width: Stage.W, height: 45), Color(red: 0.95, green: 0.87, blue: 0.65))
    // Beach umbrella
    var umbrella = Path()
    umbrella.addArc(center: CGPoint(x: 170, y: 420), radius: 55, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
    ctx.fill(umbrella, with: .color(.orange))
    fill(ctx, CGRect(x: 168, y: 420, width: 4, height: 40), .white)
    // Boardwalk planks and railing
    fill(ctx, CGRect(x: 0, y: 470, width: Stage.W, height: Stage.H - 470), Color(red: 0.72, green: 0.52, blue: 0.32))
    for x in stride(from: 0.0, to: Stage.W, by: 30) {
        fill(ctx, CGRect(x: x, y: 470, width: 2, height: Stage.H - 470), Color(red: 0.55, green: 0.38, blue: 0.22))
    }
    fill(ctx, CGRect(x: 0, y: 420, width: Stage.W, height: 6), Color(red: 0.55, green: 0.38, blue: 0.22))
    for x in stride(from: 10.0, to: Stage.W, by: 60) {
        fill(ctx, CGRect(x: x, y: 420, width: 6, height: 50), Color(red: 0.55, green: 0.38, blue: 0.22))
    }
    // Gulls
    for i in 0..<3 {
        let x = (Double(i) * 400 + t * 40).truncatingRemainder(dividingBy: Stage.W + 100) - 50
        var gull = Path()
        gull.move(to: CGPoint(x: x - 12, y: 120 + Double(i) * 30))
        gull.addQuadCurve(to: CGPoint(x: x, y: 120 + Double(i) * 30), control: CGPoint(x: x - 6, y: 110 + Double(i) * 30))
        gull.addQuadCurve(to: CGPoint(x: x + 12, y: 120 + Double(i) * 30), control: CGPoint(x: x + 6, y: 110 + Double(i) * 30))
        ctx.stroke(gull, with: .color(.white), lineWidth: 2.5)
    }
    ctx.draw(Text("BOARDWALK").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.10, green: 0.45, blue: 0.75)),
             at: CGPoint(x: 600, y: 30))
}

// MARK: Beaches

/// Ocean from the horizon down to the beach, with rolling white wave lines.
private func ocean(_ ctx: GraphicsContext, t: Double, top: Double, bottom: Double, far: Color, near: Color) {
    ctx.fill(Path(CGRect(x: 0, y: top, width: Stage.W, height: bottom - top)),
             with: .linearGradient(Gradient(colors: [far, near]), startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: bottom)))
    for row in 0..<4 {
        var wave = Path()
        let y = top + 14 + Double(row) * (bottom - top - 20) / 4
        for x in stride(from: 0.0, through: Stage.W, by: 10) {
            let pt = CGPoint(x: x, y: y + sin(x / 30 + t * 1.5 + Double(row)) * 3)
            x == 0 ? wave.move(to: pt) : wave.addLine(to: pt)
        }
        ctx.stroke(wave, with: .color(.white.opacity(0.4)), lineWidth: 2)
    }
}

private func beachPalm(_ ctx: GraphicsContext, x: Double, base: Double, height: Double, t: Double) {
    var trunk = Path()
    trunk.move(to: CGPoint(x: x, y: base))
    trunk.addQuadCurve(to: CGPoint(x: x + 18, y: base - height), control: CGPoint(x: x - 12, y: base - height * 0.5))
    ctx.stroke(trunk, with: .color(Color(red: 0.55, green: 0.40, blue: 0.24)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    let top = CGPoint(x: x + 18, y: base - height)
    for i in 0..<7 {
        let a = Double(i) / 7 * 2 * .pi + sin(t + Double(i)) * 0.05
        var frond = Path()
        frond.move(to: top)
        frond.addQuadCurve(to: CGPoint(x: top.x + cos(a) * 50, y: top.y + abs(sin(a)) * 22 + 10), control: CGPoint(x: top.x + cos(a) * 28, y: top.y - 16))
        ctx.stroke(frond, with: .color(Color(red: 0.18, green: 0.55, blue: 0.22)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
    }
}

private func gullsOver(_ ctx: GraphicsContext, t: Double) {
    for i in 0..<3 {
        let x = (Double(i) * 400 + t * 40).truncatingRemainder(dividingBy: Stage.W + 100) - 50
        let y = 110 + Double(i) * 28
        var gull = Path()
        gull.move(to: CGPoint(x: x - 12, y: y))
        gull.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 6, y: y - 10))
        gull.addQuadCurve(to: CGPoint(x: x + 12, y: y), control: CGPoint(x: x + 6, y: y - 10))
        ctx.stroke(gull, with: .color(.white), lineWidth: 2.5)
    }
}

private func venueTitle(_ ctx: GraphicsContext, _ text: String, _ c: Color) {
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(c), at: CGPoint(x: 600, y: 30))
}

/// The California coast: sea cliffs with a lone cypress, sea stacks, a concrete arch bridge, and surfers in the Pacific.
private func drawCaliforniaScenery(_ ctx: GraphicsContext, t: Double) {
    ocean(ctx, t: t, top: 290, bottom: 430, far: Color(red: 0.10, green: 0.40, blue: 0.70), near: Color(red: 0.25, green: 0.62, blue: 0.85))
    // The arch bridge spanning a canyon in the distance, on the right
    let rock = Color(red: 0.55, green: 0.45, blue: 0.35)
    var hill = Path()
    hill.move(to: CGPoint(x: 860, y: 300)); hill.addQuadCurve(to: CGPoint(x: 1200, y: 210), control: CGPoint(x: 1000, y: 200)); hill.addLine(to: CGPoint(x: 1200, y: 300))
    hill.closeSubpath()
    ctx.fill(hill, with: .color(Color(red: 0.50, green: 0.58, blue: 0.35)))
    fill(ctx, CGRect(x: 900, y: 238, width: 220, height: 8), Color(white: 0.88))
    var arch = Path()
    arch.move(to: CGPoint(x: 930, y: 300)); arch.addQuadCurve(to: CGPoint(x: 1090, y: 300), control: CGPoint(x: 1010, y: 220))
    ctx.stroke(arch, with: .color(Color(white: 0.88)), lineWidth: 7)
    for x in stride(from: 945.0, through: 1075, by: 26) { fill(ctx, CGRect(x: x, y: 246, width: 4, height: max(4, 300 - 246 - (1 - pow((x - 1010) / 80, 2)) * 40)), Color(white: 0.85)) }
    // Sea stacks with surf breaking round them
    for (x, w, h) in [(880.0, 40.0, 70.0), (950.0, 26.0, 45.0)] {
        var stack = Path()
        stack.move(to: CGPoint(x: x, y: 330)); stack.addLine(to: CGPoint(x: x + 6, y: 330 - h)); stack.addLine(to: CGPoint(x: x + w - 4, y: 330 - h + 8)); stack.addLine(to: CGPoint(x: x + w, y: 330))
        stack.closeSubpath()
        ctx.fill(stack, with: .color(rock))
        ctx.fill(Path(ellipseIn: CGRect(x: x - 8, y: 324 + sin(t * 2 + x) * 2, width: w + 16, height: 10)), with: .color(.white.opacity(0.7)))
    }
    // Cliffs on the left with the lone cypress
    var cliff = Path()
    cliff.move(to: CGPoint(x: 0, y: 220)); cliff.addLine(to: CGPoint(x: 170, y: 232)); cliff.addLine(to: CGPoint(x: 250, y: 290)); cliff.addLine(to: CGPoint(x: 290, y: 430)); cliff.addLine(to: CGPoint(x: 0, y: 430))
    cliff.closeSubpath()
    ctx.fill(cliff, with: .color(rock))
    fill(ctx, CGRect(x: 0, y: 214, width: 175, height: 14), Color(red: 0.45, green: 0.60, blue: 0.30), corner: 6)
    var trunk = Path()
    trunk.move(to: CGPoint(x: 120, y: 222)); trunk.addQuadCurve(to: CGPoint(x: 160, y: 150), control: CGPoint(x: 150, y: 200))
    ctx.stroke(trunk, with: .color(Color(red: 0.40, green: 0.28, blue: 0.18)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
    for (dx, dy, w) in [(-30.0, 0.0, 60.0), (10.0, -14.0, 70.0), (40.0, 4.0, 50.0)] {
        ctx.fill(Path(ellipseIn: CGRect(x: 160 + dx - w / 2, y: 140 + dy, width: w, height: 22)), with: .color(Color(red: 0.15, green: 0.40, blue: 0.22)))
    }
    // A surfer riding a wave
    let sx = 900 + (t * 30).truncatingRemainder(dividingBy: 300)
    ctx.fill(Path(ellipseIn: CGRect(x: sx - 16, y: 383, width: 32, height: 5)), with: .color(.yellow))
    fill(ctx, CGRect(x: sx - 2, y: 366, width: 5, height: 17), Color(white: 0.15), corner: 2)
    ctx.fill(Path(ellipseIn: CGRect(x: sx - 4, y: 358, width: 8, height: 8)), with: .color(Color(red: 0.85, green: 0.65, blue: 0.48)))
    fill(ctx, CGRect(x: 0, y: 425, width: Stage.W, height: Stage.H - 425), Color(red: 0.94, green: 0.85, blue: 0.66))
    beachPalm(ctx, x: 1110, base: 440, height: 150, t: t)
    gullsOver(ctx, t: t)
    venueTitle(ctx, "CALIFORNIA COAST", Color(red: 0.90, green: 0.45, blue: 0.10))
}

/// Tahiti: jagged green volcanic peaks, a turquoise lagoon with thatched overwater bungalows, and an outrigger canoe.
private func drawTahitiScenery(_ ctx: GraphicsContext, t: Double) {
    // Volcanic peaks behind the lagoon
    var peaks = Path()
    peaks.move(to: CGPoint(x: 0, y: 300))
    for (x, y) in [(60.0, 180.0), (130.0, 230.0), (200.0, 120.0), (260.0, 200.0), (330.0, 160.0), (420.0, 260.0), (520.0, 300.0)] { peaks.addLine(to: CGPoint(x: x, y: y)) }
    peaks.closeSubpath()
    ctx.fill(peaks, with: .linearGradient(Gradient(colors: [Color(red: 0.15, green: 0.45, blue: 0.25), Color(red: 0.25, green: 0.60, blue: 0.30)]),
                                          startPoint: CGPoint(x: 0, y: 120), endPoint: CGPoint(x: 0, y: 300)))
    // Cloud caught on the tallest peak
    for (dx, r) in [(-20.0, 18.0), (0.0, 22.0), (24.0, 16.0)] { ctx.fill(Path(ellipseIn: CGRect(x: 200 + dx - r, y: 118 - r * 0.6, width: r * 2, height: r * 1.2)), with: .color(.white.opacity(0.9))) }
    ocean(ctx, t: t, top: 300, bottom: 430, far: Color(red: 0.05, green: 0.55, blue: 0.70), near: Color(red: 0.30, green: 0.88, blue: 0.85))
    // Overwater bungalows on stilts, linked by a walkway
    let thatch = Color(red: 0.78, green: 0.62, blue: 0.35)
    fill(ctx, CGRect(x: 860, y: 352, width: 340, height: 5), Color(red: 0.55, green: 0.40, blue: 0.25))
    for x in [880.0, 980.0, 1080.0] {
        for sx in [x + 6, x + 54] { fill(ctx, CGRect(x: sx, y: 340, width: 4, height: 50), Color(red: 0.45, green: 0.32, blue: 0.20)) }
        fill(ctx, CGRect(x: x, y: 308, width: 64, height: 34), Color(red: 0.70, green: 0.52, blue: 0.32))
        fill(ctx, CGRect(x: x + 24, y: 318, width: 16, height: 24), Color(red: 0.35, green: 0.22, blue: 0.12))
        var roof = Path()
        roof.move(to: CGPoint(x: x - 8, y: 310)); roof.addLine(to: CGPoint(x: x + 32, y: 276)); roof.addLine(to: CGPoint(x: x + 72, y: 310)); roof.closeSubpath()
        ctx.fill(roof, with: .color(thatch))
    }
    // An outrigger canoe gliding across the lagoon
    let cx = (t * 22).truncatingRemainder(dividingBy: 700) + 250
    fill(ctx, CGRect(x: cx, y: 398, width: 70, height: 8), Color(red: 0.55, green: 0.30, blue: 0.15), corner: 4)
    fill(ctx, CGRect(x: cx + 10, y: 388, width: 50, height: 3), Color(red: 0.55, green: 0.30, blue: 0.15))
    for k in 0..<3 { ctx.fill(Path(ellipseIn: CGRect(x: cx + 14 + Double(k) * 18, y: 384, width: 7, height: 7)), with: .color(Color(red: 0.55, green: 0.38, blue: 0.26))) }
    fill(ctx, CGRect(x: 0, y: 425, width: Stage.W, height: Stage.H - 425), Color(red: 0.99, green: 0.96, blue: 0.86))
    beachPalm(ctx, x: 40, base: 440, height: 170, t: t)
    beachPalm(ctx, x: 260, base: 440, height: 140, t: t + 1)
    // A hibiscus flower in the sand
    for k in 0..<5 {
        let a = Double(k) / 5 * 2 * .pi
        ctx.fill(Path(ellipseIn: CGRect(x: 1150 + cos(a) * 9 - 7, y: 448 + sin(a) * 9 - 7, width: 14, height: 14)), with: .color(Color(red: 0.95, green: 0.20, blue: 0.40)))
    }
    ctx.fill(Path(ellipseIn: CGRect(x: 1146, y: 444, width: 8, height: 8)), with: .color(.yellow))
    venueTitle(ctx, "TAHITI", Color(red: 0.00, green: 0.55, blue: 0.55))
}

/// Long Beach Island: Barnegat Lighthouse, red on top and white below, dunes with snow fencing, and the Atlantic.
private func drawLBIScenery(_ ctx: GraphicsContext, t: Double) {
    ocean(ctx, t: t, top: 300, bottom: 420, far: Color(red: 0.12, green: 0.42, blue: 0.65), near: Color(red: 0.30, green: 0.62, blue: 0.80))
    // Barnegat Light
    let lx = 150.0
    var tower = Path()
    tower.move(to: CGPoint(x: lx - 30, y: 430)); tower.addLine(to: CGPoint(x: lx - 18, y: 110)); tower.addLine(to: CGPoint(x: lx + 18, y: 110)); tower.addLine(to: CGPoint(x: lx + 30, y: 430))
    tower.closeSubpath()
    ctx.fill(tower, with: .color(.white))
    var upper = ctx
    upper.clip(to: tower)
    fill(upper, CGRect(x: lx - 40, y: 100, width: 80, height: 160), Color(red: 0.80, green: 0.15, blue: 0.15))
    fill(ctx, CGRect(x: lx - 24, y: 96, width: 48, height: 8), Color(white: 0.15))
    fill(ctx, CGRect(x: lx - 12, y: 74, width: 24, height: 22), Color(red: 1, green: 0.95, blue: 0.7))
    var cap = Path()
    cap.move(to: CGPoint(x: lx - 16, y: 76)); cap.addQuadCurve(to: CGPoint(x: lx + 16, y: 76), control: CGPoint(x: lx, y: 54))
    ctx.fill(cap, with: .color(Color(white: 0.15)))
    let sweep = sin(t * 1.2)
    var beam = Path()
    beam.move(to: CGPoint(x: lx, y: 85)); beam.addLine(to: CGPoint(x: lx + sweep * 200, y: 65)); beam.addLine(to: CGPoint(x: lx + sweep * 200, y: 105)); beam.closeSubpath()
    ctx.fill(beam, with: .color(Color(red: 1, green: 0.97, blue: 0.7).opacity(0.3 * abs(sweep))))
    // Dunes and snow fence
    var dunes = Path()
    dunes.move(to: CGPoint(x: 0, y: 440)); dunes.addQuadCurve(to: CGPoint(x: 420, y: 430), control: CGPoint(x: 200, y: 390))
    dunes.addQuadCurve(to: CGPoint(x: 860, y: 430), control: CGPoint(x: 640, y: 400)); dunes.addQuadCurve(to: CGPoint(x: Stage.W, y: 432), control: CGPoint(x: 1030, y: 385))
    dunes.addLine(to: CGPoint(x: Stage.W, y: Stage.H)); dunes.addLine(to: CGPoint(x: 0, y: Stage.H)); dunes.closeSubpath()
    ctx.fill(dunes, with: .color(Color(red: 0.95, green: 0.88, blue: 0.70)))
    for x in stride(from: 880.0, to: 1180, by: 9) { fill(ctx, CGRect(x: x, y: 396 + sin(x) * 3, width: 3, height: 30), Color(red: 0.62, green: 0.45, blue: 0.30)) }
    fill(ctx, CGRect(x: 880, y: 404, width: 300, height: 2), Color(red: 0.45, green: 0.32, blue: 0.22))
    for x in stride(from: 900.0, to: 1180, by: 26) {
        var grass = Path()
        grass.move(to: CGPoint(x: x, y: 430)); grass.addQuadCurve(to: CGPoint(x: x + sin(t + x) * 6, y: 395), control: CGPoint(x: x, y: 410))
        ctx.stroke(grass, with: .color(Color(red: 0.55, green: 0.62, blue: 0.35)), lineWidth: 2)
    }
    gullsOver(ctx, t: t)
    venueTitle(ctx, "LONG BEACH ISLAND", Color(red: 0.80, green: 0.20, blue: 0.25))
}

/// Cape Cod: a white lighthouse on the bluff, gray-shingled cottages, beach grass, lobster buoys, and sailboats on the bay.
private func drawCapeCodScenery(_ ctx: GraphicsContext, t: Double) {
    ocean(ctx, t: t, top: 300, bottom: 420, far: Color(red: 0.10, green: 0.32, blue: 0.55), near: Color(red: 0.25, green: 0.52, blue: 0.72))
    // Sailboats on the bay
    for (i, x0) in [520.0, 760.0].enumerated() {
        let x = x0 + sin(t * 0.3 + Double(i)) * 30
        fill(ctx, CGRect(x: x, y: 330, width: 50, height: 8), .white, corner: 3)
        fill(ctx, CGRect(x: x + 24, y: 270, width: 2, height: 60), Color(white: 0.4))
        var sail = Path()
        sail.move(to: CGPoint(x: x + 27, y: 272)); sail.addLine(to: CGPoint(x: x + 27, y: 326)); sail.addLine(to: CGPoint(x: x + 52, y: 326)); sail.closeSubpath()
        ctx.fill(sail, with: .color(i == 0 ? .white : Color(red: 0.85, green: 0.25, blue: 0.25)))
    }
    // The bluff and its white lighthouse
    var bluff = Path()
    bluff.move(to: CGPoint(x: 0, y: 260)); bluff.addLine(to: CGPoint(x: 240, y: 268)); bluff.addQuadCurve(to: CGPoint(x: 320, y: 430), control: CGPoint(x: 300, y: 300))
    bluff.addLine(to: CGPoint(x: 0, y: 430)); bluff.closeSubpath()
    ctx.fill(bluff, with: .color(Color(red: 0.80, green: 0.66, blue: 0.48)))
    fill(ctx, CGRect(x: 0, y: 252, width: 245, height: 14), Color(red: 0.50, green: 0.62, blue: 0.35), corner: 6)
    let lx = 90.0
    fill(ctx, CGRect(x: lx - 16, y: 150, width: 32, height: 110), .white)
    fill(ctx, CGRect(x: lx - 20, y: 144, width: 40, height: 8), Color(white: 0.15))
    fill(ctx, CGRect(x: lx - 10, y: 124, width: 20, height: 20), Color(red: 1, green: 0.95, blue: 0.7))
    var cap = Path()
    cap.move(to: CGPoint(x: lx - 13, y: 126)); cap.addQuadCurve(to: CGPoint(x: lx + 13, y: 126), control: CGPoint(x: lx, y: 106))
    ctx.fill(cap, with: .color(Color(white: 0.15)))
    fill(ctx, CGRect(x: lx + 18, y: 226, width: 40, height: 34), .white)
    fill(ctx, CGRect(x: lx + 16, y: 218, width: 44, height: 10), Color(red: 0.70, green: 0.20, blue: 0.20))
    // Gray-shingled cottages on the right
    let shingle = Color(red: 0.62, green: 0.62, blue: 0.62)
    for (i, x) in [900.0, 1040.0].enumerated() {
        fill(ctx, CGRect(x: x, y: 330, width: 110, height: 95), shingle)
        for y in stride(from: 336.0, to: 425, by: 9) { fill(ctx, CGRect(x: x, y: y, width: 110, height: 1), Color(white: 0.52)) }
        var roof = Path()
        roof.move(to: CGPoint(x: x - 8, y: 332)); roof.addLine(to: CGPoint(x: x + 55, y: 290)); roof.addLine(to: CGPoint(x: x + 118, y: 332)); roof.closeSubpath()
        ctx.fill(roof, with: .color(Color(white: 0.38)))
        for wx in [x + 14, x + 70] {
            fill(ctx, CGRect(x: wx, y: 350, width: 26, height: 26), Color(red: 0.75, green: 0.88, blue: 0.98))
            fill(ctx, CGRect(x: wx - 4, y: 350, width: 4, height: 26), i == 0 ? Color(red: 0.20, green: 0.35, blue: 0.60) : Color(red: 0.25, green: 0.50, blue: 0.35))
        }
        fill(ctx, CGRect(x: x + 46, y: 385, width: 20, height: 40), .white)
    }
    // Lobster buoys hanging on the cottage
    for (k, c) in [Color.red, .yellow, Color(red: 0.2, green: 0.5, blue: 0.9)].enumerated() {
        ctx.fill(Path(ellipseIn: CGRect(x: 1015 + Double(k) * 7, y: 360 + Double(k) * 14, width: 9, height: 16)), with: .color(c))
    }
    fill(ctx, CGRect(x: 0, y: 425, width: Stage.W, height: Stage.H - 425), Color(red: 0.93, green: 0.86, blue: 0.68))
    for x in stride(from: 870.0, to: Stage.W, by: 22) {
        var grass = Path()
        grass.move(to: CGPoint(x: x, y: 440)); grass.addQuadCurve(to: CGPoint(x: x + sin(t + x) * 6, y: 412), control: CGPoint(x: x, y: 425))
        ctx.stroke(grass, with: .color(Color(red: 0.55, green: 0.62, blue: 0.35)), lineWidth: 2)
    }
    gullsOver(ctx, t: t)
    venueTitle(ctx, "CAPE COD", Color(red: 0.15, green: 0.25, blue: 0.50))
}

/// Keansburg, on the Raritan Bayshore: the amusement park's Ferris wheel and swing ride, the twisting water slides,
/// the fishing pier out into the bay, and the New York City skyline far across the water.
private func drawKeansburgScenery(_ ctx: GraphicsContext, t: Double) {
    ocean(ctx, t: t, top: 300, bottom: 425, far: Color(red: 0.25, green: 0.45, blue: 0.62), near: Color(red: 0.38, green: 0.60, blue: 0.72))
    // Manhattan's skyline, hazy across the bay
    let haze = Color(red: 0.62, green: 0.68, blue: 0.78)
    for (x, w, h) in [(870.0, 18.0, 30.0), (890.0, 14.0, 52.0), (906.0, 20.0, 40.0), (928.0, 10.0, 70.0), (940.0, 22.0, 46.0),
                      (964.0, 12.0, 34.0), (978.0, 16.0, 58.0), (996.0, 20.0, 38.0), (1018.0, 14.0, 28.0)] {
        fill(ctx, CGRect(x: x, y: 300 - h, width: w, height: h), haze)
    }
    fill(ctx, CGRect(x: 932, y: 214, width: 2, height: 16), haze)
    // The fishing pier reaching out into the bay
    fill(ctx, CGRect(x: 860, y: 330, width: 340, height: 8), Color(red: 0.55, green: 0.42, blue: 0.30))
    for x in stride(from: 868.0, to: 1200, by: 26) { fill(ctx, CGRect(x: x, y: 338, width: 4, height: 50), Color(red: 0.42, green: 0.32, blue: 0.22)) }
    for x in [1000.0, 1120.0] {
        fill(ctx, CGRect(x: x, y: 306, width: 4, height: 26), Color(white: 0.2))
        var line = Path()
        line.move(to: CGPoint(x: x + 4, y: 306)); line.addQuadCurve(to: CGPoint(x: x + 30, y: 380), control: CGPoint(x: x + 30, y: 320))
        ctx.stroke(line, with: .color(Color(white: 0.3)), lineWidth: 0.8)
    }
    // The Ferris wheel
    let hub = CGPoint(x: 150, y: 230)
    let r = 105.0
    for side in [-1.0, 1.0] {
        var leg = Path()
        leg.move(to: hub); leg.addLine(to: CGPoint(x: hub.x + side * 55, y: 430))
        ctx.stroke(leg, with: .color(Color(white: 0.85)), lineWidth: 6)
    }
    ctx.stroke(Path(ellipseIn: CGRect(x: hub.x - r, y: hub.y - r, width: r * 2, height: r * 2)), with: .color(Color(red: 0.95, green: 0.35, blue: 0.55)), lineWidth: 5)
    let cars: [Color] = [.red, .yellow, .cyan, .green, .orange, .purple]
    for i in 0..<10 {
        let a = t * 0.25 + Double(i) / 10 * 2 * .pi
        let rim = CGPoint(x: hub.x + cos(a) * r, y: hub.y + sin(a) * r)
        var spoke = Path()
        spoke.move(to: hub); spoke.addLine(to: rim)
        ctx.stroke(spoke, with: .color(.white.opacity(0.85)), lineWidth: 1.5)
        fill(ctx, CGRect(x: rim.x - 8, y: rim.y, width: 16, height: 13), cars[i % cars.count], corner: 4)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: hub.x - 9, y: hub.y - 9, width: 18, height: 18)), with: .color(.yellow))
    // A swing ride, its seats flying out as it spins
    let sx = 300.0
    fill(ctx, CGRect(x: sx - 4, y: 220, width: 8, height: 210), Color(white: 0.85))
    var canopy = Path()
    canopy.move(to: CGPoint(x: sx - 48, y: 236)); canopy.addLine(to: CGPoint(x: sx, y: 200)); canopy.addLine(to: CGPoint(x: sx + 48, y: 236)); canopy.closeSubpath()
    ctx.fill(canopy, with: .color(Color(red: 0.20, green: 0.62, blue: 0.32)))
    for i in 0..<6 {
        let a = t * 1.6 + Double(i) / 6 * 2 * .pi
        let x = sx + cos(a) * 70
        var chain = Path()
        chain.move(to: CGPoint(x: sx + cos(a) * 40, y: 236)); chain.addLine(to: CGPoint(x: x, y: 290))
        ctx.stroke(chain, with: .color(Color(white: 0.4)), lineWidth: 1)
        fill(ctx, CGRect(x: x - 6, y: 290, width: 12, height: 8), cars[i % cars.count], corner: 2)
    }
    // The water park's twisting slides
    fill(ctx, CGRect(x: 1080, y: 190, width: 60, height: 12), Color(red: 0.98, green: 0.80, blue: 0.20), corner: 3)
    for x in [1086.0, 1130] { fill(ctx, CGRect(x: x, y: 202, width: 6, height: 228), Color(white: 0.9)) }
    for (i, c) in [Color(red: 0.15, green: 0.45, blue: 0.90), Color(red: 0.95, green: 0.30, blue: 0.35)].enumerated() {
        var slide = Path()
        let dir = i == 0 ? -1.0 : 1.0
        slide.move(to: CGPoint(x: 1110, y: 202))
        slide.addCurve(to: CGPoint(x: 1110 + dir * 60, y: 320), control1: CGPoint(x: 1110 + dir * 90, y: 220), control2: CGPoint(x: 1110 - dir * 70, y: 280))
        slide.addQuadCurve(to: CGPoint(x: 1060 + Double(i) * 90, y: 425), control: CGPoint(x: 1110 + dir * 100, y: 380))
        ctx.stroke(slide, with: .color(c), style: StrokeStyle(lineWidth: 9, lineCap: .round))
    }
    // Sand and the boardwalk's welcome sign
    fill(ctx, CGRect(x: 0, y: 425, width: Stage.W, height: Stage.H - 425), Color(red: 0.93, green: 0.85, blue: 0.66))
    gullsOver(ctx, t: t)
    venueTitle(ctx, "KEANSBURG", Color(red: 0.15, green: 0.55, blue: 0.28))
}

private func drawParkScenery(_ ctx: GraphicsContext, t: Double) {
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: Stage.H - 400), Color(red: 0.45, green: 0.72, blue: 0.35))
    // Castle
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
    // Roller coaster
    func trackY(_ x: Double) -> Double { 260 + 90 * sin(x / 70) }
    for x in stride(from: 10.0, through: 320, by: 40) {
        fill(ctx, CGRect(x: x, y: trackY(x), width: 4, height: 420 - trackY(x)), Color(white: 0.6))
    }
    var track = Path()
    for x in stride(from: 0.0, through: 330, by: 5) {
        let pt = CGPoint(x: x, y: trackY(x))
        x == 0 ? track.move(to: pt) : track.addLine(to: pt)
    }
    ctx.stroke(track, with: .color(.red), lineWidth: 6)
    for k in 0..<3 {
        let x = (t * 90 + Double(k) * 26).truncatingRemainder(dividingBy: 330)
        fill(ctx, CGRect(x: x - 11, y: trackY(x) - 16, width: 22, height: 14), .yellow, corner: 4)
    }
    // Balloons
    let colors: [Color] = [.red, .blue, .yellow, .green, .pink]
    for i in 0..<5 {
        let bx = 940 + Double(i) * 16
        let by = 360 + sin(t * 2 + Double(i)) * 4
        var string = Path()
        string.move(to: CGPoint(x: bx, y: by + 14))
        string.addLine(to: CGPoint(x: 970, y: 420))
        ctx.stroke(string, with: .color(.gray), lineWidth: 1)
        ctx.fill(Path(ellipseIn: CGRect(x: bx - 10, y: by - 14, width: 20, height: 28)), with: .color(colors[i]))
    }
    ctx.draw(Text("AMUSEMENT PARK").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.55, green: 0.25, blue: 0.80)),
             at: CGPoint(x: 600, y: 30))
}

private func drawCashPop(_ ctx: GraphicsContext, _ text: String, age: Double) {
    guard age >= 0 && age < 2 else { return }
    let color: Color = text.hasPrefix("-") ? .red : Color(red: 0.10, green: 0.60, blue: 0.20)
    ctx.draw(Text(text).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(color.opacity(1 - age / 2)),
             at: CGPoint(x: Stage.cashX, y: Stage.floorY - 215 - age * 30))
}
