import Combine
import Foundation

/// Represents a guitar string with its standard tuning frequency.
struct GuitarString: Equatable {
    let name: String
    let frequency: Float
    let stringNumber: Int  // 6 = low E, 1 = high E
}

/// How close the tuning is to the target.
enum TuningAccuracy: Equatable {
    case inTune   // within +/- 5 cents
    case close    // within +/- 15 cents
    case off      // beyond +/- 15 cents
}

/// Orchestrates pitch detection and maps results to guitar strings.
/// Publishes tuning state for the UI.
final class TunerEngine: ObservableObject {

    @Published var detectedFrequency: Float?
    @Published var nearestGuitarString: GuitarString?
    @Published var centsOff: Float = 0
    @Published var accuracy: TuningAccuracy = .off

    static let standardTuning: [GuitarString] = [
        GuitarString(name: "E2", frequency: 82.41,  stringNumber: 6),
        GuitarString(name: "A2", frequency: 110.00, stringNumber: 5),
        GuitarString(name: "D3", frequency: 146.83, stringNumber: 4),
        GuitarString(name: "G3", frequency: 196.00, stringNumber: 3),
        GuitarString(name: "B3", frequency: 246.94, stringNumber: 2),
        GuitarString(name: "E4", frequency: 329.63, stringNumber: 1),
    ]

    private let audioCapture: AudioCaptureService
    private let pitchDetector = PitchDetector()
    private var cancellables = Set<AnyCancellable>()

    init(audioCapture: AudioCaptureService = AudioCaptureService()) {
        self.audioCapture = audioCapture

        audioCapture.bufferPublisher
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] buffer in
                self?.processBuffer(buffer)
            }
            .store(in: &cancellables)
    }

    func start() throws {
        try audioCapture.start()
    }

    func stop() {
        audioCapture.stop()
        DispatchQueue.main.async {
            self.detectedFrequency = nil
            self.nearestGuitarString = nil
            self.centsOff = 0
            self.accuracy = .off
        }
    }

    var permissionGranted: Bool {
        audioCapture.permissionGranted
    }

    private func processBuffer(_ buffer: [Float]) {
        let sampleRate = audioCapture.actualSampleRate
        guard let frequency = pitchDetector.detectPitch(buffer: buffer, sampleRate: sampleRate) else {
            DispatchQueue.main.async { [weak self] in
                self?.detectedFrequency = nil
                self?.nearestGuitarString = nil
            }
            return
        }

        let nearest = TunerEngine.nearestString(to: frequency)
        let cents = TunerEngine.centsOffset(detected: frequency, reference: nearest.frequency)
        let acc = TunerEngine.tuningAccuracy(centsOffset: cents)

        DispatchQueue.main.async { [weak self] in
            self?.detectedFrequency = frequency
            self?.nearestGuitarString = nearest
            self?.centsOff = cents
            self?.accuracy = acc
        }
    }

    // MARK: - Static helpers (public for testing)

    static func centsOffset(detected: Float, reference: Float) -> Float {
        1200.0 * log2(detected / reference)
    }

    static func nearestString(to frequency: Float) -> GuitarString {
        standardTuning.min(by: {
            abs(centsOffset(detected: frequency, reference: $0.frequency)) <
            abs(centsOffset(detected: frequency, reference: $1.frequency))
        })!
    }

    static func tuningAccuracy(centsOffset: Float) -> TuningAccuracy {
        let absCents = abs(centsOffset)
        if absCents <= 5.0 { return .inTune }
        if absCents <= 15.0 { return .close }
        return .off
    }
}
