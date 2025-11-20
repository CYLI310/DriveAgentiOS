import SwiftUI
import MapKit

struct FullMapView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    FullMapView()
        .environmentObject(LocationManager())
}
