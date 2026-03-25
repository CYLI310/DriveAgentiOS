import SwiftUI
import MapKit

struct FullMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var speedTrapDetector: SpeedTrapDetector
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            SpeedTrapAnnotations(traps: speedTrapDetector.nearbyTraps)
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: true))
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottomTrailing) {
            Button {
                withAnimation {
                    cameraPosition = .userLocation(fallback: .automatic)
                }
            } label: {
                Image(systemName: "location.fill")
                    .padding(15)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(20)
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    FullMapView()
        .environmentObject(LocationManager())
}
