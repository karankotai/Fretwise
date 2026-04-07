import XCTest
@testable import Fretwise

final class ChordClassifierTests: XCTestCase {

    func testPerfectGChromaReturnsG() {
        let classifier = ChordClassifier(confidenceThreshold: 0.85)
        let gChroma = ChordLibrary.gMajor.chromaProfile
        let result = classifier.classify(chroma: gChroma)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.chord, "G")
        XCTAssertGreaterThan(result?.confidence ?? 0, 0.99)
    }

    func testPerfectCChromaReturnsC() {
        let classifier = ChordClassifier(confidenceThreshold: 0.85)
        let cChroma = ChordLibrary.cMajor.chromaProfile
        let result = classifier.classify(chroma: cChroma)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.chord, "C")
    }

    func testNoisyGChromaStillReturnsG() {
        let classifier = ChordClassifier(confidenceThreshold: 0.7)
        var noisy = ChordLibrary.gMajor.chromaProfile
        noisy[0] += 0.15
        noisy[4] += 0.1
        let maxVal = noisy.max()!
        noisy = noisy.map { $0 / maxVal }

        let result = classifier.classify(chroma: noisy)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.chord, "G")
    }

    func testSilenceReturnsNil() {
        let classifier = ChordClassifier(confidenceThreshold: 0.85)
        let silence = [Float](repeating: 0.0, count: 12)
        let result = classifier.classify(chroma: silence)
        XCTAssertNil(result)
    }

    func testBelowThresholdReturnsNil() {
        let classifier = ChordClassifier(confidenceThreshold: 0.99)
        let uniform: [Float] = [Float](repeating: 1.0 / 12.0, count: 12)
        let result = classifier.classify(chroma: uniform)
        XCTAssertNil(result)
    }

    func testConfidenceIsBetweenZeroAndOne() {
        let classifier = ChordClassifier(confidenceThreshold: 0.0)
        let gChroma = ChordLibrary.gMajor.chromaProfile
        let result = classifier.classify(chroma: gChroma)

        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result!.confidence, 0.0)
        XCTAssertLessThanOrEqual(result!.confidence, 1.0)
    }
}
