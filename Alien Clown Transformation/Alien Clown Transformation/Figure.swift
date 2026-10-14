import SwiftUI

/// Where every joint of a person is this frame. Index 0 is the screen-left limb.
struct Pose {
    let h, hr, w, armW, legW: Double
    let head: CGPoint
    let neck: CGRect
    let torso: CGRect
    let shoulder, elbow, hand, hip, knee, foot: [CGPoint]

    init(_ p: Person, feet: CGPoint, facing: Double, now: Date, still: Bool = false) {
        let h = p.height
        let seated = p.seated && !still
        let walking = !still && !seated && p.isWalking(at: now)
        let t = now.timeIntervalSinceReferenceDate
        let swing = walking ? sin(t * 9) : 0
        let fy = feet.y - (walking ? abs(swing) * 2 : 0)
        let x = feet.x
        let legLen = h * 0.44
        let torsoH = h * 0.29
        let w = h * 0.22
        let hr = h * p.headScale
        let legW = h * 0.085

        // Seated, the thighs point at the camera, so the hips drop to the seat.
        var hip: [CGPoint] = [], knee: [CGPoint] = [], foot: [CGPoint] = []
        let hipY = seated ? fy - h * 0.27 : fy - legLen
        for side in [-1.0, 1.0] {
            let hp = CGPoint(x: x + side * w * 0.22, y: hipY)
            if seated {
                let kn = CGPoint(x: x + side * w * 0.3, y: hipY + h * 0.06)
                hip.append(hp)
                knee.append(kn)
                foot.append(CGPoint(x: kn.x + side * h * 0.01, y: fy - h * 0.02))
            } else {
                let ft = CGPoint(x: hp.x + side * swing * legLen * 0.3, y: fy - h * 0.02)
                hip.append(hp)
                foot.append(ft)
                knee.append(CGPoint(x: (hp.x + ft.x) / 2 + side * h * 0.004, y: (hp.y + ft.y) / 2))
            }
        }

        let shY = hipY - torsoH
        let head = CGPoint(x: x, y: shY - hr - h * 0.035)
        let neckTop = head.y + hr * 0.6

        var shoulder: [CGPoint] = [], elbow: [CGPoint] = [], hand: [CGPoint] = []
        let armLen = torsoH * 0.95
        // The arm on the side she faces does the reaching.
        let reachArm = facing < 0 ? 0 : 1
        for (i, side) in [-1.0, 1.0].enumerated() {
            let sh = CGPoint(x: x + side * (w / 2 + h * 0.005), y: shY + h * 0.035)
            let el: CGPoint, hd: CGPoint
            if p.feelsHead && !still {
                // Hands on top of her head, patting it, elbows out wide.
                let pat = sin(t * 7 + Double(i) * .pi) * hr * 0.12
                hd = CGPoint(x: head.x + side * hr * 0.65, y: head.y - hr * 1.1 + pat)
                el = CGPoint(x: sh.x + side * h * 0.16, y: sh.y - h * 0.03)
            } else if let target = p.reachTo, i == reachArm, !still {
                hd = target
                el = CGPoint(x: (sh.x + hd.x) / 2, y: max(sh.y, hd.y) + armLen * 0.12)
            } else if seated {
                // Forearms flat on the armrests.
                hd = CGPoint(x: x + side * (w / 2 + h * 0.07), y: hipY - h * 0.02)
                el = CGPoint(x: x + side * (w / 2 + h * 0.05), y: shY + torsoH * 0.55)
            } else if p.carrying && !still {
                hd = CGPoint(x: x + side * w * 0.42, y: shY + torsoH * 0.62)
                el = CGPoint(x: sh.x + side * h * 0.035, y: shY + torsoH * 0.45)
            } else {
                let reach: Double = w / 2 + h * 0.05 - swing * torsoH * 0.3
                hd = CGPoint(x: x + side * reach, y: sh.y + armLen)
                let midX: Double = (sh.x + hd.x) / 2
                el = CGPoint(x: midX + side * h * 0.012, y: (sh.y + hd.y) / 2)
            }
            shoulder.append(sh)
            elbow.append(el)
            hand.append(hd)
        }

        self.h = h
        self.hr = hr
        self.w = w
        self.armW = h * 0.066
        self.legW = legW
        self.head = head
        self.neck = CGRect(x: x - h * 0.035, y: neckTop, width: h * 0.07, height: shY - neckTop + h * 0.02)
        self.torso = CGRect(x: x - w / 2, y: shY, width: w, height: torsoH + h * 0.03)
        self.shoulder = shoulder
        self.elbow = elbow
        self.hand = hand
        self.hip = hip
        self.knee = knee
        self.foot = foot
    }

    var headTop: Double { head.y - hr }
}

// MARK: Drawing people

private func fill(_ ctx: GraphicsContext, _ rect: CGRect, _ c: Color, corner: Double = 0) {
    ctx.fill(Path(roundedRect: rect, cornerRadius: corner), with: .color(c))
}

private func polyline(_ pts: [CGPoint]) -> Path {
    var p = Path()
    p.addLines(pts)
    return p
}

private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
    CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
}

private func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

