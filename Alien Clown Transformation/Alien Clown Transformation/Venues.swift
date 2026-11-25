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
        case .wildwood: Color(red: 0.95, green: 0.30, blue: 0.55)
        case .oceanCity: Color(red: 0.10, green: 0.35, blue: 0.70)
        case .greatStirrupCay: Color(red: 0.00, green: 0.48, blue: 0.72)
        case .nassau: Color(red: 0.00, green: 0.55, blue: 0.62)
        case .bimini: Color(red: 0.08, green: 0.42, blue: 0.70)
        case .cocoCay: Color(red: 0.00, green: 0.60, blue: 0.65)
        case .catalina: Color(red: 0.80, green: 0.25, blue: 0.20)
        case .stKitts: Color(red: 0.00, green: 0.55, blue: 0.30)
        case .pisa: Color(red: 0.00, green: 0.50, blue: 0.27)
        case .paris: Color(red: 0.10, green: 0.20, blue: 0.62)
        case .laBufadora: Color(red: 0.75, green: 0.30, blue: 0.15)
        }
    }

    var banner: String { "S.S. BIG TOP CRUISES  ·  \(shortName.uppercased())  ·  $\(price)  ·  KIDS $\(kidPrice)" }
}

func drawVenue(_ ctx: GraphicsContext, _ venue: Venue, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    switch venue {
    case .wildwood: drawWildwood(ctx, t: t)
    case .oceanCity: drawOceanCity(ctx, t: t)
    case .greatStirrupCay: drawGreatStirrupCay(ctx, t: t)
    case .nassau: drawNassau(ctx, t: t)
    case .bimini: drawBimini(ctx, t: t)
    case .cocoCay: drawCocoCay(ctx, t: t)
    case .catalina: drawCatalina(ctx, t: t)
    case .stKitts: drawStKitts(ctx, t: t)
    case .pisa: drawPisa(ctx, t: t)
    case .paris: drawParis(ctx, t: t)
    case .laBufadora: drawLaBufadora(ctx, t: t)
    }
    drawHarbor(ctx, t: t)
    let label = ctx.resolve(Text(venue.banner).font(.system(size: 20, weight: .black, design: .rounded)).foregroundStyle(.white))
    let size = label.measure(in: CGSize(width: 1200, height: 60))
    let r = CGRect(x: 600 - size.width / 2 - 16, y: 18, width: size.width + 32, height: size.height + 12)
    fill(ctx, r, venue.accent.opacity(0.9), corner: r.height / 2)
    ctx.draw(label, at: CGPoint(x: r.midX, y: r.midY))
}

/// The cruise terminal at every port: a basin of harbour water on the left where the S.S. Big Top ties up,
/// and a stone quay along the front with bollards, where the gangway comes down.
private func drawHarbor(_ ctx: GraphicsContext, t: Double) {
    let top = 352.0, quay = 452.0, right = 620.0
    var basin = Path()
    basin.move(to: CGPoint(x: 0, y: top))
    basin.addLine(to: CGPoint(x: right - 40, y: top))
    basin.addQuadCurve(to: CGPoint(x: right, y: quay), control: CGPoint(x: right, y: top))
    basin.addLine(to: CGPoint(x: 0, y: quay))
    basin.closeSubpath()
    ctx.fill(basin, with: .linearGradient(Gradient(colors: [Color(red: 0.12, green: 0.42, blue: 0.70), Color(red: 0.28, green: 0.64, blue: 0.80)]),
                                          startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: quay)))
    var waves = ctx
    waves.clip(to: basin)
    for k in 0..<5 {
        var wave = Path()
        let y = top + 12 + Double(k) * 19
        for x in stride(from: 0.0, through: right, by: 10) {
            let pt = CGPoint(x: x, y: y + sin(x / 26 + t * 1.4 + Double(k)) * 2)
            x == 0 ? wave.move(to: pt) : wave.addLine(to: pt)
        }
        waves.stroke(wave, with: .color(.white.opacity(0.3)), lineWidth: 1.3)
    }
    // The quay: a stone apron with a dark edge and a row of bollards
    fill(ctx, CGRect(x: 0, y: quay, width: right + 60, height: Stage.floorY - quay + 4), Color(red: 0.70, green: 0.68, blue: 0.64))
    fill(ctx, CGRect(x: 0, y: quay, width: right + 60, height: 5), Color(red: 0.42, green: 0.40, blue: 0.38))
    for x in stride(from: 30.0, to: right + 60, by: 48) {
        fill(ctx, CGRect(x: x, y: quay + 8, width: 1.2, height: Stage.floorY - quay - 8), Color(white: 0.55))
    }
    for x in [70.0, 250.0, 430.0] {
        fill(ctx, CGRect(x: x - 7, y: quay + 4, width: 14, height: 16), Color(red: 0.22, green: 0.22, blue: 0.26), corner: 4)
        fill(ctx, CGRect(x: x - 10, y: quay + 2, width: 20, height: 5), Color(red: 0.30, green: 0.30, blue: 0.34), corner: 2)
    }
    // A little sign by the gangway
    let sx = Stage.venueTentX + Stage.gangwayFootDX + 40
    fill(ctx, CGRect(x: sx - 1.5, y: Stage.floorY - 70, width: 3, height: 70), Color(red: 0.45, green: 0.30, blue: 0.18))
    fill(ctx, CGRect(x: sx - 34, y: Stage.floorY - 92, width: 68, height: 26), Color(red: 1.0, green: 0.35, blue: 0.70), corner: 4)
    ctx.draw(Text("S.S. BIG TOP\nBOARDING").font(.system(size: 8, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: sx, y: Stage.floorY - 79))
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

// MARK: Ocean City, Great Stirrup Cay and St. Kitts

/// Ocean City, New Jersey: the boardwalk, the Spanish-style Music Pier with its red tile roof,
/// a Ferris wheel on the amusement pier, taffy and fudge shops, and a lifeguard stand on the sand.
private func drawOceanCity(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 300, color: Color(red: 0.18, green: 0.48, blue: 0.70))
    fill(ctx, CGRect(x: 0, y: 360, width: Stage.W, height: 50), Color(red: 0.95, green: 0.88, blue: 0.70))

    // The Music Pier: cream stucco, arched windows, a red tile roof and a little tower over the entrance
    let stucco = Color(red: 0.98, green: 0.93, blue: 0.80)
    let tile = Color(red: 0.78, green: 0.30, blue: 0.20)
    fill(ctx, CGRect(x: 640, y: 290, width: 260, height: 115), stucco)
    var roof = Path()
    roof.move(to: CGPoint(x: 628, y: 292))
    roof.addLine(to: CGPoint(x: 660, y: 262))
    roof.addLine(to: CGPoint(x: 880, y: 262))
    roof.addLine(to: CGPoint(x: 912, y: 292))
    roof.closeSubpath()
    ctx.fill(roof, with: .color(tile))
    for x in stride(from: 664.0, to: 880, by: 10) { fill(ctx, CGRect(x: x, y: 264, width: 1.5, height: 26), Color(red: 0.62, green: 0.22, blue: 0.15)) }
    fill(ctx, CGRect(x: 744, y: 222, width: 52, height: 42), stucco)
    var cap = Path()
    cap.move(to: CGPoint(x: 738, y: 224))
    cap.addLine(to: CGPoint(x: 770, y: 198))
    cap.addLine(to: CGPoint(x: 802, y: 224))
    cap.closeSubpath()
    ctx.fill(cap, with: .color(tile))
    ctx.fill(circle(CGPoint(x: 770, y: 242), 9), with: .color(Color(red: 0.30, green: 0.50, blue: 0.75)))
    for x in stride(from: 656.0, to: 890, by: 30) {
        var arch = Path()
        arch.addRoundedRect(in: CGRect(x: x, y: 318, width: 20, height: 34), cornerSize: CGSize(width: 10, height: 10))
        ctx.fill(arch, with: .color(Color(red: 0.30, green: 0.50, blue: 0.75)))
    }
    fill(ctx, CGRect(x: 700, y: 296, width: 140, height: 18), Color(red: 0.10, green: 0.35, blue: 0.70), corner: 4)
    ctx.draw(Text("MUSIC PIER").font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 770, y: 305))
    for x in [652.0, 888] { fill(ctx, CGRect(x: x - 6, y: 360, width: 12, height: 45), stucco) }

    // The Ferris wheel on the amusement pier
    let hub = CGPoint(x: 1065, y: 225)
    let r = 100.0
    for side in [-1.0, 1.0] {
        var leg = Path()
        leg.move(to: hub)
        leg.addLine(to: CGPoint(x: hub.x + side * 52, y: 405))
        ctx.stroke(leg, with: .color(Color(white: 0.88)), lineWidth: 6)
    }
    ctx.stroke(circle(hub, r), with: .color(Color(red: 0.10, green: 0.35, blue: 0.70)), lineWidth: 5)
    let spin = t * 0.22
    let cars: [Color] = [.red, .yellow, Color(red: 0.20, green: 0.70, blue: 0.40), .orange, .pink, .cyan]
    for i in 0..<12 {
        let a = spin + Double(i) / 12 * 2 * .pi
        let rim = CGPoint(x: hub.x + cos(a) * r, y: hub.y + sin(a) * r)
        var spoke = Path()
        spoke.move(to: hub)
        spoke.addLine(to: rim)
        ctx.stroke(spoke, with: .color(.white.opacity(0.85)), lineWidth: 1.5)
        // Rim lights chase round after dark... and in daylight too
        ctx.fill(circle(rim, 2.5), with: .color((i + Int(t * 4)) % 3 == 0 ? .white : .yellow))
        fill(ctx, CGRect(x: rim.x - 8, y: rim.y + 2, width: 16, height: 13), cars[i % cars.count], corner: 4)
    }
    ctx.fill(circle(hub, 9), with: .color(Color(red: 0.95, green: 0.30, blue: 0.30)))

    // The lifeguard stand on the beach, OCBP on the side
    let lg = 945.0
    for dx in [0.0, 30] {
        var leg = Path()
        leg.move(to: CGPoint(x: lg + dx, y: 404))
        leg.addLine(to: CGPoint(x: lg + 15 + (dx - 15) * 0.6, y: 340))
        ctx.stroke(leg, with: .color(.white), lineWidth: 4)
    }
    fill(ctx, CGRect(x: lg - 2, y: 332, width: 34, height: 12), .white, corner: 2)
    ctx.draw(Text("OCBP").font(.system(size: 8, weight: .black, design: .rounded)).foregroundStyle(.red), at: CGPoint(x: lg + 15, y: 338))
    fill(ctx, CGRect(x: lg + 13, y: 300, width: 3, height: 32), .white)
    var flag = Path()
    flag.move(to: CGPoint(x: lg + 16, y: 300))
    flag.addLine(to: CGPoint(x: lg + 34 + sin(t * 3) * 2, y: 306))
    flag.addLine(to: CGPoint(x: lg + 16, y: 312))
    flag.closeSubpath()
    ctx.fill(flag, with: .color(.red))

    // Boardwalk shops: salt water taffy, fudge and fries
    let shops: [(x: Double, w: Double, wall: Color, name: String, awning: Color)] = [
        (0, 110, Color(red: 0.98, green: 0.88, blue: 0.92), "TAFFY", Color(red: 0.90, green: 0.35, blue: 0.60)),
        (114, 100, Color(red: 0.92, green: 0.88, blue: 0.75), "FUDGE", Color(red: 0.55, green: 0.32, blue: 0.20)),
        (1140, 60, Color(red: 0.98, green: 0.95, blue: 0.75), "FRIES", Color(red: 0.95, green: 0.65, blue: 0.10)),
    ]
    for shop in shops {
        fill(ctx, CGRect(x: shop.x, y: 310, width: shop.w, height: 95), shop.wall)
        fill(ctx, CGRect(x: shop.x + 6, y: 316, width: shop.w - 12, height: 20), shop.awning, corner: 4)
        ctx.draw(Text(shop.name).font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: shop.x + shop.w / 2, y: 326))
        for k in 0..<Int(shop.w / 14) {
            fill(ctx, CGRect(x: shop.x + Double(k) * 14, y: 342, width: 14, height: 14), k % 2 == 0 ? shop.awning : .white)
        }
        fill(ctx, CGRect(x: shop.x + 10, y: 362, width: shop.w - 20, height: 30), Color(red: 0.30, green: 0.25, blue: 0.25), corner: 2)
    }

    // The boards and the railing
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.72, green: 0.58, blue: 0.40))
    for x in stride(from: 0.0, to: Stage.W, by: 26) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.58, green: 0.45, blue: 0.30)) }
    fill(ctx, CGRect(x: 0, y: 398, width: Stage.W, height: 3), Color(white: 0.92))
    for x in stride(from: 0.0, to: Stage.W, by: 40) { fill(ctx, CGRect(x: x, y: 398, width: 3, height: 12), Color(white: 0.92)) }
    // A surrey bike pedalling along the boards
    let bx = (t * 38).truncatingRemainder(dividingBy: Stage.W + 200) - 100
    fill(ctx, CGRect(x: bx, y: 414, width: 60, height: 10), Color(red: 0.10, green: 0.35, blue: 0.70), corner: 3)
    for k in 0..<8 { fill(ctx, CGRect(x: bx - 4 + Double(k) * 9, y: 396, width: 9, height: 6), k % 2 == 0 ? .red : .white) }
    for px in [bx, bx + 58] { fill(ctx, CGRect(x: px, y: 400, width: 2, height: 14), Color(white: 0.85)) }
    for wx in [bx + 10, bx + 50] { ctx.stroke(circle(CGPoint(x: wx, y: 430), 7), with: .color(Color(white: 0.15)), lineWidth: 2.5) }
    sign(ctx, "OCEAN CITY · AMERICA'S GREATEST FAMILY RESORT", at: CGRect(x: 655, y: 366, width: 230, height: 22),
         bg: Color(red: 0.10, green: 0.35, blue: 0.70), size: 9)
    gulls(ctx, t: t)
}

