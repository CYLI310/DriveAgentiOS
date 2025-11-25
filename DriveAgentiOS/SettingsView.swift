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
    @Published var currentTheme: AppTheme = .dark {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }
    
    init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(themeManager: ThemeManager(), locationManager: LocationManager(), speedTrapDetector: SpeedTrapDetector())
}
