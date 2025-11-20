import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var alertProximity: Double = 500 // meters
    @State private var selectedLanguage = "English"
    let languages = ["English", "Español", "Français", "Deutsch"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Alerts")) {
                    VStack(alignment: .leading) {
                        Text("Alert Proximity: \(Int(alertProximity)) meters")
                        Slider(value: $alertProximity, in: 100...2000, step: 50)
                    }
                }

                Section(header: Text("General")) {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Other Settings")) {
                    Text("More settings will go here...")
                }
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
    SettingsView()
}
