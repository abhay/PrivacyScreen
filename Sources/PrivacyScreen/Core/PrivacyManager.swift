import ARKit
import Combine
import CoreMotion
import SwiftUI

// MARK: - Configuration

/// Tunable parameters for threat detection.
public struct PrivacyManagerConfig: Sendable {
    /// Gaze deviation threshold for +1 score (radians).
    public var gazeThresholdLow: Float = 0.3
    /// Gaze deviation threshold for +2 score (radians).
    public var gazeThresholdHigh: Float = 0.5
    /// Tilt angle threshold for +1 score (degrees).
    public var tiltThresholdLow: Float = 25
    /// Tilt angle threshold for +2 score (degrees).
    public var tiltThresholdHigh: Float = 40
    /// Tilt rate threshold for instant lock (degrees/second).
    public var tiltRateThreshold: Float = 120
    /// Number of frames in the de-escalation smoothing window.
    public var smoothingWindowSize: Int = 8

    public init() {}
}

// MARK: - PrivacyManager

/// Central threat detection engine that fuses ARKit face tracking with accelerometer data.
///
/// Publishes the current `threatLevel` for use by view modifiers and overlays.
/// Supports two modes:
/// - Standalone: manages its own `CMMotionManager` internally
/// - External motion: receives forwarded motion data from `PowerThrottler`
@MainActor
public final class PrivacyManager: NSObject, ObservableObject {

    // MARK: - Published State

    /// Current aggregated threat level after temporal smoothing.
    @Published public private(set) var threatLevel: ThreatLevel = .clear

    /// Current raw threat state (useful for debug display).
    @Published public private(set) var currentState: ThreatState = .initial

    /// Whether to show the debug overlay.
    @Published public var showDebugOverlay: Bool = false

