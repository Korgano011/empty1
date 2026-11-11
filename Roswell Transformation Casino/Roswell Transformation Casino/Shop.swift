import SwiftUI

// MARK: - Cosmic Customs: everything the family can buy

/// The shop's four departments.
enum ShopCategory: String, CaseIterable, Identifiable {
    case alien, outfits, decor, machine
    var id: String { rawValue }

    var name: String {
        switch self {
        case .alien: "Alien Looks"
        case .outfits: "Outfits"
        case .decor: "Casino Decor"
        case .machine: "Machine"
        }
    }

    var icon: String {
        switch self {
        case .alien: "sparkles"
        case .outfits: "tshirt.fill"
        case .decor: "building.columns.fill"
        case .machine: "suit.spade.fill"
        }
    }

    /// Looks and outfits are bought for one person at a time; decor and machine upgrades are for the whole casino.
    var perPerson: Bool { self == .alien || self == .outfits }
}

/// Extra touches on someone's alien form; they grow in as she changes.
enum AlienFeature: String, Codable, CaseIterable {
    case antennae, spots, glow, bigEyes, rosyCheeks
}

/// Outfits worn as a human. Like her everyday clothes, they melt away near the end of the change and come back when she turns human.
enum Outfit: String, Codable, CaseIterable {
    case sundress, sparkleGown, redCarpet, denim, galaxy, tracksuit

    var top: RGB {
        switch self {
        case .sundress: RGB(r: 1.00, g: 0.85, b: 0.25)
        case .sparkleGown: RGB(r: 0.88, g: 0.72, b: 0.30)
        case .redCarpet: RGB(r: 0.80, g: 0.08, b: 0.16)
        case .denim: RGB(r: 0.96, g: 0.96, b: 0.96)
        case .galaxy: RGB(r: 0.42, g: 0.20, b: 0.70)
        case .tracksuit: RGB(r: 0.95, g: 0.40, b: 0.70)
        }
    }

    var bottom: RGB {
        switch self {
        case .sundress, .sparkleGown, .redCarpet: top
        case .denim: RGB(r: 0.25, g: 0.40, b: 0.70)
        case .galaxy: RGB(r: 0.10, g: 0.08, b: 0.20)
        case .tracksuit: RGB(r: 0.95, g: 0.40, b: 0.70)
        }
    }

    var isDress: Bool { [.sundress, .sparkleGown, .redCarpet].contains(self) }
    var sparkly: Bool { self == .sparkleGown || self == .galaxy }
}

enum Accessory: String, Codable, CaseIterable {
    case sunHat, sunglasses, necklace, handbag, tiara
}

/// The felt on the card table.
enum FeltColor: String, Codable, CaseIterable {
    case green, blue, red, purple, black

    var rgb: RGB {
        switch self {
        case .green: RGB(r: 0.08, g: 0.45, b: 0.25)
        case .blue: RGB(r: 0.10, g: 0.28, b: 0.62)
        case .red: RGB(r: 0.62, g: 0.10, b: 0.14)
        case .purple: RGB(r: 0.40, g: 0.14, b: 0.55)
        case .black: RGB(r: 0.10, g: 0.10, b: 0.12)
        }
    }
    var color: Color { rgb.color }
}

/// The casino carpet: a base color with a pattern on it.
enum CarpetStyle: String, Codable, CaseIterable {
    case red, gold, starry, emerald

    var base: Color {
        switch self {
        case .red: Color(red: 0.50, green: 0.08, blue: 0.12)
        case .gold: Color(red: 0.62, green: 0.46, blue: 0.12)
        case .starry: Color(red: 0.07, green: 0.08, blue: 0.28)
        case .emerald: Color(red: 0.06, green: 0.36, blue: 0.22)
        }
    }
    var pattern: Color {
        switch self {
        case .red: Color(red: 0.85, green: 0.65, blue: 0.15)
        case .gold: Color(red: 0.98, green: 0.88, blue: 0.50)
        case .starry: .white
        case .emerald: Color(red: 0.85, green: 0.65, blue: 0.15)
        }
    }
}