/// Great Stirrup Cay in the Berry Islands: turquoise shallows, the old white lighthouse on its rocky point,
/// a tender boat shuttling to a ship anchored offshore, beach cabanas, hammocks and palms.
private func drawGreatStirrupCay(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 285, color: Color(red: 0.22, green: 0.80, blue: 0.84))
    fill(ctx, CGRect(x: 0, y: 285, width: Stage.W, height: 24), Color(red: 0.06, green: 0.40, blue: 0.72))
    // A ship at anchor out on the deep blue, its tender boat running back and forth
    cruiseShip(ctx, x: 620, waterline: 300, width: 300, hull: Color(red: 0.10, green: 0.20, blue: 0.45), t: t) { ctx, r in
        fill(ctx, r, .white, corner: 3)
        fill(ctx, CGRect(x: r.minX, y: r.minY + 6, width: r.width, height: 5), Color(red: 0.10, green: 0.45, blue: 0.80))
    }
    let run = (t * 0.06).truncatingRemainder(dividingBy: 2)
    let u = run < 1 ? run : 2 - run
    let tx = 900 - u * 200, ty = 312 + u * 40
    fill(ctx, CGRect(x: tx, y: ty, width: 46, height: 11), .white, corner: 5)
    fill(ctx, CGRect(x: tx + 8, y: ty - 9, width: 30, height: 10), Color(red: 0.98, green: 0.80, blue: 0.20), corner: 3)

    // The rocky point and the 1863 lighthouse
    var point = Path()
    point.move(to: CGPoint(x: 960, y: 330))
    point.addQuadCurve(to: CGPoint(x: Stage.W, y: 250), control: CGPoint(x: 1060, y: 250))
    point.addLine(to: CGPoint(x: Stage.W, y: 340))
    point.closeSubpath()
    ctx.fill(point, with: .color(Color(red: 0.62, green: 0.58, blue: 0.48)))
    for (x, y, rr) in [(1010.0, 300.0, 22.0), (1150.0, 262.0, 30.0), (1185.0, 290.0, 26.0)] {
        ctx.fill(circle(CGPoint(x: x, y: y), rr), with: .color(Color(red: 0.25, green: 0.55, blue: 0.28)))
    }
    let lx = 1095.0
    var tower = Path()
    tower.move(to: CGPoint(x: lx - 16, y: 262))
    tower.addLine(to: CGPoint(x: lx - 10, y: 130))
    tower.addLine(to: CGPoint(x: lx + 10, y: 130))
    tower.addLine(to: CGPoint(x: lx + 16, y: 262))
    tower.closeSubpath()
    ctx.fill(tower, with: .color(.white))
    fill(ctx, CGRect(x: lx - 16, y: 120, width: 32, height: 10), Color(white: 0.25), corner: 2)
    fill(ctx, CGRect(x: lx - 9, y: 102, width: 18, height: 18), Color(red: 1, green: 0.95, blue: 0.60).opacity(0.7 + 0.3 * sin(t * 2)), corner: 2)
    var dome = Path()
    dome.addArc(center: CGPoint(x: lx, y: 102), radius: 11, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
    ctx.fill(dome, with: .color(Color(white: 0.25)))
    for y in [170.0, 215] { fill(ctx, CGRect(x: lx - 4, y: y, width: 8, height: 12), Color(white: 0.35), corner: 2) }
    // The lamp's beam sweeping round
    let beam = sin(t * 0.8)
    var ray = Path()
    ray.move(to: CGPoint(x: lx, y: 111))
    ray.addLine(to: CGPoint(x: lx + beam * 160, y: 90))
    ray.addLine(to: CGPoint(x: lx + beam * 160, y: 130))
    ray.closeSubpath()
    ctx.fill(ray, with: .color(.white.opacity(0.18 * abs(beam))))

    // White sand, beach cabanas and a hammock between palms
    fill(ctx, CGRect(x: 0, y: 360, width: Stage.W, height: 50), Color(red: 0.99, green: 0.96, blue: 0.88))
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.98, green: 0.94, blue: 0.84))
    for (i, c) in [Color(red: 0.10, green: 0.45, blue: 0.80), Color(red: 0.95, green: 0.55, blue: 0.20)].enumerated() {
        let x = 770 + Double(i) * 86
        fill(ctx, CGRect(x: x, y: 342, width: 72, height: 56), .white, corner: 2)
        var top = Path()
        top.move(to: CGPoint(x: x - 6, y: 344))
        top.addLine(to: CGPoint(x: x + 36, y: 318))
        top.addLine(to: CGPoint(x: x + 78, y: 344))
        top.closeSubpath()
        ctx.fill(top, with: .color(c))
        for k in 0..<4 { fill(ctx, CGRect(x: x + 4 + Double(k) * 17, y: 346, width: 8, height: 50), c.opacity(0.35)) }
    }
    palm(ctx, x: 940, base: 404, height: 140, t: t)
    palm(ctx, x: 1150, base: 404, height: 120, t: t + 1.5)
    var hammock = Path()
    hammock.move(to: CGPoint(x: 962, y: 330))
    hammock.addQuadCurve(to: CGPoint(x: 1150, y: 340), control: CGPoint(x: 1056, y: 372 + sin(t * 1.2) * 4))
    ctx.stroke(hammock, with: .color(Color(red: 0.95, green: 0.35, blue: 0.40)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
    beachUmbrella(ctx, x: 1060, Color(red: 0.98, green: 0.80, blue: 0.20))
    sign(ctx, "GREAT STIRRUP CAY", at: CGRect(x: 630, y: 344, width: 120, height: 26),
         bg: Color(red: 0.00, green: 0.48, blue: 0.72), size: 10)
    gulls(ctx, t: t)
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


// MARK: Catalina

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

// MARK: Wildwood

/// A beach ball as tall as a person, like the ones in front of the Wildwoods sign.
private func beachBall(_ ctx: GraphicsContext, at c: CGPoint, radius r: Double) {
    let colors: [Color] = [.red, .white, .yellow, .white, Color(red: 0.15, green: 0.45, blue: 0.85), .white]
    for (i, color) in colors.enumerated() {
        var wedge = Path()
        wedge.move(to: c)
        wedge.addArc(center: c, radius: r, startAngle: .degrees(Double(i) * 60 - 20), endAngle: .degrees(Double(i + 1) * 60 - 20), clockwise: false)
        wedge.closeSubpath()
        ctx.fill(wedge, with: .color(color))
    }
    ctx.fill(circle(c, r * 0.16), with: .color(.white))
    ctx.stroke(circle(c, r), with: .color(.black.opacity(0.2)), lineWidth: 1)
}

/// Wildwood, New Jersey: the boardwalk, an amusement pier with a Ferris wheel and a wooden coaster,
/// the Wildwoods sign with its giant beach balls, and the tram car rolling along the boards.
private func drawWildwood(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 300, color: Color(red: 0.16, green: 0.50, blue: 0.72))
    fill(ctx, CGRect(x: 0, y: 360, width: Stage.W, height: 50), Color(red: 0.95, green: 0.88, blue: 0.70))

    // The wooden coaster out on the pier
    let track = Color(red: 0.85, green: 0.20, blue: 0.20)
    func coasterY(_ x: Double) -> Double { 290 - 85 * pow(sin((x - 470) / 330 * .pi * 1.5), 2) - (x - 470) * 0.04 }
    for x in stride(from: 480.0, through: 800, by: 20) {
        fill(ctx, CGRect(x: x - 1, y: coasterY(x), width: 2, height: 405 - coasterY(x)), .white.opacity(0.9))
    }
    for y in stride(from: 250.0, to: 405, by: 30) { fill(ctx, CGRect(x: 480, y: y, width: 320, height: 1.5), .white.opacity(0.6)) }
    var rail = Path()
    for x in stride(from: 470.0, through: 810, by: 5) {
        let pt = CGPoint(x: x, y: coasterY(x))
        x == 470 ? rail.move(to: pt) : rail.addLine(to: pt)
    }
    ctx.stroke(rail, with: .color(track), lineWidth: 4)
    let carX = 480 + (t * 60).truncatingRemainder(dividingBy: 320)
    for k in 0..<3 {
        let x = carX - Double(k) * 16
        guard x > 472 else { continue }
        fill(ctx, CGRect(x: x - 7, y: coasterY(x) - 10, width: 13, height: 8), Color(red: 1, green: 0.82, blue: 0.20), corner: 2)
    }

    // The Ferris wheel
    let hub = CGPoint(x: 1010, y: 235)
    let r = 105.0
    for side in [-1.0, 1.0] {
        var leg = Path()
        leg.move(to: hub)
        leg.addLine(to: CGPoint(x: hub.x + side * 55, y: 405))
        ctx.stroke(leg, with: .color(Color(white: 0.85)), lineWidth: 6)
    }
    ctx.stroke(circle(hub, r), with: .color(Color(red: 0.95, green: 0.30, blue: 0.55)), lineWidth: 5)
    ctx.stroke(circle(hub, r * 0.62), with: .color(.white.opacity(0.8)), lineWidth: 2)
    let spin = t * 0.25
    let cars: [Color] = [.red, .yellow, .cyan, .green, .orange, .purple]
    for i in 0..<12 {
        let a = spin + Double(i) / 12 * 2 * .pi
        let rim = CGPoint(x: hub.x + cos(a) * r, y: hub.y + sin(a) * r)
        var spoke = Path()
        spoke.move(to: hub)
        spoke.addLine(to: rim)
        ctx.stroke(spoke, with: .color(.white.opacity(0.85)), lineWidth: 1.5)
        fill(ctx, CGRect(x: rim.x - 8, y: rim.y, width: 16, height: 13), cars[i % cars.count], corner: 4)
    }
    ctx.fill(circle(hub, 9), with: .color(Color(red: 1, green: 0.82, blue: 0.20)))

    // Boardwalk shops under striped awnings
    let shops: [(x: Double, w: Double, wall: Color, name: String, awning: Color)] = [
        (0, 105, Color(red: 0.98, green: 0.90, blue: 0.70), "PIZZA", Color(red: 0.85, green: 0.15, blue: 0.15)),
        (108, 100, Color(red: 0.80, green: 0.92, blue: 0.95), "FUDGE", Color(red: 0.95, green: 0.45, blue: 0.70)),
        (1130, 70, Color(red: 0.95, green: 0.85, blue: 0.95), "ARCADE", Color(red: 0.20, green: 0.50, blue: 0.85)),
    ]
    for shop in shops {
        fill(ctx, CGRect(x: shop.x, y: 310, width: shop.w, height: 95), shop.wall)
        fill(ctx, CGRect(x: shop.x + 6, y: 316, width: shop.w - 12, height: 20), shop.awning, corner: 4)
        ctx.draw(Text(shop.name).font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: shop.x + shop.w / 2, y: 326))
        for k in 0..<Int(shop.w / 14) {
            fill(ctx, CGRect(x: shop.x + Double(k) * 14, y: 342, width: 14, height: 14), k % 2 == 0 ? shop.awning : .white)
        }
        fill(ctx, CGRect(x: shop.x + 10, y: 362, width: shop.w - 20, height: 30), Color(red: 0.30, green: 0.25, blue: 0.25), corner: 2)
    }

    // The boards
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.74, green: 0.60, blue: 0.42))
    for x in stride(from: 0.0, to: Stage.W, by: 26) { fill(ctx, CGRect(x: x, y: 405, width: 1.5, height: Stage.H - 405), Color(red: 0.60, green: 0.47, blue: 0.32)) }
    fill(ctx, CGRect(x: 0, y: 398, width: Stage.W, height: 3), Color(white: 0.92))
    for x in stride(from: 0.0, to: Stage.W, by: 40) { fill(ctx, CGRect(x: x, y: 398, width: 3, height: 12), Color(white: 0.92)) }

    // WILDWOODS in big block letters, with beach balls
    let letters = Array("WILDWOODS")
    let tints: [Color] = [.red, Color(red: 0.15, green: 0.45, blue: 0.85), Color(red: 1, green: 0.75, blue: 0.10), Color(red: 0.20, green: 0.65, blue: 0.35), Color(red: 0.95, green: 0.45, blue: 0.70)]
    for (i, ch) in letters.enumerated() {
        ctx.draw(Text(String(ch)).font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(tints[i % tints.count]),
                 at: CGPoint(x: 236 + Double(i) * 24, y: 380))
    }
    beachBall(ctx, at: CGPoint(x: 210, y: 388), radius: 15)
    beachBall(ctx, at: CGPoint(x: 452, y: 390), radius: 13)

    // "Watch the tram car, please!"
    let lead = (t * 45).truncatingRemainder(dividingBy: Stage.W + 300) - 220
    for k in 0..<3 {
        let x = lead + Double(k) * 62
        fill(ctx, CGRect(x: x, y: 412, width: 56, height: 18), k == 2 ? Color(red: 0.15, green: 0.40, blue: 0.80) : Color(red: 1, green: 0.82, blue: 0.15), corner: 3)
        fill(ctx, CGRect(x: x - 2, y: 398, width: 60, height: 4), Color(red: 0.15, green: 0.40, blue: 0.80), corner: 2)
        for px in [x + 2, x + 27, x + 52] { fill(ctx, CGRect(x: px, y: 400, width: 2, height: 13), Color(white: 0.9)) }
        for wx in [x + 12, x + 44] { ctx.fill(circle(CGPoint(x: wx, y: 432), 4), with: .color(Color(white: 0.15))) }
    }
    gulls(ctx, t: t)
}

