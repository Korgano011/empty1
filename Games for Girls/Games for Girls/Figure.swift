import SwiftUI

// Characters drawn in the Princess of Poker style: girls with thick curls, big shiny eyes with lashes,
// blush, full lips and a sparkling knee-length dress; guys with ears, a collared shirt and slacks.
// A boy→girl change sweeps up from the feet behind a glowing line, then the face morphs.

private func circle(_ c: CGPoint, _ r: Double) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
}

private func limb(_ ctx: GraphicsContext, _ a: CGPoint, _ b: CGPoint, _ w: Double, _ color: Color) {
    var p = Path()
    p.move(to: a)
    p.addLine(to: b)
    ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w, lineCap: .round))
}

func drawTwinkle(_ ctx: GraphicsContext, _ c: CGPoint, _ s: Double, _ color: Color = .white) {
    var p = Path()
    p.move(to: CGPoint(x: c.x, y: c.y - s))
    p.addQuadCurve(to: CGPoint(x: c.x + s, y: c.y), control: c)
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + s), control: c)
    p.addQuadCurve(to: CGPoint(x: c.x - s, y: c.y), control: c)
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - s), control: c)
    ctx.fill(p, with: .color(color))
}

private func hash(_ a: Int, _ b: Int) -> Double {
    var x = UInt64(truncatingIfNeeded: a &* 73_856_093 ^ b &* 19_349_663)
    x ^= x >> 13; x &*= 0x5bd1e995; x ^= x >> 15
    return Double(x % 10_000) / 10_000
}

/// Looks whose mouths are moving this frame (set by the story player while a line is spoken).
var talkingLooks: [Look] = []

private let lipColor = Color(red: 0.9, green: 0.12, blue: 0.4)

private enum Face { case happy, shocked, worried, angry, laughing }

private func face(_ m: Mood) -> Face {
    switch m {
    case .happy, .neutral: .happy
    case .surprised: .shocked
    case .sad, .tired: .worried
    case .angry: .angry
    case .laughing: .laughing
    }
}

// MARK: Heads

private func drawCurlsBack(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, _ hair: Color) {
    let center = CGPoint(x: c.x, y: c.y - r * 0.2)
    ctx.fill(Path(ellipseIn: CGRect(x: center.x - r * 1.3, y: center.y - r * 1.1, width: r * 2.6, height: r * 1.9)), with: .color(hair))
    for i in 0..<16 {
        let a = Double(i) / 16 * 2 * .pi
        let p = CGPoint(x: center.x + cos(a) * r * 1.25, y: center.y + sin(a) * r * 1.0)
        guard p.y < c.y + r * 0.3 else { continue }
        ctx.fill(circle(p, r * 0.42), with: .color(hair))
        ctx.stroke(Path { $0.addArc(center: p, radius: r * 0.24, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false) },
                   with: .color(.black.opacity(0.18)), lineWidth: max(1, r * 0.06))
    }
}

private func drawCurlsFront(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, _ hair: Color) {
    for i in 0..<7 {
        let a = Double.pi * (1.08 + Double(i) / 6 * 0.84)
        let p = CGPoint(x: c.x + cos(a) * r * 0.82, y: c.y + sin(a) * r * 0.82)
        ctx.fill(circle(p, r * 0.36), with: .color(hair))
        ctx.stroke(Path { $0.addArc(center: p, radius: r * 0.18, startAngle: .degrees(20), endAngle: .degrees(200), clockwise: false) },
                   with: .color(.black.opacity(0.18)), lineWidth: max(1, r * 0.05))
    }
}