/// The color of the casino's neon: the cottage sign, the marquee bulbs and the string lights.
enum NeonColor: String, Codable, CaseIterable {
    case green, pink, blue, gold

    var color: Color {
        switch self {
        case .green: Color(red: 0.45, green: 1.0, blue: 0.45)
        case .pink: Color(red: 1.0, green: 0.40, blue: 0.80)
        case .blue: Color(red: 0.40, green: 0.75, blue: 1.0)
        case .gold: Color(red: 1.0, green: 0.85, blue: 0.30)
        }
    }
}

/// Extra decorations for the casino; any number can be on at once.
enum DecorExtra: String, Codable, CaseIterable {
    case discoBall, palms, lavaLamps
}

/// The Roswell of Poker's cabinet, and the colors of its screen.
enum MachineSkin: String, Codable, CaseIterable {
    case classic, chrome, gold, galaxy, ruby

    var cabinet: Color {
        switch self {
        case .classic: Color(red: 0.22, green: 0.10, blue: 0.36)
        case .chrome: Color(red: 0.62, green: 0.66, blue: 0.72)
        case .gold: Color(red: 0.78, green: 0.60, blue: 0.18)
        case .galaxy: Color(red: 0.08, green: 0.06, blue: 0.22)
        case .ruby: Color(red: 0.58, green: 0.06, blue: 0.14)
        }
    }
    /// The neon trim around the topper and the machine's screen accent.
    var trim: Color {
        switch self {
        case .classic: Color(red: 0.45, green: 1.0, blue: 0.45)
        case .chrome: Color(red: 0.55, green: 0.90, blue: 1.0)
        case .gold: Color(red: 1.0, green: 0.95, blue: 0.60)
        case .galaxy: Color(red: 0.85, green: 0.50, blue: 1.0)
        case .ruby: Color(red: 1.0, green: 0.55, blue: 0.60)
        }
    }
    var screenTop: Color {
        switch self {
        case .classic: Color(red: 0.10, green: 0.04, blue: 0.24)
        case .chrome: Color(red: 0.14, green: 0.18, blue: 0.26)
        case .gold: Color(red: 0.26, green: 0.16, blue: 0.04)
        case .galaxy: Color(red: 0.20, green: 0.04, blue: 0.32)
        case .ruby: Color(red: 0.26, green: 0.03, blue: 0.08)
        }
    }
    var screenBottom: Color {
        switch self {
        case .classic: Color(red: 0.02, green: 0.01, blue: 0.08)
        case .chrome: Color(red: 0.03, green: 0.04, blue: 0.07)
        case .gold: Color(red: 0.07, green: 0.04, blue: 0.01)
        case .galaxy: Color(red: 0.02, green: 0.01, blue: 0.10)
        case .ruby: Color(red: 0.06, green: 0.01, blue: 0.02)
        }
    }
    /// The backs of the cards on the machine's screen.
    var backTop: Color {
        switch self {
        case .classic: Color(red: 0.25, green: 0.60, blue: 0.30)
        case .chrome: Color(red: 0.45, green: 0.55, blue: 0.68)
        case .gold: Color(red: 0.85, green: 0.65, blue: 0.20)
        case .galaxy: Color(red: 0.45, green: 0.20, blue: 0.75)
        case .ruby: Color(red: 0.80, green: 0.15, blue: 0.25)
        }
    }
    var backBottom: Color {
        switch self {
        case .classic: Color(red: 0.08, green: 0.25, blue: 0.10)
        case .chrome: Color(red: 0.15, green: 0.20, blue: 0.28)
        case .gold: Color(red: 0.40, green: 0.26, blue: 0.05)
        case .galaxy: Color(red: 0.12, green: 0.05, blue: 0.30)
        case .ruby: Color(red: 0.30, green: 0.04, blue: 0.08)
        }
    }
}

