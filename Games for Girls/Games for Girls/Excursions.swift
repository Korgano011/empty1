import SwiftUI

// MARK: - Ports & shop items

enum Port: String, CaseIterable, Codable, Identifiable {
    case laBufadora, nassau, stirrupCay, grandCayman, cozumel, dockyard
    var id: String { rawValue }

    var title: String {
        switch self {
        case .laBufadora: "La Bufadora"
        case .nassau: "Nassau"
        case .stirrupCay: "Great Stirrup Cay"
        case .grandCayman: "Grand Cayman"
        case .cozumel: "Cozumel"
        case .dockyard: "Royal Naval Dockyard"
        }
    }

    var place: String {
        switch self {
        case .laBufadora: "Baja California, Mexico"
        case .nassau: "The Bahamas"
        case .stirrupCay: "Berry Islands, Bahamas"
        case .grandCayman: "Cayman Islands"
        case .cozumel: "Mexico"
        case .dockyard: "Bermuda"
        }
    }

    var arrival: String {
        switch self {
        case .laBufadora: "La Bufadora! The famous sea blowhole shoots ocean spray high into the air, and the road down to it is lined with market stalls."
        case .nassau: "Nassau! Pink and yellow colonial buildings, palm trees, and the busy Straw Market by the harbor."
        case .stirrupCay: "Great Stirrup Cay! A little private island with white sand, swaying hammocks, beach cabanas and an old stone lighthouse."
        case .grandCayman: "Grand Cayman! Turquoise water, Seven Mile Beach, and stingrays gliding in the shallows."
        case .cozumel: "Cozumel! A sunny plaza with a clock tower, colorful shops and jewelry stores everywhere."
        case .dockyard: "The Royal Naval Dockyard in Bermuda! Old limestone walls, the twin-towered Clocktower building and the glassworks."
        }
    }
}

enum ItemKind: Equatable { case ship, gift, game(StyleSlot) }

struct ShopItem: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let emoji: String
    let price: Int
    let kind: ItemKind
    let blurb: String
    /// Ship upgrades: bonus to passersby saying yes (0–1).
    var accept: Double = 0
    /// Ship upgrades: tip per passenger each cruise.
    var tip = 0
    /// Ship upgrades: extra winner's bonus.
    var winBonus = 0
    /// Why U.S. Customs takes it away (nil = it's allowed).
    var seized: String? = nil

    var isStyle: Bool { if case .game = kind { true } else { false } }

    var effect: String {
        if case .game(let slot) = kind { return "New look for your \(slot.title.lowercased())" }
        var parts: [String] = []
        if accept > 0 { parts.append("+\(Int(accept * 100))% passersby say yes") }
        if tip > 0 { parts.append("+$\(tip) tip per passenger") }
        if winBonus > 0 { parts.append("+$\(winBonus) winner's bonus") }
        return parts.joined(separator: ", ")
    }
}

