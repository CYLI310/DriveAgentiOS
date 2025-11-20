import Foundation
import ActivityKit
import Combine

@MainActor
class LiveActivityManager {
    private var currentActivity: Activity<SpeedActivityAttributes>?
    private var speedSubscription: AnyCancellable?
    
    private let locationManager: LocationManager

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
    
    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, currentActivity == nil else { return }

        let attributes = SpeedActivityAttributes()
        let state = SpeedActivityAttributes.ContentState(speed: locationManager.currentSpeed)

        do {
            let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            self.currentActivity = activity
            print("Live Activity started with ID: \(activity.id)")
            
            // Subscribe to speed updates
            speedSubscription = locationManager.$currentSpeed.sink { [weak self] newSpeed in
                self?.update(with: newSpeed)
            }
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    private func update(with speed: String) {
        Task {
            let state = SpeedActivityAttributes.ContentState(speed: speed)
            await currentActivity?.update(using: state)
        }
    }
    
    func stop() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
            speedSubscription?.cancel()
            speedSubscription = nil
            print("Live Activity stopped.")
        }
    }
}
