import SwiftUI

/// The card table seen from above while a game is dealt: the felt oval with everyone seated around it,
/// you at the bottom and the house (or dealer) at the top, the dealer's cards in the middle,
/// and your hand and choices along the bottom.
struct CasinoTableView: View {
    let director: Director
    let board: TableBoard

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(board.game.name) · \(board.status)")
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                Spacer()
                Text("Cash $\(director.cash)")
                    .font(.system(.headline, design: .rounded, weight: .heavy).monospacedDigit())
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .padding(.horizontal)

            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        Ellipse()
                            .fill(RadialGradient(colors: [felt.opacity(0.95), felt.opacity(0.7)], center: .center,
                                                 startRadius: 10, endRadius: size.width * 0.6))
                            .overlay(Ellipse().strokeBorder(Color(red: 0.45, green: 0.25, blue: 0.1), lineWidth: 14))
                            .overlay(Ellipse().strokeBorder(Color.yellow.opacity(0.5), lineWidth: 2).padding(7))
                            .padding(.horizontal, size.width * 0.12)
                            .padding(.vertical, size.height * 0.12)

                        // The dealer's cards (or the community cards, or the trump) and what just happened.
                        VStack(spacing: 6) {
                            ForEach(Array(center.enumerated()), id: \.offset) { _, group in
                                CardGroup(group: group, width: min(40, size.width * 0.075))
                            }
                            Text(director.caption)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .frame(maxWidth: size.width * 0.55)
                        }
                        .position(x: size.width * 0.5, y: size.height * 0.48)