private func drawEyes(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, girl: Bool, mood: Face, look: Double) {
    if mood == .laughing {
        for s in [-1.0, 1.0] {
            let e = CGPoint(x: c.x + s * r * 0.36, y: c.y - r * 0.05)
            var a = Path()
            a.move(to: CGPoint(x: e.x - r * 0.16, y: e.y + r * 0.04))
            a.addQuadCurve(to: CGPoint(x: e.x + r * 0.16, y: e.y + r * 0.04), control: CGPoint(x: e.x, y: e.y - r * 0.2))
            ctx.stroke(a, with: .color(Color(red: 0.2, green: 0.15, blue: 0.1)), style: StrokeStyle(lineWidth: max(1, r * 0.08), lineCap: .round))
            var b = Path()
            b.move(to: CGPoint(x: e.x - r * 0.16, y: e.y - r * 0.38))
            b.addQuadCurve(to: CGPoint(x: e.x + r * 0.16, y: e.y - r * 0.38), control: CGPoint(x: e.x, y: e.y - r * 0.48))
            ctx.stroke(b, with: .color(.black.opacity(0.7)), style: StrokeStyle(lineWidth: max(1, r * (girl ? 0.05 : 0.08)), lineCap: .round))
        }
        return
    }
    for s in [-1.0, 1.0] {
        let e = CGPoint(x: c.x + s * r * 0.36, y: c.y - r * 0.05)
        let big = mood == .shocked ? 1.35 : 1.0
        ctx.fill(Path(ellipseIn: CGRect(x: e.x - r * 0.17 * big, y: e.y - r * 0.2 * big, width: r * 0.34 * big, height: r * 0.4 * big)), with: .color(.white))
        let px = e.x + look * r * 0.06
        ctx.fill(circle(CGPoint(x: px, y: e.y + r * 0.03), r * 0.1), with: .color(Color(red: 0.2, green: 0.15, blue: 0.1)))
        ctx.fill(circle(CGPoint(x: px + r * 0.04, y: e.y - r * 0.02), r * 0.035), with: .color(.white))
        if girl {
            for k in 0..<3 {
                let a = Double.pi * (1.15 + Double(k) * 0.35)
                limb(ctx, CGPoint(x: e.x + cos(a) * r * 0.17, y: e.y + sin(a) * r * 0.2),
                     CGPoint(x: e.x + cos(a) * r * 0.3, y: e.y + sin(a) * r * 0.33), max(1, r * 0.05), .black)
            }
        }
        var b = Path()
        let w = max(1, r * (girl ? 0.05 : 0.08))
        switch mood {
        case .angry:
            // brows slanting down toward the nose
            b.move(to: CGPoint(x: e.x - s * r * 0.2, y: e.y - r * 0.42))
            b.addLine(to: CGPoint(x: e.x + s * r * 0.16, y: e.y - r * 0.26))
            ctx.stroke(b, with: .color(.black.opacity(0.85)), style: StrokeStyle(lineWidth: w * 1.4, lineCap: .round))
        default:
            let lift = mood == .shocked ? r * 0.12 : (mood == .worried ? r * 0.05 : 0)
            b.move(to: CGPoint(x: e.x - r * 0.16, y: e.y - r * 0.3 - lift + (mood == .worried ? s * -r * 0.04 : 0)))
            b.addQuadCurve(to: CGPoint(x: e.x + r * 0.16, y: e.y - r * 0.3 - lift), control: CGPoint(x: e.x, y: e.y - r * 0.4 - lift))
            ctx.stroke(b, with: .color(.black.opacity(0.7)), style: StrokeStyle(lineWidth: w, lineCap: .round))
        }
    }
}

private func drawMouth(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, lips: Color?, mood: Face, open: Double = 0) {
    let m = CGPoint(x: c.x, y: c.y + r * 0.48)
    if mood == .laughing {
        var g = Path()
        g.move(to: CGPoint(x: m.x - r * 0.28, y: m.y - r * 0.05))
        g.addQuadCurve(to: CGPoint(x: m.x + r * 0.28, y: m.y - r * 0.05), control: CGPoint(x: m.x, y: m.y + r * 0.45))
        g.closeSubpath()
        ctx.fill(g, with: .color(Color(red: 0.35, green: 0.05, blue: 0.08)))
        ctx.fill(Path(CGRect(x: m.x - r * 0.22, y: m.y - r * 0.05, width: r * 0.44, height: r * 0.08)), with: .color(.white))
        return
    }
    if open > 0.05 && mood != .shocked {
        // talking: an open mouth that flaps with the words
        let h = r * 0.24 * open
        ctx.fill(Path(ellipseIn: CGRect(x: m.x - r * 0.18, y: m.y - h / 2, width: r * 0.36, height: h + r * 0.05)), with: .color(Color(red: 0.35, green: 0.05, blue: 0.08)))
        if let lips {
            ctx.stroke(Path(ellipseIn: CGRect(x: m.x - r * 0.21, y: m.y - h / 2 - r * 0.03, width: r * 0.42, height: h + r * 0.11)), with: .color(lips), lineWidth: max(1.5, r * 0.09))
        }
        return
    }
    if mood == .shocked {
        ctx.fill(Path(ellipseIn: CGRect(x: m.x - r * 0.13, y: m.y - r * 0.12, width: r * 0.26, height: r * 0.3)), with: .color(Color(red: 0.35, green: 0.05, blue: 0.08)))
        if let lips {
            ctx.stroke(Path(ellipseIn: CGRect(x: m.x - r * 0.15, y: m.y - r * 0.14, width: r * 0.3, height: r * 0.34)), with: .color(lips), lineWidth: max(1.5, r * 0.08))
        }
        return
    }
    if let lips {
        let frown = mood == .worried || mood == .angry
        var top = Path()
        top.move(to: CGPoint(x: m.x - r * 0.24, y: m.y))
        top.addQuadCurve(to: CGPoint(x: m.x, y: m.y - r * 0.07), control: CGPoint(x: m.x - r * 0.12, y: m.y - r * 0.14))
        top.addQuadCurve(to: CGPoint(x: m.x + r * 0.24, y: m.y), control: CGPoint(x: m.x + r * 0.12, y: m.y - r * 0.14))
        top.addQuadCurve(to: CGPoint(x: m.x - r * 0.24, y: m.y), control: CGPoint(x: m.x, y: m.y + r * 0.02))
        ctx.fill(top, with: .color(lips))
        var bottom = Path()
        bottom.move(to: CGPoint(x: m.x - r * 0.24, y: m.y))
        bottom.addQuadCurve(to: CGPoint(x: m.x + r * 0.24, y: m.y), control: CGPoint(x: m.x, y: m.y + r * 0.05))
        bottom.addQuadCurve(to: CGPoint(x: m.x - r * 0.24, y: m.y), control: CGPoint(x: m.x, y: m.y + (frown ? r * 0.16 : r * 0.26)))
        ctx.fill(bottom, with: .color(lips))
        ctx.fill(circle(CGPoint(x: m.x - r * 0.06, y: m.y + r * 0.1), r * 0.035), with: .color(.white.opacity(0.6)))
    } else {
        var p = Path()
        p.move(to: CGPoint(x: m.x - r * 0.2, y: m.y))
        let curve: Double = mood == .worried ? -r * 0.08 : (mood == .angry ? -r * 0.12 : r * 0.14)
        p.addQuadCurve(to: CGPoint(x: m.x + r * 0.2, y: m.y), control: CGPoint(x: m.x, y: m.y + curve))
        ctx.stroke(p, with: .color(Color(red: 0.45, green: 0.15, blue: 0.12)), style: StrokeStyle(lineWidth: max(1, r * 0.07), lineCap: .round))
    }
}

