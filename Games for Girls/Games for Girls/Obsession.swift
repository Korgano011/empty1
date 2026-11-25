import SwiftUI

/// Obsession – each player has 10 rings on slides numbered 1–10.
/// Roll two dice; use each die or their sum to slide your matching ring up, or push an opponent's "up" ring back down.
/// Rings still up when your next turn begins move into your Safety Zone. Keep rolling until a roll gives no move.
struct ObsessionView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    enum Ring: Equatable { case down, up, safe }
    enum Stage { case needRoll, choosing, over }

    @State private var rings: [[Ring]] = Array(repeating: Array(repeating: .down, count: 10), count: 2)
    @State private var turn = 0
    @State private var stage: Stage = .needRoll
    @State private var d1 = 1
    @State private var d2 = 1
    @State private var left: [Int] = []          // dice numbers still unused this roll
    @State private var usedSum = false
    @State private var pickNumber: Int? = nil     // number waiting for a raise-vs-push choice
    @State private var message = "Roll the dice. Use each die – or the sum – to slide rings."
    @State private var started = false

    private let colors: [Color] = [Palette.pink, Palette.green]

    var body: some View {
        VStack(spacing: 10) {
            slides(1)
            HStack(spacing: 14) {
                DieView(value: d1, size: 46)
                DieView(value: d2, size: 46)
                VStack(spacing: 6) {
                    Text(seats[turn].name + (seats[turn].human ? " (you)" : "")).font(.headline).foregroundStyle(colors[turn])
                    if seats[turn].human { humanControls }
                }
                .frame(minWidth: 150)
            }
            .frame(minHeight: 70)
            slides(0)
            Text(message).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .onAppear {
            guard !started else { return }
            started = true
            // highest roll goes first
            var a = 0, b = 0
            repeat { a = Int.random(in: 2...12); b = Int.random(in: 2...12) } while a == b
            turn = a > b ? 0 : 1
            message = "Opening roll \(a) to \(b): \(seats[turn].name) goes first."
            if turn == 1 { later(1.4) { roll() } }
        }
    }

    private func slides(_ p: Int) -> some View {
        VStack(spacing: 4) {
            HStack {
                Avatar(look: seats[p].look, size: 30)
                Text(seats[p].name).font(.subheadline.bold())
                Spacer()
                Text("up \(rings[p].filter { $0 == .up }.count) • safe \(rings[p].filter { $0 == .safe }.count)").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 3) {
                ForEach(0..<10, id: \.self) { k in slide(p, k) }
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.95)))
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(turn == p ? colors[p].opacity(0.2) : .clear))
    }

    private func slide(_ p: Int, _ k: Int) -> some View {
        let state = rings[p][k]
        return VStack(spacing: 0) {
            // safety zone at top, then up, then down
            ZStack {
                Rectangle().fill(Color.yellow.opacity(0.3))
                if state == .safe { ring(p) }
            }
            .frame(height: 30)
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 4, height: 34)
                if state == .up { ring(p) }
            }
            ZStack {
                Rectangle().fill(Color.gray.opacity(0.5)).frame(width: 4, height: 34)
                if state == .down { ring(p) }
            }
            Text("\(k + 1)").font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .background(highlight(p, k + 1) ? Color.yellow.opacity(0.5) : Color.clear)
        .onTapGesture { tapRing(p, k + 1) }
    }

    private func tapRing(_ p: Int, _ n: Int) {
        guard highlight(p, n) else { return }
        make(n, push: p != turn)
    }

    private func ring(_ p: Int) -> some View {
        Circle().stroke(colors[p], lineWidth: 4).frame(width: 22, height: 22)
    }

    private func highlight(_ p: Int, _ n: Int) -> Bool {
        guard let pickNumber, n == pickNumber else { return false }
        return (p == turn && rings[p][n - 1] == .down) || (p != turn && rings[p][n - 1] == .up)
    }

    @ViewBuilder private var humanControls: some View {
        switch stage {
        case .needRoll:
            Button("Roll") { roll() }.buttonStyle(.borderedProminent).tint(colors[turn]).controlSize(.large)
        case .choosing:
            if let n = pickNumber {
                VStack(spacing: 6) {
                    Text("Use \(n):").font(.caption.bold())
                    if rings[turn][n - 1] == .down {
                        Button("Raise my \(n)") { make(n, push: false) }.buttonStyle(.borderedProminent).tint(colors[turn])
                    }
                    if rings[1 - turn][n - 1] == .up {
                        Button("Push down their \(n)") { make(n, push: true) }.buttonStyle(.borderedProminent).tint(colors[1 - turn])
                    }
                    Button("Back") { pickNumber = nil }.font(.caption)
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(numberChoices().enumerated()), id: \.offset) { _, c in
                        Button(c.label) { choose(c.n, sum: c.sum) }.buttonStyle(.bordered).tint(colors[turn])
                    }
                }
            }
        case .over:
            EmptyView()
        }
    }

    // MARK: rules

    private func canUse(_ n: Int, _ p: Int) -> Bool {
        guard (1...10).contains(n) else { return false }
        return rings[p][n - 1] == .down || rings[1 - p][n - 1] == .up
    }

    private struct Choice { var n: Int; var sum: Bool; var label: String }

    private func numberChoices() -> [Choice] {
        var res: [Choice] = []
        let p = turn
        for n in left where canUse(n, p) && !res.contains(where: { $0.n == n && !$0.sum }) {
            res.append(Choice(n: n, sum: false, label: "Use die \(n)"))
        }
        if left.count == 2 && !usedSum, canUse(d1 + d2, p) {
            res.append(Choice(n: d1 + d2, sum: true, label: "Use sum \(d1 + d2)"))
        }
        return res
    }

    private func roll() {
        Sound.shared.play(.dice)
        d1 = .random(in: 1...6); d2 = .random(in: 1...6)
        left = [d1, d2]
        usedSum = false
        pickNumber = nil
        let p = turn
        let anyMove = canUse(d1, p) || canUse(d2, p) || canUse(d1 + d2, p)
        if !anyMove {
            // forced to pull a safe ring back out?
            let safeHit = [d1, d2, d1 + d2].first { (1...10).contains($0) && rings[p][$0 - 1] == .safe }
            if let n = safeHit {
                rings[p][n - 1] = .up
                message = "\(seats[p].name) rolled \(d1)+\(d2) with no other move – ring \(n) is pulled out of the Safety Zone!"
                Sound.shared.play(.lose)
            } else {
                message = "\(seats[p].name) rolled \(d1)+\(d2) – no move. Turn over."
            }
            stage = .choosing
            left = []
            later(1.6) { endTurn() }
            return
        }
        stage = .choosing
        message = "\(seats[p].name) rolled \(d1) and \(d2)."
        if !seats[p].human { later(0.9) { cpuStep() } }
    }

    private func choose(_ n: Int, sum: Bool) {
        Sound.shared.play(.click)
        if sum { usedSum = true; left = [n]; pendingSum = true } else { pendingSum = false }
        let p = turn
        let canRaise = rings[p][n - 1] == .down
        let canPush = rings[1 - p][n - 1] == .up
        if canRaise && canPush { pickNumber = n } else { make(n, push: canPush) }
    }

    @State private var pendingSum = false

    private func make(_ n: Int, push: Bool) {
        let p = turn
        if push {
            rings[1 - p][n - 1] = .down
            Sound.shared.play(.crash)
        } else {
            rings[p][n - 1] = .up
            Sound.shared.play(.chip)
        }
        pickNumber = nil
        if let i = left.firstIndex(of: n) { left.remove(at: i) }
        if pendingSum { left = []; pendingSum = false }
        if rings[p].allSatisfy({ $0 != .down }) {
            stage = .over
            message = "\(seats[p].name) has all 10 rings up!"
            Sound.shared.play(.win)
            later(1.6) { onFinish(GameOutcome(winner: seats[p].name, humanWon: seats[p].human)) }
            return
        }
        // remaining die usable?
        if let r = left.first, canUse(r, p) {
            if !seats[p].human { later(0.8) { cpuStep() } }
            return
        }
        left = []
        // roll again
        stage = .needRoll
        if !seats[p].human { later(0.9) { roll() } } else { message = "Roll again!" }
    }

    private func endTurn() {
        guard stage != .over else { return }
        turn = 1 - turn
        // rings left up since this player's last turn are now safe
        for k in 0..<10 where rings[turn][k] == .up { rings[turn][k] = .safe }
        stage = .needRoll
        left = []
        if !seats[turn].human { later(0.9) { roll() } } else { message = "Your turn – roll!" }
    }

    // MARK: computer

    private func cpuStep() {
        guard stage == .choosing else { return }
        let p = turn
        let opts = numberChoices()
        guard !opts.isEmpty else {
            left = []; stage = .needRoll; later(0.6) { roll() }; return
        }
        // prefer two single dice (two moves) over the sum; prefer pushing an opponent ring down
        var best = opts[0], bestScore = -100.0
        for o in opts {
            var s = 0.0
            if rings[1 - p][o.n - 1] == .up { s += 2.2 }
            if rings[p][o.n - 1] == .down { s += 2 }
            if o.sum { s -= 1.5 }
            s += Double.random(in: 0..<0.3)
            if s > bestScore { bestScore = s; best = o }
        }
        if best.sum { usedSum = true; left = [best.n]; pendingSum = true } else { pendingSum = false }
        let push = rings[1 - p][best.n - 1] == .up
        make(best.n, push: push)
    }
}
