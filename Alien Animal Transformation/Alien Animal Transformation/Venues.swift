import SwiftUI

private func fill(_ ctx: GraphicsContext, _ rect: CGRect, _ c: Color, corner: Double = 0) {
    ctx.fill(Path(roundedRect: rect, cornerRadius: corner), with: .color(c))
}

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

extension Venue {
    var accent: Color {
        switch self {
        case .belmar: Color(red: 0.15, green: 0.40, blue: 0.75)
        case .disneyWorld: Color(red: 0.18, green: 0.36, blue: 0.78)
        case .disneyland: Color(red: 0.85, green: 0.35, blue: 0.55)
        case .sesamePlace: Color(red: 0.10, green: 0.50, blue: 0.25)
        case .cozumel: Color(red: 0.00, green: 0.60, blue: 0.65)
        case .waikiki: Color(red: 0.90, green: 0.40, blue: 0.20)
        case .longBranch: Color(red: 0.18, green: 0.45, blue: 0.35)
        case .atlanticCity: Color(red: 0.80, green: 0.10, blue: 0.45)
        case .myrtleBeach: Color(red: 0.10, green: 0.55, blue: 0.60)
        case .crystalCoast: Color(red: 0.10, green: 0.45, blue: 0.60)
        }
    }

    var banner: String { "ALIEN ANIMAL TRANSFORMATIONS  ·  \(shortName.uppercased())  ·  $\(price)  ·  KIDS $\(kidPrice)" }
}

func drawVenue(_ ctx: GraphicsContext, _ venue: Venue, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    switch venue {
    case .belmar: drawBelmar(ctx, t: t)
    case .disneyWorld: drawDisneyWorld(ctx, t: t)
    case .disneyland: drawDisneyland(ctx, t: t)
    case .sesamePlace: drawSesamePlace(ctx, t: t)
    case .cozumel: drawCozumel(ctx, t: t)
    case .waikiki: drawWaikiki(ctx, t: t)
    case .longBranch: drawLongBranch(ctx, t: t)
    case .atlanticCity: drawAtlanticCity(ctx, t: t)
    case .myrtleBeach: drawMyrtleBeach(ctx, t: t)
    case .crystalCoast: drawCrystalCoast(ctx, t: t)
    }
    // A glowing landing ring under the zoo
    let x = Stage.venuePodX
    ctx.fill(Path(ellipseIn: CGRect(x: x - 130, y: Stage.floorY - 6, width: 260, height: 22)), with: .color(Color(red: 0.35, green: 0.12, blue: 0.10).opacity(0.5)))
    ctx.stroke(Path(ellipseIn: CGRect(x: x - 120, y: Stage.floorY - 2, width: 240, height: 14)), with: .color(Color(red: 1.0, green: 0.12, blue: 0.10)), lineWidth: 2)
    let label = ctx.resolve(Text(venue.banner).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white))
    let size = label.measure(in: CGSize(width: 1200, height: 60))
    let r = CGRect(x: 600 - size.width / 2 - 16, y: 18, width: size.width + 32, height: size.height + 12)
    fill(ctx, r, venue.accent.opacity(0.9), corner: r.height / 2)
    ctx.draw(label, at: CGPoint(x: r.midX, y: r.midY))
}

private func grass(_ ctx: GraphicsContext) {
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: Stage.H - 400), Color(red: 0.45, green: 0.72, blue: 0.35))
}

private func sea(_ ctx: GraphicsContext, t: Double, top: Double, color: Color) {
    fill(ctx, CGRect(x: 0, y: top, width: Stage.W, height: 420 - top), color)
    for k in 0..<5 {
        var wave = Path()
        let y = top + 14 + Double(k) * 16
        for x in stride(from: 0.0, through: Stage.W, by: 10) {
            let pt = CGPoint(x: x, y: y + sin(x / 30 + t * 1.5 + Double(k)) * 2.5)
            x == 0 ? wave.move(to: pt) : wave.addLine(to: pt)
        }
        ctx.stroke(wave, with: .color(.white.opacity(0.35)), lineWidth: 1.5)
    }
}

private func gulls(_ ctx: GraphicsContext, t: Double) {
    for i in 0..<3 {
        let x = (t * 30 + Double(i) * 170).truncatingRemainder(dividingBy: 700) + 450
        let y = 130 + Double(i) * 25 + sin(t * 2 + Double(i)) * 6
        var gull = Path()
        gull.move(to: CGPoint(x: x - 10, y: y))
        gull.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 5, y: y - 6))
        gull.addQuadCurve(to: CGPoint(x: x + 10, y: y), control: CGPoint(x: x + 5, y: y - 6))
        ctx.stroke(gull, with: .color(Color(white: 0.25)), lineWidth: 2)
    }
}

private func palm(_ ctx: GraphicsContext, x: Double, base: Double, height: Double, t: Double) {
    var trunk = Path()
    trunk.move(to: CGPoint(x: x, y: base))
    trunk.addQuadCurve(to: CGPoint(x: x + 20, y: base - height), control: CGPoint(x: x - 10, y: base - height * 0.5))
    ctx.stroke(trunk, with: .color(Color(red: 0.55, green: 0.40, blue: 0.24)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
    let top = CGPoint(x: x + 20, y: base - height)
    for i in 0..<7 {
        let a = Double(i) / 7 * 2 * .pi + sin(t + Double(i)) * 0.05
        var frond = Path()
        frond.move(to: top)
        frond.addQuadCurve(to: CGPoint(x: top.x + cos(a) * 55, y: top.y + abs(sin(a)) * 25 + 12),
                           control: CGPoint(x: top.x + cos(a) * 30, y: top.y - 18))
        ctx.stroke(frond, with: .color(Color(red: 0.18, green: 0.55, blue: 0.22)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
    }
    for dx in [-5.0, 5.0] { ctx.fill(circle(CGPoint(x: top.x + dx, y: top.y + 8), 5), with: .color(Color(red: 0.45, green: 0.30, blue: 0.15))) }
}

// MARK: Shared pieces

/// A cruise ship side-on: dark hull, white decks, and a funnel.
private func cruiseShip(_ ctx: GraphicsContext, x: Double, waterline: Double, width w: Double, hull: Color, t: Double,
                        funnel: (GraphicsContext, CGRect) -> Void) {
    let bob = sin(t * 0.8 + x) * 1.5
    let y = waterline + bob
    var shape = Path()
    shape.move(to: CGPoint(x: x, y: y - 28))
    shape.addLine(to: CGPoint(x: x + w, y: y - 28))
    shape.addLine(to: CGPoint(x: x + w - 16, y: y))
    shape.addLine(to: CGPoint(x: x + 14, y: y))
    shape.closeSubpath()
    ctx.fill(shape, with: .color(hull))
    let decks = [w * 0.92, w * 0.80, w * 0.66]
    for (i, dw) in decks.enumerated() {
        let dx = x + Double(i) * 12 + 14
        let dy = y - 41 - Double(i) * 13
        fill(ctx, CGRect(x: dx, y: dy, width: dw, height: 13), .white, corner: 2)
        for k in 0..<Int(dw / 12) { fill(ctx, CGRect(x: dx + 4 + Double(k) * 12, y: dy + 4, width: 6, height: 4), Color(red: 0.3, green: 0.5, blue: 0.8)) }
    }
    funnel(ctx, CGRect(x: x + w * 0.62, y: y - 41 - 2 * 13 - 26, width: 26, height: 26))
}

private func beachUmbrella(_ ctx: GraphicsContext, x: Double, _ c: Color) {
    var top = Path()
    top.addArc(center: CGPoint(x: x, y: 380), radius: 42, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
    top.closeSubpath()
    ctx.fill(top, with: .color(c))
    fill(ctx, CGRect(x: x - 2, y: 380, width: 4, height: 38), Color(white: 0.9))
}

private func sign(_ ctx: GraphicsContext, _ text: String, at r: CGRect, bg: Color, fg: Color = .white, size: Double = 11) {
    fill(ctx, CGRect(x: r.midX - 3, y: r.maxY, width: 6, height: 418 - r.maxY), Color(red: 0.45, green: 0.30, blue: 0.18))
    fill(ctx, r, bg, corner: 5)
    ctx.draw(Text(text).font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(fg),
             at: CGPoint(x: r.midX, y: r.midY))
}

// MARK: More shared pieces

/// Boardwalk planks across the front, with a white railing along the back edge.
private func boardwalk(_ ctx: GraphicsContext) {
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.74, green: 0.60, blue: 0.42))
    for x in stride(from: 0.0, to: Stage.W, by: 26) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.60, green: 0.47, blue: 0.32)) }
    fill(ctx, CGRect(x: 0, y: 398, width: Stage.W, height: 3), Color(white: 0.92))
    for x in stride(from: 0.0, to: Stage.W, by: 40) { fill(ctx, CGRect(x: x, y: 398, width: 3, height: 12), Color(white: 0.92)) }
}

private func sand(_ ctx: GraphicsContext, _ c: Color = Color(red: 0.96, green: 0.90, blue: 0.74)) {
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), c)
}

