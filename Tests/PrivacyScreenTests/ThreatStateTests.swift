import Testing
@testable import PrivacyScreen

// MARK: - ThreatState Tests

@Suite("ThreatState Aggregation")
struct ThreatStateTests {

    // MARK: - Default State

    @Test("Default state is clear")
    func defaultState() {
        let state = ThreatState()
        #expect(state.aggregatedThreat == .clear)
    }

    // MARK: - Instant Lock Triggers

    @Test("Second face detected triggers instant lock")
    func secondFaceDetected() {
        let state = ThreatState(secondFaceDetected: true)
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("Second face overrides all other signals")
    func secondFaceOverridesAll() {
        let state = ThreatState(
            secondFaceDetected: true,
            primaryGazeDeviation: 0,
            primaryFaceLost: false,
            deviceTiltAngle: 0,
            deviceTiltRate: 0
        )
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("High tilt rate triggers instant lock (snatch detection)")
    func highTiltRate() {
        let state = ThreatState(deviceTiltRate: 121)
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("Tilt rate at exactly 120 does not lock")
    func tiltRateAtBoundary() {
        let state = ThreatState(deviceTiltRate: 120)
        #expect(state.aggregatedThreat == .clear)
    }

    @Test("Tilt rate just above 120 locks")
    func tiltRateAboveBoundary() {
        let state = ThreatState(deviceTiltRate: 120.1)
        #expect(state.aggregatedThreat == .locked)
    }

    // MARK: - Individual Score Signals

    @Test("Primary face lost adds 2 to score → threatened")
    func primaryFaceLost() {
        let state = ThreatState(primaryFaceLost: true)
        #expect(state.aggregatedThreat == .threatened)
    }

    @Test("Moderate gaze deviation (>0.3 rad) adds 1 → cautious")
    func moderateGazeDeviation() {
        let state = ThreatState(primaryGazeDeviation: 0.35)
        #expect(state.aggregatedThreat == .cautious)
    }

    @Test("High gaze deviation (>0.5 rad) adds 2 → threatened")
    func highGazeDeviation() {
        let state = ThreatState(primaryGazeDeviation: 0.55)
        #expect(state.aggregatedThreat == .threatened)
    }

    @Test("Gaze at exactly 0.3 does not trigger")
    func gazeAtLowBoundary() {
        let state = ThreatState(primaryGazeDeviation: 0.3)
        #expect(state.aggregatedThreat == .clear)
    }

    @Test("Gaze at exactly 0.5 does not add +2 (only +1)")
    func gazeAtHighBoundary() {
        let state = ThreatState(primaryGazeDeviation: 0.5)
        #expect(state.aggregatedThreat == .cautious)
    }

    @Test("Moderate tilt angle (>25°) adds 1 → cautious")
    func moderateTiltAngle() {
        let state = ThreatState(deviceTiltAngle: 30)
        #expect(state.aggregatedThreat == .cautious)
    }

    @Test("High tilt angle (>40°) adds 2 → threatened")
    func highTiltAngle() {
        let state = ThreatState(deviceTiltAngle: 45)
        #expect(state.aggregatedThreat == .threatened)
    }

    @Test("Tilt at exactly 25 does not trigger")
    func tiltAtLowBoundary() {
        let state = ThreatState(deviceTiltAngle: 25)
        #expect(state.aggregatedThreat == .clear)
    }

    @Test("Tilt at exactly 40 does not add +2 (only +1)")
    func tiltAtHighBoundary() {
        let state = ThreatState(deviceTiltAngle: 40)
        #expect(state.aggregatedThreat == .cautious)
    }

    @Test("Negative tilt angle uses absolute value")
    func negativeTiltAngle() {
        let state = ThreatState(deviceTiltAngle: -45)
        #expect(state.aggregatedThreat == .threatened)
    }

    @Test("Negative gaze deviation uses absolute value")
    func negativeGazeDeviation() {
        let state = ThreatState(primaryGazeDeviation: -0.55)
        #expect(state.aggregatedThreat == .threatened)
    }

    // MARK: - Score Accumulation

    @Test("Face lost + moderate tilt = score 3 → locked")
    func faceLostPlusModerateTilt() {
        let state = ThreatState(
            primaryFaceLost: true,
            deviceTiltAngle: 30
        )
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("Face lost + moderate gaze = score 3 → locked")
    func faceLostPlusModerateGaze() {
        let state = ThreatState(
            primaryGazeDeviation: 0.35,
            primaryFaceLost: true
        )
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("Moderate gaze + moderate tilt = score 2 → threatened")
    func moderateGazePlusModerateTilt() {
        let state = ThreatState(
            primaryGazeDeviation: 0.35,
            deviceTiltAngle: 30
        )
        #expect(state.aggregatedThreat == .threatened)
    }

    @Test("High gaze + high tilt = score 4 → locked")
    func highGazePlusHighTilt() {
        let state = ThreatState(
            primaryGazeDeviation: 0.55,
            deviceTiltAngle: 45
        )
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("Moderate gaze + high tilt = score 3 → locked")
    func moderateGazePlusHighTilt() {
        let state = ThreatState(
            primaryGazeDeviation: 0.35,
            deviceTiltAngle: 45
        )
        #expect(state.aggregatedThreat == .locked)
    }

    // MARK: - Edge Cases

    @Test("All signals zero = clear")
    func allZero() {
        let state = ThreatState(
            secondFaceDetected: false,
            primaryGazeDeviation: 0,
            primaryFaceLost: false,
            deviceTiltAngle: 0,
            deviceTiltRate: 0
        )
        #expect(state.aggregatedThreat == .clear)
    }

    @Test("All signals maximum = locked")
    func allMaximum() {
        let state = ThreatState(
            secondFaceDetected: true,
            primaryGazeDeviation: 1.0,
            primaryFaceLost: true,
            deviceTiltAngle: 90,
            deviceTiltRate: 200
        )
        #expect(state.aggregatedThreat == .locked)
    }

    @Test("Score exactly 1 = cautious")
    func scoreExactlyOne() {
        let state = ThreatState(primaryGazeDeviation: 0.35)
        #expect(state.aggregatedThreat == .cautious)
    }

    @Test("Score exactly 2 = threatened")
    func scoreExactlyTwo() {
        let state = ThreatState(primaryGazeDeviation: 0.55)
        #expect(state.aggregatedThreat == .threatened)
    }

    @Test("Score exactly 3 = locked")
    func scoreExactlyThree() {
        let state = ThreatState(
            primaryGazeDeviation: 0.55,
            deviceTiltAngle: 30
        )
        #expect(state.aggregatedThreat == .locked)
    }

    // MARK: - ThreatLevel Comparable

    @Test("ThreatLevel ordering is correct")
    func threatLevelOrdering() {
        #expect(ThreatLevel.clear < ThreatLevel.cautious)
        #expect(ThreatLevel.cautious < ThreatLevel.threatened)
        #expect(ThreatLevel.threatened < ThreatLevel.locked)
        #expect(ThreatLevel.clear < ThreatLevel.locked)
    }

    @Test("Initial state is zeroed out")
    func initialState() {
        let state = ThreatState.initial
        #expect(state.secondFaceDetected == false)
        #expect(state.primaryGazeDeviation == 0)
        #expect(state.primaryFaceLost == false)
        #expect(state.deviceTiltAngle == 0)
        #expect(state.deviceTiltRate == 0)
        #expect(state.aggregatedThreat == .clear)
    }
}
