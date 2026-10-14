import Foundation

/// Everything needed to redraw someone for the album's before/after photos.
struct PersonSpec: Codable {
    let name: String
    let height: Double
    let headScale: Double
    let skin: RGB
    let hair: RGB
    let style: HairStyle
    let shirt: RGB
    let pants: RGB
    let kid: Bool

    init(_ p: Person) {
        name = p.id
        height = p.height
        headScale = p.headScale
        skin = p.skin
        hair = p.hair
        style = p.style
        shirt = p.shirt
        pants = p.pants
        kid = p.isKid
    }

    /// Before: a full head of hair. After: bald.
    func person(after: Bool) -> Person {
        let p = Person(name, height: height, headScale: headScale, skin: skin, hair: hair, style: style,
                       shirt: shirt, pants: pants, kid: kid, x: 0)
        p.facing = 0
        p.bald = after
        return p
    }
}

struct AlbumEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let spec: PersonSpec
}

/// One public appearance: where, how many people were asked, and everyone who went bald.
struct EventRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let venue: Venue
    let asked: Int
    var customers: [PersonSpec]
    let fee: Int
    let earned: Int
    /// Donations for St. Baldrick's.
    let raised: Int
    let startCash: Int
    let endCash: Int

    var profit: Int { earned - fee }
}

/// The photo album, newest first, kept in Application Support/BaldingBoothAlbum/Album.json.
@Observable
final class AlbumStore {
    private(set) var entries: [AlbumEntry] = []
    private(set) var events: [EventRecord] = []

    private struct AlbumFile: Codable {
        var entries: [AlbumEntry]
        var events: [EventRecord]
    }

    private let url: URL? = {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent("BaldingBoothAlbum", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Album.json")
    }()

    init() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let file = try? decoder.decode(AlbumFile.self, from: data) {
            entries = file.entries
            events = file.events
        }
    }

    func add(_ entry: AlbumEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ id: AlbumEntry.ID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func add(_ event: EventRecord) {
        events.insert(event, at: 0)
        save()
    }

    func deleteEvent(_ id: EventRecord.ID) {
        events.removeAll { $0.id == id }
        save()
    }

    /// Removes one customer's photo from an appearance.
    func deleteCustomer(_ index: Int, from id: EventRecord.ID) {
        guard let e = events.firstIndex(where: { $0.id == id }), events[e].customers.indices.contains(index) else { return }
        events[e].customers.remove(at: index)
        save()
    }

    private func save() {
        guard let url else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(AlbumFile(entries: entries, events: events)) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
