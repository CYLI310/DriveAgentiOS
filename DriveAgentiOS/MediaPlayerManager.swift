import Foundation
import MediaPlayer
import AVFoundation
import Combine

/// Observes what's currently playing on the device (any app — Apple Music,
/// Spotify, Podcasts, YouTube Music, etc.) via MPNowPlayingInfoCenter and
/// provides basic transport controls through the system music player.
///
/// Note: Play/pause/skip controls are forwarded to MPMusicPlayerController
/// (systemMusicPlayer). This works natively with Apple Music. For third-party
/// apps like Spotify, the now-playing metadata is always visible but playback
/// control depends on the audio session active at the time.
@MainActor
class MediaPlayerManager: ObservableObject {

    // MARK: - Published State

    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumArtwork: UIImage?
    @Published var isPlaying: Bool = false
    /// True whenever there is an active audio source to display.
    @Published var isAudioActive: Bool = false

    // MARK: - Private

    private let systemPlayer = MPMusicPlayerController.systemMusicPlayer
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        setupNotifications()
        startPolling()
        
        // Listen to Spotify updates so UI reacts instantly to track changes
        SpotifyManager.shared.$trackTitle
            .combineLatest(SpotifyManager.shared.$isPlaying, SpotifyManager.shared.$artistName)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.poll() }
            .store(in: &cancellables)
            
        poll() // Immediate first read
    }

    // MARK: - Setup

    private func setupNotifications() {
        systemPlayer.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStateChange),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStateChange),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil
        )
    }

    @objc private func handleStateChange() {
        Task { @MainActor in poll() }
    }

    private func startPolling() {
        // Poll every 1.5 s to catch changes from external apps (Spotify, Podcasts…)
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    // MARK: - Core Poll

    private func poll() {
        // 1. Spotify Priority
        let spotify = SpotifyManager.shared
        if spotify.isConnected && !spotify.trackTitle.isEmpty {
            self.trackTitle = spotify.trackTitle
            self.artistName = spotify.artistName
            self.isPlaying = spotify.isPlaying
            self.albumArtwork = spotify.albumArt
            self.isAudioActive = true
            return
        }
        
        // 2. Apple Music / System Audio Fallback
        let authStatus = MPMediaLibrary.authorizationStatus()
        guard authStatus == .authorized else {
            if authStatus == .notDetermined {
                MPMediaLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized {
                        Task { @MainActor in self.poll() }
                    }
                }
            }
            return
        }

        let item = systemPlayer.nowPlayingItem
        let state = systemPlayer.playbackState

        let title  = item?.title ?? ""
        let artist = item?.artist ?? ""

        // isOtherAudioPlaying catches apps that don't share now playing info natively (Podcasts, etc.)
        // We only fall back to this if Spotify and Apple Music are empty.
        let otherAudioPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying

        trackTitle  = title
        artistName  = artist
        isPlaying   = state == .playing || (title.isEmpty && otherAudioPlaying)
        isAudioActive = state == .playing || (state == .paused && !title.isEmpty) || (title.isEmpty && otherAudioPlaying)

        // Artwork — only update if we have info to avoid flickering
        if let artwork = item?.artwork {
            albumArtwork = artwork.image(at: CGSize(width: 80, height: 80))
        } else if title.isEmpty {
            albumArtwork = nil
        }
    }

    // MARK: - Transport Controls

    func togglePlayPause() {
        let spotify = SpotifyManager.shared
        if spotify.isConnected && !spotify.trackTitle.isEmpty {
            spotify.playPause()
            return
        }
        
        if isPlaying {
            systemPlayer.pause()
        } else {
            systemPlayer.play()
        }
        isPlaying.toggle() // Optimistic update
    }

    func skipNext() {
        let spotify = SpotifyManager.shared
        if spotify.isConnected && !spotify.trackTitle.isEmpty {
            spotify.skipNext()
            return
        }
        systemPlayer.skipToNextItem()
    }

    func skipPrevious() {
        let spotify = SpotifyManager.shared
        if spotify.isConnected && !spotify.trackTitle.isEmpty {
            spotify.skipPrevious()
            return
        }
        
        if systemPlayer.currentPlaybackTime > 3 {
            systemPlayer.skipToBeginning()
        } else {
            systemPlayer.skipToPreviousItem()
        }
    }

    // MARK: - Cleanup

    nonisolated deinit {
        // Timer capture is [weak self], so no retain cycle — safe to skip explicit invalidate.
        // systemPlayer.endGeneratingPlaybackNotifications() would need @MainActor.
    }
}
