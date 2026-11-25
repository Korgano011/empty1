import SwiftUI

/// Call It – call your shot, then roll two dice whose pips are red or black.
enum DiceCall: Int, CaseIterable, Identifiable {
    case advance = 1, advanceRed, advanceBlack, setback, setbackRed, setbackBlack, split, doubles
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .advance: "Advance"
        case .advanceRed: "Advance Red"
        case .advanceBlack: "Advance Black"
        case .setback: "Setback"
        case .setbackRed: "Setback Red"
        case .setbackBlack: "Setback Black"
        case .split: "Split"
        case .doubles: "Doubles"
        }
    }

    var rule: String {
        switch self {
        case .advance: "If dice are both red or both black, advance by total."
        case .advanceRed: "Advance by red total only."
        case .advanceBlack: "Advance by black total only."
        case .setback: "Set back a player of your choice by total if both dice are red or both black."
        case .setbackRed: "Set back a player of your choice by red total."
        case .setbackBlack: "Set back a player of your choice by black total."
        case .split: "If one die is red and the other black, advance one number and set back another player by the other number."
        case .doubles: "Doubles: advance fifteen spaces, and set back another player by fifteen spaces."
        }
    }

    var isSetback: Bool { [.setback, .setbackRed, .setbackBlack].contains(self) }
}

struct CDie { var value: Int; var red: Bool }

