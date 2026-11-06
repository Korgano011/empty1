import SwiftUI

// The new house's spare room (the Animals of Poker machine and its mini saucer)
// and the backyard cottage where the flying zoo installs the family's own transformation machine.

private func box(_ ctx: GraphicsContext, _ rect: CGRect, _ c: Color, corner: Double = 0) {
    ctx.fill(Path(roundedRect: rect, cornerRadius: corner), with: .color(c))
}

private func dot(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

private let woodDark = Color(red: 0.42, green: 0.27, blue: 0.14)
private let woodLight = Color(red: 0.70, green: 0.50, blue: 0.30)
private let gold = Color(red: 1.0, green: 0.78, blue: 0.25)

// MARK: The spare room

func drawSpareRoom(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let floor = Stage.floorY
    // Sage-green wallpaper with faint stripes, and a wooden floor.
    box(ctx, CGRect(x: 0, y: 0, width: Stage.W, height: floor), Color(red: 0.80, green: 0.87, blue: 0.76))
    for x in stride(from: 0.0, to: Stage.W, by: 36) {
        box(ctx, CGRect(x: x, y: 0, width: 12, height: floor), Color(red: 0.74, green: 0.82, blue: 0.70))
    }
    box(ctx, CGRect(x: 0, y: floor - 70, width: Stage.W, height: 6), Color(white: 0.95))
    box(ctx, CGRect(x: 0, y: floor, width: Stage.W, height: Stage.H - floor), Color(red: 0.62, green: 0.44, blue: 0.26))
    for x in stride(from: 0.0, to: Stage.W, by: 90) {
        box(ctx, CGRect(x: x, y: floor, width: 1.5, height: Stage.H - floor), Color(red: 0.50, green: 0.34, blue: 0.20))
    }
    box(ctx, CGRect(x: 0, y: floor - 10, width: Stage.W, height: 10), Color(white: 0.96))

    // The door to the hall, left; a window with the morning outside; a few unpacked moving boxes.
    let door = CGRect(x: Stage.spareDoorX - 50, y: floor - 200, width: 100, height: 200)
    box(ctx, door.insetBy(dx: -8, dy: -8), Color(white: 0.96))
    box(ctx, door, Color(red: 0.30, green: 0.22, blue: 0.15))
    let win = CGRect(x: 330, y: 170, width: 150, height: 120)
    box(ctx, win.insetBy(dx: -8, dy: -8), Color(white: 0.97))
    ctx.fill(Path(win), with: .linearGradient(Gradient(colors: [Color(red: 0.5, green: 0.75, blue: 0.98), Color(red: 0.85, green: 0.95, blue: 1)]),
                                             startPoint: CGPoint(x: 0, y: win.minY), endPoint: CGPoint(x: 0, y: win.maxY)))
    box(ctx, CGRect(x: win.midX - 2, y: win.minY, width: 4, height: win.height), .white)
    box(ctx, CGRect(x: win.minX, y: win.midY - 2, width: win.width, height: 4), .white)
    for (x, w, h) in [(260.0, 70.0, 50.0), (300, 54, 40), (1050, 80, 60), (1100, 60, 44)] {
        let r = CGRect(x: x, y: floor - h - (x == 300 || x == 1100 ? 50 : 0), width: w, height: h)
        box(ctx, r, Color(red: 0.78, green: 0.62, blue: 0.40), corner: 2)
        box(ctx, CGRect(x: r.minX, y: r.minY + 6, width: r.width, height: 5), Color(red: 0.86, green: 0.78, blue: 0.55))
    }
    ctx.draw(Text("SPARE ROOM").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Color.black.opacity(0.4)),
             at: CGPoint(x: 600, y: 40))

    drawPokerMachine(ctx, d: d, now: now, t: t)
}

