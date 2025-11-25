import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    @Published var particleEffectStyle: ParticleEffectStyle {
        didSet {
            UserDefaults.standard.set(particleEffectStyle.rawValue, forKey: "particleEffectStyle")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        let savedStyle = UserDefaults.standard.string(forKey: "particleEffectStyle") ?? ParticleEffectStyle.orbit.rawValue
        self.particleEffectStyle = ParticleEffectStyle(rawValue: savedStyle) ?? .orbit
    }
}


struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var speedTrapDetector: SpeedTrapDetector
    @State private var alertProximity: Double = 500 // meters

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Particle Effects")) {
                    Picker("Effect Style", selection: $themeManager.particleEffectStyle) {
                        ForEach(ParticleEffectStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(effectDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Units")) {
                    Toggle("Use Metric (km/h, km)", isOn: $locationManager.useMetric)
                    Text(locationManager.useMetric ? "Speed in km/h, distance in km/m" : "Speed in mph, distance in mi/ft")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Trip")) {
                    HStack {
                        Text("Distance")
                        Spacer()
                        Text(locationManager.getFormattedDistance())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Max Speed")
                        Spacer()
                        Text(locationManager.getFormattedMaxSpeed())
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Reset Trip") {
                        locationManager.resetTrip()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Speed Camera Alerts")) {
                    VStack(alignment: .leading) {
                        Text("Alert Distance: \(Int(alertProximity)) meters")
                        Slider(value: $alertProximity, in: 100...2000, step: 50)
                            .onChange(of: alertProximity) { newValue in
                                speedTrapDetector.alertDistance = newValue
                            }
                    }
                    Text("You'll be alerted when within this distance of a speed camera")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Other Settings")) {
                    Text("More settings will go here...")
                }
            }
            .onAppear {
                // Sync with current detector value
                alertProximity = speedTrapDetector.alertDistance
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var effectDescription: String {
        switch themeManager.particleEffectStyle {
        case .off:
            return "No particle effects will be shown"
        case .orbit:
            return "Particles orbit around the speed display"
        case .pulse:
            return "Particles pulse in and out rhythmically"
        case .spiral:
            return "Particles move in a dynamic spiral pattern"
        }
    }
}

#Preview {
    SettingsView(themeManager: ThemeManager(), locationManager: LocationManager(), speedTrapDetector: SpeedTrapDetector())
}
