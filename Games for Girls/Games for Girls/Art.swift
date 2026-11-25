import SwiftUI

// MARK: - People

enum BoyHair: Int, Codable { case short, buzz, curly, spiky }
enum GirlHair: Int, Codable { case long, ponytail, pigtails, bob }
enum Mood { case happy, sad, angry, surprised, tired, neutral, laughing }
enum Arms { case down, up, wave, point, mop, fight, carry, strapped, hands, breakMop, snicker }

struct Look: Codable, Equatable {
    var skin: [Double]
    var hair: [Double]
    var shirt: [Double]
    var pants: [Double]
    var dress: [Double]
    var boyHair: BoyHair = .short
    var girlHair: GirlHair = .long
    /// Teen kids are drawn a bit shorter with bigger heads.
    var kid = true
    /// Already a woman (hostess, mom, bank lady) – always drawn fully female.
    var woman = false
    var bald = false
    var cap: [Double]? = nil

    static func rgb(_ c: [Double]) -> Color { Color(red: c[0], green: c[1], blue: c[2]) }
}

enum Palette {
    static let skins: [[Double]] = [[0.98, 0.84, 0.72], [0.9, 0.7, 0.55], [0.72, 0.52, 0.38], [0.52, 0.36, 0.25], [0.96, 0.8, 0.66]]
    static let hairs: [[Double]] = [[0.35, 0.2, 0.08], [0.95, 0.82, 0.45], [0.1, 0.07, 0.05], [0.7, 0.3, 0.1], [0.55, 0.4, 0.25]]
    static let shirts: [[Double]] = [[0.2, 0.45, 0.85], [0.85, 0.2, 0.2], [0.2, 0.65, 0.35], [0.95, 0.7, 0.15], [0.45, 0.3, 0.7], [0.3, 0.3, 0.35]]
    static let dresses: [[Double]] = [[1, 0.45, 0.7], [0.75, 0.5, 0.95], [0.4, 0.85, 0.75], [1, 0.6, 0.4], [0.95, 0.3, 0.5], [0.55, 0.75, 1]]
    static let pink = Color(red: 1, green: 0.42, blue: 0.68)
    static let green = Color(red: 0.2, green: 0.72, blue: 0.4)
}

// MARK: - Cast

enum Cast {
    static let elmer = Look(skin: Palette.skins[0], hair: Palette.hairs[0], shirt: [0.2, 0.45, 0.85], pants: [0.25, 0.25, 0.5], dress: [1, 0.45, 0.7], boyHair: .short, girlHair: .long)
    static let chris = Look(skin: Palette.skins[2], hair: Palette.hairs[2], shirt: [0.85, 0.2, 0.2], pants: [0.3, 0.3, 0.3], dress: [0.75, 0.5, 0.95], boyHair: .curly, girlHair: .pigtails)
    static let danny = Look(skin: Palette.skins[4], hair: Palette.hairs[3], shirt: [0.2, 0.65, 0.35], pants: [0.35, 0.28, 0.2], dress: [0.4, 0.85, 0.75], boyHair: .spiky, girlHair: .ponytail)
    static let kids = [elmer, chris, danny]
    static let boss = Look(skin: [0.95, 0.75, 0.62], hair: [0.3, 0.3, 0.3], shirt: [0.55, 0.55, 0.6], pants: [0.15, 0.15, 0.2], dress: [0, 0, 0], kid: false, bald: true)
    static let repo1 = Look(skin: Palette.skins[1], hair: Palette.hairs[2], shirt: [0.95, 0.5, 0.1], pants: [0.2, 0.25, 0.4], dress: [0, 0, 0], boyHair: .buzz, kid: false, cap: [0.15, 0.15, 0.15])
    static let repo2 = Look(skin: Palette.skins[3], hair: Palette.hairs[2], shirt: [0.95, 0.5, 0.1], pants: [0.2, 0.25, 0.4], dress: [0, 0, 0], boyHair: .short, kid: false, cap: [0.15, 0.15, 0.15])
    static let bank1 = Look(skin: Palette.skins[0], hair: Palette.hairs[4], shirt: [0.12, 0.15, 0.3], pants: [0.12, 0.15, 0.3], dress: [0, 0, 0], boyHair: .short, kid: false)
    static let bank2 = Look(skin: Palette.skins[1], hair: Palette.hairs[2], shirt: [0.12, 0.15, 0.3], pants: [0.12, 0.15, 0.3], dress: [0.12, 0.15, 0.3], girlHair: .bob, kid: false, woman: true)
    static let customs = Look(skin: Palette.skins[1], hair: Palette.hairs[2], shirt: [0.15, 0.25, 0.5], pants: [0.12, 0.15, 0.3], dress: [0, 0, 0], boyHair: .short, kid: false, cap: [0.1, 0.15, 0.35])
    static let power = Look(skin: Palette.skins[2], hair: Palette.hairs[0], shirt: [0.95, 0.82, 0.1], pants: [0.2, 0.25, 0.4], dress: [0, 0, 0], boyHair: .short, kid: false, cap: [0.95, 0.95, 0.95])
    static let hostess = Look(skin: Palette.skins[0], hair: [0.55, 0.1, 0.3], shirt: [0, 0, 0], pants: [0, 0, 0], dress: [0.85, 0.15, 0.55], girlHair: .long, kid: false, woman: true)
    static let teller = Look(skin: Palette.skins[4], hair: Palette.hairs[1], shirt: [0, 0, 0], pants: [0, 0, 0], dress: [0.2, 0.5, 0.45], girlHair: .long, kid: false, woman: true)
    static let mom = Look(skin: Palette.skins[0], hair: Palette.hairs[0], shirt: [0, 0, 0], pants: [0, 0, 0], dress: [0.4, 0.6, 0.9], girlHair: .bob, kid: false, woman: true)
}

// MARK: - Backgrounds

func sky(_ ctx: inout GraphicsContext, _ size: CGSize, top: Color, bottom: Color) {
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
}

