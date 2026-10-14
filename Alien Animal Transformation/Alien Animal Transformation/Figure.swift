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
        let holding = p.load != nil && p.load != .suitcase && !still
        for (i, side) in [-1.0, 1.0].enumerated() {
            let sh = CGPoint(x: x + side * (w / 2 + h * 0.005), y: shY + h * 0.035)
            let el: CGPoint, hd: CGPoint
            if p.feelsHead && !still {
                // Hands up by her new ears, patting her head, elbows out wide.
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
            } else if holding {
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

/// The glow of the transformation: sparkles, rings and beams.
let changeGlow = Color(red: 0.40, green: 1.0, blue: 0.50)

/// A head shape that morphs from a round human head (`a` = 0) to an alien animal's head (`a` = 1):
/// round for the cats and the pig, broad for the gorilla, rhino and hippo, long for the zebra, aardvark and elephant.
func headShape(_ head: CGPoint, hr: Double, animal a: Double, style: AnimalHead) -> (path: Path, center: CGPoint, width: Double, top: Double, bottom: Double) {
    let k = 0.5523
    let c = CGPoint(x: head.x, y: head.y - hr * 0.05 * a)
    let wd = hr * mix(1, style == .wide ? 1.32 : style == .long ? 1.0 : 1.15, a)
    let top = hr * mix(1, style == .long ? 1.12 : 1.08, a)
    let bottom = hr * mix(1, style == .long ? 1.5 : style == .wide ? 1.22 : 1.1, a)
    let chin = mix(k, style == .long ? 0.4 : 0.6, a)
    let jaw = mix(1, style == .long ? 0.85 : 1.0, a)
    var p = Path()
    p.move(to: CGPoint(x: c.x - wd, y: c.y))
    p.addCurve(to: CGPoint(x: c.x, y: c.y - top), control1: CGPoint(x: c.x - wd, y: c.y - top * k), control2: CGPoint(x: c.x - wd * k, y: c.y - top))
    p.addCurve(to: CGPoint(x: c.x + wd, y: c.y), control1: CGPoint(x: c.x + wd * k, y: c.y - top), control2: CGPoint(x: c.x + wd, y: c.y - top * k))
    p.addCurve(to: CGPoint(x: c.x, y: c.y + bottom), control1: CGPoint(x: c.x + wd * jaw, y: c.y + bottom * 0.6), control2: CGPoint(x: c.x + wd * chin, y: c.y + bottom))
    p.addCurve(to: CGPoint(x: c.x - wd, y: c.y), control1: CGPoint(x: c.x - wd * chin, y: c.y + bottom), control2: CGPoint(x: c.x - wd * jaw, y: c.y + bottom * 0.6))
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

/// A glossy boutique bag with rope handles, full of new clothes.
func drawShoppingBag(_ ctx: GraphicsContext, center c: CGPoint, size s: Double) {
    let r = CGRect(x: c.x - s * 0.42, y: c.y - s * 0.4, width: s * 0.84, height: s * 0.9)
    var handle = Path()
    handle.move(to: CGPoint(x: r.minX + s * 0.2, y: r.minY))
    handle.addQuadCurve(to: CGPoint(x: r.maxX - s * 0.2, y: r.minY), control: CGPoint(x: c.x, y: r.minY - s * 0.5))
    ctx.stroke(handle, with: .color(Color(white: 0.15)), lineWidth: max(1, s * 0.06))
    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.3, y: r.minY - s * 0.2, width: s * 0.3, height: s * 0.28)), with: .color(Color(red: 0.55, green: 0.80, blue: 0.95)))
    fill(ctx, r, Color(red: 0.95, green: 0.35, blue: 0.62), corner: 2)
    fill(ctx, CGRect(x: r.minX, y: r.midY - s * 0.08, width: r.width, height: s * 0.16), .white.opacity(0.85))
}

func drawBox(_ ctx: GraphicsContext, center c: CGPoint, size s: Double) {
    let r = CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s * 0.85)
    fill(ctx, r, Color(red: 0.78, green: 0.60, blue: 0.38), corner: 2)
    ctx.stroke(Path(roundedRect: r, cornerRadius: 2), with: .color(Color(red: 0.55, green: 0.40, blue: 0.22)), lineWidth: 1.2)
    fill(ctx, CGRect(x: r.minX, y: r.minY + r.height * 0.18, width: r.width, height: r.height * 0.12), Color(red: 0.90, green: 0.82, blue: 0.62))
}

/// A wheeled suitcase hanging from her hand.
func drawSuitcase(_ ctx: GraphicsContext, hand: CGPoint, size s: Double) {
    fill(ctx, CGRect(x: hand.x - s * 0.04, y: hand.y, width: s * 0.08, height: s * 0.25), Color(white: 0.3))
    let r = CGRect(x: hand.x - s * 0.32, y: hand.y + s * 0.22, width: s * 0.64, height: s * 0.85)
    fill(ctx, r, Color(red: 0.25, green: 0.45, blue: 0.75), corner: s * 0.08)
    for k in 1...2 { fill(ctx, CGRect(x: r.minX + r.width * Double(k) / 3 - 1, y: r.minY + 2, width: 2, height: r.height - 4), Color(red: 0.18, green: 0.34, blue: 0.60)) }
}

