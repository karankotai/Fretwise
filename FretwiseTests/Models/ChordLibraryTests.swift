import XCTest
@testable import Fretwise

final class ChordLibraryTests: XCTestCase {

    func testGChordExists() {
        let chord = ChordLibrary.chord(named: "G")
        XCTAssertNotNil(chord)
        XCTAssertEqual(chord?.name, "G")
    }

    func testGChordHasChromaProfile() {
        let chord = ChordLibrary.chord(named: "G")!
        XCTAssertEqual(chord.chromaProfile.count, 12)
        let gBin = chord.chromaProfile[7]
        let bBin = chord.chromaProfile[11]
        let dBin = chord.chromaProfile[2]
        XCTAssertGreaterThan(gBin, 0.5, "G should be strong in G chord")
        XCTAssertGreaterThan(bBin, 0.3, "B should be present in G chord")
        XCTAssertGreaterThan(dBin, 0.3, "D should be present in G chord")
    }

    func testGChordHasFingerPositions() {
        let chord = ChordLibrary.chord(named: "G")!
        XCTAssertEqual(chord.fingerPositions.count, 6)
        XCTAssertEqual(chord.fingerPositions, [3, 2, 0, 0, 0, 3])
    }

    func testChromaProfileIsNormalized() {
        let chord = ChordLibrary.chord(named: "G")!
        let maxVal = chord.chromaProfile.max()!
        XCTAssertEqual(maxVal, 1.0, accuracy: 0.001, "Chroma should be normalized to [0,1]")
    }

    func testAllChordsHaveValidData() {
        for chord in ChordLibrary.allChords {
            XCTAssertEqual(chord.chromaProfile.count, 12, "\(chord.name) chroma must have 12 bins")
            XCTAssertEqual(chord.fingerPositions.count, 6, "\(chord.name) must have 6 string positions")
            XCTAssertFalse(chord.name.isEmpty, "Chord name must not be empty")
        }
    }
}