func drawBoardwalk(_ ctx: inout GraphicsContext, _ size: CGSize, evening: Bool = false) {
    sky(&ctx, size, top: evening ? Color(red: 0.95, green: 0.55, blue: 0.4) : Color(red: 0.45, green: 0.75, blue: 1), bottom: evening ? Color(red: 1, green: 0.8, blue: 0.6) : Color(red: 0.8, green: 0.92, blue: 1))
    ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.8, y: 20, width: 34, height: 34)), with: .color(evening ? .orange : .yellow))
    // ocean
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.45, width: size.width, height: size.height * 0.2)), with: .color(Color(red: 0.15, green: 0.45, blue: 0.75)))
    for i in 0..<12 {
        let x = CGFloat(i) * size.width / 11
        var w = Path(); w.move(to: CGPoint(x: x, y: size.height * 0.5)); w.addQuadCurve(to: CGPoint(x: x + 20, y: size.height * 0.5), control: CGPoint(x: x + 10, y: size.height * 0.48))
        ctx.stroke(w, with: .color(.white.opacity(0.6)), lineWidth: 1)
    }
    // sand + boardwalk planks
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.63, width: size.width, height: size.height * 0.05)), with: .color(Color(red: 0.95, green: 0.85, blue: 0.6)))
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.68, width: size.width, height: size.height * 0.32)), with: .color(Color(red: 0.7, green: 0.5, blue: 0.3)))
    for i in 0..<30 {
        let x = CGFloat(i) * 16
        var p = Path(); p.move(to: CGPoint(x: x, y: size.height * 0.68)); p.addLine(to: CGPoint(x: x - 30, y: size.height))
        ctx.stroke(p, with: .color(Color(red: 0.5, green: 0.35, blue: 0.2)), lineWidth: 1)
    }
    // railing
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.6, width: size.width, height: 3)), with: .color(.white))
    for i in 0..<20 { ctx.fill(Path(CGRect(x: CGFloat(i) * 22, y: size.height * 0.6, width: 2, height: size.height * 0.08)), with: .color(.white)) }
}

/// A long wooden pier running out to sea. `offset` scrolls the planks/posts (walking), `end` is the x where the pier stops.
func drawPier(_ ctx: inout GraphicsContext, _ size: CGSize, offset: CGFloat, end: CGFloat) {
    sky(&ctx, size, top: Color(red: 0.95, green: 0.55, blue: 0.4), bottom: Color(red: 1, green: 0.8, blue: 0.6))
    ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.12, y: 26, width: 34, height: 34)), with: .color(.orange))
    let sea = size.height * 0.42
    ctx.fill(Path(CGRect(x: 0, y: sea, width: size.width, height: size.height - sea)), with: .color(Color(red: 0.15, green: 0.45, blue: 0.75)))
    for row in 0..<4 {
        for i in 0..<12 {
            let x = (CGFloat(i) * 40 - offset * 0.3 + CGFloat(row) * 17).truncatingRemainder(dividingBy: size.width + 40) - 20
            let y = sea + 8 + CGFloat(row) * 14
            var w = Path(); w.move(to: CGPoint(x: x, y: y)); w.addQuadCurve(to: CGPoint(x: x + 18, y: y), control: CGPoint(x: x + 9, y: y - 3))
            ctx.stroke(w, with: .color(.white.opacity(0.5)), lineWidth: 1)
        }
    }
    let top = size.height * 0.8, front = size.height * 0.91
    let wood = Color(red: 0.7, green: 0.5, blue: 0.3), dark = Color(red: 0.45, green: 0.3, blue: 0.18)
    // pilings
    var px = -(offset.truncatingRemainder(dividingBy: 50))
    while px < end {
        ctx.fill(Path(CGRect(x: px + 4, y: front, width: 8, height: size.height - front)), with: .color(dark))
        px += 50
    }
    // deck
    ctx.fill(Path(CGRect(x: 0, y: top, width: end, height: front - top)), with: .color(wood))
    var kx = -(offset.truncatingRemainder(dividingBy: 14))
    while kx < end {
        var l = Path(); l.move(to: CGPoint(x: kx, y: top)); l.addLine(to: CGPoint(x: kx - 6, y: front))
        ctx.stroke(l, with: .color(dark.opacity(0.6)), lineWidth: 1)
        kx += 14
    }
    ctx.fill(Path(CGRect(x: 0, y: front - 3, width: end, height: 3)), with: .color(dark))
    // back railing + lamp posts
    ctx.fill(Path(CGRect(x: 0, y: top - 22, width: end, height: 3)), with: .color(.white))
    var rx = -(offset.truncatingRemainder(dividingBy: 22))
    while rx < end { ctx.fill(Path(CGRect(x: rx, y: top - 22, width: 2, height: 22)), with: .color(.white)); rx += 22 }
    var lx = -(offset.truncatingRemainder(dividingBy: 120)) + 40
    while lx < end - 10 {
        ctx.fill(Path(CGRect(x: lx, y: top - 70, width: 3, height: 70)), with: .color(Color(white: 0.25)))
        ctx.fill(Path(ellipseIn: CGRect(x: lx - 5, y: top - 80, width: 13, height: 13)), with: .color(Color(red: 1, green: 0.95, blue: 0.7)))
        lx += 120
    }
    // end post of the pier
    ctx.fill(Path(CGRect(x: end - 6, y: top - 30, width: 8, height: front - top + 30)), with: .color(dark))
}

func drawArcade(_ ctx: inout GraphicsContext, _ size: CGSize, machines: Int = 6, sign: String = "FUN ZONE ARCADE", lightsOn: Bool = true) {
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(lightsOn ? Color(red: 0.16, green: 0.1, blue: 0.3) : Color(red: 0.06, green: 0.05, blue: 0.1)))
    // checkered floor
    let fy = size.height * 0.72
    for i in 0..<24 {
        for j in 0..<4 {
            if (i + j) % 2 == 0 {
                ctx.fill(Path(CGRect(x: CGFloat(i) * 18, y: fy + CGFloat(j) * 18, width: 18, height: 18)), with: .color(.white.opacity(0.12)))
            }
        }
    }
    ctx.draw(Text(sign).font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(lightsOn ? Color.yellow : Color.gray), at: CGPoint(x: size.width / 2, y: 18))
    let colors: [Color] = [.red, .blue, .purple, .orange, .teal, .pink, .green]
    for i in 0..<machines {
        let x = 20 + CGFloat(i) * 62
        drawCabinet(&ctx, CGRect(x: x, y: fy - 90, width: 40, height: 90), color: colors[i % colors.count], screenOn: lightsOn)
    }
}

func drawCabinet(_ ctx: inout GraphicsContext, _ r: CGRect, color: Color, screenOn: Bool = true) {
    ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(color))
    ctx.fill(Path(CGRect(x: r.minX + 5, y: r.minY + 10, width: r.width - 10, height: r.height * 0.32)), with: .color(screenOn ? Color(red: 0.3, green: 1, blue: 0.8) : .black))
    ctx.fill(Path(CGRect(x: r.minX + 3, y: r.minY + r.height * 0.5, width: r.width - 6, height: 8)), with: .color(Color(white: 0.2)))
    ctx.fill(Path(ellipseIn: CGRect(x: r.minX + 8, y: r.minY + r.height * 0.5 - 3, width: 5, height: 5)), with: .color(.red))
    ctx.fill(Path(ellipseIn: CGRect(x: r.minX + 18, y: r.minY + r.height * 0.5 - 3, width: 5, height: 5)), with: .color(.yellow))
}

