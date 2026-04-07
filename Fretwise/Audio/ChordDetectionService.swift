import Combine
import Foundation

/// Orchestrates the audio pipeline: capture -> chroma -> classify -> publish.
/// Publishes debounced ChordDetectionEvents for the UI and lesson engine.
final class ChordDetectionService: ObservableObject {

    @Published var currentEvent: ChordDetectionEvent?
    @Published var rawEvent: ChordDetectionEvent?

    private let audioCapture: AudioCaptureService
    private let chromaExtractor: ChromaExtractor
    private let chordClassifier: ChordClassifier
    private var cancellables = Set<AnyCancellable>()

    // Debounce state
    private var pendingChord: String?
    private var pendingStartTime: Date?
    private let debounceInterval: TimeInterval = 0.3

    init(
        audioCapture: AudioCaptureService = AudioCaptureService(),
        sampleRate: Float = 44100.0,
        bufferSize: Int = 4096,
        confidenceThreshold: Float = 0.75
    ) {
        self.audioCapture = audioCapture
        self.chromaExtractor = ChromaExtractor(sampleRate: sampleRate, bufferSize: bufferSize)
        self.chordClassifier = ChordClassifier(confidenceThreshold: confidenceThreshold)

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
            self.currentEvent = nil
            self.rawEvent = nil
        }
    }

    var permissionGranted: Bool {
        audioCapture.permissionGranted
    }

    func requestPermission() {
        audioCapture.checkPermission()
    }

    private func processBuffer(_ buffer: [Float]) {
        let chroma = chromaExtractor.extract(from: buffer)
        let event = chordClassifier.classify(chroma: chroma)

        DispatchQueue.main.async { [weak self] in
            self?.rawEvent = event
        }

        let now = Date()
        let detectedChord = event?.chord

        if detectedChord == pendingChord {
            if let startTime = pendingStartTime,
               now.timeIntervalSince(startTime) >= debounceInterval {
                DispatchQueue.main.async { [weak self] in
                    self?.currentEvent = event
                }
            }
        } else {
            pendingChord = detectedChord
            pendingStartTime = now

            if detectedChord == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.currentEvent = nil
                }
            }
        }
    }
}
