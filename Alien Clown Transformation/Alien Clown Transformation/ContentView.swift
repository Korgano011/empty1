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

            Text(director.caption)
                .font(.system(.headline, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 48)
                .animation(.default, value: director.caption)

            if let shopper = director.choosingAccessory {
                AccessoryPicker(person: shopper, spendingMoney: director.spendingMoney) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingVehicle {
                VehiclePicker(bank: director.bank, owned: director.vehicles) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if let rider = director.choosingKind {
                ClownPicker(person: rider) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingVenue {
                VenuePicker(cash: director.cash) { director.choose($0) }
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
        .animation(.spring(duration: 0.35), value: director.choosingKind?.id)
        .animation(.spring(duration: 0.35), value: director.choosingAccessory?.id)
        .animation(.spring(duration: 0.35), value: director.choosingVehicle)
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
    }
}

/// The twelve types of alien clown in two rows of six, each previewed on whoever is strapped in.
struct ClownPicker: View {
    let person: Person
    let pick: (ClownKind) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("What type of alien clown does \(person.id) want to be?")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(100), spacing: 8), count: 6), spacing: 8) {
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

/// The accessory store's shelves. She can keep buying until she is done or the spending money runs out;
/// enough cash for the cheapest setup fee is always held back.
struct AccessoryPicker: View {
    let person: Person
    let spendingMoney: Int
    let pick: (Accessory?) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("What should \(person.id) buy? She has $\(max(0, spendingMoney)) to spend after setting aside a setup fee.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(Accessory.allCases) { item in
                    let owned = person.accessories.contains(item)
                    Button {
                        pick(item)
                    } label: {
                        VStack(spacing: 4) {
                            Text(item.emoji).font(.largeTitle)
                            Text(item.name).font(.system(.caption, design: .rounded, weight: .black)).lineLimit(1).minimumScaleFactor(0.8)
                            Text(owned ? "Bought" : "$\(item.price)").font(.caption2.bold())
                        }
                        .frame(width: 84, height: 84)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.88, green: 0.20, blue: 0.48))
                    .disabled(owned || item.price > spendingMoney)
                }
                Button {
                    pick(nil)
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .frame(width: 84, height: 84)
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

/// The flying tent's pre-selected destinations. Venues they can't afford are greyed out.
struct VenuePicker: View {
    let cash: Int
    let pick: (Venue) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Where should the flying tent go? They have $\(cash) for the setup fee.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(150), spacing: 8), count: 5), spacing: 8) {
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
                            Text(venue.blurb).font(.caption2).multilineTextAlignment(.center).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            Text("Setup $\(venue.fee) · $\(venue.price), kids $\(venue.kidPrice)").font(.caption2.bold())
                        }
                        .frame(width: 138, height: 104)
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

/// After a trip: press the pink button and go again, or call it a day.
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
            .tint(Color(red: 1.0, green: 0.35, blue: 0.70))
            .disabled(!canAfford)
            Button {
                pick(false)
            } label: {
                Label("End Game", systemImage: "flag.checkered")
                    .frame(width: 180)
            }
            .buttonStyle(.bordered)
            Text(canAfford ? "Press the pink button: the tent comes back and everyone picks her type of alien clown."
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