func drawTruck(_ ctx: inout GraphicsContext, at p: CGPoint, scale s: CGFloat = 1, label: String = "REPO", load: Int = 0, color: Color = Color(red: 0.9, green: 0.9, blue: 0.92)) {
    let body = CGRect(x: p.x, y: p.y - 60 * s, width: 120 * s, height: 50 * s)
    ctx.fill(Path(roundedRect: body, cornerRadius: 3), with: .color(color))
    ctx.fill(Path(roundedRect: CGRect(x: p.x + 120 * s, y: p.y - 45 * s, width: 34 * s, height: 35 * s), cornerRadius: 5), with: .color(Color(red: 0.9, green: 0.4, blue: 0.1)))
    ctx.fill(Path(CGRect(x: p.x + 132 * s, y: p.y - 40 * s, width: 16 * s, height: 12 * s)), with: .color(Color(red: 0.6, green: 0.85, blue: 1)))
    ctx.draw(Text(label).font(.system(size: 14 * s, weight: .heavy)).foregroundStyle(.red), at: CGPoint(x: body.midX, y: body.midY))
    for x in [p.x + 20 * s, p.x + 95 * s, p.x + 140 * s] {
        ctx.fill(Path(ellipseIn: CGRect(x: x - 9 * s, y: p.y - 14 * s, width: 18 * s, height: 18 * s)), with: .color(.black))
    }
    let colors: [Color] = [.red, .blue, .purple, .orange, .teal, .pink]
    for i in 0..<min(load, 6) {
        drawCabinet(&ctx, CGRect(x: p.x + CGFloat(i % 3) * 38 * s + 4 * s, y: p.y - 60 * s - 34 * s - CGFloat(i / 3) * 8 * s, width: 30 * s, height: 34 * s), color: colors[i])
    }
}

/// A maintenance zamboni (floor scrubber). The driver sits inside it up to the waist.
func drawZamboni(_ ctx: inout GraphicsContext, x: CGFloat, floor: CGFloat, s: CGFloat = 1, driver: Look? = nil,
                 driverH: CGFloat = 84, mood: Mood = .neutral, arms: Arms = .carry, t: Double = 0, light: Bool = true) {
    let blue = Color(red: 0.15, green: 0.40, blue: 0.75)
    if let driver {
        drawPerson(&ctx, look: driver, feet: CGPoint(x: x + 4 * s, y: floor - 4 * s), h: driverH, mood: mood, arms: arms, facing: 1)
    }
    // steering column and wheel
    ctx.fill(Path(CGRect(x: x + 24 * s, y: floor - 80 * s, width: 4 * s, height: 28 * s)), with: .color(Color(white: 0.25)))
    ctx.stroke(Path(ellipseIn: CGRect(x: x + 14 * s, y: floor - 86 * s, width: 22 * s, height: 8 * s)), with: .color(Color(white: 0.15)), lineWidth: 3 * s)
    // body
    ctx.fill(Path(roundedRect: CGRect(x: x - 34 * s, y: floor - 54 * s, width: 134 * s, height: 40 * s), cornerRadius: 8 * s), with: .color(.white))
    ctx.fill(Path(CGRect(x: x - 34 * s, y: floor - 34 * s, width: 134 * s, height: 14 * s)), with: .color(blue))
    ctx.draw(Text("FUN ZONE MAINT.").font(.system(size: 9 * s, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: x + 33 * s, y: floor - 27 * s))
    // scrubber box out front
    ctx.fill(Path(roundedRect: CGRect(x: x + 100 * s, y: floor - 32 * s, width: 26 * s, height: 20 * s), cornerRadius: 4 * s), with: .color(Color(red: 0.95, green: 0.70, blue: 0.15)))
    // amber light on a post
    ctx.fill(Path(CGRect(x: x + 72 * s, y: floor - 70 * s, width: 3 * s, height: 16 * s)), with: .color(Color(white: 0.3)))
    let blink = light && sin(t * 8) > 0
    ctx.fill(Path(ellipseIn: CGRect(x: x + 67.5 * s, y: floor - 78 * s, width: 12 * s, height: 12 * s)), with: .color(Color.orange.opacity(blink ? 1 : 0.4)))
    // wheels
    for wx in [x - 8 * s, x + 78 * s] {
        ctx.fill(Path(ellipseIn: CGRect(x: wx - 13 * s, y: floor - 25 * s, width: 26 * s, height: 26 * s)), with: .color(Color(white: 0.1)))
    }
}

/// The arcade's electric meter + breaker box on the wall; lever up = on.
func drawBreakerBox(_ ctx: inout GraphicsContext, at p: CGPoint, on: Bool) {
    let r = CGRect(x: p.x, y: p.y, width: 34, height: 48)
    ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(Color(white: 0.62)))
    ctx.stroke(Path(roundedRect: r, cornerRadius: 3), with: .color(Color(white: 0.3)), lineWidth: 1.5)
    ctx.fill(Path(ellipseIn: CGRect(x: p.x + 7, y: p.y + 4, width: 20, height: 20)), with: .color(Color(white: 0.9)))
    ctx.draw(Text("kWh").font(.system(size: 6, weight: .bold)).foregroundStyle(.black), at: CGPoint(x: p.x + 17, y: p.y + 14))
    ctx.fill(Path(CGRect(x: p.x + 14, y: p.y + 28, width: 6, height: 16)), with: .color(Color(white: 0.25)))
    ctx.fill(Path(roundedRect: CGRect(x: p.x + 11, y: on ? p.y + 27 : p.y + 37, width: 12, height: 8), cornerRadius: 2), with: .color(on ? .green : .red))
}

func drawTrike(_ ctx: inout GraphicsContext, at p: CGPoint, scale s: CGFloat = 1) {
    ctx.fill(Path(roundedRect: CGRect(x: p.x, y: p.y - 30 * s, width: 50 * s, height: 14 * s), cornerRadius: 5), with: .color(.red))
    ctx.fill(Path(roundedRect: CGRect(x: p.x + 10 * s, y: p.y - 42 * s, width: 16 * s, height: 14 * s), cornerRadius: 4), with: .color(.black))
    var bar = Path(); bar.move(to: CGPoint(x: p.x + 48 * s, y: p.y - 30 * s)); bar.addLine(to: CGPoint(x: p.x + 56 * s, y: p.y - 48 * s))
    ctx.stroke(bar, with: .color(Color(white: 0.7)), lineWidth: 3 * s)
    for (x, r) in [(p.x + 6 * s, 11 * s), (p.x + 24 * s, 11 * s), (p.x + 55 * s, 9 * s)] {
        ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: p.y - r * 2, width: r * 2, height: r * 2)), with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.4, y: p.y - r * 1.4, width: r * 0.8, height: r * 0.8)), with: .color(.gray))
    }
}

