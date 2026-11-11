import SwiftUI

struct ContentView: View {
    @State private var director = Director()
    @State private var showAlbum = false
    /// The shop opened from the button between days (Mom's end-of-day visit opens it by itself).
    @State private var showShop = false

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
                        Text((director.inCustoms ? "Cosmic Customs" : director.inTown ? "Main Street" : CasinoGame.casinoName) + " · Cash $\(director.cash)"
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
                    GamePicker(canEnd: director.gamesPlayed > 0, daytime: director.daytime, host: director.hostName) { director.choose($0, daughterHouse: $1) }
                }
                .scrollBounceBehavior(.basedOnSize)
                .transition(.scale.combined(with: .opacity))
            } else if director.choosingNext {
                NightPicker(night: director.nights, cash: director.cash, bank: director.bank, shop: { showShop = true }) { director.chooseNext($0) }
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
        .overlay {
            // The Roswell of Poker's screen fills the window while someone is playing it.
            if let poker = director.poker {
                PokerMachineView(session: poker)
                    .overlay(alignment: .topLeading) { muteButton.padding(8) }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: director.poker == nil)
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
        .background {
            // Cosmic Customs: on its own view so it never fights the album sheet.
            Color.clear.sheet(isPresented: Binding(get: { director.shopping || showShop },
                                                   set: { if !$0 { closeShop() } })) {
                ShopView(director: director) { closeShop() }
            }
        }
    }

    private func closeShop() {
        showShop = false
        director.closeShop()
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

/// After a day at the casino: go back tomorrow, or call it a wrap. Mom does her errands at the end of each day.
struct NightPicker: View {
    let night: Int
    let cash: Int
    let bank: Int
    let shop: () -> Void
    let pick: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Day \(night) is over! Cash $\(cash) · Bank $\(bank)")
                .font(.system(.headline, design: .rounded, weight: .heavy))
            Text(night % 2 == 0
                 ? "Tomorrow morning the mini saucers turn the family alien again and they play one game twice in the cottage casino, then Mom shops and banks at the end of the day. If you go back, her sister visits first — while the moms shop, the girls host a casino game of their own, and the cousin helps out for a quarter of the profit."
                 : "Tomorrow morning the mini saucers turn the family alien again and they play one game twice in the cottage casino, then Mom shops and banks at the end of the day.")
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Another Day", systemImage: "suit.spade.fill") { pick(true) }
                    .buttonStyle(.borderedProminent)
                Button("Call It a Wrap", systemImage: "moon.zzz.fill") { pick(false) }
                    .buttonStyle(.bordered)
            }
            Button("Cosmic Customs Shop", systemImage: "bag.fill", action: shop)
                .buttonStyle(.bordered)
                .tint(.purple)
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
    /// Who deals: Mom, or Ava when the girls run the casino while Mom's out shopping.
    var host = "Mom"
    let pick: (CasinoGame?, Bool) -> Void
    /// At a moneymaker table: does the daughter who joins bank the game while Mom deals?
    @State private var daughterHouse = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Which game should \(host) deal in the \(CasinoGame.casinoName)? Every player stands by the Roswell of Poker and gets changed by a mini saucer first. Moneymakers have a $\(CasinoGame.buyIn) buy-in; just-for-fun games are free.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            box("Moneymaker Games", "Up to \(CasinoGame.maxPlayers) guests · play to $\(CasinoGame.buyIn * CasinoGame.goal) or broke · setup $\(CasinoGame.setupFee)", CasinoGame.moneyGames) {
                Picker("House", selection: $daughterHouse) {
                    Text(host == "Mom" ? "Mom is the house · you play a daughter" : "\(host) is the house · you play Rosie").tag(false)
                    Text(host == "Mom" ? "A daughter is the house · Mom deals" : "Rosie is the house · \(host) deals").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            box("Just for Fun", host == "Mom" ? "Mom and a daughter (you!) play too · no buy-in" : "\(host) and Rosie (you!) play too · no buy-in", CasinoGame.funGames) { EmptyView() }
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