// MARK: Nassau

/// The Queen's Staircase in Nassau: sixty-odd steps cut into a deep limestone canyon,
/// a waterfall tumbling down beside them, and jungle spilling over the rim.
private func drawNassau(_ ctx: GraphicsContext, t: Double) {
    let stone = Color(red: 0.74, green: 0.70, blue: 0.58)
    let shade = Color(red: 0.56, green: 0.53, blue: 0.44)
    // Trees along the rim, seen through the gap
    for (x, y, r) in [(640.0, 96.0, 44.0), (720.0, 80.0, 52.0), (810.0, 88.0, 46.0), (890.0, 100.0, 40.0)] {
        ctx.fill(circle(CGPoint(x: x, y: y), r), with: .color(Color(red: 0.20, green: 0.50, blue: 0.24)))
    }

    // The staircase climbing to daylight, narrower the higher it goes
    let steps = 22
    for i in 0..<steps {
        let u0 = Double(i) / Double(steps), u1 = Double(i + 1) / Double(steps)
        func edge(_ u: Double) -> (l: Double, r: Double, y: Double) { (640 + 60 * u, 850 - 40 * u, 405 - 275 * pow(u, 0.85)) }
        let a = edge(u0), b = edge(u1)
        var tread = Path()
        tread.move(to: CGPoint(x: a.l, y: a.y))
        tread.addLine(to: CGPoint(x: a.r, y: a.y))
        tread.addLine(to: CGPoint(x: b.r, y: b.y))
        tread.addLine(to: CGPoint(x: b.l, y: b.y))
        tread.closeSubpath()
        ctx.fill(tread, with: .color(i % 2 == 0 ? Color(red: 0.84, green: 0.80, blue: 0.68) : Color(red: 0.66, green: 0.62, blue: 0.52)))
    }

    // The waterfall beside the steps
    var falls = Path()
    falls.move(to: CGPoint(x: 812, y: 130))
    falls.addLine(to: CGPoint(x: 838, y: 130))
    falls.addLine(to: CGPoint(x: 905, y: 405))
    falls.addLine(to: CGPoint(x: 852, y: 405))
    falls.closeSubpath()
    ctx.fill(falls, with: .color(Color(red: 0.62, green: 0.85, blue: 0.95)))
    var streaks = ctx
    streaks.clip(to: falls)
    for i in 0..<14 {
        let k = Double(i)
        let u = (t * 0.7 + k * 0.173).truncatingRemainder(dividingBy: 1)
        let y = 130 + 275 * u
        let x = 822 + 58 * u + sin(k * 2.1) * (6 + 14 * u)
        fill(streaks, CGRect(x: x, y: y, width: 3, height: 26), .white.opacity(0.8), corner: 1.5)
    }
    for i in 0..<5 {
        ctx.fill(circle(CGPoint(x: 858 + Double(i) * 11, y: 402 - abs(sin(t * 5 + Double(i))) * 7), 7), with: .color(.white.opacity(0.75)))
    }

    // Canyon walls, streaked by a century and a half of rain
    var left = Path()
    left.move(to: CGPoint(x: 0, y: 40))
    left.addLine(to: CGPoint(x: 560, y: 60))
    left.addLine(to: CGPoint(x: 700, y: 130))
    left.addLine(to: CGPoint(x: 640, y: 405))
    left.addLine(to: CGPoint(x: 0, y: 405))
    left.closeSubpath()
    var right = Path()
    right.move(to: CGPoint(x: Stage.W, y: 30))
    right.addLine(to: CGPoint(x: 960, y: 70))
    right.addLine(to: CGPoint(x: 838, y: 130))
    right.addLine(to: CGPoint(x: 905, y: 405))
    right.addLine(to: CGPoint(x: Stage.W, y: 405))
    right.closeSubpath()
    for wall in [left, right] {
        ctx.fill(wall, with: .linearGradient(Gradient(colors: [stone, shade]), startPoint: CGPoint(x: 0, y: 40), endPoint: CGPoint(x: 0, y: 405)))
        var marks = ctx
        marks.clip(to: wall)
        for y in stride(from: 90.0, to: 400, by: 44) { fill(marks, CGRect(x: 0, y: y, width: Stage.W, height: 2), shade.opacity(0.7)) }
        for x in stride(from: 40.0, to: Stage.W, by: 95) {
            fill(marks, CGRect(x: x, y: 40, width: 7, height: 150 + (x * 7).truncatingRemainder(dividingBy: 140)), Color(red: 0.36, green: 0.40, blue: 0.30).opacity(0.35), corner: 3)
        }
        // Moss and vines spilling over the rim
        for x in stride(from: 10.0, to: Stage.W, by: 48) {
            marks.fill(circle(CGPoint(x: x, y: 52 + (x * 3).truncatingRemainder(dividingBy: 22)), 30), with: .color(Color(red: 0.22, green: 0.52, blue: 0.26)))
            var vine = Path()
            let len = 50 + (x * 11).truncatingRemainder(dividingBy: 90)
            vine.move(to: CGPoint(x: x + 14, y: 70))
            vine.addQuadCurve(to: CGPoint(x: x + 14 + sin(t + x) * 4, y: 70 + len), control: CGPoint(x: x + 22, y: 70 + len / 2))
            marks.stroke(vine, with: .color(Color(red: 0.18, green: 0.45, blue: 0.22)), lineWidth: 2.5)
        }
    }

    // Stone pavers on the canyon floor
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.70, green: 0.67, blue: 0.58))
    for x in stride(from: 0.0, to: Stage.W, by: 54) { fill(ctx, CGRect(x: x, y: 405, width: 2, height: Stage.H - 405), Color(red: 0.58, green: 0.55, blue: 0.47)) }
    palm(ctx, x: 560, base: 410, height: 150, t: t)
    palm(ctx, x: 1010, base: 410, height: 165, t: t + 1)
    palm(ctx, x: 40, base: 410, height: 170, t: t + 2)
    sign(ctx, "QUEEN'S STAIRCASE · 66 STEPS", at: CGRect(x: 1040, y: 345, width: 150, height: 26), bg: Color(red: 0.00, green: 0.55, blue: 0.62), size: 9)
}