/// How the Roswell of Poker sounds when it talks.
enum MachineVoice: String, Codable, CaseIterable {
    case classic, deepSpace, chipmunk, robot

    var pitch: Float {
        switch self {
        case .classic: 0.75
        case .deepSpace: 0.5
        case .chipmunk: 1.8
        case .robot: 1.0
        }
    }
    var rate: Float {
        switch self {
        case .classic: 0.95
        case .deepSpace: 0.8
        case .chipmunk: 1.15
        case .robot: 0.7
        }
    }
}

/// One person's look: her favorite alien color, her extra alien features, and what she wears as a human.
struct Look: Codable, Equatable {
    var color: AlienColor?
    var features: Set<AlienFeature> = []
    var outfit: Outfit?
    var accessories: Set<Accessory> = []
}

/// One thing on the shop's shelves.
enum ShopThing: Hashable, Identifiable {
    case color(AlienColor), feature(AlienFeature), outfit(Outfit), accessory(Accessory)
    case felt(FeltColor), carpet(CarpetStyle), neon(NeonColor), extra(DecorExtra), skin(MachineSkin), voice(MachineVoice)

    var id: String { key }

    var key: String {
        switch self {
        case .color(let c): "color.\(c.rawValue)"
        case .feature(let f): "feature.\(f.rawValue)"
        case .outfit(let o): "outfit.\(o.rawValue)"
        case .accessory(let a): "accessory.\(a.rawValue)"
        case .felt(let f): "felt.\(f.rawValue)"
        case .carpet(let c): "carpet.\(c.rawValue)"
        case .neon(let n): "neon.\(n.rawValue)"
        case .extra(let e): "extra.\(e.rawValue)"
        case .skin(let s): "skin.\(s.rawValue)"
        case .voice(let v): "voice.\(v.rawValue)"
        }
    }

    var category: ShopCategory {
        switch self {
        case .color, .feature: .alien
        case .outfit, .accessory: .outfits
        case .felt, .carpet, .neon, .extra: .decor
        case .skin, .voice: .machine
        }
    }

    /// Which group it's shown under in its department.
    var section: String {
        switch self {
        case .color: "Favorite Alien Color"
        case .feature: "Alien Features"
        case .outfit: "Outfits (worn as a human)"
        case .accessory: "Accessories"
        case .felt: "Table Felt"
        case .carpet: "Carpet"
        case .neon: "Neon Lights"
        case .extra: "Decorations"
        case .skin: "Cabinet"
        case .voice: "Machine Voice"
        }
    }

    var name: String {
        switch self {
        case .color(let c): c.name.capitalized
        case .feature(let f):
            switch f {
            case .antennae: "Antennae"
            case .spots: "Cosmic Spots"
            case .glow: "Alien Glow"
            case .bigEyes: "Extra-Big Eyes"
            case .rosyCheeks: "Rosy Cheeks"
            }
        case .outfit(let o):
            switch o {
            case .sundress: "Sundress"
            case .sparkleGown: "Sparkle Gown"
            case .redCarpet: "Red Carpet Dress"
            case .denim: "Jeans & Tee"
            case .galaxy: "Galaxy Outfit"
            case .tracksuit: "Pink Tracksuit"
            }
        case .accessory(let a):
            switch a {
            case .sunHat: "Sun Hat"
            case .sunglasses: "Sunglasses"
            case .necklace: "Pearl Necklace"
            case .handbag: "Handbag"
            case .tiara: "Tiara"
            }
        case .felt(let f): "\(f.rawValue.capitalized) Felt"
        case .carpet(let c):
            switch c {
            case .red: "Red & Gold"
            case .gold: "Gold Diamond"
            case .starry: "Starry Night"
            case .emerald: "Emerald"
            }
        case .neon(let n): "\(n.rawValue.capitalized) Neon"
        case .extra(let e):
            switch e {
            case .discoBall: "Disco Ball"
            case .palms: "Potted Palms"
            case .lavaLamps: "Lava Lamps"
            }
        case .skin(let s):
            switch s {
            case .classic: "Classic Purple"
            case .chrome: "Chrome"
            case .gold: "Solid Gold"
            case .galaxy: "Galaxy"
            case .ruby: "Ruby Red"
            }
        case .voice(let v):
            switch v {
            case .classic: "Classic"
            case .deepSpace: "Deep Space"
            case .chipmunk: "Chipmunk"
            case .robot: "Robot"
            }
        }
    }

