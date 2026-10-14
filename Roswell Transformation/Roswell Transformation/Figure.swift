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
            if p.cuffed && !still {
                // Hands pulled behind the back, wrists together.
                hd = CGPoint(x: x + side * w * 0.12, y: hipY - h * 0.03)
                el = CGPoint(x: x + side * (w / 2 + h * 0.025), y: shY + torsoH * 0.55)
            } else if p.feelHead && !still {
                // Both hands patting the sides of the big new head.
                let pat = sin(t * 6 + Double(i) * 1.3) * hr * 0.08
                hd = CGPoint(x: x + side * hr * 1.3, y: head.y - hr * 0.55 + pat)
                el = CGPoint(x: x + side * (w / 2 + hr * 1.1), y: shY + torsoH * 0.15)
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

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

/// A head shape that morphs from a round human head (`a` = 0) to a Roswell alien's
/// big inverted egg with a pointed chin (`a` = 1).
func headShape(_ head: CGPoint, hr: Double, alien a: Double) -> (path: Path, center: CGPoint, width: Double, top: Double, bottom: Double) {
    let k = 0.5523
    let c = CGPoint(x: head.x, y: head.y - hr * 0.28 * a)
    let wd = hr * mix(1, 1.32, a)
    let top = hr * mix(1, 1.38, a)
    let bottom = hr * mix(1, 1.08, a)
    let chin = k * (1 - 0.72 * a)
    var p = Path()
    p.move(to: CGPoint(x: c.x - wd, y: c.y))
    p.addCurve(to: CGPoint(x: c.x, y: c.y - top), control1: CGPoint(x: c.x - wd, y: c.y - top * k), control2: CGPoint(x: c.x - wd * k, y: c.y - top))
    p.addCurve(to: CGPoint(x: c.x + wd, y: c.y), control1: CGPoint(x: c.x + wd * k, y: c.y - top), control2: CGPoint(x: c.x + wd, y: c.y - top * k))
    p.addCurve(to: CGPoint(x: c.x, y: c.y + bottom), control1: CGPoint(x: c.x + wd, y: c.y + bottom * k), control2: CGPoint(x: c.x + wd * chin, y: c.y + bottom))
    p.addCurve(to: CGPoint(x: c.x - wd, y: c.y), control1: CGPoint(x: c.x - wd * chin, y: c.y + bottom), control2: CGPoint(x: c.x - wd, y: c.y + bottom * k))
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
func drawSparkle(_ ctx: GraphicsContext, at c: CGPoint, size s: Double, alpha: Double, tint: Color = Color(red: 0.6, green: 1, blue: 0.5)) {
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

/// `levels` overrides how far she has changed (the album uses `.none` for "before" and `.full` for "after").
func drawPerson(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, facing: Double, now: Date,
                still: Bool = false, levels: AlienLevels? = nil) {
    let pose = Pose(p, feet: feet, facing: facing, now: now, still: still)
    let h = pose.h, hr = pose.hr, head = pose.head
    let limbStyle = { (w: Double) in StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }
    let lv = levels ?? p.alienLevels(at: now)
    let target = p.alienRGB

    /// Skin turns the alien colour; clothes keep their own.
    func skin(_ amount: Double) -> Color {
        guard let target, amount > 0 else { return p.skin.color }
        return p.skin.mixed(with: target, amount * 0.96).color
    }
    let skinHead = skin(lv.head)
    let skinBody = skin(lv.body)
    let skinLegs = skin(lv.legs)
    let hairColor = p.hair.color
    var hairCtx = ctx
    hairCtx.opacity = 1 - lv.head
    // Once a part of her has finished turning alien, the clothes on it melt away, so she looks like a real Roswell alien;
    // as the change wears off they come back. (The saucer crew keep their silver suits.)
    func dressed(_ amount: Double) -> GraphicsContext {
        var c = ctx
        guard !p.crew else { return c }
        let u = min(max((amount - 0.6) / 0.4, 0), 1)
        c.opacity = 1 - u * u * (3 - 2 * u)
        return c
    }
    let legClothes = dressed(lv.legs)
    let bodyClothes = dressed(lv.body)
    // Alien limbs are skinny.
    let legW = pose.legW * (1 - 0.35 * lv.legs)
    let armW = pose.armW * (1 - 0.35 * lv.body)

    // Long hair and bobs hang behind the shoulders.
    switch p.style {
    case .long where !p.crew:
        fill(hairCtx, CGRect(x: head.x - hr * 1.1, y: head.y - hr * 0.6, width: hr * 2.2, height: hr * 3.5), hairColor, corner: hr * 0.8)
    case .bob where !p.crew:
        fill(hairCtx, CGRect(x: head.x - hr * 1.15, y: head.y - hr * 0.7, width: hr * 2.3, height: hr * 1.75), hairColor, corner: hr * 0.6)
    default:
        break
    }

    // Legs
    for i in 0..<2 {
        let leg = polyline([pose.hip[i], pose.knee[i], pose.foot[i]])
        ctx.stroke(leg, with: .color(skinLegs), style: limbStyle(legW))
        if p.shorts || p.bikini {
            // Shorts stop above the knee; a bikini leaves the whole leg bare.
            if !p.bikini {
                legClothes.stroke(polyline([pose.hip[i], lerp(pose.hip[i], pose.knee[i], p.seated ? 0.9 : 0.6)]), with: .color(p.pants.color),
                           style: StrokeStyle(lineWidth: pose.legW * 1.3, lineCap: .butt))
            }
        } else {
            legClothes.stroke(leg, with: .color(p.pants.color), style: limbStyle(pose.legW * 1.1))
        }
        // Shoes give way to long, thin alien feet.
        let f = pose.foot[i]
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.05 + facing * h * 0.02, y: f.y - h * 0.01, width: h * 0.1, height: h * 0.035)),
                 with: .color(skinLegs))
        if !p.crew {
            ctx.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.045 + facing * h * 0.02, y: f.y - h * 0.012, width: h * 0.09, height: h * 0.045)),
                     with: .color(Color(white: 0.25).opacity(1 - lv.legs)))
        }
    }

    // Neck (thinner once alien) and torso
    let nw = pose.neck.width * (1 - 0.4 * lv.head)
    fill(ctx, CGRect(x: pose.neck.midX - nw / 2, y: pose.neck.minY, width: nw, height: pose.neck.height), skinHead)
    let t = pose.torso
    let torsoPath = Path(roundedRect: t, cornerRadius: pose.w * 0.3)
    if !p.crew {
        // Her own body underneath, slimming into a smooth, skinny alien torso as it changes.
        let slim = t.width * 0.18 * lv.body
        let bare = t.insetBy(dx: slim / 2, dy: 0)
        ctx.fill(Path(roundedRect: bare, cornerRadius: bare.width * mix(0.3, 0.45, lv.body)), with: .color(skinBody))
    }
    if p.bikini && !p.crew {
        // A two-piece top and matching bottoms.
        let suit = p.shirt.color
        let cupY = t.minY + t.height * 0.3
        for side in [-1.0, 1.0] {
            let cx = t.midX + side * t.width * 0.22
            bodyClothes.fill(polyline([CGPoint(x: cx - t.width * 0.2, y: cupY + t.height * 0.12), CGPoint(x: cx, y: cupY - t.height * 0.12),
                                       CGPoint(x: cx + t.width * 0.2, y: cupY + t.height * 0.12)]), with: .color(suit))
            bodyClothes.stroke(polyline([CGPoint(x: cx, y: cupY - t.height * 0.12), CGPoint(x: cx + side * t.width * 0.08, y: t.minY)]),
                               with: .color(suit), lineWidth: max(0.8, h * 0.006))
        }
        fill(bodyClothes, CGRect(x: t.minX + t.width * 0.02, y: cupY + t.height * 0.1, width: t.width * 0.96, height: h * 0.012), suit)
        var bottoms = Path()
        bottoms.addLines([CGPoint(x: t.minX, y: t.maxY - h * 0.05), CGPoint(x: t.maxX, y: t.maxY - h * 0.05),
                          CGPoint(x: t.midX + t.width * 0.15, y: t.maxY + h * 0.035), CGPoint(x: t.midX - t.width * 0.15, y: t.maxY + h * 0.035)])
        bottoms.closeSubpath()
        legClothes.fill(bottoms, with: .color(suit))
    } else {
        bodyClothes.fill(torsoPath, with: .color(p.shirt.color))
        var collar = Path()
        collar.addArc(center: CGPoint(x: t.midX, y: t.minY), radius: pose.w * 0.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
        bodyClothes.fill(collar, with: .color(skinBody))
    }
    if p.crew {
        // A silver suit with a glowing emblem on the chest.
        ctx.fill(circle(CGPoint(x: t.midX, y: t.minY + t.height * 0.35), pose.w * 0.14), with: .color(Color(red: 0.4, green: 1, blue: 0.5)))
        fill(ctx, CGRect(x: t.minX, y: t.maxY - h * 0.05, width: t.width, height: h * 0.035), Color(white: 0.55), corner: 2)
    } else if !p.bikini {
        // The waistband goes with the pants.
        fill(legClothes, CGRect(x: t.minX, y: t.maxY - h * 0.05, width: t.width, height: h * 0.06), p.pants.color, corner: 3)
    }

    /// As her torso slims and her arms thin out, the arms move in with it so the shoulders stay joined to the body.
    /// `k` is how much of the shift a joint gets: all of it at the shoulder, a little less further down the arm.
    let tuck = p.crew ? 0 : lv.body * (t.width * 0.09 + h * 0.005 + armW * 0.3)
    func joint(_ pt: CGPoint, _ i: Int, _ k: Double) -> CGPoint {
        CGPoint(x: pt.x + (i == 0 ? 1 : -1) * tuck * k, y: pt.y)
    }
    /// A hand, with long three alien fingers once the change reaches the arms.
    func drawHand(_ i: Int) {
        let hd = joint(pose.hand[i], i, 0.7)
        ctx.fill(circle(hd, pose.armW * 0.62 * (1 - 0.2 * lv.body)), with: .color(skinBody))
        if lv.body > 0.3 {
            let dir = lerp(joint(pose.elbow[i], i, 0.85), hd, 1.35)
            let dx = dir.x - hd.x, dy = dir.y - hd.y
            for spread in [-0.45, 0.0, 0.45] {
                let end = CGPoint(x: hd.x + dx * cos(spread) - dy * sin(spread), y: hd.y + dx * sin(spread) + dy * cos(spread))
                ctx.stroke(polyline([hd, lerp(hd, end, 0.8)]), with: .color(skinBody.opacity(min(1, (lv.body - 0.3) * 2))),
                           style: StrokeStyle(lineWidth: armW * 0.3, lineCap: .round))
            }
        }
    }
    // Arms, with long three-fingered alien hands
    for i in 0..<2 {
        let sh = joint(pose.shoulder[i], i, 1), el = joint(pose.elbow[i], i, 0.85), hd = joint(pose.hand[i], i, 0.7)
        let arm = polyline([sh, el, hd])
        ctx.stroke(arm, with: .color(skinBody), style: limbStyle(armW))
        if !p.bikini || p.crew {
            let sleeve = polyline([sh, lerp(sh, el, p.crew ? 1 : 0.5)])
            bodyClothes.stroke(sleeve, with: .color(p.shirt.color), style: StrokeStyle(lineWidth: pose.armW * 1.35, lineCap: .round))
        }
        drawHand(i)
    }
    if p.cuffed && !still {
        // Silver handcuffs on both wrists, with a short chain between them.
        let l = joint(pose.hand[0], 0, 0.7), r = joint(pose.hand[1], 1, 0.7)
        let steel = Color(white: 0.78)
        ctx.stroke(polyline([l, r]), with: .color(Color(white: 0.55)), lineWidth: max(1, h * 0.006))
        for c in [l, r] { ctx.stroke(circle(CGPoint(x: c.x, y: c.y - pose.armW * 0.3), pose.armW * 0.55), with: .color(steel), lineWidth: max(1.2, h * 0.01)) }
    }
    if p.carrying && !still {
        let at = CGPoint(x: t.midX, y: t.minY + t.height * 0.62)
        if p.groceries { drawGroceryBag(ctx, center: at, size: pose.w * 1.2) } else { drawBox(ctx, center: at, size: pose.w * 1.25) }
    }

    // Rocking her head from side to side: the whole head tilts about the neck.
    var headCtx = ctx
    var headHair = hairCtx
    let rock = still ? 0 : p.rockAngle(at: now)
    if rock != 0 {
        let pivot = CGPoint(x: head.x, y: head.y + hr * 0.7)
        headCtx.translateBy(x: pivot.x, y: pivot.y)
        headCtx.rotate(by: .degrees(rock))
        headCtx.translateBy(x: -pivot.x, y: -pivot.y)
        headHair.translateBy(x: pivot.x, y: pivot.y)
        headHair.rotate(by: .degrees(rock))
        headHair.translateBy(x: -pivot.x, y: -pivot.y)
    }

    // Hair behind the head
    if !p.crew {
        switch p.style {
        case .ponytail:
            let back = facing == 0 ? 1.0 : -facing
            headHair.fill(Path(ellipseIn: CGRect(x: head.x + back * hr * 0.85 - hr * 0.35, y: head.y - hr * 0.3, width: hr * 0.7, height: hr * 1.7)),
                         with: .color(hairColor))
        case .bun:
            headHair.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.5, y: head.y - hr * 1.55, width: hr, height: hr * 0.85)), with: .color(hairColor))
        case .pigtails:
            for side in [-1.0, 1.0] {
                headHair.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 1.15 - hr * 0.35, y: head.y - hr * 0.2, width: hr * 0.7, height: hr * 1.3)),
                             with: .color(hairColor))
                headHair.fill(circle(CGPoint(x: head.x + side * hr * 0.98, y: head.y - hr * 0.25), hr * 0.13), with: .color(Color(red: 1, green: 0.6, blue: 0.75)))
            }
        case .long, .short, .curly, .bob:
            break
        }

        // Ears fade away.
        var ears = headCtx
        ears.opacity = 1 - lv.head
        for side in [-1.0, 1.0] {
            ears.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 0.95 - hr * 0.16, y: head.y - hr * 0.05, width: hr * 0.32, height: hr * 0.42)),
                      with: .color(skinHead))
        }
    }

    // The head itself slowly swells into a big alien egg, easing in and out.
    let a = lv.head * lv.head * (3 - 2 * lv.head)
    let shape = headShape(head, hr: hr, alien: a)
    headCtx.fill(shape.path, with: .color(skinHead))
    if a > 0 {
        headCtx.stroke(shape.path, with: .color(.black.opacity(0.18 * a)), lineWidth: max(0.6, hr * 0.04))
    }

    // Hair on top of the head fades away.
    if !p.crew {
        if p.style == .curly {
            for i in 0..<11 {
                let ang = (185.0 + Double(i) * 17) * .pi / 180
                headHair.fill(circle(CGPoint(x: head.x + cos(ang) * hr * 0.95, y: head.y + sin(ang) * hr * 0.95), hr * 0.34), with: .color(hairColor))
            }
            for side in [-1.0, 1.0] {
                headHair.fill(circle(CGPoint(x: head.x + side * hr * 1.05, y: head.y + hr * 0.25), hr * 0.3), with: .color(hairColor))
            }
        } else {
            var fringe = Path()
            for step in 0...16 {
                let ang = (190.0 + Double(step) * 10) * .pi / 180
                let pt = CGPoint(x: head.x + cos(ang) * hr * 1.05, y: head.y + sin(ang) * hr * 1.05)
                step == 0 ? fringe.move(to: pt) : fringe.addLine(to: pt)
            }
            fringe.addQuadCurve(to: CGPoint(x: head.x - hr * 1.0, y: head.y - hr * 0.1),
                                control: CGPoint(x: head.x + facing * hr * 0.2, y: head.y - hr * 0.4))
            headHair.fill(fringe, with: .color(hairColor))
        }
        if [.long, .bob].contains(p.style) {
            for side in [-1.0, 1.0] {
                fill(headHair, CGRect(x: head.x + side * hr * 0.98 - hr * 0.2, y: head.y - hr * 0.3, width: hr * 0.4, height: hr * (p.style == .long ? 2.1 : 1.2)),
                     hairColor, corner: hr * 0.2)
            }
        }
    }

    // Face: small eyes grow into huge, slanted black almonds.
    let look = facing * hr * 0.15 * (1 - a)
    let shocked = p.mood == .shocked && !still
    for side in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + side * hr * mix(0.35, 0.5, a) + look, y: head.y + hr * mix(0.1, 0.02, a))
        let ew = hr * mix(0.2, 0.68, a), eh = hr * mix(0.24, 0.36, a)
        var eye = headCtx
        eye.translateBy(x: e.x, y: e.y)
        eye.rotate(by: .degrees(side * 28 * a))
        let r = CGRect(x: -ew / 2, y: -eh / 2, width: ew, height: eh)
        if shocked && a < 0.5 {
            eye.fill(Path(ellipseIn: r.insetBy(dx: -hr * 0.06, dy: -hr * 0.06)), with: .color(.white))
            eye.stroke(Path(ellipseIn: r.insetBy(dx: -hr * 0.06, dy: -hr * 0.06)), with: .color(.black), lineWidth: max(0.8, hr * 0.05))
        }
        eye.fill(Path(ellipseIn: r), with: .color(.black))
        if a > 0 {
            eye.fill(Path(ellipseIn: CGRect(x: -ew * 0.25, y: -eh * 0.35, width: ew * 0.22, height: eh * 0.28)), with: .color(.white.opacity(0.75 * a)))
        }
    }
    for dx in [-0.75, 0.45] {
        headCtx.fill(Path(ellipseIn: CGRect(x: head.x + hr * dx + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)),
                 with: .color(.pink.opacity(0.45 * (1 - a))))
    }
    // Two tiny nostrils on an alien face
    if a > 0.4 {
        for side in [-1.0, 1.0] {
            headCtx.fill(circle(CGPoint(x: head.x + side * hr * 0.07, y: head.y + hr * 0.36), hr * 0.03), with: .color(.black.opacity(0.5 * a)))
        }
    }
    let mouthY = head.y + hr * mix(0.45, 0.52, a)
    let mw = hr * mix(0.25, 0.13, a)
    if p.mood == .angry && !still {
        // Furious: brows slammed down toward the nose, and a wide-open yell.
        for side in [-1.0, 1.0] {
            var brow = Path()
            brow.move(to: CGPoint(x: head.x + side * hr * 0.6 + look, y: head.y - hr * 0.12))
            brow.addLine(to: CGPoint(x: head.x + side * hr * 0.15 + look, y: head.y + hr * 0.02))
            headCtx.stroke(brow, with: .color(Color(white: 0.12)), style: StrokeStyle(lineWidth: max(1.2, hr * 0.1), lineCap: .round))
        }
        var yell = Path()
        yell.move(to: CGPoint(x: head.x - mw * 0.9 + look, y: mouthY + hr * 0.12))
        yell.addQuadCurve(to: CGPoint(x: head.x + mw * 0.9 + look, y: mouthY + hr * 0.12), control: CGPoint(x: head.x + look, y: mouthY - hr * 0.12))
        yell.addQuadCurve(to: CGPoint(x: head.x - mw * 0.9 + look, y: mouthY + hr * 0.12), control: CGPoint(x: head.x + look, y: mouthY + hr * 0.3))
        headCtx.fill(yell, with: .color(Color(red: 0.4, green: 0.06, blue: 0.08)))
        headCtx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.95 + look, y: head.y + hr * 0.22, width: hr * 0.4, height: hr * 0.25)), with: .color(.red.opacity(0.35)))
        headCtx.fill(Path(ellipseIn: CGRect(x: head.x + hr * 0.55 + look, y: head.y + hr * 0.22, width: hr * 0.4, height: hr * 0.25)), with: .color(.red.opacity(0.35)))
    } else if p.mood == .smiling && !still {
        // A big open grin for the camera.
        let gw = hr * mix(0.3, 0.24, a)
        var grin = Path()
        grin.move(to: CGPoint(x: head.x - gw + look, y: mouthY - hr * 0.03))
        grin.addQuadCurve(to: CGPoint(x: head.x + gw + look, y: mouthY - hr * 0.03), control: CGPoint(x: head.x + look, y: mouthY + hr * 0.38))
        grin.closeSubpath()
        headCtx.fill(grin, with: .color(Color(red: 0.4, green: 0.08, blue: 0.12)))
        var teeth = headCtx
        teeth.clip(to: grin)
        teeth.fill(Path(CGRect(x: head.x - gw + look, y: mouthY - hr * 0.03, width: gw * 2, height: hr * 0.1)), with: .color(.white))
    } else if shocked {
        headCtx.fill(Path(ellipseIn: CGRect(x: head.x - mw * 0.55 + look, y: mouthY - hr * 0.03, width: mw * 1.1, height: hr * mix(0.32, 0.16, a))),
                 with: .color(Color(red: 0.35, green: 0.08, blue: 0.1)))
    } else {
        var mouth = Path()
        mouth.move(to: CGPoint(x: head.x - mw + look, y: mouthY))
        mouth.addQuadCurve(to: CGPoint(x: head.x + mw + look, y: mouthY), control: CGPoint(x: head.x + look, y: mouthY + hr * mix(0.25, 0.06, a)))
        let lip = p.alien?.isDark == true && a > 0.5 ? Color(red: 0.8, green: 0.8, blue: 0.95) : Color(red: 0.55, green: 0.15, blue: 0.15).mix(with: .black, by: 0.4 * a)
        headCtx.stroke(mouth, with: .color(lip), style: StrokeStyle(lineWidth: max(1.1, hr * 0.08), lineCap: .round))
    }
    // A soft shine on the big alien forehead
    if a > 0 {
        headCtx.fill(Path(ellipseIn: CGRect(x: shape.center.x - shape.width * 0.55, y: shape.top + hr * 0.25, width: shape.width * 0.5, height: hr * 0.35)),
                 with: .color(.white.opacity(0.28 * a)))
    }
    // Hands feeling the head go in front of it.
    if p.feelHead && !still {
        for i in 0..<2 { drawHand(i) }
    }

    guard !still else { return }

    // Tingling: green sparkles fizz all over, then a glowing line climbs from the toes to the face.
    if p.isTingling(at: now) {
        let tt = now.timeIntervalSinceReferenceDate
        let u = p.progress(at: now)
        let tint = p.alien?.color ?? .green
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

    // A freshly finished alien twinkles for a couple of seconds.
    let st = now.timeIntervalSince(p.shineT0)
    if st >= 0 && st < 2.4 {
        let pulse = sin(st / 2.4 * .pi)
        drawSparkle(ctx, at: CGPoint(x: head.x - hr * 0.5, y: shape.top + hr * 0.1), size: hr * 0.55 * pulse, alpha: pulse)
        let later = max(0, sin((st - 0.5) / 1.9 * .pi))
        drawSparkle(ctx, at: CGPoint(x: head.x + hr * 0.75, y: shape.top), size: hr * 0.35 * later, alpha: later)
        drawSparkle(ctx, at: CGPoint(x: t.maxX + hr * 0.3, y: t.midY), size: hr * 0.4 * later, alpha: later)
    }
}
