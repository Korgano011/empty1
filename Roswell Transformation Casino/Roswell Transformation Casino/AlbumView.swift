import SwiftUI

private enum AlbumRoute: Hashable {
    case entry(UUID)
    case game(UUID)
}

/// The family's before-and-after photos, then every casino game, newest first.
struct AlbumView: View {
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var pendingEntry: AlbumEntry?
    @State private var pendingGame: GameRecord?
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationStack {
            Group {
                if album.entries.isEmpty && album.games.isEmpty {
                    ContentUnavailableView("No Photos Yet", systemImage: "photo.on.rectangle.angled",
                                           description: Text("Each time someone in the family becomes a Roswell alien, their before-and-after photo lands here."))
                } else {
                    List {
                        if !album.entries.isEmpty {
                            Section("The Family") {
                                ForEach(album.entries) { entry in
                                    HStack {
                                        NavigationLink(value: AlbumRoute.entry(entry.id)) {
                                            EntryRow(entry: entry)
                                        }
                                        trash("Delete this photo") { pendingEntry = entry }
                                    }
                                    .swipeActions {
                                        Button("Delete", systemImage: "trash", role: .destructive) { album.delete(entry.id) }
                                    }
                                }
                            }
                        }
                        if !album.games.isEmpty {
                            Section("\(CasinoGame.casinoName) Tables") {
                                ForEach(album.games) { game in
                                    HStack {
                                        NavigationLink(value: AlbumRoute.game(game.id)) {
                                            GameRow(game: game)
                                        }
                                        trash("Delete this game") { pendingGame = game }
                                    }
                                    .swipeActions {
                                        Button("Delete", systemImage: "trash", role: .destructive) { album.deleteGame(game.id) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Photo Album")
            .navigationDestination(for: AlbumRoute.self) { route in
                switch route {
                case .entry(let id):
                    if let entry = album.entries.first(where: { $0.id == id }) {
                        EntryDetailView(entry: entry, album: album)
                    }
                case .game(let id):
                    GameDetailView(gameID: id, album: album)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete All", systemImage: "trash", role: .destructive) { confirmDeleteAll = true }
                        .disabled(album.entries.isEmpty && album.games.isEmpty)
                }
            }
            .confirmationDialog("Delete this photo?", isPresented: Binding(get: { pendingEntry != nil }, set: { if !$0 { pendingEntry = nil } }),
                                presenting: pendingEntry) { entry in
                Button("Delete \(entry.spec.name)'s photo", role: .destructive) { album.delete(entry.id) }
            } message: { entry in
                Text("\(entry.spec.name), \(entry.date.formatted(date: .abbreviated, time: .shortened)). This can't be undone.")
            }
            .confirmationDialog("Delete every photo?", isPresented: $confirmDeleteAll) {
                Button("Delete All Photos", role: .destructive) { album.deleteAll() }
            } message: {
                let players = album.games.reduce(0) { $0 + $1.players.count }
                Text("\(album.entries.count) family photo\(album.entries.count == 1 ? "" : "s") and \(album.games.count) game\(album.games.count == 1 ? "" : "s") with \(players) player photo\(players == 1 ? "" : "s") will be removed. This can't be undone.")
            }
            .confirmationDialog("Delete this game?", isPresented: Binding(get: { pendingGame != nil }, set: { if !$0 { pendingGame = nil } }),
                                presenting: pendingGame) { game in
                Button("Delete \(game.game.name) game", role: .destructive) { album.deleteGame(game.id) }
            } message: { game in
                Text("\(game.game.name), \(game.date.formatted(date: .abbreviated, time: .shortened)), with all \(game.players.count) player photos. This can't be undone.")
            }
        }
        #if os(macOS)
        .frame(minWidth: 540, minHeight: 600)
        #endif
    }

    private func trash(_ help: String, _ action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}

private struct EntryRow: View {
    let entry: AlbumEntry

    var body: some View {
        HStack(spacing: 10) {
            Portrait(spec: entry.spec, after: false)
            Image(systemName: "arrow.right").font(.caption.bold()).foregroundStyle(.secondary)
            Portrait(spec: entry.spec, after: true)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.spec.name).font(.system(.headline, design: .rounded))
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text("Human → \((entry.spec.alienColor ?? .green).name) Roswell alien")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.leading, 6)
        }
        .padding(.vertical, 4)
    }
}

/// One photo pair, large.
struct EntryDetailView: View {
    let entry: AlbumEntry
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    Portrait(spec: entry.spec, after: false, width: 150, height: 250)
                    Image(systemName: "arrow.right").font(.title3.bold()).foregroundStyle(.secondary)
                    Portrait(spec: entry.spec, after: true, width: 150, height: 250)
                }
                Text(entry.date.formatted(date: .complete, time: .shortened))
                    .font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
                Button("Delete This Photo", systemImage: "trash", role: .destructive) { confirmDelete = true }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(entry.spec.name)
        .confirmationDialog("Delete this photo?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                album.delete(entry.id)
                dismiss()
            }
        } message: {
            Text("\(entry.spec.name)'s before-and-after photo will be removed. This can't be undone.")
        }
    }
}

/// One photo, drawn with the same code as the stage and framed on the head and shoulders.
struct Portrait: View {
    let spec: PersonSpec
    let after: Bool
    var width = 70.0
    var height = 96.0

    var body: some View {
        Canvas { ctx, size in
            let p = spec.person(after: after)
            let pose = Pose(p, feet: .zero, facing: 0, now: .now, still: true)
            // Frame from just above the head to the waist.
            let top = pose.headTop - pose.hr * 0.5
            let bottom = pose.torso.maxY
            let scale = min(size.height * 0.92 / (bottom - top), size.width * 0.9 / (pose.hr * 3))
            var c = ctx
            c.translateBy(x: size.width / 2, y: size.height * 0.1 - top * scale)
            c.scaleBy(x: scale, y: scale)
            drawPerson(c, p, feet: .zero, facing: 0, now: .distantPast)
        }
        .frame(width: width, height: height)
        .background(after
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.12, green: 0.08, blue: 0.30), Color(red: 0.35, green: 0.75, blue: 0.45)],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(white: 0.88)),
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .top) {
            Text(after ? "AFTER" : "BEFORE")
                .font(.system(size: width > 100 ? 13 : 9, weight: .heavy, design: .rounded))
                .foregroundStyle(after ? .white.opacity(0.9) : .black.opacity(0.55))
                .padding(.top, 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}

private struct GameRow: View {
    let game: GameRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: game.game.icon)
                .font(.title2)
                .foregroundStyle(game.game.accent)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(game.game.name).font(.system(.headline, design: .rounded))
                Text(game.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(game.players.count) \(game.players.count == 1 ? "became an alien" : "became aliens") · \(game.asked) asked")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(game.profit >= 0 ? "+$\(game.profit)" : "-$\(-game.profit)")
                .font(.system(.headline, design: .rounded).monospacedDigit())
                .foregroundStyle(game.profit >= 0 ? .green : .red)
            HStack(spacing: -18) {
                ForEach(Array(game.players.prefix(4).enumerated()), id: \.offset) { _, player in
                    Portrait(spec: player.spec, after: true, width: 40, height: 54)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// One game: every player's before-and-after photo, each deletable on its own.
struct GameDetailView: View {
    let gameID: GameRecord.ID
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var pendingPlayer: Int?

    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 12)]

    var body: some View {
        if let game = album.games.first(where: { $0.id == gameID }) {
            ScrollView {
                VStack(spacing: 16) {
                    Label(game.date.formatted(date: .complete, time: .shortened), systemImage: game.game.icon)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Text("Asked \(game.asked) \(game.asked == 1 ? "woman" : "women") · \(game.players.count) \(game.players.count == 1 ? "became an alien" : "became aliens") and played")
                        .font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
                    GameReceipt(game: game)
                        .frame(maxWidth: 340)

                    if game.players.isEmpty {
                        Text("No player photos.").foregroundStyle(.secondary).padding(.top, 20)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(game.players.enumerated()), id: \.offset) { i, player in
                                PlayerCard(player: player, won: game.winners.contains(player.spec.name)) { pendingPlayer = i }
                            }
                        }
                    }

                    Button("Delete This Game", systemImage: "trash", role: .destructive) { confirmDelete = true }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(game.game.name)
            .confirmationDialog("Delete this game?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    album.deleteGame(gameID)
                    dismiss()
                }
            } message: {
                Text("All of its player photos will be removed. This can't be undone.")
            }
            .confirmationDialog("Delete this photo?", isPresented: Binding(get: { pendingPlayer != nil }, set: { if !$0 { pendingPlayer = nil } }),
                                presenting: pendingPlayer) { i in
                Button("Delete \(game.players.indices.contains(i) ? game.players[i].spec.name : "this")'s photo", role: .destructive) {
                    album.deletePlayer(i, from: gameID)
                }
            } message: { _ in
                Text("This can't be undone.")
            }
        } else {
            ContentUnavailableView("Game Deleted", systemImage: "trash")
        }
    }
}

private struct PlayerCard: View {
    let player: TablePlayer
    let won: Bool
    let delete: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Portrait(spec: player.spec, after: false)
                Image(systemName: "arrow.right").font(.caption.bold()).foregroundStyle(.secondary)
                Portrait(spec: player.spec, after: true)
            }
            HStack {
                Text(player.spec.name).font(.system(.subheadline, design: .rounded, weight: .bold))
                if won {
                    Text("WINNER").font(.system(size: 9, weight: .heavy, design: .rounded))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(.yellow.opacity(0.6), in: Capsule())
                }
                Spacer()
                Button(role: .destructive, action: delete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete this photo")
            }
            Text(player.buyIn == 0 ? player.finish.prefix(1).uppercased() + player.finish.dropFirst()
                                   : "Bought in $\(player.buyIn) · \(player.finish) · took home $\(player.cashOut)")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Buy-ins, cash-outs and what the family made at one table.
struct GameReceipt: View {
    let game: GameRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(game.game.name) Receipt").font(.system(.headline, design: .rounded, weight: .heavy))
            let paying = game.players.filter { $0.buyIn > 0 }
            row("Buy-ins (\(paying.count) × $\(CasinoGame.buyIn))", "$\(paying.reduce(0) { $0 + $1.buyIn })")
            if let house = game.house { row("House", house == "Mom" ? "Mom" : "\(house) (Mom deals)") }
            if let daughter = game.daughter, let finish = game.daughterFinish, game.house != daughter {
                row("\(daughter) played", finish)
            }
            if let fee = game.setupFee, fee > 0 { row("Table setup", "-$\(fee)") }
            if game.game.isMoney {
                row("Cashed out after \(game.hands) hands", "$\(game.players.reduce(0) { $0 + $1.cashOut })")
                Divider()
                row(game.profit >= 0 ? "House wins" : "House loses", "$\(abs(game.profit))")
                    .foregroundStyle(game.profit >= 0 ? .green : .red)
            } else if game.pot == 0 {
                row("Buy-in", "None — just for fun")
                row("Winner\(game.winners.count == 1 ? "" : "s")", game.winners.joined(separator: " & "))
            } else {
                // Older games, from when the fun tables had a pot.
                row("Family buy-ins", "$\(game.momBuyIn)")
                row("Pot", "$\(game.pot)")
                row("Winner\(game.winners.count == 1 ? "" : "s")", game.winners.joined(separator: " & "))
                Divider()
                row(game.profit >= 0 ? "Mom comes out" : "Mom is out", game.profit >= 0 ? "+$\(game.profit)" : "$\(-game.profit)")
                    .foregroundStyle(game.profit > 0 ? .green : game.profit < 0 ? .red : .primary)
            }
            row("Family cash", "$\(game.startCash) → $\(game.endCash)")
        }
        .font(.system(.subheadline, design: .rounded))
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold().monospacedDigit()
        }
    }
}
