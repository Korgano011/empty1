import AVFoundation

/// Realtime-synthesised sounds (no audio files): the dome's motor, fizzing cream,
/// the rinse, the warm-air dryer, the button's beep, a ding, a camera shutter and a cash-register ka-ching.
nonisolated final class Synth: @unchecked Sendable {
    // Targets, written from the main thread and read on the audio thread.
    var motorT: Float = 0
    var gloopT: Float = 0
    var rinseT: Float = 0
    var dryerT: Float = 0
    var muted = false
    var dingTrig = false
    var beepTrig = false
    var chingTrig = false
    var shutterTrig = false
    var sampleRate: Float = 44100

    private var motor: Float = 0, gloop: Float = 0, rinse: Float = 0, dryer: Float = 0
    private var motorPh: Float = 0
    private var lp: Float = 0, lp2: Float = 0, hp: Float = 0, fanPh: Float = 0
    private var bubT: Float = 1, bubPh: Float = 0, bubF: Float = 300
    private var dingEnv: Float = 0, dingPh: Float = 0
    private var beepT: Float = 1, beepPh: Float = 0
    private var shutterT: Float = 1
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
        for i in 0..<frames {
            motor += (motorT - motor) * 0.002
            gloop += (gloopT - gloop) * 0.002
            rinse += (rinseT - rinse) * 0.001
            dryer += (dryerT - dryer) * 0.0008
            var s: Float = 0

            // Dome motor: a soft rising whirr.
            if motor > 0.001 {
                motorPh += twoPi * (95 + 25 * motor) / sr
                if motorPh > twoPi { motorPh -= twoPi }
                s += (sin(motorPh) + 0.4 * sin(motorPh * 3)) * motor * 0.18
            }

            let n = rand()
            // Rinse: rushing, low-passed water noise.
            if rinse > 0.001 {
                lp += (n - lp) * 0.25
                lp2 += (lp - lp2) * 0.4
                s += lp2 * rinse * 0.9
            }
            // Dryer: breathy high-passed air plus a low fan hum.
            if dryer > 0.001 {
                hp += (n - hp) * 0.6
                fanPh += twoPi * 140 / sr
                if fanPh > twoPi { fanPh -= twoPi }
                s += ((n - hp) * 0.5 + sin(fanPh) * 0.12) * dryer
            }

            // Cream: little bubbles popping, each a quick upward chirp.
            if gloop > 0.01 {
                if bubT >= 0.06 && n > 1 - 0.00035 * gloop * 44100 / sr * 2 {
                    bubT = 0
                    bubF = 250 + 500 * abs(rand())
                }
                lp += (n - lp) * 0.05
                s += lp * gloop * 0.15
            }
            if bubT < 0.06 {
                bubT += 1 / sr
                bubPh += twoPi * bubF * (1 + bubT * 25) / sr
                s += sin(bubPh) * (1 - bubT / 0.06) * 0.25
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
    func gloop(_ on: Bool) { synth.gloopT = on ? 1 : 0 }
    func rinse(_ on: Bool) { synth.rinseT = on ? 1 : 0 }
    func dryer(_ on: Bool) { synth.dryerT = on ? 1 : 0 }
    func stopAll() {
        motor(false)
        gloop(false)
        rinse(false)
        dryer(false)
    }
    func beep() { synth.beepTrig = true }
    func ding() { synth.dingTrig = true }
    func ching() { synth.chingTrig = true }
    func shutter() { synth.shutterTrig = true }
}
