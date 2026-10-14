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
        case .lasVegas: Color(red: 0.80, green: 0.10, blue: 0.45)
        case .stKitts: Color(red: 0.00, green: 0.55, blue: 0.30)
        case .celebrationKey: Color(red: 0.85, green: 0.10, blue: 0.15)
        case .halfMoonCay: Color(red: 0.08, green: 0.20, blue: 0.45)
        case .catalina: Color(red: 0.80, green: 0.25, blue: 0.20)
        case .rio: Color(red: 0.00, green: 0.58, blue: 0.25)
        case .oceanCay: Color(red: 0.00, green: 0.60, blue: 0.65)
        case .laBufadora: Color(red: 0.75, green: 0.30, blue: 0.15)
        case .kingsWharf: Color(red: 0.90, green: 0.40, blue: 0.58)
        }
    }

    var banner: String { "ROSWELL ALIEN TRANSFORMATIONS  ·  \(shortName.uppercased())  ·  $\(price)  ·  KIDS $\(kidPrice)" }
}

func drawVenue(_ ctx: GraphicsContext, _ venue: Venue, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    switch venue {
    case .lasVegas: drawLasVegas(ctx, t: t)
    case .stKitts: drawStKitts(ctx, t: t)
    case .celebrationKey: drawCelebrationKey(ctx, t: t)
    case .halfMoonCay: drawHalfMoonCay(ctx, t: t)
    case .catalina: drawCatalina(ctx, t: t)
    case .rio: drawRio(ctx, t: t)
    case .oceanCay: drawOceanCay(ctx, t: t)
    case .laBufadora: drawLaBufadora(ctx, t: t)
    case .kingsWharf: drawKingsWharf(ctx, t: t)
    }
    // A glowing landing pad under the saucer
    let x = Stage.venueSaucerX
    ctx.fill(Path(ellipseIn: CGRect(x: x - 130, y: Stage.floorY - 6, width: 260, height: 22)), with: .color(Color(white: 0.3)))
    ctx.stroke(Path(ellipseIn: CGRect(x: x - 120, y: Stage.floorY - 2, width: 240, height: 14)), with: .color(Color(red: 0.35, green: 1, blue: 0.45)), lineWidth: 2)
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

/// MSC's Ocean Cay: turquoise shallows, white sand, a red-and-white lighthouse and a cruise ship at anchor.
private func drawOceanCay(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.20, green: 0.78, blue: 0.82))
    fill(ctx, CGRect(x: 0, y: 290, width: Stage.W, height: 30), Color(red: 0.10, green: 0.50, blue: 0.75))
    // Cruise ship on the horizon
    let bob = sin(t * 0.8) * 1.5
    var hull = Path()
    hull.move(to: CGPoint(x: 640, y: 268 + bob))
    hull.addLine(to: CGPoint(x: 900, y: 268 + bob))
    hull.addLine(to: CGPoint(x: 885, y: 296 + bob))
    hull.addLine(to: CGPoint(x: 655, y: 296 + bob))
    hull.closeSubpath()
    ctx.fill(hull, with: .color(Color(red: 0.12, green: 0.16, blue: 0.35)))
    for (i, w) in [240.0, 210.0, 175.0].enumerated() {
        fill(ctx, CGRect(x: 655 + Double(i) * 12, y: 256 - Double(i) * 12 + bob, width: w, height: 13), .white, corner: 2)
        for k in 0..<Int(w / 12) { fill(ctx, CGRect(x: 660 + Double(i) * 12 + Double(k) * 12, y: 260 - Double(i) * 12 + bob, width: 6, height: 4), Color(red: 0.3, green: 0.5, blue: 0.8)) }
    }
    fill(ctx, CGRect(x: 812, y: 206 + bob, width: 22, height: 22), Color(red: 0.12, green: 0.16, blue: 0.35), corner: 3)
    // Lighthouse on the right
    var tower = Path()
    tower.move(to: CGPoint(x: 1070, y: 420))
    tower.addLine(to: CGPoint(x: 1086, y: 200))
    tower.addLine(to: CGPoint(x: 1114, y: 200))
    tower.addLine(to: CGPoint(x: 1130, y: 420))
    tower.closeSubpath()
    ctx.fill(tower, with: .color(.white))
    for y in stride(from: 230.0, to: 420, by: 60) { fill(ctx, CGRect(x: 1072, y: y, width: 56, height: 26), Color(red: 0.85, green: 0.15, blue: 0.15)) }
    fill(ctx, CGRect(x: 1082, y: 176, width: 36, height: 26), Color(red: 1, green: 0.95, blue: 0.6), corner: 4)
    fill(ctx, CGRect(x: 1078, y: 168, width: 44, height: 10), Color(red: 0.85, green: 0.15, blue: 0.15), corner: 3)
    let sweep = sin(t * 1.4)
    var ray = Path()
    ray.move(to: CGPoint(x: 1100, y: 189))
    ray.addLine(to: CGPoint(x: 1100 + sweep * 160, y: 170))
    ray.addLine(to: CGPoint(x: 1100 + sweep * 160, y: 208))
    ray.closeSubpath()
    ctx.fill(ray, with: .color(.yellow.opacity(0.25)))
    // White sand beach, palms and a striped umbrella
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.98, green: 0.95, blue: 0.86))
    palm(ctx, x: 560, base: 410, height: 150, t: t)
    palm(ctx, x: 980, base: 410, height: 120, t: t + 1)
    var umbrella = Path()
    umbrella.addArc(center: CGPoint(x: 90, y: 360), radius: 50, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
    umbrella.closeSubpath()
    ctx.fill(umbrella, with: .color(Color(red: 0.95, green: 0.35, blue: 0.4)))
    fill(ctx, CGRect(x: 88, y: 360, width: 4, height: 55), Color(white: 0.9))
    gulls(ctx, t: t)
}