/// A tall white lifeguard chair with the town's name on the back.
private func lifeguardStand(_ ctx: GraphicsContext, x: Double, base: Double, label: String, color: Color) {
    let white = Color(white: 0.96)
    for side in [-1.0, 1.0] {
        var leg = Path()
        leg.move(to: CGPoint(x: x + side * 26, y: base))
        leg.addLine(to: CGPoint(x: x + side * 16, y: base - 72))
        ctx.stroke(leg, with: .color(white), lineWidth: 5)
    }
    for y in [base - 22, base - 48] { fill(ctx, CGRect(x: x - 24, y: y, width: 48, height: 3), white) }
    fill(ctx, CGRect(x: x - 26, y: base - 78, width: 52, height: 7), white, corner: 2)
    fill(ctx, CGRect(x: x - 22, y: base - 112, width: 44, height: 34), color, corner: 3)
    ctx.draw(Text(label).font(.system(size: 8, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: x, y: base - 95))
}

/// A Ferris wheel: open cars, or the enclosed glass gondolas of a big modern wheel.
private func ferrisWheel(_ ctx: GraphicsContext, hub: CGPoint, radius r: Double, rim: Color, count: Int, t: Double, enclosed: Bool = false) {
    for side in [-1.0, 1.0] {
        var leg = Path()
        leg.move(to: hub)
        leg.addLine(to: CGPoint(x: hub.x + side * r * 0.55, y: 405))
        ctx.stroke(leg, with: .color(Color(white: 0.88)), lineWidth: enclosed ? 9 : 6)
    }
    ctx.stroke(circle(hub, r), with: .color(rim), lineWidth: enclosed ? 7 : 5)
    ctx.stroke(circle(hub, r * 0.62), with: .color(.white.opacity(0.8)), lineWidth: 2)
    let spin = t * (enclosed ? 0.12 : 0.25)
    let cars: [Color] = [.red, .yellow, .cyan, .green, .orange, .purple]
    for i in 0..<count {
        let a = spin + Double(i) / Double(count) * 2 * .pi
        let pt = CGPoint(x: hub.x + cos(a) * r, y: hub.y + sin(a) * r)
        var spoke = Path()
        spoke.move(to: hub)
        spoke.addLine(to: pt)
        ctx.stroke(spoke, with: .color(.white.opacity(0.85)), lineWidth: 1.5)
        if enclosed {
            let g = CGRect(x: pt.x - 10, y: pt.y + 2, width: 20, height: 22)
            ctx.fill(Path(roundedRect: g, cornerRadius: 9), with: .color(Color(red: 0.75, green: 0.88, blue: 0.96)))
            ctx.stroke(Path(roundedRect: g, cornerRadius: 9), with: .color(Color(white: 0.95)), lineWidth: 2)
        } else {
            fill(ctx, CGRect(x: pt.x - 8, y: pt.y, width: 16, height: 13), cars[i % cars.count], corner: 4)
        }
    }
    ctx.fill(circle(hub, enclosed ? 14 : 9), with: .color(enclosed ? Color(white: 0.92) : Color(red: 1, green: 0.82, blue: 0.20)))
}

/// A surfer riding along a wave.
private func surfer(_ ctx: GraphicsContext, x: Double, y: Double, board: Color) {
    var b = Path()
    b.addEllipse(in: CGRect(x: x - 20, y: y - 3, width: 40, height: 6))
    ctx.fill(b, with: .color(board))
    fill(ctx, CGRect(x: x - 2, y: y - 22, width: 5, height: 19), Color(red: 0.15, green: 0.20, blue: 0.40), corner: 2)
    ctx.fill(circle(CGPoint(x: x, y: y - 27), 4.5), with: .color(Color(red: 0.80, green: 0.60, blue: 0.45)))
    var arms = Path()
    arms.move(to: CGPoint(x: x - 12, y: y - 18))
    arms.addLine(to: CGPoint(x: x + 13, y: y - 21))
    ctx.stroke(arms, with: .color(Color(red: 0.80, green: 0.60, blue: 0.45)), lineWidth: 2.5)
    var curl = Path()
    curl.move(to: CGPoint(x: x - 60, y: y + 3))
    curl.addQuadCurve(to: CGPoint(x: x + 30, y: y + 3), control: CGPoint(x: x - 20, y: y - 6))
    ctx.stroke(curl, with: .color(.white.opacity(0.85)), lineWidth: 3)
}

/// A storybook castle tower: a round stone tower capped by a pointed roof with a gold finial.
private func castleTower(_ ctx: GraphicsContext, x: Double, top: Double, bottom: Double, width w: Double, roofHeight: Double,
                         wall: Color, roof: Color, t: Double) {
    fill(ctx, CGRect(x: x - w / 2, y: top, width: w, height: bottom - top), wall)
    fill(ctx, CGRect(x: x + w * 0.15, y: top, width: w * 0.35, height: bottom - top), .black.opacity(0.07))
    fill(ctx, CGRect(x: x - w * 0.12, y: top + 14, width: w * 0.24, height: w * 0.4), Color(red: 0.25, green: 0.30, blue: 0.45), corner: w * 0.12)
    var cone = Path()
    cone.move(to: CGPoint(x: x - w / 2 - 4, y: top + 2))
    cone.addLine(to: CGPoint(x: x, y: top - roofHeight))
    cone.addLine(to: CGPoint(x: x + w / 2 + 4, y: top + 2))
    cone.closeSubpath()
    ctx.fill(cone, with: .color(roof))
    fill(ctx, CGRect(x: x - w / 2 - 4, y: top - 2, width: w + 8, height: 4), Color(red: 0.95, green: 0.78, blue: 0.25))
    fill(ctx, CGRect(x: x - 1, y: top - roofHeight - 12, width: 2, height: 12), Color(red: 0.95, green: 0.78, blue: 0.25))
    ctx.fill(circle(CGPoint(x: x, y: top - roofHeight - 13), 2.5), with: .color(Color(red: 0.98, green: 0.85, blue: 0.30)))
}

// MARK: Jersey Shore

/// Belmar, New Jersey: a wide sandy beach with red lifeguard stands, the open pavilion on the boardwalk,
/// surfers in the break and a kite flying overhead.
private func drawBelmar(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.14, green: 0.48, blue: 0.70))
    surfer(ctx, x: 560 + (t * 22).truncatingRemainder(dividingBy: 500), y: 318, board: Color(red: 1, green: 0.55, blue: 0.20))
    fill(ctx, CGRect(x: 0, y: 335, width: Stage.W, height: 70), Color(red: 0.95, green: 0.88, blue: 0.70))
    var foam = Path()
    for x in stride(from: 0.0, through: Stage.W, by: 10) {
        let pt = CGPoint(x: x, y: 336 + sin(x / 40 + t * 1.2) * 3)
        x == 0 ? foam.move(to: pt) : foam.addLine(to: pt)
    }
    ctx.stroke(foam, with: .color(.white.opacity(0.9)), lineWidth: 4)

    // The pavilion on the boardwalk: white posts under a green hipped roof
    let pav = CGRect(x: 470, y: 312, width: 170, height: 88)
    for x in stride(from: pav.minX + 6, through: pav.maxX - 6, by: 31.6) { fill(ctx, CGRect(x: x - 3, y: pav.minY, width: 6, height: pav.height), Color(white: 0.96)) }
    var roof = Path()
    roof.move(to: CGPoint(x: pav.minX - 14, y: pav.minY + 4))
    roof.addLine(to: CGPoint(x: pav.minX + 30, y: pav.minY - 34))
    roof.addLine(to: CGPoint(x: pav.maxX - 30, y: pav.minY - 34))
    roof.addLine(to: CGPoint(x: pav.maxX + 14, y: pav.minY + 4))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.25, green: 0.50, blue: 0.40)))
    fill(ctx, CGRect(x: pav.minX - 10, y: pav.minY, width: pav.width + 20, height: 8), Color(white: 0.96))
    fill(ctx, CGRect(x: pav.midX - 1, y: pav.minY - 56, width: 2, height: 22), Color(white: 0.4))
    for (k, c) in [Color(red: 0.75, green: 0.10, blue: 0.15), .white, Color(red: 0.75, green: 0.10, blue: 0.15)].enumerated() {
        fill(ctx, CGRect(x: pav.midX + 1, y: pav.minY - 56 + Double(k) * 4 + sin(t * 5 + Double(k)) * 0.8, width: 22, height: 4), c)
    }
    fill(ctx, CGRect(x: pav.midX + 1, y: pav.minY - 56, width: 9, height: 7), Color(red: 0.10, green: 0.20, blue: 0.50))

    lifeguardStand(ctx, x: 760, base: 392, label: "BELMAR", color: Color(red: 0.85, green: 0.15, blue: 0.15))
    lifeguardStand(ctx, x: 1120, base: 392, label: "BELMAR", color: Color(red: 0.85, green: 0.15, blue: 0.15))
    beachUmbrella(ctx, x: 900, Color(red: 0.20, green: 0.55, blue: 0.85))
    beachUmbrella(ctx, x: 1010, Color(red: 1.00, green: 0.75, blue: 0.15))

    // A diamond kite on a long string, its tail flicking in the breeze
    let kite = CGPoint(x: 960 + sin(t * 0.7) * 25, y: 120 + sin(t * 1.1) * 10)
    var string = Path()
    string.move(to: CGPoint(x: 1060, y: 380))
    string.addQuadCurve(to: CGPoint(x: kite.x, y: kite.y + 22), control: CGPoint(x: 1050, y: 200))
    ctx.stroke(string, with: .color(Color(white: 0.3)), lineWidth: 1)
    var k = Path()
    k.move(to: CGPoint(x: kite.x, y: kite.y - 26))
    k.addLine(to: CGPoint(x: kite.x + 18, y: kite.y))
    k.addLine(to: CGPoint(x: kite.x, y: kite.y + 22))
    k.addLine(to: CGPoint(x: kite.x - 18, y: kite.y))
    k.closeSubpath()
    ctx.fill(k, with: .linearGradient(Gradient(colors: [.red, .orange, .yellow]), startPoint: CGPoint(x: kite.x, y: kite.y - 26), endPoint: CGPoint(x: kite.x, y: kite.y + 22)))
    for i in 0..<5 {
        let p = CGPoint(x: kite.x + sin(t * 4 + Double(i)) * 6, y: kite.y + 30 + Double(i) * 10)
        ctx.fill(circle(p, 3), with: .color([Color.red, .blue, .yellow][i % 3]))
    }

    boardwalk(ctx)
    sign(ctx, "BELMAR BEACH", at: CGRect(x: 640, y: 358, width: 110, height: 26), bg: Color(red: 0.15, green: 0.40, blue: 0.75))
    gulls(ctx, t: t)
}

/// Long Branch, New Jersey: Pier Village's apartment blocks with balconies and shop awnings,
/// the ocean beyond the beach, and the promenade out front.
private func drawLongBranch(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.16, green: 0.48, blue: 0.68))
    fill(ctx, CGRect(x: 0, y: 345, width: Stage.W, height: 60), Color(red: 0.95, green: 0.88, blue: 0.70))
    // A fishing boat crossing the horizon
    let bx = 1200 - (t * 14).truncatingRemainder(dividingBy: 900)
    fill(ctx, CGRect(x: bx, y: 300, width: 46, height: 9), .white, corner: 3)
    fill(ctx, CGRect(x: bx + 12, y: 290, width: 16, height: 10), Color(white: 0.9), corner: 2)
    fill(ctx, CGRect(x: bx + 30, y: 276, width: 2, height: 24), Color(white: 0.5))

    // Pier Village
    let walls = [Color(red: 0.95, green: 0.90, blue: 0.78), Color(red: 0.92, green: 0.82, blue: 0.68), Color(red: 0.97, green: 0.93, blue: 0.84)]
    let awning = Color(red: 0.18, green: 0.45, blue: 0.35)
    for (i, b) in [(x: 640.0, w: 170.0, top: 200.0), (x: 815.0, w: 190.0, top: 170.0), (x: 1010.0, w: 190.0, top: 190.0)].enumerated() {
        fill(ctx, CGRect(x: b.x, y: b.top, width: b.w, height: 405 - b.top), walls[i])
        fill(ctx, CGRect(x: b.x - 4, y: b.top - 8, width: b.w + 8, height: 10), Color(red: 0.55, green: 0.38, blue: 0.30), corner: 2)
        for y in stride(from: b.top + 18, to: 330, by: 32) {
            for x in stride(from: b.x + 12, to: b.x + b.w - 20, by: 30) {
                fill(ctx, CGRect(x: x, y: y, width: 16, height: 20), Color(red: 0.55, green: 0.70, blue: 0.82))
                fill(ctx, CGRect(x: x - 3, y: y + 18, width: 22, height: 3), Color(white: 0.30))
                for r in 0..<4 { fill(ctx, CGRect(x: x - 2 + Double(r) * 6.5, y: y + 12, width: 1.2, height: 7), Color(white: 0.30)) }
            }
        }
        for x in stride(from: b.x + 6, to: b.x + b.w - 30, by: 46) {
            fill(ctx, CGRect(x: x, y: 342, width: 40, height: 14), awning, corner: 2)
            fill(ctx, CGRect(x: x + 4, y: 358, width: 32, height: 40), Color(red: 0.30, green: 0.28, blue: 0.26).opacity(0.85))
        }
        fill(ctx, CGRect(x: b.x + b.w / 2 - 1, y: b.top - 34, width: 2, height: 26), Color(white: 0.5))
        for (k, c) in [Color(red: 0.75, green: 0.10, blue: 0.15), .white, Color(red: 0.75, green: 0.10, blue: 0.15)].enumerated() {
            fill(ctx, CGRect(x: b.x + b.w / 2 + 1, y: b.top - 34 + Double(k) * 4 + sin(t * 5 + Double(k) + Double(i)) * 0.8, width: 20, height: 4), c)
        }
        fill(ctx, CGRect(x: b.x + b.w / 2 + 1, y: b.top - 34, width: 8, height: 7), Color(red: 0.10, green: 0.20, blue: 0.50))
    }
    lifeguardStand(ctx, x: 520, base: 395, label: "L.B. PATROL", color: Color(red: 0.10, green: 0.35, blue: 0.70))
    // The promenade: pale pavers, benches and lamp posts
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.84, green: 0.82, blue: 0.78))
    for x in stride(from: 0.0, to: Stage.W, by: 40) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.74, green: 0.72, blue: 0.68)) }
    fill(ctx, CGRect(x: 0, y: 398, width: Stage.W, height: 3), Color(white: 0.35))
    for x in stride(from: 0.0, to: Stage.W, by: 40) { fill(ctx, CGRect(x: x, y: 398, width: 3, height: 12), Color(white: 0.35)) }
    for x in [600.0, 900, 1170] {
        fill(ctx, CGRect(x: x - 2, y: 330, width: 4, height: 80), Color(white: 0.20))
        ctx.fill(circle(CGPoint(x: x, y: 326), 7), with: .color(Color(red: 1, green: 0.96, blue: 0.80)))
    }
    sign(ctx, "LONG BRANCH · PIER VILLAGE", at: CGRect(x: 690, y: 362, width: 150, height: 26), bg: awning, size: 9)
    gulls(ctx, t: t)
}