// MARK: Pisa and Paris

/// Pisa's Field of Miracles: the Baptistery, the Duomo, and the bell tower that never stood up straight.
private func drawPisa(_ ctx: GraphicsContext, t: Double) {
    let marble = Color(red: 0.97, green: 0.95, blue: 0.90)
    let shadow = Color(red: 0.80, green: 0.77, blue: 0.70)
    let arch = Color(red: 0.50, green: 0.47, blue: 0.45)
    let tile = Color(red: 0.72, green: 0.42, blue: 0.30)
    // Tuscan hills and cypresses far off
    var hills = Path()
    hills.move(to: CGPoint(x: 0, y: 330))
    hills.addQuadCurve(to: CGPoint(x: 500, y: 310), control: CGPoint(x: 240, y: 250))
    hills.addQuadCurve(to: CGPoint(x: Stage.W, y: 320), control: CGPoint(x: 900, y: 260))
    hills.addLine(to: CGPoint(x: Stage.W, y: 405))
    hills.addLine(to: CGPoint(x: 0, y: 405))
    hills.closeSubpath()
    ctx.fill(hills, with: .color(Color(red: 0.55, green: 0.70, blue: 0.42)))
    for x in [30.0, 58, 1150, 1176] {
        ctx.fill(Path(ellipseIn: CGRect(x: x, y: 270, width: 18, height: 100)), with: .color(Color(red: 0.14, green: 0.36, blue: 0.22)))
    }

    // The Baptistery: a round drum under a ribbed dome
    fill(ctx, CGRect(x: 40, y: 300, width: 130, height: 90), marble)
    for k in 0..<6 {
        var a = Path()
        a.addRoundedRect(in: CGRect(x: 50 + Double(k) * 20, y: 345, width: 11, height: 32), cornerSize: CGSize(width: 5.5, height: 5.5))
        ctx.fill(a, with: .color(arch))
    }
    fill(ctx, CGRect(x: 36, y: 296, width: 138, height: 6), shadow)
    var dome = Path()
    dome.move(to: CGPoint(x: 44, y: 298))
    dome.addQuadCurve(to: CGPoint(x: 166, y: 298), control: CGPoint(x: 105, y: 190))
    dome.closeSubpath()
    ctx.fill(dome, with: .color(tile))
    fill(ctx, CGRect(x: 102, y: 232, width: 6, height: 16), shadow)

    // The Duomo: striped marble nave, a pedimented front, and a dome over the crossing
    fill(ctx, CGRect(x: 500, y: 310, width: 250, height: 80), marble)
    for y in stride(from: 322.0, to: 388, by: 11) { fill(ctx, CGRect(x: 500, y: y, width: 250, height: 2), shadow) }
    fill(ctx, CGRect(x: 496, y: 300, width: 258, height: 12), tile)
    var duomoDome = Path()
    duomoDome.move(to: CGPoint(x: 660, y: 302))
    duomoDome.addQuadCurve(to: CGPoint(x: 740, y: 302), control: CGPoint(x: 700, y: 232))
    duomoDome.closeSubpath()
    ctx.fill(duomoDome, with: .color(Color(red: 0.62, green: 0.66, blue: 0.66)))
    fill(ctx, CGRect(x: 450, y: 290, width: 70, height: 100), marble)
    var pediment = Path()
    pediment.move(to: CGPoint(x: 446, y: 292))
    pediment.addLine(to: CGPoint(x: 485, y: 258))
    pediment.addLine(to: CGPoint(x: 524, y: 292))
    pediment.closeSubpath()
    ctx.fill(pediment, with: .color(marble))
    ctx.stroke(pediment, with: .color(shadow), lineWidth: 2)
    for row in 0..<3 {
        for k in 0..<5 {
            var a = Path()
            a.addRoundedRect(in: CGRect(x: 456 + Double(k) * 12, y: 300 + Double(row) * 22, width: 7, height: 15), cornerSize: CGSize(width: 3.5, height: 3.5))
            ctx.fill(a, with: .color(arch.opacity(0.8)))
        }
    }
    fill(ctx, CGRect(x: 476, y: 366, width: 18, height: 24), Color(red: 0.40, green: 0.30, blue: 0.22), corner: 8)

    // The lawn
    fill(ctx, CGRect(x: 0, y: 385, width: Stage.W, height: 24), Color(red: 0.36, green: 0.66, blue: 0.30))

    // The Leaning Tower, a little under four degrees off plumb
    var tower = ctx
    tower.translateBy(x: 930, y: 398)
    tower.rotate(by: .degrees(4.5))
    fill(tower, CGRect(x: -38, y: -250, width: 76, height: 250), marble)
    fill(tower, CGRect(x: 14, y: -250, width: 24, height: 250), shadow.opacity(0.5))
    // Blind arcade round the base
    for k in 0..<6 {
        var a = Path()
        a.addRoundedRect(in: CGRect(x: -34 + Double(k) * 12, y: -40, width: 8, height: 36), cornerSize: CGSize(width: 4, height: 4))
        tower.fill(a, with: .color(arch.opacity(0.6)))
    }
    // Six open galleries of little columns
    for tier in 0..<6 {
        let y = -46 - Double(tier) * 34
        fill(tower, CGRect(x: -41, y: y - 3, width: 82, height: 5), shadow)
        for k in 0..<8 {
            var a = Path()
            a.addRoundedRect(in: CGRect(x: -36 + Double(k) * 9.3, y: y - 30, width: 6, height: 26), cornerSize: CGSize(width: 3, height: 3))
            tower.fill(a, with: .color(arch))
        }
    }
    fill(tower, CGRect(x: -41, y: -253, width: 82, height: 5), shadow)
    // The belfry on top
    fill(tower, CGRect(x: -28, y: -288, width: 56, height: 36), marble)
    for k in 0..<4 {
        var a = Path()
        a.addRoundedRect(in: CGRect(x: -23 + Double(k) * 13, y: -280, width: 8, height: 24), cornerSize: CGSize(width: 4, height: 4))
        tower.fill(a, with: .color(arch))
    }
    fill(tower, CGRect(x: -31, y: -291, width: 62, height: 5), shadow)
    fill(tower, CGRect(x: -1, y: -312, width: 2, height: 22), Color(white: 0.4))
    // Italy's flag, fluttering
    for (k, c) in [Color(red: 0.0, green: 0.57, blue: 0.27), .white, Color(red: 0.81, green: 0.17, blue: 0.22)].enumerated() {
        fill(tower, CGRect(x: 1 + Double(k) * 7, y: -312 + sin(t * 6 + Double(k)) * 1.2, width: 7, height: 12), c)
    }

    // Pale paving, and a gelato cart
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.88, green: 0.85, blue: 0.78))
    for x in stride(from: 0.0, to: Stage.W, by: 64) { fill(ctx, CGRect(x: x, y: 405, width: 2, height: Stage.H - 405), Color(red: 0.78, green: 0.75, blue: 0.68)) }
    fill(ctx, CGRect(x: 1060, y: 372, width: 70, height: 34), .white, corner: 4)
    for k in 0..<5 { fill(ctx, CGRect(x: 1054 + Double(k) * 16.4, y: 348, width: 16.4, height: 14), k % 2 == 0 ? Color(red: 0.95, green: 0.45, blue: 0.55) : .white) }
    for x in [1058.0, 1130] { fill(ctx, CGRect(x: x, y: 360, width: 2, height: 14), Color(white: 0.6)) }
    ctx.draw(Text("GELATO").font(.system(size: 10, weight: .black, design: .rounded)).foregroundStyle(Color(red: 0.85, green: 0.30, blue: 0.45)), at: CGPoint(x: 1095, y: 389))
    for wx in [1072.0, 1118] { ctx.fill(circle(CGPoint(x: wx, y: 408), 6), with: .color(Color(white: 0.25))) }
    sign(ctx, "TORRE DI PISA", at: CGRect(x: 766, y: 352, width: 110, height: 26), bg: Color(red: 0.0, green: 0.50, blue: 0.27))
    gulls(ctx, t: t)
}

