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
        configureAudioSession()
        setupAudioEngineAndPreload()
    }
    
    // ... configureAudioSession ...
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // .spokenAudio mode is optimized for alerts and voice, often sounding clearer/louder over music
            // .interruptSpokenAudioAndMixWithOthers ensures it cuts through podcasts/audiobooks
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func setupAudioEngineAndPreload() {
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        
        // Use an EQ node to allow gain boosting > 100%
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        eq.globalGain = 0 // Initial gain in dB
        
        engine.attach(playerNode)
        engine.attach(eq)
        
        var commonFormat: AVAudioFormat?
        
        // Preload sounds
        for sound in AlarmSound.allCases {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") {
                do {
                    let file = try AVAudioFile(forReading: url)
                    let format = file.processingFormat
                    if commonFormat == nil {
                        commonFormat = format
                    }
                    
                    let targetFormat = commonFormat ?? format
                    
                    if let buffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(file.length)) {
                        try file.read(into: buffer)
                        loadedAudioBuffers[sound] = buffer
                    }
                } catch {
                    print("Failed to load \(sound.fileName): \(error)")
                }
            }
        }
        
        // Connect nodes using the unified format
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
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func startSpeedingAlert(interval: TimeInterval = 4.0, sound: AlarmSound = .default_, volume: Float = 1.0) {
        let now = Date()
        
        // If already playing, check if we need to update the interval
        if isPlayingAlert {
            // Background fallback: If the timer suspended but the app was woken by GPS, force a play
            if let last = lastPlayTime, now.timeIntervalSince(last) >= interval - 0.1 {
                playChime(sound: sound, volume: volume, isUrgent: true)
                triggerHaptic()
                lastPlayTime = now
            }
            
            if let timer = feedbackTimer, abs(timer.timeInterval - interval) > 0.1 {
                // Interval changed significantly, restart timer
                feedbackTimer?.invalidate()
                feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.playChime(sound: sound, volume: volume, isUrgent: true)
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
        
        // Play more aggressive initial chime sequence
        playChime(sound: sound, volume: volume, isUrgent: true)
        triggerHaptic()
        lastPlayTime = now
        
        // Set up repeating timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playChime(sound: sound, volume: volume, isUrgent: true)
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
        
        // Stop timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        // Stop audio
        audioPlayerNode?.stop()
    }
    
    // Alert sound options
    enum AlarmSound: String, CaseIterable, Identifiable {
        case default_ = "Default"
        case chime = "Chime"
        case pace = "Pace"
        case ding = "Ding"
        
        var id: String { rawValue }
        
        /// The display name shown in the UI
        var displayName: String { rawValue }
        
        /// The filename (without extension) of the corresponding MP3 in the bundle
        var fileName: String {
            switch self {
            case .default_: return "navigation_pop"
            case .chime:    return "navigation_push"
            case .pace:     return "3rdParty_Failure_Haptic"
            case .ding:     return "3rdParty_Retry_Haptic"
            }
        }
    }

    private func playChime(sound: AlarmSound = .default_, volume: Float = 1.0, isUrgent: Bool = false) {
        guard let engine = audioEngine, let player = audioPlayerNode, let eq = audioEQ else {
            // Re-setup if somehow nil
            setupAudioEngineAndPreload()
            return playChime(sound: sound, volume: volume, isUrgent: isUrgent)
        }
        
        guard let buffer = loadedAudioBuffers[sound] else {
            print("\(sound.fileName).mp3 buffer not found")
            return
        }
        
        // Convert linear volume (0.0 to 2.0+) to dB Gain
        // Formula: gain_dB = 20 * log10(volume)
        // If volume is 0, we should set a very low negative dB or stop.
        let safeVolume = max(volume, 0.001)
        let gainDb = 20.0 * log10(safeVolume)
        
        // Limit max gain to prevent extreme clipping/damage (+12 dB max, usually corresponds to ~4.0 volume)
        eq.globalGain = max(min(gainDb, 12.0), -80.0)
        
        if isUrgent {
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        player.stop() // Clear queued buffers to start fresh
        player.scheduleBuffer(buffer, at: nil, options: .interrupts) {
            // Completion handler
        }
        player.play()
    }
    
    private func triggerHaptic() {
        // Soft haptic feedback (warning style)
        hapticGenerator.notificationOccurred(.warning)
        
        // Prepare for next haptic
        hapticGenerator.prepare()
    }
    
    nonisolated deinit {
        // Clean up resources directly without calling main actor methods
        feedbackTimer?.invalidate()
    }
}
