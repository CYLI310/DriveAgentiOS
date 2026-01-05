import Foundation
import CoreLocation
import Combine

struct SpeedTrapInfo {
    let coordinate: CLLocationCoordinate2D
    let speedLimit: String
    let address: String
    let direction: String
    let distance: Double
}

// Minimal decodable structure for efficient parsing (Taiwan GeoJSON)
private struct MinimalFeature: Decodable {
    let geometry: Geometry
    let properties: Properties
    
    struct Geometry: Decodable {
        let coordinates: [Double]
    }
    
    struct Properties: Decodable {
        let name: String
        let 設置地址: String
        let 拍攝方向: String?
    }
}

private struct MinimalFeatureCollection: Decodable {
    let features: [MinimalFeature]
}

// Minimal decodable structure for efficient parsing (US JSON)
private struct USMinimalFeature: Decodable {
    let attributes: Attributes
    
    struct Attributes: Decodable {
        let ROADNAME: String
        let ROADDIR: String?
        let LATITUDE: Double
        let LONGITUDE: Double
        let SPEED: Int
    }
}

private struct USMinimalFeatureCollection: Decodable {
    let features: [USMinimalFeature]
}

struct UnifiedTrap {
    let coordinate: CLLocationCoordinate2D
    let speedLimitValue: Double // Always in km/h for comparison
    let speedLimitDisplay: String // For UI display
    let address: String
    let direction: String
}

@MainActor
class SpeedTrapDetector: ObservableObject {
    @Published var closestTrap: SpeedTrapInfo?
    @Published var isWithinRange: Bool = false
    @Published var isSpeeding: Bool = false // true when speed exceeds speed limit
    @Published var speedingAmount: Double = 0.0 // Amount over limit in km/h
    @Published var alertDistance: Double = 500 // meters - configurable
    @Published var infiniteProximity: Bool = false // when true, ignores 2km limit
    
    private var lastCheckLocation: CLLocation?
    private var isChecking = false
    private var cachedTraps: [UnifiedTrap]?
    
    private func loadAllTraps() -> [UnifiedTrap] {
        if let cached = cachedTraps { return cached }
        
        var traps: [UnifiedTrap] = []
        let decoder = JSONDecoder()
        
        // 1. Load Taiwan Traps
        if let url = Bundle.main.url(forResource: "speedtraps", withExtension: "geojson") {
            do {
                let data = try Data(contentsOf: url)
                let collection = try decoder.decode(MinimalFeatureCollection.self, from: data)
                for feature in collection.features {
                    guard feature.geometry.coordinates.count >= 2 else { continue }
                    let speedLimit = Double(feature.properties.name.replacingOccurrences(of: ".0", with: "")) ?? 0
                    traps.append(UnifiedTrap(
                        coordinate: CLLocationCoordinate2D(latitude: feature.geometry.coordinates[1], longitude: feature.geometry.coordinates[0]),
                        speedLimitValue: speedLimit,
                        speedLimitDisplay: feature.properties.name,
                        address: feature.properties.設置地址,
                        direction: feature.properties.拍攝方向 ?? ""
                    ))
                }
            } catch {
                print("Error loading Taiwan speed traps: \(error)")
            }
        }
        
        // 2. Load US Traps
        if let url = Bundle.main.url(forResource: "usspeedtraps", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let collection = try decoder.decode(USMinimalFeatureCollection.self, from: data)
                for feature in collection.features {
                    // Convert US speed (presumably MPH) to KMH for consistent internal comparison if it's non-zero
                    let speedMph = Double(feature.attributes.SPEED)
                    let speedLimitKmh = speedMph * 1.60934
                    
                    traps.append(UnifiedTrap(
                        coordinate: CLLocationCoordinate2D(latitude: feature.attributes.LATITUDE, longitude: feature.attributes.LONGITUDE),
                        speedLimitValue: speedLimitKmh,
                        speedLimitDisplay: speedMph > 0 ? "\(Int(speedMph))" : "N/A",
                        address: feature.attributes.ROADNAME,
                        direction: feature.attributes.ROADDIR ?? ""
                    ))
                }
            } catch {
                print("Error loading US speed traps: \(error)")
            }
        }
        