enum Shop {
    static func items(_ port: Port) -> [ShopItem] {
        switch port {
        case .laBufadora: [
            ShopItem(name: "Talavera Tile Pool", emoji: "🏊‍♀️", price: 120, kind: .ship, blurb: "A splash pool for the top deck, lined with hand-painted blue-and-white tiles.", accept: 0.05),
            ShopItem(name: "Papel Picado Banners", emoji: "🎏", price: 40, kind: .ship, blurb: "Bright cut-paper banners strung from bow to stern.", accept: 0.03),
            ShopItem(name: "Talavera Checkers", emoji: "🔵", price: 35, kind: .game(.backgammon), blurb: "Solid blue and white backgammon checkers in Talavera pottery colors."),
            ShopItem(name: "Lotería Cards", emoji: "🃏", price: 25, kind: .game(.cards), blurb: "Playing cards with a bright Lotería-style back and old-fashioned lettering."),
            ShopItem(name: "Mexican Vanilla", emoji: "🍶", price: 15, kind: .gift, blurb: "A big bottle of real Mexican vanilla for Mom's baking."),
            ShopItem(name: "Talavera Coffee Mug", emoji: "☕️", price: 20, kind: .gift, blurb: "Hand-painted with flowers in Mom's favorite colors."),
            ShopItem(name: "Fresh Mango with Chile", emoji: "🥭", price: 6, kind: .gift, blurb: "Juicy mango on a stick, dusted with chile and lime.",
                     seized: "Fresh fruit isn't allowed into the country – it can carry fruit flies and plant pests."),
            ShopItem(name: "Homemade Chorizo", emoji: "🌭", price: 12, kind: .gift, blurb: "Spicy sausage, made fresh at the market this morning.",
                     seized: "Pork and meat products from Mexico aren't allowed – they can spread animal diseases."),
        ]
        case .nassau: [
            ShopItem(name: "Junkanoo Steel Drum Stage", emoji: "🥁", price: 150, kind: .ship, blurb: "A little stage with steel drums – passengers love the music.", tip: 3),
            ShopItem(name: "Potted Royal Palm Trees", emoji: "🌴", price: 90, kind: .ship, blurb: "Four tall palms in big pots of island soil for the deck.",
                     seized: "Live plants in foreign soil aren't allowed – soil can hide insects and plant diseases."),
            ShopItem(name: "Junkanoo Chips", emoji: "🟠", price: 30, kind: .game(.connect4), blurb: "Solid orange and turquoise Connect 4 chips in Junkanoo colors."),
            ShopItem(name: "Flamingo Cards", emoji: "🦩", price: 25, kind: .game(.cards), blurb: "Pink flamingo playing cards – the Bahamas' national bird!"),
            ShopItem(name: "Lucky Seed Chips", emoji: "🌰", price: 20, kind: .game(.connect4), blurb: "Connect 4 chips made from real dried island seeds, painted red and yellow.",
                     seized: "Seeds and plant material can't come in without an inspection permit – they can carry plant diseases."),
            ShopItem(name: "Straw Market Sun Hat", emoji: "👒", price: 18, kind: .gift, blurb: "Hand-woven straw hat with a pink ribbon."),
            ShopItem(name: "Bahamian Rum Cake", emoji: "🍰", price: 14, kind: .gift, blurb: "A sealed, golden rum cake in a pretty tin."),
            ShopItem(name: "Conch Shell", emoji: "🐚", price: 10, kind: .gift, blurb: "A big pink conch shell – hold it to your ear to hear the ocean."),
            ShopItem(name: "Cuban Cigars", emoji: "🚬", price: 40, kind: .gift, blurb: "A fancy box of Cuban cigars for Mom's boss.",
                     seized: "Cuban-made goods like cigars can't be brought into the United States."),
        ]
        case .stirrupCay: [
            ShopItem(name: "Lighthouse Beacon", emoji: "🗼", price: 120, kind: .ship, blurb: "A red-and-white striped lighthouse for the bow. Its light flashes so passersby can spot the ship.", accept: 0.05),
            ShopItem(name: "Island Tiki Bar", emoji: "🍹", price: 90, kind: .ship, blurb: "A thatched tiki bar serving fruity (no-alcohol) drinks with little umbrellas. Passengers leave tips!", tip: 2),
            ShopItem(name: "Living Coral Aquarium", emoji: "🪸", price: 100, kind: .ship, blurb: "A big tank of live coral and tiny reef fish for the lounge.",
                     seized: "Live coral is protected – it can't be taken from the reef or brought into the country."),
            ShopItem(name: "Lighthouse Checkers", emoji: "🔴", price: 35, kind: .game(.backgammon), blurb: "Solid red and white backgammon checkers, like the Stirrup Cay lighthouse."),
            ShopItem(name: "Beach Ball Chips", emoji: "🏐", price: 30, kind: .game(.connect4), blurb: "Bright beach-ball Connect 4 chips in sunny yellow and ocean blue."),
            ShopItem(name: "Sand Dollar Cards", emoji: "🐚", price: 25, kind: .game(.cards), blurb: "Sandy-colored cards with a sand dollar on the back."),
            ShopItem(name: "Seashell Wind Chime", emoji: "🎐", price: 18, kind: .gift, blurb: "Little shells that tinkle in the breeze – perfect for Mom's porch."),
            ShopItem(name: "Guava Jam", emoji: "🍯", price: 10, kind: .gift, blurb: "A sealed jar of sweet Bahamian guava jam."),
            ShopItem(name: "Beach Tote Bag", emoji: "👜", price: 22, kind: .gift, blurb: "A woven tote with \"Great Stirrup Cay\" stitched in pink."),
            ShopItem(name: "Pet Hermit Crab", emoji: "🦀", price: 12, kind: .gift, blurb: "A cute little hermit crab in a painted shell.",
                     seized: "Live animals can't come in without special permits and a health inspection."),
            ShopItem(name: "Fresh Key Limes", emoji: "🍋‍🟩", price: 6, kind: .gift, blurb: "A bag of island key limes for Mom's key lime pie.",
                     seized: "Fresh citrus isn't allowed into the country – it can carry citrus diseases and fruit flies."),
        ]
        case .grandCayman: [
            ShopItem(name: "Seven Mile Beach Cabanas", emoji: "⛱️", price: 140, kind: .ship, blurb: "Striped beach cabanas with lounge chairs for the sun deck.", accept: 0.05),
            ShopItem(name: "Stingray City Photo Wall", emoji: "📸", price: 60, kind: .ship, blurb: "A giant photo wall where passengers pose with painted stingrays.", accept: 0.03),
            ShopItem(name: "Caymanite Checkers", emoji: "🟤", price: 40, kind: .game(.backgammon), blurb: "Polished stone checkers in rust and sand colors."),
            ShopItem(name: "Antique Ivory Checkers", emoji: "⚪️", price: 55, kind: .game(.backgammon), blurb: "An old set of ivory and ebony backgammon checkers from an antique shop.",
                     seized: "Elephant ivory is banned – it can't be brought into the United States."),
            ShopItem(name: "Tortuga Rum Cake", emoji: "🎂", price: 16, kind: .gift, blurb: "The famous Cayman rum cake, sealed in a gold box."),
            ShopItem(name: "Caymanite Pendant", emoji: "📿", price: 45, kind: .gift, blurb: "A pendant made from caymanite, a stone found only in the Caymans."),
            ShopItem(name: "Sea Turtle Shell Bracelet", emoji: "🐢", price: 35, kind: .gift, blurb: "A shiny bracelet made of polished turtle shell.",
                     seized: "Sea turtles are endangered – products made from them are against the law to import."),
        ]
        case .cozumel: [
            ShopItem(name: "Mayan Mosaic Game Tables", emoji: "🎲", price: 130, kind: .ship, blurb: "Game tables inlaid with Mayan-style mosaics. Winning feels extra special!", winBonus: 10),
            ShopItem(name: "Hammock Lounge", emoji: "🛏️", price: 70, kind: .ship, blurb: "A row of colorful woven hammocks on the promenade.", accept: 0.03),
            ShopItem(name: "Mayan Jade Chips", emoji: "🟢", price: 35, kind: .game(.connect4), blurb: "Jade-green and obsidian-black Connect 4 chips."),
            ShopItem(name: "Silver Filigree Cards", emoji: "✨", price: 30, kind: .game(.cards), blurb: "Elegant silver-backed playing cards with fancy lettering."),
            ShopItem(name: "Silver Bracelet", emoji: "💍", price: 40, kind: .gift, blurb: "Sterling silver with a little dolphin charm."),
            ShopItem(name: "Tequila Chocolate Bar", emoji: "🍫", price: 10, kind: .gift, blurb: "Fancy Mexican chocolate in a gift wrapper."),
            ShopItem(name: "Black Coral Earrings", emoji: "💎", price: 60, kind: .gift, blurb: "Glossy black coral earrings – the shop says they're a Cozumel classic.",
                     seized: "Black coral is a protected species – you can't bring it in without a special permit."),
            ShopItem(name: "Fresh Avocados", emoji: "🥑", price: 8, kind: .gift, blurb: "A bag of ripe avocados for Mom's guacamole.",
                     seized: "Fresh fruits and vegetables like avocados aren't allowed in a traveler's luggage."),
        ]
        case .dockyard: [
            ShopItem(name: "Glassworks Chandelier", emoji: "🏮", price: 160, kind: .ship, blurb: "A sparkling pink glass chandelier for the game lounge.", accept: 0.04),
            ShopItem(name: "Clocktower Ship's Bell", emoji: "🔔", price: 100, kind: .ship, blurb: "A brass bell to ring when a cruise sets sail. Passengers tip the bell ringers!", tip: 2),
            ShopItem(name: "Pink Sand Deck", emoji: "🏖️", price: 110, kind: .ship, blurb: "Real Bermuda pink sand to make a little beach on the sun deck.",
                     seized: "Sand and soil can't be brought in – they can carry pests and plant diseases."),
            ShopItem(name: "Sea Glass Chips", emoji: "🫧", price: 35, kind: .game(.connect4), blurb: "Solid aqua and lavender chips made at the Dockyard Glassworks."),
            ShopItem(name: "Gold & Pearl Checkers", emoji: "🟡", price: 45, kind: .game(.backgammon), blurb: "Shiny gold and pearly-white backgammon checkers."),
            ShopItem(name: "Royal Navy Cards", emoji: "⚓️", price: 25, kind: .game(.cards), blurb: "Navy-blue cards with a gold anchor, like the old Royal Navy sailors used."),
            ShopItem(name: "Rum Swizzle Cake", emoji: "🧁", price: 15, kind: .gift, blurb: "A sealed Bermuda rum cake."),
            ShopItem(name: "Glass Hummingbird", emoji: "🐦", price: 30, kind: .gift, blurb: "Hand-blown at the Dockyard Glassworks."),
            ShopItem(name: "Bermuda Shorts", emoji: "🩳", price: 25, kind: .gift, blurb: "Bright pink Bermuda shorts, of course!"),
            ShopItem(name: "Fresh Loquats", emoji: "🍑", price: 6, kind: .gift, blurb: "A basket of sweet little loquats from a Bermuda tree.",
                     seized: "Fresh fruit isn't allowed into the country – it can carry fruit flies and plant pests."),
        ]
        }
    }