/// A heart about 2r wide, centred on c.
private func heart(_ c: CGPoint, _ r: Double) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: c.x, y: c.y + r * 0.95))
    p.addCurve(to: CGPoint(x: c.x - r, y: c.y - r * 0.2),
               control1: CGPoint(x: c.x - r * 0.35, y: c.y + r * 0.55), control2: CGPoint(x: c.x - r, y: c.y + r * 0.3))
    p.addArc(center: CGPoint(x: c.x - r * 0.5, y: c.y - r * 0.2), radius: r * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    p.addArc(center: CGPoint(x: c.x + r * 0.5, y: c.y - r * 0.2), radius: r * 0.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
    p.addCurve(to: CGPoint(x: c.x, y: c.y + r * 0.95),
               control1: CGPoint(x: c.x + r, y: c.y + r * 0.3), control2: CGPoint(x: c.x + r * 0.35, y: c.y + r * 0.55))
    p.closeSubpath()
    return p
}

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

/// The botched treatment leaves frizz in a rainbow of colors: pink, purple, blue, green, yellow, orange.
let frizzPalette = [RGB(r: 1.0, g: 0.35, b: 0.70), RGB(r: 0.62, g: 0.35, b: 0.90), RGB(r: 0.25, g: 0.60, b: 1.0),
                            RGB(r: 0.30, g: 0.85, b: 0.45), RGB(r: 1.0, g: 0.88, b: 0.25), RGB(r: 1.0, g: 0.55, b: 0.20)]

private func frizzColor(_ i: Int) -> Color {
    frizzPalette[i % frizzPalette.count].color
}

/// A head shape that morphs from a round human head (`a` = 0) to an alien clown's
/// tall, heavy-jowled head (`a` = 1).
func headShape(_ head: CGPoint, hr: Double, clown a: Double) -> (path: Path, center: CGPoint, width: Double, top: Double, bottom: Double) {
    let k = 0.5523
    let c = CGPoint(x: head.x, y: head.y - hr * 0.14 * a)
    let wd = hr * mix(1, 1.12, a)
    let top = hr * mix(1, 1.34, a)
    let bottom = hr * mix(1, 1.16, a)
    // The cheeks sag outwards below the eyes and the chin goes wide and flat.
    let jowl = wd * (1 + 0.24 * a)
    let chin = k * (1 + 0.5 * a)
    var p = Path()
    p.move(to: CGPoint(x: c.x - wd, y: c.y))
    p.addCurve(to: CGPoint(x: c.x, y: c.y - top), control1: CGPoint(x: c.x - wd, y: c.y - top * k), control2: CGPoint(x: c.x - wd * k, y: c.y - top))
    p.addCurve(to: CGPoint(x: c.x + wd, y: c.y), control1: CGPoint(x: c.x + wd * k, y: c.y - top), control2: CGPoint(x: c.x + wd, y: c.y - top * k))
    p.addCurve(to: CGPoint(x: c.x, y: c.y + bottom), control1: CGPoint(x: c.x + jowl, y: c.y + bottom * 0.8), control2: CGPoint(x: c.x + wd * chin, y: c.y + bottom))
    p.addCurve(to: CGPoint(x: c.x - wd, y: c.y), control1: CGPoint(x: c.x - wd * chin, y: c.y + bottom), control2: CGPoint(x: c.x - jowl, y: c.y + bottom * 0.8))
    p.closeSubpath()
    return (p, c, wd, c.y - top, c.y + bottom)
}

/// A brown paper grocery bag with a baguette and greens poking out.
func drawGroceryBag(_ ctx: GraphicsContext, center c: CGPoint, size s: Double) {
    fill(ctx, CGRect(x: c.x + s * 0.05, y: c.y - s * 0.85, width: s * 0.16, height: s * 0.6), Color(red: 0.88, green: 0.68, blue: 0.38), corner: s * 0.08)
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.38, y: c.y - s * 0.62, width: s * 0.4, height: s * 0.3)), with: .color(Color(red: 0.30, green: 0.65, blue: 0.25)))
    let r = CGRect(x: c.x - s * 0.45, y: c.y - s * 0.45, width: s * 0.9, height: s)
    fill(ctx, r, Color(red: 0.80, green: 0.64, blue: 0.44), corner: 2)
    fill(ctx, CGRect(x: r.minX, y: r.minY, width: r.width, height: s * 0.08), Color(red: 0.70, green: 0.54, blue: 0.34))
}

func drawBox(_ ctx: GraphicsContext, center c: CGPoint, size s: Double) {
    let r = CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s * 0.85)
    fill(ctx, r, Color(red: 0.78, green: 0.60, blue: 0.38), corner: 2)
    ctx.stroke(Path(roundedRect: r, cornerRadius: 2), with: .color(Color(red: 0.55, green: 0.40, blue: 0.22)), lineWidth: 1.2)
    fill(ctx, CGRect(x: r.minX, y: r.minY + r.height * 0.18, width: r.width, height: r.height * 0.12), Color(red: 0.90, green: 0.82, blue: 0.62))
}

/// A four-pointed twinkle.
func drawSparkle(_ ctx: GraphicsContext, at c: CGPoint, size s: Double, alpha: Double, tint: Color = Color(red: 1, green: 0.45, blue: 0.75)) {
    guard s > 0.1 else { return }
    var star = Path()
    for i in 0..<8 {
        let a = Double(i) * .pi / 4 - .pi / 2
        let r = i % 2 == 0 ? s : s * 0.22
        let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        i == 0 ? star.move(to: pt) : star.addLine(to: pt)
    }
    star.closeSubpath()
    ctx.fill(star, with: .color(.white.opacity(alpha)))
    ctx.stroke(star, with: .color(tint.opacity(alpha)), lineWidth: 1)
}

/// A fuzzy ball of clown hair: one big circle ringed by smaller ones.
private func puff(_ ctx: GraphicsContext, at c: CGPoint, radius r: Double, _ color: Color) {
    guard r > 0.2 else { return }
    ctx.fill(circle(c, r * 0.78), with: .color(color))
    for i in 0..<9 {
        let a = Double(i) / 9 * 2 * .pi
        ctx.fill(circle(CGPoint(x: c.x + cos(a) * r * 0.62, y: c.y + sin(a) * r * 0.62), r * 0.42), with: .color(color))
    }
    ctx.fill(circle(CGPoint(x: c.x - r * 0.25, y: c.y - r * 0.3), r * 0.3), with: .color(.white.opacity(0.18)))
}

