import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()
    @State private var muted = Sound.shared.muted

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.95), Color(red: 0.9, green: 1, blue: 0.93)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Group {
                switch model.phase {
                case .title: TitleView(model: model)
                case .cutscene:
                    CutsceneView(shots: model.shots, context: model.sceneContext) { model.cutsceneDone() }
                        .id(model.cutsceneID)
                        .padding(.top, 44)
                case .pickGame: GamePickerView(model: model)
                case .invite: InviteView(model: model)
                case .playing: GameHost(model: model)
                case .results: ResultsView(model: model)
                case .shopping: ShoppingView(model: model)
                case .chooseStyles: ChooseStylesView(model: model)
                }
            }
            Button {
                muted.toggle()
                Sound.shared.muted = muted
            } label: {
                Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .padding(10).background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12).padding(.top, 4)
        }
        #if DEBUG
        .onAppear { debugLaunch() }
        #endif
    }

    #if DEBUG
    /// Launch args for screenshots: -debugShot N (prologue shot), -debugBoard N (boarding shot), -debugGame name
    private func debugLaunch() {
        let d = UserDefaults.standard
        if let story = d.string(forKey: "debugStory") {
            // runs the real flow: afterFirst → day 2 morning; home/ship → night → next morning
            switch story {
            case "afterFirst": model.firstDayDone = false; model.afterResults()
            case "home": model.firstDayDone = true; model.day = 2; model.cash = 400; model.earnedToday = 130; model.spentToday = 30; model.endDay(onShip: false)
            case "ship": model.firstDayDone = true; model.day = 2; model.earnedToday = 130; model.endDay(onShip: true)
            default: break
            }
            return
        }
        if let ps = d.string(forKey: "debugPort"), let port = Port(rawValue: ps) {
            // -debugPort nassau [-debugCustoms YES]: shop there with $600, or buy everything and go through customs
            model.firstDayDone = true; model.day = 3; model.cash = 600
            if d.bool(forKey: "debugCustoms") {
                model.port = port
                for item in Shop.items(port) { model.buy(item) }
                model.leavePort()
            } else {
                model.startExcursion(port)
            }
            return
        }
        if let g = d.string(forKey: "debugInvite"), let k = GameKind(rawValue: g) {
            // -debugInvite connect4 [-debugAutoAsk YES]: at the dock inviting passersby
            model.firstDayDone = true; model.day = 3
            model.choose(k)
            return
        }
        if let names = d.string(forKey: "debugNewStyles") {
            // -debugNewStyles "Sea Glass Chips,Beach Ball Chips": just back from shore with these – pick which to use
            model.firstDayDone = true; model.day = 3
            let list = names.split(separator: ",").map(String.init)
            list.forEach { model.ownedStyleNames.insert($0) }
            model.newStyles = list
            model.applyLooks(); model.save()   // TitleView.onAppear reloads the save after this
            model.phase = .chooseStyles
            return
        }
        if let names = d.string(forKey: "debugStyles") {
            // -debugStyles "Sea Glass Chips,Royal Navy Cards": own + use these styles
            for n in names.split(separator: ",").map(String.init) {
                if let item = Shop.item(named: n), case .game(let slot) = item.kind {
                    model.ownedStyleNames.insert(n); model.styleChoice[slot.rawValue] = n
                }
            }
            model.applyLooks(); model.save()   // TitleView.onAppear reloads the save after this
        }
        if let g = d.string(forKey: "debugGame"), let k = GameKind(rawValue: g) {
            model.firstDayDone = d.bool(forKey: "debugCruise")
            if model.firstDayDone { model.passengers = [Passenger.random(), Passenger.random()].map { var p = $0; p.changed = true; return p } }
            model.game = k
            model.phase = .playing
        } else if d.object(forKey: "debugShot") != nil {
            let all = Story.prologue() + Story.afterFirstGame()
            model.play(Array(all.dropFirst(d.integer(forKey: "debugShot")))) { model.phase = .title }
        } else if d.object(forKey: "debugBoard") != nil {
            let ps = [Passenger.random(), Passenger.random(), Passenger.random()]
            model.sceneContext.passengers = ps
            model.play(Array(Story.boarding(ps, game: "Othello").dropFirst(d.integer(forKey: "debugBoard")))) { model.phase = .title }
        }
    }
    #endif
}

// MARK: - Title

