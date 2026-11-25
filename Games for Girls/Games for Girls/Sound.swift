import AVFoundation

/// Synthesized sound effects (no audio files) plus spoken dialogue.
final class Sound: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Sound()

    enum Effect: CaseIterable {
        case click, dice, chip, coin, win, lose, horn, machine, sparkle, crash, truck, mop, flip, drop
    }

    enum Voice { case narrator, boss, repo, bank, hostess, mom, boy, girl, passerby, teller }

    var muted: Bool {
        get { UserDefaults.standard.bool(forKey: "muted") }
        set { UserDefaults.standard.set(newValue, forKey: "muted"); if newValue { stopSpeaking() } }
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let rate = 44100.0
    private let format: AVAudioFormat
    private var cache: [Effect: AVAudioPCMBuffer] = [:]
    private let speech = AVSpeechSynthesizer()
    private var started = false

    private var onSpoken: (() -> Void)?

    private override init() {
        format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)!
        super.init()
        speech.delegate = self
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            let f = self.onSpoken
            self.onSpoken = nil
            f?()
        }
    }

    private func start() {
        guard !started else { return }
        started = true
        #if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.6
        try? engine.start()
        player.play()
    }

    func play(_ e: Effect) {
        guard !muted else { return }
        start()
        guard engine.isRunning else { return }
        let buf = cache[e] ?? makeBuffer(e)
        cache[e] = buf
        player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }

    private func makeBuffer(_ e: Effect) -> AVAudioPCMBuffer {
        let s = samples(e)
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(s.count))!
        buf.frameLength = AVAudioFrameCount(s.count)
        let p = buf.floatChannelData![0]
        for i in 0..<s.count { p[i] = s[i] }
        return buf
    }

    private func samples(_ e: Effect) -> [Float] {
        let rate = self.rate
        func gen(_ dur: Double, _ f: (Double, Double) -> Double) -> [Float] {
            let n = Int(dur * rate)
            var out = [Float](repeating: 0, count: n)
            for i in 0..<n {
                let t = Double(i) / rate
                out[i] = Float(f(t, t / dur))
            }
            return out
        }
        var seed: UInt64 = 0x6F6F
        func noise() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(Int64(bitPattern: seed >> 11) % 2000) / 1000.0
        }
        func tone(_ f: Double, _ t: Double) -> Double { sin(2 * .pi * f * t) }
        switch e {
        case .click:
            return gen(0.05) { t, u in tone(1600, t) * 0.3 * (1 - u) }
        case .chip:
            return gen(0.09) { t, u in (tone(2400, t) * 0.3 + noise() * 0.15) * pow(1 - u, 3) }
        case .flip:
            return gen(0.12) { t, u in tone(600 + 900 * u, t) * 0.3 * (1 - u) }
        case .drop:
            return gen(0.25) { t, u in tone(900 - 600 * u, t) * 0.35 * (1 - u) }
        case .dice:
            // a few clatters
            return gen(0.5) { t, u in
                let hits = [0.0, 0.11, 0.2, 0.31, 0.4]
                var v = 0.0
                for h in hits where t >= h { v += noise() * 0.4 * exp(-(t - h) * 60) }
                return v * (1 - u * 0.5)
            }
        case .coin:
            return gen(0.35) { t, u in (t < 0.08 ? tone(988, t) : tone(1319, t)) * 0.3 * (1 - u) }
        case .win:
            let notes = [523.0, 659, 784, 1047]
            return gen(0.9) { t, u in
                let i = min(3, Int(t / 0.18))
                return (tone(notes[i], t) * 0.25 + tone(notes[i] * 2, t) * 0.08) * (1 - u * 0.7)
            }
        case .lose:
            let notes = [392.0, 370, 349, 330]
            return gen(1.1) { t, u in
                let i = min(3, Int(t / 0.26))
                return tone(notes[i] + sin(t * 30) * 4, t) * 0.25 * (1 - u * 0.5)
            }
        case .horn:
            return gen(1.4) { t, u in
                (tone(110, t) * 0.4 + tone(165, t) * 0.25 + tone(220, t) * 0.1) * min(1, u * 8) * min(1, (1 - u) * 5)
            }
        case .machine:
            return gen(2.0) { t, u in
                let warble = tone(220 + 330 * u + 30 * sin(t * 40), t)
                return (warble * 0.25 + tone(880 + 600 * u, t) * 0.08 * sin(t * 25)) * sin(.pi * u)
            }
        case .sparkle:
            return gen(0.9) { t, u in
                (tone(2600 + 800 * sin(t * 37), t) * 0.12 + tone(3500, t) * 0.06 * sin(t * 53)) * (1 - u)
            }
        case .crash:
            var lp = 0.0
            return gen(0.6) { t, u in
                lp += (noise() - lp) * 0.3
                return (lp * 0.9 + tone(80, t) * 0.4) * pow(1 - u, 2)
            }
        case .truck:
            return gen(1.5) { t, u in
                let rumble = tone(55 + 5 * sin(t * 9), t) * 0.4 + noise() * 0.08
                return rumble * sin(.pi * u)
            }
        case .mop:
            var lp = 0.0
            return gen(0.6) { _, u in
                lp += (noise() - lp) * 0.05
                return lp * 0.8 * sin(.pi * u)
            }
        }
    }

    // MARK: speech

    /// Speaks `text`; `done` runs when the line finishes (right away if muted or empty – callers add their own pause).
    func say(_ text: String, as voice: Voice, done: (() -> Void)? = nil) {
        stopSpeaking()
        guard !muted, !text.isEmpty else { done?(); return }
        onSpoken = done
        let u = AVSpeechUtterance(string: text)
        u.voice = pickVoice(voice)
        u.rate = 0.5
        switch voice {
        case .boss: u.pitchMultiplier = 0.8
        case .repo, .bank: u.pitchMultiplier = 0.9
        case .boy: u.pitchMultiplier = 1.25
        case .girl: u.pitchMultiplier = 1.4
        case .hostess: u.pitchMultiplier = 1.1; u.rate = 0.47
        case .passerby: u.pitchMultiplier = 1.2
        case .teller: u.pitchMultiplier = 1.0; u.rate = 0.48
        default: break
        }
        speech.speak(u)
    }

    func stopSpeaking() {
        onSpoken = nil
        if speech.isSpeaking { speech.stopSpeaking(at: .immediate) }
    }

    private lazy var voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }

    private func pickVoice(_ v: Voice) -> AVSpeechSynthesisVoice? {
        let males = voices.filter { $0.gender == .male }
        let females = voices.filter { $0.gender == .female }
        func pick(_ list: [AVSpeechSynthesisVoice], _ i: Int) -> AVSpeechSynthesisVoice? {
            let us = list.filter { $0.language == "en-US" }
            let pool = us.isEmpty ? list : us
            return pool.isEmpty ? AVSpeechSynthesisVoice(language: "en-US") : pool[i % pool.count]
        }
        switch v {
        case .narrator: return pick(males, 0)
        case .boss: return pick(males, 1)
        case .repo, .boy: return pick(males, 2)
        case .bank: return pick(males, 3)
        case .hostess: return pick(females, 0)
        case .mom: return pick(females, 1)
        case .girl, .passerby: return pick(females, 2)
        case .teller: return pick(females, 3)
        }
    }
}