    static var allShipItems: [ShopItem] { Port.allCases.flatMap { items($0) }.filter { $0.kind == .ship } }
    static func item(named n: String) -> ShopItem? { Port.allCases.flatMap { items($0) }.first { $0.name == n } }
}

/// What's installed on the ship – read by drawShip (like talkingLooks, a global set by the model).
var shipExtras: Set<String> = []

// MARK: - Shopping screen

struct ShoppingView: View {
    let model: AppModel
    @State private var showTip = false

    var body: some View {
        let port = model.port ?? .nassau
        ScrollView {
            VStack(spacing: 12) {
                Text("Shore Excursion: \(port.title)").font(.title2.bold()).padding(.top, 50)
                Text(port.place).foregroundStyle(.secondary)
                Canvas { ctx, size in
                    let s = min(size.width / 400, size.height / 220)
                    ctx.translateBy(x: (size.width - 400 * s) / 2, y: 0)
                    ctx.scaleBy(x: s, y: s)
                    drawPort(&ctx, CGSize(width: 400, height: 220), port, t: 0)
                    for (i, x) in [150.0, 200, 250].enumerated() {
                        drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: 210), h: 70, girl: 1, mood: .happy, arms: .wave)
                    }
                }
                .aspectRatio(400 / 220, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Text("Cash $\(model.cash) • bags: \(model.cart.count)").font(.headline)
                Button { showTip.toggle() } label: { Label("Ask the Woman about customs", systemImage: "questionmark.bubble") }
                    .font(.footnote)
                if showTip {
                    Text("“Be careful, girls! When we get home, U.S. Customs checks every bag. They're strict about fresh food, plants and dirt, things made from endangered animals or coral, and anything from Cuba. If they take something away, you don't get your money back!”")
                        .font(.callout).italic().padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.pink.opacity(0.12)))
                        .padding(.horizontal)
                }

                section("For the Ship", [.ship], port)
                section("Game Styles", StyleSlot.allCases.map { ItemKind.game($0) }, port)
                section("Gifts for Mom", [.gift], port)

                Button { model.leavePort() } label: { Label("Back to the Ship", systemImage: "ferry.fill").frame(maxWidth: 260) }
                    .buttonStyle(.borderedProminent).tint(Palette.green).controlSize(.large)
                    .padding(.bottom)
            }
        }
    }

    private func section(_ title: String, _ kinds: [ItemKind], _ port: Port) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).padding(.horizontal)
            ForEach(Shop.items(port).filter { kinds.contains($0.kind) }) { item in
                row(item)
            }
        }
    }

    private func row(_ item: ShopItem) -> some View {
        let inBag = model.cart.contains(item)
        let owned = model.owns(item)
        return HStack(alignment: .top, spacing: 10) {
            Text(item.emoji).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.subheadline.bold())
                Text(item.blurb).font(.caption).foregroundStyle(.secondary)
                if !item.effect.isEmpty { Text(item.effect).font(.caption.bold()).foregroundStyle(Palette.green) }
            }
            Spacer(minLength: 4)
            VStack(spacing: 4) {
                Text("$\(item.price)").font(.subheadline.bold())
                if owned {
                    Text(item.kind == .ship ? "On board" : "Owned").font(.caption2).foregroundStyle(.secondary)
                } else if inBag {
                    Button("Return") { model.returnItem(item) }.buttonStyle(.bordered).controlSize(.small)
                } else {
                    Button("Buy") { model.buy(item) }
                        .buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.small)
                        .disabled(model.cash < item.price)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(inBag ? Palette.pink : .clear, lineWidth: 2))
        .padding(.horizontal)
    }
}

// MARK: - Story shots

extension Story {
    static func excursionOut(_ port: Port) -> [Shot] {
        [
            Shot(scene: .sailing(port, home: false), text: "The Games for Girls ship sets sail for \(port.title), \(port.place)!", sfx: .horn, anim: 4),
            Shot(scene: .atPort(port), text: port.arrival, sfx: .sparkle),
            Shot(scene: .atPort(port), speaker: "The Woman", text: "Go shopping, girls! Find things to make our ship even better, and pick out some gifts for your mom.", voice: .hostess),
            Shot(scene: .atPort(port), speaker: "The Woman", text: "But remember – U.S. Customs checks every bag when we get home!", voice: .hostess),
        ]
    }

    static func excursionBack(_ port: Port, cart: [ShopItem]) -> [Shot] {
        var s = [Shot(scene: .sailing(port, home: true), text: "The ship sails home from \(port.title) to the boardwalk.", sfx: .horn, anim: 4)]
        if cart.isEmpty {
            s.append(Shot(scene: .customs(nil, seized: false), speaker: "Customs Officer", text: "Anything to declare, girls? Nothing at all? Welcome home!", voice: .bank))
            return s
        }
        s.append(Shot(scene: .customs(nil, seized: false), speaker: "Customs Officer", text: "Welcome back, girls. U.S. Customs. Put your bags on the table, please.", voice: .bank, sfx: .click))
        for item in cart {
            if let why = item.seized {
                s.append(Shot(scene: .customs(item.emoji, seized: true), speaker: "Customs Officer", text: "\(item.name)? Sorry, girls. \(why) I have to confiscate it.", voice: .bank, sfx: .crash))
            } else {
                s.append(Shot(scene: .customs(item.emoji, seized: false), speaker: "Customs Officer", text: "\(item.name)… that's fine. Next!", voice: .bank, sfx: .click))
            }
        }
        let lost = cart.filter { $0.seized != nil }
        if !lost.isEmpty {
            let total = lost.reduce(0) { $0 + $1.price }
            s.append(Shot(scene: .customs(nil, seized: true), speaker: "Deirdre", text: lost.count == 1 ? "Aww! That was $\(total) down the drain." : "Aww! They took \(lost.count) things – that's $\(total) down the drain!", voice: .girl))
        } else {
            s.append(Shot(scene: .customs(nil, seized: false), speaker: "Ellie", text: "Everything made it through customs!", voice: .girl, sfx: .sparkle))
        }
        let upgrades = cart.filter { $0.kind == .ship && $0.seized == nil }
        if !upgrades.isEmpty {
            s.append(Shot(scene: .shipUpgraded, text: "The crew installs the \(ListFormatter.localizedString(byJoining: upgrades.map(\.name))) on the ship!", sfx: .sparkle, anim: 3))
        }
        let styles = cart.filter { if case .game = $0.kind { return $0.seized == nil }; return false }
        if !styles.isEmpty {
            s.append(Shot(scene: .shipUpgraded, speaker: "Christina", text: "And the game lounge gets our new \(ListFormatter.localizedString(byJoining: styles.map(\.name)))!", voice: .girl, sfx: .chip))
        }
        if cart.contains(where: { $0.kind == .gift && $0.seized == nil }) {
            s.append(Shot(scene: .shipUpgraded, speaker: "Christina", text: "Let's hide Mom's presents until we get home tonight!", voice: .girl))
        }
        return s
    }

