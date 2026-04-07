import Foundation

enum ChordLibrary {

    /// All available chord templates.
    static let allChords: [ChordTemplate] = [
        gMajor, cMajor, dMajor, eMinor, aMinor
    ]

    /// Look up a chord by name. Returns nil if not found.
    static func chord(named name: String) -> ChordTemplate? {
        allChords.first { $0.name == name }
    }

    // MARK: - Chord Definitions

    /// G Major — fingers: 3-2-0-0-0-3
    /// Notes: G B D G B G
    static let gMajor = ChordTemplate(
        name: "G",
        chromaProfile: normalize([
            0.0,  // C
            0.0,  // C#
            0.6,  // D
            0.0,  // D#
            0.0,  // E
            0.0,  // F
            0.0,  // F#
            1.0,  // G  (root)
            0.0,  // G#
            0.0,  // A
            0.0,  // A#
            0.7   // B
        ]),
        fingerPositions: [3, 2, 0, 0, 0, 3],
        fingerNumbers:   [2, 1, 0, 0, 0, 3],
        instruction: "Strum all 6 strings"
    )

    /// C Major — fingers: x-3-2-0-1-0
    /// Notes: X C E G C E
    static let cMajor = ChordTemplate(
        name: "C",
        chromaProfile: normalize([
            1.0,  // C  (root)
            0.0,  // C#
            0.0,  // D
            0.0,  // D#
            0.7,  // E
            0.0,  // F
            0.0,  // F#
            0.6,  // G
            0.0,  // G#
            0.0,  // A
            0.0,  // A#
            0.0   // B
        ]),
        fingerPositions: [-1, 3, 2, 0, 1, 0],
        fingerNumbers:   [0, 3, 2, 0, 1, 0],
        instruction: "Strum strings 5 through 1 (skip low E)"
    )

    /// D Major — fingers: x-x-0-2-3-2
    /// Notes: X X D A D F#
    static let dMajor = ChordTemplate(
        name: "D",
        chromaProfile: normalize([
            0.0,  // C
            0.0,  // C#
            1.0,  // D  (root)
            0.0,  // D#
            0.0,  // E
            0.0,  // F
            0.6,  // F#
            0.0,  // G
            0.0,  // G#
            0.7,  // A
            0.0,  // A#
            0.0   // B
        ]),
        fingerPositions: [-1, -1, 0, 2, 3, 2],
        fingerNumbers:   [0, 0, 0, 1, 3, 2],
        instruction: "Strum strings 4 through 1 (skip low E and A)"
    )

    /// E Minor — fingers: 0-2-2-0-0-0
    /// Notes: E B E G B E
    static let eMinor = ChordTemplate(
        name: "Em",
        chromaProfile: normalize([
            0.0,  // C
            0.0,  // C#
            0.0,  // D
            0.0,  // D#
            1.0,  // E  (root)
            0.0,  // F
            0.0,  // F#
            0.6,  // G
            0.0,  // G#
            0.0,  // A
            0.0,  // A#
            0.7   // B
        ]),
        fingerPositions: [0, 2, 2, 0, 0, 0],
        fingerNumbers:   [0, 2, 3, 0, 0, 0],
        instruction: "Strum all 6 strings"
    )

    /// A Minor — fingers: x-0-2-2-1-0
    /// Notes: X A E A C E
    static let aMinor = ChordTemplate(
        name: "Am",
        chromaProfile: normalize([
            0.6,  // C
            0.0,  // C#
            0.0,  // D
            0.0,  // D#
            0.7,  // E
            0.0,  // F
            0.0,  // F#
            0.0,  // G
            0.0,  // G#
            1.0,  // A  (root)
            0.0,  // A#
            0.0   // B
        ]),
        fingerPositions: [-1, 0, 2, 2, 1, 0],
        fingerNumbers:   [0, 0, 2, 3, 1, 0],
        instruction: "Strum strings 5 through 1 (skip low E)"
    )

    // MARK: - Helpers

    private static func normalize(_ profile: [Float]) -> [Float] {
        let maxVal = profile.max() ?? 1.0
        guard maxVal > 0 else { return profile }
        return profile.map { $0 / maxVal }
    }
}