    /// Whether privacy monitoring is enabled.
    @Published public var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                threatLevel = .clear
                currentState = .initial
            }
        }
    }

    /// Debug info string for the debug overlay.
    @Published public private(set) var debugInfo: PrivacyDebugInfo = .initial

    // MARK: - Configuration

    /// Tunable detection parameters.
    public var config: PrivacyManagerConfig = .init()

    // MARK: - ARKit

    /// The AR session used for face tracking. Exposed so PowerThrottler can pause/resume it.
    public let arSession = ARSession()

    /// Whether ARKit face tracking is supported on this device.
    public var isFaceTrackingSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    // MARK: - Private State

    private var internalMotionManager: CMMotionManager?
    private var useExternalMotion: Bool = false
    private var isMonitoring: Bool = false

    /// Smoothing window: stores recent raw threat levels for de-escalation logic.
    private var threatWindow: [ThreatLevel] = []

    /// Face count from latest ARKit update.
    private var faceCount: Int = 0
    /// Gaze deviation from latest ARKit update.
    private var gazeDeviation: Float = 0
    /// Whether the primary face was lost.
    private var faceLost: Bool = true

    // MARK: - Initialization

    override public init() {
        super.init()
        arSession.delegate = self
    }

    // MARK: - Public API

    /// Start privacy monitoring.
    ///
    /// - Parameter externalMotion: If `true`, motion data will be supplied externally via
    ///   `processMotionFromThrottler(_:)`. If `false`, an internal `CMMotionManager` is created.
    public func startMonitoring(externalMotion: Bool = false) {
        guard !isMonitoring else { return }
        isMonitoring = true
        useExternalMotion = externalMotion

        // Start ARKit if supported
        if isFaceTrackingSupported {
            startARKit()
        } else {
            faceLost = false // Don't penalize for no face tracking support
        }

        // Start internal motion if not using external
        if !externalMotion {
            startInternalMotion()
        }
    }

    /// Stop all monitoring and reset state.
    public func stopMonitoring() {
        isMonitoring = false
        arSession.pause()
        stopInternalMotion()
        threatLevel = .clear
        currentState = .initial
        threatWindow.removeAll()
    }

    /// Receive forwarded motion data from PowerThrottler.
    ///
    /// - Parameter motion: The device motion data from CMMotionManager.
    public func processMotionFromThrottler(_ motion: CMDeviceMotion) {
        guard isMonitoring, isEnabled else { return }
        processMotion(motion)
    }

    /// Resume ARKit session (called by PowerThrottler during duty cycling).
    public func resumeARKit() {
        guard isFaceTrackingSupported else { return }
        startARKit()
    }

    /// Pause ARKit session (called by PowerThrottler during duty cycling).
    public func pauseARKit() {
        arSession.pause()
        // When ARKit is paused, don't count face as lost (preserves last known state)
    }

    // MARK: - Simulate Threat (for testing)

    /// Set an arbitrary threat level with animation. Useful for demos, previews, and testing.
    public func simulateThreatLevel(_ level: ThreatLevel) {
        withAnimation(.easeInOut(duration: 0.3)) {
            threatLevel = level
        }
    }

    /// Manually trigger a locked state for testing purposes.
    public func simulateThreat(duration: TimeInterval = 3.0) {
        let previousEnabled = isEnabled
        withAnimation(.easeInOut(duration: 0.2)) {
            threatLevel = .locked
        }
        currentState = ThreatState(secondFaceDetected: true)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            currentState = .initial
            withAnimation(.easeInOut(duration: 0.2)) {
                threatLevel = .clear
            }
            isEnabled = previousEnabled
        }
    }

    // MARK: - Private: ARKit

    private func startARKit() {
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        arSession.run(configuration, options: [])
    }

    // MARK: - Private: Internal Motion

    private func startInternalMotion() {
        let manager = CMMotionManager()
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            Task { @MainActor in
                self.processMotion(motion)
            }
        }
        internalMotionManager = manager
    }

    private func stopInternalMotion() {
        internalMotionManager?.stopDeviceMotionUpdates()
        internalMotionManager = nil
    }

    // MARK: - Private: Motion Processing

    private func processMotion(_ motion: CMDeviceMotion) {
        let attitude = motion.attitude
        let tiltAngle = Float(attitude.roll * 180.0 / .pi)
        let rotationRate = motion.rotationRate
        let tiltRate = Float(sqrt(
            rotationRate.x * rotationRate.x +
                rotationRate.y * rotationRate.y +
                rotationRate.z * rotationRate.z
        ) * 180.0 / .pi)

        updateThreatState(tiltAngle: tiltAngle, tiltRate: tiltRate)
    }

    // MARK: - Private: Face Processing

    fileprivate func processFaceAnchors(_ anchors: [ARFaceAnchor]) {
        guard isEnabled else { return }

        // Sort by distance from camera (closest first = primary user)
        let sorted = anchors.sorted { a, b in
            let distA = simd_length(a.transform.columns.3)
            let distB = simd_length(b.transform.columns.3)
            return distA < distB
        }

        faceCount = sorted.count

        if let primary = sorted.first {
            faceLost = !primary.isTracked
            // lookAtPoint is a 3D point the user is looking at relative to the face
            let lookAt = primary.lookAtPoint
            gazeDeviation = sqrt(lookAt.x * lookAt.x + lookAt.y * lookAt.y)
        } else {
            faceLost = true
            gazeDeviation = 0
        }

        // Trigger state update with current motion values
        updateThreatState(tiltAngle: currentState.deviceTiltAngle, tiltRate: currentState.deviceTiltRate)
    }

    // MARK: - Private: Threat State Update

    private func updateThreatState(tiltAngle: Float, tiltRate: Float) {
        let state = ThreatState(
            secondFaceDetected: faceCount > 1,
            primaryGazeDeviation: gazeDeviation,
            primaryFaceLost: faceLost && isFaceTrackingSupported,
            deviceTiltAngle: tiltAngle,
            deviceTiltRate: tiltRate
        )

        currentState = state

        let rawThreat = state.aggregatedThreat

        // Update debug info
        debugInfo = PrivacyDebugInfo(
            faceCount: faceCount,
            gazeDeviation: gazeDeviation,
            tiltAngle: tiltAngle,
            tiltRate: tiltRate,
            rawThreatLevel: rawThreat,
            smoothedThreatLevel: threatLevel
        )

        // Temporal smoothing
        threatWindow.append(rawThreat)
        if threatWindow.count > config.smoothingWindowSize {
            threatWindow.removeFirst(threatWindow.count - config.smoothingWindowSize)
        }

        let newLevel: ThreatLevel
        if rawThreat > threatLevel {
            // Escalation: immediate (within 1-2 frames)
            newLevel = rawThreat
        } else if rawThreat < threatLevel {
            // De-escalation: only when ALL frames in window are lower
            let allLower = threatWindow.allSatisfy { $0 < threatLevel }
            if allLower {
                // Step down one level at a time
                let targetRaw = threatWindow.max() ?? .clear
                newLevel = targetRaw
            } else {
                newLevel = threatLevel
            }
        } else {
            newLevel = threatLevel
        }

        if newLevel != threatLevel {
            withAnimation(.easeInOut(duration: 0.2)) {
                threatLevel = newLevel
            }
            debugInfo.smoothedThreatLevel = newLevel
        }
    }
}

// MARK: - ARSessionDelegate

extension PrivacyManager: ARSessionDelegate {
    public nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        guard !faceAnchors.isEmpty else { return }
        Task { @MainActor in
            self.processFaceAnchors(faceAnchors)
        }
    }
}

// MARK: - PrivacyDebugInfo

/// Debug information published by PrivacyManager for the debug overlay.
public struct PrivacyDebugInfo: Sendable {
    public var faceCount: Int
    public var gazeDeviation: Float
    public var tiltAngle: Float
    public var tiltRate: Float
    public var rawThreatLevel: ThreatLevel
    public var smoothedThreatLevel: ThreatLevel

    public static let initial = PrivacyDebugInfo(
        faceCount: 0,
        gazeDeviation: 0,
        tiltAngle: 0,
        tiltRate: 0,
        rawThreatLevel: .clear,
        smoothedThreatLevel: .clear
    )
}