    static func giftShots(_ gifts: [String]) -> [Shot] {
        guard !gifts.isEmpty else { return [] }
        var s = [Shot(scene: .momGifts(nil), speaker: "Ellie", text: "Mom, we brought you presents from our shore excursions!", voice: .girl, sfx: .sparkle)]
        for g in gifts {
            let emoji = Shop.item(named: g)?.emoji
            s.append(Shot(scene: .momGifts(emoji), text: "Mom opens the \(g).", sfx: .sparkle, anim: 1.5))
        }
        s.append(Shot(scene: .momGifts(nil), speaker: "Mom", text: ["Oh girls, I love them! You're the sweetest daughters a mom could ask for.", "You didn't have to do that! Come here and give me a hug.", "What wonderful presents! I'm going to show everyone at work."].randomElement()!, voice: .mom))
        return s
    }
}

// MARK: - Drawing

func drawPort(_ ctx: inout GraphicsContext, _ size: CGSize, _ port: Port, t: Double) {
    let w = size.width, h = size.height
    let sky = Color(red: 0.55, green: 0.82, blue: 1)
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(sky))
    ctx.fill(Path(ellipseIn: CGRect(x: w - 70, y: 14, width: 36, height: 36)), with: .color(.yellow))
    let sea = port == .laBufadora ? Color(red: 0.15, green: 0.4, blue: 0.65) : Color(red: 0.2, green: 0.8, blue: 0.85)
    ctx.fill(Path(CGRect(x: 0, y: h * 0.5, width: w, height: h * 0.2)), with: .color(sea))
    func palm(_ x: CGFloat, _ base: CGFloat, _ s: CGFloat = 1) {
        var trunk = Path(); trunk.move(to: CGPoint(x: x, y: base)); trunk.addQuadCurve(to: CGPoint(x: x + 8 * s, y: base - 60 * s), control: CGPoint(x: x - 6 * s, y: base - 30 * s))
        ctx.stroke(trunk, with: .color(Color(red: 0.55, green: 0.4, blue: 0.2)), lineWidth: 4 * s)
        for a in stride(from: 0.0, to: 360, by: 60) {
            var leaf = Path()
            let r = Angle.degrees(a).radians
            leaf.move(to: CGPoint(x: x + 8 * s, y: base - 60 * s))
            leaf.addQuadCurve(to: CGPoint(x: x + 8 * s + CGFloat(cos(r)) * 24 * s, y: base - 60 * s + CGFloat(sin(r)) * 10 * s + 8 * s),
                              control: CGPoint(x: x + 8 * s + CGFloat(cos(r)) * 12 * s, y: base - 68 * s))
            ctx.stroke(leaf, with: .color(Color(red: 0.15, green: 0.6, blue: 0.25)), lineWidth: 4 * s)
        }
    }
    func building(_ r: CGRect, _ c: Color, roof: Color = .white) {
        ctx.fill(Path(r), with: .color(c))
        ctx.fill(Path(CGRect(x: r.minX - 3, y: r.minY - 6, width: r.width + 6, height: 6)), with: .color(roof))
        var y = r.minY + 8
        while y < r.maxY - 14 {
            var x = r.minX + 6
            while x < r.maxX - 10 {
                ctx.fill(Path(CGRect(x: x, y: y, width: 7, height: 10)), with: .color(.white))
                ctx.fill(Path(CGRect(x: x + 1, y: y + 1, width: 5, height: 8)), with: .color(Color(red: 0.3, green: 0.55, blue: 0.4)))
                x += 14
            }
            y += 18
        }
    }
    let ground = h * 0.7
    switch port {
    case .laBufadora:
        // rocky cliffs and the blowhole spout
        var cliff = Path()
        cliff.move(to: CGPoint(x: 0, y: h * 0.2)); cliff.addLine(to: CGPoint(x: 90, y: h * 0.28)); cliff.addLine(to: CGPoint(x: 150, y: h * 0.45))
        cliff.addLine(to: CGPoint(x: 170, y: h * 0.7)); cliff.addLine(to: CGPoint(x: 0, y: h * 0.7)); cliff.closeSubpath()
        ctx.fill(cliff, with: .color(Color(red: 0.5, green: 0.38, blue: 0.28)))
        let burst = 0.5 + 0.5 * sin(t * 2.2)
        for k in 0..<7 {
            let rr = 10 + CGFloat(k) * 4
            let yy = h * 0.6 - CGFloat(burst) * CGFloat(k) * 14
            ctx.fill(Path(ellipseIn: CGRect(x: 175 - rr / 2 + CGFloat(k % 2) * 6, y: yy - rr / 2, width: rr, height: rr)), with: .color(.white.opacity(0.85)))
        }
        ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(Color(red: 0.85, green: 0.75, blue: 0.6)))
        let awn: [Color] = [.red, .green, .orange, .pink, .yellow]
        for i in 0..<5 {
            let x = 200 + CGFloat(i) * 40
            ctx.fill(Path(CGRect(x: x, y: ground - 40, width: 34, height: 40)), with: .color(Color(red: 0.95, green: 0.9, blue: 0.8)))
            ctx.fill(Path(CGRect(x: x - 3, y: ground - 50, width: 40, height: 12)), with: .color(awn[i]))
        }
        ctx.draw(Text("LA BUFADORA").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 290, y: 22))
    case .nassau:
        ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(Color(red: 0.85, green: 0.82, blue: 0.75)))
        building(CGRect(x: 20, y: ground - 70, width: 90, height: 70), Color(red: 1, green: 0.7, blue: 0.75))
        building(CGRect(x: 120, y: ground - 60, width: 80, height: 60), Color(red: 1, green: 0.88, blue: 0.45))
        building(CGRect(x: 210, y: ground - 75, width: 90, height: 75), Color(red: 1, green: 0.7, blue: 0.75))
        ctx.fill(Path(roundedRect: CGRect(x: 310, y: ground - 30, width: 80, height: 30), cornerRadius: 4), with: .color(Color(red: 0.85, green: 0.7, blue: 0.4)))
        ctx.draw(Text("STRAW MARKET").font(.system(size: 8, weight: .heavy)).foregroundStyle(.brown), at: CGPoint(x: 350, y: ground - 15))
        palm(300, ground)
        ctx.draw(Text("NASSAU").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 200, y: 22))
    case .stirrupCay:
        ctx.fill(Path(CGRect(x: 0, y: ground - 10, width: w, height: h - ground + 10)), with: .color(Color(red: 1, green: 0.97, blue: 0.9)))
        // the lighthouse on its point
        let lx: CGFloat = 50, lt = ground - 130
        var tower = Path(); tower.move(to: CGPoint(x: lx - 14, y: ground - 10)); tower.addLine(to: CGPoint(x: lx - 9, y: lt)); tower.addLine(to: CGPoint(x: lx + 9, y: lt)); tower.addLine(to: CGPoint(x: lx + 14, y: ground - 10)); tower.closeSubpath()
        ctx.fill(tower, with: .color(.white))
        for k in 0..<4 {
            let y0 = lt + 10 + CGFloat(k) * 30
            ctx.fill(Path(CGRect(x: lx - 13, y: y0, width: 26, height: 13)), with: .color(Color(red: 0.85, green: 0.15, blue: 0.15)))
        }
        ctx.fill(Path(CGRect(x: lx - 10, y: lt - 16, width: 20, height: 16)), with: .color(Color(red: 1, green: 0.95, blue: 0.6).opacity(0.6 + 0.4 * (0.5 + 0.5 * sin(t * 3)))))
        var dome = Path(); dome.move(to: CGPoint(x: lx - 12, y: lt - 16)); dome.addLine(to: CGPoint(x: lx, y: lt - 28)); dome.addLine(to: CGPoint(x: lx + 12, y: lt - 16)); dome.closeSubpath()
        ctx.fill(dome, with: .color(Color(red: 0.2, green: 0.2, blue: 0.25)))
        // hammocks between palms
        palm(130, ground); palm(200, ground)
        var hm = Path(); hm.move(to: CGPoint(x: 136, y: ground - 40)); hm.addQuadCurve(to: CGPoint(x: 206, y: ground - 40), control: CGPoint(x: 171, y: ground - 10 + CGFloat(sin(t * 1.5)) * 4))
        ctx.stroke(hm, with: .color(Color(red: 0.95, green: 0.5, blue: 0.65)), lineWidth: 5)
        // beach cabanas
        let cab: [Color] = [Color(red: 0.3, green: 0.75, blue: 0.9), Color(red: 1, green: 0.6, blue: 0.3), Color(red: 1, green: 0.55, blue: 0.75)]
        for i in 0..<3 {
            let cx = 260 + CGFloat(i) * 46
            ctx.fill(Path(CGRect(x: cx, y: ground - 36, width: 36, height: 36)), with: .color(.white))
            ctx.fill(Path(CGRect(x: cx + 4, y: ground - 30, width: 28, height: 30)), with: .color(cab[i].opacity(0.35)))
            var roof = Path(); roof.move(to: CGPoint(x: cx - 4, y: ground - 36)); roof.addLine(to: CGPoint(x: cx + 18, y: ground - 52)); roof.addLine(to: CGPoint(x: cx + 40, y: ground - 36)); roof.closeSubpath()
            ctx.fill(roof, with: .color(cab[i]))
        }
        ctx.draw(Text("GREAT STIRRUP CAY").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 230, y: 22))
    case .grandCayman:
        ctx.fill(Path(CGRect(x: 0, y: ground - 10, width: w, height: h - ground + 10)), with: .color(Color(red: 0.98, green: 0.95, blue: 0.85)))
        for x in [40.0, 330, 370] { palm(x, ground) }
        // stingrays in the shallows
        for (k, x) in [140.0, 230].enumerated() {
            let dx = CGFloat(sin(t + Double(k))) * 10
            var ray = Path()
            ray.move(to: CGPoint(x: x + dx - 16, y: h * 0.6)); ray.addQuadCurve(to: CGPoint(x: x + dx + 16, y: h * 0.6), control: CGPoint(x: x + dx, y: h * 0.52))
            ray.addQuadCurve(to: CGPoint(x: x + dx - 16, y: h * 0.6), control: CGPoint(x: x + dx, y: h * 0.66))
            ctx.fill(ray, with: .color(Color(red: 0.35, green: 0.45, blue: 0.5)))
        }
        ctx.draw(Text("GRAND CAYMAN").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 200, y: 22))
    case .cozumel:
        ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(Color(red: 0.9, green: 0.85, blue: 0.75)))
        building(CGRect(x: 10, y: ground - 55, width: 80, height: 55), Color(red: 0.4, green: 0.75, blue: 0.9))
        building(CGRect(x: 280, y: ground - 60, width: 100, height: 60), Color(red: 0.95, green: 0.55, blue: 0.35))
        // clock tower
        ctx.fill(Path(CGRect(x: 175, y: ground - 110, width: 30, height: 110)), with: .color(Color(red: 0.98, green: 0.92, blue: 0.7)))
        ctx.fill(Path(ellipseIn: CGRect(x: 180, y: ground - 100, width: 20, height: 20)), with: .color(.white))
        ctx.stroke(Path(ellipseIn: CGRect(x: 180, y: ground - 100, width: 20, height: 20)), with: .color(.black), lineWidth: 1)
        var hands = Path(); hands.move(to: CGPoint(x: 190, y: ground - 90)); hands.addLine(to: CGPoint(x: 190, y: ground - 97)); hands.move(to: CGPoint(x: 190, y: ground - 90)); hands.addLine(to: CGPoint(x: 195, y: ground - 90))
        ctx.stroke(hands, with: .color(.black), lineWidth: 1.2)
        palm(120, ground); palm(250, ground)
        ctx.draw(Text("COZUMEL").font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 80, y: 22))
    case .dockyard:
        ctx.fill(Path(CGRect(x: 0, y: ground, width: w, height: h - ground)), with: .color(Color(red: 0.75, green: 0.72, blue: 0.66)))
        let stone = Color(red: 0.88, green: 0.84, blue: 0.74)
        ctx.fill(Path(CGRect(x: 60, y: ground - 60, width: 260, height: 60)), with: .color(stone))
        for x in [80.0, 260] {
            ctx.fill(Path(CGRect(x: x, y: ground - 120, width: 40, height: 60)), with: .color(stone))
            var cap = Path(); cap.move(to: CGPoint(x: x - 4, y: ground - 120)); cap.addLine(to: CGPoint(x: x + 20, y: ground - 140)); cap.addLine(to: CGPoint(x: x + 44, y: ground - 120)); cap.closeSubpath()
            ctx.fill(cap, with: .color(Color(red: 0.7, green: 0.66, blue: 0.58)))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: 88, y: ground - 112, width: 24, height: 24)), with: .color(.white))
        ctx.stroke(Path(ellipseIn: CGRect(x: 88, y: ground - 112, width: 24, height: 24)), with: .color(.black), lineWidth: 1)
        for i in 0..<8 {
            ctx.fill(Path(roundedRect: CGRect(x: 72 + CGFloat(i) * 30, y: ground - 45, width: 16, height: 26), cornerRadius: 8), with: .color(Color(red: 0.35, green: 0.3, blue: 0.3)))
        }
        ctx.draw(Text("ROYAL NAVAL DOCKYARD").font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.white), at: CGPoint(x: 200, y: 22))
    }
}

