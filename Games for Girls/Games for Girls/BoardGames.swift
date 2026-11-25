import SwiftUI

// MARK: - Othello

struct OthelloView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    /// 0 empty, 1 = you (black), 2 = opponent (white)
    @State private var cells = OthelloView.initial()
    @State private var turn = 1
    @State private var message = "You play black and move first."
    @State private var over = false
    @State private var lastMove: Int? = nil

    static func initial() -> [Int] {
        var c = [Int](repeating: 0, count: 64)
        c[27] = 2; c[36] = 2; c[28] = 1; c[35] = 1
        return c
    }

    static let dirs = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

    static func flips(_ c: [Int], _ i: Int, _ p: Int) -> [Int] {
        guard c[i] == 0 else { return [] }
        let r = i / 8, col = i % 8
        var all: [Int] = []
        for (dr, dc) in dirs {
            var line: [Int] = []
            var rr = r + dr, cc = col + dc
            while (0..<8).contains(rr) && (0..<8).contains(cc) && c[rr * 8 + cc] == 3 - p {
                line.append(rr * 8 + cc); rr += dr; cc += dc
            }
            if !line.isEmpty && (0..<8).contains(rr) && (0..<8).contains(cc) && c[rr * 8 + cc] == p { all += line }
        }
        return all
    }

    static func moves(_ c: [Int], _ p: Int) -> [Int] { (0..<64).filter { !flips(c, $0, p).isEmpty } }

    private var count1: Int { cells.filter { $0 == 1 }.count }
    private var count2: Int { cells.filter { $0 == 2 }.count }

    var body: some View {
        let legal = turn == 1 && !over ? Set(Self.moves(cells, 1)) : []
        VStack(spacing: 10) {
            HStack {
                score(seats[0], count1, .black, turn == 1)
                Spacer()
                score(seats[1], count2, .white, turn == 2)
            }
            .padding(.horizontal)
            GeometryReader { geo in
                let s = geo.size.width / 8
                ZStack(alignment: .topLeading) {
                    Rectangle().fill(Color(red: 0.1, green: 0.55, blue: 0.3))
                    ForEach(0..<64, id: \.self) { i in
                        ZStack {
                            Rectangle().stroke(Color.black.opacity(0.5), lineWidth: 1)
                            if cells[i] != 0 {
                                Circle().fill(cells[i] == 1 ? Color.black : Color.white)
                                    .overlay(Circle().stroke(Color.black.opacity(0.3)))
                                    .padding(s * 0.1)
                                    .transition(.scale)
                            } else if legal.contains(i) {
                                Circle().fill(Color.black.opacity(0.18)).padding(s * 0.36)
                            }
                            if lastMove == i { Circle().fill(Palette.pink).frame(width: 6, height: 6) }
                        }
                        .frame(width: s, height: s)
                        .contentShape(Rectangle())
                        .onTapGesture { if legal.contains(i) { place(i, 1) } }
                        .offset(x: CGFloat(i % 8) * s, y: CGFloat(i / 8) * s)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal)
            Text(message).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Spacer(minLength: 0)
        }
    }

    private func score(_ s: Seat, _ n: Int, _ c: Color, _ active: Bool) -> some View {
        HStack(spacing: 6) {
            Avatar(look: s.look, size: 34)
            Circle().fill(c).overlay(Circle().stroke(Color.gray)).frame(width: 18, height: 18)
            Text("\(s.name)  \(n)").font(.headline)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(active ? Palette.pink.opacity(0.25) : .clear))
    }

    private func place(_ i: Int, _ p: Int) {
        let f = Self.flips(cells, i, p)
        guard !f.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            cells[i] = p
            for k in f { cells[k] = p }
        }
        lastMove = i
        Sound.shared.play(.flip)
        next(after: p)
    }

    private func next(after p: Int) {
        let o = 3 - p
        if !Self.moves(cells, o).isEmpty {
            turn = o
            message = o == 1 ? "Your move." : "\(seats[1].name) is thinking…"
            if o == 2 { later(0.8) { cpu() } }
        } else if !Self.moves(cells, p).isEmpty {
            turn = p
            message = "\(o == 1 ? "You have" : seats[1].name + " has") no move – pass."
            if p == 2 { later(1.0) { cpu() } }
        } else {
            over = true
            let a = count1, b = count2
            message = "Game over: \(a) – \(b)"
            let humanWon = a > b
            later(1.6) { onFinish(GameOutcome(winner: humanWon ? seats[0].name : (a == b ? "Nobody" : seats[1].name), humanWon: humanWon)) }
        }
    }

    private static let weights: [Int] = [
        100, -20, 10, 5, 5, 10, -20, 100,
        -20, -50, -2, -2, -2, -2, -50, -20,
        10, -2, 1, 1, 1, 1, -2, 10,
        5, -2, 1, 0, 0, 1, -2, 5,
        5, -2, 1, 0, 0, 1, -2, 5,
        10, -2, 1, 1, 1, 1, -2, 10,
        -20, -50, -2, -2, -2, -2, -50, -20,
        100, -20, 10, 5, 5, 10, -20, 100,
    ]

    private func cpu() {
        let ms = Self.moves(cells, 2)
        guard !ms.isEmpty else { return }
        let best = ms.max { a, b in
            let sa = Self.weights[a] + Self.flips(cells, a, 2).count * 2 - Self.moves(after(a), 1).count
            let sb = Self.weights[b] + Self.flips(cells, b, 2).count * 2 - Self.moves(after(b), 1).count
            return sa < sb
        }!
        place(best, 2)
    }

    private func after(_ i: Int) -> [Int] {
        var c = cells
        for k in Self.flips(c, i, 2) { c[k] = 2 }
        c[i] = 2
        return c
    }
}

