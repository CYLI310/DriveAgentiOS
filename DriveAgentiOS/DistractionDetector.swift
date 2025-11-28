import Foundation
import ARKit
import Combine

class DistractionDetector: NSObject, ObservableObject, ARSessionDelegate {
    @Published var isDistracted: Bool = false
    @Published var isLookingAtScreen: Bool = false
    @Published var isSupported: Bool = false
    
    private var session: ARSession?
    private var currentSpeed: Double = 0.0
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled && isSupported {
                startSession()
            } else {
                stopSession()
            }
        }
    }
    
    // Thresholds
    private let speedThreshold: Double = 19.44 // 70 km/h in m/s
    private let distractionTimeThreshold: TimeInterval = 1.5 // Seconds to trigger alert
    private var distractionStartTime: Date?
    
    override init() {
        super.init()
        self.isSupported = ARFaceTrackingConfiguration.isSupported
        if isSupported {
            session = ARSession()
            session?.delegate = self
        }
    }
    

    
    func updateSpeed(speedMps: Double) {
        self.currentSpeed = speedMps
        checkDistraction()
    }
    
    private func startSession() {
        guard let session = session else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        // We don't need the camera feed, but ARSession usually runs with it.
        // Since we are not displaying an ARView, we just run the session.
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func stopSession() {
        session?.pause()
        DispatchQueue.main.async {
            self.isDistracted = false
            self.isLookingAtScreen = false
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        
        // Calculate gaze relative to screen (camera)
        // faceAnchor.transform is the face position in camera space.
        // faceAnchor.lookAtPoint is the gaze target in face space.
        
        let transform = faceAnchor.transform
        let lookAtPoint = faceAnchor.lookAtPoint
        
        // Convert lookAtPoint to a SIMD4 (homogeneous coordinates)
        let lookAtPointHomogeneous = simd_float4(lookAtPoint.x, lookAtPoint.y, lookAtPoint.z, 1)
        
        // Transform to world space (camera space)
        let worldLookAtPoint = simd_mul(transform, lookAtPointHomogeneous)
        
        // The camera is at (0,0,0) in world space.
        // We check if the gaze point is close to the camera.
        // We can check the distance or just the X/Y offset at Z=0.
        
        // Actually, `lookAtPoint` is where the eyes are converging.
        // If looking at the screen, the point should be near (0,0,0).
        
        let distanceToCamera = sqrt(pow(worldLookAtPoint.x, 2) + pow(worldLookAtPoint.y, 2) + pow(worldLookAtPoint.z, 2))
        
        // Threshold: 0.2 meters (20cm) radius around the camera
        let isLooking = distanceToCamera < 0.2
        
        DispatchQueue.main.async {
            self.isLookingAtScreen = isLooking
            self.checkDistraction()
        }
    }
    
    private func checkDistraction() {
        // Only trigger if enabled, speeding, and looking at screen
        if isEnabled && currentSpeed > speedThreshold && isLookingAtScreen {
            if distractionStartTime == nil {
                distractionStartTime = Date()
            } else if let startTime = distractionStartTime, Date().timeIntervalSince(startTime) > distractionTimeThreshold {
                isDistracted = true
            }
        } else {
            // Reset if condition fails
            distractionStartTime = nil
            isDistracted = false
        }
    }
}