    var detail: String {
        switch self {
        case .color: "Her alien color every time she changes"
        case .feature(let f):
            switch f {
            case .antennae: "Two bobbing antennae"
            case .spots: "Freckle-like spots all over"
            case .glow: "A soft glow around her"
            case .bigEyes: "Even bigger almond eyes"
            case .rosyCheeks: "Pink cheeks on her alien face"
            }
        case .outfit(let o): o.isDress ? "A dress for casino nights" : "A new everyday look"
        case .accessory: "Worn as a human"
        case .felt: "The card table's felt"
        case .carpet: "The casino floor"
        case .neon: "Sign, marquee and string lights"
        case .extra(let e):
            switch e {
            case .discoBall: "Spins over the slots"
            case .palms: "Tropical plants by the tables"
            case .lavaLamps: "Glowing on top of the slots"
            }
        case .skin: "The Roswell of Poker's cabinet and screen"
        case .voice: "How the machine talks"
        }
    }

    var price: Int {
        switch self {
        case .color(let c): AlienColor.basic.contains(c) ? 0 : (c == .gold || c == .silver ? 90 : 60)
        case .feature(let f):
            switch f {
            case .antennae: 50
            case .spots: 40
            case .glow: 75
            case .bigEyes: 45
            case .rosyCheeks: 30
            }
        case .outfit(let o):
            switch o {
            case .sundress: 45
            case .sparkleGown: 80
            case .redCarpet: 90
            case .denim: 35
            case .galaxy: 65
            case .tracksuit: 40
            }
        case .accessory(let a):
            switch a {
            case .sunHat: 25
            case .sunglasses: 20
            case .necklace: 30
            case .handbag: 35
            case .tiara: 40
            }
        case .felt(let f): f == .green ? 0 : 60
        case .carpet(let c): c == .red ? 0 : 75
        case .neon(let n): n == .green ? 0 : 40
        case .extra(let e):
            switch e {
            case .discoBall: 70
            case .palms: 30
            case .lavaLamps: 45
            }
        case .skin(let s):
            switch s {
            case .classic: 0
            case .chrome: 80
            case .gold: 120
            case .galaxy: 100
            case .ruby: 80
            }
        case .voice(let v): v == .classic ? 0 : 35
        }
    }

    var icon: String {
        switch self {
        case .color: "paintpalette.fill"
        case .feature(let f):
            switch f {
            case .antennae: "antenna.radiowaves.left.and.right"
            case .spots: "circle.hexagongrid.fill"
            case .glow: "sun.max.fill"
            case .bigEyes: "eye.fill"
            case .rosyCheeks: "heart.fill"
            }
        case .outfit: "tshirt.fill"
        case .accessory(let a):
            switch a {
            case .sunHat: "sun.haze.fill"
            case .sunglasses: "eyeglasses"
            case .necklace: "circle.dotted"
            case .handbag: "handbag.fill"
            case .tiara: "crown.fill"
            }
        case .felt: "rectangle.fill"
        case .carpet: "square.grid.3x3.fill"
        case .neon: "lightbulb.fill"
        case .extra(let e):
            switch e {
            case .discoBall: "circle.grid.cross.fill"
            case .palms: "leaf.fill"
            case .lavaLamps: "drop.fill"
            }
        case .skin: "rectangle.portrait.fill"
        case .voice: "speaker.wave.3.fill"
        }
    }

