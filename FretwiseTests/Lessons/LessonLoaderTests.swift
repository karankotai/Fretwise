import XCTest
@testable import Fretwise

final class LessonLoaderTests: XCTestCase {

    func testParseValidLessonJSON() throws {
        let json = """
        {
            "id": "test-lesson",
            "title": "Test Lesson",
            "module": "test/module",
            "difficulty": 1,
            "prerequisites": [],
            "steps": [
                {
                    "type": "chord_hold",
                    "chord": "G",
                    "holdDuration": 3.0,
                    "instruction": "Hold G chord"
                }
            ],
            "successCriteria": {
                "minAccuracy": 0.7,
                "minStepsCompleted": 1
            }
        }
        """.data(using: .utf8)!

        let lesson = try JSONDecoder().decode(Lesson.self, from: json)
        XCTAssertEqual(lesson.id, "test-lesson")
        XCTAssertEqual(lesson.title, "Test Lesson")
        XCTAssertEqual(lesson.steps.count, 1)
        XCTAssertEqual(lesson.steps[0].type, .chordHold)
        XCTAssertEqual(lesson.steps[0].chord, "G")
        XCTAssertEqual(lesson.steps[0].holdDuration, 3.0)
        XCTAssertEqual(lesson.successCriteria.minAccuracy, 0.7)
    }

    func testParseChordSequenceStep() throws {
        let json = """
        {
            "id": "seq-test",
            "title": "Sequence Test",
            "module": "test",
            "difficulty": 1,
            "prerequisites": [],
            "steps": [
                {
                    "type": "chord_sequence",
                    "sequence": ["G", "C", "G", "C"],
                    "bpm": 60,
                    "beatsPerChord": 4,
                    "instruction": "Switch chords on beat"
                }
            ],
            "successCriteria": {
                "minAccuracy": 0.7,
                "minStepsCompleted": 1
            }
        }
        """.data(using: .utf8)!

        let lesson = try JSONDecoder().decode(Lesson.self, from: json)
        let step = lesson.steps[0]
        XCTAssertEqual(step.type, .chordSequence)
        XCTAssertEqual(step.sequence, ["G", "C", "G", "C"])
        XCTAssertEqual(step.bpm, 60)
        XCTAssertEqual(step.beatsPerChord, 4)
    }
}