/// La Bufadora, south of Ensenada: dark Pacific cliffs, the famous blowhole geyser in the background
/// shooting spray high above the rocks every few seconds, and the row of market stalls on the walkway.
private func drawLaBufadora(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.08, green: 0.35, blue: 0.58))
    // Headland across the cove
    var far = Path()
    far.move(to: CGPoint(x: 0, y: 300))
    far.addQuadCurve(to: CGPoint(x: 260, y: 215), control: CGPoint(x: 90, y: 210))
    far.addQuadCurve(to: CGPoint(x: 470, y: 300), control: CGPoint(x: 400, y: 230))
    far.closeSubpath()
    ctx.fill(far, with: .color(Color(red: 0.50, green: 0.46, blue: 0.36)))
    // The rocky cliffs cradling the blowhole
    let rock = Color(red: 0.42, green: 0.34, blue: 0.28)
    let dark = Color(red: 0.30, green: 0.24, blue: 0.20)
    var cliffs = Path()
    cliffs.move(to: CGPoint(x: 620, y: 405))
    cliffs.addLine(to: CGPoint(x: 660, y: 280))
    cliffs.addLine(to: CGPoint(x: 720, y: 250))
    cliffs.addLine(to: CGPoint(x: 800, y: 262))
    cliffs.addLine(to: CGPoint(x: 870, y: 300))   // down into the notch
    cliffs.addLine(to: CGPoint(x: 950, y: 300))
    cliffs.addLine(to: CGPoint(x: 1010, y: 240))
    cliffs.addLine(to: CGPoint(x: 1090, y: 215))
    cliffs.addLine(to: CGPoint(x: 1160, y: 235))
    cliffs.addLine(to: CGPoint(x: 1200, y: 225))
    cliffs.addLine(to: CGPoint(x: 1200, y: 405))
    cliffs.closeSubpath()
    ctx.fill(cliffs, with: .color(rock))
    for (x0, y0, x1, y1) in [(690.0, 290.0, 720.0, 360.0), (760.0, 275.0, 745.0, 350.0), (1040.0, 250.0, 1060.0, 340.0), (1120.0, 240.0, 1110.0, 330.0)] {
        var crack = Path()
        crack.move(to: CGPoint(x: x0, y: y0))
        crack.addLine(to: CGPoint(x: x1, y: y1))
        ctx.stroke(crack, with: .color(dark), lineWidth: 3)
    }
    // Scrub on the clifftops
    for (x, y) in [(700.0, 256.0), (1070.0, 222.0), (1140.0, 234.0)] {
        ctx.fill(circle(CGPoint(x: x, y: y), 10), with: .color(Color(red: 0.35, green: 0.48, blue: 0.25)))
    }

    // The geyser: rumbles, then blasts a column of white spray out of the notch, then it rains back down.
    let hole = CGPoint(x: 910, y: 300)
    let cycle = 8.0
    let phase = t.truncatingRemainder(dividingBy: cycle)
    ctx.fill(Path(ellipseIn: CGRect(x: hole.x - 30, y: hole.y - 6, width: 60, height: 14)), with: .color(dark))
    if phase < 1.2 {
        // Rumbling foam in the notch
        for i in 0..<6 {
            let dx = sin(t * 9 + Double(i) * 1.7) * 22
            ctx.fill(circle(CGPoint(x: hole.x + dx, y: hole.y - 4 - abs(sin(t * 7 + Double(i))) * 8), 6), with: .color(.white.opacity(0.7)))
        }
    } else if phase < 4.8 {
        let p = (phase - 1.2) / 3.6                       // 0 → 1 over the blast
        let rise = min(1, p / 0.3)                        // shoots up fast
        let fade = p < 0.55 ? 1 : max(0, 1 - (p - 0.55) / 0.45)
        let h = 210 * (1 - pow(1 - rise, 2))
        let top = hole.y - h
        var column = Path()
        column.move(to: CGPoint(x: hole.x - 16, y: hole.y))
        column.addQuadCurve(to: CGPoint(x: hole.x - 34, y: top + 20), control: CGPoint(x: hole.x - 10, y: hole.y - h * 0.5))
        column.addQuadCurve(to: CGPoint(x: hole.x + 34, y: top + 20), control: CGPoint(x: hole.x, y: top - 30))
        column.addQuadCurve(to: CGPoint(x: hole.x + 16, y: hole.y), control: CGPoint(x: hole.x + 10, y: hole.y - h * 0.5))
        column.closeSubpath()
        ctx.fill(column, with: .linearGradient(Gradient(colors: [.white.opacity(0.95 * fade), Color(red: 0.80, green: 0.92, blue: 1).opacity(0.75 * fade)]),
                                               startPoint: CGPoint(x: hole.x, y: top), endPoint: hole))
        // Billowing crown and falling droplets
        for i in 0..<9 {
            let a = Double(i) / 9 * .pi * 2 + t * 2
            let spread = 20 + p * 70
            let c = CGPoint(x: hole.x + cos(a) * spread, y: top + 18 + sin(a) * 14 + p * p * 90)
            ctx.fill(circle(c, 12 - p * 5), with: .color(.white.opacity(0.85 * fade)))
        }
        for i in 0..<16 {
            let side = i % 2 == 0 ? -1.0 : 1.0
            let d = Double(i / 2) * 11 + p * 60
            let c = CGPoint(x: hole.x + side * d, y: top + 30 + pow(p * 1.4, 2) * 120 + Double(i) * 3)
            ctx.fill(circle(c, 2.5), with: .color(.white.opacity(0.8 * fade)))
        }
        // A misty rainbow in the spray
        if p > 0.25 {
            var bow = Path()
            bow.addArc(center: CGPoint(x: hole.x, y: hole.y), radius: h * 0.55, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            for (k, c) in [Color.red, .orange, .yellow, .green, .blue].enumerated() {
                ctx.stroke(bow.offsetBy(dx: 0, dy: Double(k) * 3), with: .color(c.opacity(0.18 * fade)), lineWidth: 3)
            }
        }
    }
    // Railing at the lookout above the blowhole
    fill(ctx, CGRect(x: 830, y: 282, width: 160, height: 3), Color(white: 0.9))
    for x in stride(from: 830.0, through: 990, by: 20) { fill(ctx, CGRect(x: x, y: 282, width: 3, height: 16), Color(white: 0.9)) }

    // The paved walkway lined with market stalls
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.82, green: 0.72, blue: 0.58))
    for x in stride(from: 0.0, to: Stage.W, by: 48) { fill(ctx, CGRect(x: x, y: 405, width: 2, height: Stage.H - 405), Color(red: 0.72, green: 0.62, blue: 0.48)) }
    let stripes: [Color] = [Color(red: 0.90, green: 0.20, blue: 0.30), Color(red: 1, green: 0.75, blue: 0.10), Color(red: 0.15, green: 0.60, blue: 0.55), Color(red: 0.55, green: 0.25, blue: 0.70)]
    for (i, x) in [470.0, 560.0, 1020.0, 1110.0].enumerated() {
        fill(ctx, CGRect(x: x, y: 350, width: 76, height: 58), Color(red: 0.60, green: 0.42, blue: 0.26))
        fill(ctx, CGRect(x: x + 6, y: 372, width: 64, height: 16), Color(red: 0.95, green: 0.90, blue: 0.80))
        for k in 0..<4 { ctx.fill(circle(CGPoint(x: x + 14 + Double(k) * 16, y: 372), 5), with: .color(stripes[(i + k) % 4])) }
        for k in 0..<4 {
            fill(ctx, CGRect(x: x - 4 + Double(k) * 21, y: 334, width: 21, height: 18), k % 2 == 0 ? stripes[i] : .white)
        }
    }
    // Papel picado strung between the stalls
    var string = Path()
    string.move(to: CGPoint(x: 470, y: 330))
    string.addQuadCurve(to: CGPoint(x: 636, y: 330), control: CGPoint(x: 553, y: 350))
    ctx.stroke(string, with: .color(Color(white: 0.3)), lineWidth: 1)
    for k in 0..<8 {
        let x = 480 + Double(k) * 20
        let y = 330 + sin(Double(k) / 7 * .pi) * 10 + sin(t * 2 + Double(k)) * 1.5
        fill(ctx, CGRect(x: x, y: y, width: 12, height: 14), stripes[k % 4])
    }
    sign(ctx, "LA BUFADORA", at: CGRect(x: 30, y: 350, width: 120, height: 26), bg: Color(red: 0.75, green: 0.30, blue: 0.15))
    gulls(ctx, t: t)
}

/// King's Wharf, Bermuda: the Royal Naval Dockyard's twin clock towers, a cruise ship alongside,
/// pastel cottages with white stepped roofs, and a limestone quay.
private func drawKingsWharf(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 300, color: Color(red: 0.12, green: 0.70, blue: 0.78))
    // A cruise ship tied up at the wharf
    cruiseShip(ctx, x: 420, waterline: 300, width: 380, hull: Color(red: 0.10, green: 0.12, blue: 0.30), t: t) { ctx, r in
        fill(ctx, r, Color(red: 0.10, green: 0.12, blue: 0.30), corner: 3)
        fill(ctx, CGRect(x: r.minX, y: r.minY + 7, width: r.width, height: 5), Color(red: 0.85, green: 0.20, blue: 0.20))
    }
    // The Clocktower building: long limestone warehouse with twin towers
    let stone = Color(red: 0.90, green: 0.85, blue: 0.74)
    let trim = Color(red: 0.74, green: 0.68, blue: 0.56)
    fill(ctx, CGRect(x: 850, y: 250, width: 290, height: 60), stone)
    fill(ctx, CGRect(x: 850, y: 246, width: 290, height: 6), trim)
    for k in 0..<7 {
        var arch = Path()
        let ax = 868 + Double(k) * 38
        arch.addRoundedRect(in: CGRect(x: ax, y: 270, width: 20, height: 40), cornerSize: CGSize(width: 10, height: 10))
        ctx.fill(arch, with: .color(Color(red: 0.42, green: 0.36, blue: 0.30)))
    }
    for (i, tx) in [880.0, 1080.0].enumerated() {
        fill(ctx, CGRect(x: tx, y: 150, width: 44, height: 110), stone)
        fill(ctx, CGRect(x: tx - 3, y: 146, width: 50, height: 6), trim)
        var cap = Path()
        cap.move(to: CGPoint(x: tx - 4, y: 148))
        cap.addLine(to: CGPoint(x: tx + 22, y: 112))
        cap.addLine(to: CGPoint(x: tx + 48, y: 148))
        cap.closeSubpath()
        ctx.fill(cap, with: .color(Color(red: 0.62, green: 0.58, blue: 0.52)))
        // One tower tells the time, the other the time of high tide.
        let face = CGPoint(x: tx + 22, y: 180)
        ctx.fill(circle(face, 14), with: .color(.white))
        ctx.stroke(circle(face, 14), with: .color(Color(red: 0.25, green: 0.25, blue: 0.30)), lineWidth: 2)
        let a = i == 0 ? t * 0.2 : 1.2
        for (len, ang) in [(10.0, a), (7.0, a / 12 + 2)] {
            var hand = Path()
            hand.move(to: face)
            hand.addLine(to: CGPoint(x: face.x + sin(ang) * len, y: face.y - cos(ang) * len))
            ctx.stroke(hand, with: .color(.black), lineWidth: 2)
        }
    }
    // Pastel Bermuda cottages with white stepped roofs
    fill(ctx, CGRect(x: 1138, y: 300, width: 80, height: 14), Color(red: 0.35, green: 0.60, blue: 0.30), corner: 4)
    for (i, c) in [Color(red: 0.98, green: 0.72, blue: 0.80), Color(red: 0.70, green: 0.88, blue: 0.96)].enumerated() {
        let x = 1145 + Double(i) * 34
        fill(ctx, CGRect(x: x, y: 272, width: 30, height: 30), c)
        var roof = Path()
        roof.move(to: CGPoint(x: x - 3, y: 274))
        roof.addLine(to: CGPoint(x: x + 15, y: 256))
        roof.addLine(to: CGPoint(x: x + 33, y: 274))
        roof.closeSubpath()
        ctx.fill(roof, with: .color(.white))
    }
    // Limestone quay
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.86, green: 0.82, blue: 0.72))
    for x in stride(from: 0.0, to: Stage.W, by: 60) { fill(ctx, CGRect(x: x, y: 405, width: 2, height: Stage.H - 405), Color(red: 0.76, green: 0.72, blue: 0.62)) }
    // Bollards along the edge
    for x in [480.0, 560.0, 900.0] {
        fill(ctx, CGRect(x: x, y: 395, width: 14, height: 16), Color(white: 0.2), corner: 4)
    }
    palm(ctx, x: 40, base: 410, height: 165, t: t)
    palm(ctx, x: 800, base: 410, height: 140, t: t + 1.5)
    sign(ctx, "KING'S WHARF · BERMUDA", at: CGRect(x: 622, y: 345, width: 176, height: 26), bg: Color(red: 0.90, green: 0.40, blue: 0.58))
    gulls(ctx, t: t)
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