/// Paris: the Eiffel Tower over the Champ de Mars, mansard-roofed apartments, and a café on the corner.
private func drawParis(_ ctx: GraphicsContext, t: Double) {
    // Haussmann blocks either side
    let blocks: [(x: Double, w: Double, top: Double)] = [(0, 190, 250), (1030, 170, 262)]
    for b in blocks {
        fill(ctx, CGRect(x: b.x, y: b.top, width: b.w, height: 405 - b.top), Color(red: 0.93, green: 0.89, blue: 0.80))
        var roof = Path()
        roof.move(to: CGPoint(x: b.x - 4, y: b.top))
        roof.addLine(to: CGPoint(x: b.x + 10, y: b.top - 34))
        roof.addLine(to: CGPoint(x: b.x + b.w - 10, y: b.top - 34))
        roof.addLine(to: CGPoint(x: b.x + b.w + 4, y: b.top))
        roof.closeSubpath()
        ctx.fill(roof, with: .color(Color(red: 0.36, green: 0.42, blue: 0.50)))
        for x in stride(from: b.x + 16, to: b.x + b.w - 20, by: 28) {
            fill(ctx, CGRect(x: x, y: b.top - 26, width: 12, height: 16), Color(red: 0.80, green: 0.88, blue: 0.95), corner: 5)
            for y in stride(from: b.top + 14, to: 360, by: 34) {
                fill(ctx, CGRect(x: x, y: y, width: 12, height: 22), Color(red: 0.55, green: 0.66, blue: 0.78))
                fill(ctx, CGRect(x: x - 3, y: y + 20, width: 18, height: 3), Color(white: 0.25))
            }
        }
        for x in stride(from: b.x + 30, to: b.x + b.w, by: 56) { fill(ctx, CGRect(x: x, y: b.top - 50, width: 10, height: 18), Color(red: 0.70, green: 0.42, blue: 0.32)) }
    }

    // The Eiffel Tower: four legs sweeping up to two platforms and a needle
    let cx = 880.0
    let iron = Color(red: 0.42, green: 0.35, blue: 0.28)
    let levels: [(y: Double, hw: Double)] = [(405, 118), (300, 58), (218, 30), (70, 5)]
    var outline = Path()
    outline.move(to: CGPoint(x: cx - levels[0].hw, y: levels[0].y))
    outline.addQuadCurve(to: CGPoint(x: cx - levels[1].hw, y: levels[1].y), control: CGPoint(x: cx - 74, y: 345))
    outline.addQuadCurve(to: CGPoint(x: cx - levels[2].hw, y: levels[2].y), control: CGPoint(x: cx - 40, y: 255))
    outline.addQuadCurve(to: CGPoint(x: cx - levels[3].hw, y: levels[3].y), control: CGPoint(x: cx - 14, y: 150))
    outline.addLine(to: CGPoint(x: cx + levels[3].hw, y: levels[3].y))
    outline.addQuadCurve(to: CGPoint(x: cx + levels[2].hw, y: levels[2].y), control: CGPoint(x: cx + 14, y: 150))
    outline.addQuadCurve(to: CGPoint(x: cx + levels[1].hw, y: levels[1].y), control: CGPoint(x: cx + 40, y: 255))
    outline.addQuadCurve(to: CGPoint(x: cx + levels[0].hw, y: levels[0].y), control: CGPoint(x: cx + 74, y: 345))
    outline.closeSubpath()
    // The great arch between the legs, and the gap above the first platform
    var archway = Path()
    archway.move(to: CGPoint(x: cx - 78, y: 410))
    archway.addQuadCurve(to: CGPoint(x: cx + 78, y: 410), control: CGPoint(x: cx, y: 240))
    archway.closeSubpath()
    var gap = Path()
    gap.move(to: CGPoint(x: cx - 26, y: 290))
    gap.addQuadCurve(to: CGPoint(x: cx + 26, y: 290), control: CGPoint(x: cx, y: 215))
    gap.closeSubpath()
    let body = outline.subtracting(archway).subtracting(gap)
    ctx.fill(body, with: .color(iron))
    var lattice = ctx
    lattice.clip(to: body)
    for k in stride(from: -260.0, to: 260, by: 14) {
        var a = Path()
        a.move(to: CGPoint(x: cx + k, y: 410))
        a.addLine(to: CGPoint(x: cx + k + 240, y: 60))
        var b = Path()
        b.move(to: CGPoint(x: cx + k, y: 410))
        b.addLine(to: CGPoint(x: cx + k - 240, y: 60))
        lattice.stroke(a, with: .color(.white.opacity(0.16)), lineWidth: 1.5)
        lattice.stroke(b, with: .color(.white.opacity(0.16)), lineWidth: 1.5)
    }
    for (i, lv) in levels.dropFirst().dropLast().enumerated() {
        fill(ctx, CGRect(x: cx - lv.hw - 8, y: lv.y - 5, width: (lv.hw + 8) * 2, height: i == 0 ? 11 : 8), Color(red: 0.32, green: 0.26, blue: 0.20), corner: 2)
    }
    fill(ctx, CGRect(x: cx - 7, y: 60, width: 14, height: 12), Color(red: 0.32, green: 0.26, blue: 0.20), corner: 2)
    fill(ctx, CGRect(x: cx - 1, y: 30, width: 2, height: 32), iron)
    ctx.fill(circle(CGPoint(x: cx, y: 30), 3), with: .color(.red.opacity(0.5 + 0.5 * sin(t * 4))))

    // The Champ de Mars: clipped trees along a long lawn
    fill(ctx, CGRect(x: 190, y: 378, width: 840, height: 30), Color(red: 0.40, green: 0.68, blue: 0.34))
    for x in stride(from: 215.0, to: 740, by: 58) {
        fill(ctx, CGRect(x: x + 9, y: 360, width: 5, height: 30), Color(red: 0.42, green: 0.30, blue: 0.20))
        fill(ctx, CGRect(x: x, y: 322, width: 24, height: 42), Color(red: 0.22, green: 0.50, blue: 0.26), corner: 8)
    }

    // The corner café
    fill(ctx, CGRect(x: 40, y: 340, width: 130, height: 65), Color(red: 0.30, green: 0.22, blue: 0.20))
    for k in 0..<7 { fill(ctx, CGRect(x: 32 + Double(k) * 20.8, y: 326, width: 20.8, height: 18), k % 2 == 0 ? Color(red: 0.78, green: 0.12, blue: 0.16) : .white) }
    ctx.draw(Text("CAFÉ").font(.system(size: 14, weight: .black, design: .serif)).foregroundStyle(Color(red: 1, green: 0.88, blue: 0.55)), at: CGPoint(x: 105, y: 360))
    fill(ctx, CGRect(x: 56, y: 372, width: 40, height: 30), Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.85), corner: 2)
    fill(ctx, CGRect(x: 114, y: 372, width: 40, height: 30), Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.85), corner: 2)

    // Pale gravel, a café table, a lamp post and the tricolore
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.87, green: 0.83, blue: 0.74))
    for x in stride(from: 0.0, to: Stage.W, by: 70) { fill(ctx, CGRect(x: x, y: 405, width: 2, height: Stage.H - 405), Color(red: 0.78, green: 0.74, blue: 0.65)) }
    fill(ctx, CGRect(x: 196, y: 392, width: 3, height: 22), Color(white: 0.25))
    ctx.fill(Path(ellipseIn: CGRect(x: 182, y: 388, width: 31, height: 7)), with: .color(Color(white: 0.92)))
    fill(ctx, CGRect(x: 1102, y: 300, width: 5, height: 110), Color(white: 0.18))
    ctx.fill(circle(CGPoint(x: 1104.5, y: 294), 9), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
    fill(ctx, CGRect(x: 548, y: 300, width: 3, height: 110), Color(white: 0.85))
    for (k, c) in [Color(red: 0.0, green: 0.14, blue: 0.58), .white, Color(red: 0.93, green: 0.16, blue: 0.22)].enumerated() {
        fill(ctx, CGRect(x: 551 + Double(k) * 12, y: 300 + sin(t * 5 + Double(k)) * 1.5, width: 12, height: 24), c)
    }
    sign(ctx, "TOUR EIFFEL", at: CGRect(x: 420, y: 352, width: 110, height: 26), bg: Color(red: 0.0, green: 0.14, blue: 0.58))
}

// MARK: The Bahamas

