import SwiftUI
import Observation

// MARK: - Engine (Backgammon + Acey Deucey)

/// Player 0 moves from point 23 down to 0 and bears off below 0 (home = 0…5).
/// Player 1 moves from 0 up to 23 and bears off above 23 (home = 18…23).
struct BGBoard: Hashable {
    var pts = [Int](repeating: 0, count: 24)   // + player 0, − player 1
    var bar = [0, 0]
    var off = [0, 0]
    var start = [0, 0]                          // Acey Deucey: not yet entered

    static let fromBar = -1, fromStart = -2, offBoard = 24

    static func backgammon() -> BGBoard {
        var b = BGBoard()
        b.pts[23] = 2; b.pts[12] = 5; b.pts[7] = 3; b.pts[5] = 5
        b.pts[0] = -2; b.pts[11] = -5; b.pts[16] = -3; b.pts[18] = -5
        return b
    }

    static func aceyDeucey() -> BGBoard {
        var b = BGBoard(); b.start = [15, 15]; return b
    }

    func mine(_ p: Int, _ i: Int) -> Int { p == 0 ? max(0, pts[i]) : max(0, -pts[i]) }
    func theirs(_ p: Int, _ i: Int) -> Int { mine(1 - p, i) }
    func entry(_ p: Int, _ die: Int) -> Int { p == 0 ? 24 - die : die - 1 }
    func inHome(_ p: Int, _ i: Int) -> Bool { p == 0 ? i <= 5 : i >= 18 }

    func allHome(_ p: Int) -> Bool {
        guard bar[p] == 0, start[p] == 0 else { return false }
        for i in 0..<24 where mine(p, i) > 0 && !inHome(p, i) { return false }
        return true
    }

    func moves(_ p: Int, die: Int) -> [BGMove] {
        var res: [BGMove] = []
        if bar[p] > 0 {
            let t = entry(p, die)
            if theirs(p, t) < 2 { res.append(BGMove(from: BGBoard.fromBar, to: t, die: die)) }
            return res
        }
        if start[p] > 0 {
            let t = entry(p, die)
            if theirs(p, t) < 2 { res.append(BGMove(from: BGBoard.fromStart, to: t, die: die)) }
        }
        let home = allHome(p)
        for i in 0..<24 where mine(p, i) > 0 {
            let t = p == 0 ? i - die : i + die
            if (0..<24).contains(t) {
                if theirs(p, t) < 2 { res.append(BGMove(from: i, to: t, die: die)) }
            } else if home {
                let exact = p == 0 ? t == -1 : t == 24
                var farther = false
                if !exact {
                    if p == 0 { for j in (i + 1)..<6 where mine(p, j) > 0 { farther = true } }
                    else { for j in 18..<i where mine(p, j) > 0 { farther = true } }
                }
                if exact || !farther { res.append(BGMove(from: i, to: BGBoard.offBoard, die: die)) }
            }
        }
        return res
    }

    mutating func apply(_ m: BGMove, _ p: Int) {
        let sign = p == 0 ? 1 : -1
        switch m.from {
        case BGBoard.fromBar: bar[p] -= 1
        case BGBoard.fromStart: start[p] -= 1
        default: pts[m.from] -= sign
        }
        if m.to == BGBoard.offBoard { off[p] += 1; return }
        if theirs(p, m.to) == 1 { pts[m.to] = 0; bar[1 - p] += 1 }
        pts[m.to] += sign
    }

    func pip(_ p: Int) -> Int {
        var s = (bar[p] + start[p]) * 25
        for i in 0..<24 { s += mine(p, i) * (p == 0 ? i + 1 : 24 - i) }
        return s
    }
}

struct BGMove: Hashable { var from: Int; var to: Int; var die: Int }

enum BGRules {
    /// Most dice that can be played from here.
    static func maxUse(_ b: BGBoard, _ dice: [Int], _ p: Int) -> Int {
        guard !dice.isEmpty else { return 0 }
        var best = 0
        for d in Set(dice) {
            var rest = dice; rest.remove(at: rest.firstIndex(of: d)!)
            for m in b.moves(p, die: d) {
                var nb = b; nb.apply(m, p)
                best = max(best, 1 + maxUse(nb, rest, p))
                if best == dice.count { return best }
            }
        }
        return best
    }

