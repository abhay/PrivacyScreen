import Foundation

// MARK: - ThreatLevel

/// Represents the current privacy threat level, ordered from lowest to highest.
public enum ThreatLevel: Int, Comparable, CaseIterable, Sendable {
    case clear = 0
    case cautious = 1
    case threatened = 2
    case locked = 3

    public static func < (lhs: ThreatLevel, rhs: ThreatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - ThreatState

/// Pure value type representing all sensor inputs and computed threat level.
///
/// This is the core scoring engine — no side effects, no dependencies, fully testable.
public struct ThreatState: Sendable {

    // MARK: - Sensor Inputs

    /// Whether a second face has been detected by ARKit.
    public var secondFaceDetected: Bool

    /// Primary user's gaze deviation in radians off-center.
    public var primaryGazeDeviation: Float

    /// Whether the primary user's face has been lost from tracking.
    public var primaryFaceLost: Bool

    /// Device lateral roll angle in degrees.
    public var deviceTiltAngle: Float

    /// Device rotation rate magnitude in degrees per second.
    public var deviceTiltRate: Float

    // MARK: - Initialization

    public init(
        secondFaceDetected: Bool = false,
        primaryGazeDeviation: Float = 0,
        primaryFaceLost: Bool = false,
        deviceTiltAngle: Float = 0,
        deviceTiltRate: Float = 0
    ) {
        self.secondFaceDetected = secondFaceDetected
        self.primaryGazeDeviation = primaryGazeDeviation
        self.primaryFaceLost = primaryFaceLost
        self.deviceTiltAngle = deviceTiltAngle
        self.deviceTiltRate = deviceTiltRate
    }

    // MARK: - Threat Aggregation

    /// Computed threat level based on scoring rules.
    ///
    /// Instant lock triggers:
    /// - Second face detected → `.locked`
    /// - Tilt rate > 120°/s (snatch detection) → `.locked`
    ///
    /// Score-based:
    /// - `primaryFaceLost` → +2
    /// - `primaryGazeDeviation > 0.3 rad` → +1, `> 0.5 rad` → +2
    /// - `abs(deviceTiltAngle) > 25°` → +1, `> 40°` → +2
    /// - Score 0 = `.clear`, 1 = `.cautious`, 2 = `.threatened`, 3+ = `.locked`
    public var aggregatedThreat: ThreatLevel {
        // Instant lock triggers
        if secondFaceDetected { return .locked }
        if deviceTiltRate > 120 { return .locked }

        // Score accumulation
        var score = 0

        if primaryFaceLost {
            score += 2
        }

        let absGaze = abs(primaryGazeDeviation)
        if absGaze > 0.5 {
            score += 2
        } else if absGaze > 0.3 {
            score += 1
        }

        let absTilt = abs(deviceTiltAngle)
        if absTilt > 40 {
            score += 2
        } else if absTilt > 25 {
            score += 1
        }

        switch score {
        case 0: return .clear
        case 1: return .cautious
        case 2: return .threatened
        default: return .locked
        }
    }

    /// Returns a zeroed-out default state.
    public static let initial = ThreatState()
}
