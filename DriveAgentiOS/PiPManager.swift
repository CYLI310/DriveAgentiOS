import AVKit
import UIKit
import SwiftUI
import Combine

// MARK: - PiP Data Model
struct PiPDashboardData {
    var speed: String
    var isSpeeding: Bool
    var streetName: String
    var speedingAmount: Double
    var closestTrapDistance: Double?
    var speedLimit: String?
    var tripDistance: String
    var maxSpeed: String
}

// MARK: - PiP Manager
@MainActor
final class PiPManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {

    // MARK: Public state
    @Published var isActive = false
    @Published var isSupported = false

    // MARK: Private
    private var pipController: AVPictureInPictureController?
    private var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer?

    /// Tiny UIView embedded in the window to satisfy the "layer must be in hierarchy" requirement.
    private var layerHostView: UIView?
    private var isEmbedded = false

    private var renderTimer: Timer?
    private var latestData = PiPDashboardData(
        speed: "0 km/h", isSpeeding: false,
        streetName: "", speedingAmount: 0,
        closestTrapDistance: nil, speedLimit: nil,
        tripDistance: "0 m", maxSpeed: "0 km/h"
    )

    // PiP canvas size — 16:9-ish landscape card
    private let pipSize = CGSize(width: 320, height: 160)

    override init() {
        super.init()
        isSupported = AVPictureInPictureController.isPictureInPictureSupported()
    }

    // MARK: - One-time hierarchy embedding
    private func embedLayerInHierarchyIfNeeded() -> Bool {
        guard !isEmbedded else { return true }

        // Find the key window's root view controller more robustly
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIApplication.shared.windows.first { $0.isKeyWindow }
            ?? UIApplication.shared.windows.first

        guard let rootVC = window?.rootViewController else {
            print("[PiP] Could not find root view controller")
            return false
        }

        // Create the sample-buffer layer
        let sbLayer = AVSampleBufferDisplayLayer()
        sbLayer.videoGravity = .resizeAspect
        sbLayer.backgroundColor = UIColor.black.cgColor
        sbLayer.frame = CGRect(origin: .zero, size: pipSize)
        
        // CRITICAL for Auto-PiP: Set a timebase and set its rate to 1.0 (playing)
        var timebase: CMTimebase?
        CMTimebaseCreateWithMasterClock(allocator: kCFAllocatorDefault, masterClock: CMClockGetHostTimeClock(), timebaseOut: &timebase)
        if let tb = timebase {
            sbLayer.controlTimebase = tb
            CMTimebaseSetTime(tb, time: .zero)
            CMTimebaseSetRate(tb, rate: 1.0)
        }
        
        sampleBufferDisplayLayer = sbLayer

        // Embed a minimal host view — must NOT be hidden, but can be tiny/transparent
        let host = UIView(frame: CGRect(x: -2, y: -2, width: 2, height: 2))
        host.alpha = 0.1 // Tiny but sufficiently visible for the OS
        host.clipsToBounds = true
        host.isUserInteractionEnabled = false
        host.layer.addSublayer(sbLayer)
        rootVC.view.addSubview(host)
        layerHostView = host

        // Build the PiP controller
        let source = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sbLayer,
            playbackDelegate: self
        )
        let ctrl = AVPictureInPictureController(contentSource: source)
        ctrl.delegate = self
        
        // ENABLE Automatic start on background
        ctrl.canStartPictureInPictureAutomaticallyFromInline = true
        
        pipController = ctrl

