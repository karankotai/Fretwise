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
            lessonIds: ["learn-g-chord"]
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