    /// Moves that keep the maximum number of dice playable (and the larger die when only one can be played).
    static func legal(_ b: BGBoard, _ dice: [Int], _ p: Int) -> [BGMove] {
        let target = maxUse(b, dice, p)
        guard target > 0 else { return [] }
        var res: [BGMove] = []
        for d in Set(dice) {
            var rest = dice; rest.remove(at: rest.firstIndex(of: d)!)
            for m in b.moves(p, die: d) {
                var nb = b; nb.apply(m, p)
                if 1 + maxUse(nb, rest, p) == target { res.append(m) }
            }
        }
        if target == 1 && dice.count == 2 && dice[0] != dice[1] {
            let hi = max(dice[0], dice[1])
            if res.contains(where: { $0.die == hi }) { res = res.filter { $0.die == hi } }
        }
        return res
    }

    /// Best full sequence for the computer.
    static func bestSequence(_ b: BGBoard, _ dice: [Int], _ p: Int) -> [BGMove] {
        let target = maxUse(b, dice, p)
        guard target > 0 else { return [] }
        var restrictDie: Int? = nil
        if target == 1 && dice.count == 2 && dice[0] != dice[1] {
            let hi = max(dice[0], dice[1])
            if !b.moves(p, die: hi).isEmpty { restrictDie = hi }
        }
        struct Key: Hashable { var b: BGBoard; var d: [Int] }
        var visited = Set<Key>()
        var bestScore = -Double.infinity
        var best: [BGMove] = []
        func walk(_ b: BGBoard, _ dice: [Int], _ seq: [BGMove]) {
            if seq.count == target {
                let s = evaluate(b, p) + Double.random(in: 0..<0.5)
                if s > bestScore { bestScore = s; best = seq }
                return
            }
            guard visited.insert(Key(b: b, d: dice.sorted())).inserted else { return }
            for d in Set(dice) {
                if seq.isEmpty, let r = restrictDie, d != r { continue }
                var rest = dice; rest.remove(at: rest.firstIndex(of: d)!)
                for m in b.moves(p, die: d) {
                    var nb = b; nb.apply(m, p)
                    walk(nb, rest, seq + [m])
                }
            }
        }
        walk(b, dice, [])
        return best
    }

    static func evaluate(_ b: BGBoard, _ p: Int) -> Double {
        let o = 1 - p
        var s = Double(b.pip(o) - b.pip(p))
        s += Double(b.off[p]) * 2
        s += Double(b.bar[o]) * 8
        for i in 0..<24 {
            let c = b.mine(p, i)
            if c >= 2 { s += b.inHome(p, i) ? 3 : 1.5 }
            if c == 1 {
                // exposed if any opposing checker can still reach it
                var exposed = b.bar[o] > 0 || b.start[o] > 0
                if !exposed {
                    for j in 0..<24 where b.mine(o, j) > 0 {
                        if (o == 0 && j > i) || (o == 1 && j < i) { exposed = true; break }
                    }
                }
                if exposed { s -= 5 }
            }
        }
        return s
    }
}

// MARK: - Game state

@Observable
final class BGGame {
    enum Stage { case opening, needRoll, moving, chooseDouble, over }

    let acey: Bool
    var board: BGBoard
    var turn = 0
    var dice: [Int] = []          // still to play
    var rolled: [Int] = []        // shown on screen
    var stage: Stage = .opening
    var selected: Int? = nil
    var message = ""
    var pendingAceyDouble = false
    var extraRoll = false
    var winner: Int? = nil

    init(acey: Bool) {
        self.acey = acey
        board = acey ? .aceyDeucey() : .backgammon()
    }

    var legal: [BGMove] { stage == .moving ? BGRules.legal(board, dice, turn) : [] }

    func targets(from: Int) -> [BGMove] { legal.filter { $0.from == from } }
}

// MARK: - View

struct BackgammonView: View {
    let seats: [Seat]
    let acey: Bool
    let onFinish: (GameOutcome) -> Void

    @State private var g: BGGame
    @State private var pinkIsMine = true
    @State private var chosen = false

