import SwiftUI

/// Story player. Runs continuously: each shot moves on by itself once its line has been spoken
/// (or after a reading pause when muted) and its animation has finished.
struct CutsceneView: View {
    let shots: [Shot]
    let context: SceneContext
    let onDone: () -> Void

    @State private var index = 0
    @State private var shotStart = Date()
    @State private var paused = false
    @State private var lineDone = false
    @State private var finished = false

    var body: some View {
        let shot = shots[min(index, shots.count - 1)]
        VStack(spacing: 0) {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                let elapsed = tl.date.timeIntervalSince(shotStart)
                let p = min(1, max(0, elapsed / max(0.01, shot.anim)))
                Canvas { ctx, size in
                    let s = min(size.width / 400, size.height / 260)
                    ctx.translateBy(x: (size.width - 400 * s) / 2, y: (size.height - 260 * s) / 2)
                    ctx.scaleBy(x: s, y: s)
                    ctx.clip(to: Path(CGRect(x: 0, y: 0, width: 400, height: 260)))
                    talkingLooks = lineDone ? [] : context.talkers(shot.speaker)
                    drawScene(&ctx, shot.scene, size: CGSize(width: 400, height: 260), p: p, t: t, sc: context)
                    talkingLooks = []
                }
            }
            .aspectRatio(400 / 260, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                if let sp = shot.speaker {
                    Text(sp).font(.headline).foregroundStyle(Palette.pink)
                }
                Text(shot.text).font(.title3.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(.background.secondary))
            .padding()
            .id(index)
            .transition(.opacity)

            Spacer(minLength: 8)
        }
        .onAppear { begin() }
    }

    private func begin() {
        shotStart = Date()
        lineDone = false
        let shot = shots[index]
        let me = index
        if let s = shot.sfx { Sound.shared.play(s) }
        let muted = Sound.shared.muted
        Sound.shared.say(shot.text, as: shot.voice) {
            // when muted there's no speech, so allow reading time instead
            let reading = muted ? max(2.2, Double(shot.text.count) * 0.055) : 0.7
            later(reading) { lineFinished(me) }
        }
        // safety net: if the speech engine never reports back, move on anyway
        later(max(4, Double(shot.text.count) * 0.09 + 3)) { lineFinished(me) }
    }

    private func lineFinished(_ shotIndex: Int) {
        guard shotIndex == index, !finished, !lineDone else { return }
        lineDone = true
        autoAdvance(shotIndex)
    }

    /// Moves on once the line is done, the shot's animation has played out, and we're not paused.
    private func autoAdvance(_ shotIndex: Int) {
        guard shotIndex == index, lineDone, !paused, !finished else { return }
        let remaining = shots[index].anim - Date().timeIntervalSince(shotStart) + 0.3
        if remaining > 0 {
            later(remaining) { autoAdvance(shotIndex) }
        } else {
            advance()
        }
    }

    private func advance() {
        guard !finished else { return }
        if index + 1 < shots.count {
            withAnimation(.easeInOut(duration: 0.25)) { index += 1 }
            begin()
        } else {
            finish()
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        Sound.shared.stopSpeaking()
        onDone()
    }
}