/// A four-pointed twinkle.
func drawSparkle(_ ctx: GraphicsContext, at c: CGPoint, size s: Double, alpha: Double, tint: Color = changeGlow) {
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
                still: Bool = false, levels: AnimalLevels? = nil) {
    let pose = Pose(p, feet: feet, facing: facing, now: now, still: still)
    let h = pose.h, hr = pose.hr, head = pose.head
    let limbStyle = { (w: Double) in StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }
    let lv = levels ?? p.animalLevels(at: now)
    let kind = p.animal ?? .gorilla
    let fur = kind.fur.color, dark = kind.dark.color, light = kind.light.color
    let tt = still ? 0 : now.timeIntervalSinceReferenceDate
    let back = facing == 0 ? 1.0 : -facing

    /// Fur, hide and hooves show through as soon as the change reaches that part of the body.
    func layer(_ amount: Double) -> GraphicsContext {
        var c = ctx
        c.opacity = min(1, amount * 1.5)
        return c
    }
    /// Short bands across a limb: tiger and zebra stripes.
    func limbStripes(_ c: GraphicsContext, _ pts: [CGPoint], width w: Double, count: Int) {
        for k in 0..<count {
            let u = (Double(k) + 0.6) / (Double(count) + 0.4)
            let pt = u < 0.5 ? lerp(pts[0], pts[1], u * 2) : lerp(pts[1], pts[2], u * 2 - 1)
            c.stroke(polyline([CGPoint(x: pt.x - w * 0.5, y: pt.y - w * 0.12), CGPoint(x: pt.x + w * 0.5, y: pt.y + w * 0.12)]),
                     with: .color(dark), lineWidth: w * (kind.pattern == .zebraStripes ? 0.26 : 0.18))
        }
    }
    let skinHead = p.skin.mixed(with: kind.fur, lv.head * 0.97).color
    // Hands turn into big dark hands, hooves and trotters, or furry paws.
    let handRGB = [.hands, .hooves, .trotters].contains(kind.feet) ? kind.dark : kind.fur
    let skinHands = p.skin.mixed(with: handRGB, lv.body * 0.95).color
    let skinBody = p.skin.color
    let hairColor = p.hair.color
    var hairCtx = ctx
    hairCtx.opacity = 1 - lv.head
    // The head reshapes, easing in and out.
    let a = lv.head * lv.head * (3 - 2 * lv.head)
    let shape = headShape(head, hr: hr, animal: a, style: kind.head)
    let t = pose.torso

    // Long hair and bobs hang behind the shoulders.
    switch p.style {
    case .long:
        fill(hairCtx, CGRect(x: head.x - hr * 1.1, y: head.y - hr * 0.6, width: hr * 2.2, height: hr * 3.5), hairColor, corner: hr * 0.8)
    case .waist:
        let top = head.y - hr * 0.6
        fill(hairCtx, CGRect(x: head.x - hr * 1.25, y: top, width: hr * 2.5, height: t.maxY - h * 0.05 - top), hairColor, corner: hr * 0.8)
    case .bob:
        fill(hairCtx, CGRect(x: head.x - hr * 1.15, y: head.y - hr * 0.7, width: hr * 2.3, height: hr * 1.75), hairColor, corner: hr * 0.6)
    default:
        break
    }

    // A tail grows out behind her as the change reaches her body.
    if lv.body > 0 && kind.tail != .none {
        let tc = layer(lv.body)
        let base = CGPoint(x: t.midX + back * t.width * 0.3, y: t.maxY - h * 0.03)
        let grow = mix(0.3, 1, lv.body)
        let swish = sin(tt * 3) * h * 0.01
        switch kind.tail {
        case .tuft:
            let tip = CGPoint(x: base.x + back * h * 0.2 * grow, y: base.y + h * 0.13 * grow + swish)
            var tail = Path()
            tail.move(to: base)
            tail.addQuadCurve(to: tip, control: CGPoint(x: base.x + back * h * 0.22 * grow, y: base.y - h * 0.04))
            tc.stroke(tail, with: .color(fur), style: limbStyle(h * 0.014))
            tc.stroke(tail, with: .color(dark.opacity(0.35)), style: limbStyle(h * 0.004))
            tc.fill(Path(ellipseIn: CGRect(x: tip.x - h * 0.024, y: tip.y - h * 0.014, width: h * 0.048, height: h * 0.056)), with: .color(dark))
        case .striped:
            let tip = CGPoint(x: base.x + back * h * 0.26 * grow, y: base.y - h * 0.1 * grow + swish)
            var tail = Path()
            tail.move(to: base)
            tail.addCurve(to: tip, control1: CGPoint(x: base.x + back * h * 0.14, y: base.y + h * 0.08), control2: CGPoint(x: tip.x, y: tip.y + h * 0.1))
            tc.stroke(tail, with: .color(fur), style: limbStyle(h * 0.028))
            tc.stroke(tail, with: .color(dark), style: StrokeStyle(lineWidth: h * 0.029, lineCap: .butt, dash: [h * 0.015, h * 0.03], dashPhase: h * 0.01))
            tc.fill(circle(tip, h * 0.015), with: .color(dark))
        case .curly:
            var tail = Path()
            let c = CGPoint(x: base.x + back * h * 0.04, y: base.y)
            for k in 0...30 {
                let u = Double(k) / 30, ang = u * 4 * .pi
                let r = h * 0.026 * (1 - u * 0.6) * grow
                let pt = CGPoint(x: c.x + back * cos(ang) * r, y: c.y + sin(ang) * r)
                k == 0 ? tail.move(to: pt) : tail.addLine(to: pt)
            }
            tc.stroke(tail, with: .color(fur), style: limbStyle(h * 0.012))
            tc.stroke(tail, with: .color(dark.opacity(0.5)), style: limbStyle(h * 0.004))
        case .thin:
            let tip = CGPoint(x: base.x + back * h * 0.07 * grow, y: base.y + h * 0.12 * grow + swish)
            tc.stroke(polyline([base, tip]), with: .color(fur), style: limbStyle(h * 0.012))
            tc.fill(Path(ellipseIn: CGRect(x: tip.x - h * 0.012, y: tip.y - h * 0.006, width: h * 0.024, height: h * 0.036)), with: .color(dark))
        case .thick, .banded:
            let long = kind.tail == .thick
            let tip = CGPoint(x: base.x + back * h * (long ? 0.3 : 0.2) * grow, y: min(pose.foot[0].y, pose.foot[1].y) - h * (long ? 0.02 : 0.1))
            var tail = Path()
            tail.move(to: CGPoint(x: base.x, y: base.y - h * 0.035))
            tail.addQuadCurve(to: tip, control: CGPoint(x: base.x + back * h * 0.2 * grow, y: base.y))
            tail.addQuadCurve(to: CGPoint(x: base.x, y: base.y + h * 0.035), control: CGPoint(x: base.x + back * h * 0.12 * grow, y: base.y + h * 0.06))
            tail.closeSubpath()
            tc.fill(tail, with: .color(fur))
            tc.stroke(tail, with: .color(dark.opacity(0.5)), lineWidth: max(0.6, h * 0.004))
            if !long {
                var bands = tc
                bands.clip(to: tail)
                for k in 1...5 {
                    let x = base.x + back * h * 0.035 * Double(k)
                    bands.stroke(polyline([CGPoint(x: x, y: base.y - h * 0.08), CGPoint(x: x + back * h * 0.01, y: tip.y + h * 0.04)]), with: .color(dark), lineWidth: max(0.6, h * 0.004))
                }
            }
        case .long:
            // A horse's long flowing tail of hair, reaching almost to the floor.
            let hair = (kind.mane ?? kind.dark).color
            let tip = CGPoint(x: base.x + back * h * 0.12 * grow + swish, y: base.y + (min(pose.foot[0].y, pose.foot[1].y) - base.y) * 0.85 * grow)
            var tail = Path()
            tail.move(to: CGPoint(x: base.x, y: base.y - h * 0.02))
            tail.addQuadCurve(to: CGPoint(x: tip.x + back * h * 0.03, y: tip.y), control: CGPoint(x: base.x + back * h * 0.16, y: base.y + h * 0.02))
            tail.addQuadCurve(to: CGPoint(x: tip.x - back * h * 0.03, y: tip.y), control: CGPoint(x: tip.x, y: tip.y + h * 0.02))
            tail.addQuadCurve(to: CGPoint(x: base.x, y: base.y + h * 0.02), control: CGPoint(x: base.x + back * h * 0.06, y: base.y + h * 0.1))
            tail.closeSubpath()
            tc.fill(tail, with: .color(hair))
            for k in 0..<3 {
                var strand = Path()
                strand.move(to: CGPoint(x: base.x + back * h * 0.02, y: base.y + Double(k) * h * 0.01))
                strand.addQuadCurve(to: CGPoint(x: tip.x + back * h * (Double(k) - 1) * 0.012, y: tip.y - h * 0.02), control: CGPoint(x: base.x + back * h * 0.11, y: base.y + h * 0.06))
                tc.stroke(strand, with: .color(.white.opacity(0.18)), lineWidth: max(0.5, h * 0.003))
            }
        case .gator:
            // A long, heavy alligator tail down to the floor, with a row of ridges along the top.
            let start = CGPoint(x: base.x, y: base.y - h * 0.04)
            let tip = CGPoint(x: base.x + back * h * 0.34 * grow, y: min(pose.foot[0].y, pose.foot[1].y) - h * 0.01)
            let ctrl = CGPoint(x: base.x + back * h * 0.24 * grow, y: base.y - h * 0.01)
            var tail = Path()
            tail.move(to: start)
            tail.addQuadCurve(to: tip, control: ctrl)
            tail.addQuadCurve(to: CGPoint(x: base.x, y: base.y + h * 0.045), control: CGPoint(x: base.x + back * h * 0.12 * grow, y: base.y + h * 0.08))
            tail.closeSubpath()
            tc.fill(tail, with: .color(fur))
            tc.stroke(tail, with: .color(dark.opacity(0.5)), lineWidth: max(0.6, h * 0.004))
            for k in 1...6 {
                let u = Double(k) / 7.5
                let pt = lerp(lerp(start, ctrl, u), lerp(ctrl, tip, u), u)
                let s = h * 0.016 * (1 - u * 0.6)
                tc.fill(polyline([CGPoint(x: pt.x - s, y: pt.y + s * 0.3), CGPoint(x: pt.x - back * s * 0.2, y: pt.y - s * 1.3), CGPoint(x: pt.x + s, y: pt.y + s * 0.3)]),
                        with: .color(dark))
            }
        case .serpent:
            // A long snake tail tapering away along the floor behind her.
            let floor = min(pose.foot[0].y, pose.foot[1].y) - h * 0.012
            let p1 = CGPoint(x: base.x + back * h * 0.1 * grow, y: base.y + h * 0.1)
            let p2 = CGPoint(x: base.x + back * h * 0.04 * grow, y: floor)
            let end = CGPoint(x: base.x + back * h * 0.42 * grow, y: floor - h * 0.02 + swish)
            func point(_ u: Double) -> CGPoint {
                let v = 1 - u
                return CGPoint(x: v * v * v * base.x + 3 * v * v * u * p1.x + 3 * v * u * u * p2.x + u * u * u * end.x,
                               y: v * v * v * base.y + 3 * v * v * u * p1.y + 3 * v * u * u * p2.y + u * u * u * end.y)
            }
            for k in 0..<24 {
                let u0 = Double(k) / 24, u1 = Double(k + 1) / 24
                tc.stroke(polyline([point(u0), point(u1)]), with: .color(fur), style: limbStyle(h * mix(0.04, 0.006, u0)))
                if k % 3 == 1 { tc.fill(circle(point(u0), h * mix(0.011, 0.003, u0)), with: .color(dark)) }
            }
        case .none:
            break
        }
    }

    // Legs
    let legs = layer(lv.legs)
    for i in 0..<2 {
        let side = i == 0 ? -1.0 : 1.0
        let leg = polyline([pose.hip[i], pose.knee[i], pose.foot[i]])
        ctx.stroke(leg, with: .color(skinBody), style: limbStyle(pose.legW))
        if p.bikini {
            // A bikini leaves the whole leg bare.
        } else if p.shorts {
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
        // Thick furry (or leathery) legs.
        let ankle = lerp(pose.knee[i], f, 0.85)
        let lw = pose.legW * mix(1.15, 1.2 * max(1, kind.bulk * 0.95), lv.legs)
        let pts = [pose.hip[i], pose.knee[i], ankle]
        legs.stroke(polyline(pts), with: .color(fur), style: limbStyle(lw))
        switch kind.pattern {
        case .tigerStripes: limbStripes(legs, pts, width: lw, count: 4)
        case .zebraStripes: limbStripes(legs, pts, width: lw, count: 6)
        case .armorBands:
            for k in 0..<4 { limbStripes(legs, [lerp(pose.knee[i], ankle, 0.1 * Double(k)), pose.knee[i], ankle], width: lw * 0.9, count: 1) }
        case .wrinkles:
            for c in [pose.knee[i], lerp(pose.knee[i], ankle, 0.6)] {
                for k in 0..<2 {
                    var w = Path()
                    let y = c.y + Double(k) * lw * 0.25
                    w.move(to: CGPoint(x: c.x - lw * 0.35, y: y))
                    w.addQuadCurve(to: CGPoint(x: c.x + lw * 0.35, y: y), control: CGPoint(x: c.x, y: y + lw * 0.15))
                    legs.stroke(w, with: .color(dark.opacity(0.55)), lineWidth: max(0.5, h * 0.003))
                }
            }
        case .shaggy:
            for k in 0..<6 {
                let pt = lerp(pose.hip[i], ankle, 0.1 + Double(k) * 0.15)
                legs.stroke(polyline([CGPoint(x: pt.x + side * lw * 0.45, y: pt.y), CGPoint(x: pt.x + side * lw * 0.7, y: pt.y + lw * 0.25)]),
                            with: .color(fur), style: limbStyle(max(0.8, h * 0.006)))
            }
        case .scales: limbStripes(legs, pts, width: lw, count: 5)
        case .diamonds: limbStripes(legs, pts, width: lw, count: 4)
        case .plain:
            break
        }
        // Feet
        let toe = facing * h * 0.02
        switch kind.feet {
        case .hands:
            legs.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.055 + toe, y: f.y - h * 0.03, width: h * 0.11, height: h * 0.05)), with: .color(dark))
        case .paws:
            let r = CGRect(x: f.x - h * 0.045 + toe, y: f.y - h * 0.035, width: h * 0.09, height: h * 0.05)
            legs.fill(Path(ellipseIn: r), with: .color(fur))
            for k in 1...2 {
                let x = r.minX + r.width * Double(k) / 3
                legs.stroke(polyline([CGPoint(x: x, y: r.midY), CGPoint(x: x, y: r.maxY)]), with: .color(dark.opacity(0.6)), lineWidth: max(0.5, h * 0.003))
            }
        case .trotters, .hooves:
            let wide = kind.feet == .hooves ? 0.07 : 0.05
            let r = CGRect(x: f.x - h * wide / 2 + toe * 0.5, y: f.y - h * 0.035, width: h * wide, height: h * 0.045)
            legs.fill(Path(roundedRect: r, cornerRadius: h * 0.01), with: .color(dark))
            if kind.feet == .trotters {
                legs.stroke(polyline([CGPoint(x: r.midX, y: r.minY + r.height * 0.3), CGPoint(x: r.midX, y: r.maxY)]), with: .color(.black.opacity(0.5)), lineWidth: max(0.5, h * 0.003))
            }
        case .pads:
            let r = CGRect(x: f.x - h * 0.055, y: f.y - h * 0.04, width: h * 0.11, height: h * 0.055)
            legs.fill(Path(ellipseIn: r), with: .color(fur))
            for k in -1...1 {
                legs.fill(Path(ellipseIn: CGRect(x: r.midX + Double(k) * h * 0.028 - h * 0.011, y: r.maxY - h * 0.02, width: h * 0.022, height: h * 0.014)),
                          with: .color(kind == .elephant ? Color(white: 0.92) : light))
            }
        case .claws:
            legs.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.04 + toe, y: f.y - h * 0.032, width: h * 0.08, height: h * 0.045)), with: .color(fur))
            for c in [-1.0, 0, 1.0] {
                let b = CGPoint(x: f.x + c * h * 0.018 + toe, y: f.y)
                legs.fill(polyline([CGPoint(x: b.x - h * 0.007, y: b.y - h * 0.008), CGPoint(x: b.x + facing * h * 0.012, y: b.y + h * 0.014),
                                    CGPoint(x: b.x + h * 0.007, y: b.y - h * 0.008)]), with: .color(dark))
            }
        case .scaly:
            let r = CGRect(x: f.x - h * 0.042 + toe, y: f.y - h * 0.032, width: h * 0.084, height: h * 0.042)
            legs.fill(Path(ellipseIn: r), with: .color(fur))
            legs.stroke(Path(ellipseIn: r), with: .color(dark.opacity(0.6)), lineWidth: max(0.5, h * 0.003))
        }
    }

    // Neck and torso
    fill(ctx, pose.neck, skinHead)
    if p.bikini {
        // Bare midriff, a two-piece top and matching bottoms.
        ctx.fill(Path(roundedRect: t, cornerRadius: pose.w * 0.3), with: .color(skinBody))
        let suit = p.shirt.color
        let cupY = t.minY + t.height * 0.3
        for side in [-1.0, 1.0] {
            let cx = t.midX + side * t.width * 0.22
            ctx.fill(polyline([CGPoint(x: cx - t.width * 0.2, y: cupY + t.height * 0.12), CGPoint(x: cx, y: cupY - t.height * 0.12),
                               CGPoint(x: cx + t.width * 0.2, y: cupY + t.height * 0.12)]), with: .color(suit))
            ctx.stroke(polyline([CGPoint(x: cx, y: cupY - t.height * 0.12), CGPoint(x: cx + side * t.width * 0.08, y: t.minY)]),
                       with: .color(suit), lineWidth: max(0.8, h * 0.006))
        }
        fill(ctx, CGRect(x: t.minX + t.width * 0.02, y: cupY + t.height * 0.1, width: t.width * 0.96, height: h * 0.012), suit)
        var bottoms = Path()
        bottoms.addLines([CGPoint(x: t.minX, y: t.maxY - h * 0.05), CGPoint(x: t.maxX, y: t.maxY - h * 0.05),
                          CGPoint(x: t.midX + t.width * 0.15, y: t.maxY + h * 0.035), CGPoint(x: t.midX - t.width * 0.15, y: t.maxY + h * 0.035)])
        bottoms.closeSubpath()
        ctx.fill(bottoms, with: .color(suit))
    } else {
        ctx.fill(Path(roundedRect: t, cornerRadius: pose.w * 0.3), with: .color(p.shirt.color))
        var collar = Path()
        collar.addArc(center: CGPoint(x: t.midX, y: t.minY), radius: pose.w * 0.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
        ctx.fill(collar, with: .color(skinBody))
        fill(ctx, CGRect(x: t.minX, y: t.maxY - h * 0.05, width: t.width, height: h * 0.06), p.pants.color, corner: 3)
    }

    // Fur (or hide, or armor) grows over her clothes, and her body fills out.
    let body = layer(lv.body)
    if lv.body > 0 {
        let bw = t.width * mix(1.05, kind.bulk, lv.body)
        let belly = max(0, kind.bulk - 1.2) * h * 0.1 * lv.body
        let r = CGRect(x: t.midX - bw / 2, y: t.minY - h * 0.01, width: bw, height: t.height + h * 0.03 * lv.body + belly)
        let path = Path(roundedRect: r, cornerRadius: bw * (kind.bulk > 1.35 ? 0.46 : 0.36))
        body.fill(path, with: .color(fur))
        var printed = body
        printed.clip(to: path)
        if kind.belly {
            printed.fill(Path(ellipseIn: CGRect(x: r.midX - r.width * 0.3, y: r.minY + r.height * 0.2, width: r.width * 0.6, height: r.height * 0.85)), with: .color(light))
        }
        switch kind.pattern {
        case .tigerStripes:
            for side in [-1.0, 1.0] {
                for k in 0..<4 {
                    let y = r.minY + r.height * (0.15 + Double(k) * 0.2)
                    let edge = side < 0 ? r.minX : r.maxX
                    var s = Path()
                    s.move(to: CGPoint(x: edge, y: y - r.height * 0.04))
                    s.addQuadCurve(to: CGPoint(x: edge - side * r.width * 0.32, y: y + r.height * 0.05), control: CGPoint(x: edge - side * r.width * 0.15, y: y - r.height * 0.02))
                    s.addQuadCurve(to: CGPoint(x: edge, y: y + r.height * 0.04), control: CGPoint(x: edge - side * r.width * 0.12, y: y + r.height * 0.06))
                    s.closeSubpath()
                    printed.fill(s, with: .color(dark))
                }
            }
        case .zebraStripes:
            for k in 0..<7 {
                let y = r.minY + r.height * (0.06 + Double(k) * 0.14)
                var s = Path()
                s.move(to: CGPoint(x: r.minX, y: y))
                s.addQuadCurve(to: CGPoint(x: r.maxX, y: y), control: CGPoint(x: r.midX, y: y + r.height * 0.1))
                printed.stroke(s, with: .color(dark), lineWidth: r.height * 0.055)
            }
        case .armorBands:
            // The armadillo's banded shell: a darker shield with rows of little scales.
            printed.fill(Path(r), with: .color(kind.fur.mixed(with: kind.dark, 0.25).color))
            for k in 0..<7 {
                let y = r.minY + r.height * (0.12 + Double(k) * 0.12)
                var s = Path()
                s.move(to: CGPoint(x: r.minX, y: y))
                s.addQuadCurve(to: CGPoint(x: r.maxX, y: y), control: CGPoint(x: r.midX, y: y + r.height * 0.06))
                printed.stroke(s, with: .color(dark), lineWidth: max(0.7, h * 0.005))
                for j in 0..<6 {
                    let x = r.minX + r.width * (0.1 + Double(j) * 0.16)
                    printed.fill(circle(CGPoint(x: x, y: y + r.height * 0.05), max(0.6, h * 0.004)), with: .color(kind.light.color.opacity(0.7)))
                }
            }
        case .wrinkles:
            for (dx, dy) in [(-0.3, 0.3), (0.3, 0.32), (-0.25, 0.62), (0.28, 0.6), (0.0, 0.85)] {
                let c = CGPoint(x: r.midX + dx * r.width, y: r.minY + dy * r.height)
                var w = Path()
                w.move(to: CGPoint(x: c.x - r.width * 0.12, y: c.y))
                w.addQuadCurve(to: CGPoint(x: c.x + r.width * 0.12, y: c.y), control: CGPoint(x: c.x, y: c.y + r.height * 0.05))
                printed.stroke(w, with: .color(dark.opacity(0.5)), lineWidth: max(0.5, h * 0.004))
            }
        case .shaggy:
            for k in 0..<24 {
                let u = Double(k)
                let pt = CGPoint(x: r.minX + r.width * (0.05 + (u * 0.37).truncatingRemainder(dividingBy: 0.9)),
                                 y: r.minY + r.height * (0.05 + (u * 0.29).truncatingRemainder(dividingBy: 0.9)))
                printed.stroke(polyline([pt, CGPoint(x: pt.x + sin(u) * h * 0.008, y: pt.y + h * 0.016)]), with: .color(.white.opacity(0.18)), lineWidth: max(0.5, h * 0.004))
            }
        case .scales:
            // Rows of square alligator scales over the whole body.
            for row in 0..<8 {
                for col in 0..<5 {
                    let cell = CGRect(x: r.minX + r.width * Double(col) / 5 + (row % 2 == 0 ? 0 : r.width * 0.1), y: r.minY + r.height * Double(row) / 8,
                                      width: r.width / 5, height: r.height / 8).insetBy(dx: r.width * 0.012, dy: r.height * 0.008)
                    printed.stroke(Path(roundedRect: cell, cornerRadius: cell.height * 0.3), with: .color(dark.opacity(0.45)), lineWidth: max(0.5, h * 0.003))
                }
            }
        case .diamonds:
            // A python's chain of dark diamonds, with blotches down the sides.
            for k in 0..<5 {
                let c = CGPoint(x: r.midX, y: r.minY + r.height * (0.1 + Double(k) * 0.2))
                let dw = r.width * 0.2, dh = r.height * 0.09
                let diamond = polyline([CGPoint(x: c.x, y: c.y - dh), CGPoint(x: c.x + dw, y: c.y), CGPoint(x: c.x, y: c.y + dh), CGPoint(x: c.x - dw, y: c.y)])
                printed.fill(diamond, with: .color(dark))
                printed.fill(polyline([CGPoint(x: c.x, y: c.y - dh * 0.45), CGPoint(x: c.x + dw * 0.45, y: c.y), CGPoint(x: c.x, y: c.y + dh * 0.45), CGPoint(x: c.x - dw * 0.45, y: c.y)]),
                             with: .color(kind.fur.color))
                for side in [-1.0, 1.0] {
                    printed.fill(Path(ellipseIn: CGRect(x: (side < 0 ? r.minX : r.maxX) - r.width * 0.1, y: c.y + r.height * 0.04, width: r.width * 0.2, height: r.height * 0.08)),
                                 with: .color(dark))
                }
            }
        case .plain:
            break
        }
        printed.fill(Path(ellipseIn: CGRect(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.06, width: r.width * 0.22, height: r.height * 0.14)), with: .color(.white.opacity(0.15)))
        body.stroke(path, with: .color(dark.opacity(0.45)), lineWidth: max(0.6, h * 0.005))
    }

    // Arms
    for i in 0..<2 {
        let arm = polyline([pose.shoulder[i], pose.elbow[i], pose.hand[i]])
        ctx.stroke(arm, with: .color(skinBody), style: limbStyle(pose.armW))
        if !p.bikini {
            let sleeve = polyline([pose.shoulder[i], lerp(pose.shoulder[i], pose.elbow[i], 0.5)])
            ctx.stroke(sleeve, with: .color(p.shirt.color), style: StrokeStyle(lineWidth: pose.armW * 1.35, lineCap: .round))
        }
        let hd = pose.hand[i]
        if lv.body > 0 {
            // Thick furry arms — a gorilla's are huge.
            let wrist = lerp(pose.elbow[i], hd, 0.82)
            let aw = pose.armW * mix(1.3, kind == .gorilla ? 2.0 : 1.55, lv.body)
            let pts = [pose.shoulder[i], pose.elbow[i], wrist]
            body.stroke(polyline(pts), with: .color(fur), style: limbStyle(aw))
            switch kind.pattern {
            case .tigerStripes: limbStripes(body, pts, width: aw, count: 3)
            case .zebraStripes: limbStripes(body, pts, width: aw, count: 5)
            case .armorBands: limbStripes(body, pts, width: aw * 0.9, count: 3)
            case .scales: limbStripes(body, pts, width: aw, count: 4)
            case .diamonds: limbStripes(body, pts, width: aw, count: 3)
            default: break
            }
        }
        let handR = pose.armW * mix(0.62, kind.feet == .hands ? 1.0 : kind.feet == .pads ? 0.85 : 0.72, lv.body)
        ctx.fill(circle(hd, handR), with: .color(skinHands))
        if lv.body > 0.5 {
            let det = layer((lv.body - 0.5) * 2)
            switch kind.feet {
            case .hands, .paws:
                for k in -1...1 {
                    let x = hd.x + Double(k) * handR * 0.42
                    det.stroke(polyline([CGPoint(x: x, y: hd.y + handR * 0.2), CGPoint(x: x, y: hd.y + handR * 0.9)]),
                               with: .color((kind.feet == .hands ? Color.white.opacity(0.25) : dark.opacity(0.6))), lineWidth: max(0.5, h * 0.003))
                }
            case .trotters, .hooves:
                det.stroke(polyline([CGPoint(x: hd.x, y: hd.y), CGPoint(x: hd.x, y: hd.y + handR)]), with: .color(.black.opacity(0.5)), lineWidth: max(0.5, h * 0.004))
            case .pads:
                for k in -1...1 {
                    det.fill(Path(ellipseIn: CGRect(x: hd.x + Double(k) * handR * 0.5 - handR * 0.18, y: hd.y + handR * 0.55, width: handR * 0.36, height: handR * 0.3)),
                             with: .color(kind == .elephant ? Color(white: 0.92) : light))
                }
            case .claws:
                for k in -1...1 {
                    let ang = (90.0 + Double(k) * 30) * .pi / 180
                    let b = CGPoint(x: hd.x + cos(ang) * handR * 0.6, y: hd.y + sin(ang) * handR * 0.6)
                    let tip = CGPoint(x: hd.x + cos(ang) * handR * 1.9, y: hd.y + sin(ang) * handR * 1.9)
                    det.fill(polyline([CGPoint(x: b.x - handR * 0.22, y: b.y), tip, CGPoint(x: b.x + handR * 0.22, y: b.y)]), with: .color(dark))
                }
            case .scaly:
                det.stroke(circle(hd, handR), with: .color(dark.opacity(0.6)), lineWidth: max(0.5, h * 0.003))
            }
        }
    }
    switch p.load {
    case .suitcase where !still:
        drawSuitcase(ctx, hand: pose.hand[1], size: h * 0.3)
    case let load? where !still:
        let at = CGPoint(x: t.midX, y: t.minY + t.height * 0.62)
        switch load {
        case .groceries: drawGroceryBag(ctx, center: at, size: pose.w * 1.2)
        case .shopping: drawShoppingBag(ctx, center: at, size: pose.w * 1.2)
        default: drawBox(ctx, center: at, size: pose.w * 1.25)
        }
    default:
        break
    }

    // Her own hair behind the head
    switch p.style {
    case .ponytail:
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
    case .long, .waist, .short, .curly, .bob:
        break
    }

    let sc = shape.center
    let headH = shape.bottom - shape.top
    if a > 0 {
        // A lion's big shaggy mane, all the way round her face.
        if kind == .lion {
            for ring in 0..<2 {
                for k in 0..<18 {
                    let ang = (Double(k) + Double(ring) * 0.5) / 18 * 2 * .pi
                    let rr = ring == 0 ? 1.0 : 0.82
                    let c = CGPoint(x: sc.x + cos(ang) * shape.width * 1.32 * rr, y: sc.y + hr * 0.15 + sin(ang) * headH * 0.62 * rr)
                    ctx.fill(circle(c, hr * (ring == 0 ? 0.5 : 0.45) * a), with: .color(ring == 0 ? dark : kind.dark.mixed(with: kind.fur, 0.45).color))
                }
            }
        }
        // Ears
        for side in [-1.0, 1.0] {
            switch kind.ears {
            case .small:
                let c = CGPoint(x: sc.x + side * shape.width * 0.98, y: sc.y - hr * 0.05)
                ctx.fill(circle(c, hr * 0.22 * a), with: .color(skinHead))
                ctx.fill(circle(c, hr * 0.11 * a), with: .color(dark))
            case .round, .tiny:
                let tiny = kind.ears == .tiny
                let c = CGPoint(x: sc.x + side * shape.width * (tiny ? 0.62 : 0.75), y: shape.top + hr * (tiny ? 0.08 : 0.15))
                let r = hr * (tiny ? 0.17 : 0.33) * a
                ctx.fill(circle(c, r), with: .color(fur))
                ctx.stroke(circle(c, r), with: .color(dark.opacity(0.5)), lineWidth: max(0.5, hr * 0.04))
                ctx.fill(circle(CGPoint(x: c.x, y: c.y + r * 0.1), r * 0.55), with: .color(kind == .tiger ? Color.white : light))
            case .pig:
                var ear = Path()
                ear.move(to: CGPoint(x: sc.x + side * shape.width * 0.4, y: shape.top + hr * 0.12))
                ear.addLine(to: CGPoint(x: sc.x + side * shape.width * 1.05, y: shape.top - hr * 0.3 * a))
                ear.addQuadCurve(to: CGPoint(x: sc.x + side * shape.width * 0.95, y: shape.top + hr * 0.45), control: CGPoint(x: sc.x + side * shape.width * 1.15, y: shape.top + hr * 0.2))
                ear.closeSubpath()
                ctx.fill(ear, with: .color(fur))
                ctx.stroke(ear, with: .color(dark.opacity(0.6)), lineWidth: max(0.5, hr * 0.04))
            case .pointy, .tall, .armadillo:
                let len = kind.ears == .tall ? 1.15 : kind.ears == .armadillo ? 0.4 : 0.62
                let base = CGPoint(x: sc.x + side * shape.width * 0.55, y: shape.top + hr * 0.2)
                let tip = CGPoint(x: sc.x + side * shape.width * 0.9, y: shape.top - hr * len * a)
                let wd = hr * (kind.ears == .tall ? 0.3 : 0.24)
                var ear = Path()
                ear.move(to: CGPoint(x: base.x - wd, y: base.y))
                ear.addQuadCurve(to: tip, control: CGPoint(x: base.x - wd * 1.2, y: (base.y + tip.y) / 2))
                ear.addQuadCurve(to: CGPoint(x: base.x + wd, y: base.y), control: CGPoint(x: base.x + wd * 1.4, y: (base.y + tip.y) / 2))
                ear.closeSubpath()
                ctx.fill(ear, with: .color(fur))
                ctx.stroke(ear, with: .color(dark.opacity(0.6)), lineWidth: max(0.5, hr * 0.04))
                var inner = ctx
                inner.clip(to: ear)
                inner.fill(Path(ellipseIn: CGRect(x: base.x - wd * 0.5, y: tip.y + hr * 0.15 * a, width: wd, height: base.y - tip.y)), with: .color(kind == .zebra ? Color.white : light))
                if kind == .zebra { inner.fill(Path(ellipseIn: CGRect(x: tip.x - wd, y: tip.y - wd * 0.3, width: wd * 2, height: wd * 1.2)), with: .color(dark)) }
            case .elephant:
                let c = CGPoint(x: sc.x + side * shape.width * 1.22, y: sc.y - hr * 0.02)
                let r = CGRect(x: c.x - hr * 0.78 * a, y: c.y - hr * 0.95 * a, width: hr * 1.56 * a, height: hr * 1.9 * a)
                ctx.fill(Path(ellipseIn: r), with: .color(fur))
                ctx.stroke(Path(ellipseIn: r), with: .color(dark), lineWidth: max(0.6, hr * 0.05))
                ctx.fill(Path(ellipseIn: r.insetBy(dx: r.width * 0.2, dy: r.height * 0.18).offsetBy(dx: side * r.width * 0.05, dy: 0)), with: .color(light))
            case .none:
                break
            }
        }
        // A horse's long mane falls down the side of her neck, behind her head.
        if kind == .horse, let mane = kind.mane {
            let top = shape.top + hr * 0.1
            fill(ctx, CGRect(x: sc.x + back * shape.width * 0.55 - hr * 0.32, y: top, width: hr * 0.64, height: (t.minY + h * 0.08 - top) * a + hr * 0.3),
                 mane.color, corner: hr * 0.3)
        }
        // A gorilla's high crest on top of the head.
        if kind == .gorilla {
            ctx.fill(Path(ellipseIn: CGRect(x: sc.x - hr * 0.55, y: shape.top - hr * 0.18 * a, width: hr * 1.1, height: hr * 0.6)), with: .color(skinHead))
        }
    }

    // Her own small ears, which disappear into the new ones.
    for side in [-1.0, 1.0] {
        var ears = ctx
        ears.opacity = 1 - a
        ears.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 0.95 - hr * 0.16, y: head.y - hr * 0.05, width: hr * 0.32, height: hr * 0.42)),
                  with: .color(skinHead))
    }

    ctx.fill(shape.path, with: .color(skinHead))
    if a > 0 {
        ctx.stroke(shape.path, with: .color(dark.opacity(0.5 * a)), lineWidth: max(0.6, hr * 0.045))
        var face = ctx
        face.clip(to: shape.path)
        face.opacity = a
        switch kind.pattern {
        case .tigerStripes:
            for dx in [-0.18, 0.0, 0.18] {
                face.stroke(polyline([CGPoint(x: sc.x + dx * hr, y: shape.top), CGPoint(x: sc.x + dx * hr * 0.7, y: shape.top + hr * 0.45)]), with: .color(dark), lineWidth: hr * 0.1)
            }
            for side in [-1.0, 1.0] {
                for k in 0..<2 {
                    let y = sc.y + hr * (0.1 + Double(k) * 0.22)
                    face.stroke(polyline([CGPoint(x: sc.x + side * shape.width, y: y), CGPoint(x: sc.x + side * shape.width * 0.62, y: y + hr * 0.08)]), with: .color(dark), lineWidth: hr * 0.09)
                }
            }
        case .zebraStripes:
            for k in 0..<5 {
                let y = shape.top + headH * (0.08 + Double(k) * 0.11)
                var s = Path()
                s.move(to: CGPoint(x: sc.x - shape.width, y: y + hr * 0.1))
                s.addQuadCurve(to: CGPoint(x: sc.x + shape.width, y: y + hr * 0.1), control: CGPoint(x: sc.x, y: y - hr * 0.12))
                face.stroke(s, with: .color(dark), lineWidth: hr * 0.12)
            }
        case .armorBands:
            face.fill(Path(CGRect(x: sc.x - shape.width, y: shape.top, width: shape.width * 2, height: headH * 0.32)), with: .color(kind.fur.mixed(with: kind.dark, 0.3).color))
            for k in 1...2 {
                let y = shape.top + headH * 0.11 * Double(k)
                face.stroke(polyline([CGPoint(x: sc.x - shape.width, y: y), CGPoint(x: sc.x + shape.width, y: y)]), with: .color(dark), lineWidth: max(0.5, hr * 0.04))
            }
        case .wrinkles:
            for k in 0..<3 {
                var w = Path()
                let y = shape.top + hr * (0.3 + Double(k) * 0.13)
                w.move(to: CGPoint(x: sc.x - hr * 0.35, y: y))
                w.addQuadCurve(to: CGPoint(x: sc.x + hr * 0.35, y: y), control: CGPoint(x: sc.x, y: y - hr * 0.08))
                face.stroke(w, with: .color(dark.opacity(0.5)), lineWidth: max(0.5, hr * 0.035))
            }
        case .scales:
            // Bumpy scales across the top of the head.
            for row in 0..<3 {
                for k in -2...2 {
                    let c = CGPoint(x: sc.x + Double(k) * hr * 0.3 + (row % 2 == 0 ? 0 : hr * 0.15), y: shape.top + hr * (0.18 + Double(row) * 0.22))
                    face.stroke(circle(c, hr * 0.1), with: .color(dark.opacity(0.55)), lineWidth: max(0.5, hr * 0.03))
                }
            }
        case .diamonds:
            let c = CGPoint(x: sc.x, y: shape.top + hr * 0.38)
            face.fill(polyline([CGPoint(x: c.x, y: c.y - hr * 0.26), CGPoint(x: c.x + hr * 0.36, y: c.y), CGPoint(x: c.x, y: c.y + hr * 0.26), CGPoint(x: c.x - hr * 0.36, y: c.y)]),
                      with: .color(dark))
            face.fill(polyline([CGPoint(x: c.x, y: c.y - hr * 0.11), CGPoint(x: c.x + hr * 0.15, y: c.y), CGPoint(x: c.x, y: c.y + hr * 0.11), CGPoint(x: c.x - hr * 0.15, y: c.y)]),
                      with: .color(fur))
        case .shaggy, .plain:
            break
        }
        face.fill(Path(ellipseIn: CGRect(x: sc.x - shape.width * 0.5, y: shape.top + hr * 0.12, width: shape.width * 0.4, height: hr * 0.2)), with: .color(.white.opacity(0.18)))
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
            let top = head.y - hr * 0.3
            let length = p.style == .waist ? t.maxY - h * 0.06 - top : hr * (p.style == .long ? 2.1 : 1.2)
            for side in [-1.0, 1.0] {
                fill(hairCtx, CGRect(x: head.x + side * hr * 0.98 - hr * 0.2, y: top, width: hr * 0.4, height: length),
                     hairColor, corner: hr * 0.2)
            }
        }
    }
    // A zebra's short black-and-white mane standing up along the top of her head.
    if a > 0 && kind == .zebra {
        let mane = CGRect(x: sc.x - hr * 0.16, y: shape.top - hr * 0.32 * a, width: hr * 0.32, height: hr * 0.62)
        ctx.fill(Path(roundedRect: mane, cornerRadius: hr * 0.12), with: .color(dark))
        for k in 0..<3 {
            fill(ctx, CGRect(x: mane.minX + hr * 0.04, y: mane.minY + mane.height * (0.2 + Double(k) * 0.25), width: mane.width - hr * 0.08, height: mane.height * 0.1), .white)
        }
    }
    // A horse's forelock tumbles over her forehead; a donkey's short mane stands straight up.
    if a > 0, let mane = kind.mane, kind != .zebra {
        if kind == .horse {
            var lock = Path()
            lock.move(to: CGPoint(x: sc.x - hr * 0.3, y: shape.top + hr * 0.05))
            lock.addQuadCurve(to: CGPoint(x: sc.x + facing * hr * 0.1, y: shape.top + hr * 0.62 * a), control: CGPoint(x: sc.x - hr * 0.3, y: shape.top + hr * 0.4))
            lock.addQuadCurve(to: CGPoint(x: sc.x + hr * 0.3, y: shape.top + hr * 0.05), control: CGPoint(x: sc.x + hr * 0.3, y: shape.top + hr * 0.4))
            lock.addQuadCurve(to: CGPoint(x: sc.x - hr * 0.3, y: shape.top + hr * 0.05), control: CGPoint(x: sc.x, y: shape.top - hr * 0.25 * a))
            lock.closeSubpath()
            ctx.fill(lock, with: .color(mane.color))
        } else {
            let tuft = CGRect(x: sc.x - hr * 0.14, y: shape.top - hr * 0.28 * a, width: hr * 0.28, height: hr * 0.5)
            ctx.fill(Path(roundedRect: tuft, cornerRadius: hr * 0.1), with: .color(mane.color))
        }
    }
    // A peaked cap: black, with a shiny visor and a gold badge.
    if p.driverCap {
        let black = Color(white: 0.1)
        fill(hairCtx, CGRect(x: head.x - hr * 0.95, y: head.y - hr * 1.45, width: hr * 1.9, height: hr * 0.62), black, corner: hr * 0.25)
        fill(hairCtx, CGRect(x: head.x - hr * 0.98, y: head.y - hr * 0.95, width: hr * 1.96, height: hr * 0.16), Color(white: 0.25))
        hairCtx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.8 + facing * hr * 0.25, y: head.y - hr * 0.9, width: hr * 1.6, height: hr * 0.32)), with: .color(Color(white: 0.05)))
        hairCtx.fill(circle(CGPoint(x: head.x, y: head.y - hr * 1.15), hr * 0.13), with: .color(Color(red: 0.95, green: 0.78, blue: 0.25)))
    }

    // Face
    let look = facing * hr * 0.15 * (1 - a * 0.6)
    let shocked = p.mood == .shocked && !still
    let beaming = p.mood == .beaming && !still
    let eyeY = head.y + hr * mix(0.1, 0, a)
    // Her own eyes, which the animal eyes take over.
    var human = ctx
    human.opacity = 1 - a
    for side in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + side * hr * 0.35 + look, y: eyeY)
        let ew = hr * 0.2, eh = hr * 0.24
        let r = CGRect(x: e.x - ew / 2, y: e.y - eh / 2, width: ew, height: eh)
        if beaming {
            var lid = Path()
            lid.move(to: CGPoint(x: r.minX, y: e.y + eh * 0.2))
            lid.addQuadCurve(to: CGPoint(x: r.maxX, y: e.y + eh * 0.2), control: CGPoint(x: e.x, y: e.y - eh * 0.8))
            human.stroke(lid, with: .color(.black), style: StrokeStyle(lineWidth: max(1, hr * 0.08), lineCap: .round))
            continue
        }
        if shocked {
            human.fill(Path(ellipseIn: r.insetBy(dx: -hr * 0.06, dy: -hr * 0.06)), with: .color(.white))
            human.stroke(Path(ellipseIn: r.insetBy(dx: -hr * 0.06, dy: -hr * 0.06)), with: .color(.black), lineWidth: max(0.8, hr * 0.05))
        }
        human.fill(Path(ellipseIn: r), with: .color(.black))
    }
    for dx in [-0.75, 0.45] {
        human.fill(Path(ellipseIn: CGRect(x: head.x + hr * dx + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)),
                   with: .color(.pink.opacity(0.45)))
    }

    // Animal eyes
    if a > 0 {
        let ey = sc.y - hr * (kind.head == .long ? 0.32 : 0.16)
        for side in [-1.0, 1.0] {
            let e = CGPoint(x: sc.x + side * shape.width * 0.42 + look * 0.4, y: ey)
            let r = hr * 0.17 * a
            if beaming {
                var lid = Path()
                lid.move(to: CGPoint(x: e.x - r, y: e.y + r * 0.3))
                lid.addQuadCurve(to: CGPoint(x: e.x + r, y: e.y + r * 0.3), control: CGPoint(x: e.x, y: e.y - r * 1.3))
                ctx.stroke(lid, with: .color(.black), style: StrokeStyle(lineWidth: max(1, hr * 0.08), lineCap: .round))
                continue
            }
            let er = shocked ? r * 1.25 : r
            ctx.fill(circle(e, er), with: .color(.white))
            ctx.fill(circle(CGPoint(x: e.x + look * 0.3, y: e.y), er * 0.68), with: .color(kind.eye.color))
            if kind.slitEyes {
                ctx.fill(Path(ellipseIn: CGRect(x: e.x + look * 0.3 - er * 0.14, y: e.y - er * 0.55, width: er * 0.28, height: er * 1.1)), with: .color(.black))
            } else {
                ctx.fill(circle(CGPoint(x: e.x + look * 0.3, y: e.y), er * 0.36), with: .color(.black))
            }
            ctx.fill(circle(CGPoint(x: e.x + look * 0.3 - er * 0.25, y: e.y - er * 0.3), er * 0.2), with: .color(.white.opacity(0.9)))
            ctx.stroke(circle(e, er), with: .color(dark.opacity(0.6)), lineWidth: max(0.5, hr * 0.03))
        }
        if kind == .gorilla {
            // A heavy brow ridge over deep-set eyes
            ctx.fill(Path(roundedRect: CGRect(x: sc.x - shape.width * 0.75, y: ey - hr * 0.3, width: shape.width * 1.5, height: hr * 0.17), cornerRadius: hr * 0.08),
                     with: .color(dark))
        }
    }

    // Snout: where the mouth ends up depends on the animal.
    let mx = head.x + look
    var animalMouthY = sc.y + hr * 0.6
    var animalMW = hr * 0.22
    switch kind.snout {
    case .ape: animalMouthY = sc.y + hr * 0.75; animalMW = hr * 0.3
    case .cat: animalMouthY = sc.y + hr * 0.62; animalMW = hr * 0.16
    case .pig: animalMouthY = sc.y + hr * 0.78; animalMW = hr * 0.24
    case .rhino: animalMouthY = sc.y + hr * 0.92; animalMW = hr * 0.34
    case .hippo: animalMouthY = sc.y + hr * 0.9; animalMW = hr * 0.5
    case .trunk: animalMouthY = sc.y + hr * 0.8; animalMW = hr * 0.24
    case .tube: animalMouthY = sc.y + hr * 0.62; animalMW = hr * 0.14
    case .pointy: animalMouthY = sc.y + hr * 0.62; animalMW = hr * 0.14
    case .horse: animalMouthY = sc.y + hr * 1.12; animalMW = hr * 0.26
    case .jaws: animalMouthY = sc.y + hr * 1.5; animalMW = hr * 0.42
    case .serpent: animalMouthY = sc.y + hr * 0.72; animalMW = hr * 0.5
    }
    if a > 0 {
        var sn = ctx
        sn.opacity = a
        switch kind.snout {
        case .ape:
            sn.fill(Path(ellipseIn: CGRect(x: sc.x - shape.width * 0.62, y: sc.y + hr * 0.05, width: shape.width * 1.24, height: hr * 0.95)), with: .color(light))
            for side in [-1.0, 1.0] {
                sn.fill(Path(ellipseIn: CGRect(x: mx + side * hr * 0.14 - hr * 0.08, y: sc.y + hr * 0.3, width: hr * 0.16, height: hr * 0.12)), with: .color(dark))
            }
        case .cat:
            for side in [-1.0, 1.0] {
                sn.fill(circle(CGPoint(x: mx + side * hr * 0.17, y: sc.y + hr * 0.45), hr * 0.24), with: .color(light))
            }
            var nose = Path()
            nose.move(to: CGPoint(x: mx - hr * 0.15, y: sc.y + hr * 0.22))
            nose.addLine(to: CGPoint(x: mx + hr * 0.15, y: sc.y + hr * 0.22))
            nose.addLine(to: CGPoint(x: mx, y: sc.y + hr * 0.38))
            nose.closeSubpath()
            sn.fill(nose, with: .color(kind == .lion ? Color(red: 0.35, green: 0.2, blue: 0.12) : Color(red: 0.95, green: 0.55, blue: 0.6)))
            for side in [-1.0, 1.0] {
                for k in -1...1 {
                    let y0 = sc.y + hr * (0.45 + Double(k) * 0.08)
                    sn.stroke(polyline([CGPoint(x: mx + side * hr * 0.3, y: y0), CGPoint(x: mx + side * hr * 0.8, y: y0 + Double(k) * hr * 0.1)]),
                              with: .color(.black.opacity(0.55)), lineWidth: max(0.4, hr * 0.02))
                }
            }
        case .pig:
            let disc = CGRect(x: mx - hr * 0.38, y: sc.y + hr * 0.12, width: hr * 0.76, height: hr * 0.52)
            sn.fill(Path(ellipseIn: disc), with: .color(kind.fur.mixed(with: kind.dark, 0.25).color))
            sn.stroke(Path(ellipseIn: disc), with: .color(dark), lineWidth: max(0.5, hr * 0.04))
            for side in [-1.0, 1.0] {
                sn.fill(Path(ellipseIn: CGRect(x: disc.midX + side * hr * 0.14 - hr * 0.06, y: disc.midY - hr * 0.1, width: hr * 0.12, height: hr * 0.2)), with: .color(Color(red: 0.55, green: 0.22, blue: 0.28)))
            }
        case .rhino, .hippo:
            let hippo = kind.snout == .hippo
            let muzzle = CGRect(x: sc.x - shape.width * (hippo ? 0.98 : 0.78), y: sc.y + hr * (hippo ? 0.12 : 0.25), width: shape.width * (hippo ? 1.96 : 1.56), height: hr * (hippo ? 1.0 : 0.85))
            sn.fill(Path(ellipseIn: muzzle), with: .color(light))
            sn.stroke(Path(ellipseIn: muzzle), with: .color(dark.opacity(0.5)), lineWidth: max(0.5, hr * 0.035))
            for side in [-1.0, 1.0] {
                let n = CGPoint(x: mx + side * hr * (hippo ? 0.32 : 0.2), y: muzzle.minY + hr * 0.22)
                if hippo { sn.fill(circle(n, hr * 0.14), with: .color(fur)) }
                sn.fill(Path(ellipseIn: CGRect(x: n.x - hr * 0.06, y: n.y - hr * 0.04, width: hr * 0.12, height: hr * 0.08)), with: .color(dark))
            }
            if !hippo {
                // Two horns: a smaller one up on the forehead behind, and a big one on the nose in front.
                let ivory = Color(red: 0.88, green: 0.84, blue: 0.74)
                for (baseY, tipY, wd) in [(sc.y - hr * 0.2, sc.y - hr * 0.9, 0.15), (sc.y + hr * 0.35, sc.y - hr * 0.5, 0.3)] {
                    var horn = Path()
                    horn.move(to: CGPoint(x: mx - hr * wd, y: baseY))
                    horn.addQuadCurve(to: CGPoint(x: mx + hr * 0.05, y: baseY + (tipY - baseY) * a), control: CGPoint(x: mx - hr * wd * 0.6, y: (baseY + tipY) / 2))
                    horn.addQuadCurve(to: CGPoint(x: mx + hr * wd, y: baseY), control: CGPoint(x: mx + hr * wd * 0.4, y: (baseY + tipY) / 2 + hr * 0.1))
                    horn.closeSubpath()
                    sn.fill(horn, with: .color(ivory))
                    sn.stroke(horn, with: .color(dark.opacity(0.5)), lineWidth: max(0.5, hr * 0.03))
                }
            }
        case .tube:
            // The aardvark's long snout grows straight out of her nose, getting longer as the change goes on.
            let nose = CGPoint(x: mx, y: sc.y + hr * 0.18)
            let tip = CGPoint(x: mx + facing * hr * 0.2 * a, y: nose.y + hr * 1.1 * a)
            let rw = hr * mix(0.1, 0.24, a), tw = hr * mix(0.08, 0.13, a)
            var tube = Path()
            tube.move(to: CGPoint(x: nose.x - rw, y: nose.y - hr * 0.08))
            tube.addQuadCurve(to: CGPoint(x: tip.x - tw, y: tip.y), control: CGPoint(x: mx - rw * 0.8, y: (nose.y + tip.y) / 2))
            tube.addLine(to: CGPoint(x: tip.x + tw, y: tip.y))
            tube.addQuadCurve(to: CGPoint(x: nose.x + rw, y: nose.y - hr * 0.08), control: CGPoint(x: mx + rw * 0.8, y: (nose.y + tip.y) / 2))
            tube.closeSubpath()
            ctx.fill(tube, with: .color(p.skin.mixed(with: kind.fur.mixed(with: kind.dark, 0.2), lv.head * 0.97).color))
            ctx.stroke(tube, with: .color(dark.opacity(0.5 * a)), lineWidth: max(0.5, hr * 0.03))
            let disc = CGRect(x: tip.x - tw * 1.15, y: tip.y - hr * 0.08, width: tw * 2.3, height: hr * 0.16)
            ctx.fill(Path(ellipseIn: disc), with: .color(light))
            for side in [-1.0, 1.0] { ctx.fill(circle(CGPoint(x: disc.midX + side * tw * 0.45, y: disc.midY), hr * 0.03), with: .color(dark)) }
            animalMouthY = tip.y + hr * 0.16
            animalMW = hr * 0.1
        case .pointy:
            var cone = Path()
            cone.move(to: CGPoint(x: mx - hr * 0.32, y: sc.y + hr * 0.1))
            cone.addQuadCurve(to: CGPoint(x: mx, y: sc.y + hr * 0.75 * a + hr * 0.1), control: CGPoint(x: mx - hr * 0.2, y: sc.y + hr * 0.6))
            cone.addQuadCurve(to: CGPoint(x: mx + hr * 0.32, y: sc.y + hr * 0.1), control: CGPoint(x: mx + hr * 0.2, y: sc.y + hr * 0.6))
            cone.closeSubpath()
            sn.fill(cone, with: .color(light))
            sn.stroke(cone, with: .color(dark.opacity(0.5)), lineWidth: max(0.5, hr * 0.03))
            sn.fill(circle(CGPoint(x: mx, y: sc.y + hr * 0.75 * a + hr * 0.04), hr * 0.08), with: .color(dark))
            animalMouthY = sc.y + hr * (0.75 * a + 0.24)
            animalMW = hr * 0.1
        case .horse:
            let muzzle = CGRect(x: sc.x - shape.width * 0.62, y: sc.y + hr * 0.35, width: shape.width * 1.24, height: hr * 1.05)
            sn.fill(Path(ellipseIn: muzzle), with: .color(light))
            for side in [-1.0, 1.0] {
                sn.fill(Path(ellipseIn: CGRect(x: mx + side * hr * 0.2 - hr * 0.05, y: muzzle.minY + hr * 0.3, width: hr * 0.1, height: hr * 0.18)), with: .color(.black))
            }
        case .jaws:
            // A long, flat alligator snout pushes out of her face, lined with teeth.
            let len = hr * (0.35 + 1.25 * a)
            let snout = CGRect(x: mx - shape.width * 0.5, y: sc.y + hr * 0.15, width: shape.width, height: len)
            let tooth = Color(red: 0.98, green: 0.97, blue: 0.9)
            for side in [-1.0, 1.0] {
                for k in 0..<5 {
                    let y = snout.minY + len * (0.3 + Double(k) * 0.15)
                    let x = side < 0 ? snout.minX : snout.maxX
                    sn.fill(polyline([CGPoint(x: x, y: y - hr * 0.06), CGPoint(x: x + side * hr * 0.09, y: y + hr * 0.02), CGPoint(x: x, y: y + hr * 0.08)]), with: .color(tooth))
                }
            }
            sn.fill(Path(roundedRect: snout, cornerRadius: shape.width * 0.45), with: .color(kind.fur.mixed(with: kind.dark, 0.15).color))
            sn.stroke(Path(roundedRect: snout, cornerRadius: shape.width * 0.45), with: .color(dark.opacity(0.6)), lineWidth: max(0.5, hr * 0.035))
            for k in 0..<3 {
                let y = snout.minY + len * (0.25 + Double(k) * 0.2)
                sn.fill(circle(CGPoint(x: mx - hr * 0.12, y: y), hr * 0.05), with: .color(dark.opacity(0.5)))
                sn.fill(circle(CGPoint(x: mx + hr * 0.12, y: y + len * 0.08), hr * 0.05), with: .color(dark.opacity(0.5)))
            }
            for side in [-1.0, 1.0] {
                sn.fill(Path(ellipseIn: CGRect(x: mx + side * hr * 0.14 - hr * 0.06, y: snout.maxY - hr * 0.28, width: hr * 0.12, height: hr * 0.09)), with: .color(dark))
            }
            animalMouthY = snout.maxY - hr * 0.1
        case .serpent:
            for side in [-1.0, 1.0] {
                sn.fill(Path(ellipseIn: CGRect(x: mx + side * hr * 0.12 - hr * 0.04, y: sc.y + hr * 0.38, width: hr * 0.08, height: hr * 0.06)), with: .color(dark))
            }
        case .trunk:
            break
        }
    }

    // The mouth moves down into the muzzle.
    let mouthY = mix(head.y + hr * 0.45, animalMouthY, a)
    let mw = mix(hr * 0.25, animalMW, a)
    let mouthColor = Color(red: 0.55, green: 0.15, blue: 0.15)
    let inside = Color(red: 0.30, green: 0.06, blue: 0.08)
    if beaming {
        let depth = hr * mix(0.38, 0.45, a)
        let wide = mw * 1.5
        var open = Path()
        open.move(to: CGPoint(x: mx - wide, y: mouthY - hr * 0.05))
        open.addQuadCurve(to: CGPoint(x: mx + wide, y: mouthY - hr * 0.05), control: CGPoint(x: mx, y: mouthY - hr * 0.12))
        open.addQuadCurve(to: CGPoint(x: mx - wide, y: mouthY - hr * 0.05), control: CGPoint(x: mx, y: mouthY + depth * 1.6))
        open.closeSubpath()
        ctx.fill(open, with: .color(inside))
        var tongue = ctx
        tongue.clip(to: open)
        tongue.fill(Path(ellipseIn: CGRect(x: mx - wide * 0.55, y: mouthY + depth * 0.45, width: wide * 1.1, height: depth)),
                    with: .color(Color(red: 0.95, green: 0.45, blue: 0.5)))
        fill(tongue, CGRect(x: mx - wide, y: mouthY - hr * 0.15, width: wide * 2, height: hr * 0.2), Color(red: 1, green: 0.98, blue: 0.9))
        ctx.stroke(open, with: .color(mouthColor), lineWidth: max(1, hr * 0.06))
    } else if shocked {
        let o = CGRect(x: mx - hr * 0.14, y: mouthY - hr * 0.03, width: hr * 0.28, height: hr * 0.32)
        ctx.fill(Path(ellipseIn: o), with: .color(inside))
    } else {
        var mouth = Path()
        mouth.move(to: CGPoint(x: mx - mw, y: mouthY))
        mouth.addQuadCurve(to: CGPoint(x: mx + mw, y: mouthY), control: CGPoint(x: mx, y: mouthY + hr * 0.25))
        ctx.stroke(mouth, with: .color(a > 0.5 ? inside : mouthColor), style: StrokeStyle(lineWidth: max(1.1, hr * 0.08), lineCap: .round))
    }

    // A snake's forked tongue flicks in and out.
    if a > 0.5 && kind.snout == .serpent && !shocked {
        let flick = still ? 1 : max(0, sin(tt * 5))
        if flick > 0.05 {
            let start = CGPoint(x: mx, y: mouthY + (beaming ? hr * 0.2 : hr * 0.08))
            let fork = CGPoint(x: mx, y: start.y + hr * 0.4 * flick)
            var tongue = Path()
            tongue.move(to: start)
            tongue.addLine(to: fork)
            tongue.move(to: fork)
            tongue.addLine(to: CGPoint(x: fork.x - hr * 0.1 * flick, y: fork.y + hr * 0.14 * flick))
            tongue.move(to: fork)
            tongue.addLine(to: CGPoint(x: fork.x + hr * 0.1 * flick, y: fork.y + hr * 0.14 * flick))
            ctx.stroke(tongue, with: .color(Color(red: 0.85, green: 0.12, blue: 0.2)), style: StrokeStyle(lineWidth: max(0.8, hr * 0.05), lineCap: .round))
        }
    }

    // An elephant's trunk hangs down over the mouth, with a tusk either side.
    if a > 0 && kind.snout == .trunk {
        let ivory = Color(red: 0.97, green: 0.95, blue: 0.88)
        for side in [-1.0, 1.0] {
            // The tusks poke out and lengthen along with the trunk.
            var tusk = Path()
            tusk.move(to: CGPoint(x: mx + side * hr * 0.32, y: sc.y + hr * 0.5))
            tusk.addQuadCurve(to: CGPoint(x: mx + side * hr * (0.39 + 0.23 * a), y: sc.y + hr * (0.5 + 0.55 * a)), control: CGPoint(x: mx + side * hr * 0.3, y: sc.y + hr * (0.5 + 0.5 * a)))
            tusk.addQuadCurve(to: CGPoint(x: mx + side * hr * 0.46, y: sc.y + hr * 0.45), control: CGPoint(x: mx + side * hr * 0.45, y: sc.y + hr * (0.45 + 0.35 * a)))
            tusk.closeSubpath()
            ctx.fill(tusk, with: .color(ivory.opacity(a)))
            ctx.stroke(tusk, with: .color(.black.opacity(0.25 * a)), lineWidth: max(0.5, hr * 0.025))
        }
        // The trunk grows out of her nose, longer and thicker as the change goes on.
        let swing = sin(tt * 2) * hr * 0.08 * a
        let root = CGPoint(x: mx, y: sc.y + hr * 0.18)
        let ctrl = CGPoint(x: mx - facing * hr * 0.2 * a, y: root.y + hr * 1.9 * a)
        let tip = CGPoint(x: mx + facing * hr * 0.7 * a + swing * 2, y: root.y + hr * 2.8 * a)
        let tw = hr * mix(0.16, 0.38, a)
        var trunk = Path()
        trunk.move(to: root)
        trunk.addQuadCurve(to: tip, control: ctrl)
        ctx.stroke(trunk, with: .color(dark.opacity(a)), style: limbStyle(tw + hr * 0.06))
        ctx.stroke(trunk, with: .color(skinHead), style: limbStyle(tw))
        for k in 1...10 where a > 0.3 {
            let u = Double(k) / 11
            let pt = lerp(lerp(root, ctrl, u), lerp(ctrl, tip, u), u)
            ctx.stroke(polyline([CGPoint(x: pt.x - tw * 0.34, y: pt.y), CGPoint(x: pt.x + tw * 0.34, y: pt.y)]), with: .color(dark.opacity(0.5 * a)), lineWidth: max(0.5, hr * 0.025))
        }
        // The tip curls up a little
        ctx.fill(circle(CGPoint(x: tip.x + facing * hr * 0.06 * a, y: tip.y - hr * 0.04 * a), tw * 0.45), with: .color(skinHead))
    }

    guard !still else { return }

    // Tingling: green sparkles fizz all over, then a glowing line climbs from the toes to the face.
    if p.isTingling(at: now) {
        let u = p.progress(at: now)
        let bottom = pose.foot[0].y
        let top = shape.top
        if now < p.changeT0 {
            for i in 0..<14 {
                let k = Double(i)
                let g = max(0, sin(tt * 5 + k * 1.7))
                let pt = CGPoint(x: head.x + sin(k * 2.3) * pose.w * 0.8, y: top + (bottom - top) * ((k * 0.37).truncatingRemainder(dividingBy: 1)))
                drawSparkle(ctx, at: pt, size: hr * 0.22 * g, alpha: g * 0.9)
            }
        } else {
            let y = bottom - (bottom - top) * u
            ctx.fill(Path(CGRect(x: head.x - pose.w * 0.9, y: y - 3, width: pose.w * 1.8, height: 6)),
                     with: .linearGradient(Gradient(colors: [.clear, changeGlow.opacity(0.9), .white.opacity(0.9), changeGlow.opacity(0.9), .clear]),
                                           startPoint: CGPoint(x: head.x - pose.w * 0.9, y: y), endPoint: CGPoint(x: head.x + pose.w * 0.9, y: y)))
            for i in 0..<8 {
                let k = Double(i)
                let g = max(0, sin(tt * 7 + k * 2.1))
                drawSparkle(ctx, at: CGPoint(x: head.x + sin(k * 1.9 + tt) * pose.w * 0.7, y: y + cos(k * 2.7) * 8), size: hr * 0.25 * g, alpha: g)
            }
        }
    }

    // Feeling her head: her hands pat it, by her new ears.
    if p.feelsHead {
        for hd in pose.hand {
            let r = pose.armW * mix(0.62, 0.72, lv.body)
            ctx.fill(circle(hd, r), with: .color(skinHands))
            ctx.stroke(circle(hd, r), with: .color(.black.opacity(0.25)), lineWidth: 0.7)
        }
    }

    // A freshly finished alien animal twinkles for a couple of seconds.
    let st = now.timeIntervalSince(p.shineT0)
    if st >= 0 && st < 2.4 {
        let pulse = sin(st / 2.4 * .pi)
        drawSparkle(ctx, at: CGPoint(x: head.x - hr * 0.5, y: shape.top + hr * 0.1), size: hr * 0.55 * pulse, alpha: pulse)
        let later = max(0, sin((st - 0.5) / 1.9 * .pi))
        drawSparkle(ctx, at: CGPoint(x: head.x + hr * 0.75, y: shape.top), size: hr * 0.35 * later, alpha: later)
        drawSparkle(ctx, at: CGPoint(x: t.maxX + hr * 0.3, y: t.midY), size: hr * 0.4 * later, alpha: later)
    }
}
