import Accelerate
import Foundation

/// Extracts a 12-bin chroma vector from a raw audio buffer using FFT.
/// Chroma bins: [C, C#, D, D#, E, F, F#, G, G#, A, A#, B]
final class ChromaExtractor {

    private(set) var sampleRate: Float
    private let bufferSize: Int
    private let fftSetup: vDSP.FFT<DSPSplitComplex>
    private let halfN: Int
    private let log2n: vDSP_Length

    init(sampleRate: Float, bufferSize: Int) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
        self.halfN = bufferSize / 2
        self.log2n = vDSP_Length(log2(Double(bufferSize)))
        self.fftSetup = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)!
    }

    func updateSampleRate(_ newRate: Float) {
        sampleRate = newRate
    }

    /// Extract a normalized 12-bin chroma vector from a Float audio buffer.
    func extract(from buffer: [Float]) -> [Float] {
        // Use exactly bufferSize samples — truncate or zero-pad as needed
        let input: [Float]
        if buffer.count >= bufferSize {
            input = Array(buffer.prefix(bufferSize))
        } else {
            input = buffer + [Float](repeating: 0, count: bufferSize - buffer.count)
        }

        // Apply Hann window to reduce spectral leakage
        var windowed = [Float](repeating: 0, count: bufferSize)
        var window = [Float](repeating: 0, count: bufferSize)
        vDSP_hann_window(&window, vDSP_Length(bufferSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(input, 1, window, 1, &windowed, 1, vDSP_Length(bufferSize))

        // Perform FFT
        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        realPart.withUnsafeMutableBufferPointer { realBuf in
            imagPart.withUnsafeMutableBufferPointer { imagBuf in
                var splitComplex = DSPSplitComplex(
                    realp: realBuf.baseAddress!,
                    imagp: imagBuf.baseAddress!
                )

                windowed.withUnsafeBufferPointer { inputBuf in
                    inputBuf.baseAddress!.withMemoryRebound(
                        to: DSPComplex.self,
                        capacity: halfN
                    ) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(halfN))
                    }
                }

                fftSetup.forward(input: splitComplex, output: &splitComplex)
            }
        }

        // Compute magnitudes
        var magnitudes = [Float](repeating: 0, count: halfN)
        realPart.withUnsafeBufferPointer { realBuf in
            imagPart.withUnsafeBufferPointer { imagBuf in
                var splitComplex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: realBuf.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: imagBuf.baseAddress!)
                )
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfN))
            }
        }

        // Fold magnitudes into 12 chroma bins
        var chroma = [Float](repeating: 0, count: 12)

        for bin in 1..<halfN {
            let frequency = Float(bin) * sampleRate / Float(bufferSize)

            // Only consider frequencies in the guitar range (80 Hz to 1200 Hz)
            guard frequency >= 80 && frequency <= 1200 else { continue }

            // Map frequency to chroma bin
            // MIDI note = 69 + 12 * log2(freq / 440)
            let midiNote = 69.0 + 12.0 * log2(Double(frequency) / 440.0)
            let chromaBin = Int(round(midiNote)) % 12
            let safeBin = ((chromaBin % 12) + 12) % 12

            chroma[safeBin] += magnitudes[bin]
        }

        // Normalize so max = 1.0
        let maxVal = chroma.max() ?? 0
        guard maxVal > 0 else { return chroma }
        return chroma.map { $0 / maxVal }
    }
}
