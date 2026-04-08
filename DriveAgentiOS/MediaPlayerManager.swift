import Foundation
import Combine
import MediaPlayer
import AVFoundation

/// Universal media controller that works with any now-playing app on the device
/// (Spotify, Apple Music, Podcasts, YouTube Music, etc.).
///
/// Transport commands and now-playing detection are routed through the MediaRemote
/// private framework, loaded dynamically so we never statically link to it.
@MainActor
class MediaPlayerManager: ObservableObject {
    let objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    

    // MARK: - Published State

    @Published var isPlaying: Bool = false
    /// True whenever any audio source is actively playing or paused with a known track.
    @Published var isAudioActive: Bool = false

    // Keep title/artist so future callers can use them if needed.
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""

    // MARK: - MediaRemote command constants
    private let kMRPlay             : Int32 = 0
    private let kMRPause            : Int32 = 1
    private let kMRTogglePlayPause  : Int32 = 2
    private let kMRNextTrack        : Int32 = 4
    private let kMRPreviousTrack    : Int32 = 5

    // MARK: - MediaRemote function types
    private typealias MRSendCommandFn       = @convention(c) (Int32, AnyObject?) -> Bool
    private typealias MRGetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRGetPlayStateFn      = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRRegisterForNotifFn  = @convention(c) (DispatchQueue, @escaping (CFNotificationName, AnyObject?) -> Void) -> Void

    private var mrBundle: CFBundle?
    private var mrSendCommand:       MRSendCommandFn?
    private var mrGetNowPlayingInfo: MRGetNowPlayingInfoFn?
    private var mrGetPlayState:      MRGetPlayStateFn?

    private var pollingTimer: Timer?

    // MARK: - Init

    init() {
        // Ensure all stored properties are initialized before using self
        defer {
            loadMediaRemote()
            registerNowPlayingNotifications()
            startPolling()
            poll()
        }
    }

    // MARK: - Dynamic framework loading

    private func loadMediaRemote() {
        guard let bundle = CFBundleGetBundleWithIdentifier("com.apple.mediaremote" as CFString) else {
            print("[MediaPlayerManager] MediaRemote framework not found — falling back to AVAudioSession only.")
            return
        }
        mrBundle = bundle

        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) {
            mrSendCommand = unsafeBitCast(ptr, to: MRSendCommandFn.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) {
            mrGetNowPlayingInfo = unsafeBitCast(ptr, to: MRGetNowPlayingInfoFn.self)
        }
        if let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) {
            mrGetPlayState = unsafeBitCast(ptr, to: MRGetPlayStateFn.self)
        }
    }

    // MARK: - Notifications

    private func registerNowPlayingNotifications() {
        // System posts these whenever any app changes its now-playing state
        let names: [Notification.Name] = [
            Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"),
            AVAudioSession.silenceSecondaryAudioHintNotification
        ]
        for name in names {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleExternalChange),
                name: name,
                object: nil
            )
        }
    }

    @objc private func handleExternalChange() {
        Task { @MainActor in poll() }
    }

    private func startPolling() {
        // Light 2 s poll as safety net for apps that don't post notifications reliably
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    // MARK: - Core Poll

    private func poll() {
        // 1. Play state via MediaRemote (covers all apps)
        if let getPlayState = mrGetPlayState {
            getPlayState(.main) { [weak self] playing in
                Task { @MainActor in self?.isPlaying = playing }
            }
        } else {
            isPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying
        }

        // 2. Now-playing metadata via MediaRemote (covers Spotify, Apple Music, etc.)
        if let getNowPlayingInfo = mrGetNowPlayingInfo {
            getNowPlayingInfo(.main) { [weak self] info in
                Task { @MainActor in
                    guard let self else { return }
                    let title  = info["kMRMediaRemoteNowPlayingInfoTitle"]  as? String ?? ""
                    let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                    self.trackTitle  = title
                    self.artistName  = artist
                    // Active if there is metadata OR other audio is audible
                    self.isAudioActive = !title.isEmpty
                                      || AVAudioSession.sharedInstance().isOtherAudioPlaying
                }
            }
        } else {
            // Fallback: no MediaRemote — show controls whenever audio is audible
            isAudioActive = AVAudioSession.sharedInstance().isOtherAudioPlaying
        }
    }

    // MARK: - Transport Controls (universal via MediaRemote)

    func togglePlayPause() {
        sendCommand(kMRTogglePlayPause)
        isPlaying.toggle() // Optimistic update
    }

    func skipNext() {
        sendCommand(kMRNextTrack)
    }

    func skipPrevious() {
        sendCommand(kMRPreviousTrack)
    }

    @discardableResult
    private func sendCommand(_ command: Int32) -> Bool {
        guard let fn = mrSendCommand else {
            // Hard fallback: system music player (Apple Music only)
            let mp = MPMusicPlayerController.systemMusicPlayer
            switch command {
            case kMRTogglePlayPause: isPlaying ? mp.pause() : mp.play()
            case kMRNextTrack:       mp.skipToNextItem()
            case kMRPreviousTrack:   mp.skipToPreviousItem()
            default: break
            }
            return false
        }
        return fn(command, nil)
    }

    // MARK: - Cleanup

    nonisolated deinit { }
}

