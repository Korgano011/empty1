import AVFoundation

/// Realtime-synthesised sounds (no audio files): the flying tent's throbbing hum (and the tow truck's engine), the tractor beam,
/// the transformation machine's warble, a tingly sparkle, straps clunking shut, the pink button's
/// beep, buzzing hair clippers, a clown's bulb horn, a "ta-da" chime, a fading shimmer, a camera shutter, and a customer paying.
nonisolated final class Synth: @unchecked Sendable {
    // Targets, written from the main thread and read on the audio thread.
    var humT: Float = 0
    var beamT: Float = 0
    var zapT: Float = 0
    var buzzT: Float = 0
    var muted = false
    var chimeTrig = false
    var shimmerTrig = false
    var beepTrig = false
    var tingleTrig = false
    var clunkTrig = false
    var payTrig = false
    var shutterTrig = false
    var honkTrig = false
    var sampleRate: Float = 44100

    private var hum: Float = 0, beam: Float = 0, zap: Float = 0
    private var humPh: Float = 0, humLfo: Float = 0
    private var beamPh: Float = 0, beamLfo: Float = 0
    private var zapPh: Float = 0, zapLfo: Float = 0, zapT0: Float = 0
    private var buzz: Float = 0, buzzPh: Float = 0, buzzLfo: Float = 0, buzzLp: Float = 0
    private var lp: Float = 0
    private var chimeT: Float = 2
    private var shimmerT: Float = 3
    private var beepT: Float = 1, beepPh: Float = 0
    private var tingleT: Float = 3
    private var clunkT: Float = 1
    private var shutterT: Float = 1
    private var honkT: Float = 1, honkPh: Float = 0
    private var payT: Float = 2, prevN: Float = 0
    private var seed: UInt32 = 2463534242

    private func rand() -> Float {
        seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
        return Float(seed) / Float(UInt32.max) * 2 - 1
    }

    func render(_ frames: Int, _ out: UnsafeMutablePointer<Float>) {
        let sr = sampleRate
        let twoPi = 2 * Float.pi
        if chimeTrig { chimeT = 0; chimeTrig = false }
        if shimmerTrig { shimmerT = 0; shimmerTrig = false }
        if beepTrig { beepT = 0; beepTrig = false }
        if tingleTrig { tingleT = 0; tingleTrig = false }
        if clunkTrig { clunkT = 0; clunkTrig = false }
        if shutterTrig { shutterT = 0; shutterTrig = false }
        if honkTrig { honkT = 0; honkTrig = false }
        if payTrig { payT = 0; payTrig = false }
        for i in 0..<frames {
            hum += (humT - hum) * 0.0008
            beam += (beamT - beam) * 0.002
            zap += (zapT - zap) * 0.002
            buzz += (buzzT - buzz) * 0.003
            var s: Float = 0
            let n = rand()

            // Flying tent: a low hum that throbs a few times a second.
            if hum > 0.001 {
                humLfo += twoPi * 3.2 / sr
                if humLfo > twoPi { humLfo -= twoPi }
                humPh += twoPi * (70 + 6 * sin(humLfo)) / sr
                if humPh > twoPi { humPh -= twoPi }
                s += (sin(humPh) + 0.5 * sin(humPh * 2) + 0.25 * sin(humPh * 3)) * hum * (0.55 + 0.45 * sin(humLfo)) * 0.16
            }

            // Tractor beam: a wobbling rising "wooo" over an airy hiss.
            if beam > 0.001 {
                beamLfo += twoPi * 6 / sr
                if beamLfo > twoPi { beamLfo -= twoPi }
                beamPh += twoPi * (440 + 90 * sin(beamLfo)) / sr
                if beamPh > twoPi { beamPh -= twoPi }
                lp += (n - lp) * 0.05
                s += (sin(beamPh) * 0.09 + lp * 0.5) * beam
            }

            // The machine: a warbling sci-fi sweep that climbs as the change moves up the body.
            if zap > 0.001 {
                zapT0 += 1 / sr
                zapLfo += twoPi * 9 / sr
                if zapLfo > twoPi { zapLfo -= twoPi }
                let f = 300 + 40 * zapT0 + 120 * sin(zapLfo)
                zapPh += twoPi * min(f, 1400) / sr
                if zapPh > twoPi { zapPh -= twoPi }
                s += (sin(zapPh) + 0.3 * (sin(zapPh * 2.01) > 0 ? 1 : -1)) * zap * 0.08
            } else {
                zapT0 = 0
            }

            // Hair clippers: a raspy 120 Hz motor buzz, wavering a little as the blades bite into the hair.
            if buzz > 0.001 {
                buzzLfo += twoPi * 7 / sr
                if buzzLfo > twoPi { buzzLfo -= twoPi }
                buzzPh += 120 / sr
                if buzzPh > 1 { buzzPh -= 1 }
                let saw = buzzPh * 2 - 1
                let sq: Float = buzzPh < 0.5 ? 1 : -1
                buzzLp += (n - buzzLp) * 0.3
                s += (saw * 0.6 + sq * 0.25 + sin(twoPi * buzzPh * 4) * 0.2 + buzzLp * 0.15) * buzz * (0.85 + 0.15 * sin(buzzLfo)) * 0.14
            }

            // Tingling: a scatter of tiny high pings.
            if tingleT < 2.4 {
                tingleT += 1 / sr
                for j in 0..<12 {
                    let at = Float(j) * 0.18
                    guard tingleT > at else { break }
                    let u = tingleT - at
                    let f: Float = 2800 + Float((j * 733) % 1600)
                    s += sin(twoPi * f * u) * 0.05 * exp(-u * 30)
                }
            }

            // Straps: a metallic clunk.
            if clunkT < 0.3 {
                clunkT += 1 / sr
                let u = clunkT
                s += (sin(twoPi * 120 * u) * 0.35 + sin(twoPi * 860 * u) * 0.08 + n * 0.1) * exp(-u * 25)
            }

            // "Ta-da!": a quick rising arpeggio, C-E-G-C.
            if chimeT < 1.2 {
                chimeT += 1 / sr
                for (k, f): (Float, Float) in [(0, 523), (0.08, 659), (0.16, 784), (0.24, 1047)] where chimeT > k {
                    let u = chimeT - k
                    s += (sin(twoPi * f * u) + 0.3 * sin(twoPi * f * 2 * u)) * 0.13 * exp(-u * 3.5)
                }
            }

            // Fading back: a soft falling shimmer of bell tones.
            if shimmerT < 2.2 {
                shimmerT += 1 / sr
                for j in 0..<8 {
                    let k = Float(j) * 0.18
                    guard shimmerT > k else { break }
                    let u = shimmerT - k
                    let f: Float = 2400 - Float(j) * 180
                    s += sin(twoPi * f * u) * 0.06 * exp(-u * 5)
                }
            }

            if beepT < 0.25 {
                beepT += 1 / sr
                beepPh += twoPi * (660 + 800 * beepT) / sr
                s += (sin(beepPh) > 0 ? 0.1 : -0.1) * (1 - beepT / 0.25)
            }

            // Bulb horn: two squeaky honks, each sagging in pitch.
            if honkT < 0.5 {
                honkT += 1 / sr
                let u = honkT < 0.26 ? honkT : honkT - 0.26
                if u < 0.2 {
                    honkPh += twoPi * (430 - 380 * u) / sr
                    if honkPh > twoPi { honkPh -= twoPi }
                    s += ((sin(honkPh) > 0 ? 0.12 : -0.12) + sin(honkPh * 2) * 0.06) * min(1, (0.2 - u) * 30)
                }
            }

            // Shutter: two short clicks.
            if shutterT < 0.2 {
                shutterT += 1 / sr
                if shutterT < 0.015 || (shutterT > 0.07 && shutterT < 0.085) { s += rand() * 0.5 }
            }
            // A customer pays: bills flick, the register goes "ching!", coins clink, the drawer thunks shut.
            let bright = n - prevN
            prevN = n
            if payT < 1.3 {
                payT += 1 / sr
                let t = payT
                for flick: Float in [0, 0.07] where t > flick && t < flick + 0.03 {
                    s += bright * 0.35 * (1 - (t - flick) / 0.03)
                }
                let cha: Float = 0.14
                if t > cha && t < cha + 0.06 { s += n * 0.45 * (1 - (t - cha) / 0.06) }
                for (at, f, decay): (Float, Float, Float) in [(cha + 0.05, 2093, 5), (cha + 0.14, 2637, 4)] where t > at {
                    s += sin(twoPi * f * (t - at)) * 0.22 * exp(-(t - at) * decay)
                }
                for (at, f): (Float, Float) in [(0.5, 3300), (0.56, 4100), (0.61, 3600), (0.65, 4400), (0.71, 3900)] where t > at && t < at + 0.12 {
                    let u = t - at
                    s += (sin(twoPi * f * u) + 0.5 * sin(twoPi * f * 2.4 * u)) * 0.09 * exp(-u * 45)
                }
                let thunk: Float = 1.0
                if t > thunk && t < thunk + 0.2 {
                    let u = t - thunk
                    s += (sin(twoPi * 85 * u) * 0.35 + n * 0.08) * exp(-u * 22)
                }
            }
            out[i] = muted ? 0 : tanhf(s) * 0.6
        }
    }

    static func makeNode(_ synth: Synth, _ format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { _, _, frames, abl in
            let list = UnsafeMutableAudioBufferListPointer(abl)
            guard let first = list.first, let data = first.mData else { return noErr }
            let p = data.bindMemory(to: Float.self, capacity: Int(frames))
            synth.render(Int(frames), p)
            for b in list.dropFirst() {
                if let d = b.mData { memcpy(d, data, Int(frames) * MemoryLayout<Float>.size) }
            }
            return noErr
        }
    }
}