    /// A color swatch for the item's card, where it has one.
    var swatch: Color? {
        switch self {
        case .color(let c): c.skin.color
        case .outfit(let o): o.top.color
        case .felt(let f): f.color
        case .carpet(let c): c.base
        case .neon(let n): n.color
        case .skin(let s): s.cabinet
        default: nil
        }
    }

    static func shelf(_ category: ShopCategory) -> [ShopThing] {
        switch category {
        case .alien: AlienColor.allCases.map(ShopThing.color) + AlienFeature.allCases.map(ShopThing.feature)
        case .outfits: Outfit.allCases.map(ShopThing.outfit) + Accessory.allCases.map(ShopThing.accessory)
        case .decor: FeltColor.allCases.map(ShopThing.felt) + CarpetStyle.allCases.map(ShopThing.carpet)
            + NeonColor.allCases.map(ShopThing.neon) + DecorExtra.allCases.map(ShopThing.extra)
        case .machine: MachineSkin.allCases.map(ShopThing.skin) + MachineVoice.allCases.map(ShopThing.voice)
        }
    }
}

/// Everything the family has bought and is using. Saved with the game's progress; a new game starts with none of it.
struct Customization: Codable, Equatable {
    /// Bought items: "Mom|color.purple" for one person's things, "felt.blue" for the casino's.
    var owned: Set<String> = []
    var looks: [String: Look] = [:]
    var felt = FeltColor.green
    var carpet = CarpetStyle.red
    var neon = NeonColor.green
    var extras: Set<DecorExtra> = []
    var skin = MachineSkin.classic
    var voice = MachineVoice.classic
    /// Everything spent at Cosmic Customs so far.
    var spent = 0

    private func ownKey(_ t: ShopThing, _ who: String?) -> String {
        t.category.perPerson ? "\(who ?? "")|\(t.key)" : t.key
    }

    func owns(_ t: ShopThing, for who: String?) -> Bool { t.price == 0 || owned.contains(ownKey(t, who)) }

    mutating func markOwned(_ t: ShopThing, for who: String?) { owned.insert(ownKey(t, who)) }

    /// In use right now.
    func isOn(_ t: ShopThing, for who: String?) -> Bool {
        let look = who.flatMap { looks[$0] } ?? Look()
        return switch t {
        case .color(let c): look.color == c
        case .feature(let f): look.features.contains(f)
        case .outfit(let o): look.outfit == o
        case .accessory(let a): look.accessories.contains(a)
        case .felt(let f): felt == f
        case .carpet(let c): carpet == c
        case .neon(let n): neon == n
        case .extra(let e): extras.contains(e)
        case .skin(let s): skin == s
        case .voice(let v): voice == v
        }
    }

    /// Puts an owned item on, or takes it off. A favorite color or an outfit taken off goes back to random colors or everyday clothes;
    /// the casino always has one felt, carpet, neon, cabinet and voice, so tapping the one in use does nothing.
    mutating func toggle(_ t: ShopThing, for who: String?) {
        let on = isOn(t, for: who)
        if let who {
            var look = looks[who] ?? Look()
            switch t {
            case .color(let c): look.color = on ? nil : c
            case .feature(let f): if on { look.features.remove(f) } else { look.features.insert(f) }
            case .outfit(let o): look.outfit = on ? nil : o
            case .accessory(let a): if on { look.accessories.remove(a) } else { look.accessories.insert(a) }
            default: break
            }
            looks[who] = look
        }
        switch t {
        case .felt(let f): felt = f
        case .carpet(let c): carpet = c
        case .neon(let n): neon = n
        case .extra(let e): if on { extras.remove(e) } else { extras.insert(e) }
        case .skin(let s): skin = s
        case .voice(let v): voice = v
        default: break
        }
    }
}

// MARK: - The shop screen

