import XCTest
@testable import Fretwise

final class PitchDetectorTests: XCTestCase {

    let sampleRate: Float = 44100.0
    let bufferSize = 4096

    private func sineWave(frequency: Float, count: Int, sampleRate: Float) -> [Float] {
        (0..<count).map { i in
            sinf(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
    }

    func testDetectsA440() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 440.0, accuracy: 2.0, "Should detect A440 within 2 Hz")
    }

    func testDetectsE2LowString() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 82.41, count: bufferSize, sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 82.41, accuracy: 2.0, "Should detect low E string")
    }

    func testDetectsE4HighString() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 329.63, count: bufferSize, sampleRate: sampleRate)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 329.63, accuracy: 2.0, "Should detect high E string")
    }

    func testSilenceReturnsNil() {
        let detector = PitchDetector()
        let buffer = [Float](repeating: 0.0, count: bufferSize)
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNil(result, "Silence should return nil")
    }

    func testVeryQuietSignalReturnsNil() {
        let detector = PitchDetector()
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
            .map { $0 * 0.0001 }
        let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)

        XCTAssertNil(result, "Very quiet signal should return nil")
    }

    func testDetectsAllGuitarStrings() {
        let detector = PitchDetector()
        let frequencies: [(String, Float)] = [
            ("E2", 82.41), ("A2", 110.0), ("D3", 146.83),
            ("G3", 196.0), ("B3", 246.94), ("E4", 329.63)
        ]

        for (name, freq) in frequencies {
            let buffer = sineWave(frequency: freq, count: bufferSize, sampleRate: sampleRate)
            let result = detector.detectPitch(buffer: buffer, sampleRate: sampleRate)
            XCTAssertNotNil(result, "\(name) (\(freq) Hz) should be detected")
            XCTAssertEqual(result!, freq, accuracy: 2.0, "\(name) should be within 2 Hz")
        }
    }
}