        isEmbedded = true
        print("[PiP] Layer embedded in hierarchy and auto-PiP enabled ✓")
        return true
    }

    // MARK: - Public API
    func update(data: PiPDashboardData) {
        latestData = data
    }

    /// Pre-embeds the layer and starts rendering so the OS sees "active media" 
    /// which allows the automatic transition to PiP when the app is backgrounded.
    func prepare() {
        guard isSupported else { return }
        
        // Ensure audio session is active as it's often required for PiP
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
        try? session.setActive(true)
        
        if embedLayerInHierarchyIfNeeded() {
            startRenderLoop()
        }
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
        stopRenderLoop()
    }

    // MARK: - Render loop
    private func startRenderLoop() {
        stopRenderLoop()
        
        // Push initial frames immediately to warm up the layer
        pushFrame()
        pushFrame()
        
        // 5 fps for smoother updates (iOS/iPadOS PiP handles this easily)
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.pushFrame() }
        }
    }

    private func stopRenderLoop() {
        renderTimer?.invalidate()
        renderTimer = nil
    }

    private func pushFrame() {
        guard let layer = sampleBufferDisplayLayer else { return }
        
        // On iPad/iOS, if the layer is not ready, we should still try to push 
        // the very first frame to get it ready.
        let image = renderDashboard(data: latestData, size: pipSize)
        guard let pixelBuffer = image.toPixelBuffer(size: pipSize) else { return }
        
        let currentTime = layer.controlTimebase != nil 
            ? CMTimebaseGetTime(layer.controlTimebase!) 
            : CMClockGetTime(CMClockGetHostTimeClock())
            
        guard let sampleBuffer = pixelBuffer.toSampleBuffer(at: currentTime) else { return }
        
        if layer.status == .failed { 
            print("[PiP] Layer failed, flushing...")
            layer.flush() 
        }
        
        layer.enqueue(sampleBuffer)
    }

    // MARK: - Dashboard Rendering (UIGraphicsImageRenderer → UIImage)
    private func renderDashboard(data: PiPDashboardData, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let bounds = CGRect(origin: .zero, size: size)

            // Dark gradient background
            let bgColors = [
                UIColor(red: 0.05, green: 0.05, blue: 0.12, alpha: 1).cgColor,
                UIColor(red: 0.08, green: 0.08, blue: 0.20, alpha: 1).cgColor
            ]
            let bgGrad = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: bgColors as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                bgGrad, start: .zero,
                end: CGPoint(x: 0, y: size.height), options: []
            )

            // Rounded clip
            let clipPath = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 12)
            ctx.cgContext.addPath(clipPath.cgPath)
            ctx.cgContext.clip()

            // Red speeding overlay
            if data.isSpeeding {
                UIColor.red.withAlphaComponent(0.12).setFill()
                UIRectFill(bounds)
            }

            // ── Speed number ──
            let speedStr = data.speed.components(separatedBy: " ").first ?? data.speed
            let unitStr  = data.speed.components(separatedBy: " ").dropFirst().joined(separator: " ")
            let speedColor: UIColor = data.isSpeeding ? .systemRed : .white

            let speedAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 54, weight: .bold),
                .foregroundColor: speedColor
            ]
            let unitAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.65)
            ]

            let speedSz = (speedStr as NSString).size(withAttributes: speedAttrs)
            let speedPt = CGPoint(x: 14, y: (size.height - speedSz.height) / 2 - 6)
            (speedStr as NSString).draw(at: speedPt, withAttributes: speedAttrs)
            (unitStr  as NSString).draw(
                at: CGPoint(x: 14, y: speedPt.y + speedSz.height + 2),
                withAttributes: unitAttrs
            )

            // ── Divider ──
            let divX: CGFloat = 128
            ctx.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            ctx.cgContext.setLineWidth(1)
            ctx.cgContext.move(to: CGPoint(x: divX, y: 14))
            ctx.cgContext.addLine(to: CGPoint(x: divX, y: size.height - 14))
            ctx.cgContext.strokePath()

            // ── Right panel ──
            let rx: CGFloat = divX + 10
            let rw: CGFloat = size.width - rx - 10
            var ry: CGFloat = 12

            // Street name
            if !data.streetName.isEmpty && data.streetName != "Finding your location..." {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.88)
                ]
                let rect = CGRect(x: rx, y: ry, width: rw, height: 30)
                (data.streetName as NSString).draw(
                    with: rect,
                    options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
                    attributes: attrs, context: nil
                )
                ry += 32
            }

            // Speed-camera row
            if let dist = data.closestTrapDistance, let limit = data.speedLimit {
                let label = dist < 1000
                    ? "\(Int(dist)) m"
                    : String(format: "%.1f km", dist / 1000)
                let camColor: UIColor = data.isSpeeding ? .systemRed : .systemOrange
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                    .foregroundColor: camColor
                ]
                ("📷 \(label)  Limit: \(limit)" as NSString).draw(
                    at: CGPoint(x: rx, y: ry), withAttributes: attrs
                )
                ry += 18
            }

            // Trip / max speed footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.45)
            ]
            ("Trip: \(data.tripDistance)  Max: \(data.maxSpeed)" as NSString).draw(
                at: CGPoint(x: rx, y: size.height - 22), withAttributes: footerAttrs
            )

            // Over-limit badge
            if data.isSpeeding && data.speedingAmount > 0 {
                let badge = "+\(Int(data.speedingAmount)) km/h"
                let badgeAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                    .foregroundColor: UIColor.systemRed
                ]
                let bsz = (badge as NSString).size(withAttributes: badgeAttrs)
                let brect = CGRect(
                    x: size.width - bsz.width - 16,
                    y: 12,
                    width: bsz.width + 8,
                    height: bsz.height + 4
                )
                UIColor.systemRed.withAlphaComponent(0.15).setFill()
                UIBezierPath(roundedRect: brect, cornerRadius: 5).fill()
                (badge as NSString).draw(
                    at: CGPoint(x: brect.origin.x + 4, y: brect.origin.y + 2),
                    withAttributes: badgeAttrs
                )
            }
        }
    }

    // MARK: - Delegate
    nonisolated func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) { Task { @MainActor in self.isActive = true } }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) { Task { @MainActor in self.isActive = true } }

    nonisolated func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) { Task { @MainActor [weak self] in 
        // We keep the render loop going so it can restart if needed, 
        // unless the user specifically disabled it.
    } }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) { Task { @MainActor in self.isActive = false } }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor in
            self.isActive = false
            print("[PiP] Failed to start: \(error.localizedDescription)")
        }
    }
}