private func drawGirlHead(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, skin: Color, hair: Color, mood: Face, look: Double, back: Bool = true, open: Double = 0) {
    if back { drawCurlsBack(ctx, c, r, hair) }
    ctx.fill(circle(c, r), with: .color(skin))
    for s in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: c.x + s * r * 0.55, y: c.y + r * 0.3), r * 0.15), with: .color(.pink.opacity(0.45)))
    }
    drawEyes(ctx, c, r, girl: true, mood: mood, look: look)
    drawMouth(ctx, c, r, lips: lipColor, mood: mood, open: open)
    drawCurlsFront(ctx, c, r, hair)
}

private func guyHair(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, _ l: Look) {
    let hair = Look.rgb(l.hair)
    if l.bald {
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.45, y: c.y - r * 0.85, width: r * 0.45, height: r * 0.2)), with: .color(.white.opacity(0.45)))
        // a fringe of hair over the ears
        for s in [-1.0, 1.0] {
            ctx.fill(Path(ellipseIn: CGRect(x: c.x + s * r * 0.92 - r * 0.18, y: c.y - r * 0.45, width: r * 0.36, height: r * 0.5)), with: .color(hair))
        }
        return
    }
    switch l.boyHair {
    case .short, .buzz:
        var p = Path()
        p.addArc(center: c, radius: r * 1.04, startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: c.x - r * 1.0, y: c.y - r * 0.05), control: CGPoint(x: c.x, y: c.y - (l.boyHair == .buzz ? r * 0.75 : r * 0.55)))
        ctx.fill(p, with: .color(hair))
    case .curly:
        for i in 0..<7 {
            let a = Double.pi * (1.0 + Double(i) / 6)
            ctx.fill(circle(CGPoint(x: c.x + cos(a) * r * 0.85, y: c.y + sin(a) * r * 0.85), r * 0.3), with: .color(hair))
        }
    case .spiky:
        var p = Path()
        p.addArc(center: c, radius: r * 1.04, startAngle: .degrees(185), endAngle: .degrees(355), clockwise: false)
        p.addQuadCurve(to: CGPoint(x: c.x - r * 1.0, y: c.y - r * 0.05), control: CGPoint(x: c.x, y: c.y - r * 0.55))
        for k in 0..<5 {
            let x = c.x - r * 0.7 + Double(k) * r * 0.35
            p.move(to: CGPoint(x: x - r * 0.17, y: c.y - r * 0.85))
            p.addLine(to: CGPoint(x: x, y: c.y - r * 1.4))
            p.addLine(to: CGPoint(x: x + r * 0.17, y: c.y - r * 0.85))
        }
        ctx.fill(p, with: .color(hair))
    }
}