/// Coco Cay: turquoise shallows, white sand, a cruise ship at the pier, the tall slide tower and the tethered balloon.
private func drawCocoCay(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.20, green: 0.78, blue: 0.82))
    fill(ctx, CGRect(x: 0, y: 290, width: Stage.W, height: 30), Color(red: 0.10, green: 0.50, blue: 0.75))
    cruiseShip(ctx, x: 560, waterline: 300, width: 330, hull: .white, t: t) { ctx, r in
        fill(ctx, r, Color(red: 0.10, green: 0.25, blue: 0.60), corner: 3)
        fill(ctx, CGRect(x: r.minX, y: r.minY + 7, width: r.width, height: 5), Color(red: 1, green: 0.82, blue: 0.20))
    }
    fill(ctx, CGRect(x: 880, y: 318, width: 120, height: 8), Color(white: 0.85))

    // The slide tower, with a red slide corkscrewing down it
    fill(ctx, CGRect(x: 1006, y: 200, width: 12, height: 210), Color(white: 0.88))
    fill(ctx, CGRect(x: 994, y: 186, width: 36, height: 16), Color(red: 0.98, green: 0.80, blue: 0.20), corner: 3)
    var top = Path()
    top.move(to: CGPoint(x: 990, y: 188))
    top.addLine(to: CGPoint(x: 1012, y: 166))
    top.addLine(to: CGPoint(x: 1034, y: 188))
    top.closeSubpath()
    ctx.fill(top, with: .color(Color(red: 0.10, green: 0.45, blue: 0.75)))
    for k in 0..<6 {
        let y = 208 + Double(k) * 32
        var turn = Path()
        turn.move(to: CGPoint(x: 984, y: y))
        turn.addQuadCurve(to: CGPoint(x: 1040, y: y + 16), control: CGPoint(x: 1012, y: y + 22))
        ctx.stroke(turn, with: .color(Color(red: 0.90, green: 0.18, blue: 0.20)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    }

    // The helium balloon on its tether
    let sway = sin(t * 0.6) * 10
    let balloon = CGPoint(x: 1120 + sway, y: 130 + sin(t * 0.9) * 4)
    var tether = Path()
    tether.move(to: CGPoint(x: 1120, y: 405))
    tether.addQuadCurve(to: CGPoint(x: balloon.x, y: balloon.y + 66), control: CGPoint(x: 1120 + sway * 0.3, y: 300))
    ctx.stroke(tether, with: .color(Color(white: 0.35)), lineWidth: 1.2)
    for (k, c) in [Color(red: 0.98, green: 0.80, blue: 0.15), Color(red: 0.10, green: 0.45, blue: 0.80), Color(red: 0.95, green: 0.30, blue: 0.35), Color(red: 0.98, green: 0.80, blue: 0.15)].enumerated() {
        let w = 92 - Double(k) * 26
        guard w > 0 else { continue }
        ctx.fill(Path(ellipseIn: CGRect(x: balloon.x - w / 2, y: balloon.y - 50, width: w, height: 100)), with: .color(c))
    }
    fill(ctx, CGRect(x: balloon.x - 9, y: balloon.y + 56, width: 18, height: 11), Color(red: 0.55, green: 0.38, blue: 0.22), corner: 2)

    // White sand, palms and a striped umbrella
    fill(ctx, CGRect(x: 0, y: 405, width: Stage.W, height: Stage.H - 405), Color(red: 0.98, green: 0.95, blue: 0.86))
    palm(ctx, x: 540, base: 410, height: 150, t: t)
    palm(ctx, x: 30, base: 410, height: 165, t: t + 1)
    beachUmbrella(ctx, x: 130, Color(red: 0.95, green: 0.35, blue: 0.40))
    sign(ctx, "PERFECT DAY · COCO CAY", at: CGRect(x: 800, y: 345, width: 150, height: 26), bg: Color(red: 0.00, green: 0.60, blue: 0.65), size: 10)
    gulls(ctx, t: t)
}

/// Bimini: gin-clear flats, the concrete wreck of the Sapona on the horizon, a sport-fishing boat,
/// and the pastel cottages of Alice Town.
private func drawBimini(_ ctx: GraphicsContext, t: Double) {
    sea(ctx, t: t, top: 290, color: Color(red: 0.22, green: 0.80, blue: 0.80))
    fill(ctx, CGRect(x: 0, y: 290, width: Stage.W, height: 22), Color(red: 0.08, green: 0.42, blue: 0.70))
    // The Sapona: a rusting concrete skeleton aground on the flats
    let rust = Color(red: 0.45, green: 0.32, blue: 0.26)
    var wreck = Path()
    wreck.move(to: CGPoint(x: 560, y: 300))
    wreck.addLine(to: CGPoint(x: 548, y: 272))
    wreck.addLine(to: CGPoint(x: 730, y: 266))
    wreck.addLine(to: CGPoint(x: 748, y: 300))
    wreck.closeSubpath()
    ctx.fill(wreck, with: .color(rust))
    for x in stride(from: 566.0, to: 730, by: 18) { fill(ctx, CGRect(x: x, y: 276, width: 9, height: 18), Color(red: 0.22, green: 0.80, blue: 0.80)) }
    for x in [600.0, 650, 700] { fill(ctx, CGRect(x: x, y: 246, width: 4, height: 24), rust) }
    fill(ctx, CGRect(x: 596, y: 246, width: 112, height: 3), rust)
    // A sport-fishing boat heading out, and a dolphin keeping it company
    let bx = 760 + (t * 18).truncatingRemainder(dividingBy: 380)
    fill(ctx, CGRect(x: bx, y: 340, width: 54, height: 12), .white, corner: 5)
    fill(ctx, CGRect(x: bx + 14, y: 328, width: 22, height: 12), Color(white: 0.92), corner: 3)
    fill(ctx, CGRect(x: bx + 22, y: 310, width: 2, height: 18), Color(white: 0.7))
    let hop = (t * 0.45).truncatingRemainder(dividingBy: 1)
    if hop < 0.5 {
        let u = hop / 0.5
        var dolphin = ctx
        dolphin.translateBy(x: 480 + u * 70, y: 352 - sin(u * .pi) * 30)
        dolphin.rotate(by: .degrees(-50 + u * 100))
        dolphin.fill(Path(ellipseIn: CGRect(x: -16, y: -5, width: 32, height: 10)), with: .color(Color(red: 0.45, green: 0.52, blue: 0.60)))
        var fin = Path()
        fin.move(to: CGPoint(x: -3, y: -4))
        fin.addLine(to: CGPoint(x: 1, y: -12))
        fin.addLine(to: CGPoint(x: 6, y: -4))
        fin.closeSubpath()
        dolphin.fill(fin, with: .color(Color(red: 0.45, green: 0.52, blue: 0.60)))
    }
    // The beach sweeping round to a green point on the right
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
    // Alice Town's pastel cottages
    for (i, c) in [Color(red: 0.98, green: 0.75, blue: 0.70), Color(red: 0.70, green: 0.88, blue: 0.95), Color(red: 0.98, green: 0.90, blue: 0.60)].enumerated() {
        let x = 1000 + Double(i) * 62
        fill(ctx, CGRect(x: x, y: 350, width: 50, height: 42), c)
        fill(ctx, CGRect(x: x - 4, y: 342, width: 58, height: 10), .white, corner: 2)
        fill(ctx, CGRect(x: x + 18, y: 368, width: 14, height: 24), Color(red: 0.40, green: 0.28, blue: 0.20))
    }
    palm(ctx, x: 520, base: 410, height: 150, t: t)
    palm(ctx, x: 950, base: 400, height: 120, t: t + 2)
    beachUmbrella(ctx, x: 100, Color(red: 0.10, green: 0.30, blue: 0.65))
    sign(ctx, "BIMINI · BAHAMAS", at: CGRect(x: 810, y: 345, width: 130, height: 26), bg: Color(red: 0.08, green: 0.42, blue: 0.70))
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

/// Main Street, where one of the women buys groceries and makes a deposit at the bank.
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

/// Further along Main Street: the ship-supply shop that sells cruise ship upgrades, and the dealer's showroom next door.
func drawShops(_ ctx: GraphicsContext, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    // Road and sidewalk
    fill(ctx, CGRect(x: 0, y: 440, width: Stage.W, height: 60), Color(white: 0.80))
    for x in stride(from: 0.0, to: Stage.W, by: 50) { fill(ctx, CGRect(x: x, y: 440, width: 1.5, height: 60), Color(white: 0.70)) }
    fill(ctx, CGRect(x: 0, y: 500, width: Stage.W, height: 8), Color(white: 0.6))
    fill(ctx, CGRect(x: 0, y: 508, width: Stage.W, height: Stage.H - 508), Color(white: 0.30))
    for x in stride(from: 20.0, to: Stage.W, by: 90) { fill(ctx, CGRect(x: x, y: 552, width: 44, height: 5), Color(red: 1, green: 0.85, blue: 0.2)) }

    // The ship-supply shop: navy clapboard, a rope trim and a striped awning
    let navy = Color(red: 0.10, green: 0.22, blue: 0.48)
    let rope = Color(red: 0.86, green: 0.72, blue: 0.48)
    let store = CGRect(x: 120, y: 240, width: 380, height: 200)
    fill(ctx, store, Color(red: 0.86, green: 0.92, blue: 0.98))
    for k in 0..<10 { fill(ctx, CGRect(x: store.minX, y: store.minY + 70 + Double(k) * 13, width: store.width, height: 1.2), Color(red: 0.70, green: 0.80, blue: 0.90)) }
    fill(ctx, CGRect(x: store.minX - 8, y: store.minY - 10, width: store.width + 16, height: 14), navy)
    fill(ctx, CGRect(x: store.minX + 20, y: 250, width: 340, height: 52), navy, corner: 10)
    ctx.stroke(Path(roundedRect: CGRect(x: store.minX + 24, y: 254, width: 332, height: 44), cornerRadius: 8), with: .color(rope), lineWidth: 2.5)
    ctx.draw(Text("SHIPSHAPE").font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: store.midX, y: 268))
    ctx.draw(Text("CRUISE SHIP UPGRADES").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(rope),
             at: CGPoint(x: store.midX, y: 288))
    for k in 0..<19 {
        ctx.fill(circle(CGPoint(x: store.minX + 10 + Double(k) * 20, y: 318), 10), with: .color(k % 2 == 0 ? navy : .white))
    }
    fill(ctx, CGRect(x: store.minX, y: 306, width: store.width, height: 12), navy)
    // Window displays: a life ring on one side, a little model ship in a bottle-green case on the other
    let left = CGRect(x: store.minX + 20, y: 344, width: 120, height: 72)
    let right = CGRect(x: store.maxX - 140, y: 344, width: 120, height: 72)
    for w in [left, right] {
        fill(ctx, w, Color(red: 0.80, green: 0.92, blue: 0.98))
        fill(ctx, CGRect(x: w.minX, y: w.maxY - 10, width: w.width, height: 10), .white)
        ctx.stroke(Path(w), with: .color(rope), lineWidth: 4)
    }
    let ring = CGPoint(x: left.midX, y: left.minY + 30)
    for k in 0..<8 {
        var arc = Path()
        arc.addArc(center: ring, radius: 19, startAngle: .degrees(Double(k) * 45), endAngle: .degrees(Double(k + 1) * 45), clockwise: false)
        ctx.stroke(arc, with: .color(k % 2 == 0 ? Color(red: 0.95, green: 0.35, blue: 0.20) : .white), lineWidth: 9)
    }
    ctx.stroke(Path(ellipseIn: CGRect(x: ring.x - 24, y: ring.y - 24, width: 48, height: 48)), with: .color(rope), lineWidth: 1.5)
    // The model ship: white hull with a pink stripe, a striped funnel, a tiny flag
    let mx = right.midX, my = right.maxY - 20
    var model = Path()
    model.move(to: CGPoint(x: mx - 40, y: my - 14))
    model.addLine(to: CGPoint(x: mx + 42, y: my - 16))
    model.addLine(to: CGPoint(x: mx + 30, y: my))
    model.addLine(to: CGPoint(x: mx - 36, y: my))
    model.closeSubpath()
    ctx.fill(model, with: .color(.white))
    fill(ctx, CGRect(x: mx - 38, y: my - 7, width: 74, height: 3), Color(red: 1.0, green: 0.35, blue: 0.70))
    fill(ctx, CGRect(x: mx - 28, y: my - 24, width: 48, height: 10), .white, corner: 2)
    fill(ctx, CGRect(x: mx - 4, y: my - 38, width: 12, height: 14), Color(red: 0.86, green: 0.14, blue: 0.20))
    fill(ctx, CGRect(x: mx - 4, y: my - 33, width: 12, height: 3), Color(red: 1.0, green: 0.95, blue: 0.84))
    fill(ctx, CGRect(x: mx - 26, y: my - 44, width: 1.5, height: 20), Color(white: 0.6))
    fill(ctx, CGRect(x: mx - 24.5, y: my - 44, width: 10, height: 6), Color(red: 1.0, green: 0.35, blue: 0.70))
    let door = CGRect(x: Stage.boutiqueDoorX - 28, y: 350, width: 56, height: 90)
    fill(ctx, door, Color(red: 0.60, green: 0.80, blue: 0.90))
    ctx.stroke(Path(door), with: .color(navy), lineWidth: 4)
    ctx.stroke(Path(ellipseIn: CGRect(x: door.midX - 12, y: door.minY + 12, width: 24, height: 24)), with: .color(navy), lineWidth: 4)
    fill(ctx, CGRect(x: door.midX - 1.5, y: door.minY + 36, width: 3, height: door.height - 36), navy)

    // The dealer: a glass showroom with a scooter and a car on the floor
    let lot = CGRect(x: 620, y: 270, width: 480, height: 170)
    fill(ctx, lot, Color(red: 0.90, green: 0.92, blue: 0.95))
    fill(ctx, CGRect(x: lot.minX - 10, y: lot.minY - 46, width: lot.width + 20, height: 50), Color(red: 0.15, green: 0.25, blue: 0.50), corner: 6)
    ctx.draw(Text("WHEELS & DEALS").font(.system(size: 27, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.85, blue: 0.2)),
             at: CGPoint(x: lot.midX, y: lot.minY - 22))
    let glass = CGRect(x: lot.minX + 16, y: lot.minY + 22, width: 340, height: lot.height - 30)
    fill(ctx, glass, Color(red: 0.78, green: 0.90, blue: 0.98))
    fill(ctx, CGRect(x: glass.minX, y: glass.maxY - 8, width: glass.width, height: 8), Color(white: 0.92))
    drawScooter(ctx, x: glass.minX + 70, ground: glass.maxY - 6)
    drawCar(ctx, x: glass.minX + 230, hooked: false, paint: Color(red: 0.85, green: 0.16, blue: 0.20), noseRight: true, ground: glass.maxY - 6)
    ctx.stroke(Path(glass), with: .color(.white), lineWidth: 5)
    fill(ctx, CGRect(x: glass.midX - 40 - 1.5, y: glass.minY, width: 3, height: glass.height), .white)
    for (x, price) in [(glass.minX + 70, Vehicle.scooter.price), (glass.minX + 230, Vehicle.car.price)] {
        fill(ctx, CGRect(x: x - 26, y: glass.minY + 10, width: 52, height: 22), Color(red: 1, green: 0.95, blue: 0.4), corner: 4)
        ctx.draw(Text("$\(price)").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.black), at: CGPoint(x: x, y: glass.minY + 21))
    }
    let dealerDoor = CGRect(x: Stage.dealerDoorX - 28, y: 350, width: 56, height: 90)
    fill(ctx, dealerDoor, Color(red: 0.60, green: 0.80, blue: 0.90))
    ctx.stroke(Path(dealerDoor), with: .color(Color(red: 0.15, green: 0.25, blue: 0.50)), lineWidth: 4)
    // Bunting fluttering over the lot
    let flags: [Color] = [.red, Color(red: 1, green: 0.85, blue: 0.2), Color(red: 0.25, green: 0.55, blue: 0.85)]
    for i in 0..<16 {
        let u = Double(i) / 15
        let x = lot.minX + u * lot.width
        let y = lot.minY + 8 + sin(u * .pi) * 10 + sin(t * 3 + Double(i)) * 1.5
        var flag = Path()
        flag.move(to: CGPoint(x: x - 8, y: y))
        flag.addLine(to: CGPoint(x: x + 8, y: y))
        flag.addLine(to: CGPoint(x: x, y: y + 14))
        flag.closeSubpath()
        ctx.fill(flag, with: .color(flags[i % flags.count]))
    }

    // A street lamp and a little tree
    fill(ctx, CGRect(x: 557, y: 330, width: 6, height: 110), Color(white: 0.2))
    ctx.fill(circle(CGPoint(x: 560, y: 326), 9), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
    fill(ctx, CGRect(x: 1145, y: 360, width: 10, height: 80), Color(red: 0.45, green: 0.30, blue: 0.18))
    ctx.fill(circle(CGPoint(x: 1150, y: 345), 36 + sin(t) * 1), with: .color(Color(red: 0.25, green: 0.55, blue: 0.28)))
}

// MARK: Funland Amusement Park

/// Deidre's job: the parking lot at Funland, down by the boardwalk, with the rides behind the fence.
func drawPark(_ ctx: GraphicsContext, d: Director, now: Date) {
    let t = now.timeIntervalSinceReferenceDate
    drawSky(ctx)
    // The ocean beyond the boardwalk
    fill(ctx, CGRect(x: 0, y: 330, width: Stage.W, height: 70), Color(red: 0.25, green: 0.58, blue: 0.80))
    // The rides behind the fence (unless the repo men have them)
    drawParkFixture(ctx, d: d, .ferrisWheel, anchor: Stage.ferrisAnchor, slot: Stage.ferrisSlot, scale: 0.3, onTruck: false, now: now) { drawFerrisWheel($0, t: t) }
    drawParkFixture(ctx, d: d, .coaster, anchor: Stage.coasterAnchor, slot: Stage.coasterSlot, scale: 0.35, onTruck: false, now: now) { drawCoaster($0) }
    // The entrance arch and a fence along the lot
    fill(ctx, CGRect(x: 0, y: 380, width: Stage.W, height: 6), Color(white: 0.35))
    for x in stride(from: 0.0, to: Stage.W, by: 24) { fill(ctx, CGRect(x: x, y: 362, width: 3, height: 40), Color(white: 0.35)) }
    fill(ctx, CGRect(x: 380, y: 250, width: 16, height: 150), Color(red: 0.95, green: 0.75, blue: 0.20))
    fill(ctx, CGRect(x: 560, y: 250, width: 16, height: 150), Color(red: 0.95, green: 0.75, blue: 0.20))
    fill(ctx, CGRect(x: 370, y: 232, width: 216, height: 40), Color(red: 0.85, green: 0.15, blue: 0.35), corner: 10)
    ctx.draw(Text("FUNLAND").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(.yellow), at: CGPoint(x: 478, y: 252))
    for i in 0..<10 {
        let on = !d.parkLightsOut && (Int(t * 5) + i) % 2 == 0
        ctx.fill(circle(CGPoint(x: 380 + Double(i) * 22, y: 228), 3), with: .color((on ? Color.yellow : .white).opacity(on ? 1 : 0.5)))
    }
    // The park office, where the boss keeps an eye on everything
    let office = CGRect(x: 60, y: 300, width: 170, height: 140)
    fill(ctx, office, Color(red: 0.92, green: 0.90, blue: 0.84))
    fill(ctx, CGRect(x: office.minX - 8, y: office.minY - 12, width: office.width + 16, height: 16), Color(red: 0.55, green: 0.20, blue: 0.25))
    fill(ctx, CGRect(x: office.minX + 18, y: office.minY + 26, width: 60, height: 44), Color(red: 0.70, green: 0.87, blue: 1))
    fill(ctx, CGRect(x: office.minX + 108, y: office.minY + 50, width: 44, height: 90), Color(red: 0.45, green: 0.28, blue: 0.18))
    fill(ctx, CGRect(x: office.minX + 30, y: office.minY - 36, width: 110, height: 22), Color(red: 0.2, green: 0.25, blue: 0.5), corner: 5)
    ctx.draw(Text("PARK OFFICE").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: office.minX + 85, y: office.minY - 25))
    // The electric box on the office's side wall, its big switch up (on) or pulled down (off)
    let box = CGRect(x: Stage.powerBoxX - 13, y: 372, width: 26, height: 34)
    fill(ctx, box, Color(white: 0.62), corner: 3)
    ctx.stroke(Path(roundedRect: box, cornerRadius: 3), with: .color(Color(white: 0.35)), lineWidth: 1.5)
    ctx.draw(Text("⚡︎").font(.system(size: 9, weight: .black)).foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.1)),
             at: CGPoint(x: box.midX - 5, y: box.minY + 8))
    var lever = Path()
    lever.move(to: CGPoint(x: box.maxX - 2, y: box.midY))
    lever.addLine(to: CGPoint(x: box.maxX + 8, y: box.midY + (d.parkLightsOut ? 14 : -14)))
    ctx.stroke(lever, with: .color(Color(red: 0.8, green: 0.1, blue: 0.1)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    // The parking lot
    fill(ctx, CGRect(x: 0, y: 440, width: Stage.W, height: Stage.H - 440), Color(white: 0.30))
    for x in stride(from: 40.0, to: Stage.W, by: 110) {
        var line = Path()
        line.move(to: CGPoint(x: x, y: 448))
        line.addLine(to: CGPoint(x: x - 30, y: 600))
        ctx.stroke(line, with: .color(.white.opacity(0.7)), lineWidth: 3)
    }
    // The repo men's flatbed is parked behind everyone.
    if let fx = d.flatbed(at: now) { drawFlatbed(ctx, x: fx, now: now) }
    // …with the rides being winched up onto it.
    drawParkFixture(ctx, d: d, .ferrisWheel, anchor: Stage.ferrisAnchor, slot: Stage.ferrisSlot, scale: 0.3, onTruck: true, now: now) { drawFerrisWheel($0, t: t) }
    drawParkFixture(ctx, d: d, .coaster, anchor: Stage.coasterAnchor, slot: Stage.coasterSlot, scale: 0.35, onTruck: true, now: now) { drawCoaster($0) }
    // The zamboni's seat back sits behind its driver; the rest of it is drawn in front of her.
    if let zx = d.zamboni(at: now) {
        fill(ctx, CGRect(x: zx - 24, y: Stage.floorY - 92, width: 9, height: 44), Color(white: 0.2), corner: 3)
    }
    for (z, spot) in zip(d.fleet, d.fleetSpots(at: now)) where z.rider != nil {
        fill(ctx, CGRect(x: spot.x - 24, y: Stage.floorY - 92 - spot.lift, width: 9, height: 44), Color(white: 0.2), corner: 3)
    }
    if d.funlandClosed { drawFunlandClosed(ctx) }
}

/// Funland's Ferris wheel, turning slowly behind the fence.
func drawFerrisWheel(_ ctx: GraphicsContext, t: Double) {
    let hub = CGPoint(x: 820, y: 230)
    let r = 140.0
    for side in [-1.0, 1.0] {
        var leg = Path()
        leg.move(to: hub)
        leg.addLine(to: CGPoint(x: hub.x + side * 70, y: 400))
        ctx.stroke(leg, with: .color(Color(white: 0.45)), lineWidth: 6)
    }
    ctx.stroke(circle(hub, r), with: .color(Color(red: 0.95, green: 0.30, blue: 0.40)), lineWidth: 4)
    ctx.stroke(circle(hub, r - 12), with: .color(Color(red: 0.95, green: 0.30, blue: 0.40).opacity(0.6)), lineWidth: 2)
    let cars: [Color] = [.yellow, .cyan, .orange, .green, .purple, .pink, .red, .blue]
    for k in 0..<12 {
        let ang = t * 0.15 + Double(k) / 12 * 2 * .pi
        let p = CGPoint(x: hub.x + cos(ang) * r, y: hub.y + sin(ang) * r)
        var spoke = Path()
        spoke.move(to: hub)
        spoke.addLine(to: p)
        ctx.stroke(spoke, with: .color(Color(white: 0.55)), lineWidth: 1.5)
        fill(ctx, CGRect(x: p.x - 10, y: p.y, width: 20, height: 16), cars[k % cars.count], corner: 4)
    }
    ctx.fill(circle(hub, 9), with: .color(Color(white: 0.4)))
}

/// Funland's roller coaster on the right, behind the fence.
func drawCoaster(_ ctx: GraphicsContext) {
    var track = Path()
    track.move(to: CGPoint(x: 960, y: 400))
    track.addCurve(to: CGPoint(x: 1200, y: 190), control1: CGPoint(x: 1030, y: 120), control2: CGPoint(x: 1090, y: 380))
    ctx.stroke(track, with: .color(Color(red: 0.25, green: 0.35, blue: 0.75)), lineWidth: 6)
    for x in stride(from: 975.0, to: 1200, by: 28) {
        fill(ctx, CGRect(x: x, y: 260, width: 3, height: 140), Color(white: 0.6))
    }
}

/// One of Funland's rides: in place (`anchor` is its bottom middle), being winched up onto the repo
/// flatbed and shrunk to fit (`slot` from the bed's left end, at `scale`), riding away on it, or gone once the flatbed has left.
/// `onTruck` picks which of those this call draws (nil = either), so things in place stay behind the fence.
func drawParkFixture(_ ctx: GraphicsContext, d: Director, _ item: ParkRide, anchor: CGPoint, slot: Double, scale: Double,
                     onTruck: Bool?, now: Date, draw: (GraphicsContext) -> Void) {
    guard let t0 = d.parkHaul[item] else {
        if onTruck != true { draw(ctx) }
        return
    }
    guard onTruck != false, !d.flatbedEmpty, let bed = d.flatbed(at: now) else { return }
    let u = min(max(now.timeIntervalSince(t0) / Director.rideLoadDur, 0), 1)
    let e = u * u * (3 - 2 * u)
    let target = CGPoint(x: bed + slot, y: Stage.floorY - Stage.flatbedDeck)
    // Lifted up and over in an arc, not dragged along the ground.
    let pos = CGPoint(x: anchor.x + (target.x - anchor.x) * e, y: anchor.y + (target.y - anchor.y) * e - sin(e * .pi) * 60)
    let sc = 1 + (scale - 1) * e
    var c = ctx
    c.translateBy(x: pos.x, y: pos.y)
    c.scaleBy(x: sc, y: sc)
    c.translateBy(x: -anchor.x, y: -anchor.y)
    draw(c)
}

/// Closed by the bank: the gate chained shut and a big banner across the arch.
func drawFunlandClosed(_ ctx: GraphicsContext) {
    var chain = Path()
    chain.move(to: CGPoint(x: 376, y: 380))
    chain.addQuadCurve(to: CGPoint(x: 568, y: 380), control: CGPoint(x: 472, y: 410))
    ctx.stroke(chain, with: .color(Color(white: 0.55)), style: StrokeStyle(lineWidth: 4, dash: [7, 3]))
    fill(ctx, CGRect(x: 462, y: 384, width: 20, height: 18), Color(red: 0.75, green: 0.6, blue: 0.2), corner: 3)
    var c = ctx
    c.translateBy(x: 478, y: 262)
    c.rotate(by: .degrees(-8))
    fill(c, CGRect(x: -150, y: -24, width: 300, height: 48), Color(red: 0.85, green: 0.08, blue: 0.08), corner: 4)
    c.draw(Text("CLOSED BY THE BANK").font(.system(size: 22, weight: .black)).foregroundStyle(.white), at: CGPoint(x: 0, y: -6))
    c.draw(Text("SHORE SAVINGS BANK · LOAN IN DEFAULT").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white), at: CGPoint(x: 0, y: 14))
    // The notice on the office door
    fill(ctx, CGRect(x: 170, y: 360, width: 34, height: 42), .white, corner: 2)
    fill(ctx, CGRect(x: 174, y: 364, width: 26, height: 7), Color(red: 0.85, green: 0.08, blue: 0.08))
    for k in 0..<4 { fill(ctx, CGRect(x: 174, y: 376 + Double(k) * 6, width: 26, height: 2), Color(white: 0.5)) }
}

