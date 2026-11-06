import Foundation

/// The family's progress, saved every morning (the start of each new day) so a game can be continued later.
/// Kept in Application Support/AlienAnimalAlbum/Progress.json, next to the album.
struct SaveGame: Codable {
    var date = Date()
    var cash: Int
    var bank: Int
    var nights: Int
    var trips: Int
    var cardGames: Int
    var auntVisits: Int
    var sitterVisits: Int
    var totalProfit: Int
    var totalTransformed: Int
    var rotation: Int
    /// Raw values of the wheels in the driveway.
    var vehicles: [String]

    /// The day the family wakes up to when the game is continued.
    var day: Int { nights + 1 }

    private static let url: URL? = {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent("AlienAnimalAlbum", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Progress.json")
    }()

    static func load() -> SaveGame? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SaveGame.self, from: data)
    }

    func write() {
        guard let url = Self.url else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self) { try? data.write(to: url, options: .atomic) }
    }

    static func delete() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