/// Little drawings of the installed upgrades, layered on the ship by drawShip.
func drawShipExtras(_ ctx: inout GraphicsContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
    let top = y - h * 2.6
    let deck = y - h * 1.9
    if shipExtras.contains("Papel Picado Banners") {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        for i in 0..<14 {
            let px = x + w * 0.05 + CGFloat(i) * w * 0.065
            var f = Path(); f.move(to: CGPoint(x: px, y: deck - h * 0.5)); f.addLine(to: CGPoint(x: px + w * 0.05, y: deck - h * 0.5)); f.addLine(to: CGPoint(x: px + w * 0.025, y: deck - h * 0.2)); f.closeSubpath()
            ctx.fill(f, with: .color(colors[i % colors.count]))
        }
    }
    if shipExtras.contains("Talavera Tile Pool") {
        ctx.fill(Path(roundedRect: CGRect(x: x + w * 0.72, y: deck - h * 0.25, width: w * 0.12, height: h * 0.22), cornerRadius: 2), with: .color(Color(red: 0.2, green: 0.4, blue: 0.85)))
        ctx.fill(Path(CGRect(x: x + w * 0.73, y: deck - h * 0.2, width: w * 0.1, height: h * 0.1)), with: .color(Color(red: 0.4, green: 0.85, blue: 1)))
    }
    if shipExtras.contains("Seven Mile Beach Cabanas") {
        for i in 0..<2 {
            let cx = x + w * 0.16 + CGFloat(i) * w * 0.07
            var tent = Path(); tent.move(to: CGPoint(x: cx, y: deck - h * 0.45)); tent.addLine(to: CGPoint(x: cx + w * 0.03, y: deck)); tent.addLine(to: CGPoint(x: cx - w * 0.03, y: deck)); tent.closeSubpath()
            ctx.fill(tent, with: .color(i == 0 ? Color(red: 1, green: 0.5, blue: 0.3) : Color(red: 0.3, green: 0.75, blue: 0.9)))
        }
    }
    if shipExtras.contains("Junkanoo Steel Drum Stage") {
        for i in 0..<3 {
            ctx.fill(Path(ellipseIn: CGRect(x: x + w * 0.3 + CGFloat(i) * w * 0.035, y: top - h * 0.18, width: w * 0.03, height: h * 0.15)), with: .color(Color(white: 0.75)))
        }
    }
    if shipExtras.contains("Glassworks Chandelier") {
        ctx.fill(Path(ellipseIn: CGRect(x: x + w * 0.45, y: deck + h * 0.12, width: w * 0.05, height: h * 0.2)), with: .color(Color(red: 1, green: 0.6, blue: 0.85).opacity(0.9)))
    }
    if shipExtras.contains("Clocktower Ship's Bell") {
        ctx.fill(Path(ellipseIn: CGRect(x: x + w * 0.66, y: top - h * 0.22, width: w * 0.035, height: h * 0.2)), with: .color(Color(red: 0.85, green: 0.65, blue: 0.2)))
    }
    if shipExtras.contains("Hammock Lounge") {
        var hm = Path(); hm.move(to: CGPoint(x: x + w * 0.88, y: y - h * 1.2)); hm.addQuadCurve(to: CGPoint(x: x + w * 0.98, y: y - h * 1.2), control: CGPoint(x: x + w * 0.93, y: y - h * 0.9))
        ctx.stroke(hm, with: .color(.orange), lineWidth: 2.5)
    }
    if shipExtras.contains("Stingray City Photo Wall") {
        ctx.fill(Path(CGRect(x: x + w * 0.02, y: y - h * 1.3, width: w * 0.08, height: h * 0.5)), with: .color(Color(red: 0.3, green: 0.8, blue: 0.85)))
    }
    if shipExtras.contains("Lighthouse Beacon") {
        let bx = x + w * 0.9, bt = top - h * 0.5
        ctx.fill(Path(CGRect(x: bx, y: bt, width: w * 0.03, height: h * 0.5)), with: .color(.white))
        ctx.fill(Path(CGRect(x: bx, y: bt + h * 0.15, width: w * 0.03, height: h * 0.12)), with: .color(.red))
        ctx.fill(Path(ellipseIn: CGRect(x: bx - w * 0.005, y: bt - h * 0.12, width: w * 0.04, height: h * 0.12)), with: .color(.yellow))
    }
    if shipExtras.contains("Island Tiki Bar") {
        ctx.fill(Path(CGRect(x: x + w * 0.6, y: deck - h * 0.3, width: w * 0.07, height: h * 0.3)), with: .color(Color(red: 0.6, green: 0.4, blue: 0.2)))
        var thatch = Path(); thatch.move(to: CGPoint(x: x + w * 0.585, y: deck - h * 0.3)); thatch.addLine(to: CGPoint(x: x + w * 0.635, y: deck - h * 0.55)); thatch.addLine(to: CGPoint(x: x + w * 0.685, y: deck - h * 0.3)); thatch.closeSubpath()
        ctx.fill(thatch, with: .color(Color(red: 0.85, green: 0.72, blue: 0.4)))
    }
    if shipExtras.contains("Mayan Mosaic Game Tables") {
        for i in 0..<2 {
            ctx.fill(Path(CGRect(x: x + w * 0.52 + CGFloat(i) * w * 0.07, y: top - h * 0.12, width: w * 0.05, height: h * 0.1)), with: .color(Color(red: 0.2, green: 0.6, blue: 0.55)))
        }
    }
}

