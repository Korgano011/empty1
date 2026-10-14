import Foundation

/// Everything needed to redraw someone for the album's before/after photos.
struct PersonSpec: Codable, Identifiable {
    var id = UUID()
    let name: String
    let family: Bool
    let height: Double
    let headScale: Double
    let hair: RGB
    let style: HairStyle
    let shirt: RGB
    let bottoms: RGB
    let swim: RGB
    let onePiece: Bool
    let level: TanLevel?

    init(_ p: Person, family: Bool) {
        name = p.id
        self.family = family
        height = p.height
        headScale = p.headScale
        hair = p.hair
        style = p.style
        shirt = p.shirt
        bottoms = p.bottoms
        swim = p.swim
        onePiece = p.onePiece
        level = p.level
    }

    /// Before: in clothes, untanned. After: in the swimsuit, at their tan level.
    func person(after: Bool) -> Person {
        let p = Person(name, height: height, headScale: headScale, hair: hair, style: style,
                       shirt: shirt, bottoms: bottoms, swim: swim, onePiece: onePiece, x: 0)
        if after {
            p.outfit = .swim
            p.skin1 = level?.skin ?? .fair
        }
        return p
    }
}

/// One public demonstration: where it was, the takings, and who got tanned.
struct EventRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let venue: Venue
    let tans: Int
    let startCash: Int
    let endCash: Int
    let family: [PersonSpec]
    let customers: [PersonSpec]

    var earned: Int { tans * venue.price }
    var profit: Int { earned - venue.fee }
}

/// The history album, newest event first, kept in Application Support/SprayTanAlbum/Album.json.
@Observable
final class AlbumStore {
    private(set) var events: [EventRecord] = []

    private let url: URL? = {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent("SprayTanAlbum", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Album.json")
    }()

    init() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        events = (try? decoder.decode([EventRecord].self, from: data)) ?? []
    }

    func add(_ event: EventRecord) {
        events.insert(event, at: 0)
        save()
    }

    func delete(_ id: EventRecord.ID) {
        events.removeAll { $0.id == id }
        save()
    }

    private func save() {
        guard let url else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(events) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
