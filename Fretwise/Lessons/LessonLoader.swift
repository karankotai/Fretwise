import Foundation

enum LessonLoader {

    /// Load a lesson by its ID from the app bundle.
    static func load(id: String) -> Lesson? {
        guard let url = Bundle.main.url(forResource: id, withExtension: "json") else {
            return nil
        }
        return load(from: url)
    }

    /// Load a lesson from a specific file URL.
    static func load(from url: URL) -> Lesson? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Lesson.self, from: data)
    }

    /// Load all lessons from a module directory.
    static func loadModule(named module: String) -> [Lesson] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)
        else { return [] }

        return urls.compactMap { load(from: $0) }
            .filter { $0.module == module }
            .sorted { $0.difficulty < $1.difficulty }
    }
}