/// Cosmic Customs: buy and put on alien looks, outfits, casino decor and Roswell of Poker upgrades.
/// Opened when Mom stops in at the end of the day, or from the button between days.
struct ShopView: View {
    let director: Director
    let done: () -> Void
    @State private var tab = ShopCategory.alien
    @State private var who = "Mom"
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Spending money: $\(director.spendable)")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .contentTransition(.numericText())
                    Text("Paid from the bank ($\(director.bank)) first, then any cash above the $\(CasinoGame.startCash) Mom keeps for the tables. Anything you've bought can be put on or taken off for free.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Picker("Department", selection: $tab) {
                        ForEach(ShopCategory.allCases) { Label($0.name, systemImage: $0.icon).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if tab.perPerson {
                        Picker("For", selection: $who) {
                            ForEach(director.cast.map(\.id), id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        LookPreview(person: director.cast.first { $0.id == who } ?? director.mom,
                                    look: director.custom.looks[who] ?? Look())
                            .frame(height: 170)
                    }

                    if let message {
                        Text(message)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.yellow.opacity(0.25), in: Capsule())
                    }

                    let shelf = ShopThing.shelf(tab)
                    ForEach(sections(shelf), id: \.self) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section).font(.system(.headline, design: .rounded, weight: .heavy))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                                ForEach(shelf.filter { $0.section == section }) { item in
                                    itemButton(item)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .animation(.default, value: director.spendable)
            }
            .navigationTitle("Cosmic Customs")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: done)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 640)
        #endif
    }

    private func sections(_ shelf: [ShopThing]) -> [String] {
        var seen: [String] = []
        for item in shelf where !seen.contains(item.section) { seen.append(item.section) }
        return seen
    }

    private func itemButton(_ item: ShopThing) -> some View {
        let person = tab.perPerson ? who : nil
        let owned = director.custom.owns(item, for: person)
        let on = director.custom.isOn(item, for: person)
        return Button {
            message = director.shopTap(item, for: person)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if let swatch = item.swatch {
                        Circle().fill(swatch).frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
                    } else {
                        Image(systemName: item.icon).font(.title2)
                    }
                }
                .frame(height: 32)
                Text(item.name).font(.system(.subheadline, design: .rounded, weight: .heavy))
                Text(item.detail).font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
                Text(on ? "In use ✓" : owned ? (item.price == 0 ? "Free · tap to use" : "Owned · tap to use") : "$\(item.price)")
                    .font(.caption.bold())
                    .foregroundStyle(on ? .green : owned ? .primary : (director.spendable >= item.price ? .orange : .red))
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(6)
            .background(on ? Color.green.opacity(0.18) : Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(on ? Color.green : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}

/// The person you're shopping for, side by side as a human and as an alien, wearing what she has on.
struct LookPreview: View {
    let person: Person
    let look: Look

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 15)) { timeline in
            Canvas { ctx, size in
                let human = person.preview(look: look, alien: false)
                let alien = person.preview(look: look, alien: true)
                let scale = min(1.6, (size.height - 30) / (person.height * 1.25))
                for (i, p) in [human, alien].enumerated() {
                    var c = ctx
                    let x = size.width * (i == 0 ? 0.33 : 0.67)
                    c.translateBy(x: x, y: size.height - 18)
                    c.scaleBy(x: scale, y: scale)
                    drawPerson(c, p, feet: .zero, facing: 0, now: timeline.date)
                    ctx.draw(Text(i == 0 ? "Human" : "Alien").font(.caption2.bold()).foregroundStyle(.secondary),
                             at: CGPoint(x: x, y: size.height - 7))
                }
            }
        }
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

extension Person {
    /// A stand-in for the shop's preview: same looks, standing still, fully human or fully alien.
    func preview(look: Look, alien: Bool) -> Person {
        let p = Person(id, height: height, headScale: headScale, skin: skin, hair: hair, style: style,
                       shirt: shirt, pants: pants, kid: isKid, x: 0)
        p.look = look
        p.alienColor = look.color ?? alienColor
        p.alien = alien
        if !alien { p.changeT0 = .distantFuture }
        return p
    }
}