/// Atlantic City at dusk: casino towers lit up along the boardwalk, the Steel Pier and its Ferris wheel
/// out over the water, and a rolling chair being pushed along the boards.
private func drawAtlanticCity(_ ctx: GraphicsContext, t: Double) {
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: 405)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.14, green: 0.12, blue: 0.38), Color(red: 0.55, green: 0.30, blue: 0.55),
                                                     Color(red: 0.98, green: 0.60, blue: 0.35)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: 330)))
    for i in 0..<20 {
        let p = CGPoint(x: Double((i * 97 + 40) % 1200), y: 50 + Double((i * 53) % 100))
        ctx.fill(circle(p, 1.4), with: .color(.white.opacity(0.4 + 0.35 * sin(t * 2 + Double(i)))))
    }
    sea(ctx, t: t, top: 320, color: Color(red: 0.12, green: 0.25, blue: 0.45))

    let gold = Color(red: 1.00, green: 0.82, blue: 0.20)
    let pink = Color(red: 1.00, green: 0.30, blue: 0.65)
    let cyan = Color(red: 0.30, green: 0.95, blue: 1.00)

    // The Steel Pier running out to sea, and its Ferris wheel with the lights chasing round the rim
    fill(ctx, CGRect(x: 440, y: 316, width: 300, height: 10), Color(red: 0.40, green: 0.30, blue: 0.25))
    for x in stride(from: 446.0, to: 740, by: 24) { fill(ctx, CGRect(x: x, y: 326, width: 4, height: 30), Color(red: 0.30, green: 0.22, blue: 0.18)) }
    var wheel = ctx
    wheel.clip(to: Path(CGRect(x: 0, y: 0, width: Stage.W, height: 318)))
    ferrisWheel(wheel, hub: CGPoint(x: 600, y: 200), radius: 100, rim: pink, count: 14, t: t)
    for i in 0..<28 {
        let a = Double(i) / 28 * 2 * .pi
        let hue = (Double(i) / 28 + t * 0.2).truncatingRemainder(dividingBy: 1)
        ctx.fill(circle(CGPoint(x: 600 + cos(a) * 100, y: 200 + sin(a) * 100), 2.5), with: .color(Color(hue: hue, saturation: 0.8, brightness: 1)))
    }
    fill(ctx, CGRect(x: 650, y: 290, width: 80, height: 22), Color(red: 0.12, green: 0.08, blue: 0.20), corner: 4)
    ctx.draw(Text("STEEL PIER").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(gold), at: CGPoint(x: 690, y: 301))

    // Casino towers
    let towers: [(x: Double, w: Double, top: Double, wall: Color, name: String, neon: Color)] = [
        (770, 130, 120, Color(red: 0.30, green: 0.18, blue: 0.40), "CASINO", gold),
        (905, 140, 70, Color(red: 0.22, green: 0.20, blue: 0.36), "RESORT", cyan),
        (1050, 150, 140, Color(red: 0.36, green: 0.16, blue: 0.32), "HOTEL", pink),
    ]
    for (i, f) in towers.enumerated() {
        fill(ctx, CGRect(x: f.x, y: f.top, width: f.w, height: 405 - f.top), f.wall)
        for (r, y) in stride(from: f.top + 40, to: 340, by: 16).enumerated() {
            for (c, x) in stride(from: f.x + 10, to: f.x + f.w - 12, by: 16).enumerated() where (r * 2 + c + i) % 3 != 0 {
                fill(ctx, CGRect(x: x, y: y, width: 9, height: 8), gold.opacity(0.7))
            }
        }
        let board = CGRect(x: f.x + 12, y: f.top + 8, width: f.w - 24, height: 24)
        fill(ctx, board, Color(red: 0.08, green: 0.05, blue: 0.14), corner: 5)
        ctx.stroke(Path(roundedRect: board, cornerRadius: 5), with: .color(f.neon), lineWidth: 2)
        ctx.draw(Text(f.name).font(.system(size: 15, weight: .black, design: .rounded)).foregroundStyle(f.neon), at: CGPoint(x: board.midX, y: board.midY))
        // Marquee bulbs chasing along the entrance canopy
        fill(ctx, CGRect(x: f.x + 10, y: 350, width: f.w - 20, height: 14), Color(red: 0.12, green: 0.08, blue: 0.20), corner: 3)
        for (k, x) in stride(from: f.x + 14, through: f.x + f.w - 14, by: 10).enumerated() {
            ctx.fill(circle(CGPoint(x: x, y: 357), 2.5), with: .color((k + Int(t * 6)) % 3 == 0 ? .white : gold.opacity(0.5)))
        }
    }
    // The saltwater taffy shop
    fill(ctx, CGRect(x: 0, y: 320, width: 120, height: 85), Color(red: 0.98, green: 0.88, blue: 0.92))
    for k in 0..<8 { fill(ctx, CGRect(x: Double(k) * 15, y: 320, width: 15, height: 16), k % 2 == 0 ? pink : .white) }
    ctx.draw(Text("SALT WATER TAFFY").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.45)),
             at: CGPoint(x: 60, y: 348))
    fill(ctx, CGRect(x: 14, y: 360, width: 92, height: 36), Color(red: 0.35, green: 0.25, blue: 0.28), corner: 2)

    boardwalk(ctx)
    // A rolling chair: a wicker two-seater with a canopy, pushed along the boards
    let cx = (t * 35).truncatingRemainder(dividingBy: Stage.W + 200) - 100
    let wicker = Color(red: 0.80, green: 0.62, blue: 0.35)
    fill(ctx, CGRect(x: cx, y: 410, width: 44, height: 24), wicker, corner: 5)
    var hood = Path()
    hood.move(to: CGPoint(x: cx + 2, y: 412))
    hood.addQuadCurve(to: CGPoint(x: cx + 36, y: 392), control: CGPoint(x: cx + 4, y: 388))
    hood.addLine(to: CGPoint(x: cx + 40, y: 412))
    hood.closeSubpath()
    ctx.fill(hood, with: .color(wicker.opacity(0.9)))
    for wx in [cx + 8, cx + 36] { ctx.stroke(circle(CGPoint(x: wx, y: 438), 6), with: .color(Color(white: 0.15)), lineWidth: 2) }
    fill(ctx, CGRect(x: cx + 44, y: 414, width: 14, height: 2), Color(white: 0.3))
    fill(ctx, CGRect(x: cx + 58, y: 398, width: 7, height: 34), Color(red: 0.15, green: 0.20, blue: 0.45), corner: 2)
    ctx.fill(circle(CGPoint(x: cx + 61.5, y: 392), 5), with: .color(Color(red: 0.85, green: 0.66, blue: 0.52)))
    sign(ctx, "ATLANTIC CITY BOARDWALK", at: CGRect(x: 150, y: 345, width: 150, height: 26), bg: Color(red: 0.12, green: 0.25, blue: 0.55), size: 9)
}

// MARK: Theme parks

/// Disney World: the castle in Orlando, white stone with blue spires, the monorail gliding past behind it,
/// flower beds in front and a balloon seller on the red pavement.
private func drawDisneyWorld(_ ctx: GraphicsContext, t: Double) {
    // Trees around the park, and the monorail beam
    for x in stride(from: 430.0, to: Stage.W, by: 70) {
        ctx.fill(circle(CGPoint(x: x, y: 330 + (x * 7).truncatingRemainder(dividingBy: 20)), 46), with: .color(Color(red: 0.20, green: 0.50, blue: 0.26)))
    }
    fill(ctx, CGRect(x: 0, y: 252, width: Stage.W, height: 8), Color(white: 0.85))
    for x in stride(from: 60.0, to: Stage.W, by: 240) { fill(ctx, CGRect(x: x, y: 260, width: 10, height: 145), Color(white: 0.85)) }
    let mx = (t * 70).truncatingRemainder(dividingBy: Stage.W + 500) - 400
    for k in 0..<4 {
        let x = mx + Double(k) * 82
        fill(ctx, CGRect(x: x, y: 224, width: 78, height: 28), .white, corner: k == 3 ? 14 : 5)
        fill(ctx, CGRect(x: x, y: 238, width: 78, height: 5), Color(red: 0.10, green: 0.45, blue: 0.85))
        for w in 0..<4 { fill(ctx, CGRect(x: x + 6 + Double(w) * 18, y: 228, width: 12, height: 8), Color(red: 0.20, green: 0.25, blue: 0.35)) }
    }

    // The castle
    let wall = Color(red: 0.93, green: 0.92, blue: 0.90)
    let roof = Color(red: 0.18, green: 0.36, blue: 0.78)
    let cx = 840.0
    fill(ctx, CGRect(x: cx - 170, y: 300, width: 340, height: 105), wall)
    for x in stride(from: cx - 170, to: cx + 170, by: 18) { fill(ctx, CGRect(x: x, y: 292, width: 10, height: 10), wall) }
    for (dx, top, w, rh) in [(-150.0, 250.0, 34.0, 50.0), (150.0, 250.0, 34.0, 50.0), (-100.0, 200.0, 40.0, 64.0), (100.0, 200.0, 40.0, 64.0),
                              (-52.0, 160.0, 34.0, 58.0), (52.0, 160.0, 34.0, 58.0)] {
        castleTower(ctx, x: cx + dx, top: top, bottom: 300, width: w, roofHeight: rh, wall: wall, roof: roof, t: t)
    }
    castleTower(ctx, x: cx, top: 150, bottom: 300, width: 64, roofHeight: 110, wall: wall, roof: roof, t: t)
    // Gold trim and the archway
    fill(ctx, CGRect(x: cx - 170, y: 300, width: 340, height: 4), Color(red: 0.95, green: 0.78, blue: 0.25))
    var arch = Path()
    arch.addRoundedRect(in: CGRect(x: cx - 26, y: 340, width: 52, height: 70), cornerSize: CGSize(width: 26, height: 26))
    ctx.fill(arch, with: .color(Color(red: 0.30, green: 0.26, blue: 0.36)))
    ctx.stroke(arch, with: .color(Color(red: 0.95, green: 0.78, blue: 0.25)), lineWidth: 3)
    // Flower beds
    fill(ctx, CGRect(x: 430, y: 390, width: Stage.W - 430, height: 16), Color(red: 0.30, green: 0.62, blue: 0.30))
    for x in stride(from: 436.0, to: Stage.W, by: 9) {
        ctx.fill(circle(CGPoint(x: x, y: 392 + (x * 3).truncatingRemainder(dividingBy: 8)), 3.5),
                 with: .color([Color.red, .yellow, .pink, .orange, .purple][Int(x / 9) % 5]))
    }
    // Red Main Street pavement
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.72, green: 0.42, blue: 0.36))
    for x in stride(from: 0.0, to: Stage.W, by: 50) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.62, green: 0.34, blue: 0.30)) }
    // The balloon seller's bunch
    let bx = 1130.0
    for (i, c) in [Color.red, .yellow, .blue, .green, .pink, .orange, .purple].enumerated() {
        let a = Double(i) / 7 * 2 * .pi
        let p = CGPoint(x: bx + cos(a) * 22 + sin(t + Double(i)) * 2, y: 250 + sin(a) * 18)
        var str = Path()
        str.move(to: CGPoint(x: bx, y: 360))
        str.addLine(to: CGPoint(x: p.x, y: p.y + 14))
        ctx.stroke(str, with: .color(Color(white: 0.4)), lineWidth: 0.8)
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 13, y: p.y - 16, width: 26, height: 30)), with: .color(c))
        ctx.fill(circle(CGPoint(x: p.x - 4, y: p.y - 7), 4), with: .color(.white.opacity(0.5)))
    }
    fill(ctx, CGRect(x: bx - 2, y: 360, width: 4, height: 50), Color(white: 0.4))
    sign(ctx, "DISNEY WORLD", at: CGRect(x: 520, y: 350, width: 110, height: 26), bg: roof)
    // A sprinkle of pixie dust over the spires
    for i in 0..<6 {
        let g = max(0, sin(t * 2 + Double(i) * 1.3))
        drawSparkle(ctx, at: CGPoint(x: cx - 120 + Double(i) * 48, y: 120 + sin(Double(i) * 2.1) * 40), size: 9 * g, alpha: g, tint: Color(red: 1, green: 0.9, blue: 0.5))
    }
}

/// Disneyland: the little pink castle with turquoise spires behind its moat and drawbridge,
/// and the snowy Matterhorn with a bobsled racing down it.
private func drawDisneyland(_ ctx: GraphicsContext, t: Double) {
    // The Matterhorn
    var peak = Path()
    peak.move(to: CGPoint(x: 900, y: 330))
    peak.addLine(to: CGPoint(x: 1010, y: 150))
    peak.addLine(to: CGPoint(x: 1050, y: 90))
    peak.addLine(to: CGPoint(x: 1080, y: 160))
    peak.addLine(to: CGPoint(x: 1200, y: 330))
    peak.closeSubpath()
    ctx.fill(peak, with: .color(Color(red: 0.55, green: 0.55, blue: 0.58)))
    var snow = Path()
    snow.move(to: CGPoint(x: 1010, y: 150))
    snow.addLine(to: CGPoint(x: 1050, y: 90))
    snow.addLine(to: CGPoint(x: 1080, y: 160))
    snow.addLine(to: CGPoint(x: 1062, y: 150))
    snow.addLine(to: CGPoint(x: 1048, y: 170))
    snow.addLine(to: CGPoint(x: 1030, y: 148))
    snow.closeSubpath()
    ctx.fill(snow, with: .color(.white))
    // A bobsled zigzagging down the mountain
    let u = (t * 0.25).truncatingRemainder(dividingBy: 1)
    let zig = sin(u * .pi * 4) * 40
    let sled = CGPoint(x: 1050 + zig + u * 60, y: 160 + u * 160)
    fill(ctx, CGRect(x: sled.x - 12, y: sled.y - 6, width: 24, height: 10), Color(red: 0.90, green: 0.20, blue: 0.20), corner: 4)
    // Trees
    for x in stride(from: 430.0, to: 920, by: 60) {
        ctx.fill(circle(CGPoint(x: x, y: 330 + (x * 7).truncatingRemainder(dividingBy: 20)), 40), with: .color(Color(red: 0.22, green: 0.52, blue: 0.28)))
    }

    // Sleeping-beauty-style castle: pink walls, turquoise spires, gold trim
    let wall = Color(red: 0.98, green: 0.78, blue: 0.82)
    let roof = Color(red: 0.20, green: 0.58, blue: 0.75)
    let cx = 720.0
    fill(ctx, CGRect(x: cx - 140, y: 290, width: 280, height: 90), Color(red: 0.75, green: 0.72, blue: 0.68))
    for y in stride(from: 296.0, to: 380, by: 14) { fill(ctx, CGRect(x: cx - 140, y: y, width: 280, height: 1.5), Color(red: 0.62, green: 0.60, blue: 0.56)) }
    for (dx, top, w, rh) in [(-120.0, 220.0, 30.0, 56.0), (120.0, 220.0, 30.0, 56.0), (-70.0, 190.0, 38.0, 70.0), (70.0, 200.0, 34.0, 64.0)] {
        castleTower(ctx, x: cx + dx, top: top, bottom: 292, width: w, roofHeight: rh, wall: wall, roof: roof, t: t)
    }
    fill(ctx, CGRect(x: cx - 46, y: 220, width: 92, height: 72), wall)
    castleTower(ctx, x: cx, top: 150, bottom: 292, width: 48, roofHeight: 90, wall: wall, roof: roof, t: t)
    var arch = Path()
    arch.addRoundedRect(in: CGRect(x: cx - 22, y: 320, width: 44, height: 60), cornerSize: CGSize(width: 22, height: 22))
    ctx.fill(arch, with: .color(Color(red: 0.30, green: 0.26, blue: 0.36)))
    // The moat and the drawbridge
    fill(ctx, CGRect(x: 430, y: 380, width: Stage.W - 430, height: 25), Color(red: 0.25, green: 0.55, blue: 0.70))
    for k in 0..<10 {
        let x = 450 + Double(k) * 75 + sin(t + Double(k)) * 6
        fill(ctx, CGRect(x: x, y: 390, width: 18, height: 2), .white.opacity(0.5))
    }
    fill(ctx, CGRect(x: cx - 28, y: 378, width: 56, height: 28), Color(red: 0.55, green: 0.40, blue: 0.28))
    for x in stride(from: cx - 28, to: cx + 28, by: 8) { fill(ctx, CGRect(x: x, y: 378, width: 1, height: 28), Color(red: 0.40, green: 0.28, blue: 0.20)) }
    // A pair of swans in the moat
    for (i, sx) in [560.0, 900].enumerated() {
        let x = sx + sin(t * 0.4 + Double(i) * 2) * 30
        ctx.fill(Path(ellipseIn: CGRect(x: x - 10, y: 386, width: 20, height: 9)), with: .color(.white))
        var neck = Path()
        neck.move(to: CGPoint(x: x + 6, y: 389))
        neck.addQuadCurve(to: CGPoint(x: x + 8, y: 375), control: CGPoint(x: x + 14, y: 382))
        ctx.stroke(neck, with: .color(.white), lineWidth: 2.5)
        fill(ctx, CGRect(x: x + 8, y: 374, width: 4, height: 2), .orange)
    }
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.80, green: 0.66, blue: 0.56))
    for x in stride(from: 0.0, to: Stage.W, by: 50) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.70, green: 0.56, blue: 0.46)) }
    sign(ctx, "DISNEYLAND", at: CGRect(x: 960, y: 352, width: 100, height: 26), bg: Color(red: 0.85, green: 0.35, blue: 0.55))
    for i in 0..<5 {
        let g = max(0, sin(t * 2 + Double(i) * 1.5))
        drawSparkle(ctx, at: CGPoint(x: cx - 100 + Double(i) * 50, y: 110 + sin(Double(i) * 2.3) * 30), size: 8 * g, alpha: g, tint: Color(red: 1, green: 0.85, blue: 0.95))
    }
}

