import SwiftUI

struct ContentView: View {
    @State private var director = Director()
    @State private var showAlbum = false

    var body: some View {
        VStack(spacing: 12) {
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
                } else if director.place == .town {
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

            Text(director.caption)
                .font(.system(.headline, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .animation(.default, value: director.caption)

            if let rider = director.choosingColor {
                AlienPicker(person: rider) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingVenue {
                VenuePicker(cash: director.cash) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingRest {
                RestPicker(cash: director.cash) { director.chooseRest(vacation: $0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingNext {
                HStack(alignment: .top, spacing: 14) {
                    if let result = director.result {
                        Receipt(event: result).frame(width: 300)
                    }
                    NextPicker(cash: director.cash) { director.chooseNext(again: $0) }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                if director.finished, let result = director.result {
                    Receipt(event: result)
                        .frame(width: 300)
                }
                HStack(spacing: 12) {
                    Button(director.running ? "Start Over" : (director.finished ? "Play Again" : "Start")) {
                        director.start()
                    }
                    .buttonStyle(.borderedProminent)
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
        .animation(.spring(duration: 0.35), value: director.choosingVenue)
        .animation(.spring(duration: 0.35), value: director.choosingNext)
        .animation(.spring(duration: 0.35), value: director.choosingRest)
        .animation(.spring(duration: 0.35), value: director.choosingColor?.id)
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
    }
}

/// The seven alien colours, each previewed on whoever is strapped in.
struct AlienPicker: View {
    let person: Person
    let pick: (AlienColor) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("What color Roswell alien does \(person.id) want to be?")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            // Ten colors: two rows of five.
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(76), spacing: 6), count: 5), spacing: 6) {
                ForEach(AlienColor.allCases) { color in
                    Button {
                        pick(color)
                    } label: {
                        VStack(spacing: 4) {
                            Portrait(spec: PersonSpec(person, color: color), after: true, width: 52, height: 68, showsLabel: false)
                            Text(color.name.uppercased()).font(.system(.caption, design: .rounded, weight: .black)).lineLimit(1).minimumScaleFactor(0.8)
                            Text(color.blurb).font(.caption2).multilineTextAlignment(.center).lineLimit(2)
                        }
                        .frame(width: 76, height: 124)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(color.color)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// "Press one of these buttons, and this flying saucer will take you there." Venues they can't afford are greyed out.
struct VenuePicker: View {
    let cash: Int
    let pick: (Venue) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Where should the flying saucer go? They have $\(cash) for the setup fee.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(160), spacing: 10), count: 3), spacing: 10) {
                ForEach(Venue.allCases) { venue in
                    Button {
                        pick(venue)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: venue.icon).font(.title3)
                            Text(venue.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Text(venue.blurb).font(.caption2).multilineTextAlignment(.center)
                            Text("Setup $\(venue.fee) · $\(venue.price), kids $\(venue.kidPrice)").font(.caption2.bold())
                        }
                        .frame(width: 148, height: 104)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(venue.accent)
                    .disabled(venue.fee > cash)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// After every second trip: two of them go on vacation (with a babysitter for the rest), or the money goes in the bank.
struct RestPicker: View {
    let cash: Int
    let pick: (Bool) -> Void

    private var canAfford: Bool { cash >= Director.vacationCost + Venue.cheapestFee }

    var body: some View {
        VStack(spacing: 10) {
            Text("Two trips done! What should they do with the money?")
                .font(.system(.headline, design: .rounded, weight: .heavy))
            HStack(spacing: 12) {
                Button {
                    pick(true)
                } label: {
                    Label("Mini Vacation", systemImage: "airplane.departure")
                        .frame(width: 190)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(!canAfford)
                Button {
                    pick(false)
                } label: {
                    Label("Deposit in the Bank", systemImage: "building.columns.fill")
                        .frame(width: 190)
                }
                .buttonStyle(.borderedProminent)
                .tint(AlienColor.green.color)
            }
            Text(canAfford ? "Mini vacation: Mom and one daughter go away for one night ($\(Director.vacationCost)); the rest goes in the bank, and a teenage babysitter helps run the saucer for a third of the profit."
                           : "Not enough cash for a mini vacation ($\(Director.vacationCost) plus the next setup fee).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 400)
        }
        .controlSize(.large)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// After a trip: press the green button and go again, or call it a day.
struct NextPicker: View {
    let cash: Int
    let pick: (Bool) -> Void

    private var canAfford: Bool { cash >= Venue.cheapestFee }

    var body: some View {
        VStack(spacing: 10) {
            Text("What next?")
                .font(.system(.headline, design: .rounded, weight: .heavy))
            Button {
                pick(true)
            } label: {
                Label("Do It Again", systemImage: "circle.circle.fill")
                    .frame(width: 180)
            }
            .buttonStyle(.borderedProminent)
            .tint(AlienColor.green.color)
            .disabled(!canAfford)
            Button {
                pick(false)
            } label: {
                Label("End Game", systemImage: "flag.checkered")
                    .frame(width: 180)
            }
            .buttonStyle(.bordered)
            Text(canAfford ? "Press the green button: the saucer comes back and everyone picks her alien color."
                           : "Not enough cash for another setup fee ($\(Venue.cheapestFee)).")
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
