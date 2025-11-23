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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var systemInfoManager = SystemInfoManager()
    @State private var liveActivityManager: LiveActivityManager?
    
    @State private var showingSettings = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasCenteredMap = false
    @State private var isMapVisible = false
    @State private var isTripActive = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Simple dark background
                Color.black
                    .ignoresSafeArea()

                switch locationManager.authorizationStatus {
                case .denied, .restricted:
                    PermissionDeniedView()
                case .notDetermined:
                    // Show a loading screen while waiting for authorization
                    ProgressView()
                        .onAppear {
                            locationManager.requestPermission()
                        }
                default: // Handles .authorizedWhenInUse, .authorizedAlways
                    mainContentView
                }
            }
            .foregroundColor(.primary)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                liveActivityManager = LiveActivityManager(locationManager: locationManager)
            }
            .onReceive(locationManager.$currentLocation) { location in
                if let location, !hasCenteredMap {
                    // Center map on the first location update
                    cameraPosition = .region(MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000))
                    hasCenteredMap = true
                }
            }
            .onReceive(locationManager.recenterPublisher) {_ in
                if let location = locationManager.currentLocation {
                    // Animate to user's location when relocate is tapped
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mainContentView: some View {
        VStack {
            TopBarView(systemInfoManager: systemInfoManager, locationManager: locationManager)
            
            Spacer()
            
            // Speed and Location Display
            VStack {
                Text(locationManager.currentSpeed)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                if let location = locationManager.currentLocation {
                    Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Searching for location...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            // "Start Trip" Button
            Button {
                if isTripActive {
                    liveActivityManager?.stop()
                } else {
                    liveActivityManager?.start()
                }
                isTripActive.toggle()
            } label: {
                Text(isTripActive ? "End Trip" : "Start Trip")
                    .font(.headline)
                    .foregroundColor(isTripActive ? .red : .green)
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.bottom)


            // Map View
            if isMapVisible {
                Map(position: $cameraPosition) {
                    if let location = locationManager.currentLocation {
                        Annotation("", coordinate: location) {
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 450)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            // Buttons
            HStack(spacing: 30) {
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
            .padding()
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