/// Sesame Place: a brownstone stoop with its famous street sign, a twisty blue-and-yellow coaster,
/// and the water-slide tower with three tube slides spiralling down into the splash pool.
private func drawSesamePlace(_ ctx: GraphicsContext, t: Double) {
    grass(ctx)
    // The coaster
    func coasterY(_ x: Double) -> Double { 300 - 70 * pow(sin((x - 440) / 300 * .pi * 1.4), 2) }
    for x in stride(from: 450.0, through: 740, by: 20) {
        fill(ctx, CGRect(x: x - 1.5, y: coasterY(x), width: 3, height: 405 - coasterY(x)), Color(red: 1, green: 0.82, blue: 0.15))
    }
    var rail = Path()
    for x in stride(from: 440.0, through: 750, by: 5) {
        let pt = CGPoint(x: x, y: coasterY(x))
        x == 440 ? rail.move(to: pt) : rail.addLine(to: pt)
    }
    ctx.stroke(rail, with: .color(Color(red: 0.15, green: 0.45, blue: 0.85)), lineWidth: 5)
    let carX = 450 + (t * 55).truncatingRemainder(dividingBy: 290)
    for k in 0..<3 {
        let x = carX - Double(k) * 15
        guard x > 444 else { continue }
        fill(ctx, CGRect(x: x - 7, y: coasterY(x) - 11, width: 13, height: 9), [Color.red, .green, .orange][k], corner: 2)
    }

    // The brownstone and its stoop
    let brown = Color(red: 0.58, green: 0.36, blue: 0.26)
    fill(ctx, CGRect(x: 770, y: 200, width: 160, height: 205), brown)
    fill(ctx, CGRect(x: 764, y: 192, width: 172, height: 10), Color(red: 0.42, green: 0.25, blue: 0.18))
    for y in [220.0, 270] {
        for x in [786.0, 830, 874] {
            fill(ctx, CGRect(x: x, y: y, width: 28, height: 36), Color(red: 0.70, green: 0.85, blue: 0.95))
            fill(ctx, CGRect(x: x + 13, y: y, width: 2, height: 36), .white)
            fill(ctx, CGRect(x: x - 3, y: y + 34, width: 34, height: 4), Color(red: 0.88, green: 0.80, blue: 0.70))
        }
    }
    fill(ctx, CGRect(x: 830, y: 318, width: 32, height: 46), Color(red: 0.25, green: 0.45, blue: 0.30), corner: 3)
    ctx.draw(Text("123").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 846, y: 312))
    for k in 0..<5 {
        fill(ctx, CGRect(x: 818 - Double(k) * 4, y: 364 + Double(k) * 8.4, width: 56 + Double(k) * 8, height: 8.4), Color(red: 0.70, green: 0.50, blue: 0.40))
    }
    // The street sign on its pole
    fill(ctx, CGRect(x: 752, y: 290, width: 4, height: 120), Color(red: 0.20, green: 0.40, blue: 0.25))
    fill(ctx, CGRect(x: 700, y: 284, width: 108, height: 16), Color(red: 0.10, green: 0.50, blue: 0.25), corner: 2)
    ctx.draw(Text("SESAME ST").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 754, y: 292))
    fill(ctx, CGRect(x: 742, y: 270, width: 24, height: 14), Color(red: 0.10, green: 0.50, blue: 0.25), corner: 2)
    ctx.draw(Text("123").font(.system(size: 8, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 754, y: 277))

    // The water-slide tower
    fill(ctx, CGRect(x: 1050, y: 170, width: 70, height: 12), Color(red: 1, green: 0.82, blue: 0.15), corner: 3)
    for x in [1054.0, 1110] { fill(ctx, CGRect(x: x, y: 182, width: 6, height: 223), Color(white: 0.9)) }
    var top = Path()
    top.move(to: CGPoint(x: 1044, y: 172))
    top.addLine(to: CGPoint(x: 1085, y: 140))
    top.addLine(to: CGPoint(x: 1126, y: 172))
    top.closeSubpath()
    ctx.fill(top, with: .color(Color(red: 0.90, green: 0.20, blue: 0.25)))
    for (i, c) in [Color(red: 0.15, green: 0.45, blue: 0.90), Color(red: 1, green: 0.75, blue: 0.10), Color(red: 0.25, green: 0.75, blue: 0.35)].enumerated() {
        var slide = Path()
        let dir = i % 2 == 0 ? -1.0 : 1.0
        slide.move(to: CGPoint(x: 1085, y: 182))
        slide.addCurve(to: CGPoint(x: 1085 + dir * (40 + Double(i) * 20), y: 300),
                       control1: CGPoint(x: 1085 + dir * 90, y: 200 + Double(i) * 10), control2: CGPoint(x: 1085 - dir * 70, y: 260))
        slide.addQuadCurve(to: CGPoint(x: 1000 + Double(i) * 70, y: 390), control: CGPoint(x: 1085 + dir * 110, y: 360))
        ctx.stroke(slide, with: .color(c), style: StrokeStyle(lineWidth: 10, lineCap: .round))
    }
    // The splash pool
    ctx.fill(Path(ellipseIn: CGRect(x: 960, y: 380, width: 240, height: 28)), with: .color(Color(red: 0.35, green: 0.75, blue: 0.95)))
    for i in 0..<6 {
        let s = abs(sin(t * 4 + Double(i)))
        ctx.fill(circle(CGPoint(x: 990 + Double(i) * 34, y: 386 - s * 8), 4), with: .color(.white.opacity(0.8)))
    }
    // Sidewalk
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.80, green: 0.80, blue: 0.80))
    for x in stride(from: 0.0, to: Stage.W, by: 44) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.70, green: 0.70, blue: 0.70)) }
    sign(ctx, "SESAME PLACE", at: CGRect(x: 560, y: 352, width: 110, height: 26), bg: Color(red: 0.10, green: 0.50, blue: 0.25))
}

// MARK: Islands and beaches

/// Cozumel: turquoise Caribbean, two cruise ships at the pier, thatched palapas on the sand,
/// and the big colourful COZUMEL letters.
private func drawCozumel(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 280, color: Color(red: 0.15, green: 0.78, blue: 0.80))
    fill(ctx, CGRect(x: 0, y: 280, width: Stage.W, height: 24), Color(red: 0.08, green: 0.48, blue: 0.75))
    cruiseShip(ctx, x: 470, waterline: 300, width: 300, hull: .white, t: t) { ctx, r in
        fill(ctx, r, Color(red: 0.10, green: 0.25, blue: 0.60), corner: 3)
        fill(ctx, CGRect(x: r.minX, y: r.minY + 7, width: r.width, height: 5), Color(red: 1, green: 0.82, blue: 0.20))
    }
    cruiseShip(ctx, x: 820, waterline: 316, width: 260, hull: Color(red: 0.12, green: 0.15, blue: 0.30), t: t + 2) { ctx, r in
        fill(ctx, r, Color(red: 0.85, green: 0.15, blue: 0.20), corner: 3)
    }
    fill(ctx, CGRect(x: 760, y: 318, width: 340, height: 7), Color(white: 0.85))
    sand(ctx, Color(red: 0.98, green: 0.94, blue: 0.84))
    // Thatched palapas
    for x in [520.0, 1060] {
        fill(ctx, CGRect(x: x - 3, y: 360, width: 6, height: 50), Color(red: 0.50, green: 0.35, blue: 0.20))
        var thatch = Path()
        thatch.move(to: CGPoint(x: x - 54, y: 372))
        thatch.addLine(to: CGPoint(x: x, y: 330))
        thatch.addLine(to: CGPoint(x: x + 54, y: 372))
        thatch.closeSubpath()
        ctx.fill(thatch, with: .color(Color(red: 0.82, green: 0.68, blue: 0.40)))
        for k in 0..<9 { fill(ctx, CGRect(x: x - 50 + Double(k) * 12, y: 368, width: 3, height: 8), Color(red: 0.70, green: 0.55, blue: 0.30)) }
    }
    // COZUMEL in big painted letters
    let tints: [Color] = [Color(red: 0.95, green: 0.25, blue: 0.45), Color(red: 1, green: 0.70, blue: 0.10), Color(red: 0.15, green: 0.70, blue: 0.40),
                          Color(red: 0.15, green: 0.50, blue: 0.90), Color(red: 0.60, green: 0.30, blue: 0.80), Color(red: 1, green: 0.45, blue: 0.15)]
    for (i, ch) in "COZUMEL".enumerated() {
        let p = CGPoint(x: 640 + Double(i) * 44, y: 378)
        ctx.draw(Text(String(ch)).font(.system(size: 44, weight: .black, design: .rounded)).foregroundStyle(Color(white: 0.2).opacity(0.3)), at: CGPoint(x: p.x + 2, y: p.y + 3))
        ctx.draw(Text(String(ch)).font(.system(size: 44, weight: .black, design: .rounded)).foregroundStyle(tints[i % tints.count]), at: p)
    }
    // Mexico's flag
    fill(ctx, CGRect(x: 1148, y: 250, width: 3, height: 160), Color(white: 0.85))
    for (k, c) in [Color(red: 0.0, green: 0.41, blue: 0.28), .white, Color(red: 0.81, green: 0.07, blue: 0.15)].enumerated() {
        fill(ctx, CGRect(x: 1151 + Double(k) * 14, y: 250 + sin(t * 5 + Double(k)) * 1.5, width: 14, height: 26), c)
    }
    ctx.fill(circle(CGPoint(x: 1172, y: 263 + sin(t * 5 + 1) * 1.5), 3), with: .color(Color(red: 0.55, green: 0.40, blue: 0.20)))
    palm(ctx, x: 30, base: 410, height: 165, t: t)
    palm(ctx, x: 1110, base: 410, height: 140, t: t + 1)
    gulls(ctx, t: t)
}