/// The Animals of Poker cabinet: lion-head topper, marquee, screen and buttons.
private func drawPokerMachine(_ ctx: GraphicsContext, d: Director, now: Date, t: Double) {
    let x = Stage.pokerX, floor = Stage.floorY
    let body = CGRect(x: x - 75, y: floor - 250, width: 150, height: 250)
    box(ctx, body.offsetBy(dx: 6, dy: 4), .black.opacity(0.2), corner: 10)
    ctx.fill(Path(roundedRect: body, cornerRadius: 10),
             with: .linearGradient(Gradient(colors: [Color(red: 0.12, green: 0.35, blue: 0.14), Color(red: 0.05, green: 0.18, blue: 0.07)]),
                                   startPoint: CGPoint(x: body.minX, y: 0), endPoint: CGPoint(x: body.maxX, y: 0)))
    // Chasing marquee bulbs round the edge.
    for i in 0..<18 {
        let u = Double(i) / 18
        let p = u < 0.5 ? CGPoint(x: body.minX + 6, y: body.minY + 10 + u * 2 * (body.height - 20))
                        : CGPoint(x: body.maxX - 6, y: body.maxY - 10 - (u - 0.5) * 2 * (body.height - 20))
        let on = (Int(t * 8) + i) % 3 == 0
        ctx.fill(dot(p, 3), with: .color(gold.opacity(on ? 1 : 0.3)))
    }
    // The topper: where the mini saucer lives. Its lid swings up while the saucer is out.
    let topper = CGRect(x: x - 70, y: floor - 318, width: 140, height: 70)
    box(ctx, topper, Color(red: 0.95, green: 0.72, blue: 0.25), corner: 14)
    box(ctx, topper.insetBy(dx: 6, dy: 6), Color(red: 0.15, green: 0.40, blue: 0.16), corner: 10)
    ctx.draw(Text("🦁").font(.system(size: 26)), at: CGPoint(x: topper.minX + 24, y: topper.midY))
    ctx.draw(Text("🐘").font(.system(size: 22)), at: CGPoint(x: topper.maxX - 22, y: topper.midY))
    ctx.draw(Text("ANIMALS\nOF POKER").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(gold),
             at: CGPoint(x: topper.midX, y: topper.midY))
    if d.miniShown {
        box(ctx, CGRect(x: x - 30, y: topper.minY - 16, width: 60, height: 10), Color(red: 0.5, green: 0.5, blue: 0.55), corner: 3)
    }
    // The screen: what game is on, or GAME 10 flashing.
    let scr = CGRect(x: x - 58, y: floor - 236, width: 116, height: 92)
    box(ctx, scr.insetBy(dx: -4, dy: -4), Color(white: 0.15), corner: 8)
    box(ctx, scr, Color(red: 0.05, green: 0.05, blue: 0.4), corner: 6)
    let text = d.pokerScreenText
    let flash = text.hasPrefix("GAME 10") && Int(t * 3) % 2 == 0
    ctx.draw(Text(text).font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(flash ? Color.white : gold),
             at: CGPoint(x: scr.midX, y: scr.minY + 22))
    for i in 0..<5 {
        let c = CGRect(x: scr.minX + 8 + Double(i) * 21, y: scr.minY + 42, width: 17, height: 26)
        box(ctx, c, .white, corner: 2)
        ctx.draw(Text(["♠", "♥", "♦", "♣", "★"][i]).font(.system(size: 11)).foregroundStyle(i == 1 || i == 2 ? Color.red : (i == 4 ? Color.purple : Color.black)),
                 at: CGPoint(x: c.midX, y: c.midY))
    }
    // Button deck and coin tray.
    let deck = CGRect(x: x - 72, y: floor - 136, width: 144, height: 24)
    box(ctx, deck, Color(red: 0.25, green: 0.25, blue: 0.28), corner: 4)
    for (i, c) in [Color.blue, .red, .green, .yellow, .orange].enumerated() {
        box(ctx, CGRect(x: deck.minX + 8 + Double(i) * 27, y: deck.minY + 6, width: 20, height: 11), c, corner: 3)
    }
    box(ctx, CGRect(x: x - 40, y: floor - 60, width: 80, height: 24), Color(white: 0.2), corner: 4)
    box(ctx, CGRect(x: x - 34, y: floor - 54, width: 68, height: 12), Color(white: 0.5), corner: 3)
}

