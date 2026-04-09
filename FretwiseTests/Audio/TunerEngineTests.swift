import XCTest
@testable import Fretwise

final class TunerEngineTests: XCTestCase {

    func testCentsCalculationPerfectPitch() {
        let cents = TunerEngine.centsOffset(detected: 110.0, reference: 110.0)
        XCTAssertEqual(cents, 0.0, accuracy: 0.01)
    }

    func testCentsCalculationSharp() {
        // One semitone sharp (A2 -> A#2)
        let cents = TunerEngine.centsOffset(detected: 116.54, reference: 110.0)
        XCTAssertEqual(cents, 100.0, accuracy: 1.0)
    }

    func testCentsCalculationFlat() {
        // 50 cents flat
        let freqFlat = 110.0 * powf(2.0, -50.0 / 1200.0)
        let cents = TunerEngine.centsOffset(detected: freqFlat, reference: 110.0)
        XCTAssertEqual(cents, -50.0, accuracy: 1.0)
    }

    func testNearestStringE2() {
        let string = TunerEngine.nearestString(to: 83.0)
        XCTAssertEqual(string.name, "E2")
        XCTAssertEqual(string.frequency, 82.41, accuracy: 0.01)
    }

    func testNearestStringA2() {
        let string = TunerEngine.nearestString(to: 112.0)
        XCTAssertEqual(string.name, "A2")
    }

    func testNearestStringD3() {
        let string = TunerEngine.nearestString(to: 145.0)
        XCTAssertEqual(string.name, "D3")
    }

    func testNearestStringG3() {
        let string = TunerEngine.nearestString(to: 200.0)
        XCTAssertEqual(string.name, "G3")
    }

    func testNearestStringB3() {
        let string = TunerEngine.nearestString(to: 250.0)
        XCTAssertEqual(string.name, "B3")
    }

    func testNearestStringE4() {
        let string = TunerEngine.nearestString(to: 330.0)
        XCTAssertEqual(string.name, "E4")
    }

    func testTuningAccuracyInTune() {
        let accuracy = TunerEngine.tuningAccuracy(centsOffset: 3.0)
        XCTAssertEqual(accuracy, .inTune)
    }

    func testTuningAccuracyClose() {
        let accuracy = TunerEngine.tuningAccuracy(centsOffset: 10.0)
        XCTAssertEqual(accuracy, .close)
    }

    func testTuningAccuracyOff() {
        let accuracy = TunerEngine.tuningAccuracy(centsOffset: -20.0)
        XCTAssertEqual(accuracy, .off)
    }
}