/// Waikiki: Diamond Head rising over the bay, surfers on the long rolling waves, an outrigger canoe,
/// the pink hotel on the sand, and surfboards stuck upright in the beach.
private func drawWaikiki(_ ctx: GraphicsContext, t: Double) {
    // Diamond Head: a long slope up from the left, a jagged crater rim, a steep drop to the sea
    var head = Path()
    head.move(to: CGPoint(x: 700, y: 300))
    head.addQuadCurve(to: CGPoint(x: 980, y: 175), control: CGPoint(x: 860, y: 200))
    head.addLine(to: CGPoint(x: 1010, y: 190))
    head.addLine(to: CGPoint(x: 1040, y: 160))
    head.addLine(to: CGPoint(x: 1075, y: 185))
    head.addLine(to: CGPoint(x: 1100, y: 170))
    head.addQuadCurve(to: CGPoint(x: 1210, y: 300), control: CGPoint(x: 1170, y: 210))
    head.closeSubpath()
    ctx.fill(head, with: .linearGradient(Gradient(colors: [Color(red: 0.55, green: 0.55, blue: 0.35), Color(red: 0.35, green: 0.50, blue: 0.28)]),
                                         startPoint: CGPoint(x: 0, y: 160), endPoint: CGPoint(x: 0, y: 300)))
    var ridges = ctx
    ridges.clip(to: head)
    for x in stride(from: 760.0, to: 1200, by: 34) {
        var r = Path()
        r.move(to: CGPoint(x: x, y: 160))
        r.addLine(to: CGPoint(x: x - 30, y: 300))
        ridges.stroke(r, with: .color(.black.opacity(0.12)), lineWidth: 3)
    }
    // A faint rainbow over the mountain
    var bow = Path()
    bow.addArc(center: CGPoint(x: 1000, y: 300), radius: 210, startAngle: .degrees(200), endAngle: .degrees(330), clockwise: false)
    for (k, c) in [Color.red, .orange, .yellow, .green, .blue, .purple].enumerated() {
        ctx.stroke(bow.offsetBy(dx: 0, dy: Double(k) * 4), with: .color(c.opacity(0.16)), lineWidth: 4)
    }
    // The pink hotel
    let pinkWall = Color(red: 0.96, green: 0.62, blue: 0.70)
    fill(ctx, CGRect(x: 470, y: 230, width: 210, height: 72), pinkWall)
    fill(ctx, CGRect(x: 545, y: 190, width: 60, height: 112), pinkWall)
    var dome = Path()
    dome.move(to: CGPoint(x: 545, y: 192))
    dome.addQuadCurve(to: CGPoint(x: 605, y: 192), control: CGPoint(x: 575, y: 160))
    ctx.fill(dome, with: .color(Color(red: 0.90, green: 0.50, blue: 0.60)))
    for x in stride(from: 478.0, to: 676, by: 18) {
        var a = Path()
        a.addRoundedRect(in: CGRect(x: x, y: 262, width: 10, height: 26), cornerSize: CGSize(width: 5, height: 5))
        ctx.fill(a, with: .color(Color(red: 0.55, green: 0.30, blue: 0.38)))
    }
    for y in [205.0, 232] { for x in [556.0, 578] { fill(ctx, CGRect(x: x, y: y, width: 12, height: 16), Color(red: 0.55, green: 0.30, blue: 0.38), corner: 5) } }

    sea(ctx, t: t, top: 300, color: Color(red: 0.10, green: 0.58, blue: 0.78))
    surfer(ctx, x: 520 + (t * 30).truncatingRemainder(dividingBy: 600), y: 330, board: Color(red: 1, green: 0.85, blue: 0.20))
    surfer(ctx, x: 1150 - (t * 24).truncatingRemainder(dividingBy: 520), y: 352, board: Color(red: 0.95, green: 0.35, blue: 0.45))
    // An outrigger canoe paddling across
    let ox = (t * 16).truncatingRemainder(dividingBy: 900) + 300
    fill(ctx, CGRect(x: ox, y: 312, width: 80, height: 8), Color(red: 0.45, green: 0.25, blue: 0.15), corner: 4)
    fill(ctx, CGRect(x: ox + 10, y: 300, width: 60, height: 4), Color(red: 0.45, green: 0.25, blue: 0.15), corner: 2)
    for k in 0..<4 {
        let x = ox + 14 + Double(k) * 16
        ctx.fill(circle(CGPoint(x: x, y: 304), 3.5), with: .color(Color(red: 0.55, green: 0.38, blue: 0.28)))
        var paddle = Path()
        paddle.move(to: CGPoint(x: x, y: 306))
        paddle.addLine(to: CGPoint(x: x - 6 + sin(t * 4 + Double(k)) * 4, y: 322))
        ctx.stroke(paddle, with: .color(Color(white: 0.2)), lineWidth: 1.5)
    }
    sand(ctx, Color(red: 0.96, green: 0.90, blue: 0.74))
    // Surfboards stuck upright in the sand
    for (i, c) in [Color(red: 0.20, green: 0.60, blue: 0.90), Color(red: 1, green: 0.55, blue: 0.20), Color(red: 0.30, green: 0.80, blue: 0.50)].enumerated() {
        let x = 860 + Double(i) * 30
        ctx.fill(Path(ellipseIn: CGRect(x: x, y: 330, width: 22, height: 80)), with: .color(c))
        fill(ctx, CGRect(x: x + 10, y: 336, width: 2, height: 68), .white.opacity(0.7))
    }
    palm(ctx, x: 40, base: 410, height: 175, t: t)
    palm(ctx, x: 680, base: 410, height: 160, t: t + 1)
    palm(ctx, x: 1140, base: 410, height: 150, t: t + 2)
    sign(ctx, "WAIKIKI BEACH", at: CGRect(x: 980, y: 352, width: 110, height: 26), bg: Color(red: 0.90, green: 0.40, blue: 0.20))
    gulls(ctx, t: t)
}

/// Myrtle Beach: the SkyWheel's glass gondolas turning over the boardwalk, surf shops,
/// palmettos, and the ocean beyond.
private func drawMyrtleBeach(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 300, color: Color(red: 0.15, green: 0.52, blue: 0.72))
    fill(ctx, CGRect(x: 0, y: 350, width: Stage.W, height: 55), Color(red: 0.95, green: 0.88, blue: 0.70))
    // The fishing pier off to the left
    fill(ctx, CGRect(x: 440, y: 306, width: 300, height: 8), Color(red: 0.55, green: 0.42, blue: 0.30))
    for x in stride(from: 446.0, to: 740, by: 22) { fill(ctx, CGRect(x: x, y: 314, width: 4, height: 40), Color(red: 0.42, green: 0.32, blue: 0.22)) }
    fill(ctx, CGRect(x: 690, y: 290, width: 40, height: 16), Color(red: 0.85, green: 0.80, blue: 0.70))

    ferrisWheel(ctx, hub: CGPoint(x: 940, y: 200), radius: 150, rim: .white, count: 18, t: t, enclosed: true)
    fill(ctx, CGRect(x: 900, y: 360, width: 80, height: 40), Color(red: 0.20, green: 0.30, blue: 0.45), corner: 3)
    ctx.draw(Text("SKYWHEEL").font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 940, y: 380))

    let shops: [(x: Double, w: Double, wall: Color, name: String, awning: Color)] = [
        (0, 105, Color(red: 0.80, green: 0.95, blue: 0.92), "SURF SHOP", Color(red: 0.10, green: 0.60, blue: 0.65)),
        (108, 100, Color(red: 0.98, green: 0.92, blue: 0.80), "ICE CREAM", Color(red: 0.95, green: 0.45, blue: 0.60)),
        (1110, 90, Color(red: 0.98, green: 0.95, blue: 0.75), "T-SHIRTS", Color(red: 0.95, green: 0.60, blue: 0.15)),
    ]
    for shop in shops {
        fill(ctx, CGRect(x: shop.x, y: 310, width: shop.w, height: 95), shop.wall)
        fill(ctx, CGRect(x: shop.x + 6, y: 316, width: shop.w - 12, height: 20), shop.awning, corner: 4)
        ctx.draw(Text(shop.name).font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: shop.x + shop.w / 2, y: 326))
        for k in 0..<Int(shop.w / 14) { fill(ctx, CGRect(x: shop.x + Double(k) * 14, y: 342, width: 14, height: 14), k % 2 == 0 ? shop.awning : .white) }
        fill(ctx, CGRect(x: shop.x + 10, y: 362, width: shop.w - 20, height: 30), Color(red: 0.30, green: 0.25, blue: 0.25), corner: 2)
    }
    palm(ctx, x: 760, base: 405, height: 150, t: t)
    palm(ctx, x: 1080, base: 405, height: 130, t: t + 1.5)
    boardwalk(ctx)
    sign(ctx, "MYRTLE BEACH", at: CGRect(x: 560, y: 352, width: 110, height: 26), bg: Color(red: 0.10, green: 0.55, blue: 0.60))
    gulls(ctx, t: t)
}

/// A wild Banker horse from Shackleford Banks, grazing or looking up, swishing its tail.
private func wildHorse(_ ctx: GraphicsContext, x: Double, ground: Double, facing f: Double, grazing: Bool, coat: Color, t: Double) {
    let dark = Color(red: 0.18, green: 0.12, blue: 0.08)
    for dx in [-20.0, -12, 12, 20] { fill(ctx, CGRect(x: x + dx * f - 2.5, y: ground - 30, width: 5, height: 30), coat) }
    for dx in [-20.0, -12, 12, 20] { fill(ctx, CGRect(x: x + dx * f - 3, y: ground - 4, width: 6, height: 4), dark) }
    ctx.fill(Path(ellipseIn: CGRect(x: x - 30, y: ground - 52, width: 60, height: 28)), with: .color(coat))
    var tail = Path()
    tail.move(to: CGPoint(x: x - 28 * f, y: ground - 46))
    tail.addQuadCurve(to: CGPoint(x: x - 36 * f + sin(t * 3) * 5, y: ground - 14), control: CGPoint(x: x - 40 * f, y: ground - 40))
    ctx.stroke(tail, with: .color(dark), style: StrokeStyle(lineWidth: 5, lineCap: .round))
    let neckBase = CGPoint(x: x + 22 * f, y: ground - 46)
    let headPt = grazing ? CGPoint(x: x + 40 * f, y: ground - 10) : CGPoint(x: x + 36 * f, y: ground - 78)
    var neck = Path()
    neck.move(to: neckBase)
    neck.addLine(to: headPt)
    ctx.stroke(neck, with: .color(coat), style: StrokeStyle(lineWidth: 13, lineCap: .round))
    ctx.stroke(neck.offsetBy(dx: -4 * f, dy: -3), with: .color(dark), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    var face = ctx
    face.translateBy(x: headPt.x, y: headPt.y)
    face.scaleBy(x: f, y: 1)
    face.rotate(by: .degrees(grazing ? 70 : 25))
    face.fill(Path(ellipseIn: CGRect(x: -6, y: -7, width: 26, height: 13)), with: .color(coat))
    ctx.fill(circle(CGPoint(x: headPt.x + 2 * f, y: headPt.y - 4), 1.6), with: .color(dark))
    var ear = Path()
    ear.move(to: CGPoint(x: headPt.x - 3 * f, y: headPt.y - 6))
    ear.addLine(to: CGPoint(x: headPt.x - 1 * f, y: headPt.y - 14))
    ear.addLine(to: CGPoint(x: headPt.x + 3 * f, y: headPt.y - 6))
    ctx.fill(ear, with: .color(coat))
}

/// The Crystal Coast of North Carolina: the black-and-white diamond Cape Lookout Lighthouse,
/// sea oats waving on the dunes, wild horses from Shackleford Banks, and a shrimp boat offshore.
private func drawCrystalCoast(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.18, green: 0.55, blue: 0.68))
    // A shrimp boat with its outriggers out
    let sx = 1200 - (t * 12).truncatingRemainder(dividingBy: 900)
    fill(ctx, CGRect(x: sx, y: 306, width: 60, height: 12), .white, corner: 4)
    fill(ctx, CGRect(x: sx + 8, y: 294, width: 20, height: 12), Color(white: 0.9), corner: 2)
    fill(ctx, CGRect(x: sx + 34, y: 270, width: 2, height: 36), Color(white: 0.4))
    for side in [-1.0, 1.0] {
        var boom = Path()
        boom.move(to: CGPoint(x: sx + 35, y: 274))
        boom.addLine(to: CGPoint(x: sx + 35 + side * 38, y: 296))
        ctx.stroke(boom, with: .color(Color(white: 0.4)), lineWidth: 1.5)
    }

    // Cape Lookout Lighthouse
    let cx = 1000.0
    let base = 340.0, top = 100.0
    var tower = Path()
    tower.move(to: CGPoint(x: cx - 30, y: base))
    tower.addLine(to: CGPoint(x: cx - 19, y: top))
    tower.addLine(to: CGPoint(x: cx + 19, y: top))
    tower.addLine(to: CGPoint(x: cx + 30, y: base))
    tower.closeSubpath()
    ctx.fill(tower, with: .color(.white))
    var checks = ctx
    checks.clip(to: tower)
    let d = 30.0
    for row in 0..<10 {
        let cy = top + d / 2 + Double(row) * d
        for col in -2...2 where (row + col) % 2 == 0 {
            let c = CGPoint(x: cx + Double(col) * d, y: cy)
            var diamond = Path()
            diamond.move(to: CGPoint(x: c.x, y: c.y - d / 2))
            diamond.addLine(to: CGPoint(x: c.x + d / 2, y: c.y))
            diamond.addLine(to: CGPoint(x: c.x, y: c.y + d / 2))
            diamond.addLine(to: CGPoint(x: c.x - d / 2, y: c.y))
            diamond.closeSubpath()
            checks.fill(diamond, with: .color(Color(white: 0.08)))
        }
    }
    ctx.stroke(tower, with: .color(Color(white: 0.3)), lineWidth: 1)
    fill(ctx, CGRect(x: cx - 26, y: top - 6, width: 52, height: 7), Color(white: 0.1))
    fill(ctx, CGRect(x: cx - 14, y: top - 26, width: 28, height: 20), Color(red: 0.95, green: 0.95, blue: 0.80))
    for x in [cx - 9, cx, cx + 9] { fill(ctx, CGRect(x: x - 0.75, y: top - 26, width: 1.5, height: 20), Color(white: 0.1)) }
    var cap = Path()
    cap.move(to: CGPoint(x: cx - 18, y: top - 26))
    cap.addQuadCurve(to: CGPoint(x: cx + 18, y: top - 26), control: CGPoint(x: cx, y: top - 48))
    ctx.fill(cap, with: .color(Color(white: 0.1)))
    // The beam sweeping round
    let sweep = sin(t * 1.2)
    var beam = Path()
    beam.move(to: CGPoint(x: cx, y: top - 16))
    beam.addLine(to: CGPoint(x: cx + sweep * 260, y: top - 40))
    beam.addLine(to: CGPoint(x: cx + sweep * 260, y: top + 10))
    beam.closeSubpath()
    ctx.fill(beam, with: .color(Color(red: 1, green: 0.97, blue: 0.75).opacity(0.25 * abs(sweep))))
    fill(ctx, CGRect(x: cx - 40, y: base - 18, width: 26, height: 18), Color(red: 0.92, green: 0.90, blue: 0.85))
    fill(ctx, CGRect(x: cx - 42, y: base - 22, width: 30, height: 5), Color(red: 0.55, green: 0.15, blue: 0.15))

    // Dunes and sea oats
    var dunes = Path()
    dunes.move(to: CGPoint(x: 0, y: 405))
    dunes.addLine(to: CGPoint(x: 0, y: 350))
    dunes.addQuadCurve(to: CGPoint(x: 420, y: 345), control: CGPoint(x: 200, y: 300))
    dunes.addQuadCurve(to: CGPoint(x: 820, y: 340), control: CGPoint(x: 640, y: 290))
    dunes.addQuadCurve(to: CGPoint(x: Stage.W, y: 345), control: CGPoint(x: 1050, y: 310))
    dunes.addLine(to: CGPoint(x: Stage.W, y: 405))
    dunes.closeSubpath()
    ctx.fill(dunes, with: .color(Color(red: 0.93, green: 0.86, blue: 0.68)))
    for x in stride(from: 430.0, to: Stage.W, by: 23) {
        let baseY = 340 + (x * 13).truncatingRemainder(dividingBy: 20)
        let sway = sin(t * 1.5 + x * 0.05) * 6
        var stalk = Path()
        stalk.move(to: CGPoint(x: x, y: baseY))
        stalk.addQuadCurve(to: CGPoint(x: x + sway, y: baseY - 46), control: CGPoint(x: x, y: baseY - 26))
        ctx.stroke(stalk, with: .color(Color(red: 0.62, green: 0.65, blue: 0.38)), lineWidth: 1.6)
        ctx.fill(Path(ellipseIn: CGRect(x: x + sway - 3, y: baseY - 58, width: 6, height: 14)), with: .color(Color(red: 0.82, green: 0.70, blue: 0.45)))
    }
    wildHorse(ctx, x: 590, ground: 352, facing: 1, grazing: true, coat: Color(red: 0.50, green: 0.30, blue: 0.18), t: t)
    wildHorse(ctx, x: 760, ground: 348, facing: -1, grazing: false, coat: Color(red: 0.35, green: 0.22, blue: 0.14), t: t + 1)

    sand(ctx, Color(red: 0.96, green: 0.90, blue: 0.74))
    sign(ctx, "CRYSTAL COAST · NC", at: CGRect(x: 850, y: 360, width: 130, height: 26), bg: Color(red: 0.10, green: 0.45, blue: 0.60))
    gulls(ctx, t: t)
}

