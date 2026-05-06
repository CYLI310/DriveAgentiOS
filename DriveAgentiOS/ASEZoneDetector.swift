import Foundation
import CoreLocation
import Combine

// MARK: - Models

struct ASEZone: Identifiable {
    var id: String { location }
    let location: String        // human-readable description from JSON
    let speedLimit: String      // display string e.g. "50KM"
    let speedLimitValue: Double // numeric km/h (lower value if day/night split)
    let length: String          // e.g. "約900公尺"
    let coordinate: CLLocationCoordinate2D
    let direction: String       // "往南", "往北", "往東", "往西", "雙向", "單向", or ""
}

struct ASEZoneInfo {
    let zone: ASEZone
    let distance: Double
}

// MARK: - Raw JSON

private struct ASERawCollection: Decodable {
    let features: [ASERawFeature]
}

private struct ASERawFeature: Decodable {
    let properties: Properties
    struct Properties: Decodable {
        let location: String
        let speed_limit: String
        let length: String
    }
}

// MARK: - Detector

@MainActor
class ASEZoneDetector: ObservableObject {

    // MARK: Published
    @Published var closestZone: ASEZoneInfo?
    @Published var isWithinRange: Bool = false
    @Published var nearbyZones: [ASEZone] = []
    @Published var geocodingProgress: Int = 0
    @Published var totalZones: Int = 0
    @Published var isGeocodingComplete: Bool = false

    var alertDistance: Double = 1500 // metres before zone entry

    // MARK: Private
    private var allZones: [ASEZone] = []
    private let geocoder = CLGeocoder()
    private let cacheKey = "ase_geocode_cache_v2"
    private var isLoaded = false