func drawShip(_ ctx: inout GraphicsContext, x: CGFloat, waterline y: CGFloat, w: CGFloat, gangway: Bool = false) {
    let h = w * 0.22
    var hull = Path()
    hull.move(to: CGPoint(x: x, y: y - h))
    hull.addLine(to: CGPoint(x: x + w, y: y - h))
    hull.addLine(to: CGPoint(x: x + w * 0.93, y: y + h * 0.15))
    hull.addLine(to: CGPoint(x: x + w * 0.05, y: y + h * 0.15))
    hull.closeSubpath()
    ctx.fill(hull, with: .color(Color(red: 0.95, green: 0.4, blue: 0.65)))
    ctx.fill(Path(CGRect(x: x + w * 0.02, y: y - h * 0.35, width: w * 0.95, height: h * 0.12)), with: .color(.white))
    // decks
    ctx.fill(Path(roundedRect: CGRect(x: x + w * 0.12, y: y - h * 1.9, width: w * 0.72, height: h * 0.9), cornerRadius: 4), with: .color(.white))
    ctx.fill(Path(roundedRect: CGRect(x: x + w * 0.25, y: y - h * 2.6, width: w * 0.45, height: h * 0.7), cornerRadius: 4), with: .color(Color(white: 0.95)))
    for i in 0..<12 {
        ctx.fill(Path(ellipseIn: CGRect(x: x + w * 0.15 + CGFloat(i) * w * 0.055, y: y - h * 1.6, width: w * 0.03, height: w * 0.03)), with: .color(Color(red: 0.3, green: 0.6, blue: 0.95)))
    }
    // funnel
    ctx.fill(Path(CGRect(x: x + w * 0.55, y: y - h * 3.4, width: w * 0.09, height: h * 0.8)), with: .color(Color(red: 0.2, green: 0.75, blue: 0.45)))
    drawShipExtras(&ctx, x: x, y: y, w: w, h: h)
    ctx.draw(Text("GAMES FOR GIRLS").font(.system(size: max(6, w * 0.06), weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: x + w * 0.5, y: y - h * 0.65))
    if gangway {
        var gw = Path(); gw.move(to: CGPoint(x: x + w * 0.2, y: y - h * 0.9)); gw.addLine(to: CGPoint(x: x + w * 0.05, y: y + h * 0.9))
        ctx.stroke(gw, with: .color(Color(white: 0.6)), lineWidth: 4)
    }
}

func drawLivingRoom(_ ctx: inout GraphicsContext, _ size: CGSize, night: Bool = false) {
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.98, green: 0.9, blue: 0.78)))
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.72, width: size.width, height: size.height * 0.28)), with: .color(Color(red: 0.6, green: 0.4, blue: 0.3)))
    // window
    let win = CGRect(x: 30, y: 30, width: 80, height: 60)
    ctx.fill(Path(win), with: .color(night ? Color(red: 0.1, green: 0.1, blue: 0.3) : Color(red: 0.6, green: 0.85, blue: 1)))
    ctx.stroke(Path(win), with: .color(.white), lineWidth: 4)
    // couch
    ctx.fill(Path(roundedRect: CGRect(x: size.width - 170, y: size.height * 0.52, width: 140, height: 50), cornerRadius: 10), with: .color(Color(red: 0.5, green: 0.3, blue: 0.5)))
    // lamp
    ctx.fill(Path(CGRect(x: size.width - 20, y: size.height * 0.35, width: 3, height: size.height * 0.37)), with: .color(.gray))
    ctx.fill(Path(CGRect(x: size.width - 32, y: size.height * 0.28, width: 28, height: 18)), with: .color(.yellow.opacity(0.8)))
}

func drawSecretRoom(_ ctx: inout GraphicsContext, _ size: CGSize, glow: Double = 0) {
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.12, green: 0.05, blue: 0.18)))
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.75, width: size.width, height: size.height * 0.25)), with: .color(Color(red: 0.25, green: 0.12, blue: 0.3)))
    // control panel lights
    for i in 0..<10 {
        let on = (Int(glow * 20) + i) % 3 == 0
        ctx.fill(Path(ellipseIn: CGRect(x: 20 + CGFloat(i) * 36, y: 14, width: 8, height: 8)), with: .color(on ? Palette.pink : .purple.opacity(0.5)))
    }
}

/// A transformation chair with a helmet that lowers over the head. Returns the seat point for a seated person (feet point).
func drawChair(_ ctx: inout GraphicsContext, x: CGFloat, floor: CGFloat, helmet: Double, beam: Double, t: Double) {
    ctx.fill(Path(roundedRect: CGRect(x: x - 24, y: floor - 90, width: 48, height: 70), cornerRadius: 8), with: .color(Color(red: 0.55, green: 0.2, blue: 0.5)))
    ctx.fill(Path(CGRect(x: x - 26, y: floor - 30, width: 56, height: 10)), with: .color(Color(red: 0.45, green: 0.15, blue: 0.4)))
    ctx.fill(Path(CGRect(x: x - 4, y: floor - 32, width: 8, height: 32)), with: .color(.gray))
    // arm on the back holding the helmet
    let hy = floor - 150 + CGFloat(helmet) * 62
    ctx.fill(Path(CGRect(x: x + 22, y: floor - 160, width: 5, height: 80)), with: .color(.gray))
    ctx.fill(Path(CGRect(x: x - 5, y: floor - 160, width: 30, height: 5)), with: .color(.gray))
    var dome = Path()
    dome.addArc(center: CGPoint(x: x, y: hy + 18), radius: 22, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
    dome.closeSubpath()
    ctx.fill(dome, with: .color(Color(white: 0.85)))
    ctx.fill(Path(ellipseIn: CGRect(x: x - 4, y: hy - 6, width: 8, height: 8)), with: .color(beam > 0 ? Palette.pink : .gray))
    if beam > 0 {
        var b = Path()
        b.move(to: CGPoint(x: x - 20, y: hy + 18)); b.addLine(to: CGPoint(x: x + 20, y: hy + 18))
        b.addLine(to: CGPoint(x: x + 30, y: floor - 20)); b.addLine(to: CGPoint(x: x - 30, y: floor - 20)); b.closeSubpath()
        ctx.fill(b, with: .color(Palette.pink.opacity(0.25 * beam + 0.1 * sin(t * 12))))
        for k in 0..<6 {
            let sx = x + CGFloat(sin(t * 3 + Double(k) * 1.7)) * 24
            let sy = floor - 30 - CGFloat((t * 60 + Double(k) * 23).truncatingRemainder(dividingBy: 110))
            ctx.fill(Path(ellipseIn: CGRect(x: sx - 2, y: sy - 2, width: 4, height: 4)), with: .color(.white.opacity(beam)))
        }
    }
}

func drawMirror(_ ctx: inout GraphicsContext, _ r: CGRect) {
    ctx.fill(Path(roundedRect: r.insetBy(dx: -6, dy: -6), cornerRadius: 14), with: .color(Color(red: 0.85, green: 0.7, blue: 0.3)))
    ctx.fill(Path(roundedRect: r, cornerRadius: 10), with: .linearGradient(Gradient(colors: [Color(red: 0.8, green: 0.9, blue: 1), Color(red: 0.6, green: 0.7, blue: 0.85)]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX, y: r.maxY)))
}

func drawGameLounge(_ ctx: inout GraphicsContext, _ size: CGSize) {
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [Color(red: 0.98, green: 0.75, blue: 0.85), Color(red: 0.85, green: 0.95, blue: 0.85)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    for i in 0..<5 {
        ctx.fill(Path(ellipseIn: CGRect(x: 30 + CGFloat(i) * 80, y: 30, width: 26, height: 26)), with: .color(Color(red: 0.4, green: 0.7, blue: 1)))
        ctx.stroke(Path(ellipseIn: CGRect(x: 30 + CGFloat(i) * 80, y: 30, width: 26, height: 26)), with: .color(.white), lineWidth: 3)
    }
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.75, width: size.width, height: size.height * 0.25)), with: .color(Color(red: 0.55, green: 0.3, blue: 0.45)))
    // game table
    ctx.fill(Path(ellipseIn: CGRect(x: size.width / 2 - 90, y: size.height * 0.62, width: 180, height: 40)), with: .color(Color(red: 0.1, green: 0.5, blue: 0.3)))
    ctx.fill(Path(CGRect(x: size.width / 2 - 6, y: size.height * 0.68, width: 12, height: size.height * 0.1)), with: .color(Color(red: 0.4, green: 0.25, blue: 0.15)))
}