/// A beach-style lifeguard stand on stilts.
private func lifeguardTower(_ ctx: GraphicsContext, x: Double, _ c: Color) {
    for dx in [-22.0, 18.0] { fill(ctx, CGRect(x: x + dx, y: 360, width: 5, height: 55), Color(white: 0.85)) }
    var ramp = Path()
    ramp.move(to: CGPoint(x: x + 22, y: 368))
    ramp.addLine(to: CGPoint(x: x + 70, y: 415))
    ctx.stroke(ramp, with: .color(Color(white: 0.85)), lineWidth: 5)
    fill(ctx, CGRect(x: x - 32, y: 318, width: 64, height: 44), c, corner: 6)
    fill(ctx, CGRect(x: x - 22, y: 328, width: 44, height: 16), Color(red: 0.55, green: 0.80, blue: 0.95), corner: 3)
    var roof = Path()
    roof.move(to: CGPoint(x: x - 38, y: 320))
    roof.addLine(to: CGPoint(x: x, y: 300))
    roof.addLine(to: CGPoint(x: x + 38, y: 320))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(.white))
}

private func sign(_ ctx: GraphicsContext, _ text: String, at r: CGRect, bg: Color, fg: Color = .white, size: Double = 11) {
    fill(ctx, CGRect(x: r.midX - 3, y: r.maxY, width: 6, height: 418 - r.maxY), Color(red: 0.45, green: 0.30, blue: 0.18))
    fill(ctx, r, bg, corner: 5)
    ctx.draw(Text(text).font(.system(size: size, weight: .heavy, design: .rounded)).foregroundStyle(fg),
             at: CGPoint(x: r.midX, y: r.midY))
}

// MARK: Las Vegas and St. Kitts

/// Downtown Las Vegas at dusk: casino fronts with chasing marquee bulbs, the glowing canopy over Fremont Street,
/// and a waving neon cowboy.
private func drawLasVegas(_ ctx: GraphicsContext, t: Double) {
    // Desert dusk painted over the daytime sky
    ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: 405)),
             with: .linearGradient(Gradient(colors: [Color(red: 0.16, green: 0.10, blue: 0.36), Color(red: 0.62, green: 0.26, blue: 0.50),
                                                     Color(red: 0.98, green: 0.62, blue: 0.32)]),
                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: 405)))
    for i in 0..<24 {
        let p = CGPoint(x: Double((i * 97 + 40) % 1200), y: 60 + Double((i * 53) % 110))
        ctx.fill(circle(p, 1.5), with: .color(.white.opacity(0.45 + 0.35 * sin(t * 2 + Double(i)))))
    }
    // Mountains on the horizon
    var ridge = Path()
    ridge.move(to: CGPoint(x: 0, y: 320))
    for (x, y) in [(120.0, 270.0), (260.0, 300.0), (420.0, 255.0), (600.0, 295.0), (820.0, 262.0), (1010.0, 290.0), (1200.0, 258.0)] {
        ridge.addLine(to: CGPoint(x: x, y: y))
    }
    ridge.addLine(to: CGPoint(x: Stage.W, y: 405))
    ridge.addLine(to: CGPoint(x: 0, y: 405))
    ridge.closeSubpath()
    ctx.fill(ridge, with: .color(Color(red: 0.30, green: 0.16, blue: 0.36)))

    let pink = Color(red: 1.00, green: 0.30, blue: 0.65)
    let gold = Color(red: 1.00, green: 0.82, blue: 0.20)
    let cyan = Color(red: 0.30, green: 0.95, blue: 1.00)

    // Fremont Street running away under its barrel-vault canopy of lights
    let cx = 795.0
    fill(ctx, CGRect(x: cx - 30, y: 250, width: 60, height: 155), Color(red: 0.20, green: 0.14, blue: 0.30))
    for row in 0..<9 {
        for col in 0..<4 where (row + col * 3) % 4 != 0 {
            fill(ctx, CGRect(x: cx - 24 + Double(col) * 13, y: 276 + Double(row) * 14, width: 8, height: 7), gold.opacity(0.85))
        }
    }
    fill(ctx, CGRect(x: cx - 34, y: 252, width: 68, height: 16), pink, corner: 3)
    ctx.draw(Text("HOTEL").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: cx, y: 260))
    for side in [-1.0, 1.0] {
        var wall = Path()
        wall.move(to: CGPoint(x: cx + side * 190, y: 405))
        wall.addLine(to: CGPoint(x: cx + side * 190, y: 290))
        wall.addLine(to: CGPoint(x: cx + side * 30, y: 345))
        wall.addLine(to: CGPoint(x: cx + side * 30, y: 405))
        wall.closeSubpath()
        ctx.fill(wall, with: .color(Color(red: 0.24, green: 0.14, blue: 0.34)))
        for (k, c) in [pink, cyan, gold].enumerated() {
            var strip = Path()
            strip.move(to: CGPoint(x: cx + side * 186, y: 312 + Double(k) * 26))
            strip.addLine(to: CGPoint(x: cx + side * 34, y: 354 + Double(k) * 14))
            ctx.stroke(strip, with: .color(c.opacity(0.6 + 0.4 * sin(t * 3 + Double(k) * 2))), lineWidth: 3)
        }
    }
    func arc(_ rx: Double, _ ry: Double, _ deg: Double) -> CGPoint {
        CGPoint(x: cx + cos(deg * .pi / 180) * rx, y: 405 + sin(deg * .pi / 180) * ry)
    }
    var canopy = Path()
    canopy.move(to: arc(215, 235, 180))
    for deg in stride(from: 180.0, through: 360, by: 4) { canopy.addLine(to: arc(215, 235, deg)) }
    for deg in stride(from: 360.0, through: 180, by: -4) { canopy.addLine(to: arc(190, 205, deg)) }
    canopy.closeSubpath()
    ctx.fill(canopy, with: .color(Color(red: 0.08, green: 0.06, blue: 0.18)))
    // The light show sweeps across the canopy
    for i in 0...30 {
        for j in 0..<3 {
            let hue = (Double(i) / 30 + Double(j) * 0.08 + t * 0.15).truncatingRemainder(dividingBy: 1)
            ctx.fill(circle(arc(195 + Double(j) * 7.5, 211 + Double(j) * 9, 180 + Double(i) * 6), 3),
                     with: .color(Color(hue: hue, saturation: 0.85, brightness: 1)))
        }
    }

    // Casino fronts with lit windows, neon signs and chasing bulbs along the roof
    let fronts: [(x: Double, w: Double, top: Double, wall: Color, name: String, neon: Color)] = [
        (0, 170, 322, Color(red: 0.30, green: 0.18, blue: 0.40), "MOTEL", cyan),
        (180, 230, 306, Color(red: 0.36, green: 0.16, blue: 0.34), "WEDDING CHAPEL", pink),
        (425, 150, 215, Color(red: 0.26, green: 0.14, blue: 0.38), "CASINO", gold),
        (1015, 185, 195, Color(red: 0.34, green: 0.14, blue: 0.30), "SLOTS", cyan),
    ]
    for (i, f) in fronts.enumerated() {
        fill(ctx, CGRect(x: f.x, y: f.top, width: f.w, height: 405 - f.top), f.wall)
        for (r, y) in stride(from: f.top + 44, to: 385, by: 18).enumerated() {
            for (c, x) in stride(from: f.x + 10, to: f.x + f.w - 14, by: 18).enumerated() where (r * 2 + c + i) % 3 != 0 {
                fill(ctx, CGRect(x: x, y: y, width: 10, height: 9), gold.opacity(0.75))
            }
        }
        let board = CGRect(x: f.x + 10, y: f.top + 10, width: f.w - 20, height: 26)
        fill(ctx, board, Color(red: 0.08, green: 0.05, blue: 0.14), corner: 5)
        ctx.stroke(Path(roundedRect: board, cornerRadius: 5), with: .color(f.neon), lineWidth: 2)
        ctx.draw(Text(f.name).font(.system(size: f.name.count > 8 ? 13 : 17, weight: .black, design: .rounded)).foregroundStyle(f.neon),
                 at: CGPoint(x: board.midX, y: board.midY))
        for (k, x) in stride(from: f.x + 4, through: f.x + f.w - 4, by: 12).enumerated() {
            let on = (k + Int(t * 6)) % 3 == 0
            ctx.fill(circle(CGPoint(x: x, y: f.top), 3), with: .color(on ? .white : gold.opacity(0.5)))
        }
    }

    // The neon cowboy waving from the casino roof
    let vic = CGPoint(x: 500, y: 215)
    let glow = 0.75 + 0.25 * sin(t * 5)
    fill(ctx, CGRect(x: vic.x - 16, y: vic.y - 62, width: 32, height: 62), Color(red: 0.95, green: 0.80, blue: 0.20).opacity(glow), corner: 6)
    for k in 0..<3 { fill(ctx, CGRect(x: vic.x - 16, y: vic.y - 50 + Double(k) * 16, width: 32, height: 3), Color(red: 0.85, green: 0.20, blue: 0.20)) }
    ctx.fill(circle(CGPoint(x: vic.x, y: vic.y - 74), 12), with: .color(Color(red: 1.00, green: 0.78, blue: 0.62)))
    fill(ctx, CGRect(x: vic.x - 24, y: vic.y - 88, width: 48, height: 6), cyan.opacity(glow), corner: 3)
    fill(ctx, CGRect(x: vic.x - 12, y: vic.y - 104, width: 24, height: 18), cyan.opacity(glow), corner: 5)
    fill(ctx, CGRect(x: vic.x - 9, y: vic.y - 62, width: 18, height: 8), Color(red: 0.85, green: 0.20, blue: 0.20), corner: 3)
    let wave = -0.9 + sin(t * 2.5) * 0.45
    var arm = Path()
    arm.move(to: CGPoint(x: vic.x + 14, y: vic.y - 52))
    arm.addLine(to: CGPoint(x: vic.x + 14 + cos(wave) * 38, y: vic.y - 52 + sin(wave) * 38))
    ctx.stroke(arm, with: .color(Color(red: 0.95, green: 0.80, blue: 0.20).opacity(glow)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
    ctx.fill(circle(CGPoint(x: vic.x + 14 + cos(wave) * 42, y: vic.y - 52 + sin(wave) * 42), 6), with: .color(Color(red: 1.00, green: 0.78, blue: 0.62)))

    // Pavement, with the neon shining off it
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.30, green: 0.28, blue: 0.34))
    for x in stride(from: 0.0, to: Stage.W, by: 60) { fill(ctx, CGRect(x: x, y: 405, width: 2, height: Stage.H - 405), Color(red: 0.24, green: 0.22, blue: 0.28)) }
    for (k, c) in [cyan, pink, gold, pink, cyan, gold].enumerated() {
        fill(ctx, CGRect(x: 60 + Double(k) * 200, y: 410, width: 90, height: 5), c.opacity(0.12 + 0.06 * sin(t * 3 + Double(k))), corner: 2)
    }
    sign(ctx, "FREMONT STREET", at: CGRect(x: 30, y: 350, width: 130, height: 26), bg: Color(red: 0.80, green: 0.10, blue: 0.45))
}

