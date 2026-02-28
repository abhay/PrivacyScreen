import ARKit
import Combine
import CoreMotion
import SwiftUI

// MARK: - PowerState

/// Power management states controlling ARKit and accelerometer duty cycling.
public enum PowerState: String, CaseIterable, Sendable {
    case dormant // ~5mW:  accel 5Hz, ARKit OFF
    case idle // ~30mW: accel 15Hz, ARKit samples 0.5s every 3s
    case active // ~180mW: accel 30Hz, ARKit continuous 60fps
    case alert // ~180mW: same as active, locked until threat clears + 5s cooldown

    /// Estimated power consumption in milliwatts.
    public var estimatedPowerMW: Int {
        switch self {
        case .dormant: 5
        case .idle: 30
        case .active: 180
        case .alert: 180
        }
    }

    /// Accelerometer update frequency for this state.
    public var motionHz: Double {
        switch self {
        case .dormant: 5
        case .idle: 15
        case .active: 30
        case .alert: 30
        }
    }
}

// MARK: - PowerThrottlerConfig

/// Tunable parameters for the power state machine.
public struct PowerThrottlerConfig: Sendable {
    /// Acceleration magnitude threshold to detect phone pickup (m/s^2).
    public var pickupThreshold: Double = 0.15
    /// Acceleration magnitude below which the device is considered still (m/s^2).
    public var stillThreshold: Double = 0.05
    /// Seconds of stillness before ACTIVE → IDLE.
    public var activeToIdleTimeout: TimeInterval = 8
    /// Seconds of stillness before IDLE → DORMANT.
    public var idleToDormantTimeout: TimeInterval = 30
    /// Seconds of cooldown after threat clears before ALERT → ACTIVE.
    public var alertCooldown: TimeInterval = 5
    /// Duration of ARKit sampling burst in IDLE mode (seconds).
    public var idleSampleDuration: TimeInterval = 0.5
    /// Interval between ARKit sampling bursts in IDLE mode (seconds).
    public var idleSampleInterval: TimeInterval = 3

    public init() {}
}

// MARK: - PowerThrottler

/// Battery-aware lifecycle manager that duty-cycles ARKit and adjusts accelerometer frequency.
///
/// Owns the single `CMMotionManager` instance for the app and forwards motion data
/// to `PrivacyManager`. iOS only allows one `CMMotionManager` per app — creating
/// multiple instances will crash.
@MainActor
public final class PowerThrottler: ObservableObject {

    // MARK: - Published State

    /// Current power management state.
    @Published public private(set) var powerState: PowerState = .dormant

    /// Current ARKit mode description.
    @Published public private(set) var arKitMode: String = "OFF"

    /// Current duty cycle percentage (0-100).
    @Published public private(set) var dutyCycle: Double = 0

    /// Current acceleration magnitude.
    @Published public private(set) var accelerationMagnitude: Double = 0

    /// Time since last significant motion.
    @Published public private(set) var timeSinceMotion: TimeInterval = 0

    // MARK: - Configuration

    /// Tunable power management parameters.
    public var config: PowerThrottlerConfig = .init()

    // MARK: - Private State

    private let motionManager = CMMotionManager()
    private weak var privacyManager: PrivacyManager?
    private weak var arSession: ARSession?

