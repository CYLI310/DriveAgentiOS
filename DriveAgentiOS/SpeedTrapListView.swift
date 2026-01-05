import SwiftUI
import CoreLocation

struct SpeedTrapListView: View {
    @ObservedObject var speedTrapDetector: SpeedTrapDetector
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    
    @State private var nearestTraps: [SpeedTrapInfo] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(languageManager.localize("Nearest Speed Cameras"))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                
                Divider()
                
                // List content
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Finding nearest speed cameras...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                } else if nearestTraps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.metering.unknown")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No speed cameras found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Make sure location services are enabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(nearestTraps.enumerated()), id: \.offset) { index, trap in
                                SpeedTrapRow(trap: trap, index: index + 1, languageManager: languageManager)
                            }
                        }
                        .padding()
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .frame(height: 450)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            // Exit button (matching map view style)
            Button {
                themeManager.triggerHaptic()
                withAnimation(.spring()) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
        .onAppear {
            loadNearestTraps()
        }
    }
    
    private func loadNearestTraps() {
        guard let location = locationManager.currentLocation else {
            isLoading = false
            return
        }
        
        Task {
            let traps = await speedTrapDetector.getNearestSpeedTraps(userLocation: location, count: 10)
            await MainActor.run {
                nearestTraps = traps
                isLoading = false
            }
        }
    }
}

struct SpeedTrapRow: View {
    let trap: SpeedTrapInfo
    let index: Int
    @ObservedObject var languageManager: LanguageManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Index badge
            ZStack {
                Circle()
                    .fill(indexColor)
                    .frame(width: 36, height: 36)
                
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Camera icon
            Image(systemName: "camera.fill")
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 30)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(languageManager.localize("Limit")): \(trap.speedLimit.replacingOccurrences(of: ".0", with: "")) km/h")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatDistance(trap.distance))
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
                
                Text(trap.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var indexColor: Color {
        switch index {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .blue
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}