/// The zambonis (in front of their drivers, so they sit down inside them) and Mr. Grimsby's motorcycle.
func drawParkVehicles(_ ctx: GraphicsContext, d: Director, now: Date) {
    // The coworkers' zambonis — on the lot, or up on the repo men's flatbed.
    for spot in d.fleetSpots(at: now) {
        var c = ctx
        c.translateBy(x: 0, y: -spot.lift)
        drawZamboni(c, x: spot.x, now: now)
    }
    if let mx = d.motorcycle(at: now) { drawMotorcycle(ctx, x: mx, ridden: d.motorcycleRider != nil, now: now) }
    if let fight = d.scuffle {
        let age = now.timeIntervalSince(fight.t0)
        if age < 0.9 {
            let c = CGPoint(x: fight.x, y: Stage.floorY - 130)
            for k in 0..<6 {
                let ang = Double(k) / 6 * 2 * .pi + 0.3
                ctx.draw(Text("✸").font(.system(size: 18)).foregroundStyle(Color.yellow.opacity(1 - age / 0.9)),
                         at: CGPoint(x: c.x + cos(ang) * (14 + age * 50), y: c.y + sin(ang) * (12 + age * 40)))
            }
            let word = ["POW!", "BIFF!", "WHAP!"][Int(fight.t0.timeIntervalSinceReferenceDate * 10) % 3]
            ctx.draw(Text(word).font(.system(size: 28, weight: .black, design: .rounded)).foregroundStyle(Color.red.opacity(1 - age / 0.9)),
                     at: CGPoint(x: c.x, y: c.y - 34 - age * 16))
        }
    }
    if let zx = d.zamboni(at: now) { drawZamboni(ctx, x: zx, now: now) }
}