struct TitleView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Games for Girls")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [Palette.pink, .purple], startPoint: .leading, endPoint: .trailing))
                    .padding(.top, 40)
                Canvas { ctx, size in
                    let s = min(size.width / 400, size.height / 200)
                    ctx.translateBy(x: (size.width - 400 * s) / 2, y: 0)
                    ctx.scaleBy(x: s, y: s)
                    drawShip(&ctx, x: 40, waterline: 150, w: 320)
                    ctx.fill(Path(CGRect(x: 0, y: 150, width: 400, height: 50)), with: .color(Color(red: 0.2, green: 0.5, blue: 0.8)))
                }
                .frame(height: 170)
                HStack(spacing: 14) {
                    ForEach(0..<3) { i in
                        Canvas { ctx, size in
                            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: size.width / 2, y: size.height - 4), h: size.height - 10, girl: 1, mood: .happy, arms: .wave)
                        }
                        .frame(width: 70, height: 110)
                    }
                }
                Text("Elmer, Chris and Danny lost their arcade jobs… then a pink cruise ship pulled up.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal)

                if model.hasSave && model.firstDayDone {
                    Button { model.continueGame() } label: {
                        Label("Continue – Day \(model.day)", systemImage: "play.fill").frame(maxWidth: 280)
                    }
                    .buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.large)
                }
                Button { model.newGame() } label: {
                    Label(model.hasSave && model.firstDayDone ? "Start Over" : "New Game", systemImage: "sparkles").frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent).tint(Palette.green).controlSize(.large)

                VStack(spacing: 6) {
                    Text("Play as").font(.headline)
                    Picker("Play as", selection: Binding(get: { model.me }, set: { model.me = $0; model.save() })) {
                        ForEach(0..<3) { Text(girlNames[$0]).tag($0) }
                    }
                    .pickerStyle(.segmented).frame(maxWidth: 320)
                }
                if model.firstDayDone {
                    Text("Cash $\(model.cash) • \(model.transformed) girls changed so far • \(model.cruises) cruises • \(model.wins) wins")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .onAppear { model.load() }
    }
}

// MARK: - Game picker

struct GamePickerView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(model.firstDayDone ? "Day \(model.day) – Pick the Next Game" : "Your First Game Together")
                    .font(.title2.bold()).padding(.top, 50)
                if model.firstDayDone {
                    Text("Cash $\(model.cash) • earned today $\(model.earnedToday)").foregroundStyle(.secondary)
                } else {
                    Text("Ellie, Christina and Deirdre play in the game lounge.").foregroundStyle(.secondary)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(GameKind.allCases) { g in
                        Button { Sound.shared.play(.click); model.choose(g) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Image(systemName: g.icon).font(.title).foregroundStyle(Palette.pink)
                                Text(g.title).font(.headline)
                                Text(g.blurb).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.background))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.pink.opacity(0.4)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                if model.firstDayDone {
                    ExcursionButton(model: model).padding(.top, 6)
                    StyleButton(model: model)
                    Text("Spending money – Ellie $\(model.girlSavings[0]) • Christina $\(model.girlSavings[1]) • Deirdre $\(model.girlSavings[2])")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Boardwalk Bank – Ellie $\(model.girlBank[0]) • Christina $\(model.girlBank[1]) • Deirdre $\(model.girlBank[2])")
                        .font(.caption).foregroundStyle(.secondary)
                    if !model.enhancements.isEmpty || !model.pendingGifts.isEmpty {
                        Text("Ship upgrades: \(model.enhancements.count) • gifts for Mom: \(model.pendingGifts.count)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    EndDayButton(model: model, prominent: false).padding(.top)
                }
                Button("Save & Quit to Title") { model.quitToTitle() }.font(.footnote).padding(.bottom)
            }
        }
    }
}

// MARK: - Boardwalk invitations

/// One person strolling along the dock past the ship.
struct Walker {
    enum Stage: Equatable { case walking, talking, boarding, leaving, gone }
    var person: Passenger
    var stage = Stage.walking
    var x: CGFloat = -30          // where they were when the current stage began
    var y: CGFloat = 0            // 0 = on the walkway, 1 = at the gangway
    var since = Date()
    var accepted = false
}

/// The ship is docked and people stroll past one at a time – at most five per cruise.
/// Tap "Ask" while someone is walking by and one of the girls invites them aboard.
struct InviteView: View {
    let model: AppModel
    static let maxWalkers = 5
    static let speed: CGFloat = 58            // points per second along the dock
    static let lane: CGFloat = 262            // the walkway, in front of the girls
    static let gangwayFoot = CGPoint(x: 58, y: 206)

