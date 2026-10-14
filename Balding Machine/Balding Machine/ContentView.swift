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
                    Text(venue.isCharity ? "Cash $\(director.cash) · Raised ♥ $\(director.raised)" : "\(venue.name) · Cash $\(director.cash)")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .contentTransition(.numericText())
                        .animation(.default, value: director.cash)
                        .animation(.default, value: director.raised)
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
                VenuePicker { director.choose($0) }
                    .transition(.scale.combined(with: .opacity))
            } else {
                if let result = director.result {
                    Receipt(event: result)
                        .frame(width: 300)
                }
                HStack(spacing: 12) {
                    Button(director.running ? "Start Over" : (director.finished ? "Replay" : "Start")) {
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
        .sheet(isPresented: $showAlbum) {
            AlbumView(album: director.album)
        }
    }
}

/// Where the family takes the booth for its public appearance.
struct VenuePicker: View {
    let pick: (Venue) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Where should they take the booth? They have $\(Venue.startCash) for the setup fee.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                ForEach(Venue.allCases) { venue in
                    Button {
                        pick(venue)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: venue.icon).font(.title2)
                            Text(venue.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .multilineTextAlignment(.center)
                            Text(venue.blurb).font(.caption2).multilineTextAlignment(.center)
                            Divider()
                            Text("Setup $\(venue.fee)").font(.caption.bold())
                            Text(venue.isCharity ? "Free shaves · donations" : "$\(venue.price) a bald · kids $\(venue.kidPrice)")
                                .font(.caption2)
                        }
                        .frame(width: 130, height: 150)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(venue.accent)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
}
