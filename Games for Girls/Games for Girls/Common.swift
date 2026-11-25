import SwiftUI

/// A die face. `pip` is the pip color (Call It uses red or black pips on white dice).
struct DieView: View {
    var value: Int
    var face: Color = .white
    var pip: Color = .black
    var size: CGFloat = 44
    var dim = false

    var body: some View {
        Canvas { ctx, sz in
            let r = CGRect(origin: .zero, size: sz).insetBy(dx: 1, dy: 1)
            ctx.fill(Path(roundedRect: r, cornerRadius: sz.width * 0.18), with: .color(face))
            ctx.stroke(Path(roundedRect: r, cornerRadius: sz.width * 0.18), with: .color(.black.opacity(0.35)), lineWidth: 1)
            let s = sz.width
            let spots: [[(CGFloat, CGFloat)]] = [
                [],
                [(0.5, 0.5)],
                [(0.27, 0.27), (0.73, 0.73)],
                [(0.27, 0.27), (0.5, 0.5), (0.73, 0.73)],
                [(0.27, 0.27), (0.73, 0.27), (0.27, 0.73), (0.73, 0.73)],
                [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)],
                [(0.27, 0.25), (0.73, 0.25), (0.27, 0.5), (0.73, 0.5), (0.27, 0.75), (0.73, 0.75)],
            ]
            for (x, y) in spots[max(0, min(6, value))] {
                let d = s * 0.17
                ctx.fill(Path(ellipseIn: CGRect(x: x * s - d / 2, y: y * s - d / 2, width: d, height: d)), with: .color(pip))
            }
        }
        .frame(width: size, height: size)
        .opacity(dim ? 0.35 : 1)
    }
}

/// Small avatar of a seat's girl.
struct Avatar: View {
    var look: Look
    var size: CGFloat = 40
    var mood: Mood = .happy

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 12)) { _ in
            Canvas { ctx, sz in
                drawBust(ctx, size: sz, look: look, girl: true, mood: mood)
            }
        }
        .frame(width: size, height: size)
        .background(Circle().fill(Color.white))
        .clipShape(Circle())
        .overlay(Circle().stroke(Palette.pink.opacity(0.5), lineWidth: 1.5))
    }
}

func later(_ seconds: Double, _ f: @escaping @MainActor () -> Void) {
    Task { @MainActor in
        try? await Task.sleep(for: .seconds(seconds))
        f()
    }
}

/// Pink / green colour picker shown before a two-colour game starts.
struct ColorChoice: View {
    @Binding var pinkIsMine: Bool
    var style: PieceStyle = .classic
    var start: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text("Pick your color").font(.title3.bold())
            HStack(spacing: 24) {
                chip(true)
                chip(false)
            }
            Button("Start") { start() }.buttonStyle(.borderedProminent).tint(Palette.pink).controlSize(.large)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(.background))
        .shadow(radius: 8)
    }

    private func chip(_ pink: Bool) -> some View {
        Button { pinkIsMine = pink; Sound.shared.play(.chip) } label: {
            VStack {
                ChipView(color: pink ? style.a : style.b, pattern: style.pattern, size: 54)
                    .overlay(Circle().stroke(pinkIsMine == pink ? Color.black : .clear, lineWidth: 3).padding(-5))
                Text(pink ? style.aName : style.bName).font(.headline)
            }
        }
        .buttonStyle(.plain)
    }
}