// MARK: - Playback delegate (hides play/pause controls)
extension PiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool) {}

    nonisolated func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    nonisolated func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool { false }

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    nonisolated func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) { completionHandler() }
}

// MARK: - UIImage → CVPixelBuffer
private extension UIImage {
    func toPixelBuffer(size: CGSize) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        var pb: CVPixelBuffer?
        guard CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width), Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pb
        ) == kCVReturnSuccess, let buffer = pb else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width), height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue |
                        CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(ctx)
        draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        return buffer
    }
}

// MARK: - CVPixelBuffer → CMSampleBuffer
private extension CVPixelBuffer {
    func toSampleBuffer(at time: CMTime) -> CMSampleBuffer? {
        var fmt: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
            formatDescriptionOut: &fmt
        )
        guard let desc = fmt else { return nil }

        var timing = CMSampleTimingInfo(
            duration:               CMTime(value: 1, timescale: 5), // 0.2s
            presentationTimeStamp:  time,
            decodeTimeStamp:        .invalid
        )
        var sb: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator:              kCFAllocatorDefault,
            imageBuffer:            self,
            dataReady:              true,
            makeDataReadyCallback:  nil,
            refcon:                 nil,
            formatDescription:      desc,
            sampleTiming:           &timing,
            sampleBufferOut:        &sb
        )
        guard let out = sb else { return nil }

        // Tag as display-immediately so the layer shows it right away
        if let arr = CMSampleBufferGetSampleAttachmentsArray(out, createIfNecessary: true) {
            let dict = unsafeBitCast(
                CFArrayGetValueAtIndex(arr, 0), to: CFMutableDictionary.self
            )
            CFDictionarySetValue(
                dict,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }
        return out
    }
}