/// The machine's mini saucer, and its beam when it's on.
func drawMiniSaucer(_ ctx: GraphicsContext, at c: CGPoint, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    if d.miniBeamOn {
        let a = min(max(now.timeIntervalSince(d.miniBeamT0) / 0.4, 0), 1)
        var beam = Path()
        beam.move(to: CGPoint(x: c.x - 12, y: c.y + 8))
        beam.addLine(to: CGPoint(x: c.x + 12, y: c.y + 8))
        beam.addLine(to: CGPoint(x: c.x + 62, y: Stage.floorY + 4))
        beam.addLine(to: CGPoint(x: c.x - 62, y: Stage.floorY + 4))
        beam.closeSubpath()
        let tint = d.miniBeamTint
        ctx.fill(beam, with: .linearGradient(Gradient(colors: [tint.opacity(0.55 * a), tint.opacity(0.15 * a)]),
                                             startPoint: c, endPoint: CGPoint(x: c.x, y: Stage.floorY)))
        for i in 0..<4 {
            let u = 1 - (t * 0.7 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
            let y = c.y + 8 + (Stage.floorY - c.y - 8) * u
            let hw = 12 + 50 * u
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - hw, y: y - 3, width: hw * 2, height: 6)), with: .color(.white.opacity(0.5 * a)), lineWidth: 1.2)
        }
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 62, y: Stage.floorY - 5, width: 124, height: 12)), with: .color(tint.opacity(0.35 * a)))
    }
    // Glass dome, silver hull, chasing lights.
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 13, y: c.y - 20, width: 26, height: 22)), with: .color(Color(red: 0.6, green: 0.95, blue: 0.7).opacity(0.85)))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 34, y: c.y - 8, width: 68, height: 18)),
             with: .linearGradient(Gradient(colors: [Color(white: 0.92), Color(white: 0.55)]), startPoint: CGPoint(x: c.x, y: c.y - 8), endPoint: CGPoint(x: c.x, y: c.y + 10)))
    for i in 0..<6 {
        let on = (Int(t * 10) + i) % 2 == 0
        ctx.fill(dot(CGPoint(x: c.x - 25 + Double(i) * 10, y: c.y + 2), 2.2), with: .color([gold, Color.red, Color.green][i % 3].opacity(on ? 1 : 0.35)))
    }
}

// MARK: The backyard cottage