struct CallItView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    static let finish = 40

    enum Stage { case call, rolled, chooseSplit, chooseTarget, over }

    @State private var pos: [Int] = []
    @State private var turn = 0
    @State private var call: DiceCall? = nil
    @State private var dice: [CDie] = [CDie(value: 5, red: false), CDie(value: 6, red: true)]
    @State private var stage: Stage = .call
    @State private var advanceBy = 0
    @State private var setbackBy = 0
    @State private var log: [String] = []
    @State private var showChart = false

    private let pawnColors: [Color] = [Palette.pink, Palette.green, .purple, .orange, .blue]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                track
                diceRow
                controls
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.suffix(5).enumerated()), id: \.offset) { _, l in
                        Text(l).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                Button("Chart of Dice Calls") { showChart = true }.font(.footnote)
            }
            .padding(.vertical, 8)
        }
        .onAppear {
            if pos.isEmpty {
                pos = Array(repeating: 0, count: seats.count)
                log = ["First to space \(Self.finish) wins. Call your shot before rolling!"]
            }
        }
        .sheet(isPresented: $showChart) { chart }
    }

    // MARK: pieces

    private var track: some View {
        VStack(spacing: 6) {
            ForEach(seats.indices, id: \.self) { i in
                HStack(spacing: 6) {
                    Avatar(look: seats[i].look, size: 30)
                    Text(seats[i].name).font(.caption.bold()).frame(width: 70, alignment: .leading).lineLimit(1)
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.8, green: 0.15, blue: 0.15))
                            HStack(spacing: 0) {
                                ForEach(0..<Self.finish, id: \.self) { k in
                                    Rectangle().fill(k % 5 == 4 ? Color.black.opacity(0.35) : Color.white.opacity(0.15)).frame(width: 1)
                                    Spacer(minLength: 0)
                                }
                            }
                            Text("🏁").font(.caption).offset(x: w - 16)
                            Circle().fill(pawnColors[i % 5])
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .frame(width: 20, height: 20)
                                .offset(x: CGFloat(min(pos.count > i ? pos[i] : 0, Self.finish)) / CGFloat(Self.finish) * (w - 20))
                                .animation(.easeInOut(duration: 0.5), value: pos)
                        }
                    }
                    .frame(height: 24)
                    Text("\(pos.count > i ? pos[i] : 0)").font(.caption.monospacedDigit()).frame(width: 24)
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 8).fill(turn == i ? Palette.pink.opacity(0.2) : .clear))
            }
        }
        .padding(.horizontal)
    }

    private var diceRow: some View {
        HStack(spacing: 16) {
            ForEach(0..<2, id: \.self) { k in
                DieView(value: dice[k].value, face: .white, pip: dice[k].red ? .red : .black, size: 54)
            }
            if let call {
                VStack(alignment: .leading) {
                    Text("\(seats[turn].name) called").font(.caption).foregroundStyle(.secondary)
                    Text(call.title).font(.headline).foregroundStyle(Palette.pink)
                }
            }
        }
    }

    @ViewBuilder private var controls: some View {
        let human = seats[turn].human
        switch stage {
        case .call where human:
            VStack(spacing: 6) {
                Text("Call your shot:").font(.subheadline.bold())
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 6) {
                    ForEach(DiceCall.allCases) { c in
                        Button { call = c; Sound.shared.play(.click) } label: {
                            Text("\(c.rawValue). \(c.title)").font(.callout).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(call == c ? Palette.pink : .gray)
                    }
                }
                if let call { Text(call.rule).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                Button("Roll") { roll() }.buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.large).disabled(call == nil)
            }
            .padding(.horizontal)
        case .chooseSplit where human:
            VStack {
                Text("Split! Which number moves you forward?").font(.subheadline.bold())
                HStack {
                    ForEach(0..<2, id: \.self) { k in
                        Button("Advance \(dice[k].value), set back \(dice[1 - k].value)") {
                            advanceBy = dice[k].value; setbackBy = dice[1 - k].value; afterSplit()
                        }
                        .buttonStyle(.borderedProminent).tint(Palette.pink)
                    }
                }
            }
        case .chooseTarget where human:
            VStack {
                Text("Set back who by \(setbackBy)?").font(.subheadline.bold())
                HStack {
                    ForEach(seats.indices.filter { $0 != turn }, id: \.self) { i in
                        Button(seats[i].name) { applySetback(i) }.buttonStyle(.borderedProminent).tint(pawnColors[i % 5])
                    }
                }
            }
        case .over:
            EmptyView()
        default:
            if !human { Text("\(seats[turn].name) is calling…").font(.callout).foregroundStyle(.secondary) }
        }
    }

    private var chart: some View {
        NavigationStack {
            List(DiceCall.allCases) { c in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(c.rawValue). \(c.title.uppercased())").font(.headline)
                    Text(c.rule).font(.callout)
                    HStack(spacing: 4) {
                        ForEach(Array(example(c).enumerated()), id: \.offset) { _, ex in
                            DieView(value: ex.0.value, pip: ex.0.red ? .red : .black, size: 22)
                            DieView(value: ex.1.value, pip: ex.1.red ? .red : .black, size: 22)
                            Text("= \(ex.2)").font(.caption).padding(.trailing, 8)
                        }
                    }
                }
            }
            .navigationTitle("Chart of Dice Calls")
            .toolbar { Button("Done") { showChart = false } }
        }
    }

    private func example(_ c: DiceCall) -> [(CDie, CDie, String)] {
        let r = { (v: Int) in CDie(value: v, red: true) }, b = { (v: Int) in CDie(value: v, red: false) }
        switch c {
        case .advance: return [(b(5), b(4), "9"), (r(1), r(5), "6"), (b(5), r(2), "0")]
        case .advanceRed: return [(r(3), r(4), "7"), (b(2), r(5), "5"), (b(4), b(5), "0")]
        case .advanceBlack: return [(b(3), b(4), "7"), (b(5), r(5), "5"), (r(5), r(2), "0")]
        case .setback: return [(b(3), b(4), "7"), (r(6), r(5), "11"), (b(3), r(2), "0")]
        case .setbackRed: return [(r(4), r(5), "9"), (b(3), r(3), "3"), (b(4), b(3), "0")]
        case .setbackBlack: return [(b(5), b(4), "9"), (r(5), b(2), "2"), (r(4), r(3), "0")]
        case .split: return [(b(3), r(5), "3, 5"), (b(4), b(2), "0")]
        case .doubles: return [(b(2), r(2), "15"), (b(3), b(4), "0")]
        }
    }

    // MARK: play

    private func roll() {
        guard let call else { return }
        Sound.shared.play(.dice)
        dice = [CDie(value: .random(in: 1...6), red: .random()), CDie(value: .random(in: 1...6), red: .random())]
        let same = dice[0].red == dice[1].red
        let total = dice[0].value + dice[1].value
        let red = dice.filter(\.red).map(\.value).reduce(0, +)
        let black = dice.filter { !$0.red }.map(\.value).reduce(0, +)
        advanceBy = 0; setbackBy = 0
        switch call {
        case .advance: advanceBy = same ? total : 0
        case .advanceRed: advanceBy = red
        case .advanceBlack: advanceBy = black
        case .setback: setbackBy = same ? total : 0
        case .setbackRed: setbackBy = red
        case .setbackBlack: setbackBy = black
        case .split:
            if !same {
                stage = .chooseSplit
                if !seats[turn].human {
                    let hi = max(dice[0].value, dice[1].value), lo = min(dice[0].value, dice[1].value)
                    advanceBy = hi; setbackBy = lo
                    later(1.0) { afterSplit() }
                }
                return
            }
        case .doubles:
            if dice[0].value == dice[1].value { advanceBy = 15; setbackBy = 15 }
        }
        resolve()
    }

    private func afterSplit() { resolve() }

    private func resolve() {
        let me = seats[turn].name
        let colorText = dice.map { "\($0.red ? "red" : "black") \($0.value)" }.joined(separator: " + ")
        if advanceBy == 0 && setbackBy == 0 {
            log.append("\(me) called \(call!.title), rolled \(colorText) – no move.")
            stage = .rolled
            later(1.4) { nextTurn() }
            return
        }
        if advanceBy > 0 {
            pos[turn] = min(Self.finish, pos[turn] + advanceBy)
            log.append("\(me) called \(call!.title), rolled \(colorText) – advances \(advanceBy).")
            Sound.shared.play(.chip)
            if pos[turn] >= Self.finish { win(turn); return }
        }
        if setbackBy > 0 {
            let others = seats.indices.filter { $0 != turn }
            if others.count == 1 || !seats[turn].human {
                // computer picks the player closest to winning
                let target = others.max { pos[$0] < pos[$1] }!
                stage = .chooseTarget
                later(seats[turn].human ? 0.4 : 1.0) { applySetback(target) }
            } else {
                stage = .chooseTarget
            }
            return
        }
        stage = .rolled
        later(1.3) { nextTurn() }
    }

    private func applySetback(_ i: Int) {
        guard stage == .chooseTarget else { return }
        pos[i] = max(0, pos[i] - setbackBy)
        log.append("\(seats[turn].name) sets back \(seats[i].name) by \(setbackBy).")
        Sound.shared.play(.crash)
        stage = .rolled
        later(1.3) { nextTurn() }
    }

    private func nextTurn() {
        guard stage != .over else { return }
        turn = (turn + 1) % seats.count
        call = nil
        stage = .call
        if !seats[turn].human { later(0.9) { cpuCall() } }
    }

    private func cpuCall() {
        let mine = pos[turn]
        let leader = seats.indices.filter { $0 != turn }.map { pos[$0] }.max() ?? 0
        let threatened = leader >= Self.finish - 12 || leader > mine + 8
        let choice: DiceCall
        if threatened {
            choice = [.setback, .setbackRed, .setbackBlack, .split, .doubles, .split].randomElement()!
        } else if mine >= Self.finish - 15 && Int.random(in: 0..<3) == 0 {
            choice = .doubles
        } else {
            choice = [.advance, .advanceRed, .advanceBlack, .split, .advanceRed, .advanceBlack].randomElement()!
        }
        call = choice
        log.append("\(seats[turn].name) calls \(choice.title)…")
        later(0.9) { roll() }
    }

    private func win(_ i: Int) {
        stage = .over
        log.append("\(seats[i].name) reaches the finish!")
        later(1.6) { onFinish(GameOutcome(winner: seats[i].name, humanWon: seats[i].human)) }
    }
}
