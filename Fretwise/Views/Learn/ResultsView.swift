import SwiftData
import SwiftUI

/// Post-lesson summary screen showing accuracy and stats.
struct ResultsView: View {

    let lesson: Lesson
    let accuracy: Double
    let correctCount: Int
    let totalCount: Int
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext

    private var passed: Bool {
        accuracy >= lesson.successCriteria.minAccuracy
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: passed ? "trophy.fill" : "arrow.counterclockwise")
                .font(.system(size: 64))
                .foregroundColor(passed ? .yellow : .orange)

            Text(passed ? "Lesson Complete!" : "Keep Practicing")
                .font(.title)
                .fontWeight(.bold)

            Text(lesson.title)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                StatRow(label: "Accuracy", value: "\(Int(accuracy * 100))%",
                        color: accuracy >= 0.8 ? .green : accuracy >= 0.5 ? .yellow : .red)
                StatRow(label: "Correct", value: "\(correctCount) / \(totalCount)",
                        color: .blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.15))
            )
            .padding(.horizontal)

            Spacer()

            Button(action: {
                saveProgress()
                onDone()
            }) {
                Text(passed ? "Continue" : "Try Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(passed ? .green : .orange)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func saveProgress() {
        let progress = UserProgress(
            lessonId: lesson.id,
            completedAt: passed ? .now : nil,
            accuracy: accuracy,
            attempts: 1,
            bestStreak: correctCount
        )
        modelContext.insert(progress)

        for step in lesson.steps {
            guard let chordName = step.chord else { continue }

            let descriptor = FetchDescriptor<ChordMastery>(
                predicate: #Predicate { $0.chordName == chordName }
            )
            let existing = try? modelContext.fetch(descriptor).first

            if let mastery = existing {
                mastery.timesCorrect += correctCount
                mastery.lastPracticed = .now
            } else {
                let mastery = ChordMastery(
                    chordName: chordName,
                    timesCorrect: correctCount,
                    timesFailed: totalCount - correctCount,
                    averageConfidence: accuracy,
                    lastPracticed: .now
                )
                modelContext.insert(mastery)
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}