final class Sound {
    private let synth = Synth()
    private var engine: AVAudioEngine?

    func prepare() {
        guard engine == nil else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        let e = AVAudioEngine()
        let sr = e.outputNode.outputFormat(forBus: 0).sampleRate
        synth.sampleRate = Float(sr > 0 ? sr : 44100)
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: Double(synth.sampleRate), channels: 1) else { return }
        let node = Synth.makeNode(synth, fmt)
        e.attach(node)
        try? e.connectNode(node, to: e.mainMixerNode, format: fmt)
        do { try e.start(); engine = e } catch { engine = nil }
    }

    var muted: Bool {
        get { synth.muted }
        set { synth.muted = newValue }
    }

    func hum(_ on: Bool) { synth.humT = on ? 1 : 0 }
    func beam(_ on: Bool) { synth.beamT = on ? 1 : 0 }
    func zap(_ on: Bool) { synth.zapT = on ? 1 : 0 }
    func buzz(_ on: Bool) { synth.buzzT = on ? 1 : 0 }
    func stopAll() {
        hum(false)
        beam(false)
        zap(false)
        buzz(false)
    }
    func beep() { synth.beepTrig = true }
    func tingle() { synth.tingleTrig = true }
    func clunk() { synth.clunkTrig = true }
    func chime() { synth.chimeTrig = true }
    func shimmer() { synth.shimmerTrig = true }
    func pay() { synth.payTrig = true }
    func shutter() { synth.shutterTrig = true }
    func honk() { synth.honkTrig = true }
}
