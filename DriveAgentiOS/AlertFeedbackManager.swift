import Foundation
import AVFoundation
import UIKit
import Combine

@MainActor
class AlertFeedbackManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var feedbackTimer: Timer?
    private let hapticGenerator = UINotificationFeedbackGenerator()
    private var isPlayingAlert = false
    
    init() {
        hapticGenerator.prepare()
        configureAudioSession()
    }
    
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
    
    func startSpeedingAlert(interval: TimeInterval = 4.0, sound: AlarmSound = .default_, volume: Float = 1.0) {
        // If already playing, check if we need to update the interval
        if isPlayingAlert {
            if let timer = feedbackTimer, abs(timer.timeInterval - interval) > 0.1 {
                // Interval changed significantly, restart timer
                feedbackTimer?.invalidate()
                feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.playChime(sound: sound, volume: volume, isUrgent: true)
                        self?.triggerHaptic()
                    }
                }
            }
            return
        }
        
        isPlayingAlert = true
        
        // Play more aggressive initial chime sequence
        playChime(sound: sound, volume: volume, isUrgent: true)
        triggerHaptic()
        
        // Set up repeating timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playChime(sound: sound, volume: volume, isUrgent: true)
                self?.triggerHaptic()
            }
        }
    }
    
    func stopSpeedingAlert() {
        guard isPlayingAlert else { return }
        isPlayingAlert = false
        
        // Stop timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        // Stop audio
        audioPlayer?.stop()
        audioPlayer = nil
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
        if let soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") {
            do {
                if audioPlayer == nil || audioPlayer?.url != soundURL {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.prepareToPlay()
                }
                
                // Apply volume (clamped to 0...2 range but AVAudioPlayer supports 0...1 natively;
                // values above 1.0 are allowed on AVAudioPlayer and act as a software gain boost)
                audioPlayer?.volume = min(volume, 2.0)
                
                // For urgent speed alerts ensure session is active
                if isUrgent {
                    audioPlayer?.currentTime = 0
                    audioPlayer?.play()
                    try? AVAudioSession.sharedInstance().setActive(true)
                } else {
                    audioPlayer?.currentTime = 0
                    audioPlayer?.play()
                }
                
            } catch {
                print("Failed to play \(sound.fileName).mp3: \(error)")
            }
        } else {
            print("\(sound.fileName).mp3 not found in bundle")
        }
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
        audioPlayer?.stop()
    }
}
