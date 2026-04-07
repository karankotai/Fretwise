import Foundation

struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let module: String
    let difficulty: Int
    let prerequisites: [String]
    let steps: [LessonStep]
    let successCriteria: SuccessCriteria
}

struct LessonStep: Codable, Identifiable {
    var id: String { "\(type.rawValue)-\(chord ?? "")-\(instruction.prefix(20))" }

    let type: StepType
    let instruction: String

    // chord_hold
    let chord: String?
    let holdDuration: Double?

    // chord_sequence
    let sequence: [String]?
    let bpm: Int?
    let beatsPerChord: Int?

    enum StepType: String, Codable {
        case chordHold = "chord_hold"
        case chordSequence = "chord_sequence"
        case freePlay = "free_play"
        case singleNote = "single_note"
    }
}

struct SuccessCriteria: Codable {
    let minAccuracy: Double
    let minStepsCompleted: Int
}

// Needed for .fullScreenCover(item:) and NavigationLink
extension Lesson: Hashable {
    static func == (lhs: Lesson, rhs: Lesson) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
