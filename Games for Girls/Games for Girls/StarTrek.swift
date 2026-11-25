import SwiftUI

/// Star Trek Game – two starships race around a ring of 20 space sectors.
/// Beam an officer down to planets to complete missions (Captain Kathryn Janeway, Lieutenant Dax, Dr. Beverly Crusher),
/// survive Klingons, Romulans and ion storms. First to complete 3 missions and get back to Starbase wins.
struct StarTrekView: View {
    let seats: [Seat]
    let onFinish: (GameOutcome) -> Void

    enum Sector: Equatable {
        case starbase, empty, wormhole, ionStorm, klingon, romulan
        case planet(String, Kind)
        enum Kind { case science, medical, diplomatic }

        var icon: String {
            switch self {
            case .starbase: "🛰️"
            case .empty: "✦"
            case .wormhole: "🌀"
            case .ionStorm: "⚡️"
            case .klingon: "🦅"
            case .romulan: "🐦"
            case .planet(_, let k): k == .science ? "🪐" : (k == .medical ? "🌍" : "🌕")
            }
        }
        var name: String {
            switch self {
            case .starbase: "Starbase"
            case .empty: "Deep Space"
            case .wormhole: "Wormhole"
            case .ionStorm: "Ion Storm"
            case .klingon: "Klingon Patrol"
            case .romulan: "Romulan Warbird"
            case .planet(let n, _): n
            }
        }
    }

    enum Officer: Int, CaseIterable { case janeway, dax, crusher
        var name: String { ["Captain Kathryn Janeway", "Lieutenant Dax", "Dr. Beverly Crusher"][rawValue] }
        var short: String { ["Janeway", "Dax", "Crusher"][rawValue] }
        func bonus(_ k: Sector.Kind) -> Int {
            switch (self, k) {
            case (.janeway, .diplomatic), (.dax, .science), (.crusher, .medical): 3
            case (.janeway, _): 1
            default: 0
            }
        }
        var look: Look {
            switch self {
            case .janeway: Look(skin: Palette.skins[0], hair: [0.55, 0.3, 0.15], shirt: [0, 0, 0], pants: [0, 0, 0], dress: [0.75, 0.1, 0.1], girlHair: .bob, kid: false, woman: true)
            case .dax: Look(skin: Palette.skins[4], hair: [0.12, 0.08, 0.06], shirt: [0, 0, 0], pants: [0, 0, 0], dress: [0.15, 0.5, 0.6], girlHair: .ponytail, kid: false, woman: true)
            case .crusher: Look(skin: Palette.skins[0], hair: [0.8, 0.3, 0.1], shirt: [0, 0, 0], pants: [0, 0, 0], dress: [0.15, 0.5, 0.6], girlHair: .long, kid: false, woman: true)
            }
        }
    }

    static let ring: [Sector] = [
        .starbase, .planet("Vulcan", .diplomatic), .empty, .klingon, .planet("Bajor", .science), .ionStorm,
        .planet("Risa", .medical), .wormhole, .romulan, .planet("Talos IV", .science), .empty,
        .planet("Earth Colony", .diplomatic), .klingon, .ionStorm, .planet("Ocampa", .medical), .romulan,
        .planet("Trill", .science), .wormhole, .planet("Andoria", .diplomatic), .empty,
    ]

    enum Stage { case needRoll, moving, pickOfficer, over }

    @State private var pos = [0, 0]
    @State private var missions = [0, 0]
    @State private var done: [Set<Int>] = [[], []]
    @State private var damage = [0, 0]
    @State private var skip = [false, false]
    @State private var lastOfficer: [Officer?] = [nil, nil]
    @State private var turn = 0
    @State private var stage: Stage = .needRoll
    @State private var die = 1
    @State private var message = "Roll to fly. Complete 3 missions, then return to Starbase."
    @State private var log: [String] = []