/// St. Kitts: cloud-capped Mount Liamuiga, Brimstone Hill Fortress on its hill, a cruise ship off Basseterre,
/// and the little scenic railway rolling along the shore.
private func drawStKitts(_ ctx: GraphicsContext, t: Double) {
    // Mount Liamuiga, green to the top, with sugar-cane fields on the lower slopes
    var volcano = Path()
    volcano.move(to: CGPoint(x: 400, y: 300))
    volcano.addQuadCurve(to: CGPoint(x: 640, y: 150), control: CGPoint(x: 560, y: 250))
    volcano.addLine(to: CGPoint(x: 700, y: 158))
    volcano.addQuadCurve(to: CGPoint(x: 960, y: 300), control: CGPoint(x: 790, y: 250))
    volcano.closeSubpath()
    ctx.fill(volcano, with: .color(Color(red: 0.16, green: 0.45, blue: 0.26)))
    for (x, w) in [(500.0, 90.0), (620.0, 120.0), (770.0, 100.0)] {
        ctx.fill(Path(ellipseIn: CGRect(x: x, y: 272, width: w, height: 40)), with: .color(Color(red: 0.50, green: 0.72, blue: 0.32)))
    }
    // The cloud that sits on the crater
    let drift = sin(t * 0.2) * 12
    for (dx, dy, r) in [(-46.0, 4.0, 18.0), (-18.0, -6.0, 24.0), (16.0, -4.0, 22.0), (46.0, 5.0, 17.0)] {
        ctx.fill(circle(CGPoint(x: 670 + dx + drift, y: 150 + dy), r), with: .color(.white.opacity(0.92)))
    }

    // Brimstone Hill and its fortress
    var hill = Path()
    hill.move(to: CGPoint(x: 900, y: 300))
    hill.addQuadCurve(to: CGPoint(x: 1040, y: 215), control: CGPoint(x: 950, y: 225))
    hill.addLine(to: CGPoint(x: 1150, y: 215))
    hill.addQuadCurve(to: CGPoint(x: 1210, y: 260), control: CGPoint(x: 1190, y: 225))
    hill.addLine(to: CGPoint(x: 1210, y: 300))
    hill.closeSubpath()
    ctx.fill(hill, with: .color(Color(red: 0.28, green: 0.52, blue: 0.30)))
    let stone = Color(red: 0.45, green: 0.43, blue: 0.42)
    fill(ctx, CGRect(x: 1040, y: 192, width: 112, height: 25), stone)
    for x in stride(from: 1040.0, to: 1150, by: 14) { fill(ctx, CGRect(x: x, y: 186, width: 8, height: 7), stone) }
    fill(ctx, CGRect(x: 1076, y: 170, width: 40, height: 24), Color(red: 0.52, green: 0.50, blue: 0.48))
    fill(ctx, CGRect(x: 1090, y: 180, width: 12, height: 14), Color(red: 0.22, green: 0.20, blue: 0.20), corner: 5)
    for x in [1046.0, 1128.0] { fill(ctx, CGRect(x: x, y: 200, width: 18, height: 5), Color(white: 0.12), corner: 2) }
    // The flag: green and red, split by a black band edged in yellow
    fill(ctx, CGRect(x: 1095, y: 138, width: 2, height: 32), Color(white: 0.9))
    let flag = CGRect(x: 1097, y: 138, width: 24, height: 15)
    fill(ctx, flag, Color(red: 0.00, green: 0.62, blue: 0.30))
    var red = Path()
    red.move(to: CGPoint(x: flag.maxX, y: flag.minY))
    red.addLine(to: CGPoint(x: flag.maxX, y: flag.maxY))
    red.addLine(to: CGPoint(x: flag.minX, y: flag.maxY))
    red.closeSubpath()
    ctx.fill(red, with: .color(Color(red: 0.80, green: 0.10, blue: 0.15)))
    var band = Path()
    band.move(to: CGPoint(x: flag.minX, y: flag.maxY))
    band.addLine(to: CGPoint(x: flag.maxX, y: flag.minY))
    var banner = ctx
    banner.clip(to: Path(flag))
    banner.stroke(band, with: .color(.yellow), lineWidth: 8)
    banner.stroke(band, with: .color(.black), lineWidth: 5)

    sea(ctx, t: t, top: 300, color: Color(red: 0.14, green: 0.68, blue: 0.78))
    cruiseShip(ctx, x: 460, waterline: 300, width: 300, hull: .white, t: t) { ctx, r in
        fill(ctx, r, Color(red: 0.10, green: 0.30, blue: 0.65), corner: 3)
        fill(ctx, CGRect(x: r.minX, y: r.minY + 7, width: r.width, height: 5), .yellow)
    }
    // Sand, palms and a beach umbrella
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.96, green: 0.90, blue: 0.74))
    palm(ctx, x: 40, base: 410, height: 170, t: t)
    palm(ctx, x: 560, base: 410, height: 150, t: t + 1)
    palm(ctx, x: 1140, base: 410, height: 135, t: t + 2)
    beachUmbrella(ctx, x: 140, Color(red: 0.00, green: 0.62, blue: 0.30))
    let board = CGRect(x: 820, y: 345, width: 110, height: 26)
    sign(ctx, "ST. KITTS", at: board, bg: Color(red: 0.00, green: 0.55, blue: 0.30))
    // A green vervet monkey sitting on the sign
    let fur = Color(red: 0.55, green: 0.55, blue: 0.40)
    var tail = Path()
    tail.move(to: CGPoint(x: board.maxX - 8, y: board.minY - 3))
    tail.addQuadCurve(to: CGPoint(x: board.maxX + 6, y: board.minY + 10 + sin(t * 2) * 3), control: CGPoint(x: board.maxX + 8, y: board.minY - 6))
    ctx.stroke(tail, with: .color(fur), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    ctx.fill(Path(ellipseIn: CGRect(x: board.maxX - 26, y: board.minY - 16, width: 16, height: 17)), with: .color(fur))
    ctx.fill(circle(CGPoint(x: board.maxX - 18, y: board.minY - 21), 7), with: .color(fur))
    ctx.fill(circle(CGPoint(x: board.maxX - 18, y: board.minY - 20), 4), with: .color(Color(white: 0.12)))

    // The scenic railway: a little engine pulling open double-deck cars along the shore
    fill(ctx, CGRect(x: 0, y: 428, width: Stage.W, height: 3), Color(white: 0.35))
    for x in stride(from: 0.0, to: Stage.W, by: 16) { fill(ctx, CGRect(x: x, y: 431, width: 8, height: 3), Color(red: 0.50, green: 0.36, blue: 0.22)) }
    let lead = Stage.W + 60 - (t * 40).truncatingRemainder(dividingBy: Stage.W + 420)
    fill(ctx, CGRect(x: lead, y: 408, width: 44, height: 16), Color(red: 0.12, green: 0.35, blue: 0.20), corner: 3)
    fill(ctx, CGRect(x: lead + 26, y: 398, width: 18, height: 12), Color(red: 0.12, green: 0.35, blue: 0.20), corner: 2)
    fill(ctx, CGRect(x: lead + 8, y: 400, width: 6, height: 9), Color(white: 0.2))
    for (k, c) in [Color(red: 0.80, green: 0.10, blue: 0.15), Color(red: 1.00, green: 0.82, blue: 0.20), Color(red: 0.00, green: 0.62, blue: 0.30)].enumerated() {
        let x = lead + 50 + Double(k) * 66
        fill(ctx, CGRect(x: x, y: 410, width: 60, height: 14), c, corner: 3)
        for w in 0..<4 { fill(ctx, CGRect(x: x + 5 + Double(w) * 14, y: 413, width: 8, height: 6), Color(red: 0.75, green: 0.90, blue: 0.98)) }
        fill(ctx, CGRect(x: x - 1, y: 394, width: 62, height: 3), c, corner: 1)
        for px in [x + 2, x + 29, x + 56] { fill(ctx, CGRect(x: px, y: 396, width: 2, height: 14), Color(white: 0.9)) }
        for wx in [x + 12, x + 48] { ctx.fill(circle(CGPoint(x: wx, y: 426), 4), with: .color(Color(white: 0.15))) }
    }
    for wx in [lead + 10, lead + 34] { ctx.fill(circle(CGPoint(x: wx, y: 426), 4), with: .color(Color(white: 0.15))) }
    gulls(ctx, t: t)
}


