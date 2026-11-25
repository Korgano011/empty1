import SwiftUI

struct ContentView: View {
    @State private var director = Director()
    @State private var showAlbum = false
    @State private var confirmStartOver = false

    var body: some View {
        VStack(spacing: 12) {
            if let board = director.board {
                // A day at sea: the card table takes the stage's place while the game is dealt.
                CasinoTableView(director: director, board: board)
            } else {
                stage
            }
            if director.board == nil {
                Text(director.caption)
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .animation(.default, value: director.caption)
            }

            controls
            Spacer(minLength: 0)
        }
        .padding()
        .animation(.spring(duration: 0.35), value: director.choosingDay)
        .animation(.spring(duration: 0.35), value: director.choosingNext)
        .animation(.spring(duration: 0.35), value: director.choosingKind?.id)
        .animation(.spring(duration: 0.35), value: director.choosingUpgrade?.id)
        .animation(.spring(duration: 0.35), value: director.choosingVehicle)
        .confirmationDialog("Start over from the beginning?", isPresented: $confirmStartOver) {
            Button("Start Over", role: .destructive) { director.start() }
        } message: {
            Text(director.saved.map { "Anything since day \($0.nights) ended will be lost. Your saved game stays, so you can still continue from day \($0.nights + 1)." }
                 ?? "This game hasn't been saved, so its progress will be lost.")
        }
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
        // Jen at the Clowns of Poker: the machine's screen fills the window until she makes it to game 10.
        .overlay {
            if director.pokerPlaying, let session = director.poker {
                PokerMachineView(session: session)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            director.muted.toggle()
                        } label: {
                            Image(systemName: director.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .padding(8)
                                .background(.regularMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: director.pokerPlaying)
    }

    private var stage: some View {
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    drawStage(ctx, size: size, director: director, now: timeline.date)
                }
            }
            .aspectRatio(Stage.W / Stage.H, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                Button {
                    director.muted.toggle()
                } label: {
                    Image(systemName: director.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .padding(8)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }
            .overlay(alignment: .bottomTrailing) {
                if let venue = director.venue {
                    Text("\(venue.shortName) · Cash $\(director.cash)")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .contentTransition(.numericText())
                        .animation(.default, value: director.cash)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(8)
                } else if director.place == .bigTop && !director.passengers.isEmpty {
                    Text("Passengers \(director.passengers.count)/\(director.capacity) · Cash $\(director.cash)")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .contentTransition(.numericText())
                        .animation(.default, value: director.cash)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(8)
                } else if director.place == .town || director.place == .shops {
                    Text("Cash $\(director.cash) · Bank $\(director.bank)")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .contentTransition(.numericText())
                        .animation(.default, value: director.bank)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(8)
                }
            }
    }

    @ViewBuilder private var controls: some View {
            if let shopper = director.choosingUpgrade {
                UpgradePicker(person: shopper, spendingMoney: director.spendingMoney, owned: director.upgrades) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingVehicle {
                VehiclePicker(bank: director.bank, owned: director.vehicles) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if let rider = director.choosingKind {
                ClownPicker(person: rider) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingDay {
                DayPicker(cash: director.cash, aboard: director.passengers.count, stops: director.stopsToday,
                          morningStop: director.morningStop, capacity: director.capacity) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingNext {
                HStack(alignment: .top, spacing: 14) {
                    if let result = director.result {
                        Receipt(event: result).frame(width: 300)
                    }
                    NextPicker(cash: director.cash, nextDay: director.nights + 1,
                               startOver: { confirmStartOver = true }) { director.chooseNext(again: $0) }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                if director.finished, let result = director.result {
                    Receipt(event: result)
                        .frame(width: 300)
                }
                HStack(spacing: 12) {
                    Button(director.running ? "Start Over" : (director.finished ? "Play Again" : "Start")) {
                        if director.running { confirmStartOver = true } else { director.start() }
                    }
                    .buttonStyle(.borderedProminent)
                    if !director.running, let save = director.saved {
                        Button("Continue from Day \(save.nights + 1)", systemImage: "arrow.clockwise.circle.fill") {
                            director.start(resume: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 1.0, green: 0.35, blue: 0.70))
                        .help("Saved \(save.date.formatted(date: .abbreviated, time: .shortened)) · Cash $\(save.cash) · Bank $\(save.bank)")
                    }
                    Button("Album (\(director.album.entries.count))", systemImage: "photo.on.rectangle.angled") {
                        showAlbum = true
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
    }
}

/// The fourteen types of alien clown in two rows of seven, each previewed on whoever is strapped in.
struct ClownPicker: View {
    let person: Person
    let pick: (ClownKind) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("What type of alien clown does \(person.id) want to be?")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: 8), count: 7), spacing: 8) {
                ForEach(ClownKind.allCases) { kind in
                    Button {
                        pick(kind)
                    } label: {
                        VStack(spacing: 4) {
                            Portrait(spec: PersonSpec(person, kind: kind), after: true, width: 62, height: 88, showsLabel: false)
                            Text(kind.name.uppercased()).font(.system(.caption, design: .rounded, weight: .black)).lineLimit(1).minimumScaleFactor(0.8)
                            Text(kind.blurb).font(.caption2).multilineTextAlignment(.center).lineLimit(2)
                        }
                        .frame(width: 84, height: 144)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(kind.color)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// The ship-supply shop's catalogue. She can keep ordering upgrades for the S.S. Big Top until she is done or the
/// spending money runs out; enough cash for the cheapest docking fee is always held back.
struct UpgradePicker: View {
    let person: Person
    let spendingMoney: Int
    let owned: Set<ShipUpgrade>
    let pick: (ShipUpgrade?) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Which upgrade should \(person.id) buy for the S.S. Big Top? She has $\(max(0, spendingMoney)) to spend after setting aside a docking fee.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(ShipUpgrade.allCases) { item in
                    let have = owned.contains(item)
                    Button {
                        pick(item)
                    } label: {
                        VStack(spacing: 3) {
                            Text(item.emoji).font(.largeTitle)
                            Text(item.name).font(.system(.caption, design: .rounded, weight: .black)).lineLimit(1).minimumScaleFactor(0.8)
                            Text(item.blurb).font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                            Text(have ? "On the ship" : "$\(item.price)").font(.caption2.bold())
                        }
                        .frame(width: 92, height: 96)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.10, green: 0.30, blue: 0.62))
                    .disabled(have || item.price > spendingMoney)
                }
                Button {
                    pick(nil)
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .frame(width: 84, height: 96)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// At the dealer: a scooter or another car, paid for out of the savings in the bank.
struct VehiclePicker: View {
    let bank: Int
    let owned: Set<Vehicle>
    let pick: (Vehicle?) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("They have $\(bank) saved in the bank. Buy some wheels?")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            HStack(spacing: 8) {
                ForEach(Vehicle.allCases) { vehicle in
                    Button {
                        pick(vehicle)
                    } label: {
                        VStack(spacing: 4) {
                            Text(vehicle.emoji).font(.largeTitle)
                            Text(vehicle.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                            Text(owned.contains(vehicle) ? "In the driveway" : "$\(vehicle.price)").font(.caption2.bold())
                        }
                        .frame(width: 120, height: 84)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(vehicle == .car ? Color(red: 0.85, green: 0.16, blue: 0.20) : Color(red: 0.20, green: 0.65, blue: 0.58))
                    .disabled(owned.contains(vehicle) || vehicle.price > bank)
                }
                Button {
                    pick(nil)
                } label: {
                    Label("Not Today", systemImage: "banknote")
                        .frame(width: 120, height: 84)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Planning the cruise day: dock at one of the ship's ports (ports they can't afford, or a full ship, are greyed out),
/// spend a day at sea playing a card game just for fun, or end the day and drop everyone off.
struct DayPicker: View {
    let cash: Int
    let aboard: Int
    let stops: Int
    /// The morning after a night aboard: port stop 1 or 2 of 2 — only ports are offered.
    var morningStop: Int? = nil
    var capacity = Director.baseCapacity
    let pick: (DayPlan) -> Void

    private var full: Bool { aboard >= capacity }

    var body: some View {
        VStack(spacing: 10) {
            if let morningStop {
                Text("Good morning! Port stop \(morningStop) of 2 before everyone goes home.")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
            }
            Text("Day at Port — dock, invite passers-by on the cruise, and transform them. They have $\(cash) for the docking fee.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(132), spacing: 8), count: 6), spacing: 8) {
                ForEach(Venue.allCases) { venue in
                    Button {
                        pick(.port(venue))
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: venue.icon).font(.headline)
                            Text(venue.name).font(.system(.caption, design: .rounded, weight: .heavy))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Text("Dock $\(venue.fee) · $\(venue.price), kids $\(venue.kidPrice)").font(.caption2.bold())
                        }
                        .frame(width: 120, height: 70)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(venue.accent)
                    .disabled(venue.fee > cash || (full && morningStop == nil))
                }
            }
            if morningStop != nil {
                if full { Text("The ship is full (\(aboard) passengers) — nobody new can board, but the stop still counts.").font(.caption).foregroundStyle(.secondary) }
            } else {
            if full {
                Text("The ship is full (\(aboard) passengers) — have a day at sea, or end the day.").font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            Text("Day at Sea — a card game just for fun with \(aboard == 0 ? "the family and the clowns" : "the passengers")")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(122), spacing: 8), count: 6), spacing: 8) {
                ForEach(CasinoGame.funGames) { game in
                    Button {
                        pick(.sea(game))
                    } label: {
                        VStack(spacing: 2) {
                            Label(game.name, systemImage: game.icon).font(.system(.caption, design: .rounded, weight: .heavy))
                            Text(game.blurb).font(.caption2).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                        }
                        .frame(width: 112, height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(game.accent)
                }
            }
            Divider()
            Button {
                pick(.end)
            } label: {
                Label(aboard == 0 ? "End the Day — sail home" : "End the Day — drop off all \(aboard) passengers, then sail home",
                      systemImage: "moon.stars.fill")
                    .frame(maxWidth: 420)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.30, green: 0.25, blue: 0.60))
            .disabled(stops == 0)
            Button {
                pick(.overnight)
            } label: {
                Label(aboard == 0 ? "Spend the Night Aboard — two ports in the morning, then home"
                                  : "Spend the Night Aboard with all \(aboard) passengers — two ports in the morning, then everyone goes home",
                      systemImage: "bed.double.fill")
                    .frame(maxWidth: 520)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.12, green: 0.18, blue: 0.42))
            .disabled(stops == 0)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// After a trip: press the pink button and go again, or call it a day.
struct NextPicker: View {
    let cash: Int
    /// The day "Continue" carries on with (the game was saved as this prompt came up).
    let nextDay: Int
    let startOver: () -> Void
    let pick: (Bool) -> Void

    private var canAfford: Bool { cash >= Venue.cheapestFee }

    var body: some View {
        VStack(spacing: 10) {
            Text("What next?")
                .font(.system(.headline, design: .rounded, weight: .heavy))
            Button {
                pick(true)
            } label: {
                Label("Continue from Day \(nextDay)", systemImage: "arrow.right.circle.fill")
                    .frame(width: 180)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 1.0, green: 0.35, blue: 0.70))
            .disabled(!canAfford)
            Button(action: startOver) {
                Label("Start Over", systemImage: "arrow.counterclockwise")
                    .frame(width: 180)
            }
            .buttonStyle(.bordered)
            .help("Start a new game from the very beginning")
            Button {
                pick(false)
            } label: {
                Label("End Game", systemImage: "flag.checkered")
                    .frame(width: 180)
            }
            .buttonStyle(.bordered)
            Label("Progress saved", systemImage: "checkmark.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(.green)
            Text(canAfford ? "Press the pink button: the ship comes back and everyone picks her type of alien clown."
                           : "Not enough cash for another docking fee ($\(Venue.cheapestFee)).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 200)
        }
        .controlSize(.large)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
}
