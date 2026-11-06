import Foundation

/// The family's progress, saved every night at lights-out so a game can be continued later.
/// Kept in Application Support/RoswellCasinoAlbum/Progress.json, next to the album.
struct SaveGame: Codable {
    var date = Date()
    /// Days played so far, counting the one that just ended.
    var nights: Int
    var cash: Int
    var bank: Int
    var cousinsPaid: Int
    var auntVisits: Int
    /// What the house made on the first day of a visit, still to be split with the cousin.
    var visitProfit: Int
    /// The aunt and cousin are sleeping over as aliens; these are their colors.
    var auntColor: String?
    var cousinColor: String?

    var sleepover: Bool { auntColor != nil && cousinColor != nil }

    private static let url: URL? = {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent("RoswellCasinoAlbum", isDirectory: true)
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
}
