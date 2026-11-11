import SwiftUI

/// Where every joint of a person is this frame. Index 0 is the screen-left limb.
struct Pose {
    let h, hr, w, armW, legW: Double
    /// How far her head has swollen into an alien egg, eased (0…1).
    let alien: Double
    let head: CGPoint
    let neck: CGRect
    let torso: CGRect
    let shoulder, elbow, hand, hip, knee, foot: [CGPoint]

    init(_ p: Person, feet: CGPoint, facing: Double, now: Date, still: Bool = false) {
        let h = p.height
        let walking = !still && p.isWalking(at: now)
        let t = now.timeIntervalSinceReferenceDate
        let swing = walking ? sin(t * 9) : 0
        let fy = feet.y - (walking ? abs(swing) * 2 : 0)
        let x = feet.x
        let legLen = h * 0.44
        let torsoH = h * 0.29
        let w = h * 0.22
        let hr = h * p.headScale
        let legW = h * 0.085
        let seated = p.seated && !still
        let lv = p.alienLevel(at: now)
        let alien = lv * lv * (3 - 2 * lv)

        var hip: [CGPoint] = [], knee: [CGPoint] = [], foot: [CGPoint] = []
        let hipY: Double
        if seated {
            hipY = feet.y - legLen * 0.52
            for side in [-1.0, 1.0] {
                let kn = CGPoint(x: x + facing * legLen * 0.5 + side * w * 0.1, y: hipY + 1)
                hip.append(CGPoint(x: x + side * w * 0.2, y: hipY))
                knee.append(kn)
                foot.append(CGPoint(x: kn.x + facing * 2, y: feet.y - h * 0.02))
            }
        } else {
            hipY = fy - legLen
            for side in [-1.0, 1.0] {
                let hp = CGPoint(x: x + side * w * 0.22, y: hipY)
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
            // An alien's shoulders sit tight against her skinny body, so the arms stay attached once the shirt is gone.
            let shoulderX = (w / 2 + h * 0.005) + ((w * 0.36 - h * 0.012) - (w / 2 + h * 0.005)) * alien
            let sh = CGPoint(x: x + side * shoulderX, y: shY + h * 0.035)
            let el: CGPoint, hd: CGPoint
            if let target = p.reachTo, i == reachArm, !still {
                hd = target
                el = CGPoint(x: (sh.x + hd.x) / 2, y: max(sh.y, hd.y) + armLen * 0.12)
            } else if seated {
                hd = CGPoint(x: x + facing * legLen * 0.3 + side * w * 0.12, y: hipY - legW * 0.5)
                el = CGPoint(x: sh.x + side * h * 0.02, y: sh.y + armLen * 0.5)
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

        self.alien = alien
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

    /// The top of the head; an alien's big egg reaches higher.
    var headTop: Double { head.y - hr * (1 + 0.66 * alien) }
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

private func mix(_ a: RGB, _ b: RGB, _ t: Double) -> Color {
    Color(red: mix(a.r, b.r, t), green: mix(a.g, b.g, t), blue: mix(a.b, b.b, t))
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

/// Two huge, slanted black almond eyes, the way the alien's eyes end up.
func drawAlienEyes(_ ctx: GraphicsContext, head: CGPoint, hr: Double, alien a: Double, look: Double = 0, big: Bool = false) {
    let grow = big ? mix(1, 1.3, a) : 1
    for side in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + side * hr * mix(0.35, 0.5, a) + look, y: head.y + hr * mix(0.1, 0.02, a))
        let ew = hr * mix(0.2, 0.68, a) * grow, eh = hr * mix(0.24, 0.36, a) * grow
        var eye = ctx
        eye.translateBy(x: e.x, y: e.y)
        eye.rotate(by: .degrees(side * 28 * a))
        eye.fill(Path(ellipseIn: CGRect(x: -ew / 2, y: -eh / 2, width: ew, height: eh)), with: .color(.black))
        if a > 0 {
            eye.fill(Path(ellipseIn: CGRect(x: -ew * 0.25, y: -eh * 0.35, width: ew * 0.22, height: eh * 0.28)), with: .color(.white.opacity(0.75 * a)))
        }
    }
}

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

func drawBox(_ ctx: GraphicsContext, center c: CGPoint, size s: Double) {
    let r = CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s * 0.85)
    fill(ctx, r, Color(red: 0.78, green: 0.60, blue: 0.38), corner: 2)
    ctx.stroke(Path(roundedRect: r, cornerRadius: 2), with: .color(Color(red: 0.55, green: 0.40, blue: 0.22)), lineWidth: 1.2)
    fill(ctx, CGRect(x: r.minX, y: r.minY + r.height * 0.18, width: r.width, height: r.height * 0.12), Color(red: 0.90, green: 0.82, blue: 0.62))
}

/// Draws someone as far along the change into a Roswell alien as she is at `now`: skin turns green,
/// hair and ears fade away, the head swells into a big egg and the eyes grow into black almonds.
func drawPerson(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, facing: Double, now: Date, reflection: Bool = false) {
    let pose = Pose(p, feet: feet, facing: facing, now: now, still: reflection)
    let level = p.alienLevel(at: now)
    let a = pose.alien
    let skin = mix(p.skin, p.alienColor.skin, level)
    let h = pose.h, hr = pose.hr, head = pose.head
    let limbStyle = { (w: Double) in StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }
    let left = 1 - level
    let hairColor = p.hair.color.opacity(left)
    // Clothes melt away once she's nearly all alien, leaving a smooth, skinny green body.
    let dressed = p.clothesLeft(at: now)
    // Anything bought at Cosmic Customs: an outfit in place of her everyday clothes, accessories, and extra alien features.
    let gear = p.look
    let outfit = gear.outfit
    let dress = outfit?.isDress == true
    let shirt = (outfit?.top ?? p.shirt).color.opacity(dressed)
    let pants = (outfit?.bottom ?? p.pants).color.opacity(dressed)
    let t0 = now.timeIntervalSinceReferenceDate

    // A soft halo around her once she's an alien.
    if gear.features.contains(.glow) && a > 0 {
        let c = CGPoint(x: feet.x, y: (head.y + feet.y) / 2)
        let r = h * 0.62
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.7, y: c.y - r, width: r * 1.4, height: r * 2)),
                 with: .radialGradient(Gradient(colors: [p.alienColor.beam.color.opacity(0.45 * a * (0.8 + 0.2 * sin(t0 * 3))), .clear]),
                                       center: c, startRadius: 0, endRadius: r))
    }

