import Foundation

/// The family's progress, saved by the player once a day is complete (at the "What next?" prompt), so the game can be
/// continued later from that morning. Kept in Application Support/AlienClownAlbum/Progress.json, next to the album.
struct SaveGame: Codable {
    var date = Date()
    /// Nights slept at home so far, and ports visited.
    var nights: Int
    var trips: Int
    var rotation: Int
    var familyVisits: Int
    var rescues: Int
    var cash: Int
    var bank: Int
    var totalProfit: Int
    var totalTransformed: Int
    /// `Vehicle` raw values parked in the driveway.
    var vehicles: [String]
    /// `ShipUpgrade` raw values fitted to the S.S. Big Top (nil in saves from before the upgrade shop).
    var upgrades: [String]?
    /// Rita, Sam and Tammy's clown types once they've joined the ship's crew (nil before they have).
    var recruitKinds: [String?]?

    private static let url: URL? = {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let dir = base.appendingPathComponent("AlienClownAlbum", isDirectory: true)
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
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self) { try? data.write(to: url, options: .atomic) }
    }

    static func erase() {
        guard let url else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
