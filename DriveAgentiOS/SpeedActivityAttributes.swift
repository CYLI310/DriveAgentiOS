import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct SpeedActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data that updates over time
        var speed: String
    }

    // Static data (not needed for this simple case)
}
