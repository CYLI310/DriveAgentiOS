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
            // Use .duckOthers to temporarily lower other audio, making alert more audible
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func startSpeedingAlert(interval: TimeInterval = 4.0) {
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
    
    // Navigation Pop is the only alert sound
    enum AlertSound: Int, CaseIterable, Identifiable {
        case navigationPop = 0  // Custom sound file
        
        var id: Int { rawValue }
        
        var name: String {
            return "Navigation Pop"
        }
    }

    private func playChime() {
        // Play Navigation Pop MP3 file
        if let soundURL = Bundle.main.url(forResource: "navigation_pop", withExtension: "mp3") {
            do {
                if audioPlayer == nil || audioPlayer?.url != soundURL {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.volume = 1.0  // Set to maximum volume
                    audioPlayer?.prepareToPlay()
                }
                audioPlayer?.currentTime = 0
                audioPlayer?.play()
            } catch {
                print("Failed to play navigation_pop.mp3: \(error)")
            }
        } else {
            print("navigation_pop.mp3 not found in bundle")
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