// MARK: The Bahamas

/// Carnival's Celebration Key: a turquoise lagoon, a Carnival ship with its red, white and blue funnel, and bright cabanas.
private func drawCelebrationKey(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.25, green: 0.80, blue: 0.85))
    fill(ctx, CGRect(x: 0, y: 290, width: Stage.W, height: 24), Color(red: 0.10, green: 0.50, blue: 0.78))
    cruiseShip(ctx, x: 600, waterline: 300, width: 300, hull: .white, t: t) { ctx, r in
        // Carnival's whale-tail funnel
        var tail = Path()
        tail.move(to: CGPoint(x: r.minX, y: r.maxY))
        tail.addLine(to: CGPoint(x: r.minX - 6, y: r.minY - 8))
        tail.addLine(to: CGPoint(x: r.maxX + 10, y: r.minY - 14))
        tail.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(Color(red: 0.85, green: 0.10, blue: 0.15)))
        fill(ctx, CGRect(x: r.minX - 2, y: r.minY + 2, width: r.width + 6, height: 5), .white)
        fill(ctx, CGRect(x: r.minX - 1, y: r.minY + 9, width: r.width + 4, height: 5), Color(red: 0.10, green: 0.25, blue: 0.65))
    }
    // Pier out to the ship
    fill(ctx, CGRect(x: 880, y: 318, width: 200, height: 8), Color(white: 0.85))
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.99, green: 0.95, blue: 0.85))
    // Bright cabanas
    for (i, c) in [Color(red: 1, green: 0.45, blue: 0.55), Color(red: 1, green: 0.80, blue: 0.20), Color(red: 0.30, green: 0.75, blue: 0.95)].enumerated() {
        let x = 960 + Double(i) * 70
        fill(ctx, CGRect(x: x, y: 360, width: 56, height: 50), Color(white: 0.97))
        var roof = Path()
        roof.move(to: CGPoint(x: x - 6, y: 362))
        roof.addLine(to: CGPoint(x: x + 28, y: 336))
        roof.addLine(to: CGPoint(x: x + 62, y: 362))
        roof.closeSubpath()
        ctx.fill(roof, with: .color(c))
    }
    palm(ctx, x: 540, base: 410, height: 140, t: t)
    palm(ctx, x: 30, base: 410, height: 160, t: t + 1)
    beachUmbrella(ctx, x: 140, Color(red: 1, green: 0.45, blue: 0.55))
    sign(ctx, "CELEBRATION KEY", at: CGRect(x: 820, y: 345, width: 130, height: 26), bg: Color(red: 0.85, green: 0.10, blue: 0.15))
    gulls(ctx, t: t)
}

/// Half Moon Cay: a crescent of white sand, a navy-hulled ship at anchor, and a tender boat coming in.
private func drawHalfMoonCay(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.22, green: 0.76, blue: 0.80))
    fill(ctx, CGRect(x: 0, y: 290, width: Stage.W, height: 22), Color(red: 0.08, green: 0.42, blue: 0.70))
    cruiseShip(ctx, x: 620, waterline: 296, width: 280, hull: Color(red: 0.08, green: 0.14, blue: 0.32), t: t) { ctx, r in
        fill(ctx, r, Color(red: 0.08, green: 0.14, blue: 0.32), corner: 3)
        fill(ctx, CGRect(x: r.minX, y: r.minY + 6, width: r.width, height: 4), Color(red: 0.80, green: 0.70, blue: 0.40))
    }
    // Tender boat shuttling to the beach
    let bx = 900 - (t * 25).truncatingRemainder(dividingBy: 400)
    fill(ctx, CGRect(x: bx, y: 348, width: 46, height: 12), .white, corner: 5)
    fill(ctx, CGRect(x: bx + 10, y: 338, width: 24, height: 10), Color(red: 0.95, green: 0.60, blue: 0.10), corner: 3)
    // The crescent beach sweeping round to a green headland on the right
    var crescent = Path()
    crescent.move(to: CGPoint(x: 0, y: 405))
    crescent.addQuadCurve(to: CGPoint(x: Stage.W, y: 300), control: CGPoint(x: 900, y: 420))
    crescent.addLine(to: CGPoint(x: Stage.W, y: Stage.H))
    crescent.addLine(to: CGPoint(x: 0, y: Stage.H))
    crescent.closeSubpath()
    ctx.fill(crescent, with: .color(Color(red: 0.99, green: 0.96, blue: 0.89)))
    var headland = Path()
    headland.move(to: CGPoint(x: 1030, y: 330))
    headland.addQuadCurve(to: CGPoint(x: 1210, y: 250), control: CGPoint(x: 1120, y: 250))
    headland.addLine(to: CGPoint(x: 1210, y: 330))
    headland.closeSubpath()
    ctx.fill(headland, with: .color(Color(red: 0.25, green: 0.55, blue: 0.28)))
    // Pastel beach villas
    for (i, c) in [Color(red: 0.98, green: 0.75, blue: 0.70), Color(red: 0.70, green: 0.88, blue: 0.95), Color(red: 0.98, green: 0.90, blue: 0.60)].enumerated() {
        let x = 1000 + Double(i) * 62
        fill(ctx, CGRect(x: x, y: 350, width: 50, height: 42), c)
        fill(ctx, CGRect(x: x - 4, y: 342, width: 58, height: 10), .white, corner: 2)
        fill(ctx, CGRect(x: x + 18, y: 368, width: 14, height: 24), Color(red: 0.40, green: 0.28, blue: 0.20))
    }
    palm(ctx, x: 520, base: 410, height: 150, t: t)
    palm(ctx, x: 950, base: 400, height: 120, t: t + 2)
    beachUmbrella(ctx, x: 100, Color(red: 0.10, green: 0.30, blue: 0.65))
    sign(ctx, "HALF MOON CAY", at: CGRect(x: 820, y: 345, width: 120, height: 26), bg: Color(red: 0.08, green: 0.14, blue: 0.32))
    gulls(ctx, t: t)
}