    // Long hair and bobs hang behind the shoulders.
    if left > 0 {
        switch p.style {
        case .long:
            fill(ctx, CGRect(x: head.x - hr * 1.1, y: head.y - hr * 0.6, width: hr * 2.2, height: hr * 2.8), hairColor, corner: hr * 0.8)
        case .bob:
            fill(ctx, CGRect(x: head.x - hr * 1.15, y: head.y - hr * 0.7, width: hr * 2.3, height: hr * 1.75), hairColor, corner: hr * 0.6)
        default:
            break
        }
    }

    // Legs
    for i in 0..<2 {
        let leg = polyline([pose.hip[i], pose.knee[i], pose.foot[i]])
        ctx.stroke(leg, with: .color(skin), style: limbStyle(pose.legW * mix(1, 0.8, a)))
        if !dress { ctx.stroke(leg, with: .color(pants), style: limbStyle(pose.legW * 1.15)) }
        let f = pose.foot[i]
        // Bare feet under the shoes: long and thin once alien.
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - h * mix(0.04, 0.055, a) + facing * h * 0.02, y: f.y - h * 0.01, width: h * mix(0.08, 0.11, a), height: h * 0.035)),
                 with: .color(skin))
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.045 + facing * h * 0.02, y: f.y - h * 0.012, width: h * 0.09, height: h * 0.045)),
                 with: .color(Color(white: 0.25).opacity(dressed)))
    }

    // Neck (thinner once alien) and torso
    let neck = pose.neck
    let neckW = neck.width * mix(1, 0.6, a)
    fill(ctx, CGRect(x: neck.midX - neckW / 2, y: neck.minY, width: neckW, height: neck.height), skin)
    let t = pose.torso
    // Her own body underneath, slimming into a skinny alien torso as she changes.
    let bodyW = t.width * mix(0.92, 0.72, a)
    ctx.fill(Path(roundedRect: CGRect(x: t.midX - bodyW / 2, y: t.minY, width: bodyW, height: t.height), cornerRadius: bodyW * mix(0.35, 0.22, a)), with: .color(skin))
    let spots = gear.features.contains(.spots) && a > 0
    let spotColor = mix(p.alienColor.skin, RGB(r: 0, g: 0, b: 0), 0.3).opacity(0.6 * a)
    if spots {
        for (dx, dy, r) in [(-0.25, 0.25, 0.09), (0.2, 0.45, 0.07), (-0.1, 0.7, 0.08), (0.25, 0.15, 0.05)] {
            ctx.fill(circle(CGPoint(x: t.midX + dx * t.width, y: t.minY + dy * t.height), r * t.width), with: .color(spotColor))
        }
    }
    let torsoPath = Path(roundedRect: t, cornerRadius: pose.w * 0.3)
    ctx.fill(torsoPath, with: .color(shirt))
    var collar = Path()
    collar.addArc(center: CGPoint(x: t.midX, y: t.minY), radius: pose.w * 0.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
    ctx.fill(collar, with: .color(skin))
    if dress {
        // The skirt flares out from the waist down to the knees.
        let waist = t.maxY - h * 0.06
        let hem = max(pose.knee[0].y, pose.knee[1].y) + h * 0.02
        var skirt = Path()
        skirt.move(to: CGPoint(x: t.minX + 1, y: waist))
        skirt.addLine(to: CGPoint(x: t.maxX - 1, y: waist))
        skirt.addLine(to: CGPoint(x: t.midX + t.width * 0.85, y: hem))
        skirt.addLine(to: CGPoint(x: t.midX - t.width * 0.85, y: hem))
        skirt.closeSubpath()
        ctx.fill(skirt, with: .color(shirt))
    } else {
        fill(ctx, CGRect(x: t.minX, y: t.maxY - h * 0.05, width: t.width, height: h * 0.06), pants, corner: 3)
    }
    if outfit?.sparkly == true && dressed > 0 {
        for k in 0..<7 {
            let on = (Int(t0 * 5) + k) % 3 == 0
            let pt = CGPoint(x: t.minX + t.width * (0.15 + 0.7 * (Double(k) * 0.618).truncatingRemainder(dividingBy: 1)),
                             y: t.minY + t.height * (0.15 + 0.9 * (Double(k) * 0.377).truncatingRemainder(dividingBy: 1)))
            ctx.fill(circle(pt, max(0.8, h * 0.006)), with: .color(.white.opacity(dressed * (on ? 1 : 0.35))))
        }
    }
    if gear.accessories.contains(.necklace) && dressed > 0 {
        for k in 0..<7 {
            let ang = (20.0 + Double(k) * 23.3) * .pi / 180
            ctx.fill(circle(CGPoint(x: t.midX + cos(ang) * pose.w * 0.26, y: t.minY + sin(ang) * pose.w * 0.26), max(0.8, h * 0.009)),
                     with: .color(Color(white: 0.97).opacity(dressed)))
        }
    }

    // Arms; hands grow three long alien fingers.
    for i in 0..<2 {
        let arm = polyline([pose.shoulder[i], pose.elbow[i], pose.hand[i]])
        ctx.stroke(arm, with: .color(skin), style: limbStyle(pose.armW * mix(1, 0.8, a)))
        let sleeve = polyline([pose.shoulder[i], lerp(pose.shoulder[i], pose.elbow[i], 0.5)])
        ctx.stroke(sleeve, with: .color(shirt), style: StrokeStyle(lineWidth: pose.armW * 1.35, lineCap: .round))
        let hd = pose.hand[i]
        ctx.fill(circle(hd, pose.armW * 0.62), with: .color(skin))
        if a > 0.3 {
            let dir = atan2(hd.y - pose.elbow[i].y, hd.x - pose.elbow[i].x)
            for spread in [-0.5, 0.0, 0.5] {
                let ang = dir + spread
                let len = pose.armW * 1.1 * a
                var finger = Path()
                finger.move(to: hd)
                finger.addLine(to: CGPoint(x: hd.x + cos(ang) * len, y: hd.y + sin(ang) * len))
                ctx.stroke(finger, with: .color(skin), style: StrokeStyle(lineWidth: pose.armW * 0.32, lineCap: .round))
            }
        }
    }
    if p.carrying && !reflection {
        drawBox(ctx, center: CGPoint(x: t.midX, y: t.minY + t.height * 0.62), size: pose.w * 1.25)
    }
    if gear.accessories.contains(.handbag) && dressed > 0 && !p.bags && !p.carrying && p.reachTo == nil {
        let hd = pose.hand[1]
        let bag = CGRect(x: hd.x - h * 0.045, y: hd.y + h * 0.02, width: h * 0.09, height: h * 0.07)
        var handle = Path()
        handle.addArc(center: CGPoint(x: bag.midX, y: bag.minY), radius: h * 0.025, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
        ctx.stroke(handle, with: .color(Color(red: 0.55, green: 0.10, blue: 0.30).opacity(dressed)), lineWidth: 1.2)
        fill(ctx, bag, Color(red: 0.80, green: 0.20, blue: 0.45).opacity(dressed), corner: 2)
    }
    if p.bags && !reflection {
        for (i, c) in [Color(red: 0.95, green: 0.45, blue: 0.55), Color(red: 0.35, green: 0.60, blue: 0.90)].enumerated() {
            let hd = pose.hand[i]
            let bag = CGRect(x: hd.x - h * 0.07, y: hd.y + h * 0.015, width: h * 0.14, height: h * 0.15)
            var handle = Path()
            handle.addArc(center: CGPoint(x: bag.midX, y: bag.minY), radius: h * 0.035, startAngle: .degrees(180), endAngle: .zero, clockwise: false)
            ctx.stroke(handle, with: .color(c), lineWidth: 1.5)
            fill(ctx, bag, c, corner: 2)
        }
    }

    // Hair behind the head
    if left > 0 {
        switch p.style {
        case .ponytail:
            let back = facing == 0 ? 1.0 : -facing
            ctx.fill(Path(ellipseIn: CGRect(x: head.x + back * hr * 0.85 - hr * 0.35, y: head.y - hr * 0.3, width: hr * 0.7, height: hr * 1.7)),
                     with: .color(hairColor))
        case .bun:
            ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.5, y: head.y - hr * 1.55, width: hr, height: hr * 0.85)), with: .color(hairColor))
        case .pigtails:
            for side in [-1.0, 1.0] {
                ctx.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 1.15 - hr * 0.35, y: head.y - hr * 0.2, width: hr * 0.7, height: hr * 1.3)),
                         with: .color(hairColor))
                ctx.fill(circle(CGPoint(x: head.x + side * hr * 0.98, y: head.y - hr * 0.25), hr * 0.13), with: .color(.pink.opacity(left)))
            }
        case .long, .short, .curly, .bob:
            break
        }
    }

    // Ears fade away, then the head swells into a big alien egg.
    for side in [-1.0, 1.0] where a < 1 {
        ctx.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 0.95 - hr * 0.16, y: head.y - hr * 0.05, width: hr * 0.32, height: hr * 0.42)),
                 with: .color(skin.opacity(1 - a)))
    }
    let shape = headShape(head, hr: hr, alien: a)
    // Antennae sprout from the top of the big alien head.
    if gear.features.contains(.antennae) && a > 0 {
        for side in [-1.0, 1.0] {
            let base = CGPoint(x: shape.center.x + side * shape.width * 0.35, y: shape.top + hr * 0.25)
            let tip = CGPoint(x: base.x + side * hr * 0.45, y: base.y - hr * 1.1 * a + hr * 0.08 * sin(t0 * 4 + side))
            var stalk = Path()
            stalk.move(to: base)
            stalk.addQuadCurve(to: tip, control: CGPoint(x: base.x + side * hr * 0.05, y: base.y - hr * 0.7 * a))
            ctx.stroke(stalk, with: .color(skin), style: StrokeStyle(lineWidth: max(1, hr * 0.1), lineCap: .round))
            ctx.fill(circle(tip, hr * 0.2 * a), with: .color(p.alienColor.beam.color))
        }
    }
    ctx.fill(shape.path, with: .color(skin))
    if a > 0 {
        ctx.stroke(shape.path, with: .color(.black.opacity(0.18 * a)), lineWidth: max(0.6, hr * 0.04))
    }
    if spots {
        for (dx, dy, r) in [(-0.55, -0.55, 0.12), (0.5, -0.75, 0.1), (0.05, -1.0, 0.08), (0.7, -0.2, 0.07), (-0.75, -0.1, 0.06)] {
            ctx.fill(circle(CGPoint(x: shape.center.x + dx * shape.width, y: shape.center.y + dy * hr), r * hr), with: .color(spotColor))
        }
    }

    // Hair on top of the head
    if left > 0 {
        if p.style == .curly {
            for i in 0..<11 {
                let ang = (185.0 + Double(i) * 17) * .pi / 180
                ctx.fill(circle(CGPoint(x: head.x + cos(ang) * hr * 0.95, y: head.y + sin(ang) * hr * 0.95), hr * 0.34), with: .color(hairColor))
            }
            for side in [-1.0, 1.0] {
                ctx.fill(circle(CGPoint(x: head.x + side * hr * 1.05, y: head.y + hr * 0.25), hr * 0.3), with: .color(hairColor))
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
            ctx.fill(fringe, with: .color(hairColor))
        }
        // Side locks over the ears
        if [.long, .bob].contains(p.style) {
            for side in [-1.0, 1.0] {
                fill(ctx, CGRect(x: head.x + side * hr * 0.98 - hr * 0.2, y: head.y - hr * 0.3, width: hr * 0.4, height: hr * (p.style == .long ? 1.6 : 1.2)),
                     hairColor, corner: hr * 0.2)
            }
        }
    }

    // Face: small eyes grow into huge, slanted black almonds.
    let look = facing * hr * 0.15 * (1 - a)
    // A shocked face shows in the mirror too.
    let shocked = p.mood == .shocked
    if shocked && a < 0.5 {
        for side in [-1.0, 1.0] {
            let e = CGPoint(x: head.x + side * hr * 0.35 + look, y: head.y + hr * 0.1)
            ctx.fill(circle(e, hr * 0.17), with: .color(.white))
            ctx.stroke(circle(e, hr * 0.17), with: .color(.black), lineWidth: max(0.8, hr * 0.05))
        }
    }
    drawAlienEyes(ctx, head: head, hr: hr, alien: a, look: look, big: gear.features.contains(.bigEyes))
    if gear.features.contains(.rosyCheeks) && a > 0 {
        for side in [-1.0, 1.0] {
            ctx.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 0.62 - hr * 0.17, y: head.y + hr * 0.3, width: hr * 0.34, height: hr * 0.2)),
                     with: .color(Color(red: 1, green: 0.45, blue: 0.6).opacity(0.6 * a)))
        }
    }
    for dx in [-0.75, 0.45] {
        ctx.fill(Path(ellipseIn: CGRect(x: head.x + hr * dx + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)),
                 with: .color(.pink.opacity(0.45 * (1 - a))))
    }
    // Two tiny nostrils on an alien face
    if a > 0.4 {
        for side in [-1.0, 1.0] {
            ctx.fill(circle(CGPoint(x: head.x + side * hr * 0.07, y: head.y + hr * 0.36), hr * 0.03), with: .color(.black.opacity(0.5 * a)))
        }
    }
    let mouthY = head.y + hr * mix(0.45, 0.52, a)
    let mw = hr * mix(0.25, 0.13, a)
    if shocked {
        let ow = mw * (1.1 + 0.8 * a)
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - ow / 2 + look, y: mouthY - hr * 0.05, width: ow, height: hr * mix(0.32, 0.3, a))),
                 with: .color(Color(red: 0.45, green: 0.10, blue: 0.12)))
    } else {
        var mouth = Path()
        mouth.move(to: CGPoint(x: head.x - mw + look, y: mouthY))
        mouth.addQuadCurve(to: CGPoint(x: head.x + mw + look, y: mouthY), control: CGPoint(x: head.x + look, y: mouthY + hr * mix(0.25, 0.06, a)))
        ctx.stroke(mouth, with: .color(Color(red: 0.6 * (1 - 0.4 * a), green: 0.15, blue: 0.15)),
                   style: StrokeStyle(lineWidth: max(1.2, hr * mix(0.1, 0.08, a)), lineCap: .round))
    }
    // A soft shine on the big alien forehead
    if a > 0 {
        ctx.fill(Path(ellipseIn: CGRect(x: shape.center.x - shape.width * 0.55, y: shape.top + hr * 0.25, width: shape.width * 0.5, height: hr * 0.35)),
                 with: .color(.white.opacity(0.28 * a)))
    }

    // Accessories go when her clothes do.
    guard dressed > 0 else { return }
    if gear.accessories.contains(.sunglasses) {
        let shades = Color.black.opacity(0.85 * dressed)
        for side in [-1.0, 1.0] {
            ctx.fill(Path(roundedRect: CGRect(x: head.x + side * hr * 0.37 - hr * 0.24 + look, y: head.y - hr * 0.04, width: hr * 0.48, height: hr * 0.3),
                          cornerRadius: hr * 0.12), with: .color(shades))
        }
        fill(ctx, CGRect(x: head.x - hr * 0.14 + look, y: head.y + hr * 0.02, width: hr * 0.28, height: hr * 0.06), shades)
    }
    if gear.accessories.contains(.sunHat) {
        let hatColor = Color(red: 0.95, green: 0.85, blue: 0.60).opacity(dressed)
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 1.7, y: shape.top + hr * 0.25, width: hr * 3.4, height: hr * 0.55)), with: .color(hatColor))
        fill(ctx, CGRect(x: head.x - hr * 0.85, y: shape.top - hr * 0.3, width: hr * 1.7, height: hr * 0.75), hatColor, corner: hr * 0.4)
        fill(ctx, CGRect(x: head.x - hr * 0.86, y: shape.top + hr * 0.2, width: hr * 1.72, height: hr * 0.18), Color(red: 0.90, green: 0.30, blue: 0.45).opacity(dressed))
    } else if gear.accessories.contains(.tiara) {
        var crown = Path()
        let y = shape.top + hr * 0.2
        crown.move(to: CGPoint(x: head.x - hr * 0.6, y: y))
        for k in 0..<5 {
            let x = head.x - hr * 0.6 + Double(k) * hr * 0.3
            crown.addLine(to: CGPoint(x: x + hr * 0.15, y: y - hr * (k == 2 ? 0.55 : 0.35)))
            crown.addLine(to: CGPoint(x: x + hr * 0.3, y: y))
        }
        crown.closeSubpath()
        ctx.fill(crown, with: .color(Color(red: 0.95, green: 0.80, blue: 0.30).opacity(dressed)))
        ctx.fill(circle(CGPoint(x: head.x, y: y - hr * 0.22), hr * 0.08), with: .color(Color.pink.opacity(dressed)))
    }
}