/// Mr. Grimsby's motorcycle, nose to the right. `x` is the seat, where a rider sits; once ridden, exhaust puffs out the back.
func drawMotorcycle(_ ctx: GraphicsContext, x: Double, ridden: Bool, now: Date) {
    let g = Stage.floorY
    let chrome = Color(white: 0.78)
    let black = Color(white: 0.10)
    let paint = Color(red: 0.10, green: 0.10, blue: 0.12)
    let back = CGPoint(x: x - 34, y: g - 17)
    let front = CGPoint(x: x + 58, y: g - 17)
    for w in [back, front] {
        ctx.fill(circle(w, 17), with: .color(black))
        ctx.fill(circle(w, 7), with: .color(chrome))
    }
    // Frame, engine and exhaust
    var frame = Path()
    frame.move(to: back)
    frame.addLine(to: CGPoint(x: x + 6, y: g - 22))
    frame.addLine(to: CGPoint(x: x + 30, y: g - 50))
    frame.move(to: CGPoint(x: x + 6, y: g - 22))
    frame.addLine(to: CGPoint(x: x + 34, y: g - 28))
    ctx.stroke(frame, with: .color(chrome), lineWidth: 4)
    fill(ctx, CGRect(x: x - 6, y: g - 38, width: 26, height: 18), Color(white: 0.45), corner: 4)
    fill(ctx, CGRect(x: x - 46, y: g - 26, width: 44, height: 6), chrome, corner: 3)
    // Seat, tank (with a red stripe) and the fork up to the handlebars
    fill(ctx, CGRect(x: x - 26, y: g - 50, width: 36, height: 9), Color(red: 0.25, green: 0.15, blue: 0.10), corner: 4)
    fill(ctx, CGRect(x: x + 6, y: g - 58, width: 32, height: 16), paint, corner: 7)
    fill(ctx, CGRect(x: x + 10, y: g - 52, width: 24, height: 3), Color(red: 0.85, green: 0.12, blue: 0.12))
    var fork = Path()
    fork.move(to: front)
    fork.addLine(to: CGPoint(x: x + 42, y: g - 76))
    fork.addLine(to: CGPoint(x: x + 30, y: g - 80))
    ctx.stroke(fork, with: .color(chrome), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    fill(ctx, CGRect(x: x + 44, y: g - 68, width: 10, height: 10), Color(red: 1, green: 0.95, blue: 0.6), corner: 5)
    // Rear fender over the back wheel
    var fender = Path()
    fender.addArc(center: back, radius: 21, startAngle: .degrees(190), endAngle: .degrees(300), clockwise: false)
    ctx.stroke(fender, with: .color(paint), lineWidth: 5)
    guard ridden else { return }
    for k in 0..<4 {
        let u = (now.timeIntervalSinceReferenceDate * 1.6 + Double(k) / 4).truncatingRemainder(dividingBy: 1)
        ctx.fill(circle(CGPoint(x: x - 50 - u * 50, y: g - 24 - u * 18), 5 + u * 9), with: .color(Color(white: 0.6).opacity(0.5 * (1 - u))))
    }
}

/// The repo men's long flatbed tow truck, nose to the right. `x` is the left end of its bed.
func drawFlatbed(_ ctx: GraphicsContext, x: Double, now: Date) {
    let g = Stage.floorY
    let len = Stage.flatbedLength
    let deckTop = g - Stage.flatbedDeck
    let dark = Color(white: 0.20)
    let paint = Color(red: 0.80, green: 0.14, blue: 0.12)
    // Chassis and the steel deck
    fill(ctx, CGRect(x: x + 10, y: g - 24, width: len + 80, height: 10), dark, corner: 3)
    fill(ctx, CGRect(x: x, y: deckTop, width: len, height: 12), Color(white: 0.45), corner: 2)
    for k in stride(from: 0.0, to: len, by: 25) {
        fill(ctx, CGRect(x: x + k, y: deckTop, width: 2, height: 12), Color(white: 0.32))
    }
    fill(ctx, CGRect(x: x, y: deckTop + 9, width: len, height: 3), paint)
    ctx.draw(Text("SHORE COUNTY RECOVERY").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: x + len / 2, y: g - 9))
    // Winch post at the front of the bed
    fill(ctx, CGRect(x: x + len - 14, y: deckTop - 46, width: 12, height: 46), dark, corner: 2)
    fill(ctx, CGRect(x: x + len - 22, y: deckTop - 52, width: 28, height: 8), dark, corner: 3)
    // Cab
    let cab = CGRect(x: x + len, y: g - 104, width: 104, height: 84)
    fill(ctx, cab, paint, corner: 8)
    fill(ctx, CGRect(x: cab.minX + 46, y: cab.minY + 10, width: 50, height: 32), Color(red: 0.75, green: 0.90, blue: 1), corner: 5)
    fill(ctx, CGRect(x: cab.minX + 10, y: cab.minY + 10, width: 30, height: 32), Color(red: 0.75, green: 0.90, blue: 1), corner: 4)
    ctx.draw(Text("REPO").font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white),
             at: CGPoint(x: cab.minX + 34, y: cab.minY + 58))
    fill(ctx, CGRect(x: cab.maxX - 4, y: cab.maxY - 20, width: 8, height: 9), Color(red: 1, green: 0.95, blue: 0.6), corner: 2)
    fill(ctx, CGRect(x: cab.minX + 4, y: cab.maxY - 6, width: cab.width, height: 8), dark, corner: 3)
    // Flashing amber light on the roof
    let on = sin(now.timeIntervalSinceReferenceDate * 9) > 0
    fill(ctx, CGRect(x: cab.minX + 30, y: cab.minY - 8, width: 20, height: 8), Color(red: 1, green: 0.6, blue: 0).opacity(on ? 1 : 0.4), corner: 3)
    if on { ctx.fill(circle(CGPoint(x: cab.minX + 40, y: cab.minY - 4), 18), with: .color(Color(red: 1, green: 0.7, blue: 0.1).opacity(0.3))) }
    for wx in [x + 60, x + 120, x + len - 70, x + len + 70] {
        ctx.fill(circle(CGPoint(x: wx, y: g - 14), 15), with: .color(Color(white: 0.10)))
        ctx.fill(circle(CGPoint(x: wx, y: g - 14), 6), with: .color(Color(white: 0.70)))
    }
}

/// The park's maintenance zamboni (it sweeps and scrubs the lot). The driver sits at the back, facing right.
/// `x` is where the driver sits.
func drawZamboni(_ ctx: GraphicsContext, x: Double, now: Date) {
    let c = ctx
    let ground = Stage.floorY
    let blue = Color(red: 0.15, green: 0.40, blue: 0.75)
    // Body: the driver sits down inside it, up to her waist
    fill(c, CGRect(x: x - 34, y: ground - 54, width: 134, height: 40), .white, corner: 8)
    fill(c, CGRect(x: x - 34, y: ground - 34, width: 134, height: 14), blue)
    c.draw(Text("FUNLAND MAINT.").font(.system(size: 9, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: x + 33, y: ground - 27))
    // Steering column and wheel
    fill(c, CGRect(x: x + 24, y: ground - 80, width: 4, height: 28), Color(white: 0.25))
    c.stroke(Path(ellipseIn: CGRect(x: x + 14, y: ground - 86, width: 22, height: 8)), with: .color(Color(white: 0.15)), lineWidth: 3)
    // The scrubber box out front
    fill(c, CGRect(x: x + 100, y: ground - 32, width: 26, height: 20), Color(red: 0.95, green: 0.70, blue: 0.15), corner: 4)
    // Amber light on a post
    let blink = sin(now.timeIntervalSinceReferenceDate * 8) > 0
    fill(c, CGRect(x: x + 72, y: ground - 70, width: 3, height: 16), Color(white: 0.3))
    c.fill(circle(CGPoint(x: x + 73.5, y: ground - 72), 6), with: .color(Color.orange.opacity(blink ? 1 : 0.4)))
    // Wheels
    for wx in [x - 8, x + 78] { c.fill(circle(CGPoint(x: wx, y: ground - 12), 13), with: .color(Color(white: 0.1))) }
}

