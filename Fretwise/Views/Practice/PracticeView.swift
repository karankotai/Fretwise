import SwiftUI

/// The main practice screen. Composes fretboard, tab, feedback, and header.
/// Wires ChordDetectionService events into the LessonEngine.
struct PracticeView: View {

    let lesson: Lesson
    let onComplete: (LessonEngine) -> Void

    @StateObject private var detectionService = ChordDetectionService()
    @StateObject private var engine: LessonEngine

    init(lesson: Lesson, onComplete: @escaping (LessonEngine) -> Void) {
        self.lesson = lesson
        self.onComplete = onComplete
        _engine = StateObject(wrappedValue: LessonEngine(lesson: lesson))
    }

    private var expectedTemplate: ChordTemplate? {
        guard let name = engine.expectedChord else { return nil }
        return ChordLibrary.chord(named: name)
    }

    private var isCurrentlyCorrect: Bool {
        guard let expected = engine.expectedChord else { return false }
        return detectionService.currentEvent?.chord == expected
    }

    private var allChordNames: [String] {
        lesson.steps.compactMap { $0.chord }
    }

    private var currentChordIndex: Int {
        let chordsBeforeCurrent = lesson.steps.prefix(engine.currentStepIndex).compactMap { $0.chord }
        return chordsBeforeCurrent.count
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Guitar SVG background (centered behind fretboard)
            Image("guitar-silhouette")
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .opacity(0.04)
                .allowsHitTesting(false)

            VStack(spacing: 12) {
                if let step = engine.currentStep {
                    TargetChordHeader(
                        chordName: engine.expectedChord ?? "Free Play",
                        instruction: step.instruction,
                        stepIndex: engine.currentStepIndex,
                        totalSteps: lesson.steps.count
                    )

                    FretboardView(
                        chord: expectedTemplate,
                        isCorrect: isCurrentlyCorrect
                    )
                    .padding(.horizontal)

                    if !allChordNames.isEmpty {
                        TabScrollView(
                            chords: allChordNames,
                            currentIndex: currentChordIndex
                        )
                    }

                    Spacer()

                    FeedbackOverlay(
                        detectedChord: detectionService.currentEvent?.chord,
                        expectedChord: engine.expectedChord,
                        confidence: detectionService.currentEvent?.confidence ?? 0,
                        isCorrect: isCurrentlyCorrect
                    )

                    // Hold progress bar
                    if let holdDuration = step.holdDuration, holdDuration > 0 {
                        ProgressView(
                            value: min(engine.currentStepHoldTime, holdDuration),
                            total: holdDuration
                        )
                        .tint(isCurrentlyCorrect ? .green : .gray)
                        .padding(.horizontal)
                    }

                    // Skip button for free_play steps
                    if step.type == .freePlay {
                        Button("Continue") {
                            engine.skipStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.bottom)
                    }
                }
            }
            .padding(.top)
        }
        .onAppear {
            try? detectionService.start()
        }
        .onDisappear {
            detectionService.stop()
        }
        .onChange(of: detectionService.currentEvent?.chord) { _, _ in
            if let event = detectionService.currentEvent {
                engine.receiveChordEvent(event)
                engine.advanceIfReady()
            }
        }
        .onChange(of: engine.state) { _, newState in
            if newState == .completed {
                detectionService.stop()
                onComplete(engine)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
