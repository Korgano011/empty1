import SwiftUI

private enum AlbumRoute: Hashable {
    case entry(UUID)
    case event(UUID)
}

/// The family's before-and-after photos, then every public appearance, newest first.
struct AlbumView: View {
    let album: AlbumStore
    @Environment(\.dismiss) private var dismiss
    @State private var pendingEntry: AlbumEntry?
    @State private var pendingEvent: EventRecord?

    var body: some View {
        NavigationStack {
            Group {
                if album.entries.isEmpty && album.events.isEmpty {
                    ContentUnavailableView("No Photos Yet", systemImage: "photo.on.rectangle.angled",
                                           description: Text("Each time someone in the family goes bald, their before-and-after photo lands here."))
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
                        if !album.events.isEmpty {
                            Section("Public Appearances") {
                                ForEach(album.events) { event in
                                    HStack {
                                        NavigationLink(value: AlbumRoute.event(event.id)) {
                                            EventRow(event: event)
                                        }
                                        trash("Delete this appearance") { pendingEvent = event }
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
            }
            .confirmationDialog("Delete this photo?", isPresented: Binding(get: { pendingEntry != nil }, set: { if !$0 { pendingEntry = nil } }),
                                presenting: pendingEntry) { entry in
                Button("Delete \(entry.spec.name)'s photo", role: .destructive) { album.delete(entry.id) }
            } message: { entry in
                Text("\(entry.spec.name), \(entry.date.formatted(date: .abbreviated, time: .shortened)). This can't be undone.")
            }
            .confirmationDialog("Delete this appearance?", isPresented: Binding(get: { pendingEvent != nil }, set: { if !$0 { pendingEvent = nil } }),
                                presenting: pendingEvent) { event in
                Button("Delete \(event.venue.name) appearance", role: .destructive) { album.deleteEvent(event.id) }
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
                Text("\(entry.spec.style.rawValue.capitalized) hair → bald")
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
            drawPerson(c, p, feet: .zero, facing: 0, now: .distantPast, hair: after ? 0 : 1)
        }
        .frame(width: width, height: height)
        .background(after
                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.20, green: 0.55, blue: 0.60), Color(red: 0.70, green: 0.95, blue: 0.90)],
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
                Text("\(event.customers.count) went bald · \(event.asked) asked")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if event.venue.isCharity {
                Text("♥ $\(event.raised)")
                    .font(.system(.headline, design: .rounded).monospacedDigit())
                    .foregroundStyle(event.venue.accent)
            } else {
                Text(event.profit >= 0 ? "+$\(event.profit)" : "-$\(-event.profit)")
                    .font(.system(.headline, design: .rounded).monospacedDigit())
                    .foregroundStyle(event.profit >= 0 ? .green : .red)
            }
            HStack(spacing: -18) {
                ForEach(Array(event.customers.prefix(4).enumerated()), id: \.offset) { _, spec in
                    Portrait(spec: spec, after: true, width: 40, height: 54)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// One appearance: every customer's before-and-after photo, each deletable on its own.
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
                    Text("Asked \(event.asked) \(event.asked == 1 ? "person" : "people") · \(event.customers.count) went bald")
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

                    Button("Delete This Appearance", systemImage: "trash", role: .destructive) { confirmDelete = true }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle(event.venue.name)
            .confirmationDialog("Delete this appearance?", isPresented: $confirmDelete) {
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
            ContentUnavailableView("Appearance Deleted", systemImage: "trash")
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

/// Setup fee, takings (or donations) and profit for one appearance.
struct Receipt: View {
    let event: EventRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(event.venue.name) Receipt").font(.system(.headline, design: .rounded, weight: .heavy))
            row("Booth setup", "-$\(event.fee)")
            if event.venue.isCharity {
                row("Shaves", "Free")
                Divider()
                row("Raised for St. Baldrick's", "♥ $\(event.raised)")
                    .foregroundStyle(event.venue.accent)
            } else {
                row("Balds ($\(event.venue.price), kids $\(event.venue.kidPrice))", "+$\(event.earned)")
                Divider()
                row(event.profit >= 0 ? "Profit" : "Loss", "$\(abs(event.profit))")
                    .foregroundStyle(event.profit >= 0 ? .green : .red)
            }
            row("Family cash", "$\(event.startCash) → $\(event.endCash)")
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