// MARK: - Connect 4

struct Connect4View: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    static let cols = 7, rows = 6
    /// grid[col][row], row 0 = bottom. 0 empty, 1 you, 2 opponent
    @State private var grid = [[Int]](repeating: [Int](repeating: 0, count: 6), count: 7)
    @State private var turn = 1
    @State private var pinkIsMine = true
    @State private var chosen = false
    @State private var winLine: [(Int, Int)] = []
    @State private var message = ""
    @State private var over = false

    private var style: PieceStyle { gameLook.connect4 }
    private func color(_ p: Int) -> Color { (p == 1) == pinkIsMine ? style.a : style.b }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                HStack {
                    tag(seats[0], 1)
                    Spacer()
                    tag(seats[1], 2)
                }
                .padding(.horizontal)
                GeometryReader { geo in
                    let s = geo.size.width / 7
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.95, green: 0.85, blue: 0.2))
                        ForEach(0..<7, id: \.self) { c in
                            ForEach(0..<6, id: \.self) { r in
                                let v = grid[c][r]
                                let won = winLine.contains { $0 == (c, r) }
                                Group {
                                    if v == 0 { Circle().fill(Color.white) } else { ChipView(color: color(v), pattern: style.pattern, size: s * 0.84) }
                                }
                                .overlay(Circle().stroke(won ? Color.black : Color.black.opacity(0.2), lineWidth: won ? 4 : 1))
                                .padding(s * 0.08)
                                    .frame(width: s, height: s)
                                    .offset(x: CGFloat(c) * s, y: CGFloat(5 - r) * s)
                            }
                            Rectangle().fill(Color.clear).contentShape(Rectangle())
                                .frame(width: s, height: s * 6)
                                .offset(x: CGFloat(c) * s)
                                .onTapGesture { if turn == 1 && !over && chosen { drop(c, 1) } }
                        }
                    }
                }
                .aspectRatio(7.0 / 6.0, contentMode: .fit)
                .padding(.horizontal)
                Text(message).font(.callout).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            if !chosen {
                Color.black.opacity(0.25).ignoresSafeArea()
                ColorChoice(pinkIsMine: $pinkIsMine, style: style) { chosen = true; message = "Tap a column to drop your chip." }
            }
        }
    }

    private func tag(_ s: Seat, _ p: Int) -> some View {
        HStack(spacing: 6) {
            Avatar(look: s.look, size: 34)
            ChipView(color: color(p), pattern: style.pattern, size: 18)
            Text(s.name).font(.headline)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(turn == p ? color(p).opacity(0.25) : .clear))
    }

    private func drop(_ c: Int, _ p: Int) {
        guard let r = grid[c].firstIndex(of: 0) else { return }
        withAnimation(.spring(duration: 0.3)) { grid[c][r] = p }
        Sound.shared.play(.drop)
        if let line = Self.winning(grid, c, r, p) {
            winLine = line
            over = true
            message = p == 1 ? "Four in a row – you win!" : "\(seats[1].name) got four in a row!"
            later(1.8) { onFinish(GameOutcome(winner: p == 1 ? seats[0].name : seats[1].name, humanWon: p == 1)) }
            return
        }
        if grid.allSatisfy({ !$0.contains(0) }) {
            over = true
            message = "Board full – it's a draw."
            later(1.8) { onFinish(GameOutcome(winner: "Nobody", humanWon: false)) }
            return
        }
        turn = 3 - p
        if turn == 2 {
            message = "\(seats[1].name) is thinking…"
            later(0.7) { drop(Self.bestColumn(grid), 2) }
        } else {
            message = "Your turn."
        }
    }

    static func winning(_ g: [[Int]], _ c: Int, _ r: Int, _ p: Int) -> [(Int, Int)]? {
        for (dc, dr) in [(1, 0), (0, 1), (1, 1), (1, -1)] {
            var line = [(c, r)]
            for s in [1, -1] {
                var cc = c + dc * s, rr = r + dr * s
                while (0..<7).contains(cc) && (0..<6).contains(rr) && g[cc][rr] == p {
                    line.append((cc, rr)); cc += dc * s; rr += dr * s
                }
            }
            if line.count >= 4 { return line }
        }
        return nil
    }

    static func bestColumn(_ g: [[Int]]) -> Int {
        let order = [3, 2, 4, 1, 5, 0, 6]
        var best = order.first { g[$0].contains(0) } ?? 3
        var bestScore = Int.min
        for c in order where g[c].contains(0) {
            var ng = g
            let r = ng[c].firstIndex(of: 0)!
            ng[c][r] = 2
            let s = winning(ng, c, r, 2) != nil ? 100000 : -negamax(ng, depth: 4, p: 1, alpha: -1_000_000, beta: 1_000_000)
            if s > bestScore { bestScore = s; best = c }
        }
        return best
    }

    /// score from p's point of view
    static func negamax(_ g: [[Int]], depth: Int, p: Int, alpha: Int, beta: Int) -> Int {
        if depth == 0 { return evaluate(g, p) }
        var a = alpha
        var any = false
        for c in [3, 2, 4, 1, 5, 0, 6] where g[c].contains(0) {
            any = true
            var ng = g
            let r = ng[c].firstIndex(of: 0)!
            ng[c][r] = p
            let s = winning(ng, c, r, p) != nil ? 10000 + depth : -negamax(ng, depth: depth - 1, p: 3 - p, alpha: -beta, beta: -a)
            a = max(a, s)
            if a >= beta { break }
        }
        return any ? a : 0
    }

    static func evaluate(_ g: [[Int]], _ p: Int) -> Int {
        var s = 0
        for c in 0..<7 { for r in 0..<6 {
            for (dc, dr) in [(1, 0), (0, 1), (1, 1), (1, -1)] {
                let ec = c + dc * 3, er = r + dr * 3
                guard (0..<7).contains(ec), (0..<6).contains(er) else { continue }
                var mine = 0, theirs = 0
                for k in 0..<4 {
                    let v = g[c + dc * k][r + dr * k]
                    if v == p { mine += 1 } else if v != 0 { theirs += 1 }
                }
                if theirs == 0 { s += [0, 1, 5, 40, 0][mine] }
                if mine == 0 { s -= [0, 1, 6, 50, 0][theirs] }
            }
        } }
        for r in 0..<6 { if g[3][r] == p { s += 3 } }
        return s
    }
}
