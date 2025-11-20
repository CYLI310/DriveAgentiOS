import Foundation
import CoreLocation
import Combine
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var isGeocoding = false
    private var lastGeocodedLocation: CLLocation?

    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentSpeed: String = "0 km/h"
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentStreetName: String = "Finding your location..."

    // Publisher to signal map recentering
    let recenterPublisher = PassthroughSubject<Void, Never>()

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true // Enable background updates
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    func requestPermission() {
        locationManager.requestAlwaysAuthorization() // Request Always permission
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
            currentStreetName = "Location permission needed"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        
        let speedInMetersPerSecond = location.speed
        if speedInMetersPerSecond >= 0 {
            let speedInKilometersPerHour = speedInMetersPerSecond * 3.6
            currentSpeed = String(format: "%.0f km/h", speedInKilometersPerHour)
        } else {
            currentSpeed = "0 km/h"
        }

        if shouldGeocode(newLocation: location) {
            Task {
                await geocode(location: location)
            }
        }
    }
    
    private func shouldGeocode(newLocation: CLLocation) -> Bool {
        guard !isGeocoding else { return false }
        guard let lastLocation = lastGeocodedLocation else { return true }
        
        // Only geocode if the user has moved more than 50 meters
        return newLocation.distance(from: lastLocation) > 50
    }

    private func geocode(location: CLLocation) async {
        isGeocoding = true
        defer { isGeocoding = false }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                self.currentStreetName = placemark.thoroughfare ?? placemark.name ?? "Unnamed Road"
                self.lastGeocodedLocation = location
            } else {
                self.currentStreetName = "Unknown Street"
            }
        } catch {
            print("Reverse geocode with CLGeocoder failed: \(error.localizedDescription)")
            self.currentStreetName = "Unknown Street"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        currentStreetName = "Location unavailable"
    }

    func centerMapOnUserLocation() {
        recenterPublisher.send()
    }
}
