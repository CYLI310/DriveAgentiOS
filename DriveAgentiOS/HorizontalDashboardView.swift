import SwiftUI
internal import _LocationEssentials

struct HorizontalDashboardView: View {
    let speed: String
    let speedMps: Double
    let useMetric: Bool
    let isSpeeding: Bool
    let streetName: String
    let closestTrap: SpeedTrapInfo?
    let tripDistance: String
    let maxSpeed: String
    let accelerationState: LocationManager.AccelerationState
    let accelerationMagnitude: Double
    let languageManager: LanguageManager
    
    @Binding var isMapVisible: Bool
    @Binding var showingSettings: Bool
    
    let alertGlowOpacity: Double
    let alertBackgroundOpacity: Double
    
    private var glowColor: Color {
        if isSpeeding { return .red.opacity(0.2) }
        return .clear
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                    // Left Panel: Speed Limit & Stats
                    VStack(spacing: 20) {
                        if let trap = closestTrap {
                            VStack(spacing: 8) {
                                Text(languageManager.localize("Limit"))
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                    .tracking(2)
                                
                                ZStack {
                                    // Subtle pulse background
                                    Circle()
                                        .fill(isSpeeding ? Color.red.opacity(alertBackgroundOpacity) : Color.clear)
                                        .frame(width: 90, height: 90)
                                        .blur(radius: 10)
                                    
                                    Circle()
                                        .stroke(isSpeeding ? Color.red : Color.primary.opacity(0.2), lineWidth: 1)
                                        .frame(width: 80, height: 80)
                                        .background(Circle().fill(.ultraThinMaterial))
                                    
                                    Text(trap.speedLimit.replacingOccurrences(of: ".0", with: ""))
                                        .font(.system(size: 32, weight: .medium, design: .rounded))
                                        .foregroundColor(isSpeeding ? .red : .primary)
                                }
                                .scaleEffect(isSpeeding ? 1.05 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSpeeding)
                                
                                Text(formatDistance(trap.distance))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Spacer().frame(height: 120)
                        }
                        
                        Spacer()
                        
                        // Stats Box
                        VStack(alignment: .leading, spacing: 10) {
                            StatItemView(icon: "arrow.triangle.turn.up.right.diamond", label: languageManager.localize("Distance"), value: tripDistance)
                            StatItemView(icon: "gauge.with.needle", label: languageManager.localize("Max Speed"), value: maxSpeed)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .frame(width: geometry.size.width * 0.22)
                    .padding(.vertical)
                    
                    // Center Panel: Large Speed
                    VStack {
                        Spacer()
                        
                        ZStack {
                            // Large Ambient Glow
                            Circle()
                                .fill(glowColor)
                                .frame(width: geometry.size.height * 0.7, height: geometry.size.height * 0.7)
                                .blur(radius: 60)
                            
                            VStack(spacing: 0) {
                                Text(speed.components(separatedBy: " ").first ?? "0")
                                    .font(.system(size: geometry.size.height * 0.5, weight: .semibold, design: .rounded))
                                    .foregroundColor(isSpeeding ? .red : .primary)
                                    .contentTransition(.numericText())
                                
                                Text(useMetric ? "KM/H" : "MPH")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .tracking(4)
                            }
                        }
                        
                        Spacer()
                        
                        // Street Name
                        Text(streetName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSpeeding ? Color.red.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .frame(width: geometry.size.width * 0.56)
                    
                    // Right Panel: Actions & Clock
                    VStack {
                        // Clock
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(currentTimeString)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                            
                            if let loc = closestTrap?.coordinate {
                                Text("\(loc.latitude, specifier: "%.3f"), \(loc.longitude, specifier: "%.3f")")
                                    .font(.system(size: 9).monospaced())
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        Spacer()
                        
                        // Quick Action Buttons
                        VStack(spacing: 20) {
                            Button {
                                withAnimation(.spring()) {
                                    isMapVisible.toggle()
                                }
                            } label: {
                                Image(systemName: isMapVisible ? "map.fill" : "map")
                                    .font(.title3)
                                    .foregroundColor(isMapVisible ? .primary : .secondary)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(isMapVisible ? Color.primary.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.22)
                    .padding(.vertical)
                }
            }
        .padding(.horizontal)
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}

struct StatItemView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}
