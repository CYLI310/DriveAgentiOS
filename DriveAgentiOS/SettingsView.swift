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
    @ObservedObject var languageManager: LanguageManager
    @State private var alertProximity: Double = 500 // meters
    @State private var showTutorial = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(languageManager.localize("Language"))) {
                    Picker(languageManager.localize("Language"), selection: $languageManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text(languageManager.localize("Appearance"))) {
                    Picker(languageManager.localize("Theme"), selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text(languageManager.localize("Particle Effects"))) {
                    Picker(languageManager.localize("Effect Style"), selection: $themeManager.particleEffectStyle) {
                        ForEach(ParticleEffectStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text(languageManager.localize(effectDescription))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Units"))) {
                    Toggle(languageManager.localize("Use Metric"), isOn: $locationManager.useMetric)
                    Text(locationManager.useMetric ? languageManager.localize("Metric Description") : languageManager.localize("Imperial Description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Trip"))) {
                    HStack {
                        Text(languageManager.localize("Distance"))
                        Spacer()
                        Text(locationManager.getFormattedDistance())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(languageManager.localize("Max Speed"))
                        Spacer()
                        Text(locationManager.getFormattedMaxSpeed())
                            .foregroundColor(.secondary)
                    }
                    
                    Button(languageManager.localize("Reset Trip")) {
                        locationManager.resetTrip()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text(languageManager.localize("Speed Camera Alerts"))) {
                    Toggle(languageManager.localize("Infinite Proximity"), isOn: $speedTrapDetector.infiniteProximity)
                    Text(speedTrapDetector.infiniteProximity ? 
                         languageManager.localize("Infinite Proximity On") :
                         languageManager.localize("Infinite Proximity Off"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(alignment: .leading) {
                        Text("\(languageManager.localize("Alert Distance")): \(Int(alertProximity)) m")
                        Slider(value: $alertProximity, in: 100...2000, step: 50)
                            .onChange(of: alertProximity) { newValue in
                                speedTrapDetector.alertDistance = newValue
                            }
                    }
                    Text(languageManager.localize("Alert Distance Description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Other Settings"))) {
                    Button {
                        showTutorial = true
                    } label: {
                        HStack {
                            Text(languageManager.localize("Show Tutorial"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                // Sync with current detector value
                alertProximity = speedTrapDetector.alertDistance
            }
            .navigationTitle(languageManager.localize("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(languageManager.localize("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            OnboardingView(isPresented: $showTutorial, languageManager: languageManager)
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
    SettingsView(themeManager: ThemeManager(), locationManager: LocationManager(), speedTrapDetector: SpeedTrapDetector(), languageManager: LanguageManager())
}
