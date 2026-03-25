import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
class AlertFeedbackManager: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioEQ: AVAudioUnitEQ?
    
    private var loadedAudioBuffers: [AlarmSound: AVAudioPCMBuffer] = [:]
    
    private var feedbackTimer: Timer?
    private let hapticGenerator = UINotificationFeedbackGenerator()
    private var isPlayingAlert = false
    private var lastPlayTime: Date?
    private var bgTask: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        hapticGenerator.prepare()
        configureMixSession()   // Start in mix-friendly mode
        setupAudioEngineAndPreload()
    }
    
    // MARK: - Audio Session Management
    
    /// Idle mode: mix with other audio and duck it slightly.
    private func configureMixSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("AlertFeedbackManager: Failed to configure mix session: \(error)")
        }
    }

    /// Alert mode: fully interrupt other audio (Spotify, Apple Music, etc.) for the chime.
    /// Setting .playback with NO mixing options causes iOS to pause other app audio,
    /// the same way Waze / Google Maps cut through music.
    private func activateAlertSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("AlertFeedbackManager: Failed to activate alert session: \(error)")
        }
    }

    /// Restore duck-and-mix mode after the chime finishes so music resumes automatically.
    private func restoreMixSession() {
        // Short delay to let the chime audio tail off before switching sessions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
                // Deactivate briefly so iOS signals other apps (Spotify, etc.) to resume playback
                try session.setActive(false, options: .notifyOthersOnDeactivation)
                try session.setActive(true)
            } catch {
                print("AlertFeedbackManager: Failed to restore mix session: \(error)")
            }
        }
    }
    
    // MARK: - Engine Setup
    
    private func setupAudioEngineAndPreload() {
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        
        // EQ node allows gain boosting above 100% system volume
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        eq.globalGain = 0 // dB; adjusted per-chime
        
        engine.attach(playerNode)
        engine.attach(eq)
        
        var commonFormat: AVAudioFormat?
        
        // Preload all sounds into memory for zero-latency playback
        for sound in AlarmSound.allCases {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") {
                do {
                    let file = try AVAudioFile(forReading: url)
                    let format = file.processingFormat
                    if commonFormat == nil { commonFormat = format }
                    let targetFormat = commonFormat ?? format
                    if let buffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                                     frameCapacity: AVAudioFrameCount(file.length)) {
                        try file.read(into: buffer)
                        loadedAudioBuffers[sound] = buffer
                    }
                } catch {
                    print("AlertFeedbackManager: Failed to load \(sound.fileName): \(error)")
                }
            }
        }
        
        let connectionFormat = commonFormat ?? engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: eq, format: connectionFormat)
        engine.connect(eq, to: engine.mainMixerNode, format: connectionFormat)
        
        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.audioPlayerNode = playerNode
            self.audioEQ = eq
        } catch {
            print("AlertFeedbackManager: Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Public API
    
    func startSpeedingAlert(interval: TimeInterval = 4.0, sound: AlarmSound = .default_, volume: Float = 1.0) {
        let now = Date()
        
        if isPlayingAlert {
            // Background fallback: GPS woke us up — play immediately if overdue
            if let last = lastPlayTime, now.timeIntervalSince(last) >= interval - 0.1 {
                playChime(sound: sound, volume: volume)
                triggerHaptic()
                lastPlayTime = now
            }
            // Update interval if it changed (e.g. severe → normal speeding)
            if let timer = feedbackTimer, abs(timer.timeInterval - interval) > 0.1 {
                feedbackTimer?.invalidate()
                feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.playChime(sound: sound, volume: volume)
                        self?.triggerHaptic()
                        self?.lastPlayTime = Date()
                    }
                }
            }
            return
        }
        
        isPlayingAlert = true
        
        if bgTask == .invalid {
            bgTask = UIApplication.shared.beginBackgroundTask(withName: "SpeedingAlertChime") {
                UIApplication.shared.endBackgroundTask(self.bgTask)
                self.bgTask = .invalid
            }
        }
        
        // Immediate first chime
        playChime(sound: sound, volume: volume)
        triggerHaptic()
        lastPlayTime = now
        
        // Repeating chime timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playChime(sound: sound, volume: volume)
                self?.triggerHaptic()
                self?.lastPlayTime = Date()
            }
        }
    }
    
    func stopSpeedingAlert() {
        guard isPlayingAlert else { return }
        isPlayingAlert = false
        
        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }
        
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        audioPlayerNode?.stop()
        
        // Restore mix mode so Spotify / Apple Music can resume at full volume
        configureMixSession()
    }
    
    // MARK: - Sound Definitions
    
    enum AlarmSound: String, CaseIterable, Identifiable {
        case default_ = "Default"
        case chime    = "Chime"
        case pace     = "Pace"
        case ding     = "Ding"
        
        var id: String { rawValue }
        var displayName: String { rawValue }
        
        var fileName: String {
            switch self {
            case .default_: return "navigation_pop"
            case .chime:    return "navigation_push"
            case .pace:     return "3rdParty_Failure_Haptic"
            case .ding:     return "3rdParty_Retry_Haptic"
            }
        }
    }

    // MARK: - Playback
    
    private func playChime(sound: AlarmSound = .default_, volume: Float = 1.0) {
        guard let engine = audioEngine, let player = audioPlayerNode, let eq = audioEQ else {
            setupAudioEngineAndPreload()
            return playChime(sound: sound, volume: volume)
        }
        guard let buffer = loadedAudioBuffers[sound] else {
            print("AlertFeedbackManager: buffer for \(sound.fileName) not found")
            return
        }
        
        // 1. Switch audio session to exclusive playback — this pauses Spotify/Apple Music
        activateAlertSession()
        
        // 2. Set EQ gain (cap at +20 dB to punch through without distorting)
        let safeVolume = max(volume, 0.001)
        let gainDb = 20.0 * log10(safeVolume)
        eq.globalGain = max(min(gainDb, 20.0), -80.0)
        
        // 3. Restart engine if the OS killed it while backgrounded
        if !engine.isRunning {
            try? engine.start()
        }
        
        // 4. Play the pre-loaded buffer
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            // 5. Once the chime finishes, restore the mix session → music auto-resumes
            Task { @MainActor in
                self?.restoreMixSession()
            }
        }
        player.play()
    }
    
    private func triggerHaptic() {
        hapticGenerator.notificationOccurred(.warning)
        hapticGenerator.prepare()
    }
    
    nonisolated deinit {
        feedbackTimer?.invalidate()
    }
}