/// The money table outside, with a sign promising it wears off.
func drawCashTable(_ ctx: GraphicsContext, accent: Color) {
    let cx = Stage.cashX
    fill(ctx, CGRect(x: cx - 22, y: Stage.floorY - 44, width: 44, height: 44), accent.opacity(0.85), corner: 3)
    fill(ctx, CGRect(x: cx - 27, y: Stage.floorY - 48, width: 54, height: 7), .white, corner: 2)
    fill(ctx, CGRect(x: cx - 14, y: Stage.floorY - 62, width: 28, height: 15), Color(red: 0.30, green: 0.55, blue: 0.30), corner: 3)
    ctx.draw(Text("$").font(.system(size: 11, weight: .black)).foregroundStyle(.white), at: CGPoint(x: cx, y: Stage.floorY - 54.5))
    ctx.draw(Text("DISSOLVES\nIN 8 HOURS").font(.system(size: 6, weight: .heavy, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: cx, y: Stage.floorY - 22))
}

// MARK: Town

/// Main Street, where one of them buys groceries and makes a deposit at the bank.
func drawTown(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    // Road and sidewalk
    fill(ctx, CGRect(x: 0, y: 440, width: Stage.W, height: 60), Color(white: 0.80))
    for x in stride(from: 0.0, to: Stage.W, by: 50) { fill(ctx, CGRect(x: x, y: 440, width: 1.5, height: 60), Color(white: 0.70)) }
    fill(ctx, CGRect(x: 0, y: 500, width: Stage.W, height: 8), Color(white: 0.6))
    fill(ctx, CGRect(x: 0, y: 508, width: Stage.W, height: Stage.H - 508), Color(white: 0.30))
    for x in stride(from: 20.0, to: Stage.W, by: 90) { fill(ctx, CGRect(x: x, y: 552, width: 44, height: 5), Color(red: 1, green: 0.85, blue: 0.2)) }

    // The grocery store
    let store = CGRect(x: 130, y: 230, width: 400, height: 210)
    fill(ctx, store, Color(red: 0.93, green: 0.88, blue: 0.78))
    fill(ctx, CGRect(x: store.minX - 8, y: store.minY - 10, width: store.width + 16, height: 14), Color(red: 0.55, green: 0.38, blue: 0.25))
    // Striped awning
    for k in 0..<10 {
        fill(ctx, CGRect(x: store.minX + Double(k) * 40, y: 300, width: 40, height: 26), k % 2 == 0 ? Color(red: 0.20, green: 0.60, blue: 0.30) : .white)
    }
    fill(ctx, CGRect(x: store.minX + 70, y: 244, width: 260, height: 44), Color(red: 0.20, green: 0.50, blue: 0.25), corner: 6)
    ctx.draw(Text("FRESH MARKET").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: store.midX, y: 266))
    // Front windows with fruit and veg
    for wx in [store.minX + 20, store.maxX - 130] {
        let w = CGRect(x: wx, y: 340, width: 110, height: 70)
        fill(ctx, w, Color(red: 0.75, green: 0.88, blue: 0.95))
        for (i, c) in [Color.red, .orange, .yellow, .green, .red, .orange].enumerated() {
            ctx.fill(circle(CGPoint(x: w.minX + 12 + Double(i) * 17, y: w.maxY - 12), 8), with: .color(c))
        }
        ctx.stroke(Path(w), with: .color(.white), lineWidth: 4)
    }
    let storeDoor = CGRect(x: Stage.storeDoorX - 28, y: 350, width: 56, height: 90)
    fill(ctx, storeDoor, Color(red: 0.60, green: 0.80, blue: 0.90))
    ctx.stroke(Path(storeDoor), with: .color(Color(white: 0.4)), lineWidth: 4)
    fill(ctx, CGRect(x: storeDoor.midX - 1.5, y: storeDoor.minY, width: 3, height: storeDoor.height), Color(white: 0.4))
    // Shopping carts
    for x in [470.0, 492.0] {
        ctx.stroke(Path(CGRect(x: x, y: 408, width: 30, height: 20)), with: .color(Color(white: 0.45)), lineWidth: 2)
        for wx in [x + 5, x + 25] { ctx.fill(circle(CGPoint(x: wx, y: 434), 3), with: .color(Color(white: 0.2))) }
    }

    // The bank: stone front with columns and a pediment
    let bank = CGRect(x: 690, y: 250, width: 340, height: 190)
    let stone = Color(red: 0.88, green: 0.87, blue: 0.84)
    fill(ctx, bank, stone)
    var pediment = Path()
    pediment.move(to: CGPoint(x: bank.minX - 14, y: bank.minY))
    pediment.addLine(to: CGPoint(x: bank.midX, y: bank.minY - 60))
    pediment.addLine(to: CGPoint(x: bank.maxX + 14, y: bank.minY))
    pediment.closeSubpath()
    ctx.fill(pediment, with: .color(Color(red: 0.80, green: 0.79, blue: 0.76)))
    fill(ctx, CGRect(x: bank.minX - 14, y: bank.minY, width: bank.width + 28, height: 26), Color(red: 0.80, green: 0.79, blue: 0.76))
    ctx.draw(Text("FIRST NATIONAL BANK").font(.system(size: 18, weight: .heavy, design: .serif)).foregroundStyle(Color(red: 0.25, green: 0.25, blue: 0.30)),
             at: CGPoint(x: bank.midX, y: bank.minY + 13))
    ctx.draw(Text("$").font(.system(size: 28, weight: .black, design: .serif)).foregroundStyle(Color(red: 0.15, green: 0.50, blue: 0.25)),
             at: CGPoint(x: bank.midX, y: bank.minY - 24))
    for k in 0..<6 {
        let cx = bank.minX + 22 + Double(k) * 59
        guard abs(cx - Stage.bankDoorX) > 40 else { continue }
        fill(ctx, CGRect(x: cx - 11, y: bank.minY + 32, width: 22, height: bank.height - 44), .white)
        for g in 0..<3 { fill(ctx, CGRect(x: cx - 7 + Double(g) * 6, y: bank.minY + 36, width: 1.5, height: bank.height - 52), Color(white: 0.85)) }
    }
    fill(ctx, CGRect(x: bank.minX - 10, y: bank.maxY - 12, width: bank.width + 20, height: 12), Color(red: 0.78, green: 0.77, blue: 0.74))
    let bankDoor = CGRect(x: Stage.bankDoorX - 30, y: 340, width: 60, height: 88)
    var arch = Path()
    arch.addRoundedRect(in: bankDoor, cornerSize: CGSize(width: 30, height: 30))
    ctx.fill(arch, with: .color(Color(red: 0.40, green: 0.26, blue: 0.16)))
    ctx.fill(circle(CGPoint(x: bankDoor.midX + 18, y: bankDoor.midY + 10), 3), with: .color(.yellow))

    // Street lamps and a little tree
    for x in [610.0, 1110.0] {
        fill(ctx, CGRect(x: x - 3, y: 330, width: 6, height: 110), Color(white: 0.2))
        ctx.fill(circle(CGPoint(x: x, y: 326), 9), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
    }
    fill(ctx, CGRect(x: 60, y: 360, width: 10, height: 80), Color(red: 0.45, green: 0.30, blue: 0.18))
    ctx.fill(circle(CGPoint(x: 65, y: 345), 36 + sin(t) * 1), with: .color(Color(red: 0.25, green: 0.55, blue: 0.28)))
}

/// Further along Main Street: a diner, and the dealer's showroom with a scooter, a motorcycle and a car.
func drawShops(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    // Road and sidewalk
    fill(ctx, CGRect(x: 0, y: 440, width: Stage.W, height: 60), Color(white: 0.80))
    for x in stride(from: 0.0, to: Stage.W, by: 50) { fill(ctx, CGRect(x: x, y: 440, width: 1.5, height: 60), Color(white: 0.70)) }
    fill(ctx, CGRect(x: 0, y: 500, width: Stage.W, height: 8), Color(white: 0.6))
    fill(ctx, CGRect(x: 0, y: 508, width: Stage.W, height: Stage.H - 508), Color(white: 0.30))
    for x in stride(from: 20.0, to: Stage.W, by: 90) { fill(ctx, CGRect(x: x, y: 552, width: 44, height: 5), Color(red: 1, green: 0.85, blue: 0.2)) }

    // A chrome-trimmed diner
    let diner = CGRect(x: 60, y: 300, width: 340, height: 140)
    fill(ctx, diner, Color(red: 0.85, green: 0.88, blue: 0.90), corner: 18)
    fill(ctx, CGRect(x: diner.minX, y: diner.minY + 70, width: diner.width, height: 14), Color(red: 0.85, green: 0.20, blue: 0.25))
    for k in 0..<5 { fill(ctx, CGRect(x: diner.minX + 20 + Double(k) * 62, y: diner.minY + 18, width: 50, height: 44), Color(red: 0.75, green: 0.88, blue: 0.95), corner: 4) }
    fill(ctx, CGRect(x: diner.midX - 90, y: diner.minY - 40, width: 180, height: 34), Color(red: 0.85, green: 0.20, blue: 0.25), corner: 17)
    ctx.draw(Text("ROSIE'S DINER").font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: diner.midX, y: diner.minY - 23))
    fill(ctx, CGRect(x: diner.maxX - 70, y: diner.minY + 90, width: 40, height: 50), Color(red: 0.60, green: 0.80, blue: 0.90))

    // The dealer: a glass showroom with a scooter, a motorcycle and a car on the floor
    let lot = CGRect(x: 520, y: 270, width: 580, height: 170)
    fill(ctx, lot, Color(red: 0.90, green: 0.92, blue: 0.95))
    fill(ctx, CGRect(x: lot.minX - 10, y: lot.minY - 46, width: lot.width + 20, height: 50), Color(red: 0.15, green: 0.25, blue: 0.50), corner: 6)
    ctx.draw(Text("WHEELS & DEALS").font(.system(size: 27, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.85, blue: 0.2)),
             at: CGPoint(x: lot.midX, y: lot.minY - 22))
    let glass = CGRect(x: lot.minX + 16, y: lot.minY + 22, width: 450, height: lot.height - 30)
    fill(ctx, glass, Color(red: 0.78, green: 0.90, blue: 0.98))
    fill(ctx, CGRect(x: glass.minX, y: glass.maxY - 8, width: glass.width, height: 8), Color(white: 0.92))
    let spots = [(Vehicle.scooter, glass.minX + 60), (.motorcycle, glass.minX + 175), (.car, glass.minX + 340)]
    drawScooter(ctx, x: spots[0].1, ground: glass.maxY - 6)
    drawMotorcycle(ctx, x: spots[1].1, ground: glass.maxY - 6, paint: Color(red: 0.15, green: 0.35, blue: 0.85), noseRight: true)
    drawCar(ctx, x: spots[2].1, hooked: false, paint: Color(red: 0.85, green: 0.16, blue: 0.20), noseRight: true, ground: glass.maxY - 6)
    ctx.stroke(Path(glass), with: .color(.white), lineWidth: 5)
    for (vehicle, x) in spots {
        fill(ctx, CGRect(x: x - 28, y: glass.minY + 10, width: 56, height: 22), Color(red: 1, green: 0.95, blue: 0.4), corner: 4)
        ctx.draw(Text("$\(vehicle.price)").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.black), at: CGPoint(x: x, y: glass.minY + 21))
    }
    let dealerDoor = CGRect(x: Stage.dealerDoorX - 28, y: 350, width: 56, height: 90)
    fill(ctx, dealerDoor, Color(red: 0.60, green: 0.80, blue: 0.90))
    ctx.stroke(Path(dealerDoor), with: .color(Color(red: 0.15, green: 0.25, blue: 0.50)), lineWidth: 4)
    // Bunting fluttering over the lot
    let flags: [Color] = [.red, Color(red: 1, green: 0.85, blue: 0.2), Color(red: 0.25, green: 0.55, blue: 0.85)]
    for i in 0..<20 {
        let u = Double(i) / 19
        let x = lot.minX + u * lot.width
        let y = lot.minY + 8 + sin(u * .pi) * 10 + sin(t * 3 + Double(i)) * 1.5
        var flag = Path()
        flag.move(to: CGPoint(x: x - 8, y: y))
        flag.addLine(to: CGPoint(x: x + 8, y: y))
        flag.addLine(to: CGPoint(x: x, y: y + 14))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(flags[i % flags.count]))
    }
    fill(ctx, CGRect(x: 457, y: 330, width: 6, height: 110), Color(white: 0.2))
    ctx.fill(circle(CGPoint(x: 460, y: 326), 9), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
}