// MARK: Catalina and Rio

/// Catalina Island: Avalon harbor with boats on moorings, the round Casino with its red-tile roof,
/// and the brown-green hills behind town.
private func drawCatalina(_ ctx: GraphicsContext, t: Double) {
    // Hills behind Avalon
    var hills = Path()
    hills.move(to: CGPoint(x: 420, y: 300))
    hills.addQuadCurve(to: CGPoint(x: 760, y: 190), control: CGPoint(x: 560, y: 180))
    hills.addQuadCurve(to: CGPoint(x: 1000, y: 170), control: CGPoint(x: 880, y: 210))
    hills.addQuadCurve(to: CGPoint(x: 1210, y: 230), control: CGPoint(x: 1120, y: 130))
    hills.addLine(to: CGPoint(x: 1210, y: 300))
    hills.closeSubpath()
    ctx.fill(hills, with: .color(Color(red: 0.55, green: 0.55, blue: 0.32)))
    // Little white and terracotta houses up the hillside
    for (x, y) in [(640.0, 262.0), (690.0, 248.0), (745.0, 266.0), (800.0, 240.0), (860.0, 258.0), (915.0, 236.0)] {
        fill(ctx, CGRect(x: x, y: y, width: 22, height: 16), .white)
        fill(ctx, CGRect(x: x - 2, y: y - 5, width: 26, height: 6), Color(red: 0.78, green: 0.35, blue: 0.22), corner: 2)
    }
    sea(ctx, t: t, top: 300, color: Color(red: 0.08, green: 0.45, blue: 0.70))
    // The Avalon Casino: a round white ballroom on the point with a red-tile roof
    let cx = 1090.0
    fill(ctx, CGRect(x: cx - 80, y: 236, width: 160, height: 74), Color(red: 0.97, green: 0.95, blue: 0.90))
    for k in 0..<7 {
        var arch = Path()
        arch.addRoundedRect(in: CGRect(x: cx - 72 + Double(k) * 21, y: 258, width: 12, height: 24), cornerSize: CGSize(width: 6, height: 6))
        ctx.fill(arch, with: .color(Color(red: 0.30, green: 0.45, blue: 0.60)))
    }
    fill(ctx, CGRect(x: cx - 86, y: 232, width: 172, height: 7), Color(red: 0.90, green: 0.86, blue: 0.78))
    var roof = Path()
    roof.move(to: CGPoint(x: cx - 84, y: 234))
    roof.addQuadCurve(to: CGPoint(x: cx + 84, y: 234), control: CGPoint(x: cx, y: 180))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(Color(red: 0.80, green: 0.25, blue: 0.20)))
    fill(ctx, CGRect(x: cx - 3, y: 196, width: 6, height: 14), Color(red: 0.80, green: 0.25, blue: 0.20))
    // Boats bobbing on their moorings
    for (i, x) in [560.0, 660.0, 760.0, 870.0].enumerated() {
        let bob = sin(t * 1.3 + Double(i)) * 2
        let y = 322 + Double(i % 2) * 18 + bob
        var hull = Path()
        hull.move(to: CGPoint(x: x, y: y))
        hull.addLine(to: CGPoint(x: x + 54, y: y))
        hull.addLine(to: CGPoint(x: x + 46, y: y + 10))
        hull.addLine(to: CGPoint(x: x + 6, y: y + 10))
        hull.closeSubpath()
        ctx.fill(hull, with: .color(.white))
        fill(ctx, CGRect(x: x + 2, y: y + 7, width: 50, height: 2), [Color.blue, .red, .teal, .orange][i])
        if i % 2 == 0 {
            fill(ctx, CGRect(x: x + 26, y: y - 50, width: 2, height: 50), Color(white: 0.85))
            var sail = Path()
            sail.move(to: CGPoint(x: x + 29, y: y - 48))
            sail.addLine(to: CGPoint(x: x + 29, y: y - 4))
            sail.addLine(to: CGPoint(x: x + 50, y: y - 4))
            sail.closeSubpath()
            ctx.fill(sail, with: .color(.white.opacity(0.9)))
        } else {
            fill(ctx, CGRect(x: x + 14, y: y - 12, width: 24, height: 12), Color(white: 0.92), corner: 2)
        }
    }
    // Sandy beach along Crescent Avenue
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.93, green: 0.85, blue: 0.68))
    palm(ctx, x: 40, base: 410, height: 170, t: t)
    palm(ctx, x: 520, base: 410, height: 150, t: t + 1.5)
    beachUmbrella(ctx, x: 1150, Color(red: 0.80, green: 0.25, blue: 0.20))
    sign(ctx, "CATALINA ISLAND", at: CGRect(x: 650, y: 360, width: 130, height: 26), bg: Color(red: 0.80, green: 0.25, blue: 0.20))
    gulls(ctx, t: t)
}

