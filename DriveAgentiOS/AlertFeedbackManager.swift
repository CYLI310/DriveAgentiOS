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
            // .spokenAudio mode is optimized for alerts and voice, often sounding clearer/louder over music
            // .interruptSpokenAudioAndMixWithOthers ensures it cuts through podcasts/audiobooks
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
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
                    Task { @MainActor in
                        self?.playChime(isUrgent: true)
                        self?.triggerHaptic()
                    }
                }
            }
            return
        }
        
        isPlayingAlert = true
        
        // Play more aggressive initial chime sequence
        playChime(isUrgent: true)
        triggerHaptic()
        
        // Set up repeating timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.playChime(isUrgent: true)
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
    
    // Navigation Pop is the only alert sound
    enum AlertSound: Int, CaseIterable, Identifiable {
        case navigationPop = 0  // Custom sound file
        
        var id: Int { rawValue }
        
        var name: String {
            return "Navigation Pop"
        }
    }

    private func playChime(isUrgent: Bool = false) {
        // Play Navigation Pop MP3 file
        if let soundURL = Bundle.main.url(forResource: "navigation_pop", withExtension: "mp3") {
            do {
                if audioPlayer == nil || audioPlayer?.url != soundURL {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.prepareToPlay()
                }
                
                // Force volume to max
                audioPlayer?.volume = 1.0
                
                // For urgent speed alerts, we can play it twice in quick succession 
                // or ensure it's at the very front of the audio queue
                if isUrgent {
                    // Double tap effect for better visibility
                    audioPlayer?.currentTime = 0
                    audioPlayer?.play()
                    
                    // Simple way to make it "louder" is to play it again after a tiny delay
                    // but we have to be careful not to create a messy echo.
                    // Instead, let's just ensure session is active.
                    try? AVAudioSession.sharedInstance().setActive(true)
                } else {
                    audioPlayer?.currentTime = 0
                    audioPlayer?.play()
                }
                
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