        cachedTraps = traps
        return traps
    }
    
    func checkForNearbyTraps(userLocation: CLLocationCoordinate2D, currentSpeed: Double = 0, currentStreetName: String = "", currentCourse: Double = -1) {
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
            
            let traps = await self.loadAllTraps()
            
            var closestDistance = Double.infinity
            var closestTrapData: UnifiedTrap?
            
            // Keep track of the best candidate based on matching criteria
            var bestCandidate: UnifiedTrap?
            var bestCandidateDistance = Double.infinity
            var bestCandidateScore = 0 // Higher is better
            
            // Find closest trap
            for trap in traps {
                let trapLocation = CLLocation(
                    latitude: trap.coordinate.latitude,
                    longitude: trap.coordinate.longitude
                )
                
                let distance = currentLocation.distance(from: trapLocation)
                
                // Check distance based on infiniteProximity setting
                let withinRange = useInfiniteProximity || distance < 2000
                
                if withinRange {
                    let direction = trap.direction
                    let address = trap.address
                    
                    // Calculate Match Score
                    var score = 0
                    
                    // 1. Road Name Match
                    if !currentStreetName.isEmpty && currentStreetName != "Finding your location..." && currentStreetName != "Unknown Street" {
                         if self.isRoadMatching(userStreet: currentStreetName, trapAddress: address) {
                             score += 1000
                         }
                    }
                    
                    // 2. Direction Match
                    if currentCourse >= 0 {
                        if self.isDirectionMatching(userCourse: currentCourse, trapDirection: direction) {
                            score += 500
                        }
                    }
                    
                    // 3. Distance Score
                    if distance < 2000 {
                        score += Int(2000 - distance) / 10
                    }
                    
                    if score > bestCandidateScore {
                        bestCandidateScore = score
                        bestCandidateDistance = distance
                        bestCandidate = trap
                    } else if score == bestCandidateScore {
                        if distance < bestCandidateDistance {
                            bestCandidateDistance = distance
                            bestCandidate = trap
                        }
                    }
                }
            }
            
            // Use best candidate if found
            if let candidate = bestCandidate {
                closestDistance = bestCandidateDistance
                closestTrapData = candidate
            }
            
            let distanceText = closestDistance.isFinite ? "\(Int(closestDistance))m" : "N/A"
            print("Checked \(traps.count) speed traps, closest: \(distanceText)")
                
                // Update on main thread
                await MainActor.run {
                    if let trapData = closestTrapData {
                        self.closestTrap = SpeedTrapInfo(
                            coordinate: trapData.coordinate,
                            speedLimit: trapData.speedLimitDisplay,
                            address: trapData.address,
                            direction: trapData.direction,
                            distance: closestDistance
                        )
                        self.isWithinRange = closestDistance <= self.alertDistance
                        
                        // Check if speeding (compare current speed in km/h with speed limit)
                        if trapData.speedLimitValue > 0 {
                            let currentSpeedKmh = currentSpeed * 3.6 // Convert m/s to km/h
                            self.speedingAmount = currentSpeedKmh - trapData.speedLimitValue
                            self.isSpeeding = (self.isWithinRange || self.infiniteProximity) && self.speedingAmount > 0
                        } else {
                            self.isSpeeding = false
                            self.speedingAmount = 0.0
                        }
                    } else {
                        self.closestTrap = nil
                        self.isWithinRange = false
                        self.isSpeeding = false
                        self.speedingAmount = 0.0
                    }
                }
        }
    }
    
    // Helper function to check if road names match
    nonisolated private func isRoadMatching(userStreet: String, trapAddress: String) -> Bool {
        // Simple containment check
        // "National Highway 1" vs "國道1號" is hard without mapping.
        // But "Zhongshan Road" vs "中山路" might work if userStreet is localized.
        // If userStreet is English, this will likely fail unless we have a mapping.
        // However, if the user is in Taiwan using a Chinese locale, it works.
        // Even in English, sometimes numbers match (e.g. "Route 1" vs "台1線").
        
        // Normalize: remove common suffixes/prefixes for better matching?
        // For now, strict containment is safer than false positives.
        
        // If userStreet is very short (e.g. "Road"), ignore it to avoid false positives
        if userStreet.count < 2 { return false }
        
        return trapAddress.contains(userStreet)
    }
    
    // Helper function to check if direction matches
    nonisolated private func isDirectionMatching(userCourse: Double, trapDirection: String) -> Bool {
        // userCourse is 0-360, 0 is North, 90 East, etc.
        
        // Parse trap direction
        // Common formats: "南向北" (S->N), "北向南" (N->S), "東向西" (E->W), "西向東" (W->E)
        // "東西雙向", "南北雙向" -> bidirectional
        
        if trapDirection.contains("雙向") {
            return true
        }
        
        var targetHeading: Double?
        
        if trapDirection.contains("南向北") {
            targetHeading = 0 // North
        } else if trapDirection.contains("北向南") {
            targetHeading = 180 // South
        } else if trapDirection.contains("西向東") {
            targetHeading = 90 // East
        } else if trapDirection.contains("東向西") {
            targetHeading = 270 // West
        }
        
        guard let target = targetHeading else {
            // If we can't parse direction, assume match (fail open) or mismatch?
            // "順向" (Forward) usually means aligned with road. Without road geometry, hard to tell.
            // Let's assume true for unknown directions to be safe.
            return true
        }
        
        // Check if user course is within +/- 60 degrees of target
        let diff = abs(userCourse - target)
        let minDiff = min(diff, 360 - diff)
        
        return minDiff < 60
    }
    
    func getNearestSpeedTraps(userLocation: CLLocationCoordinate2D, count: Int = 10) async -> [SpeedTrapInfo] {
        let currentLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let traps = self.loadAllTraps()
        
        // Calculate distances for all traps
        var trapsWithDistance: [(trap: SpeedTrapInfo, distance: Double)] = []
        
        for trap in traps {
            let trapLocation = CLLocation(
                latitude: trap.coordinate.latitude,
                longitude: trap.coordinate.longitude
            )
            
            let distance = currentLocation.distance(from: trapLocation)
            
            let trapInfo = SpeedTrapInfo(
                coordinate: trap.coordinate,
                speedLimit: trap.speedLimitDisplay,
                address: trap.address,
                direction: trap.direction,
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
    }
}


