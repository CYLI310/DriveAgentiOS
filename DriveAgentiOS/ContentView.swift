import SwiftUI
import CoreLocation
import MapKit
import Combine

// MARK: - Speed Display Styles

// MARK: - Speed Display Styles (Moved to separate files)


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
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var systemInfoManager = SystemInfoManager()
    @StateObject private var speedTrapDetector = SpeedTrapDetector()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var alertFeedbackManager = AlertFeedbackManager()
    @StateObject private var distractionDetector = DistractionDetector()
    @StateObject private var pipManager = PiPManager()
    @State private var liveActivityManager: LiveActivityManager?
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingSettings = false
    @State private var showingSpeedTrapList = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var hasCenteredMap = false
    @State private var isMapVisible = false
    @State private var showOnboarding = false
    @State private var alertGlowOpacity: Double = 1.0 // For ambient glow blinking
    @State private var alertBackgroundOpacity: Double = 0.6 // For alert box breathing
    
    // Analog dash-aware text colors
    private var dashTextColor: Color {
        guard themeManager.speedDisplayMode == .analog else { return .primary }
        return themeManager.analogDashColor == .black ? .white : .black
    }
    
    private var dashSecondaryTextColor: Color {
        guard themeManager.speedDisplayMode == .analog else { return .secondary }
        return themeManager.analogDashColor == .black ? .white.opacity(0.6) : .black.opacity(0.5)
    }
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color based on theme
                (themeManager.currentTheme == .dark ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()

                switch locationManager.authorizationStatus {
                case .denied, .restricted:
                    PermissionDeniedView(languageManager: languageManager, themeManager: themeManager)
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
                    ZStack {
                        if verticalSizeClass == .compact {
                            horizontalMainView
                        } else {
                            mainContentView
                        }
                    }
                    .background(
                        // Modern ambient glow effect when speeding - Shared across views
                        ZStack {
                            if speedTrapDetector.isSpeeding {
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(alertGlowOpacity * 0.5),
                                        Color.red.opacity(alertGlowOpacity * 0.2),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 600
                                )
                                .ignoresSafeArea()
                                .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: speedTrapDetector.isSpeeding)
                    )
                }
            }
            .foregroundColor(.primary)
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    themeManager: themeManager,
                    locationManager: locationManager,
                    speedTrapDetector: speedTrapDetector,
                    languageManager: languageManager,
                    distractionDetector: distractionDetector,
                    pipManager: pipManager
                )
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding, languageManager: languageManager, themeManager: themeManager)
            }
            .onAppear {
                // Check if this is the first launch
                if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    showOnboarding = true
                }
                
                // Initialize LiveActivityManager (iOS 16.1+)
                if #available(iOS 16.1, *) {
                    if liveActivityManager == nil {
                        liveActivityManager = LiveActivityManager(locationManager: locationManager)
                    }
                }

                // Prepare PiP if enabled (delay slightly to ensure window is ready)
                if themeManager.pipEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pipManager.prepare()
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if #available(iOS 16.1, *) {
                    switch newPhase {
                    case .background:
                        // Start Live Activity when app goes to background
                        liveActivityManager?.start()
                        print("App moved to background - starting Live Activity")
                    case .active:
                        // Stop Live Activity when app comes to foreground
                        liveActivityManager?.stop()
                        // Stop PiP — user is back in the app
                        pipManager.stopPiP()
                        
                        // Re-prepare if enabled so it's ready for the next backgrounding
                        if themeManager.pipEnabled {
                            pipManager.prepare()
                        }
                        
                        // Check if speeding and start alert with appropriate interval
                        if speedTrapDetector.isSpeeding {
                            let isSevere = speedTrapDetector.speedingAmount > 10
                            let interval = isSevere ? 2.0 : 4.0
                            alertFeedbackManager.startSpeedingAlert(
                                interval: interval,
                                sound: themeManager.alarmSound,
                                volume: Float(themeManager.alarmVolume / 100.0)
                            )
                        }
                        print("App moved to foreground - stopping Live Activity")
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
            }

            .onReceive(locationManager.$currentLocation) { location in
                if let location, !hasCenteredMap {
                    // Center map on the first location update
                    region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
                    hasCenteredMap = true
                }
                
                // Check for nearby speed traps
                if let location {
                    speedTrapDetector.checkForNearbyTraps(
                        userLocation: location,
                        currentSpeed: locationManager.currentSpeedMps,
                        currentStreetName: locationManager.currentStreetName,
                        currentCourse: locationManager.currentCourse
                    )
                    distractionDetector.updateSpeed(speedMps: locationManager.currentSpeedMps)
                }
                
                // Keep PiP HUD fresh with latest data
                pipManager.update(data: PiPDashboardData(
                    speed: locationManager.currentSpeed,
                    isSpeeding: speedTrapDetector.isSpeeding,
                    streetName: locationManager.currentStreetName,
                    speedingAmount: speedTrapDetector.speedingAmount,
                    closestTrapDistance: speedTrapDetector.closestTrap?.distance,
                    speedLimit: speedTrapDetector.closestTrap?.speedLimit,
                    tripDistance: locationManager.getFormattedDistance(),
                    maxSpeed: locationManager.getFormattedMaxSpeed()
                ))
            }
            .onChange(of: speedTrapDetector.infiniteProximity) { _, newValue in
                // Force a check when the setting is toggled
                if let location = locationManager.currentLocation {
                    speedTrapDetector.checkForNearbyTraps(userLocation: location, currentSpeed: locationManager.currentSpeedMps)
                }
            }
            .onChange(of: themeManager.pipEnabled) { _, enabled in
                if enabled {
                    pipManager.prepare()
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
        .overlay {
            if distractionDetector.isDistracted {
                DistractionOverlay(languageManager: languageManager)
                    .transition(.opacity)
            }
        }
        .animation(.spring(), value: distractionDetector.isDistracted)
    }

    private var mainContentView: some View {
        VStack {
            if themeManager.showTopBar {
                TopBarView(systemInfoManager: systemInfoManager, locationManager: locationManager)
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                speedDisplayView()
                
                // Compact road name pill shown while moving when top bar is hidden
                if !themeManager.showTopBar && !locationManager.currentSpeed.hasPrefix("0 ") && !isMapVisible && !showingSpeedTrapList {
                    HStack(spacing: 5) {
                        Image(systemName: "map.fill")
                            .font(.caption2)
                        Text(locationManager.currentStreetName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundColor(dashTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                if locationManager.currentSpeed.hasPrefix("0 ") && !isMapVisible && !showingSpeedTrapList {
                    // Show additional info when stopped
                    VStack(spacing: 4) {
                        Text(locationManager.currentStreetName)
                            .font(.headline)
                            .foregroundColor(dashTextColor)
                        
                        if let location = locationManager.currentLocation {
                            Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(dashSecondaryTextColor)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 2) {
                                Text(languageManager.localize("Trip Distance"))
                                    .font(.caption2)
                                    .foregroundColor(dashSecondaryTextColor)
                                Text(locationManager.getFormattedDistance())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(dashTextColor)
                            }
                            
                            VStack(spacing: 2) {
                                Text(languageManager.localize("Max Speed"))
                                    .font(.caption2)
                                    .foregroundColor(dashSecondaryTextColor)
                                Text(locationManager.getFormattedMaxSpeed())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(dashTextColor)
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
                } else if !isMapVisible && !showingSpeedTrapList {
                    if let location = locationManager.currentLocation {
                        Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                            .font(.subheadline)
                            .foregroundColor(dashSecondaryTextColor)
                    } else {
                        Text(languageManager.localize("Searching for location..."))
                            .font(.subheadline)
                            .foregroundColor(dashSecondaryTextColor)
                    }
                }
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            // Speed Trap Warning
            if let trap = speedTrapDetector.closestTrap, 
               speedTrapDetector.isWithinRange || speedTrapDetector.infiniteProximity {
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        if #available(iOS 18.0, *) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .symbolEffect(.bounce, options: .repeating)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(speedTrapDetector.speedingAmount > 10 ? languageManager.localize("Reduce speed immediately") : languageManager.localize("Speed Camera Ahead!"))
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text(formatDistance(trap.distance))
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("\(languageManager.localize("Limit")): \(trap.speedLimit.replacingOccurrences(of: ".0", with: ""))")
                                    .font(.headline)
                                    .foregroundColor(speedTrapDetector.speedingAmount > 10 ? .red : .white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(speedTrapDetector.speedingAmount > 10 ? Color.red : Color.white, lineWidth: 1.5)
                                    )
                                    .background(speedTrapDetector.speedingAmount > 10 ? Color.white : Color.clear)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        ZStack {
                            // Breathing Gradient Background
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(alertBackgroundOpacity),
                                    Color.red.opacity(alertBackgroundOpacity * 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .blur(radius: 0)
                            
                            // Glass effect overlay
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    )
                    .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(), value: speedTrapDetector.isWithinRange || speedTrapDetector.infiniteProximity)
                .padding(.bottom, 10)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        alertBackgroundOpacity = 0.9
                    }
                }
            }
            
            
            // Map View or Speed Trap List View (mutually exclusive)
            if isMapVisible {
                ZStack(alignment: .topTrailing) {
                    Map(coordinateRegion: $region, showsUserLocation: true)
                        .frame(height: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Exit button
                    Button {
                        themeManager.triggerHaptic()
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
            } else if showingSpeedTrapList {
                SpeedTrapListView(
                    speedTrapDetector: speedTrapDetector,
                    locationManager: locationManager,
                    languageManager: languageManager,
                    themeManager: themeManager,
                    isPresented: $showingSpeedTrapList
                )
            }
            
            Spacer()
            
            // Buttons
            HStack(spacing: 40) {
                Button {
                    themeManager.triggerHaptic()
                    withAnimation(.spring()) {
                        isMapVisible = false  // Close map if open
                        showingSpeedTrapList = true
                    }
                } label: {
                    Image(systemName: "camera.metering.multispot")
                }
                .buttonStyle(GlassButtonStyle())
                
                Button {
                    themeManager.triggerHaptic()
                    withAnimation(.spring()) {
                        showingSpeedTrapList = false  // Close speed trap list if open
                        isMapVisible.toggle()
                    }
                } label: {
                    Image(systemName: "map")
                }
                .buttonStyle(GlassButtonStyle())
                .scaleEffect(1.2) // Magnify the center button

                Button {
                    themeManager.triggerHaptic()
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding(.vertical, 30)
            .padding(.bottom, 40)
        }
        .animation(.easeInOut(duration: 0.5), value: speedTrapDetector.isSpeeding)
        .background(
            // Modern ambient glow effect when speeding
            ZStack {
                if speedTrapDetector.isSpeeding {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(alertGlowOpacity * 0.5),
                            Color.red.opacity(alertGlowOpacity * 0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 600
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
        )
        .onChange(of: speedTrapDetector.isSpeeding) { _, isSpeeding in
            if isSpeeding {
                // Trigger visual feedback (red glow)
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    alertGlowOpacity = 0.5
                }
                
                // Start audio chime and haptic feedback with appropriate interval
                let isSevere = speedTrapDetector.speedingAmount > 10
                let interval = isSevere ? 2.0 : 4.0
                alertFeedbackManager.startSpeedingAlert(
                    interval: interval,
                    sound: themeManager.alarmSound,
                    volume: Float(themeManager.alarmVolume / 100.0)
                )
            } else {
                // Reset glow opacity
                withAnimation(.easeInOut(duration: 0.5)) {
                    alertGlowOpacity = 0.0
                }
                
                // Stop audio chime and haptic feedback
                alertFeedbackManager.stopSpeedingAlert()
            }
        }
        .onChange(of: speedTrapDetector.speedingAmount) { _, amount in
            if speedTrapDetector.isSpeeding {
                let isSevere = amount > 10
                let interval = isSevere ? 2.0 : 4.0
                alertFeedbackManager.startSpeedingAlert(
                    interval: interval,
                    sound: themeManager.alarmSound,
                    volume: Float(themeManager.alarmVolume / 100.0)
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func speedDisplayView() -> some View {
        switch themeManager.speedDisplayMode {
        case .digital:
            DigitalSpeedView(
                speed: locationManager.currentSpeed,
                isSpeeding: speedTrapDetector.isSpeeding
            )
        case .analog:
            AnalogSpeedView(
                speedMps: locationManager.currentSpeedMps,
                useMetric: locationManager.useMetric,
                isSpeeding: speedTrapDetector.isSpeeding,
                accelerationState: locationManager.accelerationState,
                dashColor: themeManager.analogDashColor
            )
        }
    }
    
    private var horizontalMainView: some View {
        HorizontalDashboardView(
            speed: locationManager.currentSpeed,
            speedMps: locationManager.currentSpeedMps,
            useMetric: locationManager.useMetric,
            isSpeeding: speedTrapDetector.isSpeeding,
            streetName: locationManager.currentStreetName,
            closestTrap: speedTrapDetector.closestTrap,
            tripDistance: locationManager.getFormattedDistance(),
            maxSpeed: locationManager.getFormattedMaxSpeed(),
            accelerationState: locationManager.accelerationState,
            accelerationMagnitude: locationManager.accelerationMagnitude,
            languageManager: languageManager,
            isMapVisible: $isMapVisible,
            showingSettings: $showingSettings,
            alertGlowOpacity: alertGlowOpacity,
            alertBackgroundOpacity: alertBackgroundOpacity
        )
    }
    
    // Helper function to format distance
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}


struct PermissionDeniedView: View {
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(languageManager.localize("Location Access Denied"))
                .font(.title2.bold())
            Text(languageManager.localize("Location Permission Text"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(languageManager.localize("Open Settings")) {
                themeManager.triggerHaptic()
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
    }
}