func dust(_ ctx: inout GraphicsContext, at c: CGPoint, r: CGFloat, t: Double) {
    for k in 0..<9 {
        let a = Double(k) * 0.7 + t * 5
        let p = CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.6, y: c.y + CGFloat(sin(a * 1.3)) * r * 0.4)
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r * 0.35, y: p.y - r * 0.35, width: r * 0.7, height: r * 0.7)), with: .color(Color(white: 0.85, opacity: 0.85)))
    }
    for k in 0..<4 {
        let a = Double(k) * 1.6 + t * 9
        ctx.draw(Text(["POW", "BAM", "★", "!"][k]).font(.system(size: r * 0.3, weight: .black)).foregroundStyle(.red), at: CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.7, y: c.y + CGFloat(sin(a)) * r * 0.45))
    }
}

/// Arcade storefront seen from the boardwalk.
func drawArcadeFront(_ ctx: inout GraphicsContext, x: CGFloat, floor: CGFloat) {
    let r = CGRect(x: x, y: floor - 140, width: 160, height: 140)
    ctx.fill(Path(r), with: .color(Color(red: 0.3, green: 0.15, blue: 0.45)))
    ctx.fill(Path(CGRect(x: x - 4, y: r.minY - 4, width: 168, height: 26)), with: .color(Color(red: 0.95, green: 0.3, blue: 0.5)))
    ctx.draw(Text("FUN ZONE ARCADE").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.yellow), at: CGPoint(x: r.midX, y: r.minY + 9))
    ctx.fill(Path(CGRect(x: x + 60, y: floor - 70, width: 40, height: 70)), with: .color(Color(red: 0.15, green: 0.08, blue: 0.2)))
    for (i, c) in [Color.red, .blue, .orange].enumerated() where i != 1 {
        drawCabinet(&ctx, CGRect(x: x + 12 + CGFloat(i) * 52, y: floor - 95, width: 34, height: 60), color: c)
    }
}

/// Mom's car. `driver` is drawn sitting behind the front window.
func drawCar(_ ctx: inout GraphicsContext, x: CGFloat, ground: CGFloat, driver: Look?, driverMood: Mood = .happy, kids: Bool = false, kidGirl: Double = 0, doorOpen: Bool = false) {
    let body = CGRect(x: x, y: ground - 42, width: 150, height: 30)
    let cabin = CGRect(x: x + 28, y: ground - 70, width: 90, height: 30)
    let paint = Color(red: 0.25, green: 0.55, blue: 0.85)
    ctx.fill(Path(roundedRect: cabin, cornerRadius: 12), with: .color(paint))
    let front = CGRect(x: cabin.minX + 50, y: cabin.minY + 5, width: 34, height: 24)
    let back = CGRect(x: cabin.minX + 8, y: cabin.minY + 5, width: 38, height: 24)
    for w in [front, back] { ctx.fill(Path(roundedRect: w, cornerRadius: 4), with: .color(Color(red: 0.75, green: 0.9, blue: 1))) }
    if let driver {
        var c = ctx
        c.clip(to: Path(roundedRect: front, cornerRadius: 4))
        drawPerson(&c, look: driver, feet: CGPoint(x: front.midX, y: front.maxY + 55), h: 82, mood: driverMood, arms: driverMood == .happy ? .wave : .down, facing: 1)
    }
    if kids {
        var c = ctx
        c.clip(to: Path(roundedRect: back, cornerRadius: 4))
        for (i, k) in Cast.kids.enumerated() {
            drawPerson(&c, look: k, feet: CGPoint(x: back.minX + 7 + CGFloat(i) * 12, y: back.maxY + 50), h: 68, girl: kidGirl, mood: kidGirl > 0 ? .happy : .tired)
        }
    }
    ctx.fill(Path(roundedRect: body, cornerRadius: 10), with: .color(paint))
    if doorOpen {
        var d = Path()
        d.move(to: CGPoint(x: x + 120, y: ground - 62)); d.addLine(to: CGPoint(x: x + 150, y: ground - 70))
        d.addLine(to: CGPoint(x: x + 150, y: ground - 22)); d.addLine(to: CGPoint(x: x + 120, y: ground - 14)); d.closeSubpath()
        ctx.fill(d, with: .color(paint.opacity(0.9)))
        ctx.stroke(d, with: .color(.black.opacity(0.3)), lineWidth: 1)
    }
    ctx.fill(Path(ellipseIn: CGRect(x: x + 144, y: ground - 36, width: 8, height: 7)), with: .color(.yellow))
    ctx.fill(Path(CGRect(x: x - 1, y: ground - 34, width: 5, height: 6)), with: .color(.red))
    for wx in [x + 32, x + 118] {
        ctx.fill(Path(ellipseIn: CGRect(x: wx - 13, y: ground - 26, width: 26, height: 26)), with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: wx - 6, y: ground - 19, width: 12, height: 12)), with: .color(.gray))
    }
}

