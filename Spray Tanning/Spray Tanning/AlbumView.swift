import SwiftUI

/// The history album: one entry per public demonstration, newest first.
struct AlbumView: View {
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDelete: EventRecord?

    var body: some View {
        NavigationStack {
            Group {
                if album.events.isEmpty {
                    ContentUnavailableView("No Events Yet", systemImage: "photo.on.rectangle.angled",
                                           description: Text("Finish a public demonstration and it will show up here."))
                } else {
                    List {
                        ForEach(album.events) { event in
                            HStack {
                                NavigationLink(value: event.id) {
                                    EventRow(event: event)
                                }
                                Button(role: .destructive) {
                                    pendingDelete = event
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Delete this event")
                            }
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { album.delete(event.id) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tan Album")
            .navigationDestination(for: EventRecord.ID.self) { id in
                if let event = album.events.first(where: { $0.id == id }) {
                    EventDetailView(event: event, album: album)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this event?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                                presenting: pendingDelete) { event in
                Button("Delete \(event.venue.name) event", role: .destructive) { album.delete(event.id) }
            } message: { event in
                Text("\(event.venue.name), \(event.date.formatted(date: .abbreviated, time: .shortened)). This can't be undone.")
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 600)
        #endif
    }
}

private struct EventRow: View {
    let event: EventRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.venue.icon)
                .font(.title2)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.venue.name).font(.system(.headline, design: .rounded))
                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(event.tans) tans · \(event.customers.count + event.family.count) photos")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(event.profit >= 0 ? "+$\(event.profit)" : "-$\(-event.profit)")
                .font(.system(.headline, design: .rounded).monospacedDigit())
                .foregroundStyle(event.profit >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

/// One event: the receipt, then before/after photos of the family and every customer.
struct EventDetailView: View {
    let event: EventRecord
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                receipt

                Text("The Family").font(.system(.title3, design: .rounded, weight: .heavy))
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(event.family) { BeforeAfterCard(spec: $0) }
                }

                Text("Customers").font(.system(.title3, design: .rounded, weight: .heavy))
                if event.customers.isEmpty {
                    Text("Nobody bought a spray tan this time.").foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(event.customers) { BeforeAfterCard(spec: $0) }
                    }
                }

                Button("Delete This Event", systemImage: "trash", role: .destructive) { confirmDelete = true }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(event.venue.name)
        .confirmationDialog("Delete this event?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                album.delete(event.id)
                dismiss()
            }
        } message: {
            Text("Its receipt and photos will be removed. This can't be undone.")
        }
    }

    private var receipt: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(event.date.formatted(date: .complete, time: .shortened), systemImage: event.venue.icon)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
            Divider()
            row("Booth setup", "-$\(event.venue.fee)")
            row("\(event.tans) tans × $\(event.venue.price)", "+$\(event.earned)")
            Divider()
            row(event.profit >= 0 ? "Profit" : "Loss", "$\(abs(event.profit))")
                .foregroundStyle(event.profit >= 0 ? .green : .red)
            row("Cash", "$\(event.startCash) → $\(event.endCash)")
        }
        .font(.system(.subheadline, design: .rounded))
        .padding(12)
        .frame(maxWidth: 340)
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

/// A pair of snapshots: untanned in clothes, then tanned in a swimsuit.
struct BeforeAfterCard: View {
    let spec: PersonSpec

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Portrait(spec: spec, after: false)
                Image(systemName: "arrow.right").font(.caption.bold()).foregroundStyle(.secondary)
                Portrait(spec: spec, after: true)
            }
            Text(spec.name).font(.system(.subheadline, design: .rounded, weight: .bold))
            if let level = spec.level {
                HStack(spacing: 4) {
                    Circle().fill(level.skin.color).frame(width: 10, height: 10)
                    Text(level.title).font(.caption)
                }
            }
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// One photo, drawn with the same code as the stage.
struct Portrait: View {
    let spec: PersonSpec
    let after: Bool

    var body: some View {
        Canvas { ctx, size in
            var c = ctx
            // Same scale for everyone so kids look smaller than grown-ups.
            let scale = (size.height - 20) / 160
            c.translateBy(x: size.width / 2, y: size.height - 4)
            c.scaleBy(x: scale, y: scale)
            drawPerson(c, spec.person(after: after), feet: .zero, facing: 0, now: .now)
        }
        .frame(width: 76, height: 120)
        .background(after
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.72, green: 0.88, blue: 1), Color(red: 0.98, green: 0.93, blue: 0.78)],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(white: 0.88)),
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .top) {
            Text(after ? "AFTER" : "BEFORE")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.55))
                .padding(.top, 3)
        }
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}
