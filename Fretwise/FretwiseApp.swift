import SwiftData
import SwiftUI

@main
struct FretwiseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserProgress.self, ChordMastery.self])
    }
}