    private var coordinateCache: [String: [Double]] {
        get { UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: [Double]] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: cacheKey) }
    }

    // MARK: - Load & Geocode

    func loadZones() async {
        guard !isLoaded else { return }
        isLoaded = true

        guard let url = Bundle.main.url(forResource: "ase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let collection = try? JSONDecoder().decode(ASERawCollection.self, from: data) else {
            print("ASEZoneDetector: Failed to load ase.json")
            isGeocodingComplete = true
            return
        }

        let rawFeatures = collection.features
        totalZones = rawFeatures.count
        geocodingProgress = 0

        var cache = coordinateCache
        var zones: [ASEZone] = []
        var toGeocode: [ASERawFeature] = []

        // First pass: load from cache
        for feature in rawFeatures {
            let key = feature.properties.location
            if let cached = cache[key], cached.count >= 2 {
                zones.append(makeZone(from: feature, lat: cached[0], lon: cached[1]))
                geocodingProgress += 1
            } else {
                toGeocode.append(feature)
            }
        }

        allZones = zones

        guard !toGeocode.isEmpty else {
            isGeocodingComplete = true
            print("ASEZoneDetector: All \(zones.count) zones loaded from cache.")
            return
        }

        print("ASEZoneDetector: Geocoding \(toGeocode.count) zones (cached: \(zones.count))…")

        // Second pass: geocode missing zones
        for feature in toGeocode {
            let key = feature.properties.location
            let query = buildSearchQuery(from: key)

            do {
                // CLGeocoder enforces ~1 request/sec
                try await Task.sleep(nanoseconds: 1_350_000_000)
                let placemarks = try await geocoder.geocodeAddressString(query)
                if let loc = placemarks.first?.location {
                    let lat = loc.coordinate.latitude
                    let lon = loc.coordinate.longitude
                    cache[key] = [lat, lon]
                    zones.append(makeZone(from: feature, lat: lat, lon: lon))
                    allZones = zones
                    print("ASEZoneDetector: ✓ \(key)")
                } else {
                    print("ASEZoneDetector: ✗ No result for '\(key)'")
                }
            } catch {
                print("ASEZoneDetector: ✗ Error '\(key)': \(error.localizedDescription)")
            }
            geocodingProgress += 1
        }

        coordinateCache = cache
        isGeocodingComplete = true
        print("ASEZoneDetector: Done. \(allZones.count)/\(totalZones) zones active.")
    }

    // MARK: - Detection

    func checkForNearbyZones(userLocation: CLLocationCoordinate2D, currentCourse: Double = -1) {
        guard !allZones.isEmpty else { return }

        let userCLLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let hasHeading = currentCourse >= 0

        var localNearby: [ASEZone] = []
        var closestDist = Double.infinity
        var closestData: ASEZone?

        for zone in allZones {
            let zoneLoc = CLLocation(latitude: zone.coordinate.latitude, longitude: zone.coordinate.longitude)
            let dist = userCLLoc.distance(from: zoneLoc)

            if dist < 15000 { localNearby.append(zone) }

            if dist < alertDistance {
                // Direction filter — skip zones heading opposite way
                let dir = zone.direction
                if hasHeading && !dir.isEmpty && dir != "雙向" && dir != "單向" {
                    if !isDirectionMatching(userCourse: currentCourse, direction: dir) { continue }
                }
                if dist < closestDist { closestDist = dist; closestData = zone }
            }
        }

        nearbyZones = localNearby

        if let zone = closestData {
            closestZone = ASEZoneInfo(zone: zone, distance: closestDist)
            isWithinRange = true
        } else {
            closestZone = nil
            isWithinRange = false
        }
    }

    // MARK: - Private Helpers

    private func makeZone(from feature: ASERawFeature, lat: Double, lon: Double) -> ASEZone {
        let p = feature.properties
        return ASEZone(
            location: p.location,
            speedLimit: p.speed_limit,
            speedLimitValue: parseSpeedLimitValue(p.speed_limit),
            length: p.length,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            direction: parseDirection(from: p.location)
        )
    }

    private func buildSearchQuery(from location: String) -> String {
        var q = location

        // Strip km markers: "19.1K-23.1K", "47-53K", "3.94-9.92K", standalone "47K"
        let patterns = [
            #"\d+\.?\d*K-\d+\.?\d*K"#,
            #"\d+\.?\d*-\d+\.?\d*K"#,
            #"\d+\.?\d*K"#
        ]
        for pattern in patterns {
            if let re = try? NSRegularExpression(pattern: pattern) {
                let nsQ = q as NSString
                q = re.stringByReplacingMatches(in: q,
                    range: NSRange(location: 0, length: nsQ.length),
                    withTemplate: "")
            }
        }

        // Strip parenthetical directions "(雙向)", "(往南)", etc.
        if let re = try? NSRegularExpression(pattern: #"\(.*?\)"#) {
            let nsQ = q as NSString
            q = re.stringByReplacingMatches(in: q,
                range: NSRange(location: 0, length: nsQ.length),
                withTemplate: "")
        }

        q = q.components(separatedBy: .whitespaces)
             .filter { !$0.isEmpty }
             .joined(separator: " ")
             .trimmingCharacters(in: .whitespacesAndNewlines)

        return (q.isEmpty ? location : q) + " 台灣"
    }

    private func parseDirection(from location: String) -> String {
        if location.contains("雙向") { return "雙向" }
        if location.contains("往南") { return "往南" }
        if location.contains("往北") { return "往北" }
        if location.contains("往東") { return "往東" }
        if location.contains("往西") { return "往西" }
        if location.contains("單向") { return "單向" }
        return ""
    }

    private func parseSpeedLimitValue(_ str: String) -> Double {
        // "50KM" → 50; "日間60KM/夜間50KM" → 50 (stricter/lower value)
        let nums = str.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Double($0) }
            .filter { $0 > 0 && $0 < 200 }
        return nums.min() ?? 0
    }

    private func isDirectionMatching(userCourse: Double, direction: String) -> Bool {
        let target: Double
        switch direction {
        case "往北": target = 0
        case "往南": target = 180
        case "往東": target = 90
        case "往西": target = 270
        default: return true
        }
        let diff = abs(userCourse - target)
        return min(diff, 360 - diff) < 60
    }
}