/// Three side-by-side rooms, one per girl: their bedrooms at home (redesigned for girls) or their cabins on the ship.
/// `asleep` dims the lights over `p` and tucks each girl into bed.
func drawGirlRooms(_ ctx: inout GraphicsContext, _ size: CGSize, cabins: Bool, asleep: Bool, p: Double, t: Double, morning: Bool = false) {
    let w = size.width / 3
    let names = ["Ellie", "Christina", "Deirdre"]
    for i in 0..<3 {
        let look = Cast.kids[i]
        let rect = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: size.height)
        var room = ctx
        room.clip(to: Path(rect))
        room.translateBy(x: rect.minX, y: 0)
        let dress = look.dress
        let wall = Color(red: dress[0] * 0.3 + 0.7, green: dress[1] * 0.3 + 0.7, blue: dress[2] * 0.3 + 0.7)
        let floorY = size.height * 0.8
        if cabins {
            room.fill(Path(CGRect(x: 0, y: 0, width: w, height: floorY)), with: .color(wall))
            // wood paneling stripe + porthole
            room.fill(Path(CGRect(x: 0, y: floorY - 40, width: w, height: 40)), with: .color(Color(red: 0.65, green: 0.45, blue: 0.3)))
            let ph = CGRect(x: w / 2 - 22, y: 34, width: 44, height: 44)
            room.fill(Path(ellipseIn: ph.insetBy(dx: -5, dy: -5)), with: .color(Color(red: 0.8, green: 0.65, blue: 0.3)))
            let night = !morning
            room.fill(Path(ellipseIn: ph), with: .color(night ? Color(red: 0.08, green: 0.1, blue: 0.3) : Color(red: 0.55, green: 0.8, blue: 1)))
            var sea = room
            sea.clip(to: Path(ellipseIn: ph))
            let waveY = ph.midY + 6 + CGFloat(sin(t * 1.5)) * 3
            sea.fill(Path(CGRect(x: ph.minX, y: waveY, width: ph.width, height: ph.height)), with: .color(Color(red: 0.1, green: 0.35, blue: 0.65)))
            if night { sea.fill(Path(ellipseIn: CGRect(x: ph.minX + 8, y: ph.minY + 6, width: 9, height: 9)), with: .color(Color(white: 0.95))) }
            else { sea.fill(Path(ellipseIn: CGRect(x: ph.maxX - 18, y: ph.minY + 6, width: 11, height: 11)), with: .color(.yellow)) }
            // life ring on the wall
            room.stroke(Path(ellipseIn: CGRect(x: 10, y: 90, width: 22, height: 22)), with: .color(.red), lineWidth: 5)
            room.stroke(Path(ellipseIn: CGRect(x: 10, y: 90, width: 22, height: 22)), with: .color(.white), style: StrokeStyle(lineWidth: 5, dash: [6, 6]))
        } else {
            room.fill(Path(CGRect(x: 0, y: 0, width: w, height: floorY)), with: .color(wall))
            // wallpaper hearts
            for k in 0..<10 {
                let x = CGFloat((k * 37) % Int(w)), y = CGFloat(20 + (k * 53) % 120)
                room.draw(Text("♥").font(.system(size: 9)).foregroundStyle(Look.rgb(dress).opacity(0.45)), at: CGPoint(x: x + 6, y: y))
            }
            // twinkle lights along the ceiling
            for k in 0..<8 {
                let x = 8 + CGFloat(k) * (w - 16) / 7
                let on = 0.5 + 0.5 * sin(t * 3 + Double(k + i * 3))
                room.fill(Path(ellipseIn: CGRect(x: x - 3, y: 10 + CGFloat(k % 2) * 4, width: 6, height: 6)), with: .color(Color.yellow.opacity(0.4 + 0.6 * on)))
            }
            // vanity with mirror
            room.fill(Path(roundedRect: CGRect(x: w - 38, y: floorY - 34, width: 32, height: 34), cornerRadius: 3), with: .color(.white))
            room.fill(Path(ellipseIn: CGRect(x: w - 34, y: floorY - 66, width: 24, height: 30)), with: .color(Color(red: 0.85, green: 0.7, blue: 0.3)))
            room.fill(Path(ellipseIn: CGRect(x: w - 31, y: floorY - 63, width: 18, height: 24)), with: .color(Color(red: 0.75, green: 0.88, blue: 1)))
            // name sign
            room.fill(Path(roundedRect: CGRect(x: 8, y: 26, width: 62, height: 16), cornerRadius: 8), with: .color(.white))
            room.draw(Text(names[i]).font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(Look.rgb(dress)), at: CGPoint(x: 39, y: 34))
        }
        room.fill(Path(CGRect(x: 0, y: floorY, width: w, height: size.height - floorY)), with: .color(cabins ? Color(red: 0.25, green: 0.3, blue: 0.5) : Color(red: 1, green: 0.85, blue: 0.9)))
        // bed
        let bed = CGRect(x: 10, y: floorY - 30, width: 78, height: 26)
        if !cabins {
            // canopy
            room.fill(Path(CGRect(x: bed.minX, y: bed.minY - 70, width: 3, height: 74)), with: .color(.white))
            room.fill(Path(CGRect(x: bed.maxX - 3, y: bed.minY - 70, width: 3, height: 74)), with: .color(.white))
            var canopy = Path()
            canopy.move(to: CGPoint(x: bed.minX - 4, y: bed.minY - 70))
            canopy.addLine(to: CGPoint(x: bed.maxX + 4, y: bed.minY - 70))
            canopy.addLine(to: CGPoint(x: bed.maxX + 8, y: bed.minY - 20))
            canopy.addQuadCurve(to: CGPoint(x: bed.maxX - 10, y: bed.minY - 50), control: CGPoint(x: bed.maxX - 2, y: bed.minY - 30))
            canopy.addLine(to: CGPoint(x: bed.minX + 10, y: bed.minY - 50))
            canopy.addQuadCurve(to: CGPoint(x: bed.minX - 8, y: bed.minY - 20), control: CGPoint(x: bed.minX + 2, y: bed.minY - 30))
            canopy.closeSubpath()
            room.fill(canopy, with: .color(Look.rgb(dress).opacity(0.55)))
        }
        room.fill(Path(roundedRect: CGRect(x: bed.minX - 2, y: bed.minY - 14, width: 8, height: 40), cornerRadius: 3), with: .color(cabins ? Color(red: 0.6, green: 0.4, blue: 0.25) : .white))
        room.fill(Path(roundedRect: bed, cornerRadius: 5), with: .color(.white))
        room.fill(Path(ellipseIn: CGRect(x: bed.minX + 6, y: bed.minY - 6, width: 24, height: 12)), with: .color(Color(white: 0.97)))
        let blanket = Look.rgb(dress)
        if asleep {
            // tucked in: head on the pillow, blanket up to the shoulders
            var head = room
            head.translateBy(x: bed.minX + 3, y: bed.minY - 22)
            drawBust(head, size: CGSize(width: 32, height: 32), look: look, girl: true, mood: .happy)
            room.fill(Path(roundedRect: CGRect(x: bed.minX + 18, y: bed.minY + 2, width: bed.width - 18, height: bed.height - 4), cornerRadius: 6), with: .color(blanket))
            // closed eyes: cover open eyes with lids
            let hc = CGPoint(x: bed.minX + 19, y: bed.minY - 6)
            for s in [-1.0, 1.0] {
                let e = CGPoint(x: hc.x + CGFloat(s) * 2.9, y: hc.y - 0.4)
                room.fill(Path(ellipseIn: CGRect(x: e.x - 1.7, y: e.y - 2, width: 3.4, height: 4)), with: .color(Look.rgb(look.skin)))
                var lid = Path(); lid.move(to: CGPoint(x: e.x - 1.5, y: e.y)); lid.addQuadCurve(to: CGPoint(x: e.x + 1.5, y: e.y), control: CGPoint(x: e.x, y: e.y + 1.4))
                room.stroke(lid, with: .color(.black), lineWidth: 0.7)
            }
            let z = (t * 0.6 + Double(i) * 0.3).truncatingRemainder(dividingBy: 1)
            room.draw(Text("Z").font(.system(size: 8 + 8 * z, weight: .bold)).foregroundStyle(Color.white.opacity(1 - z)), at: CGPoint(x: bed.minX + 36 + CGFloat(z) * 18, y: bed.minY - 20 - CGFloat(z) * 30))
        } else {
            room.fill(Path(roundedRect: CGRect(x: bed.minX + 18, y: bed.minY + 2, width: bed.width - 18, height: bed.height - 4), cornerRadius: 6), with: .color(blanket))
            drawPerson(&room, look: look, feet: CGPoint(x: w * (morning ? 0.45 : 0.62), y: size.height * 0.95), h: 92, girl: 1, mood: morning ? .happy : .surprised, arms: .up, facing: 0)
        }
        // lights going out
        if asleep {
            room.fill(Path(CGRect(x: 0, y: 0, width: w, height: size.height)), with: .color(Color(red: 0.03, green: 0.03, blue: 0.15).opacity(0.55 * min(1, p * 1.5))))
        }
        // wall between rooms
        ctx.fill(Path(CGRect(x: rect.maxX - 1.5, y: 0, width: 3, height: size.height)), with: .color(Color(white: 0.3)))
    }
}