/// One printed motif of a clown suit, `s` across.
private func drawMark(_ ctx: GraphicsContext, _ pattern: ClownPattern, at c: CGPoint, size s: Double, _ color: Color) {
    switch pattern {
    case .moons:
        let moon = circle(c, s / 2).subtracting(circle(CGPoint(x: c.x + s * 0.3, y: c.y), s / 2))
        ctx.fill(moon, with: .color(color))
    case .stars:
        var star = Path()
        for i in 0..<10 {
            let a = Double(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? s / 2 : s * 0.21
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            i == 0 ? star.move(to: pt) : star.addLine(to: pt)
        }
        star.closeSubpath()
        ctx.fill(star, with: .color(color))
    case .dots:
        ctx.fill(circle(c, s * 0.34), with: .color(color))
    case .swirls:
        ctx.stroke(circle(c, s * 0.42), with: .color(color), lineWidth: max(0.8, s * 0.14))
        ctx.fill(circle(c, s * 0.16), with: .color(color))
    case .diamonds:
        ctx.fill(polyline([CGPoint(x: c.x, y: c.y - s * 0.55), CGPoint(x: c.x + s * 0.36, y: c.y),
                           CGPoint(x: c.x, y: c.y + s * 0.55), CGPoint(x: c.x - s * 0.36, y: c.y)]), with: .color(color))
    case .stripes:
        break
    }
}

/// `levels` overrides how far she has changed (the album uses `.none` for "before" and `.full` for "after").
func drawPerson(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, facing: Double, now: Date,
                still: Bool = false, levels: ClownLevels? = nil) {
    let pose = Pose(p, feet: feet, facing: facing, now: now, still: still)
    let h = pose.h, hr = pose.hr, head = pose.head
    let limbStyle = { (w: Double) in StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }
    let lv = levels ?? p.clownLevels(at: now)
    let kind = p.clown ?? .moonbeam
    let suit = kind.suit.color, trim = kind.trim.color, mark = kind.mark.color

    /// The jumpsuit, ruff and shoes show through as soon as the change reaches that part of the body.
    func layer(_ amount: Double) -> GraphicsContext {
        var c = ctx
        c.opacity = min(1, amount * 1.5)
        return c
    }
    let skinHead = p.skin.mixed(with: ClownKind.skin, lv.head * 0.97).color
    // Hands disappear into white gloves.
    let skinHands = p.skin.mixed(with: RGB(r: 1, g: 1, b: 1), lv.body).color
    let skinBody = p.skin.color
    let hairColor = p.hair.color
    var hairCtx = ctx
    hairCtx.opacity = 1 - lv.head
    // The head swells into its clown shape, easing in and out.
    let a = lv.head * lv.head * (3 - 2 * lv.head)
    let shape = headShape(head, hr: hr, clown: a)

    // Long hair and bobs hang behind the shoulders.
    switch p.style {
    case .long:
        fill(hairCtx, CGRect(x: head.x - hr * 1.1, y: head.y - hr * 0.6, width: hr * 2.2, height: hr * 3.5), hairColor, corner: hr * 0.8)
    case .waist:
        // Waist-length hair falls all the way down her back.
        let top = head.y - hr * 0.6
        fill(hairCtx, CGRect(x: head.x - hr * 1.25, y: top, width: hr * 2.5, height: pose.torso.maxY - h * 0.05 - top), hairColor, corner: hr * 0.8)
    case .bob:
        fill(hairCtx, CGRect(x: head.x - hr * 1.15, y: head.y - hr * 0.7, width: hr * 2.3, height: hr * 1.75), hairColor, corner: hr * 0.6)
    case .frizzy:
        // A wild multicolored cloud of curly frizz.
        for ring in 0..<2 {
            for i in 0..<22 {
                let ang = (Double(i) + Double(ring) * 0.5) / 22 * 2 * .pi
                let r = hr * (ring == 0 ? 1.55 : 1.05) * (1 + 0.1 * sin(Double(i) * 2.7))
                let c = CGPoint(x: head.x + cos(ang) * r, y: head.y + sin(ang) * r * 0.9 + hr * 0.15)
                hairCtx.fill(circle(c, hr * (ring == 0 ? 0.5 : 0.52)), with: .color(frizzColor(i + ring * 3)))
            }
        }
    default:
        break
    }

    // Legs
    let legs = layer(lv.legs)
    for i in 0..<2 {
        let leg = polyline([pose.hip[i], pose.knee[i], pose.foot[i]])
        ctx.stroke(leg, with: .color(skinBody), style: limbStyle(pose.legW))
        if p.shorts {
            // Shorts stop above the knee.
            ctx.stroke(polyline([pose.hip[i], lerp(pose.hip[i], pose.knee[i], p.seated ? 0.9 : 0.6)]), with: .color(p.pants.color),
                       style: StrokeStyle(lineWidth: pose.legW * 1.3, lineCap: .butt))
        } else {
            ctx.stroke(leg, with: .color(p.pants.color), style: limbStyle(pose.legW * 1.1))
        }
        let f = pose.foot[i]
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.045 + facing * h * 0.02, y: f.y - h * 0.012, width: h * 0.09, height: h * 0.045)),
                 with: .color(Color(white: 0.25)))
        guard lv.legs > 0 else { continue }
        // Baggy jumpsuit legs balloon out, gathered into a frill at the ankle, over enormous shoes.
        let ankle = lerp(pose.knee[i], f, 0.78)
        legs.stroke(polyline([pose.hip[i], pose.knee[i], ankle]), with: .color(suit), style: limbStyle(pose.legW * mix(1.15, 2.0, lv.legs)))
        if kind.pattern == .stripes {
            legs.stroke(polyline([pose.hip[i], pose.knee[i], ankle]), with: .color(mark), style: limbStyle(pose.legW * mix(0.3, 0.5, lv.legs)))
        }
        let side = i == 0 ? -1.0 : 1.0
        let len = h * mix(0.09, 0.17, lv.legs)
        let toe = facing == 0 ? side * len * 0.22 : facing * len * 0.3
        let shoe = CGRect(x: f.x - len / 2 + toe, y: f.y - h * mix(0.012, 0.03, lv.legs), width: len, height: h * mix(0.045, 0.07, lv.legs))
        legs.fill(Path(ellipseIn: shoe), with: .color(mark))
        legs.fill(Path(ellipseIn: CGRect(x: shoe.minX + shoe.width * 0.18, y: shoe.minY + shoe.height * 0.12, width: shoe.width * 0.3, height: shoe.height * 0.3)),
                  with: .color(.white.opacity(0.45)))
        for k in -1...1 {
            legs.fill(circle(CGPoint(x: ankle.x + Double(k) * pose.legW * 0.62, y: ankle.y + pose.legW * 0.1), pose.legW * mix(0.3, 0.52, lv.legs)), with: .color(trim))
        }
    }

    // Neck and torso
    fill(ctx, pose.neck, skinHead)
    let t = pose.torso
    let torsoPath = Path(roundedRect: t, cornerRadius: pose.w * 0.3)
    ctx.fill(torsoPath, with: .color(p.shirt.color))
    var collar = Path()
    collar.addArc(center: CGPoint(x: t.midX, y: t.minY), radius: pose.w * 0.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
    ctx.fill(collar, with: .color(skinBody))
    fill(ctx, CGRect(x: t.minX, y: t.maxY - h * 0.05, width: t.width, height: h * 0.06), p.pants.color, corner: 3)

    // A necklace or scarf from the accessory store; the jumpsuit covers them when she changes.
    if p.accessories.contains(.necklace) {
        for k in 0..<9 {
            let ang = (20.0 + Double(k) * 17.5) * .pi / 180
            let bead = CGPoint(x: t.midX + cos(ang) * pose.w * 0.3, y: t.minY + sin(ang) * pose.w * 0.34)
            ctx.fill(circle(bead, h * (k == 4 ? 0.012 : 0.008)), with: .color(k == 4 ? Color(red: 0.30, green: 0.75, blue: 0.95) : Color(red: 0.98, green: 0.82, blue: 0.25)))
        }
    }
    if p.accessories.contains(.scarf) {
        let silk = Color(red: 0.88, green: 0.20, blue: 0.48)
        fill(ctx, CGRect(x: t.midX + pose.w * 0.08, y: t.minY, width: pose.w * 0.2, height: h * 0.12), silk, corner: 2)
        fill(ctx, CGRect(x: t.midX - pose.w * 0.3, y: t.minY - h * 0.022, width: pose.w * 0.6, height: h * 0.042), silk, corner: h * 0.02)
        fill(ctx, CGRect(x: t.midX + pose.w * 0.08, y: t.minY + h * 0.1, width: pose.w * 0.2, height: h * 0.012), .white.opacity(0.7))
    }

    // The jumpsuit billows out over her clothes.
    let body = layer(lv.body)
    if lv.body > 0 {
        let bw = t.width * mix(1.05, 1.5, lv.body)
        let belly = CGRect(x: t.midX - bw / 2, y: t.minY - h * 0.005, width: bw, height: t.height + h * 0.045 * lv.body)
        let bellyPath = Path(roundedRect: belly, cornerRadius: bw * 0.42)
        body.fill(bellyPath, with: .color(suit))
        var printed = body
        printed.clip(to: bellyPath)
        let s = pose.w * 0.3
        switch kind.pattern {
        case .stripes:
            for k in stride(from: -3.0, through: 3, by: 2) {
                fill(printed, CGRect(x: belly.midX + k * bw * 0.14 - bw * 0.07, y: belly.minY, width: bw * 0.14, height: belly.height), mark)
            }
        case .dots, .swirls:
            for (dx, dy) in [(-0.27, 0.22), (0.24, 0.16), (0.0, 0.42), (-0.3, 0.62), (0.28, 0.58), (-0.04, 0.82), (0.3, 0.9)] {
                drawMark(printed, kind.pattern, at: CGPoint(x: belly.midX + dx * bw, y: belly.minY + dy * belly.height), size: s * 0.85, mark)
            }
        case .moons, .stars, .diamonds:
            // Three big ones down the front, like buttons.
            for dy in [0.3, 0.54, 0.78] {
                drawMark(printed, kind.pattern, at: CGPoint(x: belly.midX, y: belly.minY + dy * belly.height), size: s, mark)
            }
        }
        body.stroke(bellyPath, with: .color(.black.opacity(0.14)), lineWidth: max(0.6, h * 0.004))
    }

    // Arms
    for i in 0..<2 {
        let arm = polyline([pose.shoulder[i], pose.elbow[i], pose.hand[i]])
        ctx.stroke(arm, with: .color(skinBody), style: limbStyle(pose.armW))
        let sleeve = polyline([pose.shoulder[i], lerp(pose.shoulder[i], pose.elbow[i], 0.5)])
        ctx.stroke(sleeve, with: .color(p.shirt.color), style: StrokeStyle(lineWidth: pose.armW * 1.35, lineCap: .round))
        let hd = pose.hand[i]
        if lv.body > 0 {
            // Full puffy sleeves with a frill at the wrist.
            let wrist = lerp(pose.elbow[i], hd, 0.8)
            body.stroke(polyline([pose.shoulder[i], pose.elbow[i], wrist]), with: .color(suit), style: limbStyle(pose.armW * mix(1.4, 2.0, lv.body)))
            for k in -1...1 {
                body.fill(circle(CGPoint(x: wrist.x + Double(k) * pose.armW * 0.55, y: wrist.y + abs(Double(k)) * pose.armW * 0.12), pose.armW * mix(0.3, 0.5, lv.body)),
                          with: .color(trim))
            }
        }
        ctx.fill(circle(hd, pose.armW * mix(0.62, 0.9, lv.body)), with: .color(skinHands))
        if lv.body > 0.5 {
            ctx.stroke(circle(hd, pose.armW * mix(0.62, 0.9, lv.body)), with: .color(.black.opacity(0.2 * (lv.body - 0.5) * 2)), lineWidth: 0.7)
        }
    }
    if let tool = p.tool, p.reachTo != nil, !still {
        drawSalonTool(ctx, tool, in: pose.hand[facing < 0 ? 0 : 1], size: h * 0.075)
    }
    if p.accessories.contains(.handbag) && !p.seated {
        let hd = pose.hand[0]
        let bag = CGRect(x: hd.x - h * 0.05, y: hd.y + h * 0.035, width: h * 0.1, height: h * 0.075)
        var strap = Path()
        strap.move(to: CGPoint(x: bag.minX + h * 0.015, y: bag.minY))
        strap.addQuadCurve(to: CGPoint(x: bag.maxX - h * 0.015, y: bag.minY), control: CGPoint(x: hd.x, y: hd.y - h * 0.035))
        ctx.stroke(strap, with: .color(Color(red: 0.45, green: 0.22, blue: 0.12)), lineWidth: max(1, h * 0.012))
        fill(ctx, bag, Color(red: 0.75, green: 0.30, blue: 0.20), corner: h * 0.015)
        fill(ctx, CGRect(x: bag.midX - h * 0.012, y: bag.minY + h * 0.012, width: h * 0.024, height: h * 0.018), Color(red: 0.98, green: 0.82, blue: 0.25), corner: 1)
    }
    if p.carrying && !still {
        let at = CGPoint(x: t.midX, y: t.minY + t.height * 0.62)
        if p.groceries { drawGroceryBag(ctx, center: at, size: pose.w * 1.2) } else { drawBox(ctx, center: at, size: pose.w * 1.25) }
    }

    // A wide ruff fans out around the neck once the suit reaches the shoulders.
    let ruff = min(max((lv.body - 0.45) / 0.55, 0), 1)
    if ruff > 0 {
        let rc = layer(ruff)
        let rw = pose.w * mix(0.5, 0.95, ruff)
        rc.fill(Path(ellipseIn: CGRect(x: t.midX - rw, y: t.minY - h * 0.03, width: rw * 2, height: h * 0.085)), with: .color(trim))
        for k in 0..<7 {
            let u = Double(k) / 6 * 2 - 1
            let c = CGPoint(x: t.midX + u * rw, y: t.minY + h * 0.012 + (1 - u * u) * h * 0.03)
            rc.fill(circle(c, h * 0.026), with: .color(trim))
            rc.stroke(circle(c, h * 0.026), with: .color(.black.opacity(0.12)), lineWidth: 0.6)
        }
    }

    // Her own hair behind the head
    switch p.style {
    case .ponytail:
        let back = facing == 0 ? 1.0 : -facing
        hairCtx.fill(Path(ellipseIn: CGRect(x: head.x + back * hr * 0.85 - hr * 0.35, y: head.y - hr * 0.3, width: hr * 0.7, height: hr * 1.7)),
                     with: .color(hairColor))
    case .bun:
        hairCtx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.5, y: head.y - hr * 1.55, width: hr, height: hr * 0.85)), with: .color(hairColor))
    case .pigtails:
        for side in [-1.0, 1.0] {
            hairCtx.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 1.15 - hr * 0.35, y: head.y - hr * 0.2, width: hr * 0.7, height: hr * 1.3)),
                         with: .color(hairColor))
            hairCtx.fill(circle(CGPoint(x: head.x + side * hr * 0.98, y: head.y - hr * 0.25), hr * 0.13), with: .color(Color(red: 1, green: 0.6, blue: 0.75)))
        }
    case .long, .waist, .short, .curly, .bob, .buzzed, .bald, .frizzy:
        break
    }

    // Clown hair sprouts as her own fades.
    let wig = kind.hair.color
    let sc = shape.center
    if a > 0 {
        switch kind.hairShape {
        case .tufts:
            for side in [-1.0, 1.0] {
                puff(ctx, at: CGPoint(x: sc.x + side * shape.width * 1.12, y: sc.y - hr * 0.35), radius: hr * 0.72 * a, wig)
            }
        case .puff:
            for side in [-1.0, 1.0] {
                puff(ctx, at: CGPoint(x: sc.x + side * shape.width * 0.98, y: sc.y - hr * 0.5), radius: hr * 0.6 * a, wig)
            }
            puff(ctx, at: CGPoint(x: sc.x, y: shape.top + hr * 0.1), radius: hr * 1.1 * a, wig)
        case .bow:
            for side in [-1.0, 1.0] {
                puff(ctx, at: CGPoint(x: sc.x + side * shape.width * 1.05, y: sc.y - hr * 0.2), radius: hr * 0.58 * a, wig)
            }
            puff(ctx, at: CGPoint(x: sc.x, y: shape.top + hr * 0.12), radius: hr * 0.5 * a, wig)
        case .mohawk:
            var fin = Path()
            fin.move(to: CGPoint(x: sc.x - hr * 0.32, y: shape.top + hr * 0.45))
            fin.addQuadCurve(to: CGPoint(x: sc.x + hr * 0.1 * a, y: shape.top - hr * 1.15 * a), control: CGPoint(x: sc.x - hr * 0.4, y: shape.top - hr * 0.5 * a))
            fin.addQuadCurve(to: CGPoint(x: sc.x + hr * 0.32, y: shape.top + hr * 0.45), control: CGPoint(x: sc.x + hr * 0.45, y: shape.top - hr * 0.3 * a))
            fin.closeSubpath()
            ctx.fill(fin, with: .color(wig))
            for side in [-1.0, 1.0] {
                puff(ctx, at: CGPoint(x: sc.x + side * shape.width * 1.02, y: sc.y - hr * 0.1), radius: hr * 0.36 * a, wig)
            }
        case .spikes:
            for k in 0..<7 {
                let ang = (200.0 + Double(k) * 23.3) * .pi / 180
                let base = CGPoint(x: sc.x + cos(ang) * shape.width * 0.8, y: sc.y + sin(ang) * (sc.y - shape.top) * 0.8)
                let tip = CGPoint(x: sc.x + cos(ang) * (shape.width + hr * 0.95 * a), y: sc.y + sin(ang) * (sc.y - shape.top + hr * 0.95 * a))
                let nx = -sin(ang) * hr * 0.3, ny = cos(ang) * hr * 0.3
                ctx.fill(polyline([CGPoint(x: base.x + nx, y: base.y + ny), tip, CGPoint(x: base.x - nx, y: base.y - ny)]), with: .color(wig))
            }
        case .topknot:
            var flame = Path()
            flame.move(to: CGPoint(x: sc.x - hr * 0.42, y: shape.top + hr * 0.4))
            flame.addCurve(to: CGPoint(x: sc.x + hr * 0.2, y: shape.top - hr * 1.2 * a),
                           control1: CGPoint(x: sc.x - hr * 0.7, y: shape.top - hr * 0.5 * a), control2: CGPoint(x: sc.x + hr * 0.3, y: shape.top - hr * 0.5 * a))
            flame.addCurve(to: CGPoint(x: sc.x + hr * 0.42, y: shape.top + hr * 0.4),
                           control1: CGPoint(x: sc.x + hr * 0.1, y: shape.top - hr * 0.6 * a), control2: CGPoint(x: sc.x + hr * 0.75, y: shape.top - hr * 0.2 * a))
            flame.closeSubpath()
            ctx.fill(flame, with: .color(wig))
            for side in [-1.0, 1.0] {
                puff(ctx, at: CGPoint(x: sc.x + side * shape.width * 1.0, y: sc.y), radius: hr * 0.3 * a, wig)
            }
        case .mop:
            // A full, round head of curls in many colors, from ear to ear and over the top.
            let colors = kind.hairColors
            for i in 0..<14 {
                let ang = (165.0 + Double(i) * 210 / 13) * .pi / 180
                let c = CGPoint(x: sc.x + cos(ang) * (shape.width * 1.05 + hr * 0.15 * a),
                                y: sc.y + sin(ang) * (sc.y - shape.top + hr * 0.25 * a))
                puff(ctx, at: c, radius: hr * 0.62 * a, colors[i % colors.count].color)
            }
        }
    }

    // Ears grow big and stick out.
    for side in [-1.0, 1.0] {
        let er = hr * mix(1, 1.35, a)
        ctx.fill(Path(ellipseIn: CGRect(x: sc.x + side * shape.width * 0.95 - er * 0.16, y: sc.y - hr * 0.05, width: er * 0.32, height: er * 0.42)),
                 with: .color(skinHead))
    }

    ctx.fill(shape.path, with: .color(skinHead))
    if a > 0 {
        ctx.stroke(shape.path, with: .color(.black.opacity(0.2 * a)), lineWidth: max(0.6, hr * 0.04))
        // Deep creases across the big forehead
        for (k, wd) in [0.5, 0.36].enumerated() {
            var crease = Path()
            let y = shape.top + hr * (0.42 + Double(k) * 0.17)
            crease.move(to: CGPoint(x: sc.x - hr * wd, y: y))
            crease.addQuadCurve(to: CGPoint(x: sc.x + hr * wd, y: y), control: CGPoint(x: sc.x, y: y - hr * 0.1))
            ctx.stroke(crease, with: .color(Color(red: 0.6, green: 0.35, blue: 0.4).opacity(0.4 * a)), lineWidth: max(0.5, hr * 0.035))
        }
    }

    // Her own hair on top of the head fades away.
    if lv.head < 1 {
        if p.style == .curly {
            for i in 0..<11 {
                let ang = (185.0 + Double(i) * 17) * .pi / 180
                hairCtx.fill(circle(CGPoint(x: head.x + cos(ang) * hr * 0.95, y: head.y + sin(ang) * hr * 0.95), hr * 0.34), with: .color(hairColor))
            }
            for side in [-1.0, 1.0] {
                hairCtx.fill(circle(CGPoint(x: head.x + side * hr * 1.05, y: head.y + hr * 0.25), hr * 0.3), with: .color(hairColor))
            }
        } else if p.style == .frizzy {
            // Tight multicolored ringlets piled over the crown, with little curls springing out of them.
            hairCtx.fill(scalp(head, hr * 1.15), with: .color(frizzColor(5)))
            for i in 0..<13 {
                let ang = (180.0 + Double(i) * 15) * .pi / 180
                let c = CGPoint(x: head.x + cos(ang) * hr * 1.1, y: head.y + sin(ang) * hr * 1.08)
                hairCtx.fill(circle(c, hr * 0.32), with: .color(frizzColor(i)))
                hairCtx.stroke(circle(c, hr * 0.16), with: .color(frizzColor(i + 2)), style: StrokeStyle(lineWidth: max(1, hr * 0.07)))
            }
        } else if p.style == .buzzed {
            // Clipped right down: a dusting of stubble over the scalp.
            hairCtx.fill(scalp(head, hr), with: .color(hairColor.opacity(0.45)))
            for i in 0..<14 {
                let ang = (192.0 + Double(i) * 11) * .pi / 180
                hairCtx.fill(circle(CGPoint(x: head.x + cos(ang) * hr * 0.8, y: head.y + sin(ang) * hr * 0.8), hr * 0.05), with: .color(hairColor.opacity(0.6)))
            }
        } else if p.style == .bald {
            // Shaved smooth, with a shine on top.
            hairCtx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.55, y: head.y - hr * 0.88, width: hr * 0.6, height: hr * 0.28)), with: .color(.white.opacity(0.55)))
        } else {
            var fringe = Path()
            for step in 0...16 {
                let ang = (190.0 + Double(step) * 10) * .pi / 180
                let pt = CGPoint(x: head.x + cos(ang) * hr * 1.05, y: head.y + sin(ang) * hr * 1.05)
                step == 0 ? fringe.move(to: pt) : fringe.addLine(to: pt)
            }
            fringe.addQuadCurve(to: CGPoint(x: head.x - hr * 1.0, y: head.y - hr * 0.1),
                                control: CGPoint(x: head.x + facing * hr * 0.2, y: head.y - hr * 0.4))
            hairCtx.fill(fringe, with: .color(hairColor))
        }
        if [.long, .waist, .bob].contains(p.style) {
            // Waist-length locks hang down the front, over the shoulders, as far as her waist.
            let top = head.y - hr * 0.3
            let length = p.style == .waist ? pose.torso.maxY - h * 0.06 - top : hr * (p.style == .long ? 2.1 : 1.2)
            for side in [-1.0, 1.0] {
                fill(hairCtx, CGRect(x: head.x + side * hr * 0.98 - hr * 0.2, y: top, width: hr * 0.4, height: length),
                     hairColor, corner: hr * 0.2)
            }
        }
    }
    // A clear plastic processing cap over a hair treatment.
    if p.cap {
        let dome = scalp(CGPoint(x: head.x, y: head.y - hr * 0.05), hr * 1.22)
        ctx.fill(dome, with: .color(Color(white: 1).opacity(0.45)))
        ctx.stroke(dome, with: .color(Color(white: 0.6).opacity(0.8)), lineWidth: max(0.8, hr * 0.06))
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.6, y: head.y - hr * 1.05, width: hr * 0.5, height: hr * 0.2)), with: .color(.white.opacity(0.8)))
    }
    // Shaving cream piled on the scalp, wiped away stroke by stroke by the razor.
    if p.lather > 0 && p.shaved < 1 {
        var foam = ctx
        foam.opacity = min(1, p.lather * 1.5)
        let left = head.x - hr * 1.15 + p.shaved * hr * 2.3
        foam.clip(to: Path(CGRect(x: left, y: head.y - hr * 1.4, width: hr * 2.6, height: hr * 1.4)))
        foam.fill(scalp(head, hr * 1.04), with: .color(.white))
        for i in 0..<9 {
            let ang = (190.0 + Double(i) * 20) * .pi / 180
            guard Double(i) / 9 < p.lather else { break }
            foam.fill(circle(CGPoint(x: head.x + cos(ang) * hr * 0.95, y: head.y + sin(ang) * hr * 0.95), hr * 0.2), with: .color(Color(white: 0.97)))
        }
    }
    // A sun hat and a flower from the accessory store; they vanish with her own hair.
    if p.accessories.contains(.sunHat) {
        let straw = Color(red: 0.93, green: 0.80, blue: 0.52)
        fill(hairCtx, CGRect(x: head.x - hr * 0.85, y: head.y - hr * 1.5, width: hr * 1.7, height: hr * 1.0), straw, corner: hr * 0.4)
        hairCtx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 1.7, y: head.y - hr * 0.85, width: hr * 3.4, height: hr * 0.5)), with: .color(straw))
        fill(hairCtx, CGRect(x: head.x - hr * 0.85, y: head.y - hr * 0.85, width: hr * 1.7, height: hr * 0.2), Color(red: 0.88, green: 0.20, blue: 0.48))
    }
    if p.accessories.contains(.flower) {
        let c = CGPoint(x: head.x + hr * 0.78, y: head.y - hr * 0.72)
        for k in 0..<5 {
            let ang = Double(k) / 5 * 2 * .pi - .pi / 2
            hairCtx.fill(circle(CGPoint(x: c.x + cos(ang) * hr * 0.2, y: c.y + sin(ang) * hr * 0.2), hr * 0.17), with: .color(Color(red: 1, green: 0.50, blue: 0.72)))
        }
        hairCtx.fill(circle(c, hr * 0.12), with: .color(Color(red: 1, green: 0.85, blue: 0.25)))
    }
    // The mop's curls tumble down over the top of the forehead.
    if kind.hairShape == .mop && a > 0 {
        let colors = kind.hairColors
        for i in 0..<7 {
            let x = sc.x + (Double(i) - 3) / 3 * shape.width * 0.82
            let y = shape.top + hr * (0.18 + 0.12 * abs(Double(i) - 3) / 3)
            puff(ctx, at: CGPoint(x: x, y: y), radius: hr * 0.42 * a, colors[(i + 3) % colors.count].color)
        }
    }
    // The bow sits on top of everything.
    if kind.hairShape == .bow && a > 0 {
        let c = CGPoint(x: sc.x, y: shape.top + hr * 0.05)
        let s = hr * 0.62 * a
        for side in [-1.0, 1.0] {
            ctx.fill(polyline([c, CGPoint(x: c.x + side * s * 1.3, y: c.y - s * 0.7), CGPoint(x: c.x + side * s * 1.3, y: c.y + s * 0.6)]), with: .color(trim))
        }
        ctx.fill(circle(c, s * 0.3), with: .color(trim))
    }

    // Face
    let look = facing * hr * 0.15 * (1 - a * 0.5)
    let shocked = p.mood == .shocked && !still
    // Crying only reads on a human face, before the clown makeup takes over.
    let crying = p.mood == .crying && !still && a < 0.5
    // A big open-mouthed smile with happy, crinkled eyes ("Wheeeee!").
    let beaming = p.mood == .beaming && !still
    let eyeY = head.y + hr * mix(0.1, -0.02, a)
    for side in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + side * hr * mix(0.35, 0.42, a) + look, y: eyeY)
        if a > 0 {
            // A painted patch around each eye, with a high arched brow
            var patch = ctx
            patch.opacity = a
            patch.fill(Path(ellipseIn: CGRect(x: e.x - hr * 0.26 * a, y: e.y - hr * 0.5 * a, width: hr * 0.52 * a, height: hr * 0.9 * a)), with: .color(kind.makeup.color))
            var brow = Path()
            brow.move(to: CGPoint(x: e.x - hr * 0.26, y: e.y - hr * 0.55 * a))
            brow.addQuadCurve(to: CGPoint(x: e.x + hr * 0.26, y: e.y - hr * 0.55 * a), control: CGPoint(x: e.x + side * hr * 0.12, y: e.y - hr * (0.55 * a + 0.3)))
            patch.stroke(brow, with: .color(.black.opacity(0.8)), style: StrokeStyle(lineWidth: max(0.8, hr * 0.06), lineCap: .round))
        }
        let ew = hr * mix(0.2, 0.34, a), eh = hr * mix(0.24, 0.3, a)
        let r = CGRect(x: e.x - ew / 2, y: e.y - eh / 2, width: ew, height: eh)
        if shocked && a < 0.5 {
            ctx.fill(Path(ellipseIn: r.insetBy(dx: -hr * 0.06, dy: -hr * 0.06)), with: .color(.white))
            ctx.stroke(Path(ellipseIn: r.insetBy(dx: -hr * 0.06, dy: -hr * 0.06)), with: .color(.black), lineWidth: max(0.8, hr * 0.05))
        }
        if crying {
            // Eyes squeezed shut under sad, upturned brows, with tears running down her cheeks.
            var lid = Path()
            lid.move(to: CGPoint(x: r.minX, y: e.y))
            lid.addQuadCurve(to: CGPoint(x: r.maxX, y: e.y), control: CGPoint(x: e.x, y: e.y + eh * 0.7))
            ctx.stroke(lid, with: .color(.black), style: StrokeStyle(lineWidth: max(0.9, hr * 0.06), lineCap: .round))
            var brow = Path()
            brow.move(to: CGPoint(x: e.x - side * hr * 0.2, y: e.y - hr * 0.38))
            brow.addLine(to: CGPoint(x: e.x + side * hr * 0.16, y: e.y - hr * 0.24))
            ctx.stroke(brow, with: .color(.black.opacity(0.75)), style: StrokeStyle(lineWidth: max(0.8, hr * 0.06), lineCap: .round))
            let tearBlue = Color(red: 0.45, green: 0.75, blue: 1.0)
            var stream = Path()
            stream.move(to: CGPoint(x: e.x + side * ew * 0.35, y: e.y + eh * 0.3))
            stream.addQuadCurve(to: CGPoint(x: e.x + side * ew * 0.5, y: head.y + hr * 0.75), control: CGPoint(x: e.x + side * ew * 0.9, y: e.y + hr * 0.3))
            ctx.stroke(stream, with: .color(tearBlue.opacity(0.75)), style: StrokeStyle(lineWidth: max(1, hr * 0.08), lineCap: .round))
            // Fresh drops keep rolling down and falling off her chin.
            let t = now.timeIntervalSinceReferenceDate
            for k in 0..<2 {
                let u = (t * 0.9 + Double(k) * 0.5 + (side > 0 ? 0.25 : 0)).truncatingRemainder(dividingBy: 1)
                let drop = CGPoint(x: e.x + side * ew * (0.4 + u * 0.3), y: e.y + eh * 0.4 + u * hr * 1.1)
                ctx.fill(circle(drop, max(1, hr * 0.08)), with: .color(tearBlue.opacity(1 - u * 0.6)))
            }
            continue
        }
        if beaming {
            // Eyes crinkled shut in delight: little upside-down U's.
            var lid = Path()
            lid.move(to: CGPoint(x: r.minX, y: e.y + eh * 0.2))
            lid.addQuadCurve(to: CGPoint(x: r.maxX, y: e.y + eh * 0.2), control: CGPoint(x: e.x, y: e.y - eh * 0.8))
            ctx.stroke(lid, with: .color(.black), style: StrokeStyle(lineWidth: max(1, hr * 0.08), lineCap: .round))
            continue
        }
        // Eyes turn yellow with a small dark pupil.
        ctx.fill(Path(ellipseIn: r), with: .color(.black))
        if a > 0 {
            ctx.fill(Path(ellipseIn: r.insetBy(dx: ew * 0.06, dy: eh * 0.06)), with: .color(Color(red: 1, green: 0.93, blue: 0.45).opacity(a)))
            ctx.fill(circle(CGPoint(x: e.x + look * 0.5, y: e.y), ew * 0.2), with: .color(.black.opacity(a)))
        }
    }
    if p.accessories.contains(.sunglasses) {
        for side in [-1.0, 1.0] {
            fill(hairCtx, CGRect(x: head.x + side * hr * 0.38 + look - hr * 0.27, y: eyeY - hr * 0.2, width: hr * 0.54, height: hr * 0.4), Color(white: 0.08), corner: hr * 0.14)
        }
        fill(hairCtx, CGRect(x: head.x + look - hr * 0.15, y: eyeY - hr * 0.12, width: hr * 0.3, height: hr * 0.07), Color(white: 0.08))
    }
    for dx in [-0.75, 0.45] {
        ctx.fill(Path(ellipseIn: CGRect(x: head.x + hr * dx + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)),
                 with: .color(.pink.opacity(0.45 * (1 - a))))
    }

    // The painted grin stretches from jowl to jowl.
    let mouthY = head.y + hr * mix(0.45, 0.5, a)
    let mw = hr * mix(0.25, 0.8, a)
    let lipRed = Color(red: 0.82, green: 0.10, blue: 0.16)
    if crying {
        // A wobbly, downturned sob.
        let wob = sin(now.timeIntervalSinceReferenceDate * 14) * hr * 0.03
        var frown = Path()
        frown.move(to: CGPoint(x: head.x - mw + look, y: mouthY + hr * 0.12))
        frown.addQuadCurve(to: CGPoint(x: head.x + mw + look, y: mouthY + hr * 0.12), control: CGPoint(x: head.x + look, y: mouthY - hr * 0.12 + wob))
        frown.addQuadCurve(to: CGPoint(x: head.x - mw + look, y: mouthY + hr * 0.12), control: CGPoint(x: head.x + look, y: mouthY + hr * 0.02 + wob))
        ctx.fill(frown, with: .color(Color(red: 0.35, green: 0.08, blue: 0.1)))
    } else if beaming {
        // Wide open and laughing: a D-shaped mouth with top teeth and a tongue, red lips once the paint arrives.
        let depth = hr * mix(0.4, 0.75, a)
        var open = Path()
        open.move(to: CGPoint(x: head.x - mw + look, y: mouthY - hr * 0.05))
        open.addQuadCurve(to: CGPoint(x: head.x + mw + look, y: mouthY - hr * 0.05), control: CGPoint(x: head.x + look, y: mouthY - hr * 0.12))
        open.addQuadCurve(to: CGPoint(x: head.x - mw + look, y: mouthY - hr * 0.05), control: CGPoint(x: head.x + look, y: mouthY + depth * 1.6))
        open.closeSubpath()
        ctx.fill(open, with: .color(Color(red: 0.35, green: 0.08, blue: 0.1)))
        var inside = ctx
        inside.clip(to: open)
        inside.fill(Path(ellipseIn: CGRect(x: head.x - mw * 0.55 + look, y: mouthY + depth * 0.45, width: mw * 1.1, height: depth)),
                    with: .color(Color(red: 0.95, green: 0.45, blue: 0.5)))
        fill(inside, CGRect(x: head.x - mw + look, y: mouthY - hr * 0.15, width: mw * 2, height: hr * 0.22 + depth * 0.12),
             Color(red: 1, green: 0.98, blue: 0.9))
        ctx.stroke(open, with: .color(a > 0 ? lipRed.opacity(0.35 + 0.65 * a) : Color(red: 0.55, green: 0.15, blue: 0.15)),
                   lineWidth: max(1, hr * mix(0.06, 0.13, a)))
    } else if shocked {
        let o = CGRect(x: head.x - hr * mix(0.14, 0.3, a) + look, y: mouthY - hr * 0.03, width: hr * mix(0.28, 0.6, a), height: hr * mix(0.32, 0.5, a))
        ctx.fill(Path(ellipseIn: o), with: .color(Color(red: 0.35, green: 0.08, blue: 0.1)))
        if a > 0 { ctx.stroke(Path(ellipseIn: o), with: .color(lipRed.opacity(a)), lineWidth: hr * 0.13 * a) }
    } else {
        func grin(_ halfWidth: Double, _ lift: Double, _ drop: Double) -> Path {
            var g = Path()
            g.move(to: CGPoint(x: head.x - halfWidth + look, y: mouthY - lift))
            g.addQuadCurve(to: CGPoint(x: head.x + halfWidth + look, y: mouthY - lift), control: CGPoint(x: head.x + look, y: mouthY + drop))
            g.addQuadCurve(to: CGPoint(x: head.x - halfWidth + look, y: mouthY - lift), control: CGPoint(x: head.x + look, y: mouthY + drop * 0.25))
            g.closeSubpath()
            return g
        }
        if a > 0.15 {
            var paint = ctx
            paint.opacity = min(1, (a - 0.15) * 2)
            paint.fill(grin(mw, hr * 0.12 * a, hr * 0.95 * a), with: .color(lipRed))
            let teeth = grin(mw * 0.78, hr * 0.04 * a, hr * 0.62 * a)
            paint.fill(teeth, with: .color(Color(red: 1, green: 0.98, blue: 0.88)))
            var gaps = paint
            gaps.clip(to: teeth)
            for k in -2...2 {
                fill(gaps, CGRect(x: head.x + look + Double(k) * mw * 0.26 - 0.4, y: mouthY - hr * 0.1, width: 0.8, height: hr * 0.6), .black.opacity(0.3))
            }
        }
        if a < 0.6 {
            var mouth = Path()
            mouth.move(to: CGPoint(x: head.x - mw + look, y: mouthY))
            mouth.addQuadCurve(to: CGPoint(x: head.x + mw + look, y: mouthY), control: CGPoint(x: head.x + look, y: mouthY + hr * mix(0.25, 0.5, a)))
            ctx.stroke(mouth, with: .color(Color(red: 0.55, green: 0.15, blue: 0.15).opacity(1 - a / 0.6)),
                       style: StrokeStyle(lineWidth: max(1.1, hr * 0.08), lineCap: .round))
        }
    }
    // Red (or pink, blue, purple or orange) circles — or hearts — on the jowls and a big ball of a nose
    if a > 0 {
        for side in [-1.0, 1.0] {
            let c = CGPoint(x: head.x + side * shape.width * 0.72, y: head.y + hr * 0.36)
            let r = hr * (kind.bigCheeks ? 0.36 : kind.boldCheeks ? 0.27 : 0.22) * a
            let paint = GraphicsContext.Shading.color(kind.cheeks.color.opacity((kind.boldCheeks ? 0.95 : 0.8) * a))
            ctx.fill(kind.heartCheeks ? heart(c, r * 1.1) : circle(c, r), with: paint)
        }
        let nose = CGPoint(x: head.x + look * 1.4, y: head.y + hr * 0.2)
        let nr = hr * 0.32 * a
        ctx.fill(circle(nose, nr), with: .radialGradient(Gradient(colors: [kind.noseShine.color, kind.nose.color]),
                                                         center: CGPoint(x: nose.x - nr * 0.3, y: nose.y - nr * 0.3), startRadius: 0, endRadius: nr))
        ctx.fill(circle(CGPoint(x: nose.x - nr * 0.35, y: nose.y - nr * 0.35), nr * 0.25), with: .color(.white.opacity(0.8)))
        // A soft shine on the greasepaint forehead
        ctx.fill(Path(ellipseIn: CGRect(x: sc.x - shape.width * 0.55, y: shape.top + hr * 0.18, width: shape.width * 0.45, height: hr * 0.22)),
                 with: .color(.white.opacity(0.35 * a)))
    }

    guard !still else { return }

    // Tingling: pink sparkles fizz all over, then a glowing line climbs from the toes to the face.
    if p.isTingling(at: now) {
        let tt = now.timeIntervalSinceReferenceDate
        let u = p.progress(at: now)
        let tint = Color(red: 1, green: 0.35, blue: 0.7)
        let bottom = pose.foot[0].y
        let top = shape.top
        if now < p.changeT0 {
            for i in 0..<14 {
                let k = Double(i)
                let g = max(0, sin(tt * 5 + k * 1.7))
                let pt = CGPoint(x: head.x + sin(k * 2.3) * pose.w * 0.8, y: top + (bottom - top) * ((k * 0.37).truncatingRemainder(dividingBy: 1)))
                drawSparkle(ctx, at: pt, size: hr * 0.22 * g, alpha: g * 0.9, tint: tint)
            }
        } else {
            let y = bottom - (bottom - top) * u
            ctx.fill(Path(CGRect(x: head.x - pose.w * 0.9, y: y - 3, width: pose.w * 1.8, height: 6)),
                     with: .linearGradient(Gradient(colors: [.clear, tint.opacity(0.9), .white.opacity(0.9), tint.opacity(0.9), .clear]),
                                           startPoint: CGPoint(x: head.x - pose.w * 0.9, y: y), endPoint: CGPoint(x: head.x + pose.w * 0.9, y: y)))
            for i in 0..<8 {
                let k = Double(i)
                let g = max(0, sin(tt * 7 + k * 2.1))
                drawSparkle(ctx, at: CGPoint(x: head.x + sin(k * 1.9 + tt) * pose.w * 0.7, y: y + cos(k * 2.7) * 8), size: hr * 0.25 * g, alpha: g, tint: tint)
            }
        }
    }

    // Feeling her head: her hands pat the top of it, in front of the hair.
    if p.feelsHead && !still {
        for hd in pose.hand {
            let r = pose.armW * mix(0.62, 0.9, lv.body)
            ctx.fill(circle(hd, r), with: .color(skinHands))
            ctx.stroke(circle(hd, r), with: .color(.black.opacity(0.25)), lineWidth: 0.7)
        }
    }

    // A freshly finished clown twinkles for a couple of seconds.
    let st = now.timeIntervalSince(p.shineT0)
    if st >= 0 && st < 2.4 {
        let pulse = sin(st / 2.4 * .pi)
        drawSparkle(ctx, at: CGPoint(x: head.x - hr * 0.5, y: shape.top + hr * 0.1), size: hr * 0.55 * pulse, alpha: pulse)
        let later = max(0, sin((st - 0.5) / 1.9 * .pi))
        drawSparkle(ctx, at: CGPoint(x: head.x + hr * 0.75, y: shape.top), size: hr * 0.35 * later, alpha: later)
        drawSparkle(ctx, at: CGPoint(x: t.maxX + hr * 0.3, y: t.midY), size: hr * 0.4 * later, alpha: later)
    }
}