    private let shipColor: [Color] = [Palette.pink, Palette.green]
    private var shipName: [String] { ["U.S.S. Voyager", "U.S.S. Pegasus"] }
    static let goal = 3

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    shipCard(0)
                    Spacer()
                    shipCard(1)
                }
                .padding(.horizontal)
                boardRing
                    .frame(height: 300)
                    .padding(.horizontal)
                controls
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.suffix(4).enumerated()), id: \.offset) { _, l in
                        Text(l).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
            }
            .padding(.vertical, 6)
        }
    }

    private func shipCard(_ p: Int) -> some View {
        VStack(alignment: p == 0 ? .leading : .trailing, spacing: 2) {
            HStack {
                Avatar(look: seats[p].look, size: 30)
                Text(seats[p].name).font(.subheadline.bold())
            }
            Text(shipName[p]).font(.caption).foregroundStyle(shipColor[p])
            Text("Missions \(missions[p])/\(Self.goal) • Damage \(damage[p])/3").font(.caption2)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(turn == p ? shipColor[p].opacity(0.2) : .clear))
    }

    private var boardRing: some View {
        GeometryReader { geo in
            let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let rx = geo.size.width / 2 - 24, ry = geo.size.height / 2 - 22
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color(red: 0.03, green: 0.03, blue: 0.12))
                Canvas { ctx, size in
                    for k in 0..<60 {
                        let x = CGFloat((k * 73) % 997) / 997 * size.width, y = CGFloat((k * 151) % 991) / 991 * size.height
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(.white.opacity(0.7)))
                    }
                }
                ForEach(0..<Self.ring.count, id: \.self) { i in
                    let a = Double(i) / Double(Self.ring.count) * 2 * .pi - .pi / 2
                    let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rx, y: c.y + CGFloat(sin(a)) * ry)
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12)).frame(width: 38, height: 38)
                        Text(Self.ring[i].icon).font(.system(size: 18))
                        if done[0].contains(i) { Circle().fill(shipColor[0]).frame(width: 7, height: 7).offset(x: -13, y: 13) }
                        if done[1].contains(i) { Circle().fill(shipColor[1]).frame(width: 7, height: 7).offset(x: 13, y: 13) }
                    }
                    .position(pt)
                }
                ForEach(0..<2, id: \.self) { p in
                    let a = Double(pos[p]) / Double(Self.ring.count) * 2 * .pi - .pi / 2
                    let off: CGFloat = p == 0 ? -0.78 : -0.62
                    Image(systemName: "airplane")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(shipColor[p])
                        .rotationEffect(.radians(a + .pi))
                        .position(x: c.x + CGFloat(cos(a)) * rx * (1 + off * 0.35), y: c.y + CGFloat(sin(a)) * ry * (1 + off * 0.35))
                        .animation(.easeInOut(duration: 0.4), value: pos)
                }
                VStack(spacing: 6) {
                    Text(Self.ring[pos[turn]].name).font(.headline).foregroundStyle(.white)
                    Text(message).font(.caption).foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center)
                        .frame(maxWidth: geo.size.width * 0.55)
                    DieView(value: die, face: shipColor[turn], pip: .white, size: 36)
                }
            }
        }
    }

    @ViewBuilder private var controls: some View {
        if seats[turn].human {
            switch stage {
            case .needRoll:
                Button("Roll & Fly") { roll() }.buttonStyle(.borderedProminent).tint(shipColor[0]).controlSize(.large)
            case .pickOfficer:
                if case .planet(let name, let kind) = Self.ring[pos[turn]] {
                    VStack(spacing: 6) {
                        Text("Who beams down to \(name)?").font(.subheadline.bold())
                        HStack(spacing: 10) {
                            ForEach(Officer.allCases, id: \.rawValue) { o in
                                Button { beamDown(o) } label: {
                                    VStack(spacing: 2) {
                                        officerPortrait(o)
                                        Text(o.short).font(.caption.bold())
                                        Text("+\(o.bonus(kind))").font(.caption2)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(lastOfficer[turn] == o)
                            }
                        }
                        Text("Need 6+ on die + bonus. The same officer can't go twice in a row.").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            default: EmptyView()
            }
        } else {
            Text(stage == .over ? "" : "\(seats[turn].name) is on the bridge…").font(.callout).foregroundStyle(.secondary)
        }
        HStack(spacing: 12) {
            ForEach(Officer.allCases, id: \.rawValue) { o in
                VStack(spacing: 2) {
                    officerPortrait(o)
                    Text(o.name).font(.system(size: 9)).multilineTextAlignment(.center).frame(width: 90)
                }
            }
        }
        .padding(.top, 4)
    }

    private func officerPortrait(_ o: Officer) -> some View {
        Canvas { ctx, size in
            drawBust(ctx, size: size, look: o.look, mood: .happy)
            if o == .dax {
                // Trill spots down both sides of the face
                for s in [-1.0, 1.0] {
                    for k in 0..<4 {
                        let x = size.width / 2 + CGFloat(s) * size.height * 0.21
                        let y = size.height * 0.36 + CGFloat(k) * size.height * 0.05
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 1.3, y: y, width: 2.6, height: 2.6)), with: .color(Color(red: 0.45, green: 0.3, blue: 0.2)))
                    }
                }
            }
            // combadge
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.6, y: size.height * 0.78, width: 6, height: 4)), with: .color(.yellow))
        }
        .frame(width: 46, height: 46)
        .background(Circle().fill(Color.white))
        .clipShape(Circle())
    }

    // MARK: play

    private func roll() {
        guard stage == .needRoll else { return }
        let p = turn
        if skip[p] {
            skip[p] = false
            message = "\(shipName[p]) is still under repair – turn lost."
            later(1.4) { nextTurn() }
            stage = .moving
            return
        }
        stage = .moving
        die = .random(in: 1...6)
        Sound.shared.play(.dice)
        let start = pos[p]
        let steps = die
        func hop(_ k: Int) {
            if k > steps { arrive(passedStarbase: start + steps >= Self.ring.count); return }
            pos[p] = (start + k) % Self.ring.count
            Sound.shared.play(.click)
            later(0.25) { hop(k + 1) }
        }
        later(0.4) { hop(1) }
    }

    private func arrive(passedStarbase: Bool) {
        let p = turn
        if passedStarbase && missions[p] >= Self.goal { win(p); return }
        resolve(Self.ring[pos[p]])
    }

    private func resolve(_ s: Sector) {
        let p = turn
        let who = seats[p].name
        switch s {
        case .starbase:
            damage[p] = 0
            message = "Starbase: \(shipName[p]) is fully repaired."
            log.append("\(who) docks at Starbase for repairs.")
            if missions[p] >= Self.goal { win(p); return }
            later(1.3) { nextTurn() }
        case .empty:
            message = "Quiet sector. Nothing to report."
            later(1.0) { nextTurn() }
        case .wormhole:
            let jump = Int.random(in: 2...7)
            message = "Wormhole! Flung \(jump) sectors ahead."
            Sound.shared.play(.sparkle)
            let wrapped = pos[p] + jump >= Self.ring.count
            later(1.2) {
                pos[p] = (pos[p] + jump) % Self.ring.count
                if wrapped && missions[p] >= Self.goal { win(p); return }
                later(0.6) { resolve(Self.ring[pos[p]]) }
            }
        case .ionStorm:
            let r = Int.random(in: 1...6)
            let bonus = 2 // Lieutenant Dax at science
            if r + bonus >= 5 {
                message = "Ion storm! Lt. Dax plots a course through (\(r)+\(bonus))."
            } else {
                message = "Ion storm! Rolled \(r)+\(bonus) – the ship takes damage."
                hit(p)
            }
            log.append("\(who): \(message)")
            later(1.6) { nextTurn() }
        case .klingon, .romulan:
            let mine = Int.random(in: 1...6) + 1 // Captain Janeway's command
            let theirs = Int.random(in: 1...6) + (s == .romulan ? 2 : 1)
            Sound.shared.play(.crash)
            if mine >= theirs {
                message = "\(s.name)! Captain Janeway outfights them \(mine) to \(theirs)."
            } else {
                message = "\(s.name)! Lost the battle \(mine) to \(theirs) – damage taken."
                hit(p)
            }
            log.append("\(who): \(message)")
            later(1.6) { nextTurn() }
        case .planet(let name, let kind):
            if done[p].contains(pos[p]) {
                message = "\(name): mission already complete here."
                later(1.1) { nextTurn() }
                return
            }
            message = "Orbiting \(name) – a \(kindName(kind)) mission."
            stage = .pickOfficer
            if !seats[p].human {
                let pick = Officer.allCases.filter { $0 != lastOfficer[p] }.max { $0.bonus(kind) < $1.bonus(kind) }!
                later(1.2) { beamDown(pick) }
            }
        }
    }

    private func kindName(_ k: Sector.Kind) -> String {
        switch k { case .science: "science"; case .medical: "medical"; case .diplomatic: "diplomatic" }
    }

    private func beamDown(_ o: Officer) {
        guard stage == .pickOfficer, case .planet(let name, let kind) = Self.ring[pos[turn]] else { return }
        let p = turn
        lastOfficer[p] = o
        let r = Int.random(in: 1...6)
        let total = r + o.bonus(kind)
        Sound.shared.play(.sparkle)
        die = r
        if total >= 6 {
            missions[p] += 1
            done[p].insert(pos[p])
            message = "\(o.short) beams down to \(name): \(r)+\(o.bonus(kind)) = \(total). Mission complete!"
            Sound.shared.play(.coin)
        } else {
            message = "\(o.short) beams down to \(name): \(r)+\(o.bonus(kind)) = \(total). Mission failed."
        }
        log.append("\(seats[p].name): \(message)")
        if missions[p] >= Self.goal { message += " Head back to Starbase!" }
        stage = .moving
        later(1.8) { nextTurn() }
    }

    private func hit(_ p: Int) {
        damage[p] += 1
        if damage[p] >= 3 {
            damage[p] = 0
            pos[p] = 0
            skip[p] = true
            message += " Ship disabled! Towed back to Starbase and loses a turn."
            Sound.shared.play(.lose)
        }
    }

    private func nextTurn() {
        guard stage != .over else { return }
        turn = 1 - turn
        stage = .needRoll
        if !seats[turn].human { later(0.9) { roll() } }
    }

    private func win(_ p: Int) {
        stage = .over
        message = "\(shipName[p]) returns to Starbase with \(missions[p]) missions complete!"
        later(1.8) { onFinish(GameOutcome(winner: seats[p].name, humanWon: seats[p].human)) }
    }
}
