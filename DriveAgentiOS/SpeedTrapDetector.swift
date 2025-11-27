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
    @Published var isSpeeding: Bool = false // true when speed exceeds speed limit
    @Published var alertDistance: Double = 500 // meters - configurable
    @Published var infiniteProximity: Bool = false // when true, ignores 2km limit
    
    private var lastCheckLocation: CLLocation?
    private var isChecking = false
    
    func checkForNearbyTraps(userLocation: CLLocationCoordinate2D, currentSpeed: Double = 0) {
        // Prevent concurrent checks
        guard !isChecking else { return }
        
        // Only check if user has moved significantly (100m)
        let currentLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        if let lastLocation = lastCheckLocation {
            let distance = currentLocation.distance(from: lastLocation)
            // Skip check if haven't moved 100m AND infinite proximity is OFF
            if distance < 100 && !infiniteProximity {
                return
            }
        }
        
        lastCheckLocation = currentLocation
        isChecking = true
        
        // Capture the setting value before entering detached task
        let useInfiniteProximity = infiniteProximity
        
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
                    
                    // Check distance based on infiniteProximity setting
                    let withinRange = useInfiniteProximity || distance < 2000
                    
                    // Only consider traps within range and closer than current closest
                    if withinRange && distance < closestDistance {
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
                        
                        // Check if speeding (compare current speed in km/h with speed limit)
                        if let speedLimitValue = Double(trapData.speedLimit.replacingOccurrences(of: ".0", with: "")) {
                            let currentSpeedKmh = currentSpeed * 3.6 // Convert m/s to km/h
                            self.isSpeeding = (self.isWithinRange || self.infiniteProximity) && currentSpeedKmh > speedLimitValue
                        } else {
                            self.isSpeeding = false
                        }
                    } else {
                        self.closestTrap = nil
                        self.isWithinRange = false
                        self.isSpeeding = false
                    }
                }
                
            } catch {
                print("Error reading speed traps: \(error)")
            }
        }
    }
    
    func getNearestSpeedTraps(userLocation: CLLocationCoordinate2D, count: Int = 10) async -> [SpeedTrapInfo] {
        let currentLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        guard let url = Bundle.main.url(forResource: "speedtraps", withExtension: "geojson") else {
            print("Speed traps file not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let collection = try decoder.decode(MinimalFeatureCollection.self, from: data)
            
            // Calculate distances for all traps
            var trapsWithDistance: [(trap: SpeedTrapInfo, distance: Double)] = []
            
            for feature in collection.features {
                guard feature.geometry.coordinates.count >= 2 else { continue }
                
                let trapLocation = CLLocation(
                    latitude: feature.geometry.coordinates[1],
                    longitude: feature.geometry.coordinates[0]
                )
                
                let distance = currentLocation.distance(from: trapLocation)
                
                let trapInfo = SpeedTrapInfo(
                    coordinate: CLLocationCoordinate2D(
                        latitude: feature.geometry.coordinates[1],
                        longitude: feature.geometry.coordinates[0]
                    ),
                    speedLimit: feature.properties.name,
                    address: feature.properties.設置地址,
                    distance: distance
                )
                
                trapsWithDistance.append((trap: trapInfo, distance: distance))
            }
            
            // Sort by distance and take the nearest 'count' traps
            let nearestTraps = trapsWithDistance
                .sorted { $0.distance < $1.distance }
                .prefix(count)
                .map { $0.trap }
            
            return Array(nearestTraps)
            
        } catch {
            print("Error reading speed traps: \(error)")
            return []
        }
    }
}

