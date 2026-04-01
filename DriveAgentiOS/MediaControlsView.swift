import SwiftUI

/// A compact, glassmorphism media control widget that floats above the
/// bottom action buttons. It auto-shows when any audio is playing and
/// fades out when the device goes silent.
struct MediaControlsView: View {
    @ObservedObject var manager: MediaPlayerManager
    let themeManager: ThemeManager

    // Subtle continuous rotation animation for the album art disc
    @State private var artRotation: Double = 0
    @State private var artTimer: Timer?

    var body: some View {
        HStack(spacing: 14) {

            // MARK: Album Art
            ZStack {
                if let art = manager.albumArtwork {
                    Image(uiImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.secondary.opacity(0.15))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                        )
                }
            }

            // MARK: Track Info
            VStack(alignment: .leading, spacing: 3) {
                Text(manager.trackTitle.isEmpty ? "—" : manager.trackTitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(manager.artistName.isEmpty ? "Unknown Artist" : manager.artistName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: Transport Controls
            HStack(spacing: 22) {
                Button {
                    themeManager.triggerHaptic()
                    manager.skipPrevious()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }

                Button {
                    themeManager.triggerHaptic(.medium)
                    manager.togglePlayPause()
                } label: {
                    Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primary)
                        .contentTransition(.symbolEffect(.replace))
                }

                Button {
                    themeManager.triggerHaptic()
                    manager.skipNext()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
}