// MARK: The accident

/// The airport's terminal roadway: the glass terminal with its departures curb, the control tower,
/// a jet climbing out overhead, and the lanes where the cab and the shuttle bus run into each other.
func drawAirport(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    // A jet climbing away every so often
    let u = (t / 16).truncatingRemainder(dividingBy: 1)
    if u < 0.6 {
        let p = u / 0.6
        var jet = ctx
        jet.translateBy(x: -100 + p * 1400, y: 190 - p * 170)
        jet.rotate(by: .degrees(-8))
        let body = Color(white: 0.96)
        jet.fill(Path(roundedRect: CGRect(x: -46, y: -6, width: 92, height: 12), cornerRadius: 6), with: .color(body))
        var wing = Path()
        wing.move(to: CGPoint(x: -6, y: 0)); wing.addLine(to: CGPoint(x: -24, y: 22)); wing.addLine(to: CGPoint(x: -12, y: 22)); wing.addLine(to: CGPoint(x: 14, y: 0))
        jet.fill(wing, with: .color(Color(white: 0.85)))
        var fin = Path()
        fin.move(to: CGPoint(x: -44, y: -4)); fin.addLine(to: CGPoint(x: -52, y: -24)); fin.addLine(to: CGPoint(x: -38, y: -24)); fin.addLine(to: CGPoint(x: -30, y: -4))
        jet.fill(fin, with: .color(Color(red: 0.15, green: 0.35, blue: 0.75)))
        for k in 0..<7 { jet.fill(circle(CGPoint(x: -26 + Double(k) * 9, y: -1), 1.6), with: .color(Color(red: 0.3, green: 0.4, blue: 0.6))) }
    }
    // The control tower
    fill(ctx, CGRect(x: 1080, y: 120, width: 34, height: 220), Color(white: 0.82))
    var cab = Path()
    cab.move(to: CGPoint(x: 1060, y: 120)); cab.addLine(to: CGPoint(x: 1134, y: 120)); cab.addLine(to: CGPoint(x: 1126, y: 86)); cab.addLine(to: CGPoint(x: 1068, y: 86))
    cab.closeSubpath()
    ctx.fill(cab, with: .color(Color(red: 0.30, green: 0.50, blue: 0.62)))
    fill(ctx, CGRect(x: 1062, y: 78, width: 70, height: 9), Color(white: 0.75), corner: 2)
    fill(ctx, CGRect(x: 1096, y: 56, width: 2, height: 22), Color(white: 0.5))
    ctx.fill(circle(CGPoint(x: 1097, y: 55), 3), with: .color(.red.opacity(0.4 + 0.6 * max(0, sin(t * 3)))))

    // The terminal: a long glass front under a swooping roof
    let glass = Color(red: 0.55, green: 0.72, blue: 0.85)
    fill(ctx, CGRect(x: 0, y: 220, width: 1040, height: 180), glass)
    for x in stride(from: 0.0, to: 1040, by: 52) { fill(ctx, CGRect(x: x, y: 220, width: 3, height: 180), Color(white: 0.92)) }
    for y in [270.0, 320] { fill(ctx, CGRect(x: 0, y: y, width: 1040, height: 3), Color(white: 0.92)) }
    var roof = Path()
    roof.move(to: CGPoint(x: -10, y: 226))
    roof.addQuadCurve(to: CGPoint(x: 1060, y: 226), control: CGPoint(x: 520, y: 170))
    roof.addLine(to: CGPoint(x: 1060, y: 238))
    roof.addQuadCurve(to: CGPoint(x: -10, y: 238), control: CGPoint(x: 520, y: 184))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(white: 0.95)))
    ctx.draw(Text("INTERNATIONAL AIRPORT").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(Color(red: 0.12, green: 0.25, blue: 0.55)),
             at: CGPoint(x: 520, y: 252))
    // The curbside canopy, with DEPARTURES signs and airline doors
    fill(ctx, CGRect(x: 0, y: 330, width: 1040, height: 14), Color(white: 0.88))
    for x in stride(from: 60.0, to: 1040, by: 200) { fill(ctx, CGRect(x: x, y: 344, width: 8, height: 56), Color(white: 0.75)) }
    for (k, x) in [150.0, 550, 900].enumerated() {
        fill(ctx, CGRect(x: x - 70, y: 300, width: 140, height: 24), Color(red: 0.10, green: 0.12, blue: 0.20), corner: 3)
        ctx.draw(Text(k == 1 ? "✈ DEPARTURES" : (k == 0 ? "DOOR 1 · CHECK-IN" : "DOOR 4 · BAGGAGE")).font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.82, blue: 0.20)), at: CGPoint(x: x, y: 312))
    }
    for x in [300.0, 720] {
        fill(ctx, CGRect(x: x - 30, y: 346, width: 60, height: 54), Color(red: 0.70, green: 0.85, blue: 0.92))
        fill(ctx, CGRect(x: x - 1, y: 346, width: 2, height: 54), Color(white: 0.6))
    }
    // Curb, lanes and a crosswalk
    fill(ctx, CGRect(x: 0, y: 400, width: Stage.W, height: 40), Color(white: 0.80))
    fill(ctx, CGRect(x: 0, y: 436, width: Stage.W, height: 4), Color(red: 0.85, green: 0.20, blue: 0.20))
    fill(ctx, CGRect(x: 0, y: 440, width: Stage.W, height: Stage.H - 440), Color(white: 0.34))
    for x in stride(from: 20.0, to: Stage.W, by: 90) where abs(x - Stage.crashX) > 120 {
        fill(ctx, CGRect(x: x, y: 548, width: 44, height: 5), .white.opacity(0.85))
    }
    for k in 0..<6 { fill(ctx, CGRect(x: 950 + Double(k) * 26, y: 500, width: 14, height: 90), .white.opacity(0.75)) }
    // "Active loading and unloading only" sign
    fill(ctx, CGRect(x: 1160, y: 330, width: 4, height: 80), Color(white: 0.3))
    fill(ctx, CGRect(x: 1130, y: 330, width: 64, height: 36), .white, corner: 2)
    ctx.draw(Text("NO\nPARKING\nLOAD ONLY").font(.system(size: 7, weight: .heavy)).foregroundStyle(.red), at: CGPoint(x: 1162, y: 348))
}

/// A yellow Sunshine Cab sedan, nose to the right, with a TAXI light on the roof. `x` is its middle.
func drawTaxi(_ ctx: GraphicsContext, x: Double, ground: Double = Stage.floorY, dented: Bool = false, now: Date = .now, scale: Double = 1) {
    var c = ctx
    c.translateBy(x: x, y: ground)
    c.scaleBy(x: scale, y: scale)
    let half = Stage.taxiLength / 2
    let yellow = Color(red: 1.00, green: 0.80, blue: 0.10)
    var cabin = Path()
    cabin.move(to: CGPoint(x: -half + 28, y: -44))
    cabin.addLine(to: CGPoint(x: -half + 52, y: -72))
    cabin.addLine(to: CGPoint(x: half - 64, y: -72))
    cabin.addLine(to: CGPoint(x: half - 36, y: -44))
    cabin.closeSubpath()
    c.fill(cabin, with: .color(yellow))
    for (x0, x1) in [(-half + 40, -6.0), (2.0, half - 50)] {
        var w = Path()
        w.move(to: CGPoint(x: x0, y: -46))
        w.addLine(to: CGPoint(x: max(x0, -half + 56), y: -67))
        w.addLine(to: CGPoint(x: min(x1, half - 68), y: -67))
        w.addLine(to: CGPoint(x: x1, y: -46))
        w.closeSubpath()
        c.fill(w, with: .color(Color(red: 0.60, green: 0.75, blue: 0.88)))
    }
    fill(c, CGRect(x: -half, y: -46, width: Stage.taxiLength, height: 32), yellow, corner: 9)
    // The checkered stripe and the company name
    for k in 0..<Int((Stage.taxiLength - 20) / 6) {
        for row in 0..<2 where (k + row) % 2 == 0 {
            fill(c, CGRect(x: -half + 10 + Double(k) * 6, y: -36 + Double(row) * 5, width: 6, height: 5), Color(white: 0.08))
        }
    }
    c.draw(Text("SUNSHINE CAB").font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(Color(white: 0.1)), at: CGPoint(x: -4, y: -20))
    fill(c, CGRect(x: -22, y: -84, width: 44, height: 12), .white, corner: 3)
    c.draw(Text("TAXI").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(Color(white: 0.1)), at: CGPoint(x: 0, y: -78))
    fill(c, CGRect(x: half - 6, y: -40, width: 7, height: 7), Color(red: 1, green: 0.97, blue: 0.75), corner: 2)
    fill(c, CGRect(x: -half - 1, y: -40, width: 5, height: 8), Color(red: 0.9, green: 0.1, blue: 0.1), corner: 2)
    if dented {
        var dent = Path()
        dent.move(to: CGPoint(x: half + 1, y: -46))
        for (i, dy) in [6.0, 12, 18, 24, 31].enumerated() {
            dent.addLine(to: CGPoint(x: half - (i % 2 == 0 ? 14 : 4), y: -46 + dy))
        }
        dent.addLine(to: CGPoint(x: half + 1, y: -14))
        dent.closeSubpath()
        c.fill(dent, with: .color(Color(white: 0.35)))
    }
    for wx in [-half + 38, half - 40] {
        c.fill(circle(CGPoint(x: wx, y: -11), 12), with: .color(Color(white: 0.12)))
        c.fill(circle(CGPoint(x: wx, y: -11), 5.5), with: .color(Color(white: 0.8)))
    }
}

