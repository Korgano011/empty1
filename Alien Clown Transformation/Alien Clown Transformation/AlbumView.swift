import SwiftUI

private enum AlbumRoute: Hashable {
    case entry(UUID)
    case event(UUID)
}

/// The three women's before-and-after photos, then every trip in the flying tent, newest first.
struct AlbumView: View {
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var pendingEntry: AlbumEntry?
    @State private var pendingEvent: EventRecord?
    @State private var confirmDeleteAll = false

    var body: some View {
        NavigationStack {
            Group {
                if album.entries.isEmpty && album.events.isEmpty {
                    ContentUnavailableView("No Photos Yet", systemImage: "photo.on.rectangle.angled",
                                           description: Text("Each time Deidre, Kelly or Jen turns into an alien clown, her before-and-after photo lands here."))
                } else {
                    List {
                        if !album.entries.isEmpty {
                            Section("Deidre, Kelly & Jen") {
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
                        if !album.events.isEmpty {
                            Section("Flying Tent Trips") {
                                ForEach(album.events) { event in
                                    HStack {
                                        NavigationLink(value: AlbumRoute.event(event.id)) {
                                            EventRow(event: event)
                                        }
                                        trash("Delete this trip") { pendingEvent = event }
                                    }
                                    .swipeActions {
                                        Button("Delete", systemImage: "trash", role: .destructive) { album.deleteEvent(event.id) }
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
                case .event(let id):
                    EventDetailView(eventID: id, album: album)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete All", systemImage: "trash", role: .destructive) { confirmDeleteAll = true }
                        .disabled(album.entries.isEmpty && album.events.isEmpty)
                        .help("Delete everything in the album")
                }
            }
            .confirmationDialog("Delete everything in the album?", isPresented: $confirmDeleteAll) {
                Button("Delete All Photos & Trips", role: .destructive) { album.deleteAll() }
            } message: {
                Text("All \(album.entries.count) before-and-after photos and \(album.events.count) trips, with every customer photo, will be removed. This can't be undone.")
            }
            .confirmationDialog("Delete this photo?", isPresented: Binding(get: { pendingEntry != nil }, set: { if !$0 { pendingEntry = nil } }),
                                presenting: pendingEntry) { entry in
                Button("Delete \(entry.spec.name)'s photo", role: .destructive) { album.delete(entry.id) }
            } message: { entry in
                Text("\(entry.spec.name), \(entry.date.formatted(date: .abbreviated, time: .shortened)). This can't be undone.")
            }
            .confirmationDialog("Delete this trip?", isPresented: Binding(get: { pendingEvent != nil }, set: { if !$0 { pendingEvent = nil } }),
                                presenting: pendingEvent) { event in
                Button("Delete \(event.venue.name) trip", role: .destructive) { album.deleteEvent(event.id) }
            } message: { event in
                Text("\(event.venue.name), \(event.date.formatted(date: .abbreviated, time: .shortened)), with all \(event.customers.count) customer photos. This can't be undone.")
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
                Text("\(entry.spec.kind.name) alien clown")
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
    var height = 110.0
    var showsLabel = true

    var body: some View {
        Canvas { ctx, size in
            let p = spec.person(after: after)
            let pose = Pose(p, feet: .zero, facing: 0, now: .now, still: true)
            // Frame the whole body, from just above the hair (clown hair stands tall) to the feet.
            let top = pose.headTop - pose.hr * (after ? 1.7 : p.style == .bun ? 0.9 : 0.4)
            let bottom = 0.0
            let scale = min(size.height * 0.8 / (bottom - top), size.width * 0.9 / max(pose.hr * 4.2, pose.w * 2.2))
            var c = ctx
            c.translateBy(x: size.width / 2, y: size.height * 0.95)
            c.scaleBy(x: scale, y: scale)
            drawPerson(c, p, feet: .zero, facing: 0, now: .distantPast, still: true, levels: after ? .full : ClownLevels.none)
            if after {
                drawSparkle(c, at: CGPoint(x: pose.head.x + pose.hr * 0.9, y: pose.head.y - pose.hr * 1.6), size: pose.hr * 0.4, alpha: 1)
            }
        }
        .frame(width: width, height: height)
        .background(after
                    ? AnyShapeStyle(LinearGradient(colors: [spec.kind.color.mix(with: .white, by: 0.55), spec.kind.color.mix(with: .white, by: 0.85)],
                                                   startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color(white: 0.88)),
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .top) {
            if showsLabel {
                Text(after ? "AFTER" : "BEFORE")
                    .font(.system(size: width > 100 ? 13 : 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.55))
                    .padding(.top, 3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}

private struct EventRow: View {
    let event: EventRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.venue.icon)
                .font(.title2)
                .foregroundStyle(event.venue.accent)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.venue.name).font(.system(.headline, design: .rounded))
                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(event.customers.count) transformed · \(event.asked) asked")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(event.profit >= 0 ? "+$\(event.profit)" : "-$\(-event.profit)")
                .font(.system(.headline, design: .rounded).monospacedDigit())
                .foregroundStyle(event.profit >= 0 ? .green : .red)
            HStack(spacing: -18) {
                ForEach(Array(event.customers.prefix(4).enumerated()), id: \.offset) { _, spec in
                    Portrait(spec: spec, after: true, width: 40, height: 54)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// One trip: every customer's before-and-after photo, each deletable on its own.
struct EventDetailView: View {
    let eventID: EventRecord.ID
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var pendingCustomer: Int?

    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 12)]

    var body: some View {
        if let event = album.events.first(where: { $0.id == eventID }) {
            ScrollView {
                VStack(spacing: 16) {
                    Label(event.date.formatted(date: .complete, time: .shortened), systemImage: event.venue.icon)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Text("Asked \(event.asked) \(event.asked == 1 ? "person" : "people") · \(event.customers.count) transformed")
                        .font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
                    Receipt(event: event)
                        .frame(maxWidth: 340)

                    if event.customers.isEmpty {
                        Text("No customer photos.").foregroundStyle(.secondary).padding(.top, 20)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(event.customers.enumerated()), id: \.offset) { i, spec in
                                CustomerCard(spec: spec) { pendingCustomer = i }
                            }
                        }
                    }

                    Button("Delete This Trip", systemImage: "trash", role: .destructive) { confirmDelete = true }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(event.venue.name)
            .confirmationDialog("Delete this trip?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    album.deleteEvent(eventID)
                    dismiss()
                }
            } message: {
                Text("All of its customer photos will be removed. This can't be undone.")
            }
            .confirmationDialog("Delete this photo?", isPresented: Binding(get: { pendingCustomer != nil }, set: { if !$0 { pendingCustomer = nil } }),
                                presenting: pendingCustomer) { i in
                Button("Delete \(event.customers.indices.contains(i) ? event.customers[i].name : "this")'s photo", role: .destructive) {
                    album.deleteCustomer(i, from: eventID)
                }
            } message: { _ in
                Text("This can't be undone.")
            }
        } else {
            ContentUnavailableView("Trip Deleted", systemImage: "trash")
        }
    }
}

private struct CustomerCard: View {
    let spec: PersonSpec
    let delete: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Portrait(spec: spec, after: false)
                Image(systemName: "arrow.right").font(.caption.bold()).foregroundStyle(.secondary)
                Portrait(spec: spec, after: true)
            }
            HStack {
                Text(spec.name).font(.system(.subheadline, design: .rounded, weight: .bold))
                Text(spec.kind.name).font(.caption).foregroundStyle(.secondary)
                if spec.kid {
                    Text("KID").font(.system(size: 9, weight: .heavy, design: .rounded))
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
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Setup fee, takings and profit for one trip.
struct Receipt: View {
    let event: EventRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(event.venue.shortName) Receipt").font(.system(.headline, design: .rounded, weight: .heavy))
            row("Tent setup", "-$\(event.fee)")
            row("Transformations ($\(event.venue.price), kids $\(event.venue.kidPrice))", "+$\(event.earned)")
            Divider()
            row(event.profit >= 0 ? "Profit" : "Loss", "$\(abs(event.profit))")
                .foregroundStyle(event.profit >= 0 ? .green : .red)
            row("Cash on hand", "$\(event.startCash) → $\(event.endCash)")
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