private func guyHat(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, _ l: Look, facing: Double) {
    guard let cap = l.cap else { return }
    var p = Path()
    p.addArc(center: CGPoint(x: c.x, y: c.y - r * 0.2), radius: r * 1.05, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
    p.closeSubpath()
    let dir = facing < 0 ? -1.0 : 1.0
    p.addRoundedRect(in: CGRect(x: dir > 0 ? c.x : c.x - r * 1.8, y: c.y - r * 0.3, width: r * 1.8, height: r * 0.2), cornerSize: CGSize(width: r * 0.1, height: r * 0.1))
    ctx.fill(p, with: .color(Look.rgb(cap)))
}

private func drawGuyHead(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, skin: Color, look l: Look, mood: Face, facing: Double, open: Double = 0) {
    for s in [-1.0, 1.0] {
        ctx.fill(circle(CGPoint(x: c.x + s * r * 0.98, y: c.y + r * 0.05), r * 0.2), with: .color(skin))
    }
    ctx.fill(circle(c, r), with: .color(skin))
    guyHair(ctx, c, r, l)
    drawEyes(ctx, c, r, girl: false, mood: mood, look: facing)
    drawMouth(ctx, c, r, lips: nil, mood: mood, open: open)
    if mood == .angry {
        ctx.fill(circle(CGPoint(x: c.x - r * 0.55, y: c.y + r * 0.3), r * 0.2), with: .color(.red.opacity(0.35)))
        ctx.fill(circle(CGPoint(x: c.x + r * 0.55, y: c.y + r * 0.3), r * 0.2), with: .color(.red.opacity(0.35)))
    }
    guyHat(ctx, c, r, l, facing: facing)
}

private func drawMorphHead(_ ctx: GraphicsContext, _ c: CGPoint, _ r: Double, skin: Color, look l: Look, m: Double, mood: Face, back: Bool, open: Double = 0) {
    let hair = Look.rgb(l.hair)
    let grow = 0.35 + 0.65 * m
    func curls(_ draw: (GraphicsContext) -> Void) {
        ctx.drawLayer { layer in
            layer.opacity = min(1, m * 1.6)
            layer.translateBy(x: c.x, y: c.y)
            layer.scaleBy(x: grow, y: grow)
            layer.translateBy(x: -c.x, y: -c.y)
            draw(layer)
        }
    }
    if back {
        curls { drawCurlsBack($0, c, r, hair) }
        return
    }
    ctx.drawLayer { layer in
        layer.opacity = 1 - m
        for s in [-1.0, 1.0] { layer.fill(circle(CGPoint(x: c.x + s * r * 0.98, y: c.y + r * 0.05), r * 0.2), with: .color(skin)) }
    }
    ctx.fill(circle(c, r), with: .color(skin))
    ctx.drawLayer { layer in
        layer.opacity = 1 - m
        guyHair(layer, c, r, l)
        drawEyes(layer, c, r, girl: false, mood: mood, look: 0)
        drawMouth(layer, c, r, lips: nil, mood: mood, open: open)
    }
    ctx.drawLayer { layer in
        layer.opacity = m
        for s in [-1.0, 1.0] { layer.fill(circle(CGPoint(x: c.x + s * r * 0.55, y: c.y + r * 0.3), r * 0.15), with: .color(.pink.opacity(0.45))) }
        drawEyes(layer, c, r, girl: true, mood: mood, look: 0)
        drawMouth(layer, c, r, lips: lipColor, mood: mood, open: open)
    }
    curls { drawCurlsFront($0, c, r, hair) }
}

// MARK: Bodies

private struct Frame {
    let x, foot, H, r: Double
    var top: Double { foot - H }
    var head: CGPoint { CGPoint(x: x, y: top + r) }
    var shoulderY: Double { top + 2 * r + H * 0.035 }
    var shoulderW: Double { H * 0.115 }
    var waistY: Double { foot - H * 0.48 }
    var kneeY: Double { foot - H * 0.25 }
}

private struct Pose {
    var arms: Arms
    var facing: Double
    var bob: Double
    var seated: Bool { arms == .strapped }
}

private func hand(_ s: Double, _ f: Frame, _ pose: Pose, girl: Bool) -> CGPoint {
    let H = f.H
    let t = Date().timeIntervalSinceReferenceDate
    let side: Double = pose.facing < 0 ? -1 : 1
    switch pose.arms {
    case .down:
        return CGPoint(x: f.x + s * (f.shoulderW + H * (girl ? 0.03 : 0.035)), y: f.waistY + H * (girl ? 0.06 : 0.07))
    case .strapped:
        return CGPoint(x: f.x + s * H * 0.07, y: f.waistY + H * 0.045)
    case .up:
        return CGPoint(x: f.x + s * (f.shoulderW + H * 0.09), y: f.top + H * 0.02 + sin(t * 6 + s) * H * 0.015)
    case .wave:
        if s > 0 { return CGPoint(x: f.x + f.shoulderW + H * 0.1 + sin(t * 8) * H * 0.035, y: f.top + H * 0.06) }
        return hand(s, f, Pose(arms: .down, facing: 0, bob: 0), girl: girl)
    case .point:
        if s == side { return CGPoint(x: f.x + side * (f.shoulderW + H * 0.3), y: f.shoulderY + H * 0.02 + sin(t * 7) * H * 0.01) }
        return hand(s, f, Pose(arms: .down, facing: 0, bob: 0), girl: girl)
    case .mop:
        return CGPoint(x: f.x + H * 0.07 + pose.bob * 1.5 + (s > 0 ? H * 0.06 : 0), y: f.shoulderY + H * (s > 0 ? 0.2 : 0.1))
    case .fight:
        if s > 0 { return CGPoint(x: f.x + f.shoulderW + H * 0.28 + pose.bob * 2, y: f.shoulderY) }
        return CGPoint(x: f.x + H * 0.06, y: f.shoulderY + H * 0.05)
    case .carry:
        return CGPoint(x: f.x + s * H * 0.06 + H * 0.1, y: f.waistY - H * 0.03)
    case .hands:
        return CGPoint(x: f.x + s * H * 0.03, y: f.waistY - H * 0.04)
    case .snicker:
        // hands cupped over the mouth, shoulders shaking
        let r = f.r
        return CGPoint(x: f.x + s * r * 0.45 + sin(t * 30) * H * 0.006, y: f.head.y + r * 0.55)
    case .breakMop:
        // both hands out wide, gripping a mop handle across the raised knee
        return CGPoint(x: f.x + s * H * 0.2, y: f.waistY - H * 0.03)
    }
}

private func drawArms(_ ctx: GraphicsContext, _ f: Frame, _ pose: Pose, skin: Color, sleeve: Color?, girl: Bool) {
    let H = f.H
    for s in [-1.0, 1.0] {
        let sh = CGPoint(x: f.x + s * f.shoulderW * (girl ? 0.85 : 0.95), y: f.shoulderY + H * (girl ? 0.02 : 0.03))
        let hd = hand(s, f, pose, girl: girl)
        let elbow = CGPoint(x: (sh.x + hd.x) / 2 + s * H * 0.02, y: (sh.y + hd.y) / 2 + (pose.arms == .up ? 0 : H * 0.005))
        limb(ctx, sh, elbow, H * (girl ? 0.042 : 0.06), sleeve ?? skin)
        limb(ctx, elbow, hd, H * (girl ? 0.038 : 0.045), skin)
        ctx.fill(circle(hd, H * (girl ? 0.024 : 0.026)), with: .color(skin))
    }
    if pose.arms == .mop {
        let top = CGPoint(x: f.x + H * 0.06 + pose.bob * 1.5, y: f.shoulderY + H * 0.02)
        let bottom = CGPoint(x: f.x + H * 0.32 + pose.bob * 3, y: f.foot - H * 0.02)
        limb(ctx, top, bottom, H * 0.02, Color(red: 0.6, green: 0.45, blue: 0.25))
        ctx.fill(Path(ellipseIn: CGRect(x: bottom.x - H * 0.09, y: bottom.y - H * 0.03, width: H * 0.18, height: H * 0.05)), with: .color(Color(white: 0.88)))
    }
}

private func drawGirlBody(_ ctx: GraphicsContext, _ f: Frame, look: Look, skin: Color, pose: Pose, mood: Face, seed: Int, head: Bool, open: Double = 0) {
    let hair = Look.rgb(look.hair)
    let dress = Look.rgb(look.dress)
    let dressHi = Color(red: min(1, look.dress[0] * 0.5 + 0.5), green: min(1, look.dress[1] * 0.5 + 0.5), blue: min(1, look.dress[2] * 0.5 + 0.5))
    if head { drawCurlsBack(ctx, f.head, f.r, hair) }
    let H = f.H
    for s in [-1.0, 1.0] {
        let hip = CGPoint(x: f.x + s * H * 0.045, y: f.waistY + (pose.seated ? H * 0.01 : 0))
        let ankle: CGPoint
        if pose.seated {
            let knee = CGPoint(x: f.x + s * H * 0.08, y: f.waistY + H * 0.05)
            ankle = CGPoint(x: f.x + s * H * 0.06, y: f.foot - H * 0.2 - H * 0.035)
            limb(ctx, hip, knee, H * 0.065, skin)
            limb(ctx, knee, ankle, H * 0.05, skin)
        } else {
            ankle = CGPoint(x: f.x + s * H * 0.045, y: f.foot - H * 0.035)
            limb(ctx, CGPoint(x: f.x + s * H * 0.04, y: f.waistY), ankle, H * 0.05, skin)
        }
        var heel = Path()
        heel.addRoundedRect(in: CGRect(x: ankle.x - H * 0.03, y: ankle.y - H * 0.01, width: H * 0.06, height: H * 0.035), cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(heel, with: .color(dress.opacity(0.9)))
        limb(ctx, CGPoint(x: ankle.x + s * H * 0.02, y: ankle.y + H * 0.02), CGPoint(x: ankle.x + s * H * 0.022, y: ankle.y + H * 0.04), H * 0.012, .black)
    }
    drawArms(ctx, f, pose, skin: skin, sleeve: nil, girl: true)
    var chest = Path()
    chest.addRoundedRect(in: CGRect(x: f.x - f.shoulderW * 0.9, y: f.shoulderY - H * 0.005, width: f.shoulderW * 1.8, height: f.waistY - f.shoulderY),
                         cornerSize: CGSize(width: H * 0.03, height: H * 0.03))
    ctx.fill(chest, with: .color(skin))
    var d = Path()
    let bw = f.shoulderW * 0.8
    d.move(to: CGPoint(x: f.x - bw, y: f.shoulderY + H * 0.03))
    d.addQuadCurve(to: CGPoint(x: f.x + bw, y: f.shoulderY + H * 0.03), control: CGPoint(x: f.x, y: f.shoulderY + H * 0.08))
    d.addLine(to: CGPoint(x: f.x + H * 0.07, y: f.waistY))
    let hemY = pose.seated ? f.waistY + H * 0.075 : f.kneeY + H * 0.03
    let hemW = pose.seated ? H * 0.15 : H * 0.17
    d.addLine(to: CGPoint(x: f.x + hemW, y: hemY))
    d.addQuadCurve(to: CGPoint(x: f.x - hemW, y: hemY), control: CGPoint(x: f.x, y: hemY + H * 0.04))
    d.addLine(to: CGPoint(x: f.x - H * 0.07, y: f.waistY))
    d.closeSubpath()
    ctx.fill(d, with: .linearGradient(Gradient(colors: [dressHi, dress, dress.opacity(0.85)]),
                                      startPoint: CGPoint(x: f.x - H * 0.15, y: f.shoulderY), endPoint: CGPoint(x: f.x + H * 0.15, y: f.kneeY)))
    for s in [-1.0, 1.0] {
        limb(ctx, CGPoint(x: f.x + s * bw * 0.8, y: f.shoulderY + H * 0.035), CGPoint(x: f.x + s * bw * 0.7, y: f.shoulderY - H * 0.005), H * 0.012, dress)
    }
    let t = Date().timeIntervalSinceReferenceDate
    for i in 0..<14 {
        let u = hash(seed, i), v = hash(i, seed)
        let y = f.shoulderY + H * 0.05 + v * (hemY - H * 0.03 - f.shoulderY)
        let half = H * (0.06 + 0.1 * max(0, (y - f.waistY) / (f.kneeY - f.waistY)))
        let tw = 0.5 + 0.5 * sin(t * 3 + Double(i) * 1.7)
        drawTwinkle(ctx, CGPoint(x: f.x + (u * 2 - 1) * half, y: y), H * 0.018 * (0.4 + tw), .white.opacity(0.4 + 0.6 * tw))
    }
    if pose.seated { drawStraps(ctx, f) }
    limb(ctx, CGPoint(x: f.x, y: f.top + 2 * f.r - 2), CGPoint(x: f.x, y: f.shoulderY + H * 0.01), H * 0.045, skin)
    if head { drawGirlHead(ctx, f.head, f.r, skin: skin, hair: hair, mood: mood, look: pose.facing, back: false, open: open) }
}

private func drawGuyBody(_ ctx: GraphicsContext, _ f: Frame, look: Look, skin: Color, pose: Pose, mood: Face, head: Bool, open: Double = 0) {
    let H = f.H
    let shirt = Look.rgb(look.shirt), pants = Look.rgb(look.pants)
    for s in [-1.0, 1.0] {
        let hip = CGPoint(x: f.x + s * H * 0.045, y: f.waistY)
        if pose.seated {
            let knee = CGPoint(x: f.x + s * H * 0.085, y: f.waistY + H * 0.05)
            let ankle = CGPoint(x: f.x + s * H * 0.07, y: f.foot - H * 0.2 - H * 0.035)
            limb(ctx, hip, knee, H * 0.075, pants)
            limb(ctx, knee, ankle, H * 0.07, pants)
            ctx.fill(Path(ellipseIn: CGRect(x: ankle.x - H * 0.045, y: ankle.y - H * 0.005, width: H * 0.09, height: H * 0.045)), with: .color(Color(red: 0.25, green: 0.17, blue: 0.1)))
        } else if pose.arms == .breakMop && s > 0 {
            // right knee raised up to waist height to snap the mop over it
            let knee = CGPoint(x: f.x + H * 0.06, y: f.waistY - H * 0.04)
            let ankle = CGPoint(x: f.x + H * 0.09, y: f.waistY + H * 0.17)
            limb(ctx, hip, knee, H * 0.075, pants)
            limb(ctx, knee, ankle, H * 0.07, pants)
            ctx.fill(Path(ellipseIn: CGRect(x: ankle.x - H * 0.03, y: ankle.y - H * 0.005, width: H * 0.09, height: H * 0.045)), with: .color(Color(red: 0.25, green: 0.17, blue: 0.1)))
        } else {
            let ankle = CGPoint(x: f.x + s * H * 0.05, y: f.foot - H * 0.035)
            limb(ctx, hip, ankle, H * 0.075, pants)
            ctx.fill(Path(ellipseIn: CGRect(x: ankle.x - H * 0.045 + s * H * 0.01, y: ankle.y - H * 0.005, width: H * 0.09, height: H * 0.045)), with: .color(Color(red: 0.25, green: 0.17, blue: 0.1)))
        }
    }
    drawArms(ctx, f, pose, skin: skin, sleeve: shirt, girl: false)
    var torso = Path()
    torso.addRoundedRect(in: CGRect(x: f.x - f.shoulderW, y: f.shoulderY, width: 2 * f.shoulderW, height: f.waistY - f.shoulderY + H * 0.05),
                         cornerSize: CGSize(width: H * 0.04, height: H * 0.04))
    ctx.fill(torso, with: .color(shirt))
    var collar = Path()
    collar.move(to: CGPoint(x: f.x - H * 0.04, y: f.shoulderY))
    collar.addLine(to: CGPoint(x: f.x, y: f.shoulderY + H * 0.05))
    collar.addLine(to: CGPoint(x: f.x + H * 0.04, y: f.shoulderY))
    ctx.stroke(collar, with: .color(.black.opacity(0.35)), lineWidth: max(1, H * 0.01))
    // re-draw a forward arm over the torso when it reaches across the body
    if [.mop, .carry, .hands, .fight, .breakMop, .snicker].contains(pose.arms) {
        drawArms(ctx, f, pose, skin: skin, sleeve: shirt, girl: false)
    }
    if pose.seated { drawStraps(ctx, f) }
    limb(ctx, CGPoint(x: f.x, y: f.top + 2 * f.r - 2), CGPoint(x: f.x, y: f.shoulderY + H * 0.01), H * 0.05, skin)
    if head { drawGuyHead(ctx, f.head, f.r, skin: skin, look: look, mood: mood, facing: pose.facing, open: open) }
}

private func drawStraps(_ ctx: GraphicsContext, _ f: Frame) {
    for y in [f.shoulderY + f.H * 0.1, f.waistY + f.H * 0.03] {
        let rect = CGRect(x: f.x - f.H * 0.16, y: y - f.H * 0.018, width: f.H * 0.32, height: f.H * 0.036)
        ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(Color(red: 0.25, green: 0.2, blue: 0.25)))
        ctx.fill(Path(CGRect(x: rect.midX - 4, y: rect.minY - 1, width: 8, height: rect.height + 2)), with: .color(.gray))
    }
}

// MARK: Person

/// Draws a person with feet at `feet`, `h` tall. `girl` 0…1 sweeps a boy into a girl from the feet up.
/// Seated (`arms: .strapped`) people sit with `feet` on the floor.
func drawPerson(_ ctx: inout GraphicsContext, look: Look, feet: CGPoint, h: CGFloat,
                girl gIn: Double = 0, mood: Mood = .neutral, arms: Arms = .down, facing: CGFloat = 0, bob: CGFloat = 0) {
    let g = look.woman ? 1 : max(0, min(1, gIn))
    let H = Double(h)
    let bob = max(-12, min(12, bob))
    let pose = Pose(arms: arms, facing: Double(facing), bob: Double(bob))
    let open = talkingLooks.contains(look) ? 0.5 + 0.5 * sin(Date().timeIntervalSinceReferenceDate * 16) : 0
    let r = H * (look.kid ? 0.12 : 0.095)
    let drop = pose.seated ? H * 0.2 : 0
    let f = Frame(x: feet.x, foot: feet.y + drop + bob, H: H, r: r)
    let skin = Look.rgb(look.skin)
    let fm = face(mood)
    let seed = Int(look.skin[0] * 100 + look.dress[1] * 1000 + look.dress[2] * 37)
    let c = ctx
    if !pose.seated {
        c.fill(Path(ellipseIn: CGRect(x: feet.x - H * 0.13, y: feet.y - 4, width: H * 0.26, height: 8)), with: .color(.black.opacity(0.18)))
    }
    if g <= 0 {
        drawGuyBody(c, f, look: look, skin: skin, pose: pose, mood: fm, head: true, open: open)
    } else if g >= 1 {
        drawGirlBody(c, f, look: look, skin: skin, pose: pose, mood: fm, seed: seed, head: true, open: open)
    } else {
        let bandY = f.foot - g * (H + r)
        let chinY = f.top + 2 * r
        let morphing = bandY < chinY
        let m = min(1, max(0, (chinY - bandY) / (chinY - (f.top - r))))
        if morphing { drawMorphHead(c, f.head, r, skin: skin, look: look, m: m, mood: fm, back: true) }
        c.drawLayer { layer in
            layer.clip(to: Path(CGRect(x: f.x - 300, y: -2000, width: 600, height: 2000 + bandY)))
            drawGuyBody(layer, f, look: look, skin: skin, pose: pose, mood: fm, head: !morphing, open: open)
        }
        c.drawLayer { layer in
            layer.clip(to: Path(CGRect(x: f.x - 300, y: bandY, width: 600, height: 2000)))
            drawGirlBody(layer, f, look: look, skin: skin, pose: pose, mood: fm, seed: seed, head: !morphing, open: open)
        }
        if morphing { drawMorphHead(c, f.head, r, skin: skin, look: look, m: m, mood: fm, back: false, open: open) }
        let w = H * 0.32
        var line = Path()
        line.move(to: CGPoint(x: f.x - w, y: bandY))
        line.addLine(to: CGPoint(x: f.x + w, y: bandY))
        c.stroke(line, with: .color(Color.yellow.opacity(0.35)), lineWidth: max(4, H * 0.12))
        c.stroke(line, with: .color(.white), lineWidth: max(1.5, H * 0.025))
        let t = Date().timeIntervalSinceReferenceDate
        for i in 0..<6 {
            let u = (t * 0.9 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
            drawTwinkle(c, CGPoint(x: f.x - w + 2 * w * hash(i, Int(t * 3)), y: bandY - 4 - u * H * 0.2), H * 0.05 * (1 - u), .yellow)
        }
    }
}

// MARK: Portraits

/// Head and shoulders (Princess of Poker seat-portrait style). Girls get the sparkling dress; guys their shirt.
func drawBust(_ ctx: GraphicsContext, size: CGSize, look: Look, girl: Bool = true, mood: Mood = .happy) {
    let r = min(size.width, size.height) * 0.25
    let c = CGPoint(x: size.width / 2, y: size.height * 0.5)
    let skin = Look.rgb(look.skin)
    let isGirl = girl || look.woman
    if isGirl { drawCurlsBack(ctx, c, r, Look.rgb(look.hair)) }
    let sy = c.y + r * 1.25
    var shoulders = Path()
    shoulders.move(to: CGPoint(x: c.x - r * 1.5, y: size.height))
    shoulders.addQuadCurve(to: CGPoint(x: c.x - r * 0.4, y: sy), control: CGPoint(x: c.x - r * 1.4, y: sy))
    shoulders.addLine(to: CGPoint(x: c.x + r * 0.4, y: sy))
    shoulders.addQuadCurve(to: CGPoint(x: c.x + r * 1.5, y: size.height), control: CGPoint(x: c.x + r * 1.4, y: sy))
    shoulders.closeSubpath()
    ctx.fill(shoulders, with: .color(isGirl ? skin : Look.rgb(look.shirt)))
    if isGirl {
        let dress = Look.rgb(look.dress)
        let hi = Color(red: min(1, look.dress[0] * 0.5 + 0.5), green: min(1, look.dress[1] * 0.5 + 0.5), blue: min(1, look.dress[2] * 0.5 + 0.5))
        var d = Path()
        d.move(to: CGPoint(x: c.x - r * 1.2, y: size.height))
        d.addLine(to: CGPoint(x: c.x - r * 0.95, y: sy + r * 0.45))
        d.addQuadCurve(to: CGPoint(x: c.x + r * 0.95, y: sy + r * 0.45), control: CGPoint(x: c.x, y: sy + r * 0.85))
        d.addLine(to: CGPoint(x: c.x + r * 1.2, y: size.height))
        d.closeSubpath()
        ctx.fill(d, with: .linearGradient(Gradient(colors: [hi, dress]), startPoint: CGPoint(x: c.x - r, y: sy), endPoint: CGPoint(x: c.x + r, y: size.height)))
        let t = Date().timeIntervalSinceReferenceDate
        for i in 0..<6 {
            let tw = 0.5 + 0.5 * sin(t * 3 + Double(i) * 2.1)
            drawTwinkle(ctx, CGPoint(x: c.x + (hash(i, 3) * 2 - 1) * r * 0.9, y: sy + r * 0.6 + hash(3, i) * (size.height - sy - r * 0.6)), r * 0.09 * (0.4 + tw))
        }
    }
    ctx.fill(Path(CGRect(x: c.x - r * 0.25, y: c.y + r * 0.7, width: r * 0.5, height: r * 0.6)), with: .color(skin))
    if isGirl {
        drawGirlHead(ctx, c, r, skin: skin, hair: Look.rgb(look.hair), mood: face(mood), look: 0, back: false)
    } else {
        drawGuyHead(ctx, c, r, skin: skin, look: look, mood: face(mood), facing: 0)
    }
}
