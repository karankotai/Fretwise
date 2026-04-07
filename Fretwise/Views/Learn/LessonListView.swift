import SwiftData
import SwiftUI

/// Shows lessons within a module. Tapping a lesson starts the practice flow.
struct LessonListView: View {

    let module: Module
    @State private var activeLessonEngine: LessonEngine?
    @State private var activeLesson: Lesson?
    @State private var showResults = false

    @Query private var allProgress: [UserProgress]

    var body: some View {
        List {
            ForEach(module.lessonIds, id: \.self) { lessonId in
                let lesson = LessonLoader.load(id: lessonId)
                let isCompleted = allProgress.contains { $0.lessonId == lessonId && $0.completedAt != nil }

                if let lesson {
                    Button {
                        activeLesson = lesson
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lesson.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Difficulty: \(lesson.difficulty)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(module.title)
        .fullScreenCover(item: $activeLesson) { lesson in
            NavigationStack {
                PracticeView(lesson: lesson) { completedEngine in
                    activeLessonEngine = completedEngine
                    showResults = true
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("End") {
                            activeLesson = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showResults) {
            if let engine = activeLessonEngine, let lesson = activeLesson {
                ResultsView(
                    lesson: lesson,
                    accuracy: engine.accuracy,
                    correctCount: engine.correctCount,
                    totalCount: engine.totalCount
                ) {
                    showResults = false
                    activeLesson = nil
                }
            }
        }
    }
}
