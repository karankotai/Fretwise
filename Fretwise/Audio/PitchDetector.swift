import Accelerate
import Foundation

/// Detects the fundamental frequency of a monophonic audio signal
/// using the YIN autocorrelation algorithm.
final class PitchDetector {

    /// Minimum RMS amplitude to consider the signal valid (not silence).
    private let silenceThreshold: Float = 0.01

    /// YIN threshold for periodicity detection. Lower = stricter.
    private let yinThreshold: Float = 0.15

    /// Frequency range for guitar strings (E2=82Hz to A4=440Hz, with margin).
    private let minFrequency: Float = 60.0
    private let maxFrequency: Float = 500.0

    /// Detect the fundamental pitch from a raw audio buffer.
    /// Returns the frequency in Hz, or nil if no clear pitch detected.
    func detectPitch(buffer: [Float], sampleRate: Float) -> Float? {
        // Check signal energy — reject silence
        let rms = sqrt(buffer.map { $0 * $0 }.reduce(0, +) / Float(buffer.count))
        guard rms > silenceThreshold else { return nil }

        let halfN = buffer.count / 2
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = min(Int(sampleRate / minFrequency), halfN)

        guard minLag < maxLag else { return nil }

        // Step 1: Compute difference function d(tau)
        var difference = [Float](repeating: 0, count: halfN)

        for tau in minLag..<maxLag {
            var sum: Float = 0
            for j in 0..<halfN {
                let delta = buffer[j] - buffer[j + tau]
                sum += delta * delta
            }
            difference[tau] = sum
        }

        // Step 2: Cumulative mean normalized difference (CMND)
        var cmnd = [Float](repeating: 0, count: halfN)
        cmnd[0] = 1.0
        var runningSum: Float = 0

        for tau in 1..<maxLag {
            runningSum += difference[tau]
            cmnd[tau] = runningSum > 0 ? difference[tau] * Float(tau) / runningSum : 1.0
        }

        // Step 3: Find the first tau where CMND dips below threshold,
        // then pick the minimum in that valley.
        var bestTau: Int?

        for tau in minLag..<maxLag {
            if cmnd[tau] < yinThreshold {
                // Find the local minimum in this dip
                var localMin = tau
                while localMin + 1 < maxLag && cmnd[localMin + 1] < cmnd[localMin] {
                    localMin += 1
                }
                bestTau = localMin
                break
            }
        }

        guard let tau = bestTau else { return nil }

        // Step 4: Parabolic interpolation for sub-sample accuracy
        let s0 = cmnd[tau - 1]
        let s1 = cmnd[tau]
        let s2 = tau + 1 < halfN ? cmnd[tau + 1] : s1

        let adjustment = (s0 - s2) / (2.0 * (s0 - 2.0 * s1 + s2))
        let refinedTau = Float(tau) + (adjustment.isFinite ? adjustment : 0)

        guard refinedTau > 0 else { return nil }

        return sampleRate / refinedTau
    }
}