    @State private var walker: Walker?
    @State private var walkedBy = 0
    @State private var girlLine: (girl: Int, text: String)?
    @State private var answer: String?
    @State private var asker = 0
    @State private var loop: Task<Void, Never>?

    private var acceptChance: Double {
        let base: Double = switch model.fee { case ..<15: 0.85; case ..<25: 0.6; default: 0.35 }
        return min(0.95, base + model.acceptBonus)
    }
    private var full: Bool { model.passengers.count >= 4 }
    private var done: Bool { walker == nil && (walkedBy >= Self.maxWalkers || full) }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("At the Dock – Invite Passersby").font(.title2.bold()).padding(.top, 50)
                Text("Next game: \(model.game?.title ?? "")").foregroundStyle(.secondary)
                HStack {
                    Text("Cruise fee")
                    Picker("Fee", selection: Binding(get: { model.fee }, set: { model.fee = $0 })) {
                        Text("$10").tag(10); Text("$20").tag(20); Text("$30").tag(30)
                    }
                    .pickerStyle(.segmented).frame(maxWidth: 220)
                    .disabled(walkedBy > 0)
                }
                dock
                    .aspectRatio(400 / 300, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                controls
                Text(model.tipPerPassenger > 0
                     ? "Up to \(Self.maxWalkers) people walk by each cruise and up to 4 can come aboard. Higher fees mean more people say no. Ship upgrades add $\(model.tipPerPassenger) in tips per passenger."
                     : "Up to \(Self.maxWalkers) people walk by each cruise and up to 4 can come aboard. Higher fees mean more people say no.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)

                Text("Passengers: \(model.passengers.count) × $\(model.fee) = $\(model.passengers.count * model.fee)").font(.headline)
                if !model.passengers.isEmpty {
                    Text(model.passengers.map(\.boyName).joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary)
                }
                Button {
                    loop?.cancel()
                    Sound.shared.stopSpeaking()
                    model.setSail()
                } label: {
                    Label("Set Sail", systemImage: "ferry.fill").frame(maxWidth: 260)
                }
                .buttonStyle(.borderedProminent).tint(Palette.green).controlSize(.large)
                .disabled(model.passengers.isEmpty || walker?.stage == .talking || walker?.stage == .boarding)
                Button("Pick a different game") {
                    loop?.cancel()
                    Sound.shared.stopSpeaking()
                    model.passengers = []; model.phase = .pickGame
                }
                .font(.footnote).padding(.bottom)
            }
        }
        .onAppear { if walkedBy == 0 && walker == nil { nextWalker(after: 0.8) } }
        .onDisappear { loop?.cancel() }
    }

    @ViewBuilder private var controls: some View {
        if let w = walker, w.stage == .walking {
            Button { ask() } label: {
                Label("Ask \(w.person.boyName) aboard!", systemImage: "hand.wave.fill").frame(maxWidth: 260)
            }
            .buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.large)
        } else if done {
            Text(full ? "The ship is full – time to set sail!"
                 : model.passengers.isEmpty ? "That's all \(Self.maxWalkers) passersby, and nobody came aboard."
                 : "That's all \(Self.maxWalkers) passersby for this cruise – time to set sail!")
                .font(.headline).foregroundStyle(Palette.pink).multilineTextAlignment(.center)
        } else {
            Text(walker == nil ? "Watch for the next passerby…" : " ").font(.headline).foregroundStyle(.secondary)
        }
        Text("Passersby: \(walkedBy) of \(Self.maxWalkers)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
    }

    // MARK: the dock scene

    private var dock: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let k = size.width / 400
                ctx.scaleBy(x: k, y: k)
                draw(&ctx, now: tl.date)
            }
        }
    }

    private func position(_ w: Walker, _ now: Date) -> CGPoint {
        let dt = CGFloat(now.timeIntervalSince(w.since))
        switch w.stage {
        case .walking, .leaving:
            return CGPoint(x: w.x + Self.speed * dt, y: Self.lane)
        case .talking, .gone:
            return CGPoint(x: w.x, y: Self.lane)
        case .boarding:
            // over to the gangway, then up it onto the ship
            let walk = min(1, dt / 1.6)
            let up = max(0, min(1, (dt - 1.6) / 1.2))
            let foot = CGPoint(x: w.x + (Self.gangwayFoot.x - w.x) * walk, y: Self.lane + (Self.gangwayFoot.y - Self.lane) * walk)
            return CGPoint(x: foot.x + 28 * up, y: foot.y - 70 * up)
        }
    }

    private func draw(_ ctx: inout GraphicsContext, now: Date) {
        let size = CGSize(width: 400, height: 300)
        let t = now.timeIntervalSinceReferenceDate
        // sky, sea, ship
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(colors: [Color(red: 0.45, green: 0.75, blue: 1), Color(red: 0.8, green: 0.92, blue: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: 150)))
        ctx.fill(Path(ellipseIn: CGRect(x: 340, y: 18, width: 30, height: 30)), with: .color(.yellow))
        ctx.fill(Path(CGRect(x: 0, y: 110, width: 400, height: 80)), with: .color(Color(red: 0.2, green: 0.55, blue: 0.85)))
        for i in 0..<8 {
            let wx = CGFloat((Double(i) * 53 + t * 12).truncatingRemainder(dividingBy: 420)) - 10
            ctx.draw(Text("~").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.6)), at: CGPoint(x: wx, y: 170 + CGFloat(i % 3) * 6))
        }
        drawShip(&ctx, x: 40, waterline: 160, w: 250, gangway: true)
        // the dock
        ctx.fill(Path(CGRect(x: 0, y: 190, width: 400, height: 110)), with: .color(Color(red: 0.78, green: 0.6, blue: 0.4)))
        for i in 0..<9 {
            ctx.fill(Path(CGRect(x: 0, y: 196 + CGFloat(i) * 12, width: 400, height: 1)), with: .color(Color(red: 0.6, green: 0.44, blue: 0.28)))
        }
        for x in stride(from: 10.0, through: 400, by: 70) {
            ctx.fill(Path(roundedRect: CGRect(x: x, y: 182, width: 8, height: 14), cornerRadius: 2), with: .color(Color(red: 0.5, green: 0.35, blue: 0.2)))
        }
        // the girls by the gangway, the one asking waves
        for i in 0..<3 {
            let talking = girlLine?.girl == i
            drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: 100 + CGFloat(i) * 32, y: 214), h: 70, girl: 1,
                       mood: .happy, arms: talking ? .wave : .down, facing: 1)
        }
        // passengers already waiting on deck
        for (i, ps) in model.passengers.enumerated() where walker?.person.id != ps.id || walker?.stage == .gone {
            drawPerson(&ctx, look: ps.look, feet: CGPoint(x: 110 + CGFloat(i) * 22, y: 122), h: 40, girl: 0, mood: .happy)
        }
        // the passerby
        if let w = walker, w.stage != .gone {
            let p = position(w, now)
            let moving = w.stage != .talking
            let bob = moving ? CGFloat(abs(sin(t * 9))) * 3 : 0
            let facing: CGFloat = w.stage == .boarding || w.stage == .talking ? -1 : 1
            let mood: Mood = answer == nil ? .neutral : (w.accepted ? .happy : .sad)
            let h: CGFloat = w.stage == .boarding ? 84 - 30 * max(0, min(1, CGFloat(now.timeIntervalSince(w.since)) - 1.6) / 1.2) : 84
            drawPerson(&ctx, look: w.person.look, feet: p, h: h, girl: 0, mood: mood,
                       arms: w.accepted && w.stage == .talking ? .wave : .down, facing: facing, bob: -bob)
            if w.stage == .walking {
                ctx.draw(Text(w.person.boyName).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.white),
                         at: CGPoint(x: p.x, y: p.y + 12))
            }
            if let answer, w.stage == .talking {
                bubble(&ctx, answer, at: CGPoint(x: min(300, p.x + 100), y: p.y - 50), tint: .white)
            }
        }
        if let g = girlLine {
            bubble(&ctx, g.text, at: CGPoint(x: 150, y: 110), tint: Color(red: 1, green: 0.88, blue: 0.95))
        }
    }

    private func bubble(_ ctx: inout GraphicsContext, _ text: String, at c: CGPoint, tint: Color) {
        let r = CGRect(x: c.x - 95, y: c.y - 22, width: 190, height: 44)
        ctx.fill(Path(roundedRect: r, cornerRadius: 10), with: .color(tint))
        ctx.stroke(Path(roundedRect: r, cornerRadius: 10), with: .color(.black.opacity(0.25)), lineWidth: 1)
        ctx.draw(Text(text).font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundStyle(.black),
                 in: r.insetBy(dx: 7, dy: 4))
    }

    // MARK: flow

    private func nextWalker(after delay: Double) {
        loop?.cancel()
        guard walkedBy < Self.maxWalkers, !full else { walker = nil; return }
        loop = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            var names = Set(model.passengers.map(\.boyName))
            if let w = walker { names.insert(w.person.boyName) }
            walkedBy += 1
            answer = nil
            girlLine = nil
            walker = Walker(person: Passenger.random(excluding: names), x: -30, since: Date())
            Sound.shared.play(.click)
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "debugAutoAsk") {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                ask(); return
            }
            #endif
            // nobody asked them? They stroll right on past.
            try? await Task.sleep(for: .seconds(Double((430 + 30) / Self.speed)))
            guard !Task.isCancelled, walker?.stage == .walking else { return }
            walker?.stage = .gone
            nextWalker(after: 1.0)
        }
    }

    private func ask() {
        guard var w = walker, w.stage == .walking else { return }
        loop?.cancel()
        w.x = position(w, Date()).x
        w.stage = .talking
        w.since = Date()
        walker = w
        let game = model.game?.title ?? "games"
        let girl = asker
        asker = (asker + 1) % 3
        let ask = [
            "Hi \(w.person.boyName)! Come play \(game) on our pink cruise ship – only $\(model.fee)!",
            "Excuse me! Want to come on a games cruise? Today it's \(game), just $\(model.fee)!",
            "Hey! We've got room on the ship for \(game). It's $\(model.fee) – come aboard!",
        ][girl]
        girlLine = (girl, ask)
        Sound.shared.play(.click)
        let yes = Double.random(in: 0..<1) < acceptChance
        let reply = yes
            ? ["Sure, a cruise with \(game)? I'm in!", "Sounds fun! Here's my $\(model.fee).", "A pink cruise ship? Why not!", "Okay, I'll come along."].randomElement()!
            : ["No thanks, $\(model.fee) is too much.", "Games for girls? No way!", "I'm busy, sorry.", "Maybe tomorrow."].randomElement()!
        loop = Task { @MainActor in
            Sound.shared.say(ask, as: .girl)
            try? await Task.sleep(for: .seconds(Sound.shared.muted ? 1.6 : 1.2 + Double(ask.count) * 0.055))
            guard !Task.isCancelled else { return }
            answer = reply
            walker?.accepted = yes
            Sound.shared.say(reply, as: .boy)
            if yes { Sound.shared.play(.coin) }
            try? await Task.sleep(for: .seconds(Sound.shared.muted ? 1.6 : 1.0 + Double(reply.count) * 0.055))
            guard !Task.isCancelled, var cur = walker else { return }
            girlLine = nil
            cur.x = position(cur, Date()).x
            cur.since = Date()
            if yes {
                cur.stage = .boarding
                walker = cur
                try? await Task.sleep(for: .seconds(2.9))
                guard !Task.isCancelled else { return }
                model.passengers.append(cur.person)
                walker?.stage = .gone
                answer = nil
                nextWalker(after: 0.8)
            } else {
                cur.stage = .leaving
                walker = cur
                answer = nil
                try? await Task.sleep(for: .seconds(Double(max(0, 430 - cur.x) / Self.speed)))
                guard !Task.isCancelled else { return }
                walker?.stage = .gone
                nextWalker(after: 1.0)
            }
        }
    }
}

