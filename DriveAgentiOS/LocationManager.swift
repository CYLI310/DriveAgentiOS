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

    @Published var accelerationState: AccelerationState = .steady
    @Published var accelerationMagnitude: Double = 0.0 // m/s² change
    @Published var tripDistance: Double = 0.0 // meters
    @Published var maxSpeed: Double = 0.0 // m/s
    @Published var useMetric: Bool = true
    @Published var currentSpeedMps: Double = 0.0 // Current speed in m/s
    
    private var previousSpeed: CLLocationSpeed = 0
    private var lastTripLocation: CLLocation?

    enum AccelerationState {
        case accelerating
        case decelerating
        case steady
        case stopped
    }

    // ... inside didUpdateLocations ...
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        
        let speedInMetersPerSecond = location.speed
        
        // Update trip distance
        if let lastLocation = lastTripLocation {
            let distance = location.distance(from: lastLocation)
            if distance > 0 && distance < 100 { // Sanity check to avoid GPS jumps
                tripDistance += distance
            }
        }
        lastTripLocation = location
        
        if speedInMetersPerSecond > 0 {
            let speedInKilometersPerHour = speedInMetersPerSecond * 3.6
            currentSpeed = formatSpeed(speedInMetersPerSecond)
            currentSpeedMps = speedInMetersPerSecond
            
            // Track max speed
            if speedInMetersPerSecond > maxSpeed {
                maxSpeed = speedInMetersPerSecond
            }
            
            // Determine acceleration
            let speedDiff = speedInMetersPerSecond - previousSpeed
            accelerationMagnitude = abs(speedDiff)
            
            if speedDiff > 0.1 { // Threshold for noise
                accelerationState = .accelerating
            } else if speedDiff < -0.1 {
                accelerationState = .decelerating
            } else {
                accelerationState = .steady
            }
        } else {
            currentSpeed = useMetric ? "0 km/h" : "0 mph"
            currentSpeedMps = 0.0
            accelerationState = .stopped
            accelerationMagnitude = 0.0
        }
        
        previousSpeed = speedInMetersPerSecond


        if shouldGeocode(newLocation: location) {
            Task {
                await geocode(location: location)
            }
        }
    }
    
    private func formatSpeed(_ speedInMetersPerSecond: Double) -> String {
        if useMetric {
            let speedInKmh = speedInMetersPerSecond * 3.6
            return String(format: "%.0f km/h", speedInKmh)
        } else {
            let speedInMph = speedInMetersPerSecond * 2.23694
            return String(format: "%.0f mph", speedInMph)
        }
    }
    
    func getFormattedDistance() -> String {
        if useMetric {
            if tripDistance < 1000 {
                return String(format: "%.0f m", tripDistance)
            } else {
                return String(format: "%.2f km", tripDistance / 1000)
            }
        } else {
            let miles = tripDistance * 0.000621371
            if miles < 0.1 {
                let feet = tripDistance * 3.28084
                return String(format: "%.0f ft", feet)
            } else {
                return String(format: "%.2f mi", miles)
            }
        }
    }
    
    func getFormattedMaxSpeed() -> String {
        return formatSpeed(maxSpeed)
    }
    
    func resetTrip() {
        tripDistance = 0.0
        maxSpeed = 0.0
        lastTripLocation = nil
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
