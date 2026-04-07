import XCTest
@testable import Fretwise

final class ChromaExtractorTests: XCTestCase {

    let sampleRate: Float = 44100.0
    let bufferSize = 4096

    private func sineWave(frequency: Float, count: Int, sampleRate: Float) -> [Float] {
        (0..<count).map { i in
            sinf(2.0 * .pi * frequency * Float(i) / sampleRate)
        }
    }

    func testExtractChromaReturns12Bins() {
        let extractor = ChromaExtractor(sampleRate: sampleRate, bufferSize: bufferSize)
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
        let chroma = extractor.extract(from: buffer)
        XCTAssertEqual(chroma.count, 12)
    }

    func testPureADetectedInCorrectBin() {
        let extractor = ChromaExtractor(sampleRate: sampleRate, bufferSize: bufferSize)
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
        let chroma = extractor.extract(from: buffer)

        let aBin = 9
        let maxBin = chroma.enumerated().max(by: { $0.element < $1.element })!.offset
        XCTAssertEqual(maxBin, aBin, "440Hz should map to A (bin 9), got bin \(maxBin)")
    }

    func testPureGDetectedInCorrectBin() {
        let extractor = ChromaExtractor(sampleRate: sampleRate, bufferSize: bufferSize)
        let buffer = sineWave(frequency: 392.0, count: bufferSize, sampleRate: sampleRate)
        let chroma = extractor.extract(from: buffer)

        let gBin = 7
        let maxBin = chroma.enumerated().max(by: { $0.element < $1.element })!.offset
        XCTAssertEqual(maxBin, gBin, "392Hz should map to G (bin 7), got bin \(maxBin)")
    }

    func testChromaIsNormalized() {
        let extractor = ChromaExtractor(sampleRate: sampleRate, bufferSize: bufferSize)
        let buffer = sineWave(frequency: 440.0, count: bufferSize, sampleRate: sampleRate)
        let chroma = extractor.extract(from: buffer)

        let maxVal = chroma.max()!
        XCTAssertEqual(maxVal, 1.0, accuracy: 0.01, "Chroma should be normalized to peak at 1.0")

        for val in chroma {
            XCTAssertGreaterThanOrEqual(val, 0.0, "Chroma values must be non-negative")
            XCTAssertLessThanOrEqual(val, 1.0, "Chroma values must not exceed 1.0")
        }
    }

    func testSilenceReturnsZeroChroma() {
        let extractor = ChromaExtractor(sampleRate: sampleRate, bufferSize: bufferSize)
        let buffer = [Float](repeating: 0.0, count: bufferSize)
        let chroma = extractor.extract(from: buffer)

        let sum = chroma.reduce(0, +)
        XCTAssertEqual(sum, 0.0, accuracy: 0.001, "Silence should produce zero chroma")
    }
}