// MARK: - Game host

struct GameHost: View {
    let model: AppModel
    @State private var seats: [Seat] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { model.finish(GameOutcome(winner: seats.dropFirst().first?.name ?? "", humanWon: false)) } label: {
                    Label("Quit", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                Spacer()
                Text(model.game?.title ?? "").font(.headline)
                Spacer()
            }
            .padding(.horizontal).padding(.top, 6).padding(.trailing, 50)
            if !seats.isEmpty {
                Group {
                    switch model.game {
                    case .backgammon: BackgammonView(seats: seats, acey: false, onFinish: model.finish)
                    case .aceyDeucey: BackgammonView(seats: seats, acey: true, onFinish: model.finish)
                    case .othello: OthelloView(seats: seats, onFinish: model.finish)
                    case .callIt: CallItView(seats: seats, onFinish: model.finish)
                    case .obsession: ObsessionView(seats: seats, onFinish: model.finish)
                    case .starTrek: StarTrekView(seats: seats, onFinish: model.finish)
                    case .connect4: Connect4View(seats: seats, onFinish: model.finish)
                    case .alleyCat: AlleyCatView(seats: seats, onFinish: model.finish)
                    case .rummy500: Rummy500View(seats: seats, onFinish: model.finish)
                    case .ninetyNine: NinetyNineView(seats: seats, onFinish: model.finish)
                    case .crazyEights: CrazyEightsView(seats: seats, onFinish: model.finish)
                    case .imOut: ImOutView(seats: seats, onFinish: model.finish)
                    case nil: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { seats = model.seats() }
    }
}

// MARK: - Shore excursions

struct ExcursionButton: View {
    let model: AppModel
    @State private var asking = false

    var body: some View {
        Button { asking = true } label: {
            Label(model.canExcursion ? "Shore Excursion" : "Shore excursion done for today", systemImage: "map.fill").frame(maxWidth: 260)
        }
        .buttonStyle(.borderedProminent).tint(.teal)
        .disabled(!model.canExcursion)
        .confirmationDialog("Where should the ship sail? Shop for ship upgrades and gifts for Mom.", isPresented: $asking, titleVisibility: .visible) {
            ForEach(Port.allCases) { p in
                Button("\(p.title), \(p.place)") { model.startExcursion(p) }
            }
            Button("Not now", role: .cancel) {}
        }
    }
}

struct StyleButton: View {
    let model: AppModel
    @State private var open = false

    var body: some View {
        Button { open = true } label: { Label("Game Styles", systemImage: "paintpalette.fill").frame(maxWidth: 260) }
            .buttonStyle(.bordered).tint(.purple)
            .sheet(isPresented: $open) { StyleClosetView(model: model) }
    }
}

// MARK: - End of day

/// Ends the day: go home to the girls' bedrooms, or (from night 2 on) stay aboard in the ship's cabins.
struct EndDayButton: View {
    let model: AppModel
    var prominent: Bool
    @State private var asking = false

    var body: some View {
        Group {
            if prominent {
                Button { asking = true } label: { Label("End the Day", systemImage: "moon.stars.fill").frame(maxWidth: 260) }
                    .buttonStyle(.borderedProminent).tint(.purple).controlSize(.large)
            } else {
                Button("End the Day") { asking = true }.buttonStyle(.bordered)
            }
        }
        .confirmationDialog("Where will the girls sleep tonight?", isPresented: $asking, titleVisibility: .visible) {
            Button("Go home to our bedrooms") { model.endDay(onShip: false) }
            Button("Spend the night on the cruise ship") { model.endDay(onShip: true) }
            Button("Not yet", role: .cancel) {}
        }
    }
}

// MARK: - Results

struct ResultsView: View {
    let model: AppModel

    var body: some View {
        let o = model.lastOutcome
        ScrollView {
            VStack(spacing: 16) {
                Text(o?.humanWon == true ? "You Win!" : "\(o?.winner ?? "They") Wins!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(o?.humanWon == true ? Palette.pink : .purple)
                    .padding(.top, 60)
                Canvas { ctx, size in
                    let s = min(size.width / 400, size.height / 260)
                    ctx.translateBy(x: (size.width - 400 * s) / 2, y: 0)
                    ctx.scaleBy(x: s, y: s)
                    drawGameLounge(&ctx, CGSize(width: 400, height: 260))
                    var looks = Cast.kids
                    if model.firstDayDone { looks += model.passengers.map(\.look) }
                    let n = min(7, looks.count)
                    for (i, l) in looks.prefix(7).enumerated() {
                        let x = 50 + CGFloat(i) * (300 / CGFloat(max(1, n - 1)))
                        drawPerson(&ctx, look: l, feet: CGPoint(x: x, y: 235), h: 95, girl: 1, mood: .happy, arms: i % 2 == 0 ? .up : .wave)
                    }
                }
                .aspectRatio(400 / 260, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                if model.firstDayDone {
                    Text("This cruise earned $\(model.lastCruiseEarned)\(o?.humanWon == true ? " (incl. $\(model.winBonus) winner's bonus)" : "")")
                    Text("Today $\(model.earnedToday) • Bank $\(model.cash)").foregroundStyle(.secondary)
                    Button { model.afterResults() } label: { Label("Another Cruise", systemImage: "ferry").frame(maxWidth: 260) }
                        .buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.large)
                    EndDayButton(model: model, prominent: true)
                } else {
                    Button { model.afterResults() } label: { Label("Continue", systemImage: "arrow.right").frame(maxWidth: 260) }
                        .buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.large)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
