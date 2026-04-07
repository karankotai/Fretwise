import Foundation

enum LessonLoader {

    /// Load a lesson by its ID from the app bundle.
    /// Searches recursively since lesson JSON files live in subdirectories.
    static func load(id: String) -> Lesson? {
        // Try top-level first
        if let url = Bundle.main.url(forResource: id, withExtension: "json") {
            return load(from: url)
        }

        // Search recursively in the bundle
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: nil) else { return nil }

        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.deletingPathExtension().lastPathComponent == id
                && fileURL.pathExtension == "json" {
                return load(from: fileURL)
            }
        }
        return nil
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
