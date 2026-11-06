import AVFoundation

/// Realtime-synthesised sounds (no audio files): the emitters' motor, the beam's warbling hum,
/// the sparkle shimmer, the cooling mist, the button's beep, a ding, a camera shutter, a cash-register ka-ching and dealt cards.
nonisolated final class Synth: @unchecked Sendable {
    // Targets, written from the main thread and read on the audio thread.
    var motorT: Float = 0
    var beamT: Float = 0
    var sparkleT: Float = 0
    var mistT: Float = 0
    var muted = false
    var dingTrig = false
    var beepTrig = false
    var chingTrig = false
    var shutterTrig = false
    var dealTrig = false
    var sampleRate: Float = 44100

    private var motor: Float = 0, beam: Float = 0, sparkle: Float = 0, mist: Float = 0
    private var motorPh: Float = 0
    private var hp: Float = 0, fanPh: Float = 0
    private var wobPh: Float = 0, beamPh1: Float = 0, beamPh2: Float = 0
    private var lfoPh: Float = 0, sparkPh1: Float = 0, sparkPh2: Float = 0
    private var dingEnv: Float = 0, dingPh: Float = 0
    private var beepT: Float = 1, beepPh: Float = 0
    private var shutterT: Float = 1
    private var dealT: Float = 1
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
        if beepTrig { beepT = 0; beepTrig = false }
        if shutterTrig { shutterT = 0; shutterTrig = false }
        if chingTrig { chingT = 0; chingTrig = false }
        if dealTrig { dealT = 0; dealTrig = false }
        for i in 0..<frames {
            motor += (motorT - motor) * 0.002
            beam += (beamT - beam) * 0.002
            sparkle += (sparkleT - sparkle) * 0.001
            mist += (mistT - mist) * 0.0008
            var s: Float = 0

            // Emitter motor: a soft rising whirr.
            if motor > 0.001 {
                motorPh += twoPi * (95 + 25 * motor) / sr
                if motorPh > twoPi { motorPh -= twoPi }
                s += (sin(motorPh) + 0.4 * sin(motorPh * 3)) * motor * 0.18
            }

            let n = rand()
            // Sparkle: a high, twinkling shimmer of two detuned tones fluttering in and out.
            if sparkle > 0.001 {
                lfoPh += twoPi * 9 / sr
                if lfoPh > twoPi { lfoPh -= twoPi }
                sparkPh1 += twoPi * 1760 / sr
                sparkPh2 += twoPi * 2349 / sr
                if sparkPh1 > twoPi { sparkPh1 -= twoPi }
                if sparkPh2 > twoPi { sparkPh2 -= twoPi }
                s += (sin(sparkPh1) + sin(sparkPh2)) * (0.5 + 0.5 * sin(lfoPh)) * sparkle * 0.06
            }
            // Cooling mist: breathy high-passed air plus a low fan hum.
            if mist > 0.001 {
                hp += (n - hp) * 0.6
                fanPh += twoPi * 140 / sr
                if fanPh > twoPi { fanPh -= twoPi }
                s += ((n - hp) * 0.5 + sin(fanPh) * 0.12) * mist
            }

            // Beam: a warbling flying-saucer hum, two tones sliding under a slow wobble.
            if beam > 0.001 {
                wobPh += twoPi * 5.5 / sr
                if wobPh > twoPi { wobPh -= twoPi }
                let f = 220 + 40 * sin(wobPh)
                beamPh1 += twoPi * f / sr
                beamPh2 += twoPi * f * 1.5 / sr
                if beamPh1 > twoPi { beamPh1 -= twoPi }
                if beamPh2 > twoPi { beamPh2 -= twoPi }
                s += (sin(beamPh1) * 0.7 + sin(beamPh2) * 0.3) * beam * 0.22
            }

            if beepT < 0.15 {
                beepT += 1 / sr
                beepPh += twoPi * 880 / sr
                s += (sin(beepPh) > 0 ? 0.12 : -0.12) * (1 - beepT / 0.15)
            }

            if dingEnv > 0.001 {
                dingPh += twoPi * 1320 / sr
                s += (sin(dingPh) + 0.35 * sin(dingPh * 2.76)) * dingEnv * 0.25
                dingEnv *= 0.99993
            }

            // Shutter: two short clicks.
            if shutterT < 0.2 {
                shutterT += 1 / sr
                if shutterT < 0.015 || (shutterT > 0.07 && shutterT < 0.085) { s += rand() * 0.5 }
            }
            // Dealing: a quick run of card flicks.
            if dealT < 0.5 {
                dealT += 1 / sr
                if dealT.truncatingRemainder(dividingBy: 0.09) < 0.012 { s += rand() * 0.35 }
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

    func motor(_ on: Bool) { synth.motorT = on ? 1 : 0 }
    func beam(_ on: Bool) { synth.beamT = on ? 1 : 0 }
    func sparkle(_ on: Bool) { synth.sparkleT = on ? 1 : 0 }
    func mist(_ on: Bool) { synth.mistT = on ? 1 : 0 }
    func stopAll() {
        motor(false)
        beam(false)
        sparkle(false)
        mist(false)
    }
    func beep() { synth.beepTrig = true }
    func ding() { synth.dingTrig = true }
    func ching() { synth.chingTrig = true }
    func shutter() { synth.shutterTrig = true }
    func deal() { synth.dealTrig = true }
}
