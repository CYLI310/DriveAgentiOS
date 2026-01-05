import SwiftUI
import Combine
import AudioToolbox
import UIKit

enum SpeedDisplayMode: String, CaseIterable, Identifiable {
    case digital = "Digital"
    case analog = "Analog"
    case retroDigital = "Retro Digital"
    
    var id: String { self.rawValue }
}

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

@MainActor
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
    
    @Published var showTopBar: Bool {
        didSet {
            UserDefaults.standard.set(showTopBar, forKey: "showTopBar")
        }
    }
    
    @Published var speedDisplayMode: SpeedDisplayMode {
        didSet {
            UserDefaults.standard.set(speedDisplayMode.rawValue, forKey: "speedDisplayMode")
        }
    }
    
    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        let savedStyle = UserDefaults.standard.string(forKey: "particleEffectStyle") ?? ParticleEffectStyle.off.rawValue
        self.particleEffectStyle = ParticleEffectStyle(rawValue: savedStyle) ?? .off
        
        self.showTopBar = UserDefaults.standard.object(forKey: "showTopBar") as? Bool ?? true
        
        let savedMode = UserDefaults.standard.string(forKey: "speedDisplayMode") ?? SpeedDisplayMode.digital.rawValue
        self.speedDisplayMode = SpeedDisplayMode(rawValue: savedMode) ?? .digital
        
        self.hapticFeedbackEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
    }
    
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}


struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var speedTrapDetector: SpeedTrapDetector
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var distractionDetector: DistractionDetector
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
                    .pickerStyle(.menu)
                    .onChange(of: languageManager.currentLanguage) { _ in
                        themeManager.triggerHaptic()
                    }
                }
                
                Section(header: Text(languageManager.localize("Appearance"))) {
                    Toggle(languageManager.localize("Show Top Bar"), isOn: $themeManager.showTopBar)
                        .onChange(of: themeManager.showTopBar) { _ in themeManager.triggerHaptic() }
                    
                    Picker(languageManager.localize("Theme"), selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(languageManager.localize(theme.rawValue)).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: themeManager.currentTheme) { _ in themeManager.triggerHaptic() }
                }
                
                Section(header: Text(languageManager.localize("Haptics"))) {
                    Toggle(languageManager.localize("Haptic Feedback"), isOn: $themeManager.hapticFeedbackEnabled)
                        .onChange(of: themeManager.hapticFeedbackEnabled) { _ in themeManager.triggerHaptic(.medium) }
                    
                    Text(languageManager.localize("Haptic Feedback Description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Speed Display"))) {
                    Picker(languageManager.localize("Speed Display Mode"), selection: $themeManager.speedDisplayMode) {
                        ForEach(SpeedDisplayMode.allCases) { mode in
                            Text(languageManager.localize(mode.rawValue)).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: themeManager.speedDisplayMode) { _ in themeManager.triggerHaptic() }
                    
                    Text(languageManager.localize("Choose how your current speed is visualized on the main screen."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Particle Effects"))) {
                    Picker(languageManager.localize("Effect Style"), selection: $themeManager.particleEffectStyle) {
                        ForEach(ParticleEffectStyle.allCases) { style in
                            Text(languageManager.localize(style.rawValue)).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: themeManager.particleEffectStyle) { _ in themeManager.triggerHaptic() }
                    
                    Text(languageManager.localize(effectDescription))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Units"))) {
                    Toggle(languageManager.localize("Use Metric"), isOn: $locationManager.useMetric)
                        .onChange(of: locationManager.useMetric) { _ in themeManager.triggerHaptic() }
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
                        themeManager.triggerHaptic(.medium)
                        locationManager.resetTrip()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text(languageManager.localize("Speed Camera Alerts"))) {
                    Toggle(languageManager.localize("Infinite Proximity"), isOn: $speedTrapDetector.infiniteProximity)
                        .onChange(of: speedTrapDetector.infiniteProximity) { _ in themeManager.triggerHaptic() }
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
                                // Subtle feedback while sliding
                            }
                    }
                    Text(languageManager.localize("Alert Distance Description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text(languageManager.localize("Distraction Alert"))) {
                    if distractionDetector.isSupported {
                        Toggle(languageManager.localize("Distraction Alert"), isOn: $distractionDetector.isEnabled)
                            .onChange(of: distractionDetector.isEnabled) { _ in themeManager.triggerHaptic() }
                        Text(languageManager.localize("Warns you if you look at the screen while driving fast."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(languageManager.localize("Face tracking is not supported on this device."))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text(languageManager.localize("Other Settings"))) {
                    Button {
                        themeManager.triggerHaptic()
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
                        themeManager.triggerHaptic()
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            OnboardingView(isPresented: $showTutorial, languageManager: languageManager, themeManager: themeManager)
        }
    }
    
    private var effectDescription: String {
        switch themeManager.particleEffectStyle {
        case .off:
            return "No particle effects will be shown"
        case .orbit:
            return "Particles orbit around the speed display"
        case .linearGradient:
            return "A rotating gradient background"
        }
    }
}
