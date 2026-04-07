import SwiftUI

struct Module: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let lessonIds: [String]
}

/// Root view of the Learn tab.
struct ModuleListView: View {

    let modules: [Module] = [
        Module(
            id: "beginner/first-chords",
            title: "First Chords",
            subtitle: "Learn G, C, D, Em, Am",
            icon: "hand.raised.fingers.spread",
            lessonIds: [
                "learn-em-chord",
                "learn-g-chord",
                "learn-am-chord",
                "learn-c-chord",
                "learn-d-chord"
            ]
        ),
        Module(
            id: "beginner/chord-changes",
            title: "Chord Changes",
            subtitle: "Practice switching between chords",
            icon: "arrow.left.arrow.right",
            lessonIds: [
                "em-to-am-transition",
                "g-to-c-transition",
                "g-d-c-progression"
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            List(modules) { module in
                NavigationLink(destination: LessonListView(module: module)) {
                    HStack(spacing: 16) {
                        Image(systemName: module.icon)
                            .font(.title2)
                            .foregroundColor(.green)
                            .frame(width: 44, height: 44)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(module.title)
                                .font(.headline)
                            Text(module.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Learn")
        }
    }
}
