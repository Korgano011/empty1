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
            let sh = CGPoint(x: x + side * (w / 2 + h * 0.005), y: shY + h * 0.035)
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

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

func drawBox(_ ctx: GraphicsContext, center c: CGPoint, size s: Double) {
    let r = CGRect(x: c.x - s / 2, y: c.y - s / 2, width: s, height: s * 0.85)
    fill(ctx, r, Color(red: 0.78, green: 0.60, blue: 0.38), corner: 2)
    ctx.stroke(Path(roundedRect: r, cornerRadius: 2), with: .color(Color(red: 0.55, green: 0.40, blue: 0.22)), lineWidth: 1.2)
    fill(ctx, CGRect(x: r.minX, y: r.minY + r.height * 0.18, width: r.width, height: r.height * 0.12), Color(red: 0.90, green: 0.82, blue: 0.62))
}

/// `hair` overrides how much hair is left (the album uses 1 for "before" and 0 for "after").
func drawPerson(_ ctx: GraphicsContext, _ p: Person, feet: CGPoint, facing: Double, now: Date,
                reflection: Bool = false, hair: Double? = nil) {
    let pose = Pose(p, feet: feet, facing: facing, now: now, still: reflection)
    let skin = p.skin.color
    let h = pose.h, hr = pose.hr, head = pose.head
    let limbStyle = { (w: Double) in StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }
    let left = hair ?? p.hairLeft(at: now)
    let hairColor = p.hair.color.opacity(left)

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
        ctx.stroke(leg, with: .color(skin), style: limbStyle(pose.legW))
        ctx.stroke(leg, with: .color(p.pants.color), style: limbStyle(pose.legW * 1.15))
        let f = pose.foot[i]
        ctx.fill(Path(ellipseIn: CGRect(x: f.x - h * 0.045 + facing * h * 0.02, y: f.y - h * 0.012, width: h * 0.09, height: h * 0.045)),
                 with: .color(Color(white: 0.25)))
    }

    // Neck and torso
    fill(ctx, pose.neck, skin)
    let t = pose.torso
    let torsoPath = Path(roundedRect: t, cornerRadius: pose.w * 0.3)
    ctx.fill(torsoPath, with: .color(p.shirt.color))
    var collar = Path()
    collar.addArc(center: CGPoint(x: t.midX, y: t.minY), radius: pose.w * 0.2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
    ctx.fill(collar, with: .color(skin))
    fill(ctx, CGRect(x: t.minX, y: t.maxY - h * 0.05, width: t.width, height: h * 0.06), p.pants.color, corner: 3)

    // Arms
    for i in 0..<2 {
        let arm = polyline([pose.shoulder[i], pose.elbow[i], pose.hand[i]])
        ctx.stroke(arm, with: .color(skin), style: limbStyle(pose.armW))
        let sleeve = polyline([pose.shoulder[i], lerp(pose.shoulder[i], pose.elbow[i], 0.5)])
        ctx.stroke(sleeve, with: .color(p.shirt.color), style: StrokeStyle(lineWidth: pose.armW * 1.35, lineCap: .round))
        ctx.fill(circle(pose.hand[i], pose.armW * 0.62), with: .color(skin))
    }
    if p.carrying && !reflection {
        drawBox(ctx, center: CGPoint(x: t.midX, y: t.minY + t.height * 0.62), size: pose.w * 1.25)
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

    // Ears, then the head
    for side in [-1.0, 1.0] {
        ctx.fill(Path(ellipseIn: CGRect(x: head.x + side * hr * 0.95 - hr * 0.16, y: head.y - hr * 0.05, width: hr * 0.32, height: hr * 0.42)),
                 with: .color(skin))
    }
    let headRect = CGRect(x: head.x - hr, y: head.y - hr, width: hr * 2, height: hr * 2)
    ctx.fill(Path(ellipseIn: headRect), with: .color(skin))

    // Hair on top of the head
    if left > 0 {
        if p.style == .curly {
            for i in 0..<11 {
                let a = (185.0 + Double(i) * 17) * .pi / 180
                ctx.fill(circle(CGPoint(x: head.x + cos(a) * hr * 0.95, y: head.y + sin(a) * hr * 0.95), hr * 0.34), with: .color(hairColor))
            }
            for side in [-1.0, 1.0] {
                ctx.fill(circle(CGPoint(x: head.x + side * hr * 1.05, y: head.y + hr * 0.25), hr * 0.3), with: .color(hairColor))
            }
        } else {
            var fringe = Path()
            for step in 0...16 {
                let a = (190.0 + Double(step) * 10) * .pi / 180
                let pt = CGPoint(x: head.x + cos(a) * hr * 1.05, y: head.y + sin(a) * hr * 1.05)
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

    // Face
    let look = facing * hr * 0.15
    let shocked = p.mood == .shocked && !reflection
    for side in [-1.0, 1.0] {
        let e = CGPoint(x: head.x + side * hr * 0.35 + look, y: head.y + hr * 0.1)
        if shocked {
            ctx.fill(circle(e, hr * 0.17), with: .color(.white))
            ctx.stroke(circle(e, hr * 0.17), with: .color(.black), lineWidth: max(0.8, hr * 0.05))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: e.x - hr * 0.1, y: e.y - hr * 0.12, width: hr * 0.2, height: hr * 0.24)), with: .color(.black))
    }
    for dx in [-0.75, 0.45] {
        ctx.fill(Path(ellipseIn: CGRect(x: head.x + hr * dx + look, y: head.y + hr * 0.3, width: hr * 0.3, height: hr * 0.18)),
                 with: .color(.pink.opacity(0.45)))
    }
    if shocked {
        ctx.fill(Path(ellipseIn: CGRect(x: head.x - hr * 0.13 + look, y: head.y + hr * 0.42, width: hr * 0.26, height: hr * 0.32)),
                 with: .color(Color(red: 0.45, green: 0.10, blue: 0.12)))
    } else {
        var mouth = Path()
        mouth.move(to: CGPoint(x: head.x - hr * 0.25 + look, y: head.y + hr * 0.45))
        mouth.addQuadCurve(to: CGPoint(x: head.x + hr * 0.25 + look, y: head.y + hr * 0.45),
                           control: CGPoint(x: head.x + look, y: head.y + hr * 0.7))
        ctx.stroke(mouth, with: .color(Color(red: 0.6, green: 0.15, blue: 0.15)), style: StrokeStyle(lineWidth: max(1.2, hr * 0.1), lineCap: .round))
    }
}
