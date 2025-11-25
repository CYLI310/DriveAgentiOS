import Foundation
import CoreLocation
import Combine

struct SpeedTrapInfo {
    let coordinate: CLLocationCoordinate2D
    let speedLimit: String
    let address: String
    let distance: Double
}

// Minimal decodable structure for efficient parsing
private struct MinimalFeature: Decodable {
    let geometry: Geometry
    let properties: Properties
    
    struct Geometry: Decodable {
        let coordinates: [Double]
    }
    
    struct Properties: Decodable {
        let name: String
        let 設置地址: String
    }
}

private struct MinimalFeatureCollection: Decodable {
    let features: [MinimalFeature]
}

@MainActor
class SpeedTrapDetector: ObservableObject {
    @Published var closestTrap: SpeedTrapInfo?
    @Published var isWithinRange: Bool = false
    @Published var alertDistance: Double = 500 // meters - configurable
    
    private var lastCheckLocation: CLLocation?
    private var isChecking = false
    
    func checkForNearbyTraps(userLocation: CLLocationCoordinate2D) {
        // Prevent concurrent checks
        guard !isChecking else { return }
        
        // Only check if user has moved significantly (100m)
        let currentLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        if let lastLocation = lastCheckLocation {
            let distance = currentLocation.distance(from: lastLocation)
            if distance < 100 {
                return
            }
        }
        
        lastCheckLocation = currentLocation
        isChecking = true
        
        Task.detached(priority: .utility) {
            defer {
                Task { @MainActor in
                    self.isChecking = false
                }
            }
            
            guard let url = Bundle.main.url(forResource: "speedtraps", withExtension: "geojson") else {
                print("Speed traps file not found")
                return
            }
            
            var closestDistance = Double.infinity
            var closestTrapData: (coordinate: CLLocationCoordinate2D, speedLimit: String, address: String)?
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                // Decode the entire file (it's done efficiently by JSONDecoder)
                let collection = try decoder.decode(MinimalFeatureCollection.self, from: data)
                
                // Find closest trap
                for feature in collection.features {
                    guard feature.geometry.coordinates.count >= 2 else { continue }
                    
                    let trapLocation = CLLocation(
                        latitude: feature.geometry.coordinates[1],
                        longitude: feature.geometry.coordinates[0]
                    )
                    
                    let distance = currentLocation.distance(from: trapLocation)
                    
                    // Only consider traps within 2km and closer than current closest
                    if distance < 2000 && distance < closestDistance {
                        closestDistance = distance
                        closestTrapData = (
                            coordinate: CLLocationCoordinate2D(
                                latitude: feature.geometry.coordinates[1],
                                longitude: feature.geometry.coordinates[0]
                            ),
                            speedLimit: feature.properties.name,
                            address: feature.properties.設置地址
                        )
                    }
                }
                
                let distanceText = closestDistance.isFinite ? "\(Int(closestDistance))m" : "N/A"
                print("Checked \(collection.features.count) speed traps, closest: \(distanceText)")
                
                // Update on main thread
                await MainActor.run {
                    if let trapData = closestTrapData {
                        self.closestTrap = SpeedTrapInfo(
                            coordinate: trapData.coordinate,
                            speedLimit: trapData.speedLimit,
                            address: trapData.address,
                            distance: closestDistance
                        )
                        self.isWithinRange = closestDistance <= self.alertDistance
                    } else {
                        self.closestTrap = nil
                        self.isWithinRange = false
                    }
                }
                
            } catch {
                print("Error reading speed traps: \(error)")
            }
        }
    }
}

