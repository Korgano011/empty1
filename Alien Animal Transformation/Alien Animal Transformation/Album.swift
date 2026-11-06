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
    let shorts: Bool
    let female: Bool
    /// Optional so albums saved before bikinis still load.
    let bikini: Bool?
    let kind: AnimalKind

    init(_ p: Person, kind: AnimalKind) {
        name = p.id
        height = p.height
        headScale = p.headScale
        skin = p.skin
        hair = p.hair
        style = p.style
        shirt = p.shirt
        pants = p.pants
        kid = p.isKid
        shorts = p.shorts
        female = p.female
        bikini = p.bikini
        self.kind = kind
    }

    /// Before: still human. After: an alien animal.
    func person(after: Bool) -> Person {
        let p = Person(name, height: height, headScale: headScale, skin: skin, hair: hair, style: style,
                       shirt: shirt, pants: pants, kid: kid, shorts: shorts, female: female, x: 0)
        p.facing = 0
        p.bikini = bikini ?? false
        if after {
            p.animal = kind
            p.changeT0 = .distantPast
        }
        return p
    }
}

struct AlbumEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let spec: PersonSpec
}

/// One trip to a venue: where, how many people were asked, and everyone who got transformed.
struct EventRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let venue: Venue
    let asked: Int
    var customers: [PersonSpec]
    let fee: Int
    let earned: Int
    let startCash: Int
    let endCash: Int
    /// Set when this was a card game hosted at home rather than a trip (`venue` is then just a placeholder).
    var cardGame: CasinoGame? = nil
    /// A card game that's no longer in the app (the old moneymaker games): kept so the album still opens.
    var retiredGame: String? = nil

    var profit: Int { earned - fee }
}

extension EventRecord {
    private enum Keys: String, CodingKey {
        case id, date, venue, asked, customers, fee, earned, startCash, endCash, cardGame, retiredGame
    }

    /// Reads albums saved with games that have since been removed, instead of failing to open the whole album.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        venue = try c.decode(Venue.self, forKey: .venue)
        asked = try c.decode(Int.self, forKey: .asked)
        customers = try c.decode([PersonSpec].self, forKey: .customers)
        fee = try c.decode(Int.self, forKey: .fee)
        earned = try c.decode(Int.self, forKey: .earned)
        startCash = try c.decode(Int.self, forKey: .startCash)
        endCash = try c.decode(Int.self, forKey: .endCash)
        let raw = try c.decodeIfPresent(String.self, forKey: .cardGame)
        cardGame = raw.flatMap(CasinoGame.init(rawValue:))
        retiredGame = try c.decodeIfPresent(String.self, forKey: .retiredGame) ?? (cardGame == nil ? raw : nil)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(venue, forKey: .venue)
        try c.encode(asked, forKey: .asked)
        try c.encode(customers, forKey: .customers)
        try c.encode(fee, forKey: .fee)
        try c.encode(earned, forKey: .earned)
        try c.encode(startCash, forKey: .startCash)
        try c.encode(endCash, forKey: .endCash)
        try c.encodeIfPresent(cardGame, forKey: .cardGame)
        try c.encodeIfPresent(retiredGame, forKey: .retiredGame)
    }
}

/// The photo album, newest first, kept in Application Support/AlienAnimalAlbum/Album.json.
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
        let dir = base.appendingPathComponent("AlienAnimalAlbum", isDirectory: true)
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

    /// Removes one customer's photo from a trip.
    func deleteCustomer(_ index: Int, from id: EventRecord.ID) {
        guard let e = events.firstIndex(where: { $0.id == id }), events[e].customers.indices.contains(index) else { return }
        events[e].customers.remove(at: index)
        save()
    }

    /// Empties the whole album: every before-and-after photo and every trip.
    func deleteAll() {
        entries.removeAll()
        events.removeAll()
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
