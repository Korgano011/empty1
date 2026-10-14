import AVFoundation

/// Realtime-synthesised sounds (no audio files): the hissing spray jets, the warm-air dryer,
/// a ding when the booth finishes and a cash-register ka-ching.
nonisolated final class Synth: @unchecked Sendable {
    // Targets, written from the main thread and read on the audio thread.
    var sprayT: Float = 0
    var dryerT: Float = 0
    var muted = false
    var dingTrig = false
    var chingTrig = false
    var sampleRate: Float = 44100

    private var spray: Float = 0
    private var hp: Float = 0, lp: Float = 0, lp2: Float = 0
    private var flutter: Float = 0
    private var dryer: Float = 0, airLp: Float = 0, fanPh: Float = 0
    private var dingEnv: Float = 0, dingPh: Float = 0
    private var chingT: Float = 1, chingPh1: Float = 0, chingPh2: Float = 0
    private var seed: UInt32 = 2463534242

    private func rand() -> Float {
        seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
        return Float(seed) / Float(UInt32.max) * 2 - 1
    }

    func render(_ frames: Int, _ out: UnsafeMutablePointer<Float>) {
        let sr = sampleRate
        let twoPi = 2 * Float.pi
        if dingTrig { dingEnv = 1; dingPh = 0; dingTrig = false }
        if chingTrig { chingT = 0; chingTrig = false }
        for i in 0..<frames {
            // Spray: band-limited noise with a fast attack and a jet flutter.
            let rate: Float = sprayT > spray ? 0.004 : 0.0006
            spray += (sprayT - spray) * rate
            flutter += twoPi * 7 / sr
            let n = rand()
            lp += (n - lp) * 0.55
            hp = lp - lp2
            lp2 += (lp - lp2) * 0.08
            let gate = 0.7 + 0.3 * sin(flutter)
            var s = hp * spray * gate * 1.4

            // Dryer: a soft, breathy rush of air over a low fan hum.
            dryer += (dryerT - dryer) * 0.0008
            if dryer > 0.001 {
                airLp += (n - airLp) * 0.12
                fanPh += twoPi * 120 / sr
                if fanPh > twoPi { fanPh -= twoPi }
                s += (airLp * 0.9 + sin(fanPh) * 0.1) * dryer
            }

            // Ding
            if dingEnv > 0.001 {
                dingPh += twoPi * 1320 / sr
                s += (sin(dingPh) + 0.35 * sin(dingPh * 2.76)) * dingEnv * 0.25
                dingEnv *= 0.99993
            }

            // Ka-ching: a noisy "cha", then two bright bell tones.
            if chingT < 1.2 {
                chingT += 1 / sr
                if chingT < 0.06 { s += rand() * 0.5 * (1 - chingT / 0.06) }
                if chingT > 0.05 {
                    chingPh1 += twoPi * 2093 / sr
                    s += sin(chingPh1) * 0.22 * exp(-(chingT - 0.05) * 5)
                }
                if chingT > 0.14 {
                    chingPh2 += twoPi * 2637 / sr
                    s += sin(chingPh2) * 0.22 * exp(-(chingT - 0.14) * 4)
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
        e.connect(node, to: e.mainMixerNode, format: fmt)
        do { try e.start(); engine = e } catch { engine = nil }
    }

    var muted: Bool {
        get { synth.muted }
        set { synth.muted = newValue }
    }

    func spray(_ on: Bool) { synth.sprayT = on ? 1 : 0 }
    func dryer(_ on: Bool) { synth.dryerT = on ? 1 : 0 }
    func ding() { synth.dingTrig = true }
    func ching() { synth.chingTrig = true }
}
