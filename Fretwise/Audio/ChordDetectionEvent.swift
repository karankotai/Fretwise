import Foundation

/// Emitted by the audio pipeline when a chord is detected (or not).
struct ChordDetectionEvent: Equatable {
    /// The name of the detected chord (e.g., "G", "Am"). Nil if no chord detected.
    let chord: String?
    /// Confidence score between 0.0 and 1.0.
    let confidence: Float
    /// Timestamp of detection.
    let timestamp: Date

    init(chord: String?, confidence: Float, timestamp: Date = .now) {
        self.chord = chord
        self.confidence = confidence
        self.timestamp = timestamp
    }
}