/// The airport shuttle bus, nose to the left. `x` is its middle.
func drawShuttleBus(_ ctx: GraphicsContext, x: Double, ground: Double = Stage.floorY, dented: Bool = false) {
    let half = Stage.busLength / 2
    let left = x - half
    let blue = Color(red: 0.12, green: 0.35, blue: 0.72)
    // Body, with a sloped windshield at the front
    var body = Path()
    body.move(to: CGPoint(x: left + 6, y: ground - 14))
    body.addLine(to: CGPoint(x: left, y: ground - 70))
    body.addLine(to: CGPoint(x: left + 18, y: ground - 124))
    body.addLine(to: CGPoint(x: x + half, y: ground - 124))
    body.addLine(to: CGPoint(x: x + half, y: ground - 14))
    body.closeSubpath()
    ctx.fill(body, with: .color(Color(white: 0.97)))
    ctx.stroke(body, with: .color(Color(white: 0.7)), lineWidth: 1.5)
    var shield = Path()
    shield.move(to: CGPoint(x: left + 3, y: ground - 74))
    shield.addLine(to: CGPoint(x: left + 19, y: ground - 118))
    shield.addLine(to: CGPoint(x: left + 32, y: ground - 118))
    shield.addLine(to: CGPoint(x: left + 32, y: ground - 74))
    shield.closeSubpath()
    ctx.fill(shield, with: .color(Color(red: 0.45, green: 0.62, blue: 0.80)))
    // The door, a row of windows, and the blue stripe
    fill(ctx, CGRect(x: left + 38, y: ground - 116, width: 30, height: 98), Color(red: 0.45, green: 0.62, blue: 0.80))
    fill(ctx, CGRect(x: left + 52, y: ground - 116, width: 2, height: 98), Color(white: 0.85))
    for wx in stride(from: left + 80, to: x + half - 30, by: 42) {
        fill(ctx, CGRect(x: wx, y: ground - 114, width: 36, height: 34), Color(red: 0.45, green: 0.62, blue: 0.80), corner: 3)
    }
    fill(ctx, CGRect(x: left + 70, y: ground - 72, width: Stage.busLength - 70, height: 16), blue)
    ctx.draw(Text("AIRPORT SHUTTLE").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: x + 30, y: ground - 64))
    ctx.draw(Text("TERMINALS · RENTAL CARS · PARKING").font(.system(size: 7, weight: .bold, design: .rounded)).foregroundStyle(blue), at: CGPoint(x: x + 30, y: ground - 44))
    fill(ctx, CGRect(x: left + 2, y: ground - 40, width: 8, height: 8), Color(red: 1, green: 0.97, blue: 0.75), corner: 2)
    fill(ctx, CGRect(x: x + half - 6, y: ground - 44, width: 6, height: 12), Color(red: 0.9, green: 0.1, blue: 0.1), corner: 2)
    if dented {
        var dent = Path()
        dent.move(to: CGPoint(x: left - 1, y: ground - 62))
        for (i, dy) in [8.0, 16, 24, 32, 40].enumerated() {
            dent.addLine(to: CGPoint(x: left + (i % 2 == 0 ? 14 : 5), y: ground - 62 + dy))
        }
        dent.addLine(to: CGPoint(x: left + 2, y: ground - 14))
        dent.closeSubpath()
        ctx.fill(dent, with: .color(Color(white: 0.45)))
        // A cracked windshield
        var crack = Path()
        crack.move(to: CGPoint(x: left + 14, y: ground - 90))
        crack.addLine(to: CGPoint(x: left + 22, y: ground - 100))
        crack.addLine(to: CGPoint(x: left + 18, y: ground - 108))
        crack.move(to: CGPoint(x: left + 22, y: ground - 100))
        crack.addLine(to: CGPoint(x: left + 30, y: ground - 96))
        ctx.stroke(crack, with: .color(.white), lineWidth: 1.2)
    }
    for wx in [left + 52, x + half - 50] {
        ctx.fill(circle(CGPoint(x: wx, y: ground - 13), 14), with: .color(Color(white: 0.12)))
        ctx.fill(circle(CGPoint(x: wx, y: ground - 13), 6), with: .color(Color(white: 0.75)))
    }
}

/// An airport vehicle with its lights flashing: the white police SUV (nose right), or the yellow operations pickup (nose left).
func drawAirportVehicle(_ ctx: GraphicsContext, x: Double, police: Bool, now: Date, ground: Double = Stage.floorY) {
    let t = now.timeIntervalSinceReferenceDate
    var c = ctx
    c.translateBy(x: x, y: ground)
    if !police { c.scaleBy(x: -1, y: 1) }
    let paint = police ? Color(white: 0.97) : Color(red: 1.00, green: 0.78, blue: 0.10)
    if police {
        var cabin = Path()
        cabin.move(to: CGPoint(x: -66, y: -46)); cabin.addLine(to: CGPoint(x: -60, y: -82)); cabin.addLine(to: CGPoint(x: 30, y: -82)); cabin.addLine(to: CGPoint(x: 52, y: -46))
        cabin.closeSubpath()
        c.fill(cabin, with: .color(paint))
        for (x0, w) in [(-54.0, 40.0), (-8.0, 40.0)] { fill(c, CGRect(x: x0, y: -77, width: w, height: 24), Color(red: 0.35, green: 0.45, blue: 0.55), corner: 2) }
    } else {
        var cabin = Path()
        cabin.move(to: CGPoint(x: 0, y: -46)); cabin.addLine(to: CGPoint(x: 6, y: -80)); cabin.addLine(to: CGPoint(x: 42, y: -80)); cabin.addLine(to: CGPoint(x: 60, y: -46))
        cabin.closeSubpath()
        c.fill(cabin, with: .color(paint))
        fill(c, CGRect(x: 12, y: -76, width: 32, height: 24), Color(red: 0.35, green: 0.45, blue: 0.55), corner: 2)
        fill(c, CGRect(x: -70, y: -58, width: 70, height: 6), paint)
    }
    fill(c, CGRect(x: -72, y: -48, width: 144, height: 34), paint, corner: 8)
    fill(c, CGRect(x: -72, y: -36, width: 144, height: 7), police ? Color(red: 0.12, green: 0.30, blue: 0.70) : Color(white: 0.1))
    var label = c
    if !police { label.scaleBy(x: -1, y: 1) }
    label.draw(Text(police ? "AIRPORT POLICE" : "AIRPORT OPERATIONS").font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(police ? Color(red: 0.12, green: 0.30, blue: 0.70) : Color(white: 0.1)), at: CGPoint(x: 0, y: -20))
    // The light bar
    let lx = police ? -15.0 : 24.0
    let flip = Int(t * 4) % 2 == 0
    fill(c, CGRect(x: lx - 22, y: police ? -90 : -88, width: 44, height: 8), Color(white: 0.2), corner: 3)
    let on: (Color, Color) = police ? (.red, .blue) : (.orange, .orange)
    c.fill(Path(roundedRect: CGRect(x: lx - 20, y: police ? -89 : -87, width: 18, height: 6), cornerRadius: 2), with: .color(on.0.opacity(flip ? 1 : 0.25)))
    c.fill(Path(roundedRect: CGRect(x: lx + 2, y: police ? -89 : -87, width: 18, height: 6), cornerRadius: 2), with: .color(on.1.opacity(flip ? 0.25 : 1)))
    let glowC = flip ? on.0 : on.1
    c.fill(circle(CGPoint(x: flip ? lx - 11 : lx + 11, y: police ? -86 : -84), 18), with: .color(glowC.opacity(0.25)))
    fill(c, CGRect(x: 66, y: -42, width: 7, height: 7), Color(red: 1, green: 0.97, blue: 0.75), corner: 2)
    for wx in [-44.0, 44] {
        c.fill(circle(CGPoint(x: wx, y: -11), 12), with: .color(Color(white: 0.12)))
        c.fill(circle(CGPoint(x: wx, y: -11), 5), with: .color(Color(white: 0.75)))
    }
}

/// Smoke curling up from the crash, with bits of broken glass on the road.
func drawCrashSmoke(_ ctx: GraphicsContext, at c: CGPoint, since t0: Date, now: Date) {
    let age = now.timeIntervalSince(t0)
    guard age >= 0 else { return }
    // A flash on impact
    if age < 0.4 {
        ctx.fill(circle(c, 40 + age * 120), with: .color(Color(red: 1, green: 0.9, blue: 0.5).opacity(0.8 * (1 - age / 0.4))))
    }
    for k in 0..<6 {
        let u = (age * 0.35 + Double(k) / 6).truncatingRemainder(dividingBy: 1)
        let p = CGPoint(x: c.x + sin(Double(k) * 2.1 + u * 3) * 14, y: c.y - u * 110)
        ctx.fill(circle(p, 10 + u * 22), with: .color(Color(white: 0.55).opacity(0.45 * (1 - u))))
    }
    for k in 0..<9 {
        let g = CGPoint(x: c.x - 40 + Double(k) * 10, y: Stage.floorY + 6 + Double((k * 7) % 5) * 3)
        ctx.fill(circle(g, 1.6), with: .color(Color(red: 0.75, green: 0.90, blue: 1)))
    }
}

// MARK: Sunshine Cab Company

/// The cab company's dispatch office: a fares board, key hooks, and the boss's desk by the window onto the lot of taxis.
func drawCabOffice(_ ctx: GraphicsContext, now: Date) {
    fill(ctx, CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY), Color(red: 0.92, green: 0.88, blue: 0.76))
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.42, green: 0.34, blue: 0.30))
    fill(ctx, CGRect(x: 0, y: Stage.floorY - 12, width: Stage.W, height: 12), Color(red: 0.55, green: 0.45, blue: 0.38))
    fill(ctx, CGRect(x: 0, y: 0, width: Stage.W, height: 60), Color(red: 0.12, green: 0.12, blue: 0.14))
    for k in 0..<60 { fill(ctx, CGRect(x: Double(k) * 20, y: 54, width: 10, height: 6), Color(red: 1.00, green: 0.80, blue: 0.10)) }
    ctx.draw(Text("☀ SUNSHINE CAB COMPANY ☀").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1.00, green: 0.80, blue: 0.10)),
             at: CGPoint(x: 600, y: 28))
    // The front door
    let door = CGRect(x: Stage.officeDoorX - 40, y: Stage.floorY - 190, width: 80, height: 190)
    fill(ctx, door, Color(red: 0.45, green: 0.30, blue: 0.20))
    fill(ctx, door.insetBy(dx: 12, dy: 14).offsetBy(dx: 0, dy: -30), Color(red: 0.70, green: 0.85, blue: 0.95).opacity(0.8))
    ctx.fill(circle(CGPoint(x: door.maxX - 14, y: door.midY + 10), 4), with: .color(.yellow))
    // Fares board
    let board = CGRect(x: 230, y: 110, width: 260, height: 150)
    fill(ctx, board, .white, corner: 4)
    ctx.stroke(Path(board), with: .color(Color(white: 0.4)), lineWidth: 4)
    ctx.draw(Text("TODAY'S FARES").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(Color(red: 0.55, green: 0.40, blue: 0.00)),
             at: CGPoint(x: board.midX, y: board.minY + 18))
    for (k, line) in ["9:00  Airport — DEBBIE", "10:15 Hospital — RAY", "12:30 Train stn — LUIS", "3:00  Airport — SANDRA"].enumerated() {
        ctx.draw(Text(line).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(.black.opacity(0.75)),
                 at: CGPoint(x: board.minX + 16, y: board.minY + 48 + Double(k) * 24), anchor: .leading)
    }
    // Key hooks
    fill(ctx, CGRect(x: 520, y: 140, width: 120, height: 70), Color(red: 0.55, green: 0.40, blue: 0.25), corner: 4)
    for k in 0..<5 {
        let x = 535 + Double(k) * 22
        ctx.fill(circle(CGPoint(x: x, y: 158), 2.5), with: .color(Color(white: 0.8)))
        fill(ctx, CGRect(x: x - 3, y: 164, width: 6, height: 16), Color(red: 1.00, green: 0.80, blue: 0.10), corner: 2)
    }
    // A window onto the lot, with taxis parked outside
    let window = CGRect(x: 690, y: 110, width: 470, height: 200)
    fill(ctx, window, Color(red: 0.62, green: 0.82, blue: 0.98))
    var lot = ctx
    lot.clip(to: Path(window))
    fill(lot, CGRect(x: window.minX, y: window.maxY - 40, width: window.width, height: 40), Color(white: 0.55))
    drawTaxi(lot, x: window.minX + 110, ground: window.maxY - 12, scale: 0.8)
    drawTaxi(lot, x: window.minX + 330, ground: window.maxY - 12, scale: 0.8)
    ctx.stroke(Path(window), with: .color(.white), lineWidth: 6)
    fill(ctx, CGRect(x: window.midX - 2, y: window.minY, width: 4, height: window.height), .white)
    // The boss's desk, with the radio dispatch mic
    let desk = CGRect(x: Stage.bossDeskX - 30, y: Stage.floorY - 70, width: 190, height: 70)
    fill(ctx, CGRect(x: desk.minX - 6, y: desk.minY - 8, width: desk.width + 12, height: 10), Color(red: 0.40, green: 0.26, blue: 0.16), corner: 2)
    fill(ctx, desk, Color(red: 0.50, green: 0.34, blue: 0.22))
    fill(ctx, CGRect(x: desk.minX + 110, y: desk.minY - 34, width: 44, height: 28), Color(white: 0.2), corner: 2)
    fill(ctx, CGRect(x: desk.minX + 20, y: desk.minY - 18, width: 40, height: 10), .white, corner: 1)
    fill(ctx, CGRect(x: desk.minX + 66, y: desk.minY - 20, width: 26, height: 12), Color(red: 0.85, green: 0.20, blue: 0.20), corner: 2)
    ctx.draw(Text("COMPLAINTS").font(.system(size: 5, weight: .heavy)).foregroundStyle(.white), at: CGPoint(x: desk.minX + 79, y: desk.minY - 14))
    fill(ctx, CGRect(x: desk.minX + 164, y: desk.minY - 30, width: 3, height: 22), Color(white: 0.25))
    ctx.fill(circle(CGPoint(x: desk.minX + 165.5, y: desk.minY - 32), 5), with: .color(Color(white: 0.15)))
    // Water cooler and a plant
    fill(ctx, CGRect(x: 600, y: Stage.floorY - 90, width: 34, height: 90), Color(white: 0.85), corner: 4)
    ctx.fill(Path(ellipseIn: CGRect(x: 602, y: Stage.floorY - 132, width: 30, height: 44)), with: .color(Color(red: 0.55, green: 0.80, blue: 0.98).opacity(0.85)))
    fill(ctx, CGRect(x: 1150, y: Stage.floorY - 34, width: 26, height: 34), Color(red: 0.75, green: 0.42, blue: 0.28), corner: 3)
    for dx in [-10.0, 0, 10] {
        ctx.fill(Path(ellipseIn: CGRect(x: 1157 + dx, y: Stage.floorY - 80, width: 12, height: 50)), with: .color(Color(red: 0.22, green: 0.55, blue: 0.28)))
    }
}
