import SwiftUI

/// A minimal glassmorphism media control pill.
/// Shows only Previous / Play-Pause / Next buttons.
struct MediaControlsView: View {
    @ObservedObject var manager: MediaPlayerManager
    let themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 32) {

            // Previous
            Button {
                themeManager.triggerHaptic()
                manager.skipPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }

            // Play / Pause
            Button {
                themeManager.triggerHaptic(.medium)
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.primary)
                    .contentTransition(.symbolEffect(.replace))
            }

            // Next
            Button {
                themeManager.triggerHaptic()
                manager.skipNext()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 13)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .overlay(
            Capsule()
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
    }
}