func drawCustoms(_ ctx: inout GraphicsContext, _ size: CGSize, item: String?, seized: Bool, t: Double) {
    let floor = size.height * 0.88
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.9, green: 0.92, blue: 0.95)))
    ctx.fill(Path(CGRect(x: 0, y: size.height * 0.72, width: size.width, height: size.height * 0.28)), with: .color(Color(red: 0.7, green: 0.72, blue: 0.75)))
    ctx.fill(Path(CGRect(x: 110, y: 14, width: 180, height: 26)), with: .color(Color(red: 0.1, green: 0.2, blue: 0.45)))
    ctx.draw(Text("U.S. CUSTOMS").font(.system(size: 15, weight: .black)).foregroundStyle(.white), at: CGPoint(x: 200, y: 27))
    // inspection table
    ctx.fill(Path(CGRect(x: 150, y: floor - 50, width: 130, height: 8)), with: .color(Color(white: 0.5)))
    for lx in [158.0, 266] { ctx.fill(Path(CGRect(x: lx, y: floor - 42, width: 6, height: 42)), with: .color(Color(white: 0.4))) }
    ctx.fill(Path(roundedRect: CGRect(x: 160, y: floor - 72, width: 40, height: 24), cornerRadius: 4), with: .color(Palette.pink))
    for (i, x) in [40.0, 80, 120].enumerated() {
        drawPerson(&ctx, look: Cast.kids[i], feet: CGPoint(x: x, y: floor), h: 88, girl: 1, mood: seized ? .sad : .happy, arms: .down, facing: 1)
    }
    drawPerson(&ctx, look: Cast.customs, feet: CGPoint(x: 330, y: floor), h: 122, mood: seized ? .angry : .neutral, arms: seized ? .point : .hands, facing: -1)
    if let item {
        ctx.draw(Text(item).font(.system(size: 34)), at: CGPoint(x: 240, y: floor - 70))
        if seized {
            var st = ctx
            st.translateBy(x: 240, y: floor - 70)
            st.rotate(by: .degrees(-14))
            st.stroke(Path(roundedRect: CGRect(x: -62, y: -13, width: 124, height: 26), cornerRadius: 4), with: .color(.red), lineWidth: 3)
            st.draw(Text("CONFISCATED").font(.system(size: 15, weight: .black)).foregroundStyle(.red), at: .zero)
        } else {
            ctx.draw(Text("✅").font(.system(size: 20)), at: CGPoint(x: 268, y: floor - 92))
        }
    }
}

