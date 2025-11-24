import SwiftUI
import CoreLocation
import MapKit
import Combine

// A custom button style for the "liquid glass" effect.
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding()
            .background(
                .ultraThinMaterial,
                in: Circle()
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// The new top bar view with the "liquid glass" effect.
struct TopBarView: View {
    @ObservedObject var systemInfoManager: SystemInfoManager
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        HStack {
            // Battery
            if systemInfoManager.batteryLevel >= 0 {
                Label {
                    Text("\(Int(systemInfoManager.batteryLevel * 100))%")
                } icon: {
                    Image(systemName: batteryIcon(for: systemInfoManager.batteryLevel))
                        .foregroundColor(batteryColor(for: systemInfoManager.batteryLevel))
                }
            } else {
                // Show a placeholder when battery level is unknown (e.g., in Simulator)
                Image(systemName: "battery.unknown")
                    .foregroundColor(.secondary)
            }


            Spacer()

            // Street Name
            Text(locationManager.currentStreetName)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)

            Spacer()

            // Signal
            Image(systemName: systemInfoManager.networkStatusSymbol)
                .font(.body.weight(.semibold))
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .overlay( // Glossy edge highlight
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(.horizontal)
    }

    private func batteryIcon(for level: Float) -> String {
        switch level {
        case 0.75...: return "battery.100percent"
        case 0.50...: return "battery.75percent"
        case 0.25...: return "battery.50percent"
        case 0.0...: return "battery.25percent"
        default: return "battery.0percent"
        }
    }

    private func batteryColor(for level: Float) -> Color {
        switch level {
        case 0.20...: return .primary
        case 0.10...: return .yellow
        default: return .red
        }
    }
}


struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var systemInfoManager = SystemInfoManager()

    @State private var showingSettings = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var hasCenteredMap = false
    @State private var isMapVisible = false
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color based on theme
                (themeManager.currentTheme == .dark ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()

                switch locationManager.authorizationStatus {
                case .denied, .restricted:
                    PermissionDeniedView()
                case .notDetermined:
                    // Show a loading screen while waiting for authorization
                    VStack {
                        ProgressView()
                        Text("Waiting for location permission...")
                            .padding(.top)
                        Text("Status: \(locationManager.authorizationStatus.rawValue)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .onAppear {
                        print("Requesting permission...")
                        locationManager.requestPermission()
                    }
                default: // Handles .authorizedWhenInUse, .authorizedAlways
                    mainContentView
                }
            }
            .foregroundColor(.primary)
            .sheet(isPresented: $showingSettings) {
                SettingsView(themeManager: themeManager, locationManager: locationManager)
            }

            .onReceive(locationManager.$currentLocation) { location in
                if let location, !hasCenteredMap {
                    // Center map on the first location update
                    region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
                    hasCenteredMap = true
                }
            }
            .onReceive(locationManager.recenterPublisher) {_ in
                if let location = locationManager.currentLocation {
                    // Animate to user's location when relocate is tapped
                    withAnimation {
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
                    }
                }
            }
            .onReceive(timer) { _ in
                if isMapVisible, let location = locationManager.currentLocation {
                    withAnimation {
                        region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
                    }
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }

    private var mainContentView: some View {
        VStack {
            TopBarView(systemInfoManager: systemInfoManager, locationManager: locationManager)
            
            Spacer()
            
            // Speed and Location Display with Particle Effect
            ZStack {
                ParticleEffectView(
                    accelerationState: locationManager.accelerationState,
                    accelerationMagnitude: locationManager.accelerationMagnitude
                )
                .frame(width: 400, height: 400)
                
                VStack(spacing: 8) {
                    Text(locationManager.currentSpeed)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                    
                    if locationManager.currentSpeed == "0 km/h" && !isMapVisible {
                        // Show additional info when stopped
                        VStack(spacing: 4) {
                            Text(locationManager.currentStreetName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let location = locationManager.currentLocation {
                                Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack(spacing: 20) {
                                VStack(spacing: 2) {
                                    Text("Trip Distance")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(locationManager.getFormattedDistance())
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(spacing: 2) {
                                    Text("Max Speed")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(locationManager.getFormattedMaxSpeed())
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if systemInfoManager.batteryLevel >= 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "battery.100percent")
                                        .foregroundColor(.green)
                                    Text("\(Int(systemInfoManager.batteryLevel * 100))%")
                                        .font(.caption)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if let location = locationManager.currentLocation {
                        Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Searching for location...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            // Map View
            if isMapVisible {
                ZStack(alignment: .topTrailing) {
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Exit button
                    Button {
                        withAnimation(.spring()) {
                            isMapVisible = false
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
            }
            
            Spacer()

            // Buttons
            HStack(spacing: 40) {
                Button {
                    locationManager.centerMapOnUserLocation()
                } label: {
                    Image(systemName: "location.circle")
                }
                .buttonStyle(GlassButtonStyle())
                
                Button {
                    withAnimation(.spring()) {
                        isMapVisible.toggle()
                    }
                } label: {
                    Image(systemName: "map")
                }
                .buttonStyle(GlassButtonStyle())
                .scaleEffect(1.2) // Magnify the center button

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding(.vertical, 30)
            .padding(.bottom, 20)
        }
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Location Access Denied")
                .font(.title2.bold())
            Text("To provide speed and location data, this app needs access to your location. Please enable it in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
    }
}


#Preview {
    ContentView()
}