/// Rio de Janeiro: Sugarloaf rising out of Guanabara Bay with its cable car, Christ the Redeemer on Corcovado,
/// the high-rises along Avenida Atlântica, and Copacabana's black-and-white wave promenade.
private func drawRio(_ ctx: GraphicsContext, t: Double) {
    // Corcovado with Christ the Redeemer on top
    var corcovado = Path()
    corcovado.move(to: CGPoint(x: 380, y: 300))
    corcovado.addQuadCurve(to: CGPoint(x: 560, y: 150), control: CGPoint(x: 500, y: 230))
    corcovado.addLine(to: CGPoint(x: 590, y: 145))
    corcovado.addQuadCurve(to: CGPoint(x: 780, y: 300), control: CGPoint(x: 640, y: 210))
    corcovado.closeSubpath()
    ctx.fill(corcovado, with: .color(Color(red: 0.25, green: 0.48, blue: 0.30)))
    let statue = Color(red: 0.92, green: 0.92, blue: 0.88)
    fill(ctx, CGRect(x: 569, y: 135, width: 12, height: 12), Color(white: 0.75))
    fill(ctx, CGRect(x: 571, y: 104, width: 8, height: 32), statue, corner: 2)
    fill(ctx, CGRect(x: 552, y: 110, width: 46, height: 5), statue, corner: 2)
    ctx.fill(circle(CGPoint(x: 575, y: 100), 4), with: .color(statue))
    // Sugarloaf and Morro da Urca
    var urca = Path()
    urca.move(to: CGPoint(x: 900, y: 300))
    urca.addQuadCurve(to: CGPoint(x: 1010, y: 300), control: CGPoint(x: 950, y: 220))
    urca.closeSubpath()
    ctx.fill(urca, with: .color(Color(red: 0.30, green: 0.50, blue: 0.30)))
    var loaf = Path()
    loaf.move(to: CGPoint(x: 1010, y: 300))
    loaf.addCurve(to: CGPoint(x: 1090, y: 120), control1: CGPoint(x: 1030, y: 200), control2: CGPoint(x: 1040, y: 125))
    loaf.addCurve(to: CGPoint(x: 1180, y: 300), control1: CGPoint(x: 1140, y: 115), control2: CGPoint(x: 1170, y: 200))
    loaf.closeSubpath()
    ctx.fill(loaf, with: .color(Color(red: 0.42, green: 0.45, blue: 0.40)))
    var greenCap = Path()
    greenCap.move(to: CGPoint(x: 1050, y: 150))
    greenCap.addQuadCurve(to: CGPoint(x: 1132, y: 150), control: CGPoint(x: 1090, y: 105))
    greenCap.closeSubpath()
    ctx.fill(greenCap, with: .color(Color(red: 0.30, green: 0.50, blue: 0.30)))
    // Cable car wire and a gondola gliding up and back
    let a = CGPoint(x: 955, y: 244), b = CGPoint(x: 1088, y: 124)
    var wire = Path()
    wire.move(to: a)
    wire.addLine(to: b)
    ctx.stroke(wire, with: .color(Color(white: 0.2)), lineWidth: 1.2)
    let f = (sin(t * 0.3) + 1) / 2
    let g = CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    fill(ctx, CGRect(x: g.x - 1, y: g.y, width: 2, height: 6), Color(white: 0.2))
    fill(ctx, CGRect(x: g.x - 8, y: g.y + 6, width: 16, height: 10), Color(red: 0.95, green: 0.80, blue: 0.20), corner: 3)
    // High-rises along Avenida Atlântica
    for (i, h) in [70.0, 95.0, 60.0, 110.0, 80.0, 65.0].enumerated() {
        let r = CGRect(x: 20 + Double(i) * 58, y: 300 - h, width: 50, height: h)
        fill(ctx, r, i % 2 == 0 ? Color(red: 0.96, green: 0.94, blue: 0.88) : Color(red: 0.88, green: 0.90, blue: 0.94))
        for row in stride(from: r.minY + 6, to: r.maxY - 4, by: 10) { fill(ctx, CGRect(x: r.minX + 4, y: row, width: r.width - 8, height: 3), Color(red: 0.40, green: 0.62, blue: 0.80)) }
    }
    sea(ctx, t: t, top: 300, color: Color(red: 0.12, green: 0.55, blue: 0.72))
    // Golden sand, then the famous wavy mosaic promenade
    fill(ctx, CGRect(x: 0, y: 380, width: Stage.W, height: Stage.H - 380), Color(red: 0.97, green: 0.88, blue: 0.66))
    fill(ctx, CGRect(x: 0, y: 440, width: Stage.W, height: Stage.H - 440), .white)
    for band in 0..<5 {
        var wave = Path()
        let y0 = 450 + Double(band) * 30
        for x in stride(from: 0.0, through: Stage.W, by: 6) {
            let pt = CGPoint(x: x, y: y0 + sin(x / 26) * 9)
            x == 0 ? wave.move(to: pt) : wave.addLine(to: pt)
        }
        for x in stride(from: Stage.W, through: 0, by: -6) { wave.addLine(to: CGPoint(x: x, y: y0 + 13 + sin(x / 26) * 9)) }
        wave.closeSubpath()
        ctx.fill(wave, with: .color(Color(white: 0.12)))
    }
    // Beach umbrellas in Brazil's colors, a coconut-water kiosk, a lifeguard post and palms
    beachUmbrella(ctx, x: 130, Color(red: 0.00, green: 0.58, blue: 0.25))
    beachUmbrella(ctx, x: 560, Color(red: 1.00, green: 0.85, blue: 0.10))
    beachUmbrella(ctx, x: 1165, Color(red: 0.05, green: 0.25, blue: 0.60))
    fill(ctx, CGRect(x: 690, y: 395, width: 60, height: 40), Color(red: 0.95, green: 0.95, blue: 0.95), corner: 3)
    fill(ctx, CGRect(x: 684, y: 386, width: 72, height: 12), Color(red: 0.00, green: 0.58, blue: 0.25), corner: 3)
    ctx.draw(Text("ÁGUA DE COCO").font(.system(size: 7, weight: .heavy, design: .rounded)).foregroundStyle(Color(red: 0.00, green: 0.45, blue: 0.20)),
             at: CGPoint(x: 720, y: 410))
    lifeguardTower(ctx, x: 850, Color(red: 1.00, green: 0.85, blue: 0.10))
    palm(ctx, x: 60, base: 440, height: 170, t: t)
    palm(ctx, x: 930, base: 440, height: 150, t: t + 1)
    sign(ctx, "COPACABANA · RIO", at: CGRect(x: 985, y: 360, width: 130, height: 26), bg: Color(red: 0.00, green: 0.58, blue: 0.25))
    gulls(ctx, t: t)
}

