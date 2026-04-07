import Foundation

/// Classifies a 12-bin chroma vector against known chord templates
/// using cosine similarity.
final class ChordClassifier {

    private let confidenceThreshold: Float

    init(confidenceThreshold: Float = 0.85) {
        self.confidenceThreshold = confidenceThreshold
    }

    /// Classify a chroma vector against all known chords.
    /// Returns a ChordDetectionEvent with the best match, or nil if below threshold.
    func classify(chroma: [Float]) -> ChordDetectionEvent? {
        guard chroma.count == 12 else { return nil }

        let magnitude = chroma.reduce(0, +)
        guard magnitude > 0.001 else { return nil }

        var bestChord: String?
        var bestScore: Float = -1.0

        for template in ChordLibrary.allChords {
            let score = cosineSimilarity(chroma, template.chromaProfile)
            if score > bestScore {
                bestScore = score
                bestChord = template.name
            }
        }

        guard bestScore >= confidenceThreshold, let chord = bestChord else {
            return nil
        }

        return ChordDetectionEvent(chord: chord, confidence: bestScore)
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }

        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        let denominator = sqrtf(normA) * sqrtf(normB)
        guard denominator > 0 else { return 0 }

        return dotProduct / denominator
    }
}