/// Close-up of one girl at her bedroom vanity, admiring herself in the mirror before bed.
func drawVanity(_ ctx: inout GraphicsContext, _ size: CGSize, girl i: Int, p: Double, t: Double) {
    let look = Cast.kids[i]
    let dress = look.dress
    let wall = Color(red: dress[0] * 0.3 + 0.7, green: dress[1] * 0.3 + 0.7, blue: dress[2] * 0.3 + 0.7)
    let floorY = size.height * 0.82
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(wall))
    for k in 0..<14 {
        let x = CGFloat((k * 61) % Int(size.width)), y = CGFloat(30 + (k * 47) % 150)
        ctx.draw(Text("♥").font(.system(size: 11)).foregroundStyle(Look.rgb(dress).opacity(0.4)), at: CGPoint(x: x + 8, y: y))
    }
    for k in 0..<12 {
        let x = 10 + CGFloat(k) * (size.width - 20) / 11
        let on = 0.5 + 0.5 * sin(t * 3 + Double(k))
        ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: 8 + CGFloat(k % 2) * 4, width: 6, height: 6)), with: .color(Color.yellow.opacity(0.4 + 0.6 * on)))
    }
    ctx.fill(Path(CGRect(x: 0, y: floorY, width: size.width, height: size.height - floorY)), with: .color(Color(red: 1, green: 0.85, blue: 0.9)))
    // vanity table with perfume, brush and lipstick
    let table = CGRect(x: 205, y: floorY - 62, width: 180, height: 62)
    ctx.fill(Path(roundedRect: table, cornerRadius: 6), with: .color(.white))
    ctx.fill(Path(CGRect(x: table.minX, y: table.minY, width: table.width, height: 6)), with: .color(Look.rgb(dress).opacity(0.7)))
    ctx.fill(Path(roundedRect: CGRect(x: 220, y: table.minY - 18, width: 12, height: 18), cornerRadius: 3), with: .color(Color(red: 1, green: 0.6, blue: 0.8).opacity(0.8)))
    ctx.fill(Path(ellipseIn: CGRect(x: 222, y: table.minY - 24, width: 8, height: 7)), with: .color(Color(red: 0.85, green: 0.7, blue: 0.3)))
    ctx.fill(Path(roundedRect: CGRect(x: 350, y: table.minY - 14, width: 6, height: 14), cornerRadius: 2), with: .color(.red))
    ctx.fill(Path(roundedRect: CGRect(x: 330, y: table.minY - 6, width: 18, height: 6), cornerRadius: 3), with: .color(Color(red: 0.55, green: 0.35, blue: 0.25)))
    // big oval mirror with light bulbs
    let mr = CGRect(x: 225, y: 34, width: 140, height: table.minY - 46)
    ctx.fill(Path(ellipseIn: mr.insetBy(dx: -8, dy: -8)), with: .color(Color(red: 0.85, green: 0.7, blue: 0.3)))
    ctx.fill(Path(ellipseIn: mr), with: .linearGradient(Gradient(colors: [Color(red: 0.85, green: 0.92, blue: 1), Color(red: 0.65, green: 0.75, blue: 0.9)]),
                                                        startPoint: CGPoint(x: mr.minX, y: mr.minY), endPoint: CGPoint(x: mr.maxX, y: mr.maxY)))
    for k in 0..<10 {
        let a = Double(k) / 10 * 2 * .pi
        let c = CGPoint(x: mr.midX + CGFloat(cos(a)) * (mr.width / 2 + 8), y: mr.midY + CGFloat(sin(a)) * (mr.height / 2 + 8))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)), with: .color(Color(red: 1, green: 0.97, blue: 0.75)))
    }
    // reflection: smiling back, a little twirl
    var rctx = ctx
    rctx.clip(to: Path(ellipseIn: mr))
    rctx.opacity = 0.9
    let sway = CGFloat(sin(t * 2.2)) * 3
    drawPerson(&rctx, look: look, feet: CGPoint(x: mr.midX + sway, y: mr.maxY + 70), h: 190, girl: 1, mood: .happy, arms: .hands, facing: -1)
    // the girl herself, from behind the shoulder side, admiring
    drawPerson(&ctx, look: look, feet: CGPoint(x: 120 - sway, y: size.height + 40), h: 230, girl: 1, mood: .happy, arms: p < 0.5 ? .hands : .up, facing: 1)
    // sparkles around the mirror
    for k in 0..<5 {
        let u = (t * 0.8 + Double(k) / 5).truncatingRemainder(dividingBy: 1)
        let a = Double(k) * 1.3 + t * 0.5
        ctx.draw(Text("✨").font(.system(size: 10 + 8 * u)).foregroundStyle(.white.opacity(1 - u)),
                 at: CGPoint(x: mr.midX + CGFloat(cos(a)) * 70, y: mr.midY + CGFloat(sin(a)) * 80))
    }
}