func drawCottage(_ ctx: GraphicsContext, d: Director, now: Date) {
    let floor = Stage.floorY, wall = Stage.cottageWallX
    let t = now.timeIntervalSinceReferenceDate
    // Backyard: sky, lawn, a picket fence and a shade tree.
    drawSky(ctx)
    box(ctx, CGRect(x: 0, y: floor, width: Stage.W, height: Stage.H - floor), Color(red: 0.45, green: 0.72, blue: 0.35))
    box(ctx, CGRect(x: 0, y: floor - 60, width: wall, height: 6), Color(white: 0.96))
    box(ctx, CGRect(x: 0, y: floor - 30, width: wall, height: 6), Color(white: 0.96))
    for x in stride(from: 6.0, to: wall, by: 22) {
        var picket = Path()
        picket.move(to: CGPoint(x: x, y: floor))
        picket.addLine(to: CGPoint(x: x, y: floor - 70))
        picket.addLine(to: CGPoint(x: x + 6, y: floor - 78))
        picket.addLine(to: CGPoint(x: x + 12, y: floor - 70))
        picket.addLine(to: CGPoint(x: x + 12, y: floor))
        picket.closeSubpath()
        ctx.fill(picket, with: .color(.white))
    }
    box(ctx, CGRect(x: 40, y: floor - 190, width: 18, height: 130), Color(red: 0.45, green: 0.30, blue: 0.18))
    for (dx, dy, r) in [(49.0, -205.0, 52.0), (20, -180, 38), (80, -178, 40)] {
        ctx.fill(dot(CGPoint(x: dx, y: floor + dy), r), with: .color(Color(red: 0.25, green: 0.55, blue: 0.27)))
    }

    // The cottage, cut away: a peaked roof, board-and-batten walls, a striped awning sign.
    var roof = Path()
    roof.move(to: CGPoint(x: wall - 24, y: 130))
    roof.addLine(to: CGPoint(x: (wall + Stage.W) / 2, y: 38))
    roof.addLine(to: CGPoint(x: Stage.W + 20, y: 130))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.55, green: 0.20, blue: 0.16)))
    ctx.stroke(roof, with: .color(Color(red: 0.35, green: 0.12, blue: 0.10)), lineWidth: 5)
    let inside = CGRect(x: wall, y: 130, width: Stage.W - wall, height: floor - 130)
    box(ctx, inside, Color(red: 0.93, green: 0.84, blue: 0.66))
    for x in stride(from: wall + 30, to: Stage.W, by: 60) {
        box(ctx, CGRect(x: x, y: inside.minY, width: 5, height: inside.height), Color(red: 0.85, green: 0.74, blue: 0.55))
    }
    // Jungle mural stripe and the sign.
    box(ctx, CGRect(x: wall, y: 130, width: inside.width, height: 26), Color(red: 0.25, green: 0.55, blue: 0.27))
    for i in 0..<Int(inside.width / 40) {
        ctx.draw(Text(["🌴", "🐾", "🦓", "🐾"][i % 4]).font(.system(size: 14)), at: CGPoint(x: wall + 20 + Double(i) * 40, y: 143))
    }
    let sign = CGRect(x: 820, y: 168, width: 300, height: 34)
    box(ctx, sign.insetBy(dx: -5, dy: -5), woodDark, corner: 10)
    box(ctx, sign, woodLight, corner: 8)
    ctx.draw(Text("OUR ANIMAL COTTAGE").font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.95, blue: 0.75)),
             at: CGPoint(x: sign.midX, y: sign.midY))
    // A round window over the console, and the wooden floor.
    let win = CGRect(x: 1080, y: 230, width: 80, height: 80)
    ctx.fill(Path(ellipseIn: win.insetBy(dx: -6, dy: -6)), with: .color(woodDark))
    ctx.fill(Path(ellipseIn: win), with: .color(Color(red: 0.6, green: 0.82, blue: 1)))
    box(ctx, CGRect(x: wall, y: floor, width: Stage.W - wall, height: Stage.H - floor), Color(red: 0.66, green: 0.48, blue: 0.30))
    for x in stride(from: wall, to: Stage.W, by: 70) {
        box(ctx, CGRect(x: x, y: floor, width: 1.5, height: Stage.H - floor), Color(red: 0.52, green: 0.36, blue: 0.22))
    }
    // The open front wall: a post with the doorway into the backyard.
    box(ctx, CGRect(x: wall - 6, y: 130, width: 12, height: Stage.doorwayTop - 130), woodDark)
    box(ctx, CGRect(x: wall - 10, y: Stage.doorwayTop - 6, width: 20, height: 8), woodDark)
    // Glow rings under the chairs once the machine is in.
    let level = d.cottageMachineLevel(at: now)
    if level > 0 {
        for x in Stage.chairX {
            ctx.stroke(Path(ellipseIn: CGRect(x: x - 60, y: floor + 8, width: 120, height: 22)),
                       with: .color(changeGlow.opacity(level * (0.45 + 0.25 * sin(t * 2)))), lineWidth: 2.5)
        }
    }
    // Sparkles while the zoo's beam builds the machine.
    let build = now.timeIntervalSince(d.cottageMachineT0)
    if build >= 0 && build < 3.5 {
        for i in 0..<40 {
            let k = Double(i)
            let x = Stage.chairX[0] - 80 + (k * 53).truncatingRemainder(dividingBy: Stage.consoleX - Stage.chairX[0] + 160)
            let y = floor - 20 - ((k * 37 + build * 120).truncatingRemainder(dividingBy: 300))
            ctx.fill(dot(CGPoint(x: x, y: y), 2 + (k.truncatingRemainder(dividingBy: 3))), with: .color(.white.opacity(0.8 * (1 - build / 3.5))))
        }
    }
}
