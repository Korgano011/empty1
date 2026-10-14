import AVFoundation

/// Realtime-synthesised sounds (no audio files): the saucer's throbbing hum, the tractor beam,
/// the transformation machine's warble, a tingly sparkle, straps clunking shut, the green button's
/// beep, a crash of breaking glass and furniture, a police siren, a "ta-da" chime, a fading shimmer, a camera shutter, and a customer paying.
nonisolated final class Synth: @unchecked Sendable {
    // Targets, written from the main thread and read on the audio thread.
    var humT: Float = 0
    var beamT: Float = 0
    var zapT: Float = 0
    var sirenT: Float = 0
    var muted = false
    var chimeTrig = false
    var shimmerTrig = false
    var beepTrig = false
    var tingleTrig = false
    var clunkTrig = false
    var payTrig = false
    var shutterTrig = false
    var crashTrig = false
    var sampleRate: Float = 44100

    private var hum: Float = 0, beam: Float = 0, zap: Float = 0
    private var humPh: Float = 0, humLfo: Float = 0
    private var beamPh: Float = 0, beamLfo: Float = 0
    private var zapPh: Float = 0, zapLfo: Float = 0, zapT0: Float = 0
    private var lp: Float = 0
    private var siren: Float = 0, sirenPh: Float = 0, sirenLfo: Float = 0
    private var crashT: Float = 2, crashLp: Float = 0
    private var chimeT: Float = 2
    private var shimmerT: Float = 3
    private var beepT: Float = 1, beepPh: Float = 0
    private var tingleT: Float = 3
    private var clunkT: Float = 1
    private var shutterT: Float = 1
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
        if payTrig { payT = 0; payTrig = false }
        if crashTrig { crashT = 0; crashTrig = false }
        for i in 0..<frames {
            hum += (humT - hum) * 0.0008
            beam += (beamT - beam) * 0.002
            zap += (zapT - zap) * 0.002
            siren += (sirenT - siren) * 0.0006
            var s: Float = 0
            let n = rand()

            // A police siren: a tone sweeping up and down, a little over a second each way.
            if siren > 0.001 {
                sirenLfo += twoPi * 0.4 / sr
                if sirenLfo > twoPi { sirenLfo -= twoPi }
                sirenPh += twoPi * (700 + 320 * sin(sirenLfo)) / sr
                if sirenPh > twoPi { sirenPh -= twoPi }
                s += (sin(sirenPh) + 0.3 * sin(sirenPh * 2)) * siren * 0.07
            }

            // Smashing things: a thud, a burst of noise, and glass tinkling.
            if crashT < 1.6 {
                crashT += 1 / sr
                let t = crashT
                crashLp += (n - crashLp) * 0.08
                s += (sin(twoPi * 55 * t) * 0.6 + crashLp * 1.6) * exp(-t * 6)
                s += n * 0.35 * exp(-t * 3) * (0.5 + 0.5 * sin(twoPi * 31 * t))
                for (at, f): (Float, Float) in [(0.25, 4200), (0.38, 5100), (0.47, 3800), (0.6, 4700), (0.74, 5600), (0.9, 4400)] where t > at {
                    s += sin(twoPi * f * (t - at)) * 0.08 * exp(-(t - at) * 30)
                }
            }

            // Saucer: a low hum that throbs a few times a second.
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
    func siren(_ on: Bool) { synth.sirenT = on ? 1 : 0 }
    func stopAll() {
        hum(false)
        beam(false)
        zap(false)
        siren(false)
    }
    func beep() { synth.beepTrig = true }
    func tingle() { synth.tingleTrig = true }
    func clunk() { synth.clunkTrig = true }
    func chime() { synth.chimeTrig = true }
    func shimmer() { synth.shimmerTrig = true }
    func pay() { synth.payTrig = true }
    func shutter() { synth.shutterTrig = true }
    func crash() { synth.crashTrig = true }
}
