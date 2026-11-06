import SwiftUI

struct ContentView: View {
    @State private var director = Director()
    @State private var showAlbum = false

    var body: some View {
        VStack(spacing: 12) {
            if let board = director.board {
                // While cards are being dealt, the table is seen from above — at the casino or at home.
                CasinoTableView(director: director, board: board)
                    .overlay(alignment: .topLeading) { muteButton.offset(x: -4, y: -40) }
            } else {
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        drawStage(ctx, size: size, director: director, now: timeline.date)
                    }
                }
                .aspectRatio(Stage.W / Stage.H, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) { muteButton.padding(8) }
                .overlay(alignment: .bottomTrailing) {
                    if director.atCasino || director.inTown {
                        Text((director.inTown ? "Main Street" : CasinoGame.casinoName) + " · Cash $\(director.cash)"
                             + (director.bank > 0 || director.inTown ? " · Bank $\(director.bank)" : ""))
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .contentTransition(.numericText())
                            .animation(.default, value: director.cash)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                            .padding(8)
                    }
                }

                Text(director.caption)
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .animation(.default, value: director.caption)
            }

            if director.choosingGame {
                // On a phone the two game boxes don't fit under the stage, so the picker scrolls.
                ScrollView {
                    GamePicker(canEnd: director.gamesPlayed > 0, daytime: director.daytime) { director.choose($0, daughterHouse: $1) }
                }
                .scrollBounceBehavior(.basedOnSize)
                .transition(.scale.combined(with: .opacity))
            } else if director.choosingNext {
                NightPicker(night: director.nights, cash: director.cash, bank: director.bank) { director.chooseNext($0) }
                    .transition(.scale.combined(with: .opacity))
            } else {
                if let result = director.result {
                    GameReceipt(game: result)
                        .frame(width: 300)
                }
                HStack(spacing: 12) {
                    if let save = director.saved {
                        // Every night is saved automatically at lights-out; this picks the game up from the last one.
                        Button("Continue After Day \(save.nights)", systemImage: "arrow.clockwise.circle.fill") {
                            director.start(resume: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    Button(director.running ? "Start Over" : (director.finished ? "Replay" : director.saved == nil ? "Start" : "New Game")) {
                        director.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(director.saved == nil ? nil : .gray)
                    Button("Album (\(director.album.entries.count))", systemImage: "photo.on.rectangle.angled") {
                        showAlbum = true
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .animation(.spring(duration: 0.35), value: director.choosingGame)
        .animation(.spring(duration: 0.35), value: director.choosingNext)
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
    }

    private var muteButton: some View {
        Button {
            director.muted.toggle()
        } label: {
            Image(systemName: director.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .padding(8)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// After a day and a night at the casino: go back tomorrow, or call it a wrap. Either way Mom does her errands in the morning.
struct NightPicker: View {
    let night: Int
    let cash: Int
    let bank: Int
    let pick: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Day \(night) is over! Cash $\(cash) · Bank $\(bank)")
                .font(.system(.headline, design: .rounded, weight: .heavy))
            Text(night % 2 == 0
                 ? "Tomorrow morning the family turns alien again and plays one game twice, then Mom shops and banks. If you go back, her sister visits first — they go shopping, and the cousin helps out for a quarter of the day's profit."
                 : "Tomorrow morning the family turns alien again and plays one game twice, then Mom shops and banks before bed.")
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Another Day", systemImage: "suit.spade.fill") { pick(true) }
                    .buttonStyle(.borderedProminent)
                Button("Call It a Wrap", systemImage: "moon.zzz.fill") { pick(false) }
                    .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .frame(maxWidth: 520)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Mom's next table: moneymaker games against the house at the casino, or just-for-fun games at home with no buy-in.
struct GamePicker: View {
    let canEnd: Bool
    /// The afternoon session rather than the night one.
    var daytime = false
    let pick: (CasinoGame?, Bool) -> Void
    /// At a moneymaker table: does the daughter who joins bank the game while Mom deals?
    @State private var daughterHouse = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Which game should Mom deal? Every player goes through the Roswell transformation machine first. Moneymakers are at the casino ($\(CasinoGame.buyIn) buy-in); just-for-fun games are at home and free.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            box("Moneymaker Games", "Up to \(CasinoGame.maxPlayers) guests · play to $\(CasinoGame.buyIn * CasinoGame.goal) or broke · setup $\(CasinoGame.setupFee)", CasinoGame.moneyGames) {
                Picker("House", selection: $daughterHouse) {
                    Text("Mom is the house · you play a daughter").tag(false)
                    Text("A daughter is the house · Mom deals").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            box("Just for Fun", "At home · Mom and a daughter (you!) play too · no buy-in", CasinoGame.funGames) { EmptyView() }
            if canEnd {
                Button(daytime ? "End the Day" : "End the Night", systemImage: daytime ? "sun.max.fill" : "moon.stars.fill") { pick(nil, false) }
                    .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func box(_ title: String, _ subtitle: String, _ games: [CasinoGame], @ViewBuilder options: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(.headline, design: .rounded, weight: .heavy))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            options()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                ForEach(games) { game in
                    Button {
                        pick(game, daughterHouse)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: game.icon).font(.title3)
                            Text(game.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                            Text(game.blurb).font(.caption2).multilineTextAlignment(.center)
                            if !game.isMoney {
                                Text("\(game.funSeats) players\(game.isPartners ? " · partners" : "")").font(.caption2.bold())
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 78)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(game.accent)
                }
            }
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// One card in your hand.
struct CardButton: View {
    enum State { case idle, playable, picked, dimmed }
    let card: Card
    let state: State
    var width = 34.0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CardFace(card: card, width: width)
                .overlay(RoundedRectangle(cornerRadius: width * 0.14)
                    .strokeBorder(state == .picked ? Color.green : Color.yellow, lineWidth: 3)
                    .opacity(state == .picked || state == .playable ? 1 : 0))
                .offset(y: state == .picked ? -10 : 0)
                .opacity(state == .dimmed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state == .dimmed || state == .idle)
    }
}

#Preview {
    ContentView()
}