/// The top of the head, from ear to ear: where stubble, shine and shaving cream go.
func scalp(_ head: CGPoint, _ hr: Double) -> Path {
    var p = Path()
    p.addArc(center: CGPoint(x: head.x, y: head.y - hr * 0.1), radius: hr, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
    p.closeSubpath()
    return p
}

/// Deidre's clippers, can of shaving cream or safety razor, held up in her hand.
func drawSalonTool(_ ctx: GraphicsContext, _ tool: SalonTool, in hand: CGPoint, size s: Double) {
    switch tool {
    case .clippers:
        fill(ctx, CGRect(x: hand.x - s * 0.3, y: hand.y - s * 1.1, width: s * 0.6, height: s * 1.4), Color(white: 0.15), corner: s * 0.2)
        fill(ctx, CGRect(x: hand.x - s * 0.36, y: hand.y - s * 1.3, width: s * 0.72, height: s * 0.25), Color(white: 0.75), corner: 1)
    case .cream:
        fill(ctx, CGRect(x: hand.x - s * 0.3, y: hand.y - s * 0.9, width: s * 0.6, height: s * 1.5), Color(red: 0.20, green: 0.45, blue: 0.85), corner: s * 0.12)
        fill(ctx, CGRect(x: hand.x - s * 0.18, y: hand.y - s * 1.15, width: s * 0.36, height: s * 0.28), .white, corner: 1)
    case .razor:
        fill(ctx, CGRect(x: hand.x - s * 0.08, y: hand.y - s * 0.9, width: s * 0.16, height: s * 1.3), Color(red: 1, green: 0.55, blue: 0.75), corner: 1)
        fill(ctx, CGRect(x: hand.x - s * 0.4, y: hand.y - s * 1.1, width: s * 0.8, height: s * 0.22), Color(white: 0.8), corner: 1)
    }
}