/// Boardwalk Bank – the storefront (`outside`) or the lobby with the teller's window.
func drawBank(_ ctx: inout GraphicsContext, _ size: CGSize, outside: Bool) {
    let stone = Color(red: 0.88, green: 0.86, blue: 0.8)
    let navy = Color(red: 0.12, green: 0.2, blue: 0.42)
    let gold = Color(red: 0.9, green: 0.75, blue: 0.3)
    if outside {
        let front = CGRect(x: size.width - 170, y: size.height * 0.3, width: 160, height: size.height * 0.58 - 8)
        ctx.fill(Path(front), with: .color(stone))
        // pediment
        var roof = Path()
        roof.move(to: CGPoint(x: front.minX - 8, y: front.minY))
        roof.addLine(to: CGPoint(x: front.midX, y: front.minY - 30))
        roof.addLine(to: CGPoint(x: front.maxX + 8, y: front.minY)); roof.closeSubpath()
        ctx.fill(roof, with: .color(stone.opacity(0.9)))
        ctx.stroke(roof, with: .color(.black.opacity(0.2)), lineWidth: 1)
        ctx.fill(Path(CGRect(x: front.minX, y: front.minY + 2, width: front.width, height: 18)), with: .color(navy))
        ctx.draw(Text("BOARDWALK BANK").font(.system(size: 11, weight: .heavy, design: .serif)).foregroundStyle(gold), at: CGPoint(x: front.midX, y: front.minY + 11))
        // columns + door
        for k in 0..<4 {
            ctx.fill(Path(CGRect(x: front.minX + 12 + CGFloat(k) * 42, y: front.minY + 24, width: 10, height: front.height - 28)), with: .color(.white.opacity(0.85)))
        }
        ctx.fill(Path(roundedRect: CGRect(x: front.midX - 16, y: front.maxY - 46, width: 32, height: 46), cornerRadius: 3), with: .color(navy))
        ctx.draw(Text("$").font(.system(size: 16, weight: .bold)).foregroundStyle(gold), at: CGPoint(x: front.midX, y: front.minY + 44))
        return
    }
    // lobby
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.93, green: 0.9, blue: 0.82)))
    let floorY = size.height * 0.72
    for k in 0..<10 {
        let r = CGRect(x: CGFloat(k) * size.width / 10, y: floorY, width: size.width / 10, height: size.height - floorY)
        ctx.fill(Path(r), with: .color(k % 2 == 0 ? Color(white: 0.95) : Color(white: 0.8)))
    }
    for x in [20.0, 180] {
        ctx.fill(Path(CGRect(x: x, y: 20, width: 14, height: floorY - 20)), with: .color(.white.opacity(0.8)))
    }
    ctx.fill(Path(CGRect(x: 0, y: 6, width: size.width, height: 22)), with: .color(navy))
    ctx.draw(Text("BOARDWALK BANK").font(.system(size: 13, weight: .heavy, design: .serif)).foregroundStyle(gold), at: CGPoint(x: size.width / 2, y: 17))
    // vault door behind the teller
    let vc = CGPoint(x: size.width - 40, y: floorY - 80)
    ctx.fill(Path(ellipseIn: CGRect(x: vc.x - 34, y: vc.y - 34, width: 68, height: 68)), with: .color(Color(white: 0.62)))
    ctx.stroke(Path(ellipseIn: CGRect(x: vc.x - 26, y: vc.y - 26, width: 52, height: 52)), with: .color(Color(white: 0.4)), lineWidth: 3)
    for a in stride(from: 0.0, to: .pi * 2, by: .pi / 3) {
        var sp = Path(); sp.move(to: vc); sp.addLine(to: CGPoint(x: vc.x + 18 * cos(a), y: vc.y + 18 * sin(a)))
        ctx.stroke(sp, with: .color(Color(white: 0.3)), lineWidth: 3)
    }
    // velvet rope for the line
    for x in [80.0, 150, 220] {
        ctx.fill(Path(CGRect(x: x - 2, y: floorY + 30, width: 4, height: 34)), with: .color(gold))
    }
    var rope = Path(); rope.move(to: CGPoint(x: 80, y: floorY + 34))
    rope.addQuadCurve(to: CGPoint(x: 150, y: floorY + 34), control: CGPoint(x: 115, y: floorY + 46))
    rope.addQuadCurve(to: CGPoint(x: 220, y: floorY + 34), control: CGPoint(x: 185, y: floorY + 46))
    ctx.stroke(rope, with: .color(Color(red: 0.7, green: 0.1, blue: 0.2)), lineWidth: 3)
}

/// The teller's counter with its brass window – drawn over the teller so she stands behind it.
func drawBankCounter(_ ctx: inout GraphicsContext, _ size: CGSize, floor: CGFloat) {
    let gold = Color(red: 0.9, green: 0.75, blue: 0.3)
    let top = floor - 56
    let r = CGRect(x: 270, y: top, width: size.width - 270, height: floor - top)
    ctx.fill(Path(r), with: .color(Color(red: 0.45, green: 0.28, blue: 0.16)))
    ctx.fill(Path(CGRect(x: r.minX - 4, y: top - 6, width: r.width + 4, height: 8)), with: .color(Color(red: 0.6, green: 0.4, blue: 0.22)))
    // brass bars of the teller window
    for k in 0..<6 {
        ctx.fill(Path(CGRect(x: r.minX + 6 + CGFloat(k) * 22, y: top - 110, width: 2, height: 72)), with: .color(gold.opacity(0.8)))
    }
    ctx.fill(Path(CGRect(x: r.minX, y: top - 112, width: r.width, height: 4)), with: .color(gold))
    ctx.draw(Text("TELLER").font(.system(size: 9, weight: .bold)).foregroundStyle(.white), at: CGPoint(x: r.midX, y: top + 20))
}
