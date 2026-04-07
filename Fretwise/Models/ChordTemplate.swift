import Foundation

struct ChordTemplate: Identifiable, Equatable {
    let id = UUID()
    let name: String

    /// 12-bin chroma profile normalized to [0, 1].
    /// Index 0 = C, 1 = C#, 2 = D, ..., 11 = B
    let chromaProfile: [Float]

    /// Fret numbers for each string, low E (6th) to high E (1st).
    /// 0 = open, -1 = muted.
    let fingerPositions: [Int]

    /// Which finger to use on each string (0 = none, 1-4 = index through pinky).
    /// Same order as fingerPositions: low E to high E.
    let fingerNumbers: [Int]

    /// Human-readable strumming instruction.
    let instruction: String
}