// MARK: - Game styles (checkers, chips, playing cards)

enum StyleSlot: String, Codable, CaseIterable { case backgammon, connect4, cards
    var title: String {
        switch self {
        case .backgammon: "Backgammon checkers"
        case .connect4: "Connect 4 chips"
        case .cards: "Playing cards"
        }
    }
}

enum PiecePattern { case plain, swirl, marble, star, glass, pearl, sparkle }

struct PieceStyle {
    let name: String
    let a: Color, b: Color
    let aName: String, bName: String
    var pattern: PiecePattern = .plain

    static let classic = PieceStyle(name: "Classic Pink & Green", a: Palette.pink, b: Palette.green, aName: "Pink", bName: "Green")
    static let all: [PieceStyle] = [
        classic,
        PieceStyle(name: "Talavera Checkers", a: Color(red: 0.15, green: 0.3, blue: 0.75), b: Color(red: 0.95, green: 0.93, blue: 0.85), aName: "Blue", bName: "White", pattern: .swirl),
        PieceStyle(name: "Caymanite Checkers", a: Color(red: 0.55, green: 0.3, blue: 0.2), b: Color(red: 0.85, green: 0.7, blue: 0.5), aName: "Rust", bName: "Sand", pattern: .marble),
        PieceStyle(name: "Gold & Pearl Checkers", a: Color(red: 0.9, green: 0.72, blue: 0.2), b: Color(red: 0.97, green: 0.95, blue: 0.98), aName: "Gold", bName: "Pearl", pattern: .pearl),
        PieceStyle(name: "Antique Ivory Checkers", a: Color(red: 0.98, green: 0.95, blue: 0.85), b: Color(red: 0.25, green: 0.15, blue: 0.1), aName: "Ivory", bName: "Ebony", pattern: .marble),
        PieceStyle(name: "Junkanoo Chips", a: Color(red: 1, green: 0.55, blue: 0.1), b: Color(red: 0.1, green: 0.75, blue: 0.8), aName: "Orange", bName: "Turquoise", pattern: .star),
        PieceStyle(name: "Mayan Jade Chips", a: Color(red: 0.2, green: 0.6, blue: 0.45), b: Color(red: 0.12, green: 0.12, blue: 0.15), aName: "Jade", bName: "Obsidian", pattern: .marble),
        PieceStyle(name: "Sea Glass Chips", a: Color(red: 0.4, green: 0.85, blue: 0.8), b: Color(red: 0.7, green: 0.55, blue: 0.95), aName: "Aqua", bName: "Lavender", pattern: .glass),
        PieceStyle(name: "Lighthouse Checkers", a: Color(red: 0.85, green: 0.12, blue: 0.15), b: Color(red: 0.98, green: 0.98, blue: 0.98), aName: "Red", bName: "White", pattern: .swirl),
        PieceStyle(name: "Beach Ball Chips", a: Color(red: 1, green: 0.85, blue: 0.1), b: Color(red: 0.15, green: 0.45, blue: 0.95), aName: "Yellow", bName: "Blue", pattern: .star),
        PieceStyle(name: "Emerald & Sapphire", a: Color(red: 0.05, green: 0.62, blue: 0.35), b: Color(red: 0.08, green: 0.25, blue: 0.75), aName: "Emerald", bName: "Sapphire", pattern: .sparkle),
        PieceStyle(name: "Ruby & Diamond", a: Color(red: 0.82, green: 0.05, blue: 0.22), b: Color(red: 0.85, green: 0.93, blue: 1), aName: "Ruby", bName: "Diamond", pattern: .sparkle),
        PieceStyle(name: "Amethyst & Topaz", a: Color(red: 0.6, green: 0.3, blue: 0.85), b: Color(red: 1, green: 0.72, blue: 0.15), aName: "Amethyst", bName: "Topaz", pattern: .sparkle),
        PieceStyle(name: "Lucky Seed Chips", a: Color(red: 0.75, green: 0.2, blue: 0.2), b: Color(red: 0.95, green: 0.8, blue: 0.3), aName: "Red", bName: "Yellow", pattern: .star),
    ]
    /// Sparkling gem sets – everyone owns these from the start, for both backgammon and Connect 4.
    static let gems = ["Emerald & Sapphire", "Ruby & Diamond", "Amethyst & Topaz"]
    static func named(_ n: String) -> PieceStyle { all.first { $0.name == n } ?? classic }
}

struct CardStyle {
    let name: String
    let back1: Color, back2: Color
    let emblem: String
    var serif = false
    var face: Color = .white
    var red: Color = Color(red: 0.85, green: 0.1, blue: 0.2)
    var black: Color = .black