    private var threatCancellable: AnyCancellable?
    private var lastMotionTime: Date = .init()
    private var lastSignificantMotionTime: Date = .init()
    private var stillnessTimer: Timer?
    private var idleSamplingTimer: Timer?
    private var alertCooldownTimer: Timer?
    private var isRunning: Bool = false
    private var arKitRunning: Bool = false

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Attach to a PrivacyManager and its AR session.
    ///
    /// Must be called after both objects are initialized. The throttler will
    /// forward all motion data to the manager and control its AR session lifecycle.
    public func attach(to manager: PrivacyManager, arSession: ARSession) {
        privacyManager = manager
        self.arSession = arSession

        // Observe threat level changes
        threatCancellable = manager.$threatLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                guard let self else { return }
                Task { @MainActor in
                    self.handleThreatLevelChange(level)
                }
            }
    }

    /// Start the power management system.
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        transitionTo(.dormant)
    }

    /// Stop the power management system.
    public func stop() {
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
        stopIdleSampling()
        stillnessTimer?.invalidate()
        stillnessTimer = nil
        alertCooldownTimer?.invalidate()
        alertCooldownTimer = nil
        arKitMode = "OFF"
        arKitRunning = false
    }

    // MARK: - Private: State Transitions

    private func transitionTo(_ newState: PowerState) {
        let oldState = powerState
        if newState == oldState, isRunning {
            return
        }

        powerState = newState

        // Clean up old state timers
        stillnessTimer?.invalidate()
        stillnessTimer = nil
        stopIdleSampling()
        alertCooldownTimer?.invalidate()
        alertCooldownTimer = nil

        // Configure new state
        switch newState {
        case .dormant:
            configureMotion(hz: config.pickupThreshold > 0 ? 5 : 5)
            pauseARKit()
            arKitMode = "OFF"
            dutyCycle = 0

        case .idle:
            configureMotion(hz: 15)
            startIdleSampling()
            arKitMode = "SAMPLING"
            dutyCycle = (config.idleSampleDuration / config.idleSampleInterval) * 100
            startStillnessTimer(timeout: config.idleToDormantTimeout, target: .dormant)

        case .active:
            configureMotion(hz: 30)
            resumeARKit()
            arKitMode = "ON"
            dutyCycle = 100
            startStillnessTimer(timeout: config.activeToIdleTimeout, target: .idle)

        case .alert:
            configureMotion(hz: 30)
            resumeARKit()
            arKitMode = "ON"
            dutyCycle = 100
        }
    }

    // MARK: - Private: Motion Management

    private func configureMotion(hz: Double) {
        motionManager.stopDeviceMotionUpdates()
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            Task { @MainActor in
                self.processMotionUpdate(motion)
            }
        }
    }

    private func processMotionUpdate(_ motion: CMDeviceMotion) {
        guard isRunning else { return }

        let accel = motion.userAcceleration
        let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
        accelerationMagnitude = magnitude
        lastMotionTime = Date()
        timeSinceMotion = lastMotionTime.timeIntervalSince(lastSignificantMotionTime)

        // Forward to privacy manager
        privacyManager?.processMotionFromThrottler(motion)

        // State-specific motion handling
        switch powerState {
        case .dormant:
            if magnitude > config.pickupThreshold {
                lastSignificantMotionTime = Date()
                transitionTo(.active)
            }

        case .idle:
            if magnitude > config.pickupThreshold {
                lastSignificantMotionTime = Date()
                transitionTo(.active)
            }

        case .active:
            if magnitude > config.stillThreshold {
                lastSignificantMotionTime = Date()
                timeSinceMotion = 0
                // Reset stillness timer
                startStillnessTimer(timeout: config.activeToIdleTimeout, target: .idle)
            }

        case .alert:
            if magnitude > config.stillThreshold {
                lastSignificantMotionTime = Date()
                timeSinceMotion = 0
            }
        }
    }

    // MARK: - Private: Threat Level Handling

    private func handleThreatLevelChange(_ level: ThreatLevel) {
        guard isRunning else { return }

        if level >= .threatened, powerState != .alert {
            transitionTo(.alert)
        } else if level < .threatened, powerState == .alert {
            // Start cooldown before transitioning out of alert
            alertCooldownTimer?.invalidate()
            alertCooldownTimer = Timer
                .scheduledTimer(withTimeInterval: config.alertCooldown, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    Task { @MainActor in
                        // Only transition if still in alert and threat has cleared
                        if self.powerState == .alert,
                           let manager = self.privacyManager,
                           manager.threatLevel < .threatened
                        {
                            self.transitionTo(.active)
                        }
                    }
                }
        }
    }

    // MARK: - Private: ARKit Control

    private func resumeARKit() {
        guard !arKitRunning else { return }
        privacyManager?.resumeARKit()
        arKitRunning = true
    }

    private func pauseARKit() {
        guard arKitRunning else { return }
        privacyManager?.pauseARKit()
        arKitRunning = false
    }

    // MARK: - Private: Idle Sampling

    private func startIdleSampling() {
        stopIdleSampling()
        performIdleSample()
        idleSamplingTimer = Timer.scheduledTimer(
            withTimeInterval: config.idleSampleInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.performIdleSample()
            }
        }
    }

    private func performIdleSample() {
        resumeARKit()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(config.idleSampleDuration))
            if self.powerState == .idle {
                self.pauseARKit()
            }
        }
    }

    private func stopIdleSampling() {
        idleSamplingTimer?.invalidate()
        idleSamplingTimer = nil
    }

    // MARK: - Private: Stillness Timer

    private func startStillnessTimer(timeout: TimeInterval, target: PowerState) {
        stillnessTimer?.invalidate()
        stillnessTimer = Timer.scheduledTimer(
            withTimeInterval: timeout,
            repeats: false
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.transitionTo(target)
            }
        }
    }
}
