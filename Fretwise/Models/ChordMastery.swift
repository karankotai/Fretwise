import Foundation
import SwiftData

@Model
final class ChordMastery {
    var chordName: String
    var timesCorrect: Int
    var timesFailed: Int
    var averageConfidence: Double
    var lastPracticed: Date

    init(
        chordName: String,
        timesCorrect: Int = 0,
        timesFailed: Int = 0,
        averageConfidence: Double = 0,
        lastPracticed: Date = .now
    ) {
        self.chordName = chordName
        self.timesCorrect = timesCorrect
        self.timesFailed = timesFailed
        self.averageConfidence = averageConfidence
        self.lastPracticed = lastPracticed
    }
}
