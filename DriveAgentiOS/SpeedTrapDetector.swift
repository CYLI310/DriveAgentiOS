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
                
                // Only consider traps within range
                let withinRange = useInfiniteProximity || distance < 2000
                
                if withinRange {
                    let direction = trap.direction
                    let address = trap.address
                    
                    // 1. Direction Match
                    var directionScore = 0
                    var isDirectionMatched = false
                    
                    if currentCourse >= 0 {
                        if self.isDirectionMatching(userCourse: currentCourse, trapDirection: direction) {
                            directionScore = 500
                            isDirectionMatched = true
                        } else if direction.isEmpty || direction == "N/A" {
                            // If no direction info, don't penalize but don't reward
                            directionScore = 0
                        } else {
                            // Direction known and doesn't match - heavy penalty
                            directionScore = -1000
                        }
                    }
                    
                    // 2. Ahead Check
                    let bearingToTrap = self.calculateBearing(from: userLocation, to: trap.coordinate)
                    let bearingDiff = abs(currentCourse - bearingToTrap)
                    let minBearingDiff = min(bearingDiff, 360 - bearingDiff)
                    
                    var aheadScore = 0
                    let isAhead = minBearingDiff < 60 // Trap is in front of us
                    let isPassed = minBearingDiff > 120 // Trap is behind us
                    
                    if isAhead {
                        aheadScore = 400
                    } else if isPassed && distance > 50 {
                        // Already passed by more than 50m - heavy penalty
                        aheadScore = -2000
                    }
                    
                    // 3. Road Name Match
                    var roadScore = 0
                    if !currentStreetName.isEmpty && currentStreetName != "Finding your location..." && currentStreetName != "Unknown Street" {
                         if self.isRoadMatching(userStreet: currentStreetName, trapAddress: address) {
                             roadScore = 1200 // Strongest signal
                         }
                    }
                    
                    // 4. Distance Score
                    let distanceScore = Int(max(0, 2000 - distance)) / 10
                    
                    // Final Match Score calculation
                    let totalScore = roadScore + directionScore + aheadScore + distanceScore
                    
                    if totalScore > bestCandidateScore {
                        bestCandidateScore = totalScore
                        bestCandidateDistance = distance
                        bestCandidate = trap
                    } else if totalScore == bestCandidateScore {
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
        if userStreet.count < 2 { return false }
        
        let normalizedUser = userStreet.lowercased()
            .replacingOccurrences(of: "road", with: "rd")
            .replacingOccurrences(of: "street", with: "st")
            .replacingOccurrences(of: "highway", with: "hwy")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        let normalizedTrap = trapAddress.lowercased()
            .replacingOccurrences(of: "road", with: "rd")
            .replacingOccurrences(of: "street", with: "st")
            .replacingOccurrences(of: "highway", with: "hwy")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalizedTrap.contains(normalizedUser) || normalizedUser.contains(normalizedTrap) {
            return true
        }
        
        // Match numbers (e.g. "Route 1" and "台1線" or "Hwy 1")
        let userNumbers = normalizedUser.filter { $0.isNumber }
        let trapNumbers = normalizedTrap.filter { $0.isNumber }
        
        if !userNumbers.isEmpty && userNumbers == trapNumbers {
            // If they have the same numbers and it's a short sequence (like a highway number), count it as a potential match
            if userNumbers.count >= 1 && (normalizedUser.contains("hwy") || normalizedUser.contains("route") || normalizedUser.contains("國道") || normalizedUser.contains("台")) {
                return true
            }
        }
        
        return false
    }
    
    // Helper function to check if direction matches
    nonisolated private func isDirectionMatching(userCourse: Double, trapDirection: String) -> Bool {
        // userCourse is 0-360, 0 is North, 90 East, etc.
        let dir = trapDirection.uppercased()
        
        if dir.contains("雙向") || dir.contains("BOTH") || dir.contains("BIDIRECTIONAL") {
            return true
        }
        
        var targetHeading: Double?
        
        // Taiwan formats
        if dir.contains("南向北") || dir.contains("由南往北") {
            targetHeading = 0 // North
        } else if dir.contains("北向南") || dir.contains("由北往南") {
            targetHeading = 180 // South
        } else if dir.contains("西向東") || dir.contains("由西往東") {
            targetHeading = 90 // East
        } else if dir.contains("東向西") || dir.contains("由東往西") {
            targetHeading = 270 // West
        }
        // US / English formats
        else if dir == "N" || dir == "NORTH" || dir.contains("NORTHBOUND") || dir == "NB" {
            targetHeading = 0
        } else if dir == "S" || dir == "SOUTH" || dir.contains("SOUTHBOUND") || dir == "SB" {
            targetHeading = 180
        } else if dir == "E" || dir == "EAST" || dir.contains("EASTBOUND") || dir == "EB" {
            targetHeading = 90
        } else if dir == "W" || dir == "WEST" || dir.contains("WESTBOUND") || dir == "WB" {
            targetHeading = 270
        }
        
        guard let target = targetHeading else {
            // If we can't parse direction, assume match (fail open) for safety
            // but the scoring logic will now use ahead-check to compensate.
            return true
        }
        
        // Check if user course is within +/- 45 degrees of target (tighter than 60)
        let diff = abs(userCourse - target)
        let minDiff = min(diff, 360 - diff)
        
        return minDiff < 45
    }
    
    nonisolated private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        let degrees = radians * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
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


