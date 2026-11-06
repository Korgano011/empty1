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
    /// Optional so photos saved before there were colours still load (as green).
    var alienColor: AlienColor?

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
        alienColor = p.alienColor
    }

    /// Before: human. After: a Roswell alien.
    func person(after: Bool) -> Person {
        let p = Person(name, height: height, headScale: headScale, skin: skin, hair: hair, style: style,
                       shirt: shirt, pants: pants, kid: kid, x: 0)
        p.facing = 0
        p.alien = after
        p.alienColor = alienColor ?? .green
        return p
    }
}

struct AlbumEntry: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let spec: PersonSpec
}

/// One player at a casino table: her before-and-after photo and what she walked away with.
struct TablePlayer: Codable {
    let spec: PersonSpec
    let buyIn: Int
    let cashOut: Int
    /// Final chips, or her score in a just-for-fun game.
    let finish: String
}

/// One game at the casino: who Mom asked, who played (and became a Roswell alien first), and how the money went.
struct GameRecord: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let game: CasinoGame
    let asked: Int
    var players: [TablePlayer]
    let hands: Int
    /// Who won a just-for-fun game.
    let winners: [String]
    /// The family's own buy-ins (Mom's and the daughter's) and what they took home.
    let momBuyIn: Int
    let momCashOut: Int
    let startCash: Int
    let endCash: Int
    /// Who banked a moneymaker table, and the daughter who joined. Optional so older games still load.
    var house: String?
    var daughter: String?
    /// Her chips or score, or "was the house".
    var daughterFinish: String?
    /// What the casino charged to set up a moneymaker table.
    var setupFee: Int?

    /// What the family's cash did over the game.
    var profit: Int { endCash - startCash }
    var pot: Int { players.reduce(momBuyIn) { $0 + $1.buyIn } }
}

/// The photo album, newest first, kept in Application Support/RoswellCasinoAlbum/Album.json.
@Observable
final class AlbumStore {
    private(set) var entries: [AlbumEntry] = []
    private(set) var games: [GameRecord] = []

    /// `games` is optional so albums saved before the casino (with venue trips instead) still open.
    private struct AlbumFile: Codable {
        var entries: [AlbumEntry]
        var games: [GameRecord]?
    }

    private let url: URL? = {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent("RoswellCasinoAlbum", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Album.json")
    }()

    init() {
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let file = try? decoder.decode(AlbumFile.self, from: data) {
            entries = file.entries
            games = file.games ?? []
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

    func add(_ game: GameRecord) {
        games.insert(game, at: 0)
        save()
    }

    func deleteGame(_ id: GameRecord.ID) {
        games.removeAll { $0.id == id }
        save()
    }

    /// Empties the album: every family photo and every game.
    func deleteAll() {
        entries = []
        games = []
        save()
    }

    /// Removes one player's photo from a game.
    func deletePlayer(_ index: Int, from id: GameRecord.ID) {
        guard let g = games.firstIndex(where: { $0.id == id }), games[g].players.indices.contains(index) else { return }
        games[g].players.remove(at: index)
        save()
    }

    private func save() {
        guard let url else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(AlbumFile(entries: entries, games: games)) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