    static let classic = CardStyle(name: "Classic Pink Hearts", back1: Palette.pink, back2: .purple, emblem: "♥")
    static let all: [CardStyle] = [
        classic,
        CardStyle(name: "Lotería Cards", back1: Color(red: 0.95, green: 0.3, blue: 0.2), back2: Color(red: 0.98, green: 0.75, blue: 0.1), emblem: "🌵", serif: true, face: Color(red: 1, green: 0.97, blue: 0.88)),
        CardStyle(name: "Flamingo Cards", back1: Color(red: 1, green: 0.55, blue: 0.65), back2: Color(red: 0.3, green: 0.8, blue: 0.85), emblem: "🦩", red: Color(red: 0.95, green: 0.3, blue: 0.5)),
        CardStyle(name: "Silver Filigree Cards", back1: Color(white: 0.75), back2: Color(white: 0.45), emblem: "✦", serif: true, face: Color(white: 0.97)),
        CardStyle(name: "Sand Dollar Cards", back1: Color(red: 0.93, green: 0.85, blue: 0.68), back2: Color(red: 0.35, green: 0.78, blue: 0.85), emblem: "🐚", face: Color(red: 1, green: 0.98, blue: 0.93)),
        CardStyle(name: "Royal Navy Cards", back1: Color(red: 0.08, green: 0.15, blue: 0.4), back2: Color(red: 0.2, green: 0.3, blue: 0.6), emblem: "⚓️", serif: true, red: Color(red: 0.75, green: 0.1, blue: 0.15), black: Color(red: 0.05, green: 0.1, blue: 0.3)),
    ]
    static func named(_ n: String) -> CardStyle { all.first { $0.name == n } ?? classic }
}

/// The styles currently in use – read by the game views (set by the model).
struct GameLook {
    var backgammon = PieceStyle.classic
    var connect4 = PieceStyle.classic
    var cards = CardStyle.classic
}
var gameLook = GameLook()

/// One game piece (checker / chip) drawn in a piece style.
struct ChipView: View {
    var color: Color
    var pattern: PiecePattern
    var size: CGFloat

    var body: some View {
        ZStack {
            // every checker / chip is one solid color; gem colors add a little sparkle on top
            Circle().fill(color)
            if pattern == .sparkle {
                TimelineView(.animation(minimumInterval: 1 / 15)) { tl in
                    Canvas { ctx, sz in
                        let t = tl.date.timeIntervalSinceReferenceDate
                        let spots: [(Double, Double)] = [(0.32, 0.3), (0.68, 0.42), (0.45, 0.7), (0.72, 0.72)]
                        for (k, s) in spots.enumerated() {
                            let tw = 0.5 + 0.5 * sin(t * 3 + Double(k) * 1.9)
                            drawTwinkle(ctx, CGPoint(x: s.0 * sz.width, y: s.1 * sz.height), sz.width * 0.09 * (0.35 + tw))
                        }
                    }
                }
            }
            Circle().stroke(Color.black.opacity(0.35), lineWidth: 0.6)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    /// White on dark pieces, dark on light ones.
    private var contrast: Color {
        #if canImport(UIKit)
        var w: CGFloat = 0
        UIColor(color).getWhite(&w, alpha: nil)
        return w > 0.7 ? Color(white: 0.3) : .white
        #else
        let w = NSColor(color).usingColorSpace(.deviceGray)?.whiteComponent ?? 0.5
        return w > 0.7 ? Color(white: 0.3) : .white
        #endif
    }
}

/// Sheet for choosing which owned style each game uses.
struct StyleClosetView: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                ForEach(StyleSlot.allCases, id: \.self) { slot in
                    Section(slot.title) {
                        ForEach(model.ownedStyles(slot), id: \.self) { name in
                            Button { model.selectStyle(slot, name) } label: {
                                HStack {
                                    preview(slot, name)
                                    Text(name).foregroundStyle(.primary)
                                    Spacer()
                                    if model.selectedStyle(slot) == name { Image(systemName: "checkmark").foregroundStyle(Palette.pink) }
                                }
                            }
                        }
                    }
                }
                Section {
                    Text("Buy more styles on shore excursions!").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Game Styles")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .frame(minWidth: 320, minHeight: 420)
    }

    private func preview(_ slot: StyleSlot, _ name: String) -> some View { StylePreview(slot: slot, name: name) }
}

/// A little sample of a style: two chips, or a card back and face.
struct StylePreview: View {
    let slot: StyleSlot
    let name: String
    var size: CGFloat = 22

    var body: some View {
        if slot == .cards {
            let s = CardStyle.named(name)
            HStack(spacing: size * 0.15) {
                CardView(card: nil, w: size, style: s)
                CardView(card: PCard(rank: 1, suit: 2), w: size, style: s)
            }
        } else {
            let s = PieceStyle.named(name)
            HStack(spacing: size * 0.1) {
                ChipView(color: s.a, pattern: s.pattern, size: size)
                ChipView(color: s.b, pattern: s.pattern, size: size)
            }
        }
    }
}

/// Back on the ship after an excursion with new chips or cards: the player picks which set to play with,
/// for each game that got something new. The old favorites stay on the list.
struct ChooseStylesView: View {
    let model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("New Game Styles!").font(.largeTitle.bold()).foregroundStyle(Palette.pink)
                Text("You brought home new \(model.newStyleSlots.map { $0 == .cards ? "cards" : "chips" }.uniqued().joined(separator: " and ")). Which ones do you want to use?")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                ForEach(model.newStyleSlots, id: \.self) { slot in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(slot.title).font(.headline)
                        ForEach(model.ownedStyles(slot), id: \.self) { name in
                            let on = model.selectedStyle(slot) == name
                            Button { model.selectStyle(slot, name) } label: {
                                HStack(spacing: 12) {
                                    StylePreview(slot: slot, name: name, size: 34)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name).font(.subheadline.bold()).foregroundStyle(.primary)
                                        if model.newStyles.contains(name) {
                                            Text("NEW").font(.caption2.weight(.black)).foregroundStyle(.white)
                                                .padding(.horizontal, 6).padding(.vertical, 1)
                                                .background(Palette.pink, in: Capsule())
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                        .font(.title2).foregroundStyle(on ? Palette.pink : .secondary)
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(on ? Palette.pink.opacity(0.15) : Color.gray.opacity(0.08)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(.background.opacity(0.7)))
                }
                Button("Use These") { model.finishChoosingStyles() }
                    .buttonStyle(.borderedProminent).tint(Palette.pink).font(.headline)
                Text("You can change them any time with Game Styles.").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] { var seen = Set<Element>(); return filter { seen.insert($0).inserted } }
}
