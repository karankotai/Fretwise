import Foundation
import SwiftData

@Model
final class UserProgress {
    var lessonId: String
    var completedAt: Date?
    var accuracy: Double
    var attempts: Int
    var bestStreak: Int

    init(
        lessonId: String,
        completedAt: Date? = nil,
        accuracy: Double = 0,
        attempts: Int = 0,
        bestStreak: Int = 0
    ) {
        self.lessonId = lessonId
        self.completedAt = completedAt
        self.accuracy = accuracy
        self.attempts = attempts
        self.bestStreak = bestStreak
    }
}
