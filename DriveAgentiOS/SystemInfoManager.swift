import Foundation
import UIKit
import Network
import Combine

class SystemInfoManager: ObservableObject {
    @Published var batteryLevel: Float = 0.0
    @Published var networkStatusSymbol: String = "network.slash"

    private let monitor = NWPathMonitor()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Battery Monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.batteryLevel = UIDevice.current.batteryLevel

        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.batteryLevel = UIDevice.current.batteryLevel
            }
            .store(in: &cancellables)

        // Network Monitoring
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self?.networkStatusSymbol = "wifi"
                    } else if path.usesInterfaceType(.cellular) {
                        self?.networkStatusSymbol = "antenna.radiowaves.left.and.right"
                    } else {
                        self?.networkStatusSymbol = "network"
                    }
                } else {
                    self?.networkStatusSymbol = "network.slash"
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
