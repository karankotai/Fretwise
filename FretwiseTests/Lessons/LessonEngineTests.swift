import XCTest
@testable import Fretwise

final class LessonEngineTests: XCTestCase {

    private func makeLesson(steps: [LessonStep]) -> Lesson {
        Lesson(
            id: "test",
            title: "Test",
            module: "test",
            difficulty: 1,
            prerequisites: [],
            steps: steps,
            successCriteria: SuccessCriteria(minAccuracy: 0.7, minStepsCompleted: 1)
        )
    }

    private func chordHoldStep(_ chord: String, duration: Double = 3.0) -> LessonStep {
        LessonStep(
            type: .chordHold,
            instruction: "Hold \(chord)",
            chord: chord,
            holdDuration: duration,
            sequence: nil,
            bpm: nil,
            beatsPerChord: nil
        )
    }

    func testInitialState() {
        let lesson = makeLesson(steps: [chordHoldStep("G")])
        let engine = LessonEngine(lesson: lesson)

        XCTAssertEqual(engine.currentStepIndex, 0)
        XCTAssertEqual(engine.state, .playing)
        XCTAssertEqual(engine.expectedChord, "G")
    }

    func testCorrectChordIncrementsScore() {
        let lesson = makeLesson(steps: [chordHoldStep("G")])
        let engine = LessonEngine(lesson: lesson)

        let event = ChordDetectionEvent(chord: "G", confidence: 0.95)
        engine.receiveChordEvent(event)

        XCTAssertEqual(engine.correctCount, 1)
        XCTAssertEqual(engine.totalCount, 1)
    }

    func testWrongChordIncrementsTotal() {
        let lesson = makeLesson(steps: [chordHoldStep("G")])
        let engine = LessonEngine(lesson: lesson)

        let event = ChordDetectionEvent(chord: "C", confidence: 0.9)
        engine.receiveChordEvent(event)

        XCTAssertEqual(engine.correctCount, 0)
        XCTAssertEqual(engine.totalCount, 1)
    }

    func testAdvancesToNextStep() {
        let lesson = makeLesson(steps: [
            chordHoldStep("G", duration: 0.0),
            chordHoldStep("C", duration: 0.0)
        ])
        let engine = LessonEngine(lesson: lesson)

        let event = ChordDetectionEvent(chord: "G", confidence: 0.95)
        engine.receiveChordEvent(event)
        engine.advanceIfReady()

        XCTAssertEqual(engine.currentStepIndex, 1)
        XCTAssertEqual(engine.expectedChord, "C")
    }

    func testLessonCompletesAfterAllSteps() {
        let lesson = makeLesson(steps: [
            chordHoldStep("G", duration: 0.0)
        ])
        let engine = LessonEngine(lesson: lesson)

        let event = ChordDetectionEvent(chord: "G", confidence: 0.95)
        engine.receiveChordEvent(event)
        engine.advanceIfReady()

        XCTAssertEqual(engine.state, .completed)
    }

    func testAccuracyCalculation() {
        let lesson = makeLesson(steps: [chordHoldStep("G")])
        let engine = LessonEngine(lesson: lesson)

        engine.receiveChordEvent(ChordDetectionEvent(chord: "G", confidence: 0.9))
        engine.receiveChordEvent(ChordDetectionEvent(chord: "G", confidence: 0.9))
        engine.receiveChordEvent(ChordDetectionEvent(chord: "C", confidence: 0.9))
        engine.receiveChordEvent(ChordDetectionEvent(chord: "G", confidence: 0.9))

        XCTAssertEqual(engine.accuracy, 0.75, accuracy: 0.01)
    }
}