/// The money table outside, with a sign promising it wears off.
func drawCashTable(_ ctx: GraphicsContext, accent: Color) {
    let cx = Stage.cashX
    fill(ctx, CGRect(x: cx - 22, y: Stage.floorY - 44, width: 44, height: 44), accent.opacity(0.85), corner: 3)
    fill(ctx, CGRect(x: cx - 27, y: Stage.floorY - 48, width: 54, height: 7), .white, corner: 2)
    fill(ctx, CGRect(x: cx - 14, y: Stage.floorY - 62, width: 28, height: 15), Color(red: 0.30, green: 0.55, blue: 0.30), corner: 3)
    ctx.draw(Text("$").font(.system(size: 11, weight: .black)).foregroundStyle(.white), at: CGPoint(x: cx, y: Stage.floorY - 54.5))
    ctx.draw(Text("WEARS OFF\nIN 8 HOURS").font(.system(size: 6, weight: .heavy, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: cx, y: Stage.floorY - 22))
}

// MARK: Town

/// Main Street, where Mom buys groceries and makes a deposit at the bank.
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

// MARK: Rusty's Tavern

/// How long after the rampage starts each thing gets wrecked, in seconds.
enum BarWreck {
    static let stools: [(x: Double, at: Double)] = [(640, 6.0), (740, 0.3), (840, 0.7), (940, 7.0)]
    static let tables: [(x: Double, at: Double)] = [(250, 3.4), (450, 2.1)]
    static let chairsAt = 3.7
    static let signAt = 3.9
    /// Bottles on the back bar fall one after another over this window.
    static let bottlesFrom = 6.4, bottlesTo = 8.6
}

/// The tavern where Mom's ex-husband gets cut off: wood paneling, a neon sign, tables, a back bar full of bottles.
/// Everything gets knocked over, flipped or smashed as the rampage (from `rampageT0`) goes on; police lights flash
/// through the front window once `policeT0` comes.
func drawBar(_ ctx: GraphicsContext, rampageT0: Date, policeT0: Date, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    let r = now.timeIntervalSince(rampageT0)
    let wood = Color(red: 0.36, green: 0.22, blue: 0.13)
    let darkWood = Color(red: 0.24, green: 0.14, blue: 0.08)
    fill(ctx, CGRect(x: 0, y: 0, width: Stage.W, height: Stage.floorY), wood)
    for x in stride(from: 0.0, to: Stage.W, by: 60) { fill(ctx, CGRect(x: x, y: 0, width: 3, height: Stage.floorY), darkWood) }
    fill(ctx, CGRect(x: 0, y: 360, width: Stage.W, height: Stage.floorY - 360), darkWood)
    fill(ctx, CGRect(x: 0, y: 356, width: Stage.W, height: 6), Color(red: 0.55, green: 0.38, blue: 0.22))
    // Plank floor
    fill(ctx, CGRect(x: 0, y: Stage.floorY, width: Stage.W, height: Stage.H - Stage.floorY), Color(red: 0.45, green: 0.30, blue: 0.18))
    for x in stride(from: 0.0, to: Stage.W, by: 40) { fill(ctx, CGRect(x: x, y: Stage.floorY, width: 1.5, height: Stage.H - Stage.floorY), darkWood) }

    // The tavern's name in neon
    let flick = 0.8 + 0.2 * sin(t * 13) * sin(t * 3.1)
    ctx.draw(Text("RUSTY'S TAVERN").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.45, blue: 0.2).opacity(flick)),
             at: CGPoint(x: 820, y: 60))

    // The front door and the window onto the street
    let door = CGRect(x: Stage.barDoorX - 36, y: Stage.floorY - 190, width: 72, height: 190)
    fill(ctx, door, darkWood)
    let doorGlass = CGRect(x: door.minX + 12, y: door.minY + 14, width: door.width - 24, height: 70)
    let window = CGRect(x: 170, y: 190, width: 200, height: 130)
    for g in [doorGlass, window] { fill(ctx, g, Color(red: 0.08, green: 0.10, blue: 0.20)) }
    for k in 0..<5 {
        ctx.fill(circle(CGPoint(x: window.minX + 20 + Double(k) * 40, y: window.minY + 30 + Double(k % 2) * 25), 2), with: .color(Color(red: 1, green: 0.9, blue: 0.6).opacity(0.7)))
    }
    if now >= policeT0 {
        // Red and blue lights flashing outside.
        let red = Int(t * 4) % 2 == 0
        for g in [doorGlass, window] { fill(ctx, g, (red ? Color.red : Color.blue).opacity(0.55)) }
        ctx.fill(Path(CGRect(x: 0, y: 0, width: Stage.W, height: Stage.H)), with: .color((red ? Color.red : Color.blue).opacity(0.08)))
    }
    ctx.stroke(Path(window), with: .color(darkWood), lineWidth: 6)
    fill(ctx, CGRect(x: window.midX - 2, y: window.minY, width: 4, height: window.height), darkWood)
    ctx.fill(circle(CGPoint(x: door.maxX - 12, y: door.midY + 10), 4), with: .color(Color(red: 0.85, green: 0.70, blue: 0.30)))

    // A neon beer sign that ends up hanging crooked
    var sign = ctx
    sign.translateBy(x: 470, y: 150)
    if r > BarWreck.signAt { sign.rotate(by: .degrees(min(1, (r - BarWreck.signAt) * 3) * 24)) }
    fill(sign, CGRect(x: -60, y: -26, width: 120, height: 52), Color(white: 0.08), corner: 8)
    sign.draw(Text("COLD BEER").font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.3, green: 0.9, blue: 1).opacity(flick)), at: .zero)

    // The back bar: a mirror and three shelves of bottles
    let back = CGRect(x: 610, y: 120, width: 470, height: 230)
    fill(ctx, back, Color(red: 0.55, green: 0.65, blue: 0.70).opacity(0.5))
    let bottleColors = [Color(red: 0.25, green: 0.55, blue: 0.25), Color(red: 0.55, green: 0.30, blue: 0.12), Color(red: 0.75, green: 0.75, blue: 0.80),
                        Color(red: 0.70, green: 0.15, blue: 0.15), Color(red: 0.85, green: 0.65, blue: 0.20)]
    let total = 3 * 13
    let fallen = r > BarWreck.bottlesFrom ? Int(Double(total) * min(1, (r - BarWreck.bottlesFrom) / (BarWreck.bottlesTo - BarWreck.bottlesFrom))) : 0
    for shelf in 0..<3 {
        let y = back.minY + 70 + Double(shelf) * 70
        fill(ctx, CGRect(x: back.minX, y: y, width: back.width, height: 7), darkWood)
        for k in 0..<13 {
            let idx = shelf * 13 + k
            // They go in a scattered order, as he sweeps them off.
            guard (idx * 7) % total >= fallen else { continue }
            let x = back.minX + 18 + Double(k) * 34
            let c = bottleColors[(idx * 3) % bottleColors.count]
            fill(ctx, CGRect(x: x, y: y - 44, width: 16, height: 44), c.opacity(0.9), corner: 4)
            fill(ctx, CGRect(x: x + 5, y: y - 58, width: 6, height: 16), c.opacity(0.9), corner: 2)
            fill(ctx, CGRect(x: x + 2, y: y - 32, width: 12, height: 12), .white.opacity(0.7), corner: 1)
        }
    }

    // Hanging lamps that swing once the brawl starts
    for (i, x) in [250.0, 450.0].enumerated() {
        let swing = r > 0 ? sin(t * 3 + Double(i)) * 12 * exp(-max(0, r - 5) * 0.1) : 0
        var lamp = ctx
        lamp.translateBy(x: x, y: 0)
        lamp.rotate(by: .degrees(swing))
        fill(lamp, CGRect(x: -1, y: 0, width: 2, height: 230), Color(white: 0.15))
        var shade = Path()
        shade.move(to: CGPoint(x: -26, y: 255)); shade.addLine(to: CGPoint(x: -10, y: 228)); shade.addLine(to: CGPoint(x: 10, y: 228)); shade.addLine(to: CGPoint(x: 26, y: 255))
        shade.closeSubpath()
        lamp.fill(shade, with: .color(Color(red: 0.15, green: 0.35, blue: 0.20)))
        lamp.fill(Path(ellipseIn: CGRect(x: -10, y: 250, width: 20, height: 10)), with: .color(Color(red: 1, green: 0.92, blue: 0.6)))
    }

    // Tables and chairs, flipped over when he gets to them
    for table in BarWreck.tables {
        let tc = Color(red: 0.50, green: 0.32, blue: 0.18)
        if r > table.at {
            // On its side, legs pointing at the window
            fill(ctx, CGRect(x: table.x - 12, y: Stage.floorY - 90, width: 16, height: 90), tc, corner: 4)
            fill(ctx, CGRect(x: table.x + 4, y: Stage.floorY - 52, width: 56, height: 8), darkWood)
        } else {
            ctx.fill(Path(ellipseIn: CGRect(x: table.x - 55, y: Stage.floorY - 82, width: 110, height: 18)), with: .color(tc))
            fill(ctx, CGRect(x: table.x - 4, y: Stage.floorY - 70, width: 8, height: 70), darkWood)
            fill(ctx, CGRect(x: table.x - 26, y: Stage.floorY - 6, width: 52, height: 6), darkWood)
            fill(ctx, CGRect(x: table.x - 10, y: Stage.floorY - 100, width: 20, height: 20), Color(red: 0.95, green: 0.75, blue: 0.20).opacity(0.85), corner: 3)
        }
        for side in [-1.0, 1.0] {
            let cx = table.x + side * 75
            if r > BarWreck.chairsAt {
                fill(ctx, CGRect(x: cx - 30, y: Stage.floorY - 12, width: 60, height: 8), darkWood, corner: 2)
                fill(ctx, CGRect(x: cx - 30, y: Stage.floorY - 20, width: 8, height: 14), darkWood)
            } else {
                fill(ctx, CGRect(x: cx - 18, y: Stage.floorY - 48, width: 36, height: 6), darkWood)
                fill(ctx, CGRect(x: cx + side * 14 - 3, y: Stage.floorY - 92, width: 6, height: 48), darkWood)
                for lx in [cx - 15, cx + 12] { fill(ctx, CGRect(x: lx, y: Stage.floorY - 44, width: 4, height: 44), darkWood) }
            }
        }
    }
}

/// The front of the bar counter and the stools, drawn over the bartender standing behind it.
func drawBarCounter(_ ctx: GraphicsContext, rampageT0: Date, now: Date) {
    let r = now.timeIntervalSince(rampageT0)
    let top = Color(red: 0.30, green: 0.18, blue: 0.10)
    let front = CGRect(x: 590, y: Stage.floorY - 100, width: 510, height: 100)
    fill(ctx, CGRect(x: front.minX - 10, y: front.minY - 12, width: front.width + 20, height: 14), top, corner: 3)
    fill(ctx, front, Color(red: 0.42, green: 0.26, blue: 0.14))
    for x in stride(from: front.minX + 20, to: front.maxX, by: 70) {
        ctx.stroke(Path(roundedRect: CGRect(x: x, y: front.minY + 16, width: 50, height: 66), cornerRadius: 4), with: .color(top), lineWidth: 3)
    }
    fill(ctx, CGRect(x: front.minX, y: front.maxY - 10, width: front.width, height: 4), Color(red: 0.75, green: 0.60, blue: 0.30))
    // Stools: upright, or kicked over onto the floor
    let stoolTop = Color(red: 0.60, green: 0.12, blue: 0.12)
    for stool in BarWreck.stools {
        if r > stool.at {
            var s = ctx
            s.translateBy(x: stool.x, y: Stage.floorY - 10)
            s.rotate(by: .degrees(84))
            fill(s, CGRect(x: -3, y: -64, width: 6, height: 64), Color(white: 0.7))
            fill(s, CGRect(x: -20, y: -72, width: 40, height: 10), stoolTop, corner: 5)
        } else {
            fill(ctx, CGRect(x: stool.x - 3, y: Stage.floorY - 66, width: 6, height: 66), Color(white: 0.7))
            fill(ctx, CGRect(x: stool.x - 16, y: Stage.floorY - 4, width: 32, height: 4), Color(white: 0.6), corner: 2)
            fill(ctx, CGRect(x: stool.x - 20, y: Stage.floorY - 74, width: 40, height: 10), stoolTop, corner: 5)
        }
    }
    // Smashed glass and spilled drinks on the floor
    if r > BarWreck.bottlesFrom {
        let u = min(1, (r - BarWreck.bottlesFrom) / (BarWreck.bottlesTo - BarWreck.bottlesFrom))
        for k in 0..<Int(30 * u) {
            let x = 600 + Double((k * 97) % 480)
            let y = Stage.floorY + 6 + Double((k * 37) % 70)
            var shard = Path()
            shard.move(to: CGPoint(x: x, y: y)); shard.addLine(to: CGPoint(x: x + 6, y: y + 3)); shard.addLine(to: CGPoint(x: x + 1, y: y + 7)); shard.closeSubpath()
            ctx.fill(shard, with: .color([Color(red: 0.4, green: 0.7, blue: 0.4), Color(red: 0.7, green: 0.5, blue: 0.3), Color(white: 0.85)][k % 3].opacity(0.85)))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: 700, y: Stage.floorY + 20, width: 160 * u, height: 24 * u)), with: .color(Color(red: 0.85, green: 0.65, blue: 0.20).opacity(0.35)))
    }
}
