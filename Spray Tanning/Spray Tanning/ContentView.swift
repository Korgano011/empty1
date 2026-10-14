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
                    Text("\(venue.name) · Cash $\(director.cash)")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .contentTransition(.numericText())
                        .animation(.default, value: director.cash)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                        .padding(8)
                } else if director.running && director.trips > 0 {
                    Text("Cash $\(director.cash) · Bank $\(director.bank)")
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

            if director.choosingVenue {
                VenuePicker(cash: director.cash) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingVacation {
                VacationPicker { director.chooseVacation($0) }
                    .transition(.scale.combined(with: .opacity))
            } else if director.choosingNext {
                HStack(alignment: .top, spacing: 14) {
                    if let result = director.result { ResultCard(result: result) }
                    NextPicker(prompt: director.nextPrompt) { director.chooseNext(again: $0) }
                }
                .transition(.scale.combined(with: .opacity))
            } else if let person = director.choosingFor {
                LevelPicker(name: person.id) { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else {
                if let result = director.result {
                    ResultCard(result: result)
                }
                HStack(spacing: 12) {
                    Button(director.running ? "Start Over" : (director.finished ? "Replay" : "Start")) {
                        director.start()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Album (\(director.album.events.count))", systemImage: "photo.on.rectangle.angled") {
                        showAlbum = true
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .animation(.spring(duration: 0.35), value: director.choosingFor?.id)
        .animation(.spring(duration: 0.35), value: director.choosingVenue)
        .animation(.spring(duration: 0.35), value: director.choosingNext)
        .animation(.spring(duration: 0.35), value: director.choosingVacation)
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
    }
}

/// The booth's four buttons, shown whenever someone is inside.
struct LevelPicker: View {
    let name: String
    let choose: (TanLevel) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("\(name) is in the booth. Press a button!")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            HStack(spacing: 12) {
                ForEach(TanLevel.allCases) { level in
                    Button {
                        choose(level)
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(level.skin.color)
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                                .shadow(radius: 2)
                            Text(level.title)
                                .font(.system(.caption, design: .rounded).weight(.bold))
                        }
                        .frame(minWidth: 64)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.25, green: 0.28, blue: 0.35), in: RoundedRectangle(cornerRadius: 14))
        .foregroundStyle(.white)
    }
}

/// Where to hold the public demonstration; each spot charges a setup fee.
struct VenuePicker: View {
    let cash: Int
    let pick: (Venue) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Where should they set up the booth? They have $\(cash).")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(122), spacing: 10), count: 4), spacing: 10) {
                ForEach(Venue.allCases) { venue in
                    Button {
                        pick(venue)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: venue.icon).font(.title2)
                            Text(venue.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                            Text(venue.blurb).font(.caption2).multilineTextAlignment(.center)
                            Divider()
                            Text("Setup $\(venue.fee)").font(.caption.bold())
                            Text("$\(venue.price) a tan").font(.caption.bold())
                            Text("\(venue.groups) groups").font(.caption)
                        }
                        .frame(width: 112, height: 150)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Between trips: carry on, or end the game.
struct NextPicker: View {
    let prompt: String
    let choose: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(prompt).font(.system(.subheadline, design: .rounded).weight(.semibold)).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Let's Go!", systemImage: "sun.max.fill") { choose(true) }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                Button("End Game", systemImage: "flag.checkered") { choose(false) }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding(14)
        .frame(maxWidth: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// A one-night mini vacation for Mom and one of the girls, with a babysitter for the others.
struct VacationPicker: View {
    let choose: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Take a one-night mini vacation ($150)? A babysitter will take the other two girls on two trips for a third of the profits.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Mini Vacation", systemImage: "airplane") { choose(true) }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                Button("Stay Home", systemImage: "house.fill") { choose(false) }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding(14)
        .frame(maxWidth: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// The day's takings after the demonstration.
struct ResultCard: View {
    let result: DemoResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(result.venue.name) Receipt").font(.system(.headline, design: .rounded, weight: .heavy))
            row("Booth setup", "-$\(result.venue.fee)")
            row("\(result.tans) tans × $\(result.venue.price)", "+$\(result.earned)")
            Divider()
            row(result.profit >= 0 ? "Profit" : "Loss", "$\(abs(result.profit))")
                .foregroundStyle(result.profit >= 0 ? .green : .red)
            if result.share > 0 { row("Helper's share", "-$\(result.share)") }
            row("Cash", "$\(result.startCash) → $\(result.endCash)")
        }
        .font(.system(.subheadline, design: .rounded))
        .frame(width: 260)
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

#Preview {
    ContentView()
}
