import Combine
import Foundation

/// Drives a single lesson: tracks current step, receives chord events,
/// grades correctness, and decides when to advance.
final class LessonEngine: ObservableObject {

    enum State: Equatable {
        case playing
        case completed
    }

    @Published var state: State = .playing
    @Published var currentStepIndex: Int = 0
    @Published var correctCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var currentStepHoldTime: TimeInterval = 0

    let lesson: Lesson
    private var holdStartTime: Date?

    init(lesson: Lesson) {
        self.lesson = lesson
    }

    var currentStep: LessonStep? {
        guard currentStepIndex < lesson.steps.count else { return nil }
        return lesson.steps[currentStepIndex]
    }

    var expectedChord: String? {
        currentStep?.chord
    }

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    func receiveChordEvent(_ event: ChordDetectionEvent) {
        guard state == .playing else { return }
        guard let step = currentStep else { return }

        guard step.type == .chordHold || step.type == .chordSequence else { return }
        guard let expected = expectedChord else { return }

        totalCount += 1

        if event.chord == expected {
            correctCount += 1
            if holdStartTime == nil {
                holdStartTime = Date()
            }
            currentStepHoldTime = Date().timeIntervalSince(holdStartTime!)
        } else {
            holdStartTime = nil
            currentStepHoldTime = 0
        }
    }

    func advanceIfReady() {
        guard state == .playing else { return }
        guard let step = currentStep else { return }

        let shouldAdvance: Bool

        switch step.type {
        case .chordHold:
            let requiredDuration = step.holdDuration ?? 3.0
            shouldAdvance = currentStepHoldTime >= requiredDuration
        case .freePlay:
            shouldAdvance = true
        case .chordSequence, .singleNote:
            shouldAdvance = currentStepHoldTime >= (step.holdDuration ?? 3.0)
        }

        if shouldAdvance {
            moveToNextStep()
        }
    }

    func skipStep() {
        guard state == .playing else { return }
        moveToNextStep()
    }

    private func moveToNextStep() {
        holdStartTime = nil
        currentStepHoldTime = 0

        if currentStepIndex + 1 < lesson.steps.count {
            currentStepIndex += 1
        } else {
            state = .completed
        }
    }
}
