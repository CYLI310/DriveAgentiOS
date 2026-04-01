import Foundation
import Combine
import SpotifyiOS
import UIKit

@MainActor
class SpotifyManager: NSObject, ObservableObject {
    static let shared = SpotifyManager()

    @Published var isConnected = false
    @Published var trackTitle = ""
    @Published var artistName = ""
    @Published var isPlaying = false
    @Published var albumArt: UIImage? = nil

    private var appRemote: SPTAppRemote?

    // TODO: YOU MUST REPLACE THIS WITH YOUR ACTUAL SPOTIFY CLIENT ID!
    private let clientIdentifier = "YOUR_CLIENT_ID" 
    private let redirectURI = URL(string: "driveagent://spotify-login-callback")!
    
    override init() {
        super.init()
        setupAppRemote()
    }

    private func setupAppRemote() {
        let configuration = SPTConfiguration(clientID: clientIdentifier, redirectURL: redirectURI)
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .none)
        appRemote?.delegate = self
    }

    func connect() {
        // Will seamlessly connect if authorized. Otherwise, opens Spotify app for auth.
        appRemote?.connect()
    }

    func disconnect() {
        if let appRemote = appRemote, appRemote.isConnected {
            appRemote.disconnect()
        }
    }

    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == redirectURI.scheme else { return false }
        
        let parameters = appRemote?.authorizationParameters(from: url)
        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote?.connectionParameters.accessToken = access_token
            appRemote?.connect()
            return true
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print("Spotify auth error: \(error_description)")
        }
        return false
    }

    // MARK: - Controls
    func playPause() {
        guard let appRemote = appRemote else { return }
        if isPlaying {
            appRemote.playerAPI?.pause(nil)
        } else {
            appRemote.playerAPI?.resume(nil)
        }
    }

    func skipNext() {
        appRemote?.playerAPI?.skip(toNext: nil)
    }

    func skipPrevious() {
        appRemote?.playerAPI?.skip(toPrevious: nil)
    }
}

extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnected = true
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
            if let error = error {
                print("Error subscribing to player state: \(error)")
            }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        isConnected = false
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        isConnected = false
        // Trigger generic authorization flow if connection fails (likely because tokens expired).
        appRemote.authorizeAndPlayURI("")
    }
}

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        trackTitle = playerState.track.name
        artistName = playerState.track.artist.name
        isPlaying = !playerState.isPaused
        
        appRemote?.imageAPI?.fetchImage(forItem: playerState.track, with: CGSize(width: 80, height: 80), callback: { [weak self] (img, err) in
            if let image = img as? UIImage {
                DispatchQueue.main.async {
                    self?.albumArt = image
                }
            }
        })
    }
}