                        ForEach(Array(board.rows.enumerated()), id: \.offset) { row, info in
                            let p = spot(row)
                            SeatView(person: director.tableSeats[safe: row], info: info, label: label(row, info),
                                     cards: cards(row), isYou: row == director.humanRow,
                                     yourTurn: row == director.humanRow && director.prompt != nil,
                                     says: says(row, at: timeline.date))
                                .position(x: size.width * p.x, y: size.height * p.y)
                        }
                    }
                }
            }
            .frame(minHeight: 520)

            actionBar
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(LinearGradient(colors: [Color(red: 0.30, green: 0.06, blue: 0.10), Color(red: 0.10, green: 0.02, blue: 0.05)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 12))
        .animation(.default, value: director.cash)
    }

    private let felt = Color(red: 0.08, green: 0.45, blue: 0.25)

    /// Rows go clockwise from you at the bottom.
    private func spot(_ row: Int) -> CGPoint {
        let n = board.rows.count
        let bottom = CGPoint(x: 0.5, y: 0.86), top = CGPoint(x: 0.5, y: 0.14)
        let me = director.humanRow ?? 0
        let around = (row - me + n) % n
        let ring = n == 3 ? [bottom, CGPoint(x: 0.16, y: 0.3), CGPoint(x: 0.84, y: 0.3)]
                          : [bottom, CGPoint(x: 0.12, y: 0.5), top, CGPoint(x: 0.88, y: 0.5)]
        return ring[around]
    }

    private func label(_ row: Int, _ info: BoardRow) -> String {
        if row == director.humanRow { return "\(info.id) · You" }
        return info.id
    }

    /// Scoreboard rows line up with the game's seats.
    private func seat(_ row: Int) -> Int? { row }

    private var center: [FeltGroup] { director.tableGroups.filter { $0.seat == nil } }

    private func cards(_ row: Int) -> [FeltGroup] {
        guard let s = seat(row) else { return [] }
        return director.tableGroups.filter { $0.seat == s }
    }

    private func says(_ row: Int, at now: Date) -> String? {
        guard let p = director.tableSeats[safe: row], let text = p.says, now < p.saysUntil else { return nil }
        return text
    }

    // MARK: Your hand and choices

    @State private var picked: [PlayingCard] = []

    @ViewBuilder private var actionBar: some View {
        VStack(spacing: 8) {
            // Your whole hand is shown here.
            if !director.myHand.isEmpty {
                GeometryReader { geo in
                    let hand = director.myHand
                    let w = 44.0
                    let step = min(w + 4, (geo.size.width - w) / Double(max(hand.count - 1, 1)))
                    HStack(spacing: step - w) {
                        ForEach(hand, id: \.self) { card in
                            CardButton(card: card, state: state(card), width: w) { tap(card) }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 70)
            }
            HStack {
                if let prompt = director.prompt {
                    Text(prompt.title)
                        .font(.system(.callout, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(director.you == nil ? "Watching the game." : "Waiting for the others…")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                if director.you != nil {
                    Toggle("Play for me", isOn: Binding(get: { director.autoPlay }, set: {
                        director.autoPlay = $0
                        if $0 { director.releasePrompt() }
                    }))
                    .toggleStyle(.switch)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .fixedSize()
                }
            }
            if let prompt = director.prompt {
                HStack(spacing: 8) {
                    ForEach(Array(prompt.options.enumerated()), id: \.offset) { i, option in
                        actionButton(option, i == 0 && prompt.options.count > 1 && option.contains("Fold") ? .gray : .pink) {
                            director.answer(.option(i))
                        }
                    }
                    if let n = prompt.pick {
                        actionButton("Done (\(picked.count)/\(n))", .green) {
                            director.answer(.cards(picked))
                            picked = []
                        }
                        .disabled(picked.count != n)
                        .opacity(picked.count == n ? 1 : 0.5)
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .onChange(of: director.prompt == nil) { picked = [] }
    }

    private func state(_ card: PlayingCard) -> CardButton.State {
        guard let prompt = director.prompt else { return .idle }
        if prompt.pick != nil { return picked.contains(card) ? .picked : .playable }
        if let playable = prompt.playable { return playable.contains(card) ? .playable : .dimmed }
        return .idle
    }

    private func tap(_ card: PlayingCard) {
        guard let prompt = director.prompt else { return }
        if let n = prompt.pick {
            if let i = picked.firstIndex(of: card) { picked.remove(at: i) } else if picked.count < n { picked.append(card) }
        } else if prompt.playable?.contains(card) == true {
            director.answer(.card(card))
        }
    }

    private func actionButton(_ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// One seat: a round portrait, name, chips or score, her cards and a note.
private struct SeatView: View {
    let person: Person?
    let info: BoardRow
    let label: String
    let cards: [FeltGroup]
    let isYou: Bool
    let yourTurn: Bool
    let says: String?
    var compact = false

    var body: some View {
        VStack(spacing: 2) {
            Headshot(person: person)
                .frame(width: compact ? 46 : 62, height: compact ? 46 : 62)
                .background(Circle().fill(Color.white.opacity(0.15)))
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(yourTurn ? Color.yellow : isYou ? Color.pink : Color.white.opacity(0.4),
                                               lineWidth: yourTurn || isYou ? 3 : 1))
                .overlay(alignment: .topTrailing) {
                    if let team = info.team {
                        Circle().fill(team == 0 ? Color.blue : .orange).frame(width: 14, height: 14)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                    }
                }
                .opacity(info.out ? 0.45 : 1)
                .overlay(alignment: .top) {
                    if let says {
                        Text(says)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8))
                            .frame(width: 150)
                            .fixedSize(horizontal: false, vertical: true)
                            .offset(y: -40)
                    }
                }
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 3) {
                Circle().fill(Color.red).frame(width: 9, height: 9)
                    .overlay(Circle().strokeBorder(.white, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2])))
                Text(info.value)
                    .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.yellow)
            }
            ForEach(Array(cards.enumerated()), id: \.offset) { _, group in
                // Players' cards are big; four or more fan out overlapping so they still fit the seat.
                CardGroup(group: group, width: group.cards.count > 4 ? 32 : group.cards.count > 2 ? 44 : 60, fan: group.cards.count > 3)
            }
            if !info.note.isEmpty {
                Text(info.note)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(Capsule().fill(.white.opacity(0.9)))
                    .lineLimit(1)
                    .frame(maxWidth: 150)
            }
        }
        .frame(width: compact ? 100 : 130)
    }
}

/// A row of cards with an optional label under it.
private struct CardGroup: View {
    let group: FeltGroup
    let width: Double
    /// Overlap the cards, showing each one's corner.
    var fan = false

    var body: some View {
        VStack(spacing: 2) {
            if !group.cards.isEmpty {
                HStack(spacing: fan ? -width * 0.5 : 2) {
                    ForEach(Array(group.cards.enumerated()), id: \.offset) { i, card in
                        CardFace(card: card, faceDown: group.hidden.contains(i), width: width, corner: fan)
                            .padding(.leading, i == group.splitAt ? width * 0.3 : 0)
                    }
                }
            }
            if let label = group.label {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
        }
    }
}

/// A playing card, face up or showing its back.
struct CardFace: View {
    let card: PlayingCard
    var faceDown = false
    var width = 34.0
    /// Rank and suit in the top-left corner, for overlapping cards.
    var corner = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width * 0.14)
        Group {
            if faceDown {
                shape.fill(Color(red: 0.20, green: 0.30, blue: 0.70))
                    .overlay(shape.inset(by: width * 0.1).strokeBorder(.white.opacity(0.7), lineWidth: 1))
            } else {
                VStack(spacing: 0) {
                    Text(card.rankText).font(.system(size: width * (corner ? 0.34 : 0.42), weight: .heavy, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(card.suitText).font(.system(size: width * (corner ? 0.36 : 0.48)))
                }
                .foregroundStyle(card.isRed ? .red : .black)
                .frame(width: corner ? width * 0.5 : nil)
                .padding(.top, corner ? width * 0.06 : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner ? .topLeading : .center)
                .background(.white, in: shape)
                .overlay(shape.strokeBorder(.black.opacity(0.25), lineWidth: 1))
            }
        }
        .frame(width: width, height: width * 1.4)
    }
}

/// Someone's face, drawn with the same code as the stage.
private struct Headshot: View {
    let person: Person?

    var body: some View {
        Canvas { ctx, size in
            guard let p = person else { return }
            let pose = Pose(p, feet: .zero, facing: 0, now: .now, still: true)
            let top = pose.headTop - pose.hr * 0.4
            let bottom = pose.torso.minY + pose.torso.height * 0.45
            let scale = size.height * 0.95 / (bottom - top)
            var c = ctx
            c.translateBy(x: size.width / 2, y: size.height * 0.05 - top * scale)
            c.scaleBy(x: scale, y: scale)
            drawPerson(c, p, feet: .zero, facing: 0, now: .distantPast)
        }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
