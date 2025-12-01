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
        // Prepare haptic generator
        hapticGenerator.prepare()
        
        // Configure audio session for background playback
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func startSpeedingAlert(interval: TimeInterval = 1.0) {
        // If already playing, check if we need to update the interval
        if isPlayingAlert {
            if let timer = feedbackTimer, abs(timer.timeInterval - interval) > 0.1 {
                // Interval changed significantly, restart timer
                feedbackTimer?.invalidate()
                feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    self?.playChime()
                    self?.triggerHaptic()
                }
            }
            return
        }
        
        isPlayingAlert = true
        
        // Play initial chime and haptic
        playChime()
        triggerHaptic()
        
        // Set up repeating timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playChime()
            self?.triggerHaptic()
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
    
    // Define available alert sounds
    enum AlertSound: Int, CaseIterable, Identifiable {
        case softChime = 1013
        case modern = 1057
        case bloom = 1073
        case chord = 1103
        case pop = 1004
        case subtle = 1104
        case news = 1028
        case positive = 1012
        
        var id: Int { rawValue }
        
        var name: String {
            switch self {
            case .softChime: return "Soft Chime"
            case .modern: return "Modern"
            case .bloom: return "Bloom"
            case .chord: return "Chord"
            case .pop: return "Pop (Mac-like)"
            case .subtle: return "Subtle Click"
            case .news: return "News Flash"
            case .positive: return "Positive"
            }
        }
    }

    private func playChime() {
        // Check for custom file first (override)
        if let soundURL = Bundle.main.url(forResource: "alert_sound", withExtension: "mp3") ?? 
                          Bundle.main.url(forResource: "alert_sound", withExtension: "wav") ??
                          Bundle.main.url(forResource: "alert_sound", withExtension: "m4a") {
             // ... (existing custom file logic) ...
             do {
                if audioPlayer == nil || audioPlayer?.url != soundURL {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.prepareToPlay()
                }
                audioPlayer?.currentTime = 0
                audioPlayer?.play()
                return
            } catch {
                print("Failed to play custom sound: \(error)")
            }
        }
        
        // Load selected sound from settings (default to Pop/1004)
        let savedSoundID = UserDefaults.standard.integer(forKey: "selectedAlertSound")
        let soundID = savedSoundID != 0 ? savedSoundID : AlertSound.pop.rawValue
        
        AudioServicesPlaySystemSound(SystemSoundID(soundID))
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