    init(seats: [Seat], acey: Bool, onFinish: @escaping (GameOutcome) -> Void) {
        self.seats = seats; self.acey = acey; self.onFinish = onFinish
        _g = State(initialValue: BGGame(acey: acey))
    }

    private var style: PieceStyle { gameLook.backgammon }
    private func color(_ p: Int) -> Color { (p == 0) == pinkIsMine ? style.a : style.b }
    private func chip(_ p: Int, _ size: CGFloat) -> some View { ChipView(color: color(p), pattern: style.pattern, size: size) }

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                header
                board
                    .padding(.horizontal, 6)
                controls
                Text(g.message).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                Spacer(minLength: 0)
            }
            if !chosen {
                Color.black.opacity(0.25).ignoresSafeArea()
                ColorChoice(pinkIsMine: $pinkIsMine, style: style) { chosen = true; opening() }
            }
        }
    }

    private var header: some View {
        HStack {
            ForEach(0..<2) { p in
                HStack(spacing: 6) {
                    Avatar(look: seats[p].look, size: 34)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(seats[p].name).font(.subheadline.bold())
                        Text("off \(g.board.off[p]) • pips \(g.board.pip(p))").font(.caption2).foregroundStyle(.secondary)
                    }
                    chip(p, 14)
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 10).fill(g.turn == p ? color(p).opacity(0.25) : .clear))
                if p == 0 { Spacer() }
            }
        }
        .padding(.horizontal)
    }

    // MARK: board

    private var board: some View {
        GeometryReader { geo in
            let W = geo.size.width, H = geo.size.height
            let trayW = W * 0.1, barW = W * 0.07
            let pw = (W - trayW - barW) / 12
            let rowH = H * 0.44
            let legalTargets: Set<Int> = Set(g.selected.map { s in g.targets(from: s).map(\.to) } ?? [])
            let sources: Set<Int> = g.turn == 0 ? Set(g.legal.map(\.from)) : []
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.45, green: 0.28, blue: 0.18))
                Rectangle().fill(Color(red: 0.95, green: 0.88, blue: 0.75)).frame(width: W - trayW - 8, height: H - 8).offset(x: 4, y: 4)
                // points
                ForEach(0..<24, id: \.self) { i in
                    let top = i >= 12
                    let col = top ? i - 12 : 11 - i
                    let x = CGFloat(col) * pw + (col >= 6 ? barW : 0)
                    pointView(i, top: top, w: pw, h: rowH, highlight: legalTargets.contains(i), source: sources.contains(i))
                        .offset(x: x, y: top ? 4 : H - rowH - 4)
                }
                // bar
                Rectangle().fill(Color(red: 0.45, green: 0.28, blue: 0.18)).frame(width: barW, height: H).offset(x: 6 * pw)
                barStack(W: barW, H: H, source: sources.contains(BGBoard.fromBar)).offset(x: 6 * pw)
                // tray: off + start
                tray(W: trayW, H: H, legalOff: legalTargets.contains(BGBoard.offBoard), startSource: sources.contains(BGBoard.fromStart))
                    .offset(x: W - trayW)
            }
        }
        .aspectRatio(1.35, contentMode: .fit)
    }

    private func pointView(_ i: Int, top: Bool, w: CGFloat, h: CGFloat, highlight: Bool, source: Bool) -> some View {
        let n = abs(g.board.pts[i])
        let owner = g.board.pts[i] > 0 ? 0 : 1
        let r = min(w * 0.9, h / 5.2)
        return ZStack(alignment: top ? .top : .bottom) {
            Triangle(down: top)
                .fill(i % 2 == 0 ? Color(red: 0.75, green: 0.2, blue: 0.35) : Color(red: 0.3, green: 0.55, blue: 0.45))
                .frame(width: w * 0.92, height: h * 0.95)
            if highlight {
                Triangle(down: top).fill(Color.yellow.opacity(0.55)).frame(width: w * 0.92, height: h * 0.95)
            }
            VStack(spacing: 0) {
                ForEach(0..<min(n, 5), id: \.self) { k in
                    checker(owner, size: r, label: k == (top ? 4 : 0) && n > 5 ? "\(n)" : nil)
                        .overlay(Circle().stroke(g.selected == i && k == (top ? min(n, 5) - 1 : 0) ? Color.yellow : .clear, lineWidth: 3))
                }
            }
            .rotationEffect(.zero)
            .frame(maxHeight: .infinity, alignment: top ? .top : .bottom)
            Text("\(i + 1)")
                .font(.system(size: 7)).foregroundStyle(.secondary)
                .frame(maxHeight: .infinity, alignment: top ? .bottom : .top)
                .opacity(0.6)
        }
        .frame(width: w, height: h)
        .overlay(source ? RoundedRectangle(cornerRadius: 3).stroke(Color.yellow.opacity(0.8), lineWidth: 1.5) : nil)
        .contentShape(Rectangle())
        .onTapGesture { tap(i) }
    }

    private func checker(_ owner: Int, size: CGFloat, label: String? = nil) -> some View {
        chip(owner, size)
            .overlay(label.map { Text($0).font(.system(size: size * 0.45, weight: .bold)).foregroundStyle(.white).shadow(color: .black, radius: 1) })
    }

    private func barStack(W: CGFloat, H: CGFloat, source: Bool) -> some View {
        VStack {
            if g.board.bar[1] > 0 { checker(1, size: W * 0.85, label: "\(g.board.bar[1])") }
            Spacer()
            if g.board.bar[0] > 0 {
                checker(0, size: W * 0.85, label: "\(g.board.bar[0])")
                    .overlay(Circle().stroke(source ? Color.yellow : .clear, lineWidth: 3))
            }
        }
        .padding(.vertical, 8)
        .frame(width: W, height: H)
        .contentShape(Rectangle())
        .onTapGesture { tap(BGBoard.fromBar) }
    }

    private func tray(W: CGFloat, H: CGFloat, legalOff: Bool, startSource: Bool) -> some View {
        VStack(spacing: 4) {
            trayBox(owner: 1, count: g.board.off[1], title: "OFF")
            if acey { trayBox(owner: 1, count: g.board.start[1], title: "START") }
            Spacer()
            if acey {
                trayBox(owner: 0, count: g.board.start[0], title: "START")
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(startSource ? Color.yellow : .clear, lineWidth: 2))
                    .onTapGesture { tap(BGBoard.fromStart) }
            }
            trayBox(owner: 0, count: g.board.off[0], title: "OFF")
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(legalOff ? Color.yellow : .clear, lineWidth: 3))
                .background(legalOff ? Color.yellow.opacity(0.4) : .clear)
                .onTapGesture { tap(BGBoard.offBoard) }
        }
        .padding(4)
        .frame(width: W, height: H)
    }

    private func trayBox(owner: Int, count: Int, title: String) -> some View {
        VStack(spacing: 1) {
            Text(title).font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
            chip(owner, 16)
            Text("\(count)").font(.caption2.bold()).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.25)))
    }

    // MARK: controls

    private var controls: some View {
        HStack(spacing: 10) {
            ForEach(Array(g.rolled.enumerated()), id: \.offset) { _, d in
                DieView(value: d, face: color(g.turn), pip: .white, size: 40)
            }
            if g.dice.count < g.rolled.count || g.rolled.count == 4 {
                Text("left: \(g.dice.map(String.init).joined(separator: " "))").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if g.turn == 0 && g.stage == .needRoll {
                Button("Roll") { roll() }.buttonStyle(.borderedProminent).tint(color(0)).controlSize(.large)
            }
            if g.turn == 0 && g.stage == .chooseDouble {
                Menu("Pick doubles") {
                    ForEach(1...6, id: \.self) { d in Button("Double \(d)s") { pickDouble(d) } }
                }
                .buttonStyle(.borderedProminent).tint(color(0))
            }
        }
        .padding(.horizontal)
        .frame(minHeight: 48)
    }

    // MARK: flow

    private func opening() {
        var a = 0, b = 0
        repeat { a = Int.random(in: 1...6); b = Int.random(in: 1...6) } while a == b
        Sound.shared.play(.dice)
        g.turn = a > b ? 0 : 1
        g.rolled = [a, b]
        g.message = "Opening roll: \(seats[0].name) \(a), \(seats[1].name) \(b). \(seats[g.turn].name) goes first."
        g.dice = [a, b]
        later(1.4) { beginMoving() }
    }

    private func roll() {
        Sound.shared.play(.dice)
        let a = Int.random(in: 1...6), b = Int.random(in: 1...6)
        g.rolled = a == b ? [a, a, a, a] : [a, b]
        g.dice = g.rolled
        g.pendingAceyDouble = acey && Set([a, b]) == [1, 2]
        if g.pendingAceyDouble { g.message = "Acey-deucey! Play the 1 and 2, then pick any doubles and roll again." }
        else { g.message = "" }
        beginMoving()
    }

    private func beginMoving() {
        g.stage = .moving
        g.selected = nil
        if g.legal.isEmpty {
            g.message += (g.message.isEmpty ? "" : " ") + "\(seats[g.turn].name) can't move."
            later(1.2) { endOfDice() }
            return
        }
        if g.turn == 1 { cpuPlay() }
    }

    private func tap(_ i: Int) {
        guard g.turn == 0, g.stage == .moving else { return }
        if let s = g.selected, let m = g.targets(from: s).filter({ $0.to == i }).max(by: { $0.die > $1.die }) {
            make(m)
            return
        }
        if g.legal.contains(where: { $0.from == i }) {
            g.selected = i
            Sound.shared.play(.click)
            // auto-move when there's exactly one destination
            let ts = Set(g.targets(from: i).map(\.to))
            if ts.count == 1, let m = g.targets(from: i).first { make(m) }
        } else {
            g.selected = nil
        }
    }

    private func make(_ m: BGMove) {
        let hit = m.to != BGBoard.offBoard && g.board.theirs(g.turn, m.to) == 1
        g.board.apply(m, g.turn)
        g.dice.remove(at: g.dice.firstIndex(of: m.die)!)
        g.selected = nil
        Sound.shared.play(hit ? .crash : .chip)
        if g.board.off[g.turn] == 15 { win(g.turn); return }
        if g.dice.isEmpty || g.legal.isEmpty { later(g.turn == 0 ? 0.5 : 0.7) { endOfDice() } }
    }

    private func endOfDice() {
        guard g.stage != .over else { return }
        if g.pendingAceyDouble {
            g.pendingAceyDouble = false
            g.stage = .chooseDouble
            g.extraRoll = true
            if g.turn == 1 {
                // computer picks the doubles that score best
                var best = 6, bestS = -Double.infinity
                for d in 1...6 {
                    let seq = BGRules.bestSequence(g.board, [d, d, d, d], 1)
                    var b = g.board; for m in seq { b.apply(m, 1) }
                    let s = BGRules.evaluate(b, 1)
                    if s > bestS { bestS = s; best = d }
                }
                later(0.8) { pickDouble(best) }
            }
            return
        }
        if g.extraRoll {
            g.extraRoll = false
            g.message = "\(seats[g.turn].name) rolls again."
            g.stage = .needRoll
            if g.turn == 1 { later(1) { roll() } }
            return
        }
        g.turn = 1 - g.turn
        g.stage = .needRoll
        g.rolled = []
        g.dice = []
        if g.turn == 1 { later(0.9) { roll() } }
    }

    private func pickDouble(_ d: Int) {
        g.rolled = [d, d, d, d]
        g.dice = g.rolled
        g.message = "\(seats[g.turn].name) takes double \(d)s."
        beginMoving()
    }

    private func cpuPlay() {
        let seq = BGRules.bestSequence(g.board, g.dice, 1)
        func step(_ k: Int) {
            guard g.stage == .moving, g.turn == 1 else { return }
            if k >= seq.count { if !g.dice.isEmpty && !g.legal.isEmpty { cpuPlay() }; return }
            later(0.65) {
                if g.legal.contains(seq[k]) { make(seq[k]); step(k + 1) } else { cpuPlay() }
            }
        }
        step(0)
    }

    private func win(_ p: Int) {
        g.stage = .over
        g.winner = p
        g.message = "\(seats[p].name) bore off all 15!"
        later(1.5) { onFinish(GameOutcome(winner: seats[p].name, humanWon: p == 0)) }
    }
}

struct Triangle: Shape {
    var down: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        if down {
            p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        } else {
            p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        }
        p.closeSubpath()
        return p
    }
}
